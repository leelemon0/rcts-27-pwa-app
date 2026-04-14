import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user.dart';
import '../models/hotel.dart';
import '../widgets/modal_sheets.dart';
import '../widgets/room_card_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HotelManagerDashboard extends StatefulWidget {
  final User managerData;

  const HotelManagerDashboard({super.key, required this.managerData});

  @override
  State<HotelManagerDashboard> createState() => _HotelManagerDashboardState();
}

class _HotelManagerDashboardState extends State<HotelManagerDashboard>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  String? selectedHotelKey;

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final List<String> managerHotelKeys = [];

    if (widget.managerData.hotelKeys != null && widget.managerData.hotelKeys!.isNotEmpty) {
      managerHotelKeys.addAll(widget.managerData.hotelKeys!);
    } else if (widget.managerData.hotelKey != null && widget.managerData.hotelKey!.isNotEmpty) {
      final raw = widget.managerData.hotelKey!;
      if (raw.contains(',')) {
        managerHotelKeys.addAll(raw.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty));
      } else {
        managerHotelKeys.add(raw);
      }
    }

    final Stream<List<DocumentSnapshot<Map<String, dynamic>>>> hotelStream = managerHotelKeys.isEmpty
        ? Stream.value([])
        : FirebaseFirestore.instance
            .collection('hotels')
            .where(FieldPath.documentId, whereIn: managerHotelKeys)
            .snapshots()
            .map((snapshot) => snapshot.docs);

    return StreamBuilder<List<DocumentSnapshot<Map<String, dynamic>>>>(
      stream: hotelStream,
      builder: (context, hotelsSnapshot) {
        if (hotelsSnapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: Color(0xFF001436),
            body: Center(child: CircularProgressIndicator(color: Color(0xFFFFD700))),
          );
        }

        if (!hotelsSnapshot.hasData || hotelsSnapshot.data!.isEmpty) {
          return _buildErrorState(
            "No valid hotel documents found for: ${managerHotelKeys.join(', ')}",
            context
          );
        }

        final hotels = hotelsSnapshot.data!
            .map((doc) => Hotel.fromMap(doc.id, doc.data()!))
            .toList();

        if (selectedHotelKey == null || !hotels.any((h) => h.key == selectedHotelKey)) {
          selectedHotelKey = hotels[0].key;
        }

        final selectedHotel = hotels.firstWhere(
          (h) => h.key == selectedHotelKey,
          orElse: () => hotels.first,
        );

        return StreamBuilder<QuerySnapshot>(
          key: ValueKey(selectedHotel.key),
          stream: FirebaseFirestore.instance
              .collection('guests')
              .where('hotelKey', isEqualTo: selectedHotel.key)
              .snapshots(),
          builder: (context, guestsSnapshot) {
            if (guestsSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                backgroundColor: Color(0xFF001436),
                body: Center(child: CircularProgressIndicator(color: Color(0xFFFFD700))),
              );
            }

            final allGuests = guestsSnapshot.data?.docs
                    .map((doc) => User.fromMap(doc.id, doc.data() as Map<String, dynamic>))
                    .toList() ?? [];

            final Map<String, List<User>> roomGroups = {};
            for (final guest in allGuests) {
              final roomKey = guest.roomID ?? 'Unassigned';
              roomGroups.putIfAbsent(roomKey, () => []).add(guest);
            }

            final sortedRoomKeys = roomGroups.keys.toList()..sort();
            for (var room in roomGroups.values) {
              room.sort((a, b) => (a.isLeadGuest ? 0 : 1).compareTo(b.isLeadGuest ? 0 : 1));
            }

            return Scaffold(
              appBar: AppBar(
                automaticallyImplyLeading: false,
                backgroundColor: const Color(0xFF001436),
                title: _buildAppBarTitle(selectedHotel),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.edit_note, color: Color(0xFFFFD700)),
                    tooltip: 'Edit Hotel Logistics',
                    onPressed: () => showEditHotelSheet(
                      context, 
                      selectedHotel, 
                      () => setState(() {}),
                      canEditManager: false, // Managers cannot reassign themselves/others
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.search, color: Color(0xFFFFD700)),
                    onPressed: () {
                      showSearch(
                        context: context,
                        delegate: GuestSearchDelegate(limitToHotels: managerHotelKeys),
                      );
                    },
                  ),
                  if (hotels.length > 1) _buildHotelDropdown(hotels),
                  _buildLogoutButton(context),
                ],
              ),
              body: CustomScrollView(
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.all(16),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        Text(
                          'Current Transport: ${selectedHotel.transport}',
                          style: const TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                        Text(
                          'Pickup Location: ${selectedHotel.pickup}',
                          style: const TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Room Manifest (${roomGroups.length} Rooms - ${allGuests.length} Guests)',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFFFD700),
                          ),
                        ),
                        const SizedBox(height: 12),
                      ]),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final roomId = sortedRoomKeys[index];
                          final sharers = roomGroups[roomId]!;
                          return RoomCardWidget(
                            roomId: roomId,
                            roomType: sharers.first.room ?? 'N/A',
                            guests: sharers,
                          );
                        },
                        childCount: sortedRoomKeys.length,
                      ),
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 100)),
                ],
              ),
              floatingActionButton: _buildFAB(context, selectedHotel.key),
            );
          },
        );
      },
    );
  }

  // --- UI HELPER METHODS ---

  Widget _buildAppBarTitle(Hotel hotel) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(hotel.hotelName, style: const TextStyle(fontSize: 18)),
        Text(widget.managerData.name,
            style: const TextStyle(fontSize: 12, color: Color(0xFFFFD700))),
      ],
    );
  }

  Widget _buildHotelDropdown(List<Hotel> hotels) {
    return Theme(
      data: Theme.of(context).copyWith(canvasColor: const Color(0xFF001436)),
      child: DropdownButton<String>(
        value: selectedHotelKey,
        underline: const SizedBox(),
        icon: const Icon(Icons.swap_horiz, color: Color(0xFFFFD700)),
        items: hotels.map((h) => DropdownMenuItem(
          value: h.key,
          child: Text(h.hotelName, style: const TextStyle(color: Colors.white, fontSize: 14)),
        )).toList(),
        onChanged: (value) => setState(() => selectedHotelKey = value),
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.logout, color: Color(0xFFFFD700)),
      onPressed: () {
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
                'Are you sure you want to exit?',
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
      },
    );
  }

  Widget _buildFAB(BuildContext context, String hotelKey) {
    return FloatingActionButton.extended(
      backgroundColor: Colors.redAccent,
      icon: const Icon(Icons.campaign, color: Colors.white),
      label: const Text('Send Alert', style: TextStyle(color: Colors.white)),
      onPressed: () => showBroadcastSheet(
        context,
        'RCTS MANAGER - ${widget.managerData.name}',
        fixedHotelKey: hotelKey,
      ),
    );
  }

  Widget _buildErrorState(String message, BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF001436),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          _buildLogoutButton(context)],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white54, fontSize: 16),
          ),
        ),
      ),
    );
  }
}

