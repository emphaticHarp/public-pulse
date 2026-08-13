class LocationSuggestion {
  final String name;
  final String formattedAddress;
  final double latitude;
  final double longitude;

  const LocationSuggestion({
    required this.name,
    required this.formattedAddress,
    required this.latitude,
    required this.longitude,
  });

  factory LocationSuggestion.fromGeoapify(Map<String, dynamic> json) {
    final formatted = json['formatted']?.toString().trim() ?? '';

    final name =
        json['name']?.toString().trim() ??
        json['city']?.toString().trim() ??
        json['locality']?.toString().trim() ??
        formatted;

    return LocationSuggestion(
      name: name.isEmpty ? formatted : name,
      formattedAddress: formatted,
      latitude: (json['lat'] as num?)?.toDouble() ?? 0,
      longitude: (json['lon'] as num?)?.toDouble() ?? 0,
    );
  }
}
