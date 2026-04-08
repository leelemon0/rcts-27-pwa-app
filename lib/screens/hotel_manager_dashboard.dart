import 'package:flutter/material.dart';

import '../models/user.dart';
import '../services/mock_database.dart';
import '../widgets/modal_sheets.dart';

class HotelManagerDashboard extends StatefulWidget {
  final User managerData;
  const HotelManagerDashboard({super.key, required this.managerData});

  @override
  State<HotelManagerDashboard> createState() => _HotelManagerDashboardState();
}

class _HotelManagerDashboardState extends State<HotelManagerDashboard> {
  @override
  Widget build(BuildContext context) {
    final hotelKey = widget.managerData.hotelKey!;
    final hotel = MockDatabase.hotels[hotelKey];

    final allGuests = MockDatabase.users.values
        .where((user) => user.role == 'user' && user.hotelKey == hotelKey)
        .toList();

    final Map<String, List<User>> roomGroups = {};
    for (final guest in allGuests) {
      final roomKey = guest.roomID ?? 'Unassigned';
      roomGroups.putIfAbsent(roomKey, () => []).add(guest);
    }

    final roomKeys = roomGroups.keys.toList();

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(hotel?.hotelName ?? 'Hotel', style: const TextStyle(fontSize: 18)),
            Text(widget.managerData.name, style: const TextStyle(fontSize: 12, color: Color(0xFFFFD700))),
          ],
        ),
        backgroundColor: const Color(0xFF001436),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_note, color: Color(0xFFFFD700)),
            tooltip: 'Edit Hotel Details',
            onPressed: () {
              if (hotel != null) {
                showEditHotelSheet(context, hotel, () {
                  setState(() {});
                }, canEditManager: false);
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Color(0xFFFFD700)),
            onPressed: () {
              Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Current Transport: ${hotel?.transport ?? 'N/A'}',
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
            const SizedBox(height: 16),
            Text(
              'Room Manifest (${roomGroups.length} Rooms)',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFFFFD700)),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.builder(
                itemCount: roomKeys.length,
                itemBuilder: (context, index) {
                  final roomId = roomKeys[index];
                  final sharers = roomGroups[roomId]!;
                  final roomType = sharers.first.room ?? 'N/A';

                  return Card(
                    color: const Color(0xFF003C82),
                    margin: const EdgeInsets.only(bottom: 12),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.bed, color: Color(0xFFFFD700), size: 20),
                              const SizedBox(width: 8),
                              Text('$roomId - $roomType', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            ],
                          ),
                          const Divider(color: Colors.white24, height: 20),
                          ...sharers.map(
                            (guest) => Padding(
                              padding: const EdgeInsets.only(bottom: 6.0),
                              child: Row(
                                children: [
                                  Icon(
                                    guest.isLeadGuest ? Icons.star : Icons.person,
                                    size: 16,
                                    color: guest.isLeadGuest ? const Color(0xFFFFD700) : Colors.white70,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(guest.name, style: const TextStyle(color: Colors.white)),
                                  const Spacer(),
                                  Text(guest.ref ?? '', style: const TextStyle(fontSize: 10, color: Colors.white38)),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.redAccent,
        icon: const Icon(Icons.campaign, color: Colors.white),
        label: const Text('Send Alert', style: TextStyle(color: Colors.white)),
        onPressed: () {
          showBroadcastSheet(
            context,
            'RCTS EVENT MANAGER - ${widget.managerData.name}',
            fixedHotelKey: hotelKey,
          );
        },
      ),
    );
  }
}
