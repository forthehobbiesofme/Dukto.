class Driver {
  final String id;
  final String name;
  final String phone;
  final String? autoName;
  final String numberPlate;
  final double avgRating;
  final int totalRatings;
  final bool available;
  final double? distanceMeters;
  final String? profileUrl;

  Driver({
    required this.id,
    required this.name,
    required this.phone,
    this.autoName,
    required this.numberPlate,
    required this.avgRating,
    required this.totalRatings,
    required this.available,
    this.distanceMeters,
    this.profileUrl,
  });

  factory Driver.fromJson(Map<String, dynamic> json) {
    return Driver(
      id: json['id'],
      name: json['name'],
      phone: json['phone'],
      autoName: json['auto_name'],
      numberPlate: json['number_plate'],
      avgRating: _parseDouble(json['avg_rating']),
      totalRatings: json['total_ratings'] ?? 0,
      available: json['available'] ?? true,
      distanceMeters: _parseDouble(json['distance_meters']),
      profileUrl: json['profile_url'],
    );
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }
}
