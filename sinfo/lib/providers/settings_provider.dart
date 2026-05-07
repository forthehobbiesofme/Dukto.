import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final settingsProvider = StateNotifierProvider<SettingsNotifier, SettingsState>((ref) {
  return SettingsNotifier();
});

class SettingsState {
  final ThemeMode themeMode;
  final bool isMalayalam;

  SettingsState({
    required this.themeMode,
    required this.isMalayalam,
  });

  SettingsState copyWith({
    ThemeMode? themeMode,
    bool? isMalayalam,
  }) {
    return SettingsState(
      themeMode: themeMode ?? this.themeMode,
      isMalayalam: isMalayalam ?? this.isMalayalam,
    );
  }
}

class SettingsNotifier extends StateNotifier<SettingsState> {
  SettingsNotifier() : super(SettingsState(themeMode: ThemeMode.system, isMalayalam: false)) {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final isDark = prefs.getBool('isDarkMode');
    final isMal = prefs.getBool('isMalayalam') ?? false;

    ThemeMode mode = ThemeMode.system;
    if (isDark != null) {
      mode = isDark ? ThemeMode.dark : ThemeMode.light;
    }

    state = state.copyWith(themeMode: mode, isMalayalam: isMal);
  }

  Future<void> setTheme(ThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    if (mode == ThemeMode.dark) {
      await prefs.setBool('isDarkMode', true);
    } else if (mode == ThemeMode.light) {
      await prefs.setBool('isDarkMode', false);
    } else {
      await prefs.remove('isDarkMode');
    }
    state = state.copyWith(themeMode: mode);
  }

  Future<void> setLanguage(bool isMalayalam) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isMalayalam', isMalayalam);
    state = state.copyWith(isMalayalam: isMalayalam);
  }

  String translate(String englishText) {
    if (!state.isMalayalam) return englishText;

    // Simple dictionary for translations
    const Map<String, String> translations = {
      'AutoConnect': 'ഓട്ടോ കണക്റ്റ്',
      'showing nearby result': 'അടുത്തുള്ള ഡ്രൈവർമാർ',
      'Tap the button below to find autos near you.': 'നിങ്ങൾക്ക് അടുത്തുള്ള ഓട്ടോകൾ കണ്ടെത്താൻ താഴെ ടാപ്പുചെയ്യുക.',
      'Find Nearby Autos': 'അടുത്തുള്ള ഓട്ടോകൾ കണ്ടെത്തുക',
      'No drivers found within 5km': '5 കിലോമീറ്ററിനുള്ളിൽ ഡ്രൈവർമാരെ കണ്ടെത്തിയില്ല',
      'Settings': 'ക്രമീകരണങ്ങൾ',
      'Language': 'ഭാഷ',
      'English': 'English',
      'Malayalam': 'മലയാളം',
      'Theme': 'തീം',
      'Dark Mode': 'ഡാർക്ക് മോഡ്',
      'Light Mode': 'ലൈറ്റ് മോഡ്',
      'System': 'സിസ്റ്റം',
      'My Details': 'എന്റെ വിവരങ്ങൾ',
      'Logout / Delete Account': 'ലോഗ്ഔട്ട് / അക്കൗണ്ട് ഇല്ലാതാക്കുക',
      'Are you sure you want to logout and delete your account?': 'ലോഗ്ഔട്ട് ചെയ്ത് അക്കൗണ്ട് ഇല്ലാതാക്കാൻ ഉറപ്പാണോ?',
      'Cancel': 'റദ്ദാക്കുക',
      'Confirm': 'ഉറപ്പാക്കുക',
      'message': 'സന്ദേശം',
      'Call': 'വിളിക്കുക',
      'rate': 'റേറ്റ്',
      'Rate your experience.....': 'നിങ്ങളുടെ അനുഭവം റേറ്റ് ചെയ്യുക.....',
      'type something..': 'എന്തെങ്കിലും ടൈപ്പ് ചെയ്യുക..',
      'Done': 'പൂർത്തിയായി',
    };

    return translations[englishText] ?? englishText;
  }
}
