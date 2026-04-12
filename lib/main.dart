import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart'; // Add this
import 'firebase_options.dart';
import 'screens/login_screen.dart';
import 'dart:async';

const Color primaryDarkBlue = Color(0xFF001436);
const Color secondaryBlue = Color(0xFF003C82);
const Color accentGold = Color(0xFFFFD700);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // --- REMOTE CONFIG WARM UP ---
  try {
    final remoteConfig = FirebaseRemoteConfig.instance;
    await remoteConfig.setConfigSettings(RemoteConfigSettings(
      fetchTimeout: const Duration(seconds: 10),
      minimumFetchInterval: const Duration(hours: 1), // Standard for production
    ));
    // Fetch and activate so the key is ready immediately for the WeatherWidget
    await remoteConfig.fetchAndActivate();
  } catch (e) {
    debugPrint('Remote Config initialization failed: $e');
  }

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
  Timer? _nudgeTimer;

  @override
  void initState() {
    super.initState();
    
    // 1. Force the browser to keep painting (avoids the freeze)
    _nudgeTimer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      if (mounted) setState(() {});
    });

    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    try {
      // 2. Warm up Remote Config inside the wrapper instead of main()
      final remoteConfig = FirebaseRemoteConfig.instance;
      await remoteConfig.fetchAndActivate();

      final prefs = await SharedPreferences.getInstance();
      final String? savedRef = prefs.getString('user_ref');

      // 3. Give the UI one last second to settle
      await Future.delayed(const Duration(seconds: 1));

      if (!mounted) return;
      
      // Stop the nudge timer before moving away
      _nudgeTimer?.cancel();

      if (savedRef != null) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => LoginScreen(autoLoginRef: savedRef)),
        );
      } else {
        Navigator.of(context).pushReplacementNamed('/login');
      }
    } catch (e) {
      debugPrint("Init Error: $e");
      // Even if it fails, navigate to login so the user isn't stuck
      Navigator.of(context).pushReplacementNamed('/login');
    }
  }

  @override
  void dispose() {
    _nudgeTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(color: accentGold),
      ),
    );
  }
}