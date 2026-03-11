import 'dart:convert';
import 'package:rmutt_navigation_app/models/api_constants.dart';
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
  List<dynamic> _topRooms = [];

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
      print("Fetching stats for: $email"); // Debug print

      final response = await http.get(
        Uri.parse('${ApiConstants.getUserStats}?email=$email'),
      );

      print(
        "Stats Response: ${response.statusCode} - ${response.body}",
      ); // Debug print

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (mounted) {
          setState(() {
            // Safely parse integers
            _totalSearches =
                int.tryParse(data['total_searches'].toString()) ?? 0;
            _topRooms = data['top_rooms'] ?? [];
            _isLoading = false;
          });
        }
      } else {
        // ERROR: Stop loading if server fails
        print("Server Error: ${response.statusCode}");
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (e) {
      print("Error fetching stats: $e");
      // ERROR: Stop loading if connection fails
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("My Statistics"),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFFFFD700)),
            )
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFD700),
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        const Text(
                          "Total Visits",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          "$_totalSearches",
                          style: const TextStyle(
                            fontSize: 48,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Text(
                          "Rooms Explored",
                          style: TextStyle(fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),
                  const Text(
                    "Top 5 Most Visited Rooms",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: _topRooms.isEmpty
                        ? const Center(child: Text("No history data yet."))
                        : ListView.builder(
                            itemCount: _topRooms.length,
                            itemBuilder: (context, index) {
                              final room = _topRooms[index];
                              final count = room['visit_count'];
                              return Container(
                                margin: const EdgeInsets.only(bottom: 10),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 10,
                                  horizontal: 15,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: Colors.grey.shade200,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      backgroundColor: Colors.grey[200],
                                      child: Text(
                                        "${index + 1}",
                                        style: const TextStyle(
                                          color: Colors.black,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 15),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            room['name'],
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(height: 5),
                                          LinearProgressIndicator(
                                            value:
                                                (count /
                                                        (_topRooms[0]['visit_count'] ??
                                                            1))
                                                    .toDouble(),
                                            backgroundColor: Colors.grey[100],
                                            color: const Color(0xFFFFD700),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 15),
                                    Text(
                                      "$count times",
                                      style: const TextStyle(
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
    );
  }
}
