class ApiConstants {
  static const String baseUrl =
      'https://qohst-2403-6200-88a2-a177-cda8-1a1f-b1d4-9707.a.free.pinggy.link/UniversityNavigationWebApp/api';

  /// The base URL of the web server (without 'api' at the end)
  static String get baseAppUrl => baseUrl.replaceAll(RegExp(r'/api/?$'), '');

  static const String authUser = '$baseUrl/auth_user.php';
  static const String hierarchy = '$baseUrl/get_hierarchy.php';
  static const String favorites = '$baseUrl/get_favorites.php';
  static const String toggleFavorite = '$baseUrl/toggle_favorite.php';
  static const String checkFavorite = '$baseUrl/check_favorite.php';
  static const String addHistory = '$baseUrl/add_history.php';
  static const String getHistory = '$baseUrl/get_history.php';
  static const String clearHistory = '$baseUrl/clear_history.php';
  static const String reportIssue = '$baseUrl/report_issue.php';
  static const String getUserStats = '$baseUrl/get_user_stats.php';
}
