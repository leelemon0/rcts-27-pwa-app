import 'package:flutter/material.dart';

import '../models/client_data.dart';
import '../services/mock_database.dart';
import 'admin_dashboard.dart';
import 'hotel_manager_dashboard.dart';
import 'itinerary_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  bool _isLoading = false;

  Future<void> _handleLogin() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your booking email.')),
      );
      return;
    }

    setState(() => _isLoading = true);
    final ClientData? data = await MockDatabase.getClientData(email);
    if (!mounted) return;

    setState(() => _isLoading = false);
    if (data == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User not found.')),
      );
      return;
    }

    Widget nextScreen;
    if (data.user.role == 'superuser') {
      nextScreen = const AdminDashboard();
    } else if (data.user.role == 'manager') {
      nextScreen = HotelManagerDashboard(managerData: data.user);
    } else {
      nextScreen = ItineraryScreen(clientData: data);
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => nextScreen),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(32.0),
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 80),
              Image.asset(
                'web/icons/MatchShield.png',
                height: 100,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return const Icon(Icons.shield, size: 80, color: Color(0xFFFFD700));
                },
              ),
              const SizedBox(height: 24),
              const Text(
                'Welcome to the Ryder Cup Travel Services app',
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              const Text(
                'Press "Add to Home Screen" to save this on your phone',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const Divider(color: Colors.white24),
              const SizedBox(height: 8),
              const Text(
                'Enter your booking email to receive a magic sign-in link.',
                style: TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),
              TextField(
                controller: _emailController,
                style: const TextStyle(color: Colors.black),
                decoration: const InputDecoration(
                  hintText: 'Email address',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFFD700),
                  foregroundColor: const Color(0xFF001436),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                onPressed: _isLoading ? null : _handleLogin,
                child: _isLoading
                    ? const CircularProgressIndicator(color: Color(0xFF001436))
                    : const Text('Send Magic Link'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
