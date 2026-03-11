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
    if (widget.location != null) {
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
    await HistoryService.addToHistory(widget.location!);
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
    final String floor = widget.location?.floor?.toString() ?? '-';
    final String roomId = widget.location?.roomNumber ?? '-';

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
                  _buildInfoRow('Department', buildingInfo),
                  const SizedBox(height: 8),
                  _buildInfoRow('Type', type),
                  const SizedBox(height: 8),
                  _buildInfoRow('Floor', floor),
                  const SizedBox(height: 8),
                  _buildInfoRow('Room ID', roomId),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _onNavigatePressed,
                          icon: const Icon(Icons.navigation),
                          label: const Text('Start Navigation'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFFD700),
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
                            color: const Color(0xFFFFD700),
                          ),
                          label: Text(
                            isFavorite ? 'Saved' : 'Add to Favorites',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFFFFD700),
                            side: const BorderSide(color: Color(0xFFFFD700)),
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
                    'Floor Layout',
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
                        : const Center(
                            child: Text(
                              'No Floor Layout Available',
                              style: TextStyle(color: Colors.white70),
                            ),
                          ),
                  ),
                  const SizedBox(height: 24),

                  // ==========================================
                  // ส่วนแสดงผลรูปภาพสถานที่จริง (Images)
                  // ==========================================
                  Text(
                    'Images',
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
                        : const Center(
                            child: Text(
                              "No gallery images available",
                              style: TextStyle(color: Colors.white70),
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
    if (widget.location?.imageUrl != null &&
        widget.location!.imageUrl!.isNotEmpty) {
      return Image.network(
        widget.location!.imageUrl!, // Removed $serverUrl/
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
}
