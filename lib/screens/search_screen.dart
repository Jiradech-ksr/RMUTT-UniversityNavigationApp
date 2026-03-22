import 'dart:async';
import 'package:rmutt_navigation_app/models/api_constants.dart';
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
  String _nlpEntity = "";
  Timer? _debounce;

  Future<void> _fetchNlpEntity(String query) async {
    try {
      final url = '${ApiConstants.baseUrl}/NLP/search.php?query=${Uri.encodeComponent(query)}';
      final response = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 2));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['entity'] != null && mounted) {
          setState(() {
            _nlpEntity = data['entity'].toString().toLowerCase();
          });
        }
      }
    } catch (_) {
      // Fail silently, fallback to standard text search
    }
  }
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
      nameEn: data['title_en'] ?? 'Unknown',
      nameTh: data['title_th'] ?? 'Unknown',
      type: 'Building',
      latitude: lat,
      longitude: lng,
      departmentNameEn: 'Search Result',
      departmentNameTh: 'ค้นหา',
      imageUrl: data['image_url'],
      roomNumber: data['room_number']?.toString(),
      floor: int.tryParse(data['floor']?.toString() ?? '1'),
    );

    await HistoryService.addToHistory(location);
    if (mounted) await MapUtils.openMap(lat, lng, context);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  bool _hasMatch(Map<String, dynamic> data, String query) {
    if (query.isEmpty) return false;
    final titleEn = data['title_en'].toString().toLowerCase();
    final titleTh = data['title_th'].toString().toLowerCase();
    final roomNumber = data['room_number']?.toString().toLowerCase() ?? '';
    final searchLower = query.toLowerCase();

    // Search in both English and Thai!
    if (titleEn.contains(searchLower) ||
        titleTh.contains(searchLower) ||
        roomNumber.contains(searchLower) ||
        (_nlpEntity.isNotEmpty && 
         (titleEn.contains(_nlpEntity) || 
          titleTh.contains(_nlpEntity) || 
          roomNumber.contains(_nlpEntity)))) {
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
        title: Text(AppLanguage.current == 'TH' ? 'แผนที่นำทางมหาวิทยาลัย' : 'Campus Navigator'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(70),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: TextField(
              controller: _searchController,
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                  _nlpEntity = "";
                });
                if (_debounce?.isActive ?? false) _debounce!.cancel();
                _debounce = Timer(const Duration(milliseconds: 500), () {
                  if (value.isNotEmpty) _fetchNlpEntity(value);
                });
              },
              decoration: InputDecoration(
                hintText: AppLanguage.current == 'TH' ? 'ค้นหาอาคาร, ห้อง...' : 'Search Buildings, Rooms...',
                prefixIcon: const Icon(Icons.search),
              ),
            ),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _campusHierarchy.isEmpty
          ? Center(child: Text(AppLanguage.current == 'TH' ? "ไม่พบข้อมูล" : "No data found"))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _campusHierarchy.length,
              itemBuilder: (context, index) {
                return _buildTreeItem(
                  _campusHierarchy[index],
                  forceShow: false,
                  parentNameEn: 'RMUTT',
                  parentNameTh: 'ราชมงคลธัญบุรี',
                );
              },
            ),
    );
  }

  Widget _buildTreeItem(
    Map<String, dynamic> data, {
    bool forceShow = false,
    String parentNameEn = 'RMUTT',
    String parentNameTh = 'ราชมงคลธัญบุรี',
    int depth = 0,
  }) {
    // Determine which string to show based on global language
    String displayTitle = AppLanguage.current == 'TH'
        ? (data['title_th'] ?? data['title_en'] ?? 'Unknown')
        : (data['title_en'] ?? 'Unknown');

    bool selfMatches =
        _searchQuery.isNotEmpty &&
        ((data['title_en']?.toString().toLowerCase().contains(
                  _searchQuery.toLowerCase(),
                ) ??
                false) ||
            (data['title_th']?.toString().toLowerCase().contains(
                  _searchQuery.toLowerCase(),
                ) ??
                false) ||
            (data['room_number']?.toString().toLowerCase().contains(
                  _searchQuery.toLowerCase(),
                ) ??
                false) ||
            (_nlpEntity.isNotEmpty &&
                ((data['title_en']?.toString().toLowerCase().contains(_nlpEntity) ?? false) ||
                 (data['title_th']?.toString().toLowerCase().contains(_nlpEntity) ?? false) ||
                 (data['room_number']?.toString().toLowerCase().contains(_nlpEntity) ?? false))));

    bool shouldShow =
        _searchQuery.isEmpty ||
        forceShow ||
        selfMatches ||
        _hasMatch(data, _searchQuery);

    if (!shouldShow) return const SizedBox.shrink();

    bool passForceShow = forceShow || selfMatches;
    // --- ROOM STYLE ---
    if (data['type'] == 'room') {
      return Padding(
        padding: const EdgeInsets.only(left: 16, bottom: 12),
        child: ListTile(
          tileColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          dense: true,
          leading: Icon(
            Icons.meeting_room,
            color: Theme.of(context).colorScheme.secondary,
          ),
          title: Text(
            displayTitle,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Text(
            AppLanguage.current == 'TH'
                ? 'ห้อง ${data['room_number'] ?? '-'} • ชั้น ${data['floor'] ?? '-'}'
                : 'Room ${data['room_number'] ?? '-'} • Floor ${data['floor'] ?? '-'}',
          ),
          trailing: const Icon(Icons.chevron_right, color: Colors.grey),
          onTap: () {
            int roomId = int.tryParse(data['id']?.toString() ?? '0') ?? 0;
            int floor = int.tryParse(data['floor']?.toString() ?? '1') ?? 1;
            double lat =
                double.tryParse(data['lat']?.toString() ?? '0.0') ?? 0.0;
            double lng =
                double.tryParse(data['lng']?.toString() ?? '0.0') ?? 0.0;

            final location = Location(
              id: roomId,
              nameEn: data['title_en'] ?? 'Unknown',
              nameTh: data['title_th'] ?? 'ไม่ระบุ',
              type: 'Room',
              latitude: lat,
              longitude: lng,
              departmentNameEn: parentNameEn,
              departmentNameTh: parentNameTh,
              imageUrl: data['image_url'],
              roomNumber: data['room_number']?.toString(),
              floor: floor,
              floorLayoutUrl: data['floor_layout_url'],
              buildingImageUrl: data['building_image_url'],
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

    // Depth-based indentation for department level
    final isGroupNode =
        data['type'] == 'faculty' || data['type'] == 'department';
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      margin: EdgeInsets.only(
        bottom: 12,
        left: data['type'] == 'department' ? 16.0 : 0.0,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: const Color.fromARGB(255, 199, 199, 199),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ExpansionTile(
        shape: const Border(),
        collapsedShape: const Border(),
        key: Key('${data['id']}_$_searchQuery'),
        initiallyExpanded: shouldExpand,
        leading: Icon(
          _getIconForType(data['type']),
          color: data['type'] == 'building'
              ? colorScheme.secondary
              : colorScheme.primary,
        ),
        title: Text(
          displayTitle,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: isGroupNode ? 15 : 16,
            color: isGroupNode ? colorScheme.primary : Colors.black87,
          ),
        ),
        subtitle: data['type'] == 'building'
            ? GestureDetector(
                onTap: () => _handleNavigation(data),
                child: Row(
                  children: [
                    Text(
                      AppLanguage.current == 'TH' ? "นำทาง" : "Navigate",
                      style: TextStyle(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward,
                      size: 14,
                      color: colorScheme.primary,
                    ),
                  ],
                ),
              )
            : null,
        childrenPadding: const EdgeInsets.all(8),
        children: (data['children'] as List<dynamic>).map<Widget>((child) {
          return _buildTreeItem(
            child,
            forceShow: passForceShow,
            parentNameEn: data['title_en'] ?? 'RMUTT',
            parentNameTh: data['title_th'] ?? 'ราชมงคลธัญบุรี',
            depth: depth + 1,
          );
        }).toList(),
      ),
    );
  }

  // Helper to pick an icon based on hierarchy level type
  IconData _getIconForType(String? type) {
    switch (type) {
      case 'faculty':
        return Icons.school;
      case 'department':
        return Icons.account_balance;
      case 'building':
        return Icons.business;
      case 'room':
        return Icons.meeting_room;
      default:
        return Icons.location_on;
    }
  }
}
