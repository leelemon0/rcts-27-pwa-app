import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/weather_data.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:qr_flutter/qr_flutter.dart';
import 'package:barcode_widget/barcode_widget.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';

import '../models/broadcast.dart';

class BroadcastBanner extends StatelessWidget {
  final String? userHotelKey;
  const BroadcastBanner({super.key, this.userHotelKey});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      // Ordering by timestamp descending ensures the latest message is index 0
      stream: FirebaseFirestore.instance
          .collection('broadcasts')
          .orderBy('timestamp', descending: true)
          .limit(10) // Check the last 10 to find a relevant one
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const SizedBox.shrink();
        }

        // Find the first broadcast that is either "all" or matches the user's hotel
        final broadcasts = snapshot.data!.docs
            .map((doc) => Broadcast.fromMap(doc.data() as Map<String, dynamic>))
            .where((b) => b.visibleFor(userHotelKey))
            .toList();

        if (broadcasts.isEmpty) return const SizedBox.shrink();

        final latest = broadcasts.first;

        return Container(
          margin: const EdgeInsets.only(bottom: 24),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.redAccent.withValues(alpha: 0.1),
            border: Border.all(color: Colors.redAccent.withValues(alpha: 0.5)),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.campaign, color: Colors.redAccent, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      latest.sender.toUpperCase() == 'RYDER CUP TRAVEL SERVICES'
                          ? 'URGENT UPDATE FROM RYDER CUP TRAVEL SERVICES'
                          : 'UPDATE FROM ${latest.sender.toUpperCase()}',
                      style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.redAccent,
                          letterSpacing: 1.1),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      latest.message,
                      style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.white),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class WeatherWidget extends StatefulWidget {
  const WeatherWidget({super.key});

  @override
  State<WeatherWidget> createState() => _WeatherWidgetState();
}

class _WeatherWidgetState extends State<WeatherWidget> {
  late Future<WeatherData> _weatherFuture;

  @override
  void initState() {
    super.initState();
    _weatherFuture = _fetchWeather();
  }

  Future<WeatherData> _fetchWeather() async {
  try {
    final remoteConfig = FirebaseRemoteConfig.instance;
    
    // 1. Configure settings (Lower interval for development, e.g., 1 hour)
    await remoteConfig.setConfigSettings(RemoteConfigSettings(
      fetchTimeout: const Duration(minutes: 1),
      minimumFetchInterval: const Duration(hours: 1), 
    ));

    // 2. Fetch and activate the latest values from Firebase
    await remoteConfig.fetchAndActivate();

    // 3. Retrieve the key you saved in the console
    final String apiKey = remoteConfig.getString('weather_api_key');

    if (apiKey.isEmpty) throw 'API Key not found in Remote Config';

    final url = 'https://api.openweathermap.org/data/2.5/weather?lat=52.5639&lon=-8.7892&appid=$apiKey&units=metric';

    final response = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      return WeatherData.fromJson(jsonDecode(response.body));
    } else {
      throw 'Error: ${response.statusCode}';
    }
  } catch (e) {
    debugPrint('Weather Error: $e');
    throw 'Network Error';
  }
}

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFF003C82).withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: FutureBuilder<WeatherData>(
        future: _weatherFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const SizedBox(
              width: 28, height: 28,
              child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFFFD700)),
            );
          }

          if (snapshot.hasError || !snapshot.hasData) {
            return GestureDetector(
              onTap: () => setState(() => _weatherFuture = _fetchWeather()),
              child: const Column(
                children: [
                  Icon(Icons.refresh, color: Colors.white54, size: 28),
                  SizedBox(height: 4),
                  Text('Retry', style: TextStyle(fontSize: 10, color: Colors.white54)),
                ],
              ),
            );
          }

          final data = snapshot.data!;
          return Column(
            children: [
              Icon(_getWeatherIcon(data.condition), color: const Color(0xFFFFD700), size: 28),
              const SizedBox(height: 4),
              Text('${data.temp.round()}°C', style: const TextStyle(fontWeight: FontWeight.bold)),
              const Text('Adare', style: TextStyle(fontSize: 10, color: Colors.white54)),
            ],
          );
        },
      ),
    );
  }

  IconData _getWeatherIcon(String? condition) {
    final cond = condition?.toLowerCase() ?? '';
    if (cond.contains('cloud')) return Icons.cloud_outlined;
    if (cond.contains('rain') || cond.contains('drizzle')) return Icons.umbrella_outlined;
    if (cond.contains('sun') || cond.contains('clear')) return Icons.wb_sunny_outlined;
    if (cond.contains('thunder')) return Icons.thunderstorm_outlined;
    return Icons.wb_cloudy_outlined;
  }
}

class ItineraryCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Widget details;

  const ItineraryCard(
      {super.key,
      required this.title,
      required this.subtitle,
      required this.icon,
      required this.details});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFF003C82),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        shape: const Border(),
        collapsedShape: const Border(),
        leading: Icon(icon, color: const Color(0xFFFFD700)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle, style: const TextStyle(color: Colors.white70)),
        children: [Padding(padding: const EdgeInsets.all(16.0), child: details)],
      ),
    );
  }
}

