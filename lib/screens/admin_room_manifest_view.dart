import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user.dart';
import '../models/hotel.dart';

class AdminRoomManifestView extends StatelessWidget {
  final Hotel hotel;

  const AdminRoomManifestView({super.key, required this.hotel});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF001436),
      appBar: AppBar(
        title: Text('${hotel.hotelName} Manifest'),
        backgroundColor: const Color(0xFF001436),
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        // Listen to all GUESTS assigned to this specific hotel
        stream: FirebaseFirestore.instance
            .collection('guests')
            .where('hotelKey', isEqualTo: hotel.key)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('Error loading manifest', style: TextStyle(color: Colors.white)));
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFFFFD700)));
          }

          // 1. Convert documents to User objects
          final allGuests = snapshot.data!.docs.map((doc) {
            return User.fromMap(doc.id, doc.data() as Map<String, dynamic>);
          }).toList();

          if (allGuests.isEmpty) {
            return const Center(
              child: Text('No guests assigned to this hotel yet.', 
              style: TextStyle(color: Colors.white54))
            );
          }

          // 2. Grouping logic: Group guests by their roomID
          final Map<String, List<User>> roomGroups = {};
          for (final guest in allGuests) {
            final roomKey = guest.roomID ?? 'Unassigned';
            roomGroups.putIfAbsent(roomKey, () => []).add(guest);
          }

          // Sort room keys numerically/alphabetically
          final roomKeys = roomGroups.keys.toList()..sort();

          // 3. UI Construction
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                color: Colors.black26,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hotel Ref: ${hotel.hotelRef}',
                      style: const TextStyle(color: Color(0xFFFFD700), fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Total Capacity: ${roomGroups.length} Rooms | ${allGuests.length} Guests',
                      style: const TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: roomKeys.length,
                  itemBuilder: (context, index) {
                    final roomId = roomKeys[index];
                    final sharers = roomGroups[roomId]!;

                    // Sort: Lead Guest (isLeadGuest == true) to the top
                    sharers.sort((a, b) {
                      if (a.isLeadGuest && !b.isLeadGuest) return -1;
                      if (!a.isLeadGuest && b.isLeadGuest) return 1;
                      return 0;
                    });

                    final roomType = sharers.isNotEmpty ? (sharers.first.room ?? 'N/A') : 'N/A';

                    return Card(
                      color: const Color(0xFF003C82),
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: const BorderSide(color: Colors.white10),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.meeting_room, color: Color(0xFFFFD700), size: 18),
                                const SizedBox(width: 8),
                                Text(
                                  'Room $roomId — $roomType',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                ),
                              ],
                            ),
                            const Divider(color: Colors.white24, height: 20),
                            ...sharers.map((guest) => _buildGuestRow(guest)),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildGuestRow(User guest) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Icon(
            guest.isLeadGuest ? Icons.star : Icons.person,
            size: 14,
            color: guest.isLeadGuest ? const Color(0xFFFFD700) : Colors.white60,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              guest.name,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              // Add overflow handling to the name
              overflow: TextOverflow.ellipsis, 
              maxLines: 1,
            ),
          ),
          const SizedBox(width: 8), // Added spacing
          // Wrap trailing elements in a Row with mainAxisSize: MainAxisSize.min
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (guest.hasTicket) ...[
                const Icon(Icons.confirmation_number, size: 14, color: Color(0xFFFFD700)),
                const SizedBox(width: 6),
              ],
              if (guest.hasTransport) ...[
                const Icon(Icons.directions_bus, size: 14, color: Color(0xFFFFD700)),
                const SizedBox(width: 6),
              ],
              Text(
                guest.ref ?? '',
                style: const TextStyle(
                  fontSize: 10, 
                  color: Colors.white38, 
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}