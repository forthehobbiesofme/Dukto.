import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});

class AuthState {
  final bool isLoggedIn;
  final String role; // 'user' or 'driver'
  final String name;
  final String phone;
  final String? numberPlate;
  final String? autoName;
  final String? profileImageUrl;

  AuthState({
    this.isLoggedIn = false,
    this.role = '',
    this.name = '',
    this.phone = '',
    this.numberPlate,
    this.autoName,
    this.profileImageUrl,
  });

  AuthState copyWith({
    bool? isLoggedIn,
    String? role,
    String? name,
    String? phone,
    String? numberPlate,
    String? autoName,
    String? profileImageUrl,
  }) {
    return AuthState(
      isLoggedIn: isLoggedIn ?? this.isLoggedIn,
      role: role ?? this.role,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      numberPlate: numberPlate ?? this.numberPlate,
      autoName: autoName ?? this.autoName,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final Completer<void> _initCompleter = Completer<void>();
  Future<void> get initialized => _initCompleter.future;

  AuthNotifier() : super(AuthState()) {
    _loadSession();
  }

  Future<void> _loadSession() async {
    final prefs = await SharedPreferences.getInstance();
    final isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
    if (isLoggedIn) {
      state = AuthState(
        isLoggedIn: true,
        role: prefs.getString('role') ?? 'user',
        name: prefs.getString('name') ?? '',
        phone: prefs.getString('phone') ?? '',
        numberPlate: prefs.getString('numberPlate'),
        autoName: prefs.getString('autoName'),
        profileImageUrl: prefs.getString('profileImageUrl'),
      );
    }
    _initCompleter.complete();
  }

  Future<void> saveSession({
    required String role,
    required String name,
    required String phone,
    String? numberPlate,
    String? autoName,
    String? profileImageUrl,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', true);
    await prefs.setString('role', role);
    await prefs.setString('name', name);
    await prefs.setString('phone', phone);
    if (numberPlate != null) await prefs.setString('numberPlate', numberPlate);
    if (autoName != null) await prefs.setString('autoName', autoName);
    if (profileImageUrl != null) {
      await prefs.setString('profileImageUrl', profileImageUrl);
    }

    // 1. Sign in anonymously to Supabase to get a JWT session
    try {
      final authResponse = await Supabase.instance.client.auth.signInAnonymously();
      if (authResponse.session != null) {
        // 2. If driver, register in the drivers table
        if (role == 'driver') {
          await Supabase.instance.client.from('drivers').upsert({
            'id': authResponse.user!.id,
            'name': name,
            'phone': phone,
            'number_plate': numberPlate,
            'auto_name': autoName,
            'profile_url': profileImageUrl,
            'location': 'POINT(75.7804 11.2588)', // Default to demo location for now
            'verified': true,
            'available': true,
          });
        }
        // Also could save user metadata if needed
        await Supabase.instance.client.auth.updateUser(
          UserAttributes(
            data: {
              'display_name': name,
              'phone': phone,
              'role': role,
            },
          ),
        );
      }
    } catch (e) {
      print('Supabase registration error: $e');
    }

    state = AuthState(
      isLoggedIn: true,
      role: role,
      name: name,
      phone: phone,
      numberPlate: numberPlate,
      autoName: autoName,
      profileImageUrl: profileImageUrl,
    );
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('isLoggedIn');
    await prefs.remove('role');
    await prefs.remove('name');
    await prefs.remove('phone');
    await prefs.remove('numberPlate');
    await prefs.remove('autoName');
    await prefs.remove('profileImageUrl');
    try {
      await Supabase.instance.client.rpc('delete_user_account');
      await Supabase.instance.client.auth.signOut();
    } catch (_) {}
    state = AuthState();
  }
}
