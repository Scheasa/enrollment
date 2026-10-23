class AppConstants {
  static const String baseUrl = String.fromEnvironment(
    'API_URL',
    defaultValue: 'http://127.0.0.1:8000/api',
  );

  static const String userKey = 'saved_user';

  /// The "tap to fill" demo accounts on the login screen.
  /// Hide them for the final demo: --dart-define=DEMO_LOGINS=false
  static const bool showDemoLogins = bool.fromEnvironment(
    'DEMO_LOGINS',
    defaultValue: true,
  );
}
