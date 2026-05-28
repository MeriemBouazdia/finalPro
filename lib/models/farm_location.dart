class FarmLocation {
  const FarmLocation({
    required this.latitude,
    required this.longitude,
    required this.locationName,
  });

  final double latitude;
  final double longitude;
  final String locationName;

  Map<String, dynamic> toMap() => {
        'lat': latitude,
        'lng': longitude,
        'locationName': locationName,
      };

  Map<String, dynamic> toJson() => toMap();
}
