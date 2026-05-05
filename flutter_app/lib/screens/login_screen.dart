import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_providers.dart';

class LoginScreen extends ConsumerWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.check_circle_outline, size: 72, color: Colors.indigo),
              const SizedBox(height: 24),
              Text(
                'TODO App',
                style: Theme.of(context).textTheme.headlineMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),
              FilledButton.icon(
                icon: const Icon(Icons.language),
                label: const Text('自社アカウントでログイン'),
                onPressed: () => context.push('/login/webview'),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                icon: const Icon(Icons.lock_open),
                label: const Text('OAuthでログイン（デモ）'),
                onPressed: () => _mockOAuth(context, ref),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _mockOAuth(BuildContext context, WidgetRef ref) async {
    // 本番では flutter_web_auth_2 を使用:
    // final result = await FlutterWebAuth2.authenticate(
    //   url: AppConfig.oauthUrl,
    //   callbackUrlScheme: AppConfig.callbackUrlScheme,
    // );
    // final token = Uri.parse(result).queryParameters['token']!;
    await ref.read(authProvider.notifier).login('mock_oauth_token');
  }
}
