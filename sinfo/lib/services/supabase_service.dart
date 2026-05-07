import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:nearby_service_app/models/driver.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';

class SupabaseService {
  final _supabase = Supabase.instance.client;

  Future<List<Driver>> getNearbyDrivers(double lon, double lat) async {
    try {
      final List<dynamic> data = await _supabase.rpc(
        'fetch_nearby_drivers',
        params: {
          'user_lon': lon,
          'user_lat': lat,
          'search_radius_meters': 5000,
        },
      );

      return data.map((json) => Driver.fromJson(json)).toList();
    } catch (e) {
      debugPrint('Error fetching drivers: $e');
      rethrow;
    }
  }

  Future<List<Driver>> searchDrivers(String query) async {
    try {
      final response = await _supabase
          .from('drivers')
          .select()
          .or('name.ilike.%$query%,number_plate.ilike.%$query%');
      
      final List<dynamic> data = response as List<dynamic>;
      return data.map((json) => Driver.fromJson(json)).toList();
    } catch (e) {
      debugPrint('Error searching drivers: $e');
      rethrow;
    }
  }

  Future<void> submitRating(String driverId, int stars, String rawPhone, {String? comment}) async {
    try {
      // SHA-256 Hashing for Privacy (DPDP Act Compliance)
      final bytes = utf8.encode(rawPhone);
      final hash = sha256.convert(bytes).toString();

      await _supabase.from('ratings').insert({
        'driver_id': driverId,
        'stars': stars,
        'user_phone_hash': hash,
        if (comment != null && comment.isNotEmpty) 'comment': comment,
      });
    } catch (e) {
      debugPrint('Error submitting rating: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> getUserRating(String driverId, String rawPhone) async {
    try {
      final bytes = utf8.encode(rawPhone);
      final hash = sha256.convert(bytes).toString();

      final response = await _supabase
          .from('ratings')
          .select()
          .eq('driver_id', driverId)
          .eq('user_phone_hash', hash)
          .maybeSingle();
      return response;
    } catch (e) {
      debugPrint('Error fetching user rating: $e');
      return null;
    }
  }

  Future<void> updateRating(String driverId, int stars, String rawPhone, {String? comment}) async {
    try {
      final bytes = utf8.encode(rawPhone);
      final hash = sha256.convert(bytes).toString();

      await _supabase.from('ratings').update({
        'stars': stars,
        if (comment != null && comment.isNotEmpty) 'comment': comment,
      }).eq('driver_id', driverId).eq('user_phone_hash', hash);
    } catch (e) {
      debugPrint('Error updating rating: $e');
      rethrow;
    }
  }

  Future<void> deleteRating(String driverId, String rawPhone) async {
    try {
      final bytes = utf8.encode(rawPhone);
      final hash = sha256.convert(bytes).toString();

      await _supabase
          .from('ratings')
          .delete()
          .eq('driver_id', driverId)
          .eq('user_phone_hash', hash);
    } catch (e) {
      debugPrint('Error deleting rating: $e');
      rethrow;
    }
  }

  Future<void> deleteUserAccount() async {
    try {
      await _supabase.rpc('delete_user_account');
      await _supabase.auth.signOut();
    } catch (e) {
      debugPrint('Error deleting user account: $e');
      rethrow;
    }
  }

  Future<void> registerDriver({
    required String name,
    required String phone,
    required String numberPlate,
    required double lat,
    required double lon,
    String? profileUrl,
  }) async {
    try {
      await _supabase.from('drivers').insert({
        'name': name,
        'phone': phone,
        'number_plate': numberPlate,
        'location': 'POINT($lon $lat)',
        'profile_url': profileUrl,
        'verified': true, // Auto-verify for now as per MVP simplicity
        'available': true,
      });
    } catch (e) {
      debugPrint('Error registering driver: $e');
      rethrow;
    }
  }
}
