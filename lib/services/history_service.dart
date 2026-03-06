import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/location_model.dart';
import '../models/api_constants.dart';
import 'user_session.dart';

class HistoryService {
  // --- ADD TO HISTORY ---
  static Future<void> addToHistory(Location location) async {
    // 1. Check if Guest (Guests don't save to DB)
    if (await UserSession.isGuest()) {
      print("History: User is Guest, skipping save.");
      return;
    }

    final String? email = await UserSession.getEmail();
    if (email == null) {
      print("History: Email is null, cannot save.");
      return;
    }

    try {
      print("History: Adding Room ID ${location.id} for $email...");

      final response = await http.post(
        Uri.parse(ApiConstants.addHistory),
        body: {'email': email, 'room_id': location.id.toString()},
      );

      print("History Add Response: ${response.statusCode} - ${response.body}");
    } catch (e) {
      print("History Add Error: $e");
    }
  }

  // --- GET HISTORY ---
  static Future<List<Location>> getHistory() async {
    // 1. Check if Guest
    if (await UserSession.isGuest()) {
      return [];
    }

    final String? email = await UserSession.getEmail();
    if (email == null) return [];

    try {
      final uri = Uri.parse(
        '${ApiConstants.getHistory}?email=${Uri.encodeComponent(email)}',
      );
      print("History: Fetching from $uri");

      final response = await http.get(uri);

      if (response.statusCode == 200) {
        // Debug: Print raw JSON to see what PHP sends
        print("History Raw JSON: ${response.body}");

        final dynamic data = json.decode(response.body);

        if (data is List) {
          return data.map((json) {
            // FIX: Ensure ID is parsed correctly even if string
            return Location.fromJson(json);
          }).toList();
        }
      } else {
        print("History Error: Server returned ${response.statusCode}");
      }
    } catch (e) {
      print("History Fetch Error: $e");
    }
    return [];
  }

  // --- CLEAR HISTORY ---
  static Future<void> clearHistory() async {
    final String? email = await UserSession.getEmail();
    if (email == null) return;

    try {
      await http.post(
        Uri.parse(ApiConstants.clearHistory),
        body: {'email': email},
      );
    } catch (e) {
      print("History Clear Error: $e");
    }
  }
}
