import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'firebase_options.dart';
import 'screens/login_screen.dart';

const Color primaryDarkBlue = Color(0xFF001436);
const Color secondaryBlue = Color(0xFF003C82);
const Color accentGold = Color(0xFFFFD700);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const EventPoCApp());
}

class EventPoCApp extends StatelessWidget {
  const EventPoCApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ryder Cup Travel Services 2027',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: primaryDarkBlue,
        primaryColor: primaryDarkBlue,
        colorScheme: const ColorScheme.dark(
          primary: accentGold, 
          secondary: secondaryBlue,
        ),
        fontFamily: 'Gotham',
      ),
      home: const AuthWrapper(),
      routes: {
        '/login': (_) => const LoginScreen(),
      },
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  @override
  void initState() {
    super.initState();
    // Start the check after the framework has initialised
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    // 1. Fetch preferences
    final prefs = await SharedPreferences.getInstance();
    final String? savedRef = prefs.getString('user_ref');
    
    // 2. Critical for Web: Wait for the CanvasKit engine to settle
    // and for the first frame of AuthWrapper to actually mount.
    await Future.delayed(const Duration(milliseconds: 100));

    if (!mounted) return;

    // 3. Perform navigation after the current build frame completes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (savedRef != null) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => LoginScreen(autoLoginRef: savedRef)),
        );
      } else {
        Navigator.of(context).pushReplacementNamed('/login');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // We use a SizedBox instead of a CircularProgressIndicator here.
    // Tickers (animations) during immediate navigation transitions 
    // are the primary cause of 'window.dart:99:12' assertions on Web.
    return const Scaffold(
      body: Center(
        child: SizedBox(
          width: 40,
          height: 40,
          child: Icon(Icons.sports_golf, color: accentGold, size: 32),
        ),
      ),
    );
  }
}