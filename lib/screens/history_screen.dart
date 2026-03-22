import 'package:flutter/material.dart';
import '../models/location_model.dart';
import '../services/history_service.dart';
import '../screens/details_screen.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<Location> _history = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    List<Location> loadedHistory = await HistoryService.getHistory();
    if (mounted) {
      setState(() {
        _history = loadedHistory;
        _isLoading = false;
      });
    }
  }

  Future<void> _clearHistory() async {
    await HistoryService.clearHistory();
    _loadHistory();
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(AppLanguage.current == 'TH' ? "ล้างประวัติเรียบร้อยแล้ว" : "History cleared")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLanguage.current == 'TH' ? 'ประวัติการค้นหา' : 'Recent Places'),
        actions: [
          if (_history.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: AppLanguage.current == 'TH' ? 'ล้างประวัติ' : 'Clear History',
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: Text(AppLanguage.current == 'TH' ? "ล้างประวัติ" : "Clear History"),
                    content: Text(
                      AppLanguage.current == 'TH' ? "คุณแน่ใจหรือไม่ที่จะลบประวัติทั้งหมด?" : "Are you sure you want to delete all history?",
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: Text(AppLanguage.current == 'TH' ? "ยกเลิก" : "Cancel"),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pop(ctx);
                          _clearHistory();
                        },
                        child: Text(
                          AppLanguage.current == 'TH' ? "ล้าง" : "Clear",
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _history.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history, size: 80, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  Text(
                    AppLanguage.current == 'TH' ? "ไม่มีประวัติการค้นหาล่าสุด" : "No recent history",
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _history.length,
              itemBuilder: (context, index) {
                final Location loc = _history[index];
                return Card(
                  elevation: 2,
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.indigo.shade50,
                      child: const Icon(Icons.history, color: Colors.indigo),
                    ),
                    title: Text(
                      loc.localizedName,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      AppLanguage.current == 'TH'
                          ? (loc.departmentNameTh ?? 'Unknown')
                          : '${loc.departmentNameEn ?? 'Unknown'} • Room ${loc.roomNumber ?? '-'}',
                    ),
                    trailing: const Icon(
                      Icons.chevron_right,
                      color: Colors.grey,
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => DetailsScreen(location: loc),
                        ),
                      ).then((_) => _loadHistory());
                    },
                  ),
                );
              },
            ),
    );
  }
}
