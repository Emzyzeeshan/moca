import 'dart:developer';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../common_imports.dart';
import '../constants/constant_text.dart';

/// Enum to define keys used in shared preferences
enum LocalSaveType {
  isLoggedIn,
  name,
  mobileNumber,
  role,
  otp,
  userid,
  isAirportDataLoaded, // ✅ New key added
}

class LocalStorages {
  static SharedPreferences? _prefs;

  /// Initialize the shared preferences
  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  /// Save user data or flags to local storage
  static dynamic saveUserData({
    required LocalSaveType localSaveType,
    required dynamic value,
  }) {
    dynamic val =
        value ?? (localSaveType == LocalSaveType.isLoggedIn ? false : '');

    log("Saving to local: $localSaveType = $val");

    switch (localSaveType) {
      case LocalSaveType.isLoggedIn:
        _prefs?.setBool(ShareKey.isLoggedIn, val);
        break;
      case LocalSaveType.name:
        _prefs?.setString(ShareKey.name, val);
        break;
      case LocalSaveType.mobileNumber:
        _prefs?.setString(ShareKey.mobileNumber, val);
        break;
      case LocalSaveType.role:
        _prefs?.setString(ShareKey.role, val);
        break;
      case LocalSaveType.otp:
        _prefs?.setString(ShareKey.otp, val);
        break;
      case LocalSaveType.userid:
        _prefs?.setInt(ShareKey.userId, val);
        break;
      case LocalSaveType.isAirportDataLoaded: // ✅ New case
        _prefs?.setBool(ShareKey.isAirportDataLoaded, val);
        break;
    }
  }

  /// Getters for shared preference values

  static bool getIsLoggedIn(bool) =>
      _prefs?.getBool(ShareKey.isLoggedIn) ?? false;

  static String getName() =>
      _prefs?.getString(ShareKey.name) ?? Constants.empty;

  static String getMobileNumber() =>
      _prefs?.getString(ShareKey.mobileNumber) ?? Constants.empty;

  static String getRole() =>
      _prefs?.getString(ShareKey.role) ?? Constants.empty;

  static String getOtp() =>
      _prefs?.getString(ShareKey.otp) ?? Constants.empty;

  static int getUserId() =>
      _prefs?.getInt(ShareKey.userId) ?? 0;

  static bool getIsAirportDataLoaded() => // ✅ New getter
  _prefs?.getBool(ShareKey.isAirportDataLoaded) ?? false;

  /// Clear all user data (logout)
  static Future<void> logOutUser() async {
    _prefs?.setBool(ShareKey.isLoggedIn, false);
    _prefs?.setString(ShareKey.name, Constants.empty);
    _prefs?.setString(ShareKey.mobileNumber, Constants.empty);
    _prefs?.setString(ShareKey.role, Constants.empty);
    _prefs?.setString(ShareKey.otp, Constants.empty);
    _prefs?.setInt(ShareKey.userId, 0);
    _prefs?.setBool(ShareKey.isAirportDataLoaded, false); // Reset on logout
    _prefs?.clear();
  }
}

/// Static keys used for storing data in SharedPreferences
class ShareKey {
  static String isLoggedIn = "is_logged_in";
  static String name = "name";
  static String mobileNumber = "mobile_number";
  static String role = "role";
  static String userId = "user_id";
  static String otp = "otp";
  static String isAirportDataLoaded = "is_airport_data_loaded"; // ✅ New key
}
