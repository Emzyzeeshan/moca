// ignore_for_file: use_build_context_synchronously

import 'package:mocadb/src/core/utils/shared_preference.dart';

import '../../../common_imports.dart';
import '../../features/dashboard/ui/dashboard_screen.dart';
import '../../features/login/login_index.dart';

class NavigateRoutes {
  /// Define a global key for the navigator
  static GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  /// Navigate to Dashboard or Login based on user login status
  static dynamic navigateTo() {
    bool isLoggedIn = LocalStorages.getIsLoggedIn(true); // Check login status

    if (!isLoggedIn) {
      return navigateToLoginScreen(); // If logged out, go to login
    }

    return Navigator.push(
      navigatorKey.currentContext!,
      MaterialPageRoute<Widget>(builder: (_) => const DashboardScreen()),
    );
  }

  /// Navigate to Login Screen (Handles Logout Properly)
  static dynamic navigateToLoginScreen({bool isLogoutTap = false}) async {
    if (isLogoutTap) {
      await LocalStorages.logOutUser(); // Clear stored user data
      return Navigator.pushAndRemoveUntil(
        navigatorKey.currentContext!,
        MaterialPageRoute<Widget>(builder: (_) => const LoginScreenWidget()),
            (Route<dynamic> route) => false,
      );
    }

    return Timer(
      const Duration(seconds: 5),
          () => Navigator.pushAndRemoveUntil(
        navigatorKey.currentContext!,
        MaterialPageRoute<Widget>(builder: (_) => const LoginScreenWidget()),
            (Route<dynamic> route) => false,
      ),
    );
  }

  static Future<Widget?> navigatePush(
      {required Widget widget, BuildContext? context}) {
    return Navigator.push(
      context ?? navigatorKey.currentContext!,
      MaterialPageRoute<Widget>(builder: (_) => widget),
    );
  }

  static void navigatePop({BuildContext? context}) {
    return Navigator.pop(context ?? navigatorKey.currentContext!);
  }
}
