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
    return Location(
      id: int.parse(json['id'].toString()),
      name: json['name'] ?? 'Unknown',
      type: json['type'] ?? 'Unknown',
      latitude: double.tryParse(json['latitude'].toString()) ?? 0.0,
      longitude: double.tryParse(json['longitude'].toString()) ?? 0.0,
      departmentName: json['department_name'] ?? json['building_name'],
      imageUrl: json['image_url'],
      roomNumber: json['room_number'],
      floor: json['floor'] != null
          ? int.tryParse(json['floor'].toString())
          : null,
      floorLayoutUrl: json['floor_layout_url'],
    );
  }
}
