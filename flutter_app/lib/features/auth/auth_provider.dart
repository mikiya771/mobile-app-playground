import 'package:flutter_riverpod/flutter_riverpod.dart';

// ── State ────────────────────────────────────────────────────────────────────
class AuthState {
  const AuthState({this.isLoggedIn = false});
  final bool isLoggedIn;
}

// ── ViewModel ────────────────────────────────────────────────────────────────
class AuthNotifier extends AsyncNotifier<AuthState> {
  @override
  Future<AuthState> build() async {
    // Step 14 で flutter_secure_storage からトークンを読む
    return const AuthState(isLoggedIn: false);
  }

  Future<void> login() async {
    state = const AsyncData(AuthState(isLoggedIn: true));
  }

  Future<void> logout() async {
    state = const AsyncData(AuthState(isLoggedIn: false));
  }
}

// ── Provider ─────────────────────────────────────────────────────────────────
final authProvider =
    AsyncNotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);
