package com.example.addtoapp

import android.content.Intent
import android.os.Bundle
import androidx.activity.OnBackPressedCallback
import androidx.appcompat.app.AppCompatActivity
import com.example.addtoapp.databinding.ActivityMainBinding
import com.example.addtoapp.fragments.ActivityTabFragment
import com.example.addtoapp.fragments.HomeFragment
import com.example.addtoapp.fragments.ProfileFragment
import io.flutter.embedding.android.FlutterFragment
import io.flutter.embedding.engine.FlutterEngineCache
import io.flutter.plugin.common.MethodChannel

/**
 * Single-activity host.
 *
 * Layout: FrameLayout (fragment container) + NavigationBarView (5 items).
 *
 * Fragment strategy:
 *   - FlutterFragment: added ONCE with add(), shown/hidden with show()/hide().
 *     Never replaced or recreated — the engine stays resident between tab switches.
 *   - Native fragments: same show()/hide() discipline, added lazily on first visit.
 *
 * Tab-to-branch mapping:
 *   nav_home (0)     → HomeFragment        (native)
 *   nav_search (1)   → FlutterFragment     (branch 0)
 *   nav_activity (2) → ActivityTabFragment (native)
 *   nav_shop (3)     → FlutterFragment     (branch 1)
 *   nav_profile (4)  → ProfileFragment     (native)
 *
 * Back-press policy (see setupBackHandler):
 *   Flutter tab active + depth > 1  → delegate pop to go_router via MethodChannel
 *   Flutter tab active + depth == 1 → switch to Home tab
 *   Native tab active               → default Android behavior (finish() at root)
 */
class MainActivity : AppCompatActivity() {

    private lateinit var binding: ActivityMainBinding
    private lateinit var navigationChannel: MethodChannel

    // The FlutterFragment is created once. On activity recreation (config change),
    // it is restored from the fragment manager rather than rebuilt — otherwise the
    // lazy would hold a new (detached) instance while the manager has the old one.
    private val flutterFragment: FlutterFragment by lazy {
        (supportFragmentManager.findFragmentByTag(TAG_FLUTTER) as? FlutterFragment)
            ?: FlutterFragment.withCachedEngine(MyApplication.ENGINE_ID)
                .shouldAttachEngineToActivity(true)
                .build()
    }

    private var currentTabIndex: Int = 0

    // Depth of the active Flutter branch's navigation stack (1 = at root).
    // Updated via branchStackDidChange MethodChannel callback from Flutter.
    private var currentFlutterDepth: Int = 1

    private val flutterTabIndices = setOf(1, 3)

    // Maps nav item ID → (tabIndex, branchIndex)
    private val navItemMap = mapOf(
        R.id.nav_home     to Pair(0, -1),
        R.id.nav_search   to Pair(1,  0),
        R.id.nav_activity to Pair(2, -1),
        R.id.nav_shop     to Pair(3,  1),
        R.id.nav_profile  to Pair(4, -1),
    )

    // Ordered nav item IDs matching tab indices 0-4.
    private val navItemIds = listOf(
        R.id.nav_home,
        R.id.nav_search,
        R.id.nav_activity,
        R.id.nav_shop,
        R.id.nav_profile,
    )

    // MARK: - Lifecycle

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        binding = ActivityMainBinding.inflate(layoutInflater)
        setContentView(binding.root)

        setupFragments()
        setupNavigationBar()
        setupMethodChannel()
        setupBackHandler()

