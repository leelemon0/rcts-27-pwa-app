import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;

import '../models/user.dart';
import '../models/client_data.dart';
import 'admin_dashboard.dart';
import 'hotel_manager_dashboard.dart';
import 'itinerary_screen.dart';
import '../models/hotel.dart';

class LoginScreen extends StatefulWidget {
  final String? autoLoginRef;
  const LoginScreen({super.key, this.autoLoginRef});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _isMagicLinkLoading = false;

  @override
  void initState() {
    super.initState();
    _handleIncomingLink();

    if (widget.autoLoginRef != null) {
      _emailController.text = widget.autoLoginRef!;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _handleLogin(isMagicLink: true);
      });
    }
  }

  Future<void> _handleIncomingLink() async {
    final fb_auth.FirebaseAuth auth = fb_auth.FirebaseAuth.instance;
    if (auth.isSignInWithEmailLink(Uri.base.toString())) {
      setState(() => _isLoading = true);
      try {
        final prefs = await SharedPreferences.getInstance();
        String? email = prefs.getString('user_email_for_login');
        email ??= _emailController.text.trim().toLowerCase();

        if (email.isEmpty) throw 'Please enter your email to confirm sign-in.';

        final userCredential = await auth.signInWithEmailLink(
          email: email,
          emailLink: Uri.base.toString(),
        );

        if (userCredential.user != null) {
          _emailController.text = email;
          await _handleLogin(isMagicLink: true); 
        }
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Sign-in error: $e')));
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleLogin({bool isMagicLink = false}) async {
    final email = _emailController.text.trim().toLowerCase();
    final enteredPassword = _passwordController.text.trim();

    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter your email.')));
      return;
    }

    setState(() => _isLoading = true);

    try {
      final DocumentSnapshot? userDoc = await _findUserDoc(email);

      if (userDoc == null || !userDoc.exists) {
        if (!mounted) return;
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('User not found.')));
        return;
      }

      // 1. EXTRACT PASSWORD LOGIC
      // Fetch the 'ref' field. If it's a superuser/manager, it might not have a ref, 
      // so we provide a fallback or different logic.
      final userDataMap = userDoc.data() as Map<String, dynamic>;
      final String? userRef = userDataMap['ref']?.toString();
      
      if (!isMagicLink) {
        String requiredPassword = "";
        
        if (userRef != null && userRef.length >= 4) {
          requiredPassword = userRef.substring(userRef.length - 4);
        } else {
          // Fallback for accounts without a long enough ref (like admins)
          requiredPassword = "RyderCup"; 
        }

        if (enteredPassword != requiredPassword) {
          if (!mounted) return;
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Incorrect password. Use the last 4 digits of your reference.'))
          );
          return;
        }
      }

      // 2. PROCEED WITH SESSION
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_ref', email);

      final userData = User.fromMap(userDoc.id, userDataMap);
      
      Hotel? hotelData;
      if (userData.hotelKey != null && userData.hotelKey!.isNotEmpty) {
        try {
          final hotelDoc = await FirebaseFirestore.instance
              .collection('hotels')
              .doc(userData.hotelKey)
              .get(const GetOptions(source: Source.serverAndCache));
          if (hotelDoc.exists) {
            hotelData = Hotel.fromMap(hotelDoc.id, hotelDoc.data() as Map<String, dynamic>);
          }
        } catch (e) {
          debugPrint("Hotel fetch failed: $e");
        }
      }

      final data = ClientData(user: userData, hotel: hotelData);

      if (!mounted) return;
      setState(() => _isLoading = false);

      Widget nextScreen;
      if (data.user.role == 'superuser') {
        nextScreen = const AdminDashboard();
      } else if (data.user.role == 'manager') {
        nextScreen = HotelManagerDashboard(managerData: data.user);
      } else {
        nextScreen = ItineraryScreen(clientData: data);
      }

      Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => nextScreen), (route) => false);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Unable to login.')));
    }
  }

  Future<void> _sendMagicLink() async {
    final email = _emailController.text.trim().toLowerCase();
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter email first.')));
      return;
    }
    setState(() => _isMagicLinkLoading = true);
    try {
      var acs = fb_auth.ActionCodeSettings(
        url: "http://localhost:5000", 
        handleCodeInApp: true,
        androidPackageName: "com.rcts.app",
        androidInstallApp: true,
        androidMinimumVersion: "1",
      );
      await fb_auth.FirebaseAuth.instance.sendSignInLinkToEmail(email: email, actionCodeSettings: acs);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_email_for_login', email);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(backgroundColor: Colors.green, content: Text('Magic link sent!')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isMagicLinkLoading = false);
    }
  }

  Future<DocumentSnapshot?> _findUserDoc(String email) async {
    const collections = ['staff', 'guests'];
    for (final collection in collections) {
      try {
        final primaryDoc = await FirebaseFirestore.instance.collection(collection).doc(email).get(const GetOptions(source: Source.serverAndCache));
        if (primaryDoc.exists) return primaryDoc;
        final querySnapshot = await FirebaseFirestore.instance.collection(collection).where('email', isEqualTo: email).limit(1).get(const GetOptions(source: Source.serverAndCache));
        if (querySnapshot.docs.isNotEmpty) return querySnapshot.docs.first;
      } catch (e) {
        debugPrint("Check failed: $e");
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
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
                Image.asset('web/icons/MatchShield.png', height: 120, errorBuilder: (c, e, s) => const Icon(Icons.shield, size: 100, color: Color(0xFFFFD700))),
                const SizedBox(height: 40),
                const Text('RYDER CUP', style: TextStyle(color: Colors.white, letterSpacing: 4, fontSize: 14)),
                const Text('Travel Services', style: TextStyle(color: Color(0xFFFFD700), fontSize: 28, fontWeight: FontWeight.bold)),
                const SizedBox(height: 48),
                TextField(
                  controller: _emailController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Email',
                    hintStyle: const TextStyle(color: Colors.white38),
                    prefixIcon: const Icon(Icons.email_outlined, color: Color(0xFFFFD700)),
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: .05),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.white10)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFFFD700))),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Last 4 digits of Ref',
                    hintStyle: const TextStyle(color: Colors.white38),
                    prefixIcon: const Icon(Icons.lock_outline, color: Color(0xFFFFD700)),
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: .05),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.white10)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFFFD700))),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFFD700), foregroundColor: const Color(0xFF001436), padding: const EdgeInsets.symmetric(vertical: 18), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                    onPressed: _isLoading ? null : () => _handleLogin(isMagicLink: false),
                    child: _isLoading ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('SIGN IN'),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 18), side: const BorderSide(color: Color(0xFFFFD700)), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                    onPressed: _isMagicLinkLoading ? null : _sendMagicLink,
                    child: _isMagicLinkLoading ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('SEND MAGIC LINK (NO PASSWORD)', style: TextStyle(color: Color(0xFFFFD700))),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}