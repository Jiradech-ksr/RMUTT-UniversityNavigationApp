import 'api_constants.dart';

// Simple global class to manage language state
class AppLanguage {
  static String current =
      'TH'; // Change this to 'EN' to switch the app's data language!
}

class Location {
  final int id; // ไอดีของสถานที่ (Identifier)
  final String nameEn; // ชื่อสถานที่ (ภาษาอังกฤษ)
  final String nameTh; // ชื่อสถานที่ (ภาษาไทย)
  final String type; // ประเภทของสถานที่ (เช่น อาคาร, ห้อง)
  final double latitude; // พิกัดละติจูด (Latitude) แนวนอน
  final double longitude; // พิกัดลองจิจูด (Longitude) แนวตั้ง
  final String? departmentNameEn; // ชื่อคณะหรือภาควิชา (ภาษาอังกฤษ)
  final String? departmentNameTh; // ชื่อคณะหรือภาควิชา (ภาษาไทย)
  final String? imageUrl; // ลิงก์รูปภาพของสถานที่หรือห้อง
  final String? roomNumber; // หมายเลขห้อง (สำหรับห้อง)
  final int? floor; // ชั้นของอาคาร
  final String? floorLayoutUrl; // ลิงก์รูปภาพแผนผังชั้น
  final String? buildingImageUrl; // ลิงก์รูปภาพอาคารโดยรวม
  final String? details; // รายละเอียดเพิ่มเติมของสถานที่
  final String? responsibleEmail; // อีเมลของผู้รับผิดชอบสถานที่นี้

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
    this.details,
    this.responsibleEmail,
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
      details: json['details']?.toString(),
      responsibleEmail: json['responsible_email']?.toString(),
    );
  }
}
