import 'api_constants.dart';

// Simple global class to manage language state
class AppLanguage {
  static String current =
      'TH'; // Change this to 'EN' to switch the app's data language!
}

class Location {
  final int id;
  final String nameEn;
  final String nameTh;
  final String type;
  final double latitude;
  final double longitude;
  final String? departmentNameEn;
  final String? departmentNameTh;
  final String? imageUrl;
  final String? roomNumber;
  final int? floor;
  final String? floorLayoutUrl;
  final String? buildingImageUrl;

  Location({
    required this.id,
    required this.nameEn,
    required this.nameTh,
    required this.type,
    required this.latitude,
    required this.longitude,
    this.departmentNameEn,
    this.departmentNameTh,
    this.imageUrl,
    this.roomNumber,
    this.floor,
    this.floorLayoutUrl,
    this.buildingImageUrl,
  });

  // Smart getter that returns the correct language automatically
  String get localizedName => AppLanguage.current == 'TH' ? nameTh : nameEn;

  String get localizedDepartment => AppLanguage.current == 'TH'
      ? (departmentNameTh ?? 'ไม่ระบุ')
      : (departmentNameEn ?? 'Unknown');

  factory Location.fromJson(Map<String, dynamic> json) {
    String? rawImageUrl = json['image_url'];
    String? fullImageUrl;
    if (rawImageUrl != null && rawImageUrl.isNotEmpty) {
      fullImageUrl = rawImageUrl.startsWith('http')
          ? rawImageUrl
          : '${ApiConstants.baseAppUrl}/$rawImageUrl';
    }

    String? rawLayoutUrl = json['floor_layout_url'];
    String? fullLayoutUrl;
    if (rawLayoutUrl != null && rawLayoutUrl.isNotEmpty) {
      fullLayoutUrl = rawLayoutUrl.startsWith('http')
          ? rawLayoutUrl
          : '${ApiConstants.baseAppUrl}/$rawLayoutUrl';
    }

    String? rawBuildingImageUrl = json['building_image_url'];
    String? fullBuildingImageUrl;
    if (rawBuildingImageUrl != null && rawBuildingImageUrl.isNotEmpty) {
      fullBuildingImageUrl = rawBuildingImageUrl.startsWith('http')
          ? rawBuildingImageUrl
          : '${ApiConstants.baseAppUrl}/$rawBuildingImageUrl';
    }

    return Location(
      id: int.parse(json['id'].toString()),
      // Note: check for name_en OR title_en depending on which API is calling this
      nameEn: json['name_en'] ?? json['title_en'] ?? 'Unknown',
      nameTh: json['name_th'] ?? json['title_th'] ?? 'ไม่ระบุ',
      type: json['type'] ?? 'Unknown',
      latitude: double.tryParse(json['latitude'].toString()) ?? 0.0,
      longitude: double.tryParse(json['longitude'].toString()) ?? 0.0,
      departmentNameEn: json['department_name_en'] ?? json['building_name_en'],
      departmentNameTh: json['department_name_th'] ?? json['building_name_th'],
      imageUrl: fullImageUrl,
      roomNumber: json['room_number']?.toString(),
      floor: json['floor'] != null
          ? int.tryParse(json['floor'].toString())
          : null,
      floorLayoutUrl: fullLayoutUrl,
      buildingImageUrl: fullBuildingImageUrl,
    );
  }
}
