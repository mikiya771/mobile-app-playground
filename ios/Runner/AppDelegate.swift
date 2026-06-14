import UIKit
import Flutter
import FlutterPluginRegistrant

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    // The single shared FlutterEngine. Warmed up once at launch and never
    // recreated. All branches (Search, Shop) share this engine and therefore
    // share one Dart isolate — the fundamental constraint of this architecture.
    //
    // We use a lazy var so warm-up happens on first access (application:didFinish…),
    // not at allocation time.
    lazy var flutterEngine: FlutterEngine = {
        let engine = FlutterEngine(name: "main_engine")
        // executeDartEntrypoint runs main() in the Flutter module.
        engine.run()
        // Register plugins declared by the Flutter module.
        GeneratedPluginRegistrant.register(with: engine)
        return engine
    }()

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        // Access the engine now to trigger warm-up before the first frame.
        _ = flutterEngine

        window = UIWindow(frame: UIScreen.main.bounds)
        window?.rootViewController = MainTabBarController()
        window?.makeKeyAndVisible()
        return true
    }

    // MARK: - Deep Link Handling (URL Scheme: sampleapp://)
    //
    // Example: sampleapp://shop/42  →  native selects Shop tab  +  Flutter goes to /shop/42
    //          sampleapp://search/alpha  →  Search tab  +  /search/alpha
    //
    // We parse the host+path to reconstruct a go_router location string.
    func application(
        _ app: UIApplication,
        open url: URL,
        options: [UIApplication.OpenURLOptionsKey: Any] = [:]
    ) -> Bool {
        guard let tabBarController = window?.rootViewController as? MainTabBarController else {
            return false
        }
        tabBarController.handleDeepLink(url: url)
        return true
    }
}
