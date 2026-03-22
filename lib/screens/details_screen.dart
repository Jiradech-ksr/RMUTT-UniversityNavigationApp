import 'package:rmutt_navigation_app/models/api_constants.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'report_screen.dart';
import '../models/location_model.dart';
import '../services/map_utils.dart';
import '../services/history_service.dart';
import '../services/user_session.dart';

class DetailsScreen extends StatefulWidget {
  final Location? location;

  const DetailsScreen({super.key, this.location});

  @override
  State<DetailsScreen> createState() => _DetailsScreenState();
}

class _DetailsScreenState extends State<DetailsScreen> {
  bool isFavorite = false;
  bool isLoading = false;

  // สร้างตัวแปรดึง Base URL ของ Server (ตัด /api ด้านหลังออก)
  String get serverUrl {
    return ApiConstants.baseAppUrl;
  }

  @override
  void initState() {
    super.initState();
    _checkIfFavorite();
    
    // Automatic Room Visit Recording
    if (widget.location != null && widget.location!.type.toLowerCase() == 'room') {
      HistoryService.addToHistory(widget.location!);
    }
  }

  Future<void> _checkIfFavorite() async {
    if (widget.location == null) return;
    if (await UserSession.isGuest()) return;

    final String? email = await UserSession.getEmail();
    if (email == null) return;

    try {
      final response = await http.post(
        Uri.parse(ApiConstants.checkFavorite),
        body: {'email': email, 'room_id': widget.location!.id.toString()},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (mounted) {
          setState(() {
            isFavorite = data['is_favorite'] ?? false;
          });
        }
      }
    } catch (e) {
      debugPrint("Error checking favorite: $e");
    }
  }

