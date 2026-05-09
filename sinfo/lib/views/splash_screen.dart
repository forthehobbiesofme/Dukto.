import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:nearby_service_app/views/landing_screen.dart';
import 'package:nearby_service_app/views/home_screen.dart';
import 'package:nearby_service_app/providers/auth_provider.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _initAndNavigate();
  }

  Future<void> _initAndNavigate() async {
    // 1. Initialize Supabase in background
    try {
      await Supabase.initialize(
        url: 'https://vhcfrwyyytmqxihbfiue.supabase.co',
        anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZoY2Zyd3l5eXRtcXhpaGJmaXVlIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzY5MjY1OTEsImV4cCI6MjA5MjUwMjU5MX0.bpjkEU1rnTtVMV6dH3c08BPgmuxvFMZWFvxq0irDCp0',
      );
    } catch (e) {
      debugPrint('Supabase init error: $e');
    }

    // 2. Wait for a minimum time for branding
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    // 3. Wait for local session via authProvider to load
    await ref.read(authProvider.notifier).initialized;

    if (!mounted) return;

    final auth = ref.read(authProvider);
    
    // Check both local auth and Supabase JWT
    final hasSupabaseSession = Supabase.instance.client.auth.currentSession != null;
    
    if (auth.isLoggedIn || hasSupabaseSession) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LandingScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // Standardize to white as per new design language
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFF2BC5C).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.location_on,
                size: 80,
                color: Color(0xFFF2BC5C),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'AutoConnect',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFFF2BC5C),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
