import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../services/user_session.dart';
import 'stats_screen.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  String _name = "Loading...";
  String _email = "Loading...";
  String _photoUrl = "";
  bool _isGuest = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    // 1. Use Service to check guest status
    bool isGuest = await UserSession.isGuest();

    if (isGuest) {
      setState(() {
        _isGuest = true;
        _name = "Guest User";
        _email = "Not logged in";
        _photoUrl = "";
      });
    } else {
      // 2. Use Service to get user details
      String? name = await UserSession.getName();
      String? email = await UserSession.getEmail();
      String? photo = await UserSession.getPhoto();

      setState(() {
        _isGuest = false;
        _name = name ?? "User";
        _email = email ?? "No Email";
        _photoUrl = photo ?? "";
      });
    }
  }

  Future<void> _handleLogoutOrLogin() async {
    // 1. Use Service to clear session
    await UserSession.logout();

    // 2. Sign out from Google (only if actually logged in)
    if (!_isGuest) {
      final GoogleSignIn googleSignIn = GoogleSignIn();
      await googleSignIn.signOut();
    }

    if (mounted) {
      // Navigate back to Login Screen
      Navigator.of(
        context,
      ).pushNamedAndRemoveUntil('/', (Route<dynamic> route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
      ), // Added AppBar for better navigation feel
      body: SingleChildScrollView(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                const SizedBox(height: 20),
                // --- PROFILE PICTURE SECTION ---
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors
                        .grey
                        .shade200, // Light grey background if no image
                    border: Border.all(
                      // Use the App's Primary Color (Indigo) instead of Gold
                      color: Theme.of(context).primaryColor,
                      width: 4,
                    ),
                    image: _photoUrl.isNotEmpty
                        ? DecorationImage(
                            fit: BoxFit.cover,
                            image: NetworkImage(_photoUrl),
                          )
                        : null, // If empty, don't set an image, just let child show
                  ),
                  // Child Icon shows ONLY if no photo
                  child: _photoUrl.isEmpty
                      ? const Icon(
                          Icons
                              .person, // Changed to 'person' for a cleaner look
                          size: 80,
                          color: Colors.grey,
                        )
                      : null,
                ),

                const SizedBox(height: 24),

                // --- NAME & EMAIL ---
                Text(
                  _name,
                  style: Theme.of(
                    context,
                  ).textTheme.headlineSmall, // Uses Theme Style
                ),
                const SizedBox(height: 8),
                Text(
                  _email,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium, // Uses Theme Style
                ),

                const SizedBox(height: 40),

                // --- STATS BUTTON ---
                if (!_isGuest) ...[
                  ListTile(
                    leading: const Icon(Icons.bar_chart, color: Colors.indigo),
                    title: const Text("My Statistics"),
                    trailing: const Icon(Icons.chevron_right),
                    tileColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const StatsScreen(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                ],

                // --- LOGOUT / LOGIN BUTTON ---
                ListTile(
                  leading: Icon(
                    _isGuest ? Icons.login : Icons.logout,
                    color: Colors.redAccent,
                  ),
                  title: Text(
                    _isGuest ? 'Login' : 'Logout',
                    style: const TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  onTap: _handleLogoutOrLogin,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
