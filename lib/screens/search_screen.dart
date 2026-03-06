import 'package:universitynavigationapp/models/api_constants.dart';
import 'package:flutter/material.dart';
import 'details_screen.dart';
import '../models/location_model.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../services/map_utils.dart';
import '../services/history_service.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";
  bool _isLoading = true;
  List<dynamic> _campusHierarchy = [];

  @override
  void initState() {
    super.initState();
    fetchCampusData();
  }

  Future<void> fetchCampusData() async {
    try {
      final response = await http.post(Uri.parse(ApiConstants.hierarchy));
      if (response.statusCode == 200) {
        setState(() {
          _campusHierarchy = json.decode(response.body);
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _handleNavigation(Map<String, dynamic> data) async {
    final double lat = double.tryParse(data['lat']?.toString() ?? '0.0') ?? 0.0;
    final double lng = double.tryParse(data['lng']?.toString() ?? '0.0') ?? 0.0;
    if (lat == 0.0 || lng == 0.0) return;

    final location = Location(
      id: int.tryParse(data['id']?.toString() ?? '0') ?? 0,
      name: data['title'] ?? 'Unknown',
      type: 'Building',
      latitude: lat,
      longitude: lng,
      departmentName: 'Search Result',
      imageUrl: data['image_url'],
      roomNumber: data['room_number']?.toString(),
      floor: int.tryParse(data['floor']?.toString() ?? '1'),
    );

    await HistoryService.addToHistory(location);
    if (mounted) await MapUtils.openMap(lat, lng, context);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  bool _hasMatch(Map<String, dynamic> data, String query) {
    if (query.isEmpty) return false;
    final title = data['title'].toString().toLowerCase();
    final roomNumber = data['room_number']?.toString().toLowerCase() ?? '';
    final searchLower = query.toLowerCase();
    if (title.contains(searchLower) || roomNumber.contains(searchLower)) {
      return true;
    }
    if (data.containsKey('children')) {
      for (var child in data['children']) {
        if (_hasMatch(child, query)) return true;
      }
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    // We use Safe Area and a Column structure
    return Scaffold(
      appBar: AppBar(
        title: const Text('Campus Navigator'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(70),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: TextField(
              controller: _searchController,
              onChanged: (value) => setState(() => _searchQuery = value),
              decoration: const InputDecoration(
                hintText: 'Search Buildings, Rooms...',
                prefixIcon: Icon(Icons.search),
              ),
            ),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _campusHierarchy.isEmpty
          ? const Center(child: Text("No data found"))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _campusHierarchy.length,
              itemBuilder: (context, index) {
                return _buildTreeItem(
                  _campusHierarchy[index],
                  forceShow: false,
                  parentName: 'RMUTT',
                );
              },
            ),
    );
  }

  Widget _buildTreeItem(
    Map<String, dynamic> data, {
    bool forceShow = false,
    String parentName = 'RMUTT',
  }) {
    // ... (Keep your matching logic) ...
    bool selfMatches =
        _searchQuery.isNotEmpty &&
        (data['title'].toString().toLowerCase().contains(
              _searchQuery.toLowerCase(),
            ) ||
            (data['room_number']?.toString().toLowerCase().contains(
                  _searchQuery.toLowerCase(),
                ) ??
                false));
    bool shouldShow =
        _searchQuery.isEmpty ||
        forceShow ||
        selfMatches ||
        _hasMatch(data, _searchQuery);
    if (!shouldShow) return const SizedBox.shrink();
    bool passForceShow = forceShow || selfMatches;

    // --- ROOM STYLE (Cleaner) ---
    if (data['type'] == 'room') {
      return Container(
        margin: const EdgeInsets.only(left: 12, bottom: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(
            left: BorderSide(color: Colors.indigo.shade100, width: 4),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.shade200,
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ListTile(
          dense: true,
          leading: const Icon(Icons.meeting_room, color: Colors.indigo),
          title: Text(
            data['title'] ?? 'Unknown',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Text(
            'Room ${data['room_number'] ?? '-'} • Floor ${data['floor'] ?? '-'}',
          ),
          trailing: const Icon(Icons.chevron_right, color: Colors.grey),
          onTap: () {
            // ... (Keep your onTap logic) ...
            int roomId = int.tryParse(data['id']?.toString() ?? '0') ?? 0;
            int floor = int.tryParse(data['floor']?.toString() ?? '1') ?? 1;
            double lat =
                double.tryParse(data['lat']?.toString() ?? '0.0') ?? 0.0;
            double lng =
                double.tryParse(data['lng']?.toString() ?? '0.0') ?? 0.0;

            final location = Location(
              id: roomId,
              name: data['title'] ?? 'Unknown',
              type: 'Room',
              latitude: lat,
              longitude: lng,
              departmentName: parentName,
              imageUrl: data['image_url'],
              roomNumber: data['room_number']?.toString(),
              floor: floor,
              floorLayoutUrl: data['floor_layout_url'],
            );
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => DetailsScreen(location: location),
              ),
            );
          },
        ),
      );
    }

    // --- BUILDING STYLE (Modern Expansion Tile) ---
    bool shouldExpand =
        _searchQuery.isNotEmpty &&
        (selfMatches || _hasMatch(data, _searchQuery));

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        shape: const Border(),
        collapsedShape: const Border(),
        key: Key('${data['title']}_$_searchQuery'),
        initiallyExpanded: shouldExpand,
        leading: CircleAvatar(
          backgroundColor: Colors.indigo.shade50,
          child: Icon(_getIconForType(data['type']), color: Colors.indigo),
        ),
        title: Text(
          data['title'],
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: data['type'] == 'building'
            ? GestureDetector(
                onTap: () => _handleNavigation(data),
                child: const Row(
                  children: [
                    Text(
                      "Navigate",
                      style: TextStyle(
                        color: Colors.blue,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Icon(Icons.arrow_forward, size: 14, color: Colors.blue),
                  ],
                ),
              )
            : null,
        childrenPadding: const EdgeInsets.all(8),
        children: (data['children'] as List<dynamic>).map<Widget>((child) {
          return _buildTreeItem(
            child,
            forceShow: passForceShow,
            parentName: data['title'],
          );
        }).toList(),
      ),
    );
  }

  // ... (Keep helper methods _getIconForType, etc.) ...
  IconData _getIconForType(String type) {
    switch (type) {
      case 'faculty':
        return Icons.school;
      case 'major':
        return Icons.engineering;
      case 'building':
        return Icons.business;
      default:
        return Icons.meeting_room;
    }
  }
}
