import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Add this import

import '../models/user.dart';
import '../models/client_data.dart';
import 'admin_dashboard.dart';
import 'hotel_manager_dashboard.dart';
import 'itinerary_screen.dart';
import '../models/hotel.dart';

class LoginScreen extends StatefulWidget {
  final String? autoLoginRef;

  const LoginScreen({super.key, this.autoLoginRef}); // Update constructor

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // If a saved email was found by the AuthWrapper, auto-fill and login
    if (widget.autoLoginRef != null) {
      _emailController.text = widget.autoLoginRef!;
      // Use postFrameCallback to ensure the context is ready before logging in
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _handleLogin();
      });
    }
  }

  Future<void> _handleLogin() async {
    final email = _emailController.text.trim().toLowerCase();
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your booking email.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final DocumentSnapshot? userDoc = await _findUserDoc(email);

      // 3. FINAL VALIDATION
      if (userDoc == null || !userDoc.exists) {
        if (!mounted) return;
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User not found.')),
        );
        return;
      }

      // PERSISTENCE
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_ref', email);

      // 4. MAP DATA
      final userData = User.fromMap(userDoc.id, userDoc.data() as Map<String, dynamic>);
      
      Hotel? hotelData;
      if (userData.hotelKey != null && userData.hotelKey!.isNotEmpty) {
        final hotelDoc = await FirebaseFirestore.instance
            .collection('hotels')
            .doc(userData.hotelKey)
            .get();
        
        if (hotelDoc.exists) {
          hotelData = Hotel.fromMap(hotelDoc.id, hotelDoc.data() as Map<String, dynamic>);
        }
      }

      final data = ClientData(user: userData, hotel: hotelData);

      if (!mounted) return;
      setState(() => _isLoading = false);

      // 5. NAVIGATION
      Widget nextScreen;
      if (data.user.role == 'superuser') {
        nextScreen = const AdminDashboard();
      } else if (data.user.role == 'manager') {
        nextScreen = HotelManagerDashboard(managerData: data.user);
      } else {
        nextScreen = ItineraryScreen(clientData: data);
      }

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => nextScreen),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Connection Error: $e')),
      );
    }
  }

  Future<DocumentSnapshot?> _findUserDoc(String email) async {
    const collections = ['staff', 'guests'];

    for (final collection in collections) {
      final primaryDoc = await FirebaseFirestore.instance
          .collection(collection)
          .doc(email)
          .get();

      if (primaryDoc.exists) {
        return primaryDoc;
      }

      final querySnapshot = await FirebaseFirestore.instance
          .collection(collection)
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        return querySnapshot.docs.first;
      }
    }

    return null;
  }

@override
Widget build(BuildContext context) {
  return Scaffold(
    body: Container(
      // Adding a subtle gradient gives a more premium feel than a flat colour
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF001A44), Color(0xFF000B1E)],
        ),
      ),
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo with a slight glow or shadow effect
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFFD700).withValues(alpha: 0.1),
                      blurRadius: 20,
                      spreadRadius: 5,
                    )
                  ],
                ),
                child: Image.asset(
                  'web/icons/MatchShield.png',
                  height: 120,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) =>
                      const Icon(Icons.shield, size: 100, color: Color(0xFFFFD700)),
                ),
              ),
              const SizedBox(height: 40),
              const Text(
                'RYDER CUP',
                style: TextStyle(
                  color: Colors.white,
                  letterSpacing: 4,
                  fontSize: 14,
                  fontWeight: FontWeight.w300,
                ),
              ),
              const Text(
                'Travel Services',
                style: TextStyle(
                  color: Color(0xFFFFD700),
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 48),
              // Modernized TextField
              TextField(
                controller: _emailController,
                style: const TextStyle(color: Colors.white),
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  hintText: 'Enter your booking email',
                  hintStyle: const TextStyle(color: Colors.white38),
                  prefixIcon: const Icon(Icons.email_outlined, color: Color(0xFFFFD700)),
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.05),
                  contentPadding: const EdgeInsets.symmetric(vertical: 20),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.white10),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFFFD700)),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFD700),
                    foregroundColor: const Color(0xFF001436),
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  onPressed: _isLoading ? null : _handleLogin,
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF001436)),
                        )
                      : const Text('SIGN IN', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                ),
              ),
              const SizedBox(height: 60),
              // Subtler instructions
              Text(
                'Tap install, or go to browser options and press "Add to Home Screen" to install.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
}