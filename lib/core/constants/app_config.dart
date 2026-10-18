class AppConfig {
  const AppConfig._();

  static const String appName = 'Kamil Resto POS';
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://api.aljadeedrahathotel.com/api',
  );
  static const bool useMockRepositories = bool.fromEnvironment(
    'USE_MOCK_REPOSITORIES',
    defaultValue: false,
  );
}
