import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:nearby_service_app/models/driver.dart';
import 'package:nearby_service_app/services/supabase_service.dart';

final supabaseServiceProvider = Provider((ref) => SupabaseService());

final nearbyDriversProvider = FutureProvider<List<Driver>>((ref) async {
  final supabaseService = ref.watch(supabaseServiceProvider);
  
  List<Driver> drivers = [];

  try {
    // 1. Get current location (Ephemeral - only in memory)
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) throw Exception('Location services are disabled.');

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) throw Exception('Location permissions are denied');
    }
    
    if (permission == LocationPermission.deniedForever) {
      throw Exception('Location permissions are permanently denied');
    }

    await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);

    // DEMO MODE: Override with fake location (Kozhikode) to test the 4 profiles
    const double demoLatitude = 11.2588;
    const double demoLongitude = 75.7804;

    // 2. Fetch nearby drivers from Supabase using demo location
    drivers = await supabaseService.getNearbyDrivers(demoLongitude, demoLatitude);
  } catch (e) {
    debugPrint('Location/Fetch error, falling back to dummy profiles: $e');
  }

  // 3. Always show three dummy driver profiles no matter the location
  final dummyDrivers = [
    Driver(
      id: 'dummy-1',
      name: 'Dummy Driver 1',
      phone: '+919999999991',
      autoName: 'Demo Auto',
      numberPlate: 'KL-01-D-0001',
      avgRating: 4.8,
      totalRatings: 120,
      available: true,
      distanceMeters: 500,
    ),
    Driver(
      id: 'dummy-2',
      name: 'Dummy Driver 2',
      phone: '+919999999992',
      autoName: 'Speedy Auto',
      numberPlate: 'KL-01-D-0002',
      avgRating: 4.5,
      totalRatings: 85,
      available: true,
      distanceMeters: 1200,
    ),
    Driver(
      id: 'dummy-3',
      name: 'Dummy Driver 3',
      phone: '+919999999993',
      autoName: 'Safe Ride Auto',
      numberPlate: 'KL-01-D-0003',
      avgRating: 5.0,
      totalRatings: 42,
      available: true,
      distanceMeters: 2500,
    ),
  ];

  // Combine real drivers (if any) with dummy drivers
  return [...drivers, ...dummyDrivers];
});

