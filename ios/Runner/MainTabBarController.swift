import UIKit
import Flutter

// MARK: - Architecture Note
//
// View hierarchy:
//   UIWindow
//   └── MainTabBarController  (root VC)
//       ├── [0] HomeViewController         (native tab)
//       ├── [1] SearchPlaceholderVC        (Flutter tab — placeholder for tab item)
//       ├── [2] ActivityViewController     (native tab)
//       ├── [3] ShopPlaceholderVC          (Flutter tab — placeholder for tab item)
//       ├── [4] ProfileViewController      (native tab)
//       ├── UITabBar                       (always on top)
//       └── FlutterViewController.view     (child VC overlay, pinned above tab bar)
//
// Why overlay and not embed inside each tab's content VC?
// If the FVC were parented inside tab 1 or tab 3, switching tabs would require
// re-parenting (removeFromParent / addChild) on every switch, causing view
// hierarchy flicker and potential engine detachment. By parking the FVC's view
// permanently above the tab content but below the tab bar, we simply
// show/hide it — zero re-parenting, zero flicker.
//
// The FlutterViewController is NEVER recreated. It is created once from the
// single warm FlutterEngine and stays alive for the app's lifetime.

final class MainTabBarController: UITabBarController {

    // The single resident Flutter view controller.
    // "resident" = lives for the full app lifetime, just hidden when not needed.
    private var flutterVC: FlutterViewController!
    private var navigationChannel: FlutterMethodChannel!

    // Native tab indices that host Flutter content.
    private let flutterTabIndices: Set<Int> = [1, 3]

    // Maps native tab index → go_router branch index.
    private let tabToBranchIndex: [Int: Int] = [1: 0, 3: 1]

