import 'package:flutter/material.dart';
import '../models/user.dart';
import 'guest_row_widget.dart';

/// Reusable room card widget for displaying room and guest information.
class RoomCardWidget extends StatelessWidget {
  final String roomId;
  final String roomType;
  final List<User> guests;

  const RoomCardWidget({
    super.key,
    required this.roomId,
    required this.roomType,
    required this.guests,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFF003C82),
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.bed, color: Color(0xFFFFD700), size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '$roomId - $roomType',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const Divider(color: Colors.white24, height: 20),
            ...guests.map((guest) => GuestRowWidget(guest: guest)),
          ],
        ),
      ),
    );
  }
}
