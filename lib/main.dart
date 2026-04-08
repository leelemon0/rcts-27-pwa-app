import 'package:flutter/material.dart';

import 'screens/login_screen.dart';

const Color primaryDarkBlue = Color(0xFF001436);
const Color secondaryBlue = Color(0xFF003C82);
const Color accentGold = Color(0xFFFFD700);

void main() {
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
        colorScheme: const ColorScheme.dark(primary: accentGold, secondary: secondaryBlue),
        fontFamily: 'Gotham',
      ),
      initialRoute: '/login',
      routes: {
        '/login': (_) => const LoginScreen(),
      },
    );
  }
}
