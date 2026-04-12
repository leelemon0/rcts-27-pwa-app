import 'package:flutter/material.dart';
import '../models/hotel.dart';
import '../models/user.dart';

/// Reusable hotel card widget for the admin dashboard.
/// Isolates hotel card UI logic into a separate, testable component.
class HotelCardWidget extends StatelessWidget {
  final Hotel hotel;
  final List<User> assignedManagers;
  final Map<String, int> managerAssignmentCounts;
  final int uniqueRooms;
  final int totalGuests;
  final VoidCallback onManifestView;
  final VoidCallback onEditHotel;

  const HotelCardWidget({
    super.key,
    required this.hotel,
    required this.assignedManagers,
    required this.managerAssignmentCounts,
    required this.uniqueRooms,
    required this.totalGuests,
    required this.onManifestView,
    required this.onEditHotel,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: const Color(0xFF003C82),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    '${hotel.hotelName} ($uniqueRooms rooms - $totalGuests guests)',
                    style: const TextStyle(
                      color: Color(0xFFFFD700),
                      fontWeight: FontWeight.bold,
                      fontSize: 17,
                    ),
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.receipt_long, color: Color(0xFFFFD700), size: 22),
                      tooltip: 'View Manifest',
                      onPressed: onManifestView,
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.white70, size: 20),
                      onPressed: onEditHotel,
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              'Assigned Managers:',
              style: TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            assignedManagers.isEmpty
                ? const Text(
                    'None Assigned',
                    style: TextStyle(color: Colors.redAccent, fontSize: 13, fontWeight: FontWeight.bold),
                  )
                : Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: assignedManagers.map((manager) {
                      final assignmentCount = managerAssignmentCounts[manager.name] ?? 0;
                      final isMultiAssigned = assignmentCount > 1;

                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: isMultiAssigned
                              ? Colors.orange.withValues(alpha: 0.15)
                              : Colors.white.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: isMultiAssigned ? Colors.orange : Colors.white24,
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              manager.name,
                              style: TextStyle(
                                color: isMultiAssigned ? Colors.orange : Colors.white,
                                fontSize: 13,
                                fontWeight: isMultiAssigned ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                            if (isMultiAssigned) ...[
                              const SizedBox(width: 6),
                              const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 14),
                            ],
                          ],
                        ),
                      );
                    }).toList(),
                  ),
            const SizedBox(height: 12),
            const Divider(color: Colors.white12, height: 1),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildInfoBadge('Ref: ${hotel.hotelRef}'),
                const SizedBox(width: 8),
                _buildInfoBadge('Transport: ${hotel.transport}'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoBadge(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.black26,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: const TextStyle(color: Colors.white54, fontSize: 11),
      ),
    );
  }
}
