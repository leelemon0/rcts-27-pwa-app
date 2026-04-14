import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'firebase_options.dart';
import 'screens/login_screen.dart';
import 'version_check_service.dart';
import 'dart:async';

const Color primaryDarkBlue = Color(0xFF001436);
const Color secondaryBlue = Color(0xFF003C82);
const Color accentGold = Color(0xFFFFD700);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
    cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
  );

  try {
    final remoteConfig = FirebaseRemoteConfig.instance;
    await remoteConfig.setConfigSettings(RemoteConfigSettings(
      fetchTimeout: const Duration(seconds: 10),
      minimumFetchInterval: const Duration(hours: 1),
    ));
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
  Timer? _versionTimer;

  @override
  void initState() {
    super.initState();
    
    // 1. Existing nudge timer to prevent web freeze
    _nudgeTimer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      if (mounted) setState(() {});
    });

    // Version Check Logic
    _initVersionCheck();

    _checkLoginStatus();
  }

  void _initVersionCheck() {
    final versionService = VersionCheckService();
    
    // Check immediately on app launch
    versionService.checkForUpdate();

    // Check every 15 minutes while the app is open
    _versionTimer = Timer.periodic(const Duration(minutes: 15), (timer) {
      versionService.checkForUpdate();
    });
  }

  Future<void> _checkLoginStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? savedRef = prefs.getString('user_ref');

      if (!mounted) return;

      if (savedRef != null) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => LoginScreen(autoLoginRef: savedRef)),
        );
      } else {
        Navigator.of(context).pushReplacementNamed('/login');
      }
    } catch (e) {
      Navigator.of(context).pushReplacementNamed('/login');
    }
  }

  @override
  void dispose() {
    _nudgeTimer?.cancel();
    _versionTimer?.cancel(); // CLEAN UP THE TIMER
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