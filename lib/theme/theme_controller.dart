import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeController extends GetxController with WidgetsBindingObserver {
  static ThemeController get instance => Get.find<ThemeController>();
  static const String _themePrefKey = 'user_theme_mode';

  final _themeMode = ThemeMode.light.obs;
  ThemeMode get themeMode => _themeMode.value;

  final _platformBrightness =
      WidgetsBinding.instance.platformDispatcher.platformBrightness.obs;

  bool get isDarkMode => _themeMode.value == ThemeMode.dark;

  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addObserver(this);
    _loadThemeFromPrefs();
  }

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);
    super.onClose();
  }

  @override
  void didChangePlatformBrightness() {
    _platformBrightness.value =
        WidgetsBinding.instance.platformDispatcher.platformBrightness;
    _updateSystemUi();
  }

  void _loadThemeFromPrefs() {
    if (Get.isRegistered<SharedPreferences>()) {
      final prefs = Get.find<SharedPreferences>();
      final savedMode = prefs.getString(_themePrefKey);
      if (savedMode == 'dark') {
        _themeMode.value = ThemeMode.dark;
      } else {
        _themeMode.value = ThemeMode.light;
      }
    } else {
      _themeMode.value = ThemeMode.light;
    }
    _updateSystemUi();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode.value = mode;
    Get.changeThemeMode(mode);
    if (Get.isRegistered<SharedPreferences>()) {
      final prefs = Get.find<SharedPreferences>();
      await prefs.setString(_themePrefKey, mode.name);
    }
    _updateSystemUi();
  }

  Future<void> toggleTheme() async {
    await setThemeMode(isDarkMode ? ThemeMode.light : ThemeMode.dark);
  }

  void _updateSystemUi() {
    final dark = isDarkMode;
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: dark ? Brightness.light : Brightness.dark,
        statusBarBrightness: dark ? Brightness.dark : Brightness.light,
        systemNavigationBarColor:
            dark ? Colors.black : const Color(0xFFF8FAFC),
        systemNavigationBarIconBrightness:
            dark ? Brightness.light : Brightness.dark,
      ),
    );
  }
}

