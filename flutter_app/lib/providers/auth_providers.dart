import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/auth_repository.dart';

final authRepositoryProvider = Provider((_) => AuthRepository());

// String? = token。nullなら未ログイン
final authProvider = AsyncNotifierProvider<AuthNotifier, String?>(AuthNotifier.new);

class AuthNotifier extends AsyncNotifier<String?> {
  @override
  Future<String?> build() => ref.read(authRepositoryProvider).getToken();

  Future<void> login(String token) async {
    await ref.read(authRepositoryProvider).saveToken(token);
    state = AsyncData(token);
  }

  Future<void> logout() async {
    await ref.read(authRepositoryProvider).deleteToken();
    state = const AsyncData(null);
  }
}
