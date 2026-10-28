class AppConfigDataSource {
  const AppConfigDataSource();

  String get authBaseUrl => const String.fromEnvironment(
        'AUTH_BASE_URL',
        defaultValue: '',
      );
}
