import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/client_data.dart';
import '../services/mock_database.dart';
import '../widgets/shared_widgets.dart';

class ItineraryScreen extends StatefulWidget {
  final ClientData clientData;
  const ItineraryScreen({super.key, required this.clientData});

  @override
  State<ItineraryScreen> createState() => _ItineraryScreenState();
}

class _ItineraryScreenState extends State<ItineraryScreen> {
  final TextEditingController _subjectController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  void _handleLogout() {
    Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    final currentRoomID = widget.clientData.user.roomID;
    final currentUserName = widget.clientData.user.name;
    final sharers = MockDatabase.users.values
        .where((user) =>
            user.roomID == currentRoomID &&
            user.name != currentUserName &&
            user.hotelKey == widget.clientData.user.hotelKey)
        .map((user) => user.name)
        .join(', ');

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF001436),
        leadingWidth: 200,
        leading: Padding(
          padding: const EdgeInsets.only(left: 16.0),
          child: Image.asset(
            'web/icons/EventLogo.png',
            height: 40,
            fit: BoxFit.contain,
            filterQuality: FilterQuality.high,
            errorBuilder: (context, error, stackTrace) {
              return const Icon(Icons.confirmation_num_outlined, color: Color(0xFFFFD700));
            },
          ),
        ),
        title: const Text('RCTS Event Guide', style: TextStyle(fontSize: 18)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Color(0xFFFFD700)),
            onPressed: _handleLogout,
          )
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                BroadcastBanner(userHotelKey: widget.clientData.user.hotelKey),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${_getGreeting()} ${widget.clientData.user.name},',
                            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          const Text('View your 2027 Ryder Cup details:', style: TextStyle(color: Colors.white70)),
                        ],
                      ),
                    ),
                    const WeatherWidget(),
                  ],
                ),
                const SizedBox(height: 24),
                ItineraryCard(
                  title: '2027 Ryder Cup',
                  subtitle: 'General Admission - 4-day Ticket',
                  icon: Icons.stadium,
                  details: TicketDetails(
                    ref: widget.clientData.user.ref ?? '',
                    name: widget.clientData.user.name,
                  ),
                ),
                const SizedBox(height: 16),
                ItineraryCard(
                  title: widget.clientData.hotelName ?? 'Hotel Information',
                  subtitle: 'Check-in: 15 Sept, 15:00',
                  icon: Icons.hotel,
                  details: HotelDetails(
                    hotel: widget.clientData.hotelName,
                    address: widget.clientData.address,
                    room: sharers.isNotEmpty ? '${widget.clientData.user.room} (Sharing with: $sharers)' : widget.clientData.user.room,
                    board: widget.clientData.board,
                  ),
                ),
                const SizedBox(height: 16),
                ItineraryCard(
                  title: 'Coach Transfer',
                  subtitle: 'Status: Confirmed',
                  icon: Icons.directions_bus,
                  details: TransportDetails(
                    vehicle: widget.clientData.transport,
                    pickup: widget.clientData.pickup,
                  ),
                ),
                const SizedBox(height: 16),
                const ItineraryCard(
                  title: 'Tournament Info',
                  subtitle: 'Players, Matchups & History',
                  icon: Icons.info_outline,
                  details: TournamentDetails(),
                ),
                const SizedBox(height: 16),
                ItineraryCard(
                  title: 'THE BUNKER',
                  subtitle: 'Exclusive Content & Guides',
                  icon: Icons.shopping_cart_outlined,
                  details: Column(
                    children: [
                      const Text(
                        'Access exclusive tournament content, behind-the-scenes footage, and the info about the area through the RCTS digital portal.',
                        style: TextStyle(fontSize: 13, height: 1.4),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFFD700),
                          foregroundColor: const Color(0xFF001436),
                        ),
                        onPressed: () async {
                            final messenger = ScaffoldMessenger.of(context);
                            final Uri url = Uri.parse('https://www.rydercuptravelservices.com/');
                            final bool launched = await launchUrl(url);
                            if (!mounted) return;
                            if (!launched) {
                              messenger.showSnackBar(const SnackBar(content: Text('Could not open external site.')));
                          }
                        },
                        child: const Text('Enter The Bunker'),
                      )
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF003C82),
                foregroundColor: const Color(0xFFFFD700),
                minimumSize: const Size(double.infinity, 50),
                side: const BorderSide(color: Color(0xFFFFD700)),
              ),
              icon: const Icon(Icons.support_agent),
              label: const Text('Contact Support'),
              onPressed: _showContactForm,
            ),
          ),
        ],
      ),
    );
  }

  void _showContactForm() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF001436),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 24,
          right: 24,
          top: 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Support Request', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFFFFD700))),
            const SizedBox(height: 20),
            TextField(controller: _subjectController, decoration: const InputDecoration(labelText: 'Subject', filled: true, fillColor: Colors.white10)),
            const SizedBox(height: 12),
            TextField(controller: _messageController, maxLines: 4, decoration: const InputDecoration(labelText: 'Message', filled: true, fillColor: Colors.white10)),
            const SizedBox(height: 24),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFFD700), foregroundColor: const Color(0xFF001436)),
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(backgroundColor: Colors.green, content: Text('Message Sent.')));
              },
              child: const Text('Submit'),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}
