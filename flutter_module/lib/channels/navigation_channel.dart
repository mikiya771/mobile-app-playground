import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

// Singleton that owns the 'app/navigation' MethodChannel.
//
// Why singleton and not a provider? The channel must survive widget rebuilds
// and be reachable from outside the widget tree (router delegate listener).
// Native drives all branch switches; Flutter never initiates tab changes.
class NavigationChannelController {
  NavigationChannelController._();

  static NavigationChannelController? _instance;
  static NavigationChannelController get instance {
    assert(_instance != null, 'Call NavigationChannelController.initialize() first');
    return _instance!;
  }

  static const _channel = MethodChannel('app/navigation');

  late GoRouter _router;
  StatefulNavigationShell? _shell;

  /// Called once in main() after the GoRouter is created.
  static void initialize(GoRouter router) {
    _instance = NavigationChannelController._();
    _instance!._router = router;
    _channel.setMethodCallHandler(_instance!._handleCall);
  }

  /// Shell builder stores the shell so branch switches can be performed.
  void updateShell(StatefulNavigationShell shell) {
    _shell = shell;
  }

  // ── Incoming (Native → Flutter) ──────────────────────────────────────────

  Future<dynamic> _handleCall(MethodCall call) async {
    switch (call.method) {
      case 'setBranch':
        // Native tab selected — switch go_router branch.
        // reselect=true means the user tapped the already-active tab → reset to root.
        final args = Map<String, dynamic>.from(call.arguments as Map);
        final index = args['index'] as int;
        final reselect = args['reselect'] as bool? ?? false;
        _shell?.goBranch(index, initialLocation: reselect);

      case 'navigate':
        // Deep-link arrival. The path prefix (/search or /shop) is enough for
        // StatefulShellRoute to pick the correct branch automatically.
        final args = Map<String, dynamic>.from(call.arguments as Map);
        final location = args['location'] as String;
        _router.go(location);

      case 'popRoute':
        // Android back-press delegation: pop go_router if possible.
        try {
          _router.pop();
        } catch (_) {
          // Already at branch root — native should fall back (e.g. go to Home tab).
        }

      default:
        throw PlatformException(code: 'NOT_IMPLEMENTED', message: call.method);
    }
  }

  // ── Outgoing (Flutter → Native) ──────────────────────────────────────────

  /// Request native to open a native screen.
  /// Native decides push vs modal; see README §"Flutter→native push".
  Future<void> openNativeScreen(String route, [Map<String, dynamic> args = const {}]) {
    return _channel.invokeMethod('openNativeScreen', {'route': route, 'args': args});
  }

  /// Notify native of current branch stack depth (used by Android back handler).
  Future<void> reportBranchStackChange(int branchIndex, int depth) {
    return _channel.invokeMethod('branchStackDidChange', {
      'index': branchIndex,
      'depth': depth,
    });
  }
}
