import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user.dart';
import '../models/hotel.dart';
import '../widgets/modal_sheets.dart';
import '../widgets/room_card_widget.dart';

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

    // 1. Resolve which hotels this manager can see.
    // This logic handles both pre-parsed lists and raw comma-separated strings.
    final List<String> managerHotelKeys = [];

    if (widget.managerData.hotelKeys != null && widget.managerData.hotelKeys!.isNotEmpty) {
      managerHotelKeys.addAll(widget.managerData.hotelKeys!);
    } else if (widget.managerData.hotelKey != null && widget.managerData.hotelKey!.isNotEmpty) {
      final raw = widget.managerData.hotelKey!;
      if (raw.contains(',')) {
        // Splits "hotel1, hotel2" into ["hotel1", "hotel2"]
        managerHotelKeys.addAll(raw.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty));
      } else {
        managerHotelKeys.add(raw);
      }
    }

    debugPrint("Fetching hotels for: $managerHotelKeys");

    // 2. Fetch Hotel Documents
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

        // Error state if no hotels match the keys provided
        if (!hotelsSnapshot.hasData || hotelsSnapshot.data!.isEmpty) {
          return _buildErrorState(
            "No valid hotel documents found for: ${managerHotelKeys.join(', ')}",
            context
          );
        }

        final hotels = hotelsSnapshot.data!
            .map((doc) => Hotel.fromMap(doc.id, doc.data()!))
            .toList();

        // Initialise or validate selectedHotelKey
        if (selectedHotelKey == null || !hotels.any((h) => h.key == selectedHotelKey)) {
          selectedHotelKey = hotels[0].key;
        }

        final selectedHotel = hotels.firstWhere(
          (h) => h.key == selectedHotelKey,
          orElse: () => hotels.first,
        );

        // 3. Fetch Guests for the SELECTED hotel
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

            // Grouping Logic by Room
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
      onPressed: () => Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false),
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
        actions: [_buildLogoutButton(context)],
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