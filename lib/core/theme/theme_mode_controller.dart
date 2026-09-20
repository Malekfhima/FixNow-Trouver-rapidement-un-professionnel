import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// App theme mode: system / light / dark (persisted in SharedPreferences).
enum AppThemeMode { system, light, dark }

class ThemeModeState {
  final AppThemeMode mode;
  final bool loaded;

  const ThemeModeState({
    this.mode = AppThemeMode.system,
    this.loaded = false,
  });

  ThemeModeState copyWith({AppThemeMode? mode, bool? loaded}) {
    return ThemeModeState(
      mode: mode ?? this.mode,
      loaded: loaded ?? this.loaded,
    );
  }

  /// Material [ThemeMode] equivalent for MaterialApp.
  ThemeMode get materialThemeMode {
    switch (mode) {
      case AppThemeMode.system:
        return ThemeMode.system;
      case AppThemeMode.light:
        return ThemeMode.light;
      case AppThemeMode.dark:
        return ThemeMode.dark;
    }
  }
}

/// Loads the persisted theme mode once at startup.
class ThemeModeController extends StateNotifier<ThemeModeState> {
  static const _prefKey = 'appThemeMode';

  ThemeModeController() : super(const ThemeModeState()) {
    _load();
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final stored = prefs.getString(_prefKey);
      final mode = AppThemeMode.values.firstWhere(
        (m) => m.name == stored,
        orElse: () => AppThemeMode.system,
      );
      state = state.copyWith(mode: mode, loaded: true);
    } catch (_) {
      state = state.copyWith(loaded: true);
    }
  }

  Future<void> setMode(AppThemeMode mode) async {
    state = state.copyWith(mode: mode);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefKey, mode.name);
    } catch (_) {
      // Persistence failure: keep the in-memory selection.
    }
  }

  /// Material [ThemeMode] equivalent for MaterialApp.
  ThemeMode get materialThemeMode => state.materialThemeMode;
}

final themeModeControllerProvider =
    StateNotifierProvider<ThemeModeController, ThemeModeState>(
  (ref) => ThemeModeController(),
);