  Future<void> _toggleFavorite() async {
    if (widget.location == null) return;

    if (await UserSession.isGuest()) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Login required to save favorites'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 2),
          ),
        );
      }
      return;
    }

    final String? email = await UserSession.getEmail();
    if (email == null) return;

    setState(() {
      isFavorite = !isFavorite;
    });

    try {
      final response = await http.post(
        Uri.parse(ApiConstants.toggleFavorite),
        body: {'email': email, 'room_id': widget.location!.id.toString()},
      );

      if (response.statusCode == 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                isFavorite ? 'Added to Favorites' : 'Removed from Favorites',
              ),
              backgroundColor: isFavorite ? Colors.green : Colors.grey,
              duration: const Duration(seconds: 1),
            ),
          );
        }
      } else {
        throw Exception("Server status not 200");
      }
    } catch (e) {
      debugPrint("Error toggling favorite: $e");
      if (mounted) {
        setState(() {
          isFavorite = !isFavorite;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Connection failed. Action undone.')),
        );
      }
    }
  }

  Future<void> _onNavigatePressed() async {
    if (widget.location == null) return;
    
    // Explicit Building Navigation Recording
    if (widget.location!.type.toLowerCase() == 'building') {
      await HistoryService.addToHistory(widget.location!);
    }
    
    if (mounted) {
      await MapUtils.openMap(
        widget.location!.latitude,
        widget.location!.longitude,
        context,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final String title = AppLanguage.current == 'TH'
        ? (widget.location?.nameTh ?? 'Unknown Room')
        : (widget.location?.nameEn ?? 'Unknown Room');
    final String buildingInfo = AppLanguage.current == 'TH'
        ? (widget.location?.departmentNameTh ?? 'RMUTT')
        : (widget.location?.departmentNameEn ?? 'RMUTT');
    final String type = widget.location?.type ?? 'room';
    String displayType = type;
    if (AppLanguage.current == 'TH') {
      if (type.toLowerCase() == 'room') displayType = 'ห้อง';
      else if (type.toLowerCase() == 'building') displayType = 'อาคาร';
      else if (type.toLowerCase() == 'department') displayType = 'หน่วยงาน';
      else if (type.toLowerCase() == 'faculty') displayType = 'คณะ';
    }

    final String floor = widget.location?.floor?.toString() ?? '-';
    final String roomNumber = widget.location?.roomNumber ?? '-';
    final String? details = widget.location?.details;
    final String? responsibleEmail = widget.location?.responsibleEmail;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            child: IconButton(
              icon: const Icon(
                Icons.report_problem,
                color: Color.fromARGB(255, 255, 255, 255),
              ),
              tooltip: 'Report Issue',
              onPressed: () {
                if (widget.location != null) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          ReportScreen(location: widget.location!),
                    ),
                  );
                }
              },
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ClipRRect(child: _buildHeaderImage()),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(
                      context,
                    ).textTheme.headlineSmall?.copyWith(fontSize: 28),
                  ),
                  const SizedBox(height: 16),
                  _buildInfoRow(AppLanguage.current == 'TH' ? 'คณะ/หน่วยงาน' : 'Department', buildingInfo),
                  const SizedBox(height: 8),
                  _buildInfoRow(AppLanguage.current == 'TH' ? 'ประเภท' : 'Type', displayType),
                  const SizedBox(height: 8),
                  _buildInfoRow(AppLanguage.current == 'TH' ? 'ชั้น' : 'Floor', floor),
                  const SizedBox(height: 8),
                  _buildInfoRow(AppLanguage.current == 'TH' ? 'หมายเลขห้อง' : 'Room Number', roomNumber),
                  if (details != null && details.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    _buildInfoRow(AppLanguage.current == 'TH' ? 'รายละเอียด' : 'Details', details),
                  ],
                  if (responsibleEmail != null && responsibleEmail.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    _buildEmailRow(responsibleEmail),
                  ],
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _onNavigatePressed,
                          icon: const Icon(Icons.navigation),
                          label: Text(AppLanguage.current == 'TH' ? 'เริ่มนำทาง' : 'Start Navigation'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFFC107),
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _toggleFavorite,
                          icon: Icon(
                            isFavorite ? Icons.star : Icons.star_border,
                            color: const Color(0xFFFFC107),
                          ),
                          label: Text(
                            isFavorite 
                                ? (AppLanguage.current == 'TH' ? 'บันทึกแล้ว' : 'Saved') 
                                : (AppLanguage.current == 'TH' ? 'เพิ่มลงรายการโปรด' : 'Add to Favorites'),
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFFFFC107),
                            side: const BorderSide(color: Color(0xFFFFC107)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // ==========================================
                  // ส่วนแสดงผลแผนผังห้อง (Floor Layout)
                  // ==========================================
                  Text(
                    AppLanguage.current == 'TH' ? 'แผนผังชั้น' : 'Floor Layout',
                    style: Theme.of(
                      context,
                    ).textTheme.headlineSmall?.copyWith(fontSize: 24),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    height: 200,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child:
                        widget.location?.floorLayoutUrl != null &&
                            widget.location!.floorLayoutUrl!.isNotEmpty
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: InteractiveViewer(
                              child: Image.network(
                                widget.location!.floorLayoutUrl!,
                                fit: BoxFit.contain,
                                errorBuilder: (context, error, stackTrace) =>
                                    const Center(
                                      child: Text(
                                        'Failed to load map image',
                                        style: TextStyle(color: Colors.white70),
                                      ),
                                    ),
                              ),
                            ),
                          )
                        : Center(
                            child: Text(
                              AppLanguage.current == 'TH' ? 'ไม่มีแผนผังชั้น' : 'No Floor Layout Available',
                              style: const TextStyle(color: Colors.white70),
                            ),
                          ),
                  ),
                  const SizedBox(height: 24),

                  // ==========================================
                  // ส่วนแสดงผลรูปภาพสถานที่จริง (Images)
                  // ==========================================
                  Text(
                    AppLanguage.current == 'TH' ? 'รูปภาพสถานที่' : 'Images',
                    style: Theme.of(
                      context,
                    ).textTheme.headlineSmall?.copyWith(fontSize: 24),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 200,
                    child:
                        widget.location?.imageUrl != null &&
                            widget.location!.imageUrl!.isNotEmpty
                        ? ListView(
                            scrollDirection: Axis.horizontal,
                            children: [
                              Container(
                                width: 280,
                                margin: const EdgeInsets.only(right: 12.0),
                                child: Card(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12.0),
                                  ),
                                  clipBehavior: Clip.antiAlias,
                                  child: Image.network(
                                    widget.location!.imageUrl!,
                                    fit: BoxFit.cover,
                                    errorBuilder: (ctx, err, stack) =>
                                        const Center(
                                          child: Icon(
                                            Icons.broken_image,
                                            size: 50,
                                            color: Colors.grey,
                                          ),
                                        ),
                                  ),
                                ),
                              ),
                            ],
                          )
                        : Center(
                            child: Text(
                              AppLanguage.current == 'TH' ? "ไม่มีรูปภาพ" : "No gallery images available",
                              style: const TextStyle(color: Colors.white70),
                            ),
                          ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // ส่วนแสดงรูปภาพหน้าปกด้านบนสุด
  // ==========================================
  Widget _buildHeaderImage() {
    String? headerImageUrl = widget.location?.buildingImageUrl ?? widget.location?.imageUrl;
    
    if (headerImageUrl != null && headerImageUrl.isNotEmpty) {
      return Image.network(
        headerImageUrl,
        height: 250,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (ctx, err, stack) => Image.asset(
          'assets/images/cpe_lap_building.png',
          height: 250,
          width: double.infinity,
          fit: BoxFit.cover,
        ),
      );
    }
    return Image.asset(
      'assets/images/cpe_lap_building.png',
      height: 250,
      width: double.infinity,
      fit: BoxFit.cover,
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Text('$label : $value', style: const TextStyle(fontSize: 16));
  }

  Widget _buildEmailRow(String email) {
    return Row(
      children: [
        const Icon(Icons.email_outlined, size: 18, color: Colors.blueAccent),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            'Email : $email',
            style: const TextStyle(fontSize: 16, color: Colors.blueAccent),
          ),
        ),
      ],
    );
  }
}
