import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:universitynavigationapp/models/api_constants.dart';
import '../services/user_session.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final GoogleSignIn _googleSignIn = GoogleSignIn(scopes: ['email']);
  bool _isSigningIn = false;

  Future<void> _handleGoogleSignIn() async {
    setState(() => _isSigningIn = true);

    try {
      // 1. Start Google Login
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        setState(() => _isSigningIn = false);
        return; // User canceled
      }

      // 2. Send to PHP Backend
      final response = await http.post(
        Uri.parse(ApiConstants.authUser),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'google_id': googleUser.id,
          'email': googleUser.email,
          'display_name': googleUser.displayName ?? '',
          'photo_url': googleUser.photoUrl ?? '',
        }),
      );

      // 3. Handle Response
      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);

        if (responseData['status'] == 'success') {
          // --- SUCCESS: Proceed to Home ---
          await UserSession.saveUser(
            googleUser.email,
            googleUser.displayName ?? 'User',
            googleUser.photoUrl,
            // If you added role to UserSession, save it here too
          );

          if (mounted) {
            Navigator.pushReplacementNamed(context, '/home');
          }
        } else {
          // --- FAILURE (e.g., BANNED) ---

          // *** CRITICAL FIX: FORCE GOOGLE LOGOUT ***
          await _googleSignIn.signOut();

          if (mounted) {
            _showError(responseData['message'] ?? "Login Failed");
          }
        }
      } else {
        // --- SERVER ERROR (500, 404, etc.) ---
        await _googleSignIn.signOut(); // Safety logout
        _showError("Server Error: ${response.statusCode}");
      }
    } catch (error) {
      debugPrint("Google SignIn / Server Connection Error: $error");
      await _googleSignIn.signOut(); // Safety logout
      _showError("Error: $error");
    } finally {
      if (mounted) setState(() => _isSigningIn = false);
    }
  }

  // Helper for substring
  int min(int a, int b) => a < b ? a : b;

  Future<void> _handleGuestLogin() async {
    await UserSession.loginAsGuest();
    if (mounted) Navigator.pushReplacementNamed(context, '/home');
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            color: const Color(
              0xFF1A237E,
            ).withValues(alpha: 0.95), // Indigo overlay
          ),

          // 2. Content
          Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // White Logo for contrast
                  Image.asset('assets/images/logoRMUTT.png', height: 120),
                  const SizedBox(height: 30),

                  const Text(
                    'RMUTT\nNavigation',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: 2.0,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Your guide to RMUTT',
                    style: TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                  const SizedBox(height: 60),

                  // Modern Google Button
                  _isSigningIn
                      ? const CircularProgressIndicator(color: Colors.white)
                      : SizedBox(
                          width: double.infinity,
                          height: 55,
                          child: ElevatedButton.icon(
                            onPressed: _handleGoogleSignIn,
                            icon: Image.asset(
                              'assets/images/google.png',
                              height: 24,
                            ),
                            label: const Text(
                              'Continue with Google',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white, // White button
                              foregroundColor: Colors.black,
                              elevation: 5,
                            ),
                          ),
                        ),

                  const SizedBox(height: 20),

                  // Guest Button (Transparent)
                  TextButton(
                    onPressed: _handleGuestLogin,
                    child: const Text(
                      'Skip and Continue as Guest',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
