import 'dart:developer';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../common_imports.dart';
import '../constants/constant_text.dart';

enum LocalSaveType {
  isLoggedIn,
  name,
  mobileNumber,
  role,
  otp,
  userid
}

class LocalStorages {
  static SharedPreferences? _prefs;

  /// INITIALIZE THE SHARED PREFERENCE STATE
  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  /// SAVE THE USER DATA
  static dynamic saveUserData({
    required LocalSaveType localSaveType,
    required dynamic value,
  }) {
    dynamic val =
        value ?? (localSaveType == LocalSaveType.isLoggedIn ? false : '');

    log("local save $localSaveType and $val");

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
    }
  }

  /// GET IS LOGGED IN
  static bool getIsLoggedIn(bool) =>
      _prefs?.getBool(ShareKey.isLoggedIn) ?? false;

  /// GET NAME
  static String getName() =>
      _prefs?.getString(ShareKey.name) ?? Constants.empty;

  /// GET MOBILE NUMBER
  static String getMobileNumber() =>
      _prefs?.getString(ShareKey.mobileNumber) ?? Constants.empty;

  /// GET ROLE
  static String getRole() =>
      _prefs?.getString(ShareKey.role) ?? Constants.empty;

  /// GET OTP
  static String getOtp() =>
      _prefs?.getString(ShareKey.otp) ?? Constants.empty;

  /// GET USER ID (as int)
  static int getUserId() =>
      _prefs?.getInt(ShareKey.userId) ?? 0;

  /// LOG OUT USER
  static Future<void> logOutUser() async {
    _prefs?.setBool(ShareKey.isLoggedIn, false);
    _prefs?.setString(ShareKey.name, Constants.empty);
    _prefs?.setString(ShareKey.mobileNumber, Constants.empty);
    _prefs?.setString(ShareKey.role, Constants.empty);
    _prefs?.setString(ShareKey.otp, Constants.empty);
    _prefs?.setInt(ShareKey.userId, 0);
    _prefs?.clear();
  }
}

class ShareKey {
  static String isLoggedIn = "isloggedin";
  static String name = "name";
  static String mobileNumber = "mobile_number";
  static String role = "role";
  static String userId = "userid";
  static String otp = "otp";
}
