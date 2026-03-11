import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import '../models/location_model.dart';
import '../models/api_constants.dart';
import 'user_session.dart';

class HistoryService {
  // Local volatile storage for guest sessions. This clears when the app is killed.
  static final List<Location> _guestSessionHistory = [];

  // --- ADD TO HISTORY ---
  static Future<void> addToHistory(Location location) async {
    String emailToSave = "guest";
    
    // Check if user is logged in
    bool isGuest = await UserSession.isGuest();
    if (!isGuest) {
      final String? email = await UserSession.getEmail();
      if (email != null) {
        emailToSave = email;
      }
    } else {
      // If guest, add to local session tracking so it shows up in their UI immediately
      // Remove older instances of the same location to put it at the top
      _guestSessionHistory.removeWhere((loc) => loc.id == location.id && loc.type == location.type);
      _guestSessionHistory.insert(0, location);
    }

    try {
      debugPrint("History: Adding Room ID ${location.id} for $emailToSave...");

      final response = await http.post(
        Uri.parse(ApiConstants.addHistory),
        body: {
          'email': emailToSave,
          'location_id': location.id.toString(),
          'location_type': location.type,
        },
      );

      debugPrint("History Add Response: ${response.statusCode} - ${response.body}");
    } catch (e) {
      debugPrint("History Add Error: $e");
    }
  }

  // --- GET HISTORY ---
  static Future<List<Location>> getHistory() async {
    // If user is a guest, only return their temporary local session history 
    // instead of pulling the global guest database history
    if (await UserSession.isGuest()) {
      return List.from(_guestSessionHistory);
    }
    
    String emailToSave = "guest";
    
    // Check if user is logged in
    final String? email = await UserSession.getEmail();
    if (email != null) {
      emailToSave = email;
    }

    try {
      final uri = Uri.parse(
        '${ApiConstants.getHistory}?email=${Uri.encodeComponent(emailToSave)}',
      );
      debugPrint("History: Fetching from $uri");

      final response = await http.get(uri);

      if (response.statusCode == 200) {
        // Debug: Print raw JSON to see what PHP sends
        debugPrint("History Raw JSON: ${response.body}");

        final dynamic data = json.decode(response.body);

        if (data is List) {
          return data.map((json) {
            // FIX: Ensure ID is parsed correctly even if string
            return Location.fromJson(json);
          }).toList();
        }
      } else {
        debugPrint("History Error: Server returned ${response.statusCode}");
      }
    } catch (e) {
      debugPrint("History Fetch Error: $e");
    }
    return [];
  }

  // --- CLEAR HISTORY ---
  static Future<void> clearHistory() async {
    // Check if user is logged in
    bool isGuest = await UserSession.isGuest();
    if (isGuest) {
      // For guests, we only clear their local active session.
      // We do NOT tell the server to clear 'guest' history, 
      // otherwise it wipes the statistics we collected!
      _guestSessionHistory.clear();
      return;
    }
    
    final String? email = await UserSession.getEmail();
    if (email == null) return;

    try {
      await http.post(
        Uri.parse(ApiConstants.clearHistory),
        body: {'email': email},
      );
    } catch (e) {
      debugPrint("History Clear Error: $e");
    }
  }
}
