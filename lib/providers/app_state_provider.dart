import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/constants.dart';

class AppState {
  final ThemeMode themeMode;
  final bool isFirstLaunch;
  final bool hasPermissions;
  final double analysisSensitivity;
  final bool notificationsEnabled;
  final bool autoRecording;
  final bool isCallActive;
  final String? activeCallNumber;
  
  const AppState({
    this.themeMode = ThemeMode.system,
    this.isFirstLaunch = true,
    this.hasPermissions = false,
    this.analysisSensitivity = 0.7,
    this.notificationsEnabled = true,
    this.autoRecording = true,
    this.isCallActive = false,
    this.activeCallNumber,
  });
  
  AppState copyWith({
    ThemeMode? themeMode,
    bool? isFirstLaunch,
    bool? hasPermissions,
    double? analysisSensitivity,
    bool? notificationsEnabled,
    bool? autoRecording,
    bool? isCallActive,
    String? activeCallNumber,
  }) {
    return AppState(
      themeMode: themeMode ?? this.themeMode,
      isFirstLaunch: isFirstLaunch ?? this.isFirstLaunch,
      hasPermissions: hasPermissions ?? this.hasPermissions,
      analysisSensitivity: analysisSensitivity ?? this.analysisSensitivity,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      autoRecording: autoRecording ?? this.autoRecording,
      isCallActive: isCallActive ?? this.isCallActive,
      activeCallNumber: activeCallNumber ?? this.activeCallNumber,
    );
  }
}

class AppStateNotifier extends StateNotifier<AppState> {
  AppStateNotifier() : super(const AppState()) {
    _loadState();
  }
  
  Future<void> _loadState() async {
    final prefs = await SharedPreferences.getInstance();
    
    final themeModeIndex = prefs.getInt(AppConstants.prefsKeyThemeMode) ?? 0;
    final themeMode = ThemeMode.values[themeModeIndex];
    
    final analysisSensitivity = prefs.getDouble(AppConstants.prefsKeyAnalysisSensitivity) ?? 0.7;
    final notificationsEnabled = prefs.getBool(AppConstants.prefsKeyNotificationsEnabled) ?? true;
    final autoRecording = prefs.getBool(AppConstants.prefsKeyAutoRecording) ?? true;
    final isFirstLaunch = prefs.getBool('is_first_launch') ?? true;
    
    state = state.copyWith(
      themeMode: themeMode,
      analysisSensitivity: analysisSensitivity,
      notificationsEnabled: notificationsEnabled,
      autoRecording: autoRecording,
      isFirstLaunch: isFirstLaunch,
    );
  }
  
  Future<void> setThemeMode(ThemeMode themeMode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(AppConstants.prefsKeyThemeMode, themeMode.index);
    state = state.copyWith(themeMode: themeMode);
  }
  
  Future<void> setAnalysisSensitivity(double sensitivity) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(AppConstants.prefsKeyAnalysisSensitivity, sensitivity);
    state = state.copyWith(analysisSensitivity: sensitivity);
  }
  
  Future<void> setNotificationsEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.prefsKeyNotificationsEnabled, enabled);
    state = state.copyWith(notificationsEnabled: enabled);
  }
  
  Future<void> setAutoRecording(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.prefsKeyAutoRecording, enabled);
    state = state.copyWith(autoRecording: enabled);
  }
  
  Future<void> setFirstLaunchComplete() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_first_launch', false);
    state = state.copyWith(isFirstLaunch: false);
  }
  
  void setPermissionsGranted(bool granted) {
    state = state.copyWith(hasPermissions: granted);
  }
  
  void setCallActive(bool active, [String? phoneNumber]) {
    state = state.copyWith(
      isCallActive: active,
      activeCallNumber: active ? phoneNumber : null,
    );
  }
}

final appStateProvider = StateNotifierProvider<AppStateNotifier, AppState>((ref) {
  return AppStateNotifier();
});