        // Handle deep-link intent that started this activity.
        handleDeepLinkIntent(intent)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        // launchMode="singleTop": deep links while app is running come here.
        handleDeepLinkIntent(intent)
    }

    // MARK: - Fragment Setup

    private fun setupFragments() {
        // Add the FlutterFragment ONCE. All subsequent tab switches use show/hide.
        if (supportFragmentManager.findFragmentByTag(TAG_FLUTTER) == null) {
            supportFragmentManager.beginTransaction()
                .add(R.id.fragment_container, flutterFragment, TAG_FLUTTER)
                .hide(flutterFragment)   // hidden initially; Home tab is active
                .commit()
        }

        // Add native fragments (all hidden initially; Home will be shown below).
        addNativeFragmentIfAbsent(HomeFragment(), TAG_HOME)
        addNativeFragmentIfAbsent(ActivityTabFragment(), TAG_ACTIVITY)
        addNativeFragmentIfAbsent(ProfileFragment(), TAG_PROFILE)

        // Show Home tab on launch.
        showNativeFragment(TAG_HOME)
    }

    private fun addNativeFragmentIfAbsent(fragment: androidx.fragment.app.Fragment, tag: String) {
        if (supportFragmentManager.findFragmentByTag(tag) == null) {
            supportFragmentManager.beginTransaction()
                .add(R.id.fragment_container, fragment, tag)
                .hide(fragment)
                .commit()
        }
    }

    // MARK: - Navigation Bar

    private fun setupNavigationBar() {
        // Normal tab switch.
        binding.navBar.setOnItemSelectedListener { item ->
            val (tabIndex, branchIndex) = navItemMap[item.itemId] ?: return@setOnItemSelectedListener false
            if (tabIndex != currentTabIndex) {
                switchToTab(tabIndex, branchIndex)
            }
            true
        }

        // Re-tap on already-active tab: reset Flutter branch to root (acceptance criterion #4).
        binding.navBar.setOnItemReselectedListener { item ->
            val (tabIndex, branchIndex) = navItemMap[item.itemId] ?: return@setOnItemReselectedListener
            if (flutterTabIndices.contains(tabIndex)) {
                sendBranchSwitch(branchIndex, reselect = true)
            }
        }
    }

    private fun switchToTab(tabIndex: Int, branchIndex: Int) {
        currentTabIndex = tabIndex

        if (flutterTabIndices.contains(tabIndex)) {
            // Show Flutter, hide all native fragments.
            showFlutterFragment()
            sendBranchSwitch(branchIndex, reselect = false)
        } else {
            // Hide Flutter, show the target native fragment.
            hideFlutterFragment()
            val tag = nativeTagForTab(tabIndex)
            showNativeFragment(tag)
        }

        // Update back-press callback enablement.
        backCallback.isEnabled = flutterTabIndices.contains(tabIndex)
    }

    private fun showFlutterFragment() {
        val fm = supportFragmentManager
        val tx = fm.beginTransaction()
        // Show Flutter; hide all native fragments.
        listOf(TAG_HOME, TAG_ACTIVITY, TAG_PROFILE).forEach { tag ->
            fm.findFragmentByTag(tag)?.let { tx.hide(it) }
        }
        tx.show(flutterFragment).commit()
    }

    private fun hideFlutterFragment() {
        val fm = supportFragmentManager
        fm.beginTransaction().hide(flutterFragment).commit()
    }

    private fun showNativeFragment(tag: String) {
        val fm = supportFragmentManager
        val tx = fm.beginTransaction()
        listOf(TAG_HOME, TAG_ACTIVITY, TAG_PROFILE).forEach { t ->
            fm.findFragmentByTag(t)?.let { if (t == tag) tx.show(it) else tx.hide(it) }
        }
        tx.commit()
    }

    private fun nativeTagForTab(tabIndex: Int) = when (tabIndex) {
        0 -> TAG_HOME
        2 -> TAG_ACTIVITY
        4 -> TAG_PROFILE
        else -> error("Not a native tab: $tabIndex")
    }

    /** Send setBranch to Flutter. This is the MethodChannel call that drives branch switches. */
    private fun sendBranchSwitch(branchIndex: Int, reselect: Boolean) {
        navigationChannel.invokeMethod(
            "setBranch",
            mapOf("index" to branchIndex, "reselect" to reselect)
        )
    }

    // MARK: - MethodChannel

    private fun setupMethodChannel() {
        val engine = FlutterEngineCache.getInstance().get(MyApplication.ENGINE_ID)
            ?: error("FlutterEngine not in cache — check MyApplication.onCreate()")

        navigationChannel = MethodChannel(engine.dartExecutor.binaryMessenger, "app/navigation")

        // Flutter → Native calls.
        navigationChannel.setMethodCallHandler { call, result ->
            when (call.method) {
                "openNativeScreen" -> {
                    // Show a native Activity as a new screen on top of everything.
                    // Using a new Activity (instead of a Fragment) keeps the Flutter
                    // surface intact and avoids z-ordering complexity with the FlutterFragment.
                    val args = call.arguments as? Map<*, *> ?: emptyMap<Any, Any>()
                    val route = args["route"] as? String ?: ""
                    val extraArgs = args["args"] as? Map<*, *> ?: emptyMap<Any, Any>()
                    val intent = Intent(this, NativeDetailActivity::class.java).apply {
                        putExtra(NativeDetailActivity.EXTRA_ROUTE, route)
                        putExtra(NativeDetailActivity.EXTRA_ARGS, extraArgs.toString())
                    }
                    startActivity(intent)
                    result.success(null)
                }

                "branchStackDidChange" -> {
                    // Update depth so the back callback can decide whether to delegate to Flutter.
                    val args = call.arguments as? Map<*, *> ?: emptyMap<Any, Any>()
                    currentFlutterDepth = (args["depth"] as? Int) ?: 1
                    result.success(null)
                }

                else -> result.notImplemented()
            }
        }
    }

    // MARK: - Back Press Handling

    // Why OnBackPressedCallback instead of overriding onBackPressed()?
    // onBackPressed() is deprecated in API 33+. The callback integrates with
    // Android 14's predictive back gesture system.
    private val backCallback = object : OnBackPressedCallback(false) {
        override fun handleOnBackPressed() {
            if (currentFlutterDepth > 1) {
                // go_router has a page to pop within the current branch.
                navigationChannel.invokeMethod("popRoute", null)
            } else {
                // At branch root — go Home instead of finishing the app.
                binding.navBar.selectedItemId = R.id.nav_home
                switchToTab(0, -1)
            }
        }
    }

    private fun setupBackHandler() {
        onBackPressedDispatcher.addCallback(this, backCallback)
    }

    // MARK: - Deep Link Handling

    /**
     * Parses a sampleapp:// URL and navigates to the correct tab + Flutter route.
     *
     * sampleapp://shop/42    → Shop tab  (index 3, branch 1) + navigate /shop/42
     * sampleapp://search/42  → Search tab (index 1, branch 0) + navigate /search/42
     */
    private fun handleDeepLinkIntent(intent: Intent?) {
        val uri = intent?.data ?: return
        if (uri.scheme != "sampleapp") return

        val host = uri.host ?: return
        val path = uri.path ?: ""     // "/42" or ""
        val location = "/$host$path"  // "/shop/42"

        val tabIndex = when {
            location.startsWith("/shop")   -> 3
            location.startsWith("/search") -> 1
            else -> return
        }

        // Setting selectedItemId programmatically triggers setOnItemSelectedListener,
        // which calls switchToTab() and sendBranchSwitch(). We only need to add the
        // navigate() call afterward for the specific deep-link sub-path.
        binding.navBar.selectedItemId = navItemIds[tabIndex]

        // Tell Flutter to navigate to the full path within the already-selected branch.
        // go_router uses the path prefix to confirm which branch is active.
        navigationChannel.invokeMethod("navigate", mapOf("location" to location))
    }

    // MARK: - Constants

    private companion object {
        const val TAG_FLUTTER  = "flutter"
        const val TAG_HOME     = "home"
        const val TAG_ACTIVITY = "activity"
        const val TAG_PROFILE  = "profile"
    }
}
