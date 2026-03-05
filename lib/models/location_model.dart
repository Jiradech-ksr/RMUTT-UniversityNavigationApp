import 'api_constants.dart';

class Location {
  final int id;
  final String name;
  final String type;
  final double latitude;
  final double longitude;
  final String? departmentName;
  final String? imageUrl;
  final String? roomNumber;
  final int? floor;
  final String? floorLayoutUrl;

  Location({
    required this.id,
    required this.name,
    required this.type,
    required this.latitude,
    required this.longitude,
    this.departmentName,
    this.imageUrl,
    this.roomNumber,
    this.floor,
    this.floorLayoutUrl,
  });

  factory Location.fromJson(Map<String, dynamic> json) {
    // 1. Process Image URL
    String? rawImageUrl = json['image_url'];
    String? fullImageUrl;
    if (rawImageUrl != null && rawImageUrl.isNotEmpty) {
      fullImageUrl = rawImageUrl.startsWith('http')
          ? rawImageUrl // Fallback for old test data
          : '${ApiConstants.baseAppUrl}/$rawImageUrl';
    }

    // 2. Process Layout URL
    String? rawLayoutUrl = json['floor_layout_url'];
    String? fullLayoutUrl;
    if (rawLayoutUrl != null && rawLayoutUrl.isNotEmpty) {
      fullLayoutUrl = rawLayoutUrl.startsWith('http')
          ? rawLayoutUrl
          : '${ApiConstants.baseAppUrl}/$rawLayoutUrl';
    }

    return Location(
      id: int.parse(json['id'].toString()),
      name: json['name'] ?? 'Unknown',
      type: json['type'] ?? 'Unknown',
      latitude: double.tryParse(json['latitude'].toString()) ?? 0.0,
      longitude: double.tryParse(json['longitude'].toString()) ?? 0.0,
      departmentName: json['department_name'] ?? json['building_name'],
      imageUrl: fullImageUrl, // Use the processed URL
      roomNumber: json['room_number'],
      floor: json['floor'] != null
          ? int.tryParse(json['floor'].toString())
          : null,
      floorLayoutUrl: fullLayoutUrl, // Use the processed URL
    );
  }
}