class TicketDetails extends StatelessWidget {
  final String ref;
  final String name;

  const TicketDetails({super.key, required this.ref, required this.name});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 10),
        Container(
          color: Colors.white,
          padding: const EdgeInsets.all(10),
          child: QrImageView(
            data: ref, // This uses the 'ref' passed into the widget
            version: QrVersions.auto,
            size: 120.0,
            gapless: false,
          ),
        ),
        const SizedBox(height: 10),
        Text('$name • Ref: $ref', textAlign: TextAlign.center),
        const SizedBox(height: 24),
        const Text('Schedule of Events',
            style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Color(0xFFFFD700),
                fontSize: 16)),
        const SizedBox(height: 12),
        const SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: BouncingScrollPhysics(),
          child: Row(
            children: [
              InfoCard(
                  title: 'Thursday 16 Sept',
                  subtitle: '• Practice Rounds\n• Opening Ceremony'),
              InfoCard(
                  title: 'Friday 17 Sept',
                  subtitle: '• Morning Foursomes\n• Afternoon Four-balls'),
              InfoCard(
                  title: 'Saturday 18 Sept',
                  subtitle: '• Morning Foursomes\n• Afternoon Four-balls'),
              InfoCard(
                  title: 'Sunday 19 Sept',
                  subtitle: '• Singles Matches\n• Trophy Presentation'),
            ],
          ),
        ),
      ],
    );
  }
}

class TournamentDetails extends StatelessWidget {
  const TournamentDetails({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        SizedBox(height: 10),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: BouncingScrollPhysics(),
          child: Row(
            children: [
              InfoCard(
                  title: 'Europe Team',
                  subtitle: 'Captain: Luke Donald\nPlayers: McIlroy, Rahm... ',
                  width: 200),
              InfoCard(
                  title: 'USA Team',
                  subtitle:
                      'Captain: TBD\nPlayers: Scheffler, Schauffele...',
                  width: 200),
              InfoCard(
                  title: 'The Course',
                  subtitle: 'Adare Manor, Limerick\nPar 72, 7,509 Yards',
                  width: 200),
            ],
          ),
        ),
      ],
    );
  }
}

class HotelDetails extends StatelessWidget {
  final String? hotel;
  final String? address;
  final String? room;
  final String? board;
  final VoidCallback? onDirectionsTap;

  const HotelDetails({
    super.key,
    required this.hotel,
    required this.address,
    required this.room,
    required this.board,
    this.onDirectionsTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Hotel: ${hotel ?? 'N/A'}'),
        Text('Address: ${address ?? 'N/A'}'),
        Text('Room: ${room ?? 'N/A'}'),
        Text('Board: ${board ?? 'N/A'}'),
        const SizedBox(height: 16),
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFFFD700),
            foregroundColor: const Color(0xFF001436),
          ),
          icon: const Icon(Icons.map_outlined),
          label: const Text('Directions'),
          onPressed: onDirectionsTap,
        ),
      ],
    );
  }
}

class TransportDetails extends StatelessWidget {
  final String? pickup;
  final String? vehicle;
  final String? hotelKey; // Pass this in
  final String? reference; // Pass this in

  const TransportDetails({
    super.key, 
    required this.vehicle, 
    required this.pickup,
    this.hotelKey,
    this.reference,
  });

  @override
  Widget build(BuildContext context) {
    // Combine data for the barcode: e.g., "ADARE-RC12345"
    final String barcodeData = '${hotelKey ?? 'NA'}-${reference ?? '0000'}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        Text('Pickup Location: ${pickup ?? 'N/A'}', style: const TextStyle(color: Colors.white)),
        Text('Vehicle: ${vehicle ?? 'N/A'}', style: const TextStyle(color: Colors.white70)),
        const SizedBox(height: 20),
        
        // Barcode Section
        Center(
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white, // High contrast for scanners
                  borderRadius: BorderRadius.circular(8),
                ),
                child: BarcodeWidget(
                  barcode: Barcode.code128(), // Standard 1D barcode
                  data: barcodeData,
                  width: 220,
                  height: 70,
                  drawText: false, // Text displayed separately for styling
                ),
              ),
              const SizedBox(height: 8),
              Text(
                barcodeData.toUpperCase(),
                style: const TextStyle(
                  color: Colors.white54, 
                  fontSize: 10, 
                  letterSpacing: 2,
                  fontWeight: FontWeight.bold
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class InfoCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final double width;

  const InfoCard(
      {super.key,
      required this.title,
      required this.subtitle,
      this.width = 160});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF001436),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFFFD700).withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Text(title,
              style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFFFD700),
                  fontSize: 12),
              textAlign: TextAlign.center),
          const SizedBox(height: 6),
          Text(subtitle,
              style: const TextStyle(fontSize: 10, color: Colors.white70),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }
}