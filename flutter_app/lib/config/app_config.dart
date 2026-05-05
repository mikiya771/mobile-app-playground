abstract final class AppConfig {
  static const baseUrl = 'https://jsonplaceholder.typicode.com';
  static const allowedHosts = ['jsonplaceholder.typicode.com'];
  static const authAllowedHosts = <String>[];  // ローカルHTMLのためホスト制限なし
  static const callbackUrlScheme = 'todoapp';
  static const oauthUrl =
      'https://accounts.google.com/o/oauth2/auth?response_type=code&client_id=demo';
}
