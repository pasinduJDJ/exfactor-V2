
class AppConstants {
  // App Info
  static const String appName = 'Exfactor';
  static const String appVersion = '1.0.0';

  // API Endpoints
  static const String baseUrl = 'YOUR_BASE_URL';

  // Storage Keys
  static const String tokenKey = 'auth_token';
  static const String userTypeKey = 'user_type';

  // Dimensions
  static const double defaultPadding = 16.0;
  static const double defaultRadius = 12.0;
  static const double defaultSpacing = 8.0;

  // Animation Durations
  static const Duration defaultAnimationDuration = Duration(milliseconds: 300);

  // Screen Breakpoints
  static const double mobileBreakpoint = 480;
  static const double tabletBreakpoint = 768;
  static const double desktopBreakpoint = 1024;
}

class AppAssets {
  // Images
  static const String logo = 'assets/images/logo.png';
  static const String placeholder = 'assets/images/placeholder.png';

  // Icons
  static const String homeIcon = 'assets/icons/home.png';
  static const String profileIcon = 'assets/icons/profile.png';
}

class AppStrings {
  // Common
  static const String ok = 'OK';
  static const String cancel = 'Cancel';
  static const String error = 'Error';
  static const String success = 'Success';
  static const String loading = 'Loading...';

  // Auth
  static const String login = 'Login';
  static const String logout = 'Logout';
  static const String email = 'Email';
  static const String password = 'Password';
  static const String forgotPassword = 'Forgot Password?';

  // Validation Messages
  static const String requiredField = 'This field is required';
  static const String invalidEmail = 'Please enter a valid email';
  static const String invalidPassword =
      'Password must be at least 6 characters';
}
