import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/client_data.dart';
import '../models/hotel.dart';
import '../models/user.dart';
import '../widgets/shared_widgets.dart';

class ItineraryScreen extends StatefulWidget {
  final ClientData clientData;
  const ItineraryScreen({super.key, required this.clientData});

  @override
  State<ItineraryScreen> createState() => _ItineraryScreenState();
}

class _ItineraryScreenState extends State<ItineraryScreen>
    with AutomaticKeepAliveClientMixin {
  final TextEditingController _subjectController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();

  @override
  bool get wantKeepAlive => true;

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  Future<void> _openMapDirections(String? coords) async {
    if (coords == null || coords.isEmpty) return;

    final Uri googleMapsUrl = Uri.parse("https://www.google.com/maps/search/?api=1&query=$coords");
    final Uri appleMapsUrl = Uri.parse("https://maps.apple.com/?q=$coords");

    if (await canLaunchUrl(googleMapsUrl)) {
      await launchUrl(googleMapsUrl, mode: LaunchMode.externalApplication);
    } else if (await canLaunchUrl(appleMapsUrl)) {
      await launchUrl(appleMapsUrl, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open maps application.')),
        );
      }
    }
  }

void _handleLogout() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF001436),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: const Text(
            'Confirm Logout',
            style: TextStyle(color: Color(0xFFFFD700)),
          ),
          content: const Text(
            'Are you sure you want to sign out?',
            style: TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('CANCEL', style: TextStyle(color: Colors.white38)),
            ),
            TextButton(
              onPressed: () async {
                final prefs = await SharedPreferences.getInstance();
                await prefs.remove('user_ref');
                
                // Guard the async gap: ensure the dialog/screen is still present
                if (!context.mounted) return; 

                Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
              },
              child: const Text(
                'LOGOUT',
                style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final user = widget.clientData.user;

    return Scaffold(
      backgroundColor: const Color(0xFF001436),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFF001436),
        leadingWidth: 120,
        leading: Padding(
          padding: const EdgeInsets.only(left: 16.0),
          child: Image.asset(
            'web/icons/EventLogo.png',
            fit: BoxFit.contain,
            filterQuality: FilterQuality.high,
            errorBuilder: (context, error, stackTrace) =>
                const Icon(Icons.emoji_events_outlined, color: Color(0xFFFFD700)),
          ),
        ),
        title: const Text(
          'EVENT GUIDE',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Color(0xFFFFD700)),
            onPressed: _handleLogout,
          )
        ],
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('hotels')
            .doc(user.hotelKey)
            .snapshots(),
        builder: (context, hotelSnapshot) {
          final liveHotel = hotelSnapshot.hasData && hotelSnapshot.data!.exists
              ? Hotel.fromMap(hotelSnapshot.data!.id,
                  hotelSnapshot.data!.data() as Map<String, dynamic>)
              : widget.clientData.hotel;

          return Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  children: [
                    BroadcastBanner(userHotelKey: user.hotelKey),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${_getGreeting()} ${user.name},',
                                style: const TextStyle(
                                    fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                              ),
                              const SizedBox(height: 4),
                              const Text('View your 2027 Ryder Cup details:',
                                  style: TextStyle(color: Colors.white60)),
                            ],
                          ),
                        ),
                        const WeatherWidget(),
                      ],
                    ),
                    const SizedBox(height: 24),
                    if (user.hasTicket) ...[
                      ItineraryCard(
                        title: '2027 Ryder Cup',
                        subtitle: 'General Admission - 4-day Ticket',
                        icon: Icons.confirmation_number_outlined,
                        details: TicketDetails(
                          ref: user.ref ?? '',
                          name: user.name,
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    _buildHotelCard(user, liveHotel),
                    if (liveHotel?.hotelType == 'glamping' || liveHotel?.hotelType == 'cruise') ...[
                      const SizedBox(height: 16),
                      ItineraryCard(
                        title: 'All-Inclusive Experience Guide',
                        subtitle: 'Everything included in your stay',
                        icon: Icons.auto_awesome_outlined,
                        details: Text(
                          liveHotel?.experienceGuide ?? 'Guide information will be available shortly.',
                          style: const TextStyle(color: Colors.white70, height: 1.4),
                        ),
                      ),
                      const SizedBox(height: 16),
                      ItineraryCard(
                        title: '${liveHotel?.hotelName} Entertainment',
                        subtitle: 'Daily activities & shows',
                        icon: Icons.theater_comedy_outlined,
                        details: Text(
                          liveHotel?.entertainmentSchedule ?? 'Schedule will be updated soon.',
                          style: const TextStyle(color: Colors.white70, height: 1.4),
                        ),
                      ),
                    ],
                    if (user.hasTransport) ...[
                      const SizedBox(height: 16),
                      ItineraryCard(
                        title: 'Ground Transportation',
                        subtitle: 'Status: Confirmed',
                        icon: Icons.directions_bus_outlined,
                        details: TransportDetails(
                          vehicle: liveHotel?.transport ?? widget.clientData.transport,
                          pickup: liveHotel?.pickup ?? widget.clientData.pickup,
                          hotelKey: user.hotelKey,
                          reference: user.ref,
                          // Pass the schedules here
                          thu: liveHotel?.transportThursday,
                          fri: liveHotel?.transportFriday,
                          sat: liveHotel?.transportSaturday,
                          sun: liveHotel?.transportSunday,
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    const ItineraryCard(
                      title: 'Tournament Info',
                      subtitle: 'Players, Matchups & History',
                      icon: Icons.info_outline_rounded,
                      details: TournamentDetails(),
                    ),
                    const SizedBox(height: 16),
                    _buildBunkerCard(),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
              _buildSupportButton(),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHotelCard(User user, Hotel? hotel) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('guests')
          .where('hotelKey', isEqualTo: user.hotelKey)
          .where('roomID', isEqualTo: user.roomID)
          .snapshots(),
      builder: (context, snapshot) {
        String sharersText = "";
        if (snapshot.hasData) {
          final sharers = snapshot.data!.docs
              .map((doc) => doc['name'] as String)
              .where((name) => name != user.name)
              .join(', ');
          sharersText = sharers.isNotEmpty ? ' (Sharing with: $sharers)' : '';
        }

        return ItineraryCard(
          title: hotel?.hotelName ?? 'Hotel Information',
          subtitle: 'Check-in: 15 Sept, 15:00',
          icon: Icons.hotel_outlined,
          details: HotelDetails(
            hotel: hotel?.hotelName,
            address: hotel?.address,
            room: '${user.room}$sharersText',
            board: hotel?.board,
            onDirectionsTap: () => _openMapDirections(hotel?.coordinates),
          ),
        );
      },
    );
  }

  Widget _buildBunkerCard() {
    return ItineraryCard(
      title: 'The Bunker',
      subtitle: 'Exclusive Content & Guides',
      icon: Icons.diamond_outlined,
      details: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Access exclusive tournament content, behind-the-scenes footage, and the info about the area through the RCTS digital portal.',
            style: TextStyle(fontSize: 13, height: 1.4, color: Colors.white70),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFFD700),
              foregroundColor: const Color(0xFF001436),
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            onPressed: () async {
              final Uri url = Uri.parse('https://www.rydercuptravelservices.com/');
              if (await canLaunchUrl(url)) {
                await launchUrl(url);
              }
            },
            child: const Text('ENTER THE BUNKER', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1)),
          )
        ],
      ),
    );
  }

  Widget _buildSupportButton() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF001436),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 10, offset: const Offset(0, -2))],
      ),
      padding: const EdgeInsets.all(16.0),
      child: SafeArea(
        top: false,
        child: ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF003C82),
            foregroundColor: const Color(0xFFFFD700),
            minimumSize: const Size(double.infinity, 56),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            side: const BorderSide(color: Color(0xFFFFD700), width: 1),
          ),
          icon: const Icon(Icons.support_agent_rounded),
          label: const Text('CONTACT SUPPORT', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1)),
          onPressed: _showContactForm,
        ),
      ),
    );
  }

  void _showContactForm() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF001436),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 24, right: 24, top: 32,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Support Request',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFFFFD700))),
            const SizedBox(height: 8),
            const Text('How can we help you today?', style: TextStyle(color: Colors.white60, fontSize: 14)),
            const SizedBox(height: 24),
            TextField(
                controller: _subjectController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Subject',
                  labelStyle: const TextStyle(color: Colors.white38),
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.05),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFFFD700))),
                )),
            const SizedBox(height: 16),
            TextField(
                controller: _messageController,
                maxLines: 4,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Message',
                  labelStyle: const TextStyle(color: Colors.white38),
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.05),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFFFD700))),
                )),
            const SizedBox(height: 24),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFD700),
                foregroundColor: const Color(0xFF001436),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () async {
                final String subject = _subjectController.text.trim();
                final String message = _messageController.text.trim();

                if (subject.isEmpty || message.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please fill in all fields.')),
                  );
                  return;
                }

                // Pre-capture states to avoid using context across async gaps
                final messenger = ScaffoldMessenger.of(context);
                final navigator = Navigator.of(context);

                try {
                  await FirebaseFirestore.instance.collection('support_requests').add({
                    'user_name': widget.clientData.user.name,
                    'user_ref': widget.clientData.user.ref,
                    'user_email': widget.clientData.user.email,
                    'hotel_key': widget.clientData.user.hotelKey,
                    'subject': subject,
                    'message': message,
                    'timestamp': FieldValue.serverTimestamp(),
                    'status': 'pending',
                  });

                  _subjectController.clear();
                  _messageController.clear();

                  if (mounted) {
                    navigator.pop();
                    messenger.showSnackBar(
                      const SnackBar(
                        backgroundColor: Colors.green,
                        content: Text('Support request sent successfully.'),
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    messenger.showSnackBar(
                      SnackBar(content: Text('Failed to send: $e')),
                    );
                  }
                }
              },
              child: const Text(
                'SUBMIT',
                style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}