/// App-wide constants.
class Constants {
  Constants._();

  /// App name.
  static const String appName = 'BahiKhata';

  /// App version.
  static const String appVersion = '1.0.1';

  /// Email domain used for username-to-email mapping.
  static const String emailDomain = 'bahikhata.local';

  /// Default currency symbol.
  static const String defaultCurrency = '\$';

  /// Converts a username to an email for Firebase Auth.
  /// e.g., "arjun" → "arjun@bahikhata.local"
  static String usernameToEmail(String username) {
    final cleanUsername = username.trim().toLowerCase();
    if (cleanUsername.contains('@')) return cleanUsername;
    return '$cleanUsername@$emailDomain';
  }

  /// Extracts username from email.
  /// e.g., "arjun@bahikhata.local" → "arjun"
  static String emailToUsername(String email) {
    return email.split('@').first;
  }

  /// Firestore collection paths.
  static const String organizationsCollection = 'organizations';
  static String usersCollection(String orgId) =>
      'organizations/$orgId/users';
  static String staffCollection(String orgId) =>
      'organizations/$orgId/staff';
  static String itemTypesCollection(String orgId) =>
      'organizations/$orgId/itemTypes';
  static String monthlyRatesCollection(String orgId) =>
      'organizations/$orgId/monthlyRates';
  static String productionEntriesCollection(String orgId) =>
      'organizations/$orgId/productionEntries';
  static String moneyEntriesCollection(String orgId) =>
      'organizations/$orgId/moneyEntries';
  static String auditLogsCollection(String orgId) =>
      'organizations/$orgId/auditLogs';
}
