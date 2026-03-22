import 'package:flutter/material.dart';
import 'search_screen.dart';
import 'history_screen.dart';
import 'favorites_screen.dart';
import 'account_screen.dart';
import '../models/location_model.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  static const List<Widget> _widgetOptions = <Widget>[
    SearchScreen(),
    HistoryScreen(),
    FavoritesScreen(),
    AccountScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      // Clean Background Color instead of Image
      backgroundColor: colorScheme.surface,

      body: _widgetOptions.elementAt(_selectedIndex),

      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          items: <BottomNavigationBarItem>[
            BottomNavigationBarItem(
              icon: const Icon(Icons.search), 
              label: AppLanguage.current == 'TH' ? 'ค้นหา' : 'Search'
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.history),
              label: AppLanguage.current == 'TH' ? 'ประวัติ' : 'History',
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.favorite),
              label: AppLanguage.current == 'TH' ? 'รายการโปรด' : 'Favorites',
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.person), 
              label: AppLanguage.current == 'TH' ? 'บัญชี' : 'Account'
            ),
          ],
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: colorScheme.primary, // Uses our new Indigo
          unselectedItemColor: Colors.grey,
          showUnselectedLabels: true,
          elevation: 0,
        ),
      ),
    );
  }
}
