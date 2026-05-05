import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthRepository {
  static const _key = 'auth_token';
  final _storage = const FlutterSecureStorage();

  Future<String?> getToken() => _storage.read(key: _key);
  Future<void> saveToken(String token) => _storage.write(key: _key, value: token);
  Future<void> deleteToken() => _storage.delete(key: _key);
}
