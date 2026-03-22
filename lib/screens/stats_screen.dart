import 'dart:convert';
import 'package:rmutt_navigation_app/models/api_constants.dart';
import '../models/location_model.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../services/user_session.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  bool _isLoading = true;
  int _totalSearches = 0;
  int _uniqueRooms = 0;
  int _uniqueBuildings = 0;
  List<dynamic> _topRooms = [];
  List<dynamic> _topBuildings = [];

  @override
  void initState() {
    super.initState();
    _fetchStats();
  }

  Future<void> _fetchStats() async {
    // 1. Check Guest
    if (await UserSession.isGuest()) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    final email = await UserSession.getEmail();
    if (email == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    try {
      debugPrint("Fetching stats for: $email");

      final response = await http.get(
        Uri.parse('${ApiConstants.getUserStats}?email=$email'),
      );

      debugPrint("Stats Response: ${response.statusCode} - ${response.body}");

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (mounted) {
          setState(() {
            _totalSearches =
                int.tryParse(data['total_searches'].toString()) ?? 0;
            _uniqueRooms = int.tryParse(data['unique_rooms'].toString()) ?? 0;
            _uniqueBuildings =
                int.tryParse(data['unique_buildings'].toString()) ?? 0;
            _topRooms = data['top_rooms'] ?? [];
            _topBuildings = data['top_buildings'] ?? [];
            _isLoading = false;
          });
        }
      } else {
        debugPrint("Server Error: ${response.statusCode}");
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint("Error fetching stats: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _buildOverviewCard(String title, String value, String subtitle,
      Color bgColor, Color textColor) {
    return Expanded(
      child: Container(
        height: 110,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(15),
          border: bgColor == Colors.white
              ? Border.all(color: Colors.grey.shade200)
              : null,
          boxShadow: [
            if (bgColor != Colors.white)
              const BoxShadow(
                color: Colors.black12,
                blurRadius: 10,
                offset: Offset(0, 5),
              ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: textColor.withOpacity(0.7),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 5),
            Text(
              value,
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 10,
                color: textColor.withOpacity(0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopList(String title, List<dynamic> items, bool isRoom) {
    if (items.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 15),
          child: Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        ...items.asMap().entries.map((entry) {
          var item = entry.value;
          int count = int.tryParse(item['visit_count'].toString()) ?? 0;
          int maxCount = int.tryParse(items[0]['visit_count'].toString()) ?? 1;

          IconData iconData = isRoom ? Icons.door_front_door : Icons.apartment;
          Color iconColor = isRoom ? Colors.blue : Colors.orange;

          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 15),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: iconColor.withOpacity(0.1),
                  child: Icon(iconData, color: iconColor, size: 20),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item['name'] ?? 'Unknown',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 5),
                      LinearProgressIndicator(
                        value: (count / maxCount).toDouble(),
                        backgroundColor: Colors.grey[100],
                        color: const Color(0xFFFFC107),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 15),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      "$count",
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    const Text(
                      "searches",
                      style: TextStyle(fontSize: 10, color: Colors.grey),
                    ),
                  ],
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(AppLanguage.current == 'TH' ? "สถิติของฉัน" : "My Statistics",
            style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFFFFC107)),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppLanguage.current == 'TH' ? "ภาพรวมกิจกรรม" : "Activity Overview",
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 15),
                  // Summary Cards Row
                  Row(
                    children: [
                      _buildOverviewCard(AppLanguage.current == 'TH' ? "การเข้าชมทั้งหมด" : "Total Visits", "$_totalSearches",
                          AppLanguage.current == 'TH' ? "เวลาทั้งหมด" : "All Time", const Color(0xFFFFC107), Colors.black),
                      const SizedBox(width: 10),
                      _buildOverviewCard(AppLanguage.current == 'TH' ? "ห้อง" : "Rooms", "$_uniqueRooms", AppLanguage.current == 'TH' ? "ที่สำรวจ" : "Explored",
                          Colors.white, Colors.black),
                      const SizedBox(width: 10),
                      _buildOverviewCard(AppLanguage.current == 'TH' ? "อาคาร" : "Buildings", "$_uniqueBuildings",
                          AppLanguage.current == 'TH' ? "ที่สำรวจ" : "Explored", Colors.white, Colors.black),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Empty State if no history at all
                  if (_topRooms.isEmpty && _topBuildings.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(30),
                      margin: const EdgeInsets.only(top: 20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Column(
                        children: [
                          const Icon(Icons.history_toggle_off,
                              size: 50, color: Colors.grey),
                          const SizedBox(height: 15),
                          Text(AppLanguage.current == 'TH' ? "ยังไม่มีข้อมูลประวัติการค้นหา" : "No history data yet.",
                              style: const TextStyle(color: Colors.grey)),
                        ],
                      ),
                    ),

                  // Top Rooms Section
                  _buildTopList(AppLanguage.current == 'TH' ? "5 อันดับห้องที่ค้นหาบ่อยที่สุด" : "Top 5 Most Searched Rooms", _topRooms, true),

                  // Spacer
                  if (_topRooms.isNotEmpty && _topBuildings.isNotEmpty)
                    const SizedBox(height: 10),

                  // Top Buildings Section
                  _buildTopList(AppLanguage.current == 'TH' ? "5 อันดับอาคารที่ค้นหาบ่อยที่สุด" : "Top 5 Most Searched Buildings", _topBuildings, false),
                  
                  const SizedBox(height: 40),
                ],
              ),
            ),
    );
  }
}