    // Track the currently active Flutter branch for re-select detection.
    private var activeBranchIndex: Int = 0

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        self.delegate = self
        setupViewControllers()
        setupFlutterOverlay()
        setupMethodChannel()
    }

    // MARK: - Tab Setup

    private func setupViewControllers() {
        let home = HomeViewController()
        home.tabBarItem = UITabBarItem(title: "Home", image: UIImage(systemName: "house"), tag: 0)

        // Placeholder VCs hold only the tab bar item; Flutter's view covers their content area.
        let searchPlaceholder = PlaceholderViewController()
        searchPlaceholder.tabBarItem = UITabBarItem(title: "Search", image: UIImage(systemName: "magnifyingglass"), tag: 1)

        let activity = ActivityViewController()
        activity.tabBarItem = UITabBarItem(title: "Activity", image: UIImage(systemName: "bell"), tag: 2)

        let shopPlaceholder = PlaceholderViewController()
        shopPlaceholder.tabBarItem = UITabBarItem(title: "Shop", image: UIImage(systemName: "cart"), tag: 3)

        let profile = ProfileViewController()
        profile.tabBarItem = UITabBarItem(title: "Profile", image: UIImage(systemName: "person"), tag: 4)

        viewControllers = [home, searchPlaceholder, activity, shopPlaceholder, profile]
    }

    // MARK: - Flutter Overlay

    private func setupFlutterOverlay() {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return }

        // Create the single FlutterViewController from the warm engine.
        // This is the ONLY FVC in the app — never create a second one.
        flutterVC = FlutterViewController(engine: appDelegate.flutterEngine, nibName: nil, bundle: nil)

        // Add as child of self (the UITabBarController), NOT inside any tab's content VC.
        addChild(flutterVC)

        let fv = flutterVC.view!
        fv.translatesAutoresizingMaskIntoConstraints = false

        // Insert below the tab bar so the tab bar always renders on top.
        view.insertSubview(fv, belowSubview: tabBar)

        NSLayoutConstraint.activate([
            fv.topAnchor.constraint(equalTo: view.topAnchor),
            fv.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            fv.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            // Stop at the tab bar's top edge — Flutter handles safe area internally.
            fv.bottomAnchor.constraint(equalTo: tabBar.topAnchor),
        ])

        flutterVC.didMove(toParent: self)

        // Hidden initially because the app opens on the Home (native) tab.
        flutterVC.view.isHidden = true
    }

    // MARK: - MethodChannel

    private func setupMethodChannel() {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return }

        navigationChannel = FlutterMethodChannel(
            name: "app/navigation",
            binaryMessenger: appDelegate.flutterEngine.binaryMessenger
        )

        // Flutter → Native messages.
        navigationChannel.setMethodCallHandler { [weak self] call, result in
            guard let self else { return }
            switch call.method {
            case "openNativeScreen":
                // Flutter requested a native screen.
                // Implementation: present modally with a UINavigationController wrapper.
                // Rationale: using modal avoids inserting into the UITabBarController's
                // navigation stack, which could conflict with tab-bar ownership.
                // See README §"Flutter→Native push".
                if let args = call.arguments as? [String: Any] {
                    let route = args["route"] as? String ?? ""
                    let extraArgs = args["args"] as? [String: Any] ?? [:]
                    self.presentNativeScreen(route: route, args: extraArgs)
                }
                result(nil)

            case "branchStackDidChange":
                // No-op on iOS — back navigation is handled by Flutter's AppBar
                // leading button and go_router's pop(). We don't need depth info here.
                result(nil)

            default:
                result(FlutterMethodNotImplemented)
            }
        }
    }

    // MARK: - Branch Switching (Native → Flutter)

    private func showFlutterBranch(branchIndex: Int, reselect: Bool) {
        activeBranchIndex = branchIndex
        flutterVC.view.isHidden = false
        navigationChannel.invokeMethod(
            "setBranch",
            arguments: ["index": branchIndex, "reselect": reselect]
        )
    }

    private func hideFlutter() {
        flutterVC.view.isHidden = true
    }

    // MARK: - Native Screen Presentation (Flutter → Native)

    private func presentNativeScreen(route: String, args: [String: Any]) {
        let nativeVC = NativeDetailViewController(route: route, args: args)
        let navVC = UINavigationController(rootViewController: nativeVC)
        navVC.modalPresentationStyle = .pageSheet
        present(navVC, animated: true)
    }

    // MARK: - Deep Link Entry Point

    /// Called by AppDelegate when the app opens via a URL scheme.
    ///
    /// URL format: sampleapp://<branch-prefix>/<id>
    /// Example:    sampleapp://shop/42  →  Flutter /shop/42 (Shop branch)
    func handleDeepLink(url: URL) {
        guard let host = url.host else { return }
        // Reconstruct a go_router location: host becomes the first path segment.
        // sampleapp://shop/42  →  host="shop", path="/42"  →  location="/shop/42"
        let suffix = url.path  // includes leading slash or empty
        let location = "/\(host)\(suffix)"  // → "/shop/42" or "/search/alpha"

        if location.hasPrefix("/shop") {
            selectedIndex = 3
            showFlutterBranch(branchIndex: 1, reselect: false)
        } else if location.hasPrefix("/search") {
            selectedIndex = 1
            showFlutterBranch(branchIndex: 0, reselect: false)
        }

        // Tell Flutter to navigate to the full location (branch auto-selected by path prefix).
        navigationChannel.invokeMethod("navigate", arguments: ["location": location])
    }
}

// MARK: - UITabBarControllerDelegate

extension MainTabBarController: UITabBarControllerDelegate {

    func tabBarController(
        _ tabBarController: UITabBarController,
        shouldSelect viewController: UIViewController
    ) -> Bool {
        guard let vcs = viewControllers,
              let index = vcs.firstIndex(of: viewController) else { return true }

        if flutterTabIndices.contains(index) {
            let branchIndex = tabToBranchIndex[index]!
            let isReselect = (selectedIndex == index)
            showFlutterBranch(branchIndex: branchIndex, reselect: isReselect)
        } else {
            hideFlutter()
        }
        return true
    }
}

// MARK: - PlaceholderViewController
// A minimal VC that provides a home for the tab bar item of Flutter-hosted tabs.
// Its view is always covered by the FlutterViewController overlay when the tab is active.
private final class PlaceholderViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
    }
}
