import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/mock_database.dart';

class BroadcastBanner extends StatelessWidget {
  final String? userHotelKey;
  const BroadcastBanner({super.key, this.userHotelKey});

  @override
  Widget build(BuildContext context) {
    final visibleBroadcasts = MockDatabase.broadcasts.where((broadcast) => broadcast.visibleFor(userHotelKey)).toList();
    if (visibleBroadcasts.isEmpty) return const SizedBox.shrink();

    final latest = visibleBroadcasts.first;
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
                  latest.sender == 'RYDER CUP TRAVEL SERVICES'
                      ? 'URGENT UPDATE FROM RYDER CUP TRAVEL SERVICES'
                      : 'UPDATE FROM ${latest.sender}',
                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.redAccent, letterSpacing: 1.1),
                ),
                const SizedBox(height: 4),
                Text(
                  latest.message,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.white),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class WeatherWidget extends StatelessWidget {
  const WeatherWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFF003C82).withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: const Column(
        children: [
          Icon(Icons.wb_sunny_outlined, color: Color(0xFFFFD700), size: 28),
          SizedBox(height: 4),
          Text('18°C', style: TextStyle(fontWeight: FontWeight.bold)),
          Text('Adare', style: TextStyle(fontSize: 10, color: Colors.white54)),
        ],
      ),
    );
  }
}

class ItineraryCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Widget details;

  const ItineraryCard({super.key, required this.title, required this.subtitle, required this.icon, required this.details});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFF003C82),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
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
        const Divider(color: Colors.white24),
        const SizedBox(height: 10),
        Container(
          color: Colors.white,
          padding: const EdgeInsets.all(10),
          child: const Icon(Icons.qr_code, size: 100, color: Colors.black),
        ),
        const SizedBox(height: 10),
        Text('$name • Ref: $ref', textAlign: TextAlign.center),
        const SizedBox(height: 24),
        const Text('Schedule of Events', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFFFD700), fontSize: 16)),
        const SizedBox(height: 12),
        const SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: BouncingScrollPhysics(),
          child: Row(
            children: [
              InfoCard(title: 'Thursday 16 Sept', subtitle: '• Practice Rounds\n• Opening Ceremony'),
              InfoCard(title: 'Friday 17 Sept', subtitle: '• Morning Foursomes\n• Afternoon Four-balls'),
              InfoCard(title: 'Saturday 18 Sept', subtitle: '• Morning Foursomes\n• Afternoon Four-balls'),
              InfoCard(title: 'Sunday 19 Sept', subtitle: '• Singles Matches\n• Trophy Presentation'),
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
        Divider(color: Colors.white24),
        SizedBox(height: 10),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: BouncingScrollPhysics(),
          child: Row(
            children: [
              InfoCard(title: 'Europe Team', subtitle: 'Captain: Luke Donald\nPlayers: McIlroy, Rahm... ', width: 200),
              InfoCard(title: 'USA Team', subtitle: 'Captain: TBD\nPlayers: Scheffler, Schauffele...', width: 200),
              InfoCard(title: 'The Course', subtitle: 'Adare Manor, Limerick\nPar 72, 7,509 Yards', width: 200),
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

  const HotelDetails({super.key, required this.hotel, required this.address, required this.room, required this.board});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(),
        Text('Hotel: ${hotel ?? 'N/A'}'),
        Text('Address: ${address ?? 'N/A'}'),
        Text('Room: ${room ?? 'N/A'}'),
        Text('Board: ${board ?? 'N/A'}'),
        const SizedBox(height: 16),
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFFD700), foregroundColor: const Color(0xFF001436)),
          icon: const Icon(Icons.map_outlined),
          label: const Text('Directions'),
          onPressed: () async {
            final messenger = ScaffoldMessenger.of(context);
            final query = Uri.encodeComponent(address ?? hotel ?? 'Ireland');
            final Uri url = Uri.parse('https://www.google.com/maps/search/?api=1&query=$query');
            if (await canLaunchUrl(url)) {
              await launchUrl(url, mode: LaunchMode.externalApplication);
            } else {
              messenger.showSnackBar(const SnackBar(content: Text('Could not launch maps.')));
            }
          },
        ),
      ],
    );
  }
}

class TransportDetails extends StatelessWidget {
  final String? pickup;
  final String? vehicle;

  const TransportDetails({super.key, required this.vehicle, required this.pickup});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(),
        Text('Pickup Location: ${pickup ?? 'N/A'}'),
        Text('Vehicle: ${vehicle ?? 'N/A'}'),
      ],
    );
  }
}

class InfoCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final double width;

  const InfoCard({super.key, required this.title, required this.subtitle, this.width = 160});

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
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFFFD700), fontSize: 12), textAlign: TextAlign.center),
          const SizedBox(height: 6),
          Text(subtitle, style: const TextStyle(fontSize: 10, color: Colors.white70), textAlign: TextAlign.center),
        ],
      ),
    );
  }
}
