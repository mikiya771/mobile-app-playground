import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../config/app_config.dart';
import '../models/todo.dart';
import '../providers/todo_providers.dart';

class TodoDetailWebViewScreen extends ConsumerStatefulWidget {
  const TodoDetailWebViewScreen({super.key, required this.todo});
  final Todo todo;

  @override
  ConsumerState<TodoDetailWebViewScreen> createState() =>
      _TodoDetailWebViewScreenState();
}

class _TodoDetailWebViewScreenState
    extends ConsumerState<TodoDetailWebViewScreen> {
  late final WebViewController _controller;
  var _isLoading = true;
  var _isBlocked = false;

  @override
  void initState() {
    super.initState();

    final url = widget.todo.detailUrl;
    final host = Uri.parse(url).host;

    if (!AppConfig.allowedHosts.contains(host)) {
      _isBlocked = true;
      return;
    }

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(NavigationDelegate(
        onPageFinished: (_) => setState(() => _isLoading = false),
        onPageStarted: (_) => setState(() => _isLoading = true),
        onNavigationRequest: _onNavRequest,
      ))
      ..loadRequest(Uri.parse(url));
  }

  NavigationDecision _onNavRequest(NavigationRequest req) {
    final host = Uri.tryParse(req.url)?.host ?? '';
    if (host.isEmpty || AppConfig.allowedHosts.contains(host)) {
      return NavigationDecision.navigate;
    }
    _showBlockedAlert(req.url);
    return NavigationDecision.prevent;
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
              child: const Text('OK')),
        ],
      ),
    );
  }

  Future<void> _confirmDelete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('削除の確認'),
        content: Text('「${widget.todo.title}」を削除しますか？'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('キャンセル')),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('削除')),
        ],
      ),
    );
    if (ok == true && mounted) {
      await ref.read(todoListProvider.notifier).delete(widget.todo.id);
      if (mounted) context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isBlocked) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.todo.title)),
        body: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.block, size: 64, color: Colors.red),
              SizedBox(height: 16),
              Text('このURLは許可されていません'),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.todo.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => context.push('/edit', extra: widget.todo),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: _confirmDelete,
          ),
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
