import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../providers/auth_providers.dart';

class LoginWebViewScreen extends ConsumerStatefulWidget {
  const LoginWebViewScreen({super.key});

  @override
  ConsumerState<LoginWebViewScreen> createState() => _LoginWebViewScreenState();
}

class _LoginWebViewScreenState extends ConsumerState<LoginWebViewScreen> {
  late final WebViewController _controller;
  var _isLoading = true;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..addJavaScriptChannel(
        'AuthBridge',
        onMessageReceived: _onAuthMessage,
      )
      ..setNavigationDelegate(NavigationDelegate(
        onPageFinished: (_) => setState(() => _isLoading = false),
        onNavigationRequest: _onNavRequest,
      ))
      ..loadFlutterAsset('assets/login.html');
  }

  NavigationDecision _onNavRequest(NavigationRequest req) {
    // ローカルアセット（blob: / about: / file:）は常に許可
    final uri = Uri.tryParse(req.url);
    if (uri == null || uri.host.isEmpty) return NavigationDecision.navigate;

    // 外部URLはブロック
    _showBlockedAlert(req.url);
    return NavigationDecision.prevent;
  }

  void _onAuthMessage(JavaScriptMessage msg) {
    try {
      final data = jsonDecode(msg.message) as Map<String, dynamic>;
      final token = data['token'] as String?;
      if (token != null && token.isNotEmpty) {
        ref.read(authProvider.notifier).login(token);
      }
    } catch (_) {}
  }

  void _showBlockedAlert(String url) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('アクセスできません'),
        content: Text('このURLは許可されていません:\n$url'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ログイン'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _controller.reload,
          ),
        ],
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_isLoading) const Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }
}