class GuestSearchDelegate extends SearchDelegate {
  /// If null, searches all guests (Admin). 
  /// If provided, restricts results to these hotel keys (Manager).
  final List<String>? limitToHotels;

  GuestSearchDelegate({this.limitToHotels});

@override
  List<Widget>? buildActions(BuildContext context) {
    return [
      // Only show the button if there is text to clear
      if (query.isNotEmpty)
        Padding(
          padding: const EdgeInsets.only(right: 8.0),
          child: Center(
            child: TextButton(
              onPressed: () => query = '',
              child: const Text(
                'CLEAR',
                style: TextStyle(
                  color: Color(0xFFFFD700),
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        ),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () => close(context, null),
    );
  }

  @override
  Widget buildResults(BuildContext context) => _buildSearchResults();

  @override
  Widget buildSuggestions(BuildContext context) => _buildSearchResults();

  Widget _buildSearchResults() {
    if (query.length < 2) {
      return const Center(
        child: Text("Enter at least 2 characters to search...",
            style: TextStyle(color: Colors.white54)),
      );
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('guests').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox();

        final results = snapshot.data!.docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          
          // 1. Security Scope Check
          if (limitToHotels != null && !limitToHotels!.contains(data['hotelKey'])) {
            return false;
          }

          // 2. Search logic
          final name = (data['name'] ?? '').toString().toLowerCase();
          final email = (data['email'] ?? '').toString().toLowerCase();
          final searchLower = query.toLowerCase();
          return name.contains(searchLower) || email.contains(searchLower);
        }).toList();

        if (results.isEmpty) {
          return const Center(
            child: Text("No guests found matching that search.",
                style: TextStyle(color: Colors.white54)),
          );
        }

        return ListView.builder(
          itemCount: results.length,
          itemBuilder: (context, index) {
            final guest = User.fromMap(
                results[index].id, results[index].data() as Map<String, dynamic>);

            return ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              title: Text(guest.name,
                  style: const TextStyle(
                      color: Color(0xFFFFD700), fontWeight: FontWeight.bold)),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(guest.email, style: const TextStyle(color: Colors.white70)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.hotel, size: 14, color: Colors.white38),
                      const SizedBox(width: 4),
                      Text("Hotel: ${guest.hotelKey ?? 'Unassigned'}",
                          style: const TextStyle(color: Colors.white38, fontSize: 12)),
                      const SizedBox(width: 12),
                      const Icon(Icons.door_front_door, size: 14, color: Colors.white38),
                      const SizedBox(width: 4),
                      Text("Room: ${guest.roomID ?? 'N/A'}",
                          style: const TextStyle(color: Colors.white38, fontSize: 12)),
                    ],
                  ),
                ],
              ),
              isThreeLine: true,
              onTap: () => close(context, null),
            );
          },
        );
      },
    );
  }

  @override
  ThemeData appBarTheme(BuildContext context) {
    return Theme.of(context).copyWith(
      appBarTheme: const AppBarTheme(backgroundColor: Color(0xFF001436)),
      inputDecorationTheme: const InputDecorationTheme(
        hintStyle: TextStyle(color: Colors.white38),
        border: InputBorder.none,
      ),
      textTheme: const TextTheme(
        titleLarge: TextStyle(color: Colors.white),
      ),
    );
  }
}