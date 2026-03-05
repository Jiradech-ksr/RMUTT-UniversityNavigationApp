import 'package:universitynavigationapp/models/api_constants.dart';
import 'package:universitynavigationapp/services/user_session.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'details_screen.dart';
import '../models/location_model.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  List<dynamic> _favorites = [];
  bool _isLoading = true;
  bool _isGuest = false;

  @override
  void initState() {
    super.initState();
    _fetchFavorites();
  }

  Future<void> _fetchFavorites() async {
    if (await UserSession.isGuest()) {
      if (mounted) {
        setState(() {
          _isGuest = true;
          _isLoading = false;
        });
      }
      return;
    }

    final String? email = await UserSession.getEmail();
    if (email == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    try {
      final response = await http.post(
        Uri.parse(ApiConstants.favorites),
        body: {'email': email},
      );
      if (response.statusCode == 200) {
        final dynamic data = json.decode(response.body);
        if (data is List) {
          if (mounted) {
            setState(() {
              _favorites = data;
              _isLoading = false;
            });
          }
        }
      } else {
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isGuest) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.lock_outline, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              "Login to save favorites",
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Saved Locations')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _favorites.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.star_border,
                    size: 80,
                    color: Colors.grey.shade300,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "No favorites yet",
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _favorites.length,
              itemBuilder: (context, index) {
                final fav = _favorites[index];
                return Card(
                  elevation: 2,
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    leading: const Icon(
                      Icons.star,
                      color: Colors.amber,
                      size: 32,
                    ),
                    title: Text(
                      fav['name'] ?? 'Unknown',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      '${fav['building_name'] ?? '-'} • Room ${fav['room_number'] ?? '-'}',
                    ),
                    trailing: const Icon(
                      Icons.arrow_forward_ios,
                      size: 16,
                      color: Colors.grey,
                    ),
                    onTap: () {
                      final location = Location(
                        id: int.parse(fav['id'].toString()),
                        name: fav['name'],
                        type: 'Room',
                        latitude:
                            double.tryParse(
                              fav['latitude']?.toString() ?? '0.0',
                            ) ??
                            0.0,
                        longitude:
                            double.tryParse(
                              fav['longitude']?.toString() ?? '0.0',
                            ) ??
                            0.0,
                        departmentName: fav['building_name'],
                        roomNumber: fav['room_number'],
                        floor: int.tryParse(fav['floor'].toString()),
                        imageUrl: fav['image_url'],
                        floorLayoutUrl: fav['floor_layout_url'],
                      );
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              DetailsScreen(location: location),
                        ),
                      ).then((_) => _fetchFavorites());
                    },
                  ),
                );
              },
            ),
    );
  }
}
