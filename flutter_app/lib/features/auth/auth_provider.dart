import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'token_storage.dart';

// ── State ────────────────────────────────────────────────────────────────────
class AuthState {
  const AuthState({this.isLoggedIn = false, this.token});
  final bool isLoggedIn;
  final String? token;
}

// ── ViewModel ────────────────────────────────────────────────────────────────
class AuthNotifier extends AsyncNotifier<AuthState> {
  @override
  Future<AuthState> build() async {
    final token = await ref.read(tokenStorageProvider).read();
    return AuthState(isLoggedIn: token != null, token: token);
  }

  Future<void> login({String token = 'dummy-token'}) async {
    await ref.read(tokenStorageProvider).write(token);
    state = AsyncData(AuthState(isLoggedIn: true, token: token));
  }

  Future<void> logout() async {
    await ref.read(tokenStorageProvider).delete();
    state = const AsyncData(AuthState(isLoggedIn: false));
  }
}

// ── Provider ─────────────────────────────────────────────────────────────────
final authProvider =
    AsyncNotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);