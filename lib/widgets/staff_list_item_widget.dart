import 'package:flutter/material.dart';
import '../models/user.dart';

class StaffListItemWidget extends StatelessWidget {
  final User person;

  const StaffListItemWidget({
    super.key,
    required this.person,
  });

  @override
  Widget build(BuildContext context) {
    final bool isSuper = person.role == 'superuser';
    
    // Split the comma-separated string into a clean list
    final List<String> hotelKeys = person.hotelKey != null && person.hotelKey!.isNotEmpty
        ? person.hotelKey!.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList()
        : [];

    // If they have multiple hotels, use an ExpansionTile
    if (hotelKeys.length > 1) {
      return Theme(
        // Removes the default border lines from ExpansionTile
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          leading: _buildAvatar(isSuper),
          title: _buildTitle(),
          subtitle: _buildSubtitle(),
          trailing: _buildBadge(hotelKeys),
          childrenPadding: const EdgeInsets.only(left: 72, right: 16, bottom: 8),
          children: hotelKeys.map((key) => _buildHotelDetailRow(key)).toList(),
        ),
      );
    }

    // Default simple ListTile for single or no assignments
    return ListTile(
      leading: _buildAvatar(isSuper),
      title: _buildTitle(),
      subtitle: _buildSubtitle(),
      trailing: _buildBadge(hotelKeys),
    );
  }

  Widget _buildAvatar(bool isSuper) {
    return CircleAvatar(
      backgroundColor: isSuper ? Colors.redAccent : const Color(0xFF003C82),
      child: Icon(
        isSuper ? Icons.shield : Icons.badge,
        color: Colors.white,
        size: 20,
      ),
    );
  }

  Widget _buildTitle() {
    return Text(
      person.name,
      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
    );
  }

  Widget _buildSubtitle() {
    return Text(
      '${person.role.toUpperCase()} • ${person.email}',
      style: const TextStyle(color: Colors.white54, fontSize: 12),
    );
  }

  Widget _buildBadge(List<String> hotelKeys) {
    if (hotelKeys.isEmpty) {
      return const Text('No Hotel', style: TextStyle(color: Colors.white24, fontSize: 10));
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: hotelKeys.length > 1 ? Colors.orangeAccent.withValues(alpha: 0.1) : Colors.white10,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        hotelKeys.length > 1 ? '${hotelKeys.length} HOTELS' : hotelKeys.first.toUpperCase().replaceAll('_', ' '),
        style: TextStyle(
          color: hotelKeys.length > 1 ? Colors.orangeAccent : const Color(0xFFFFD700), 
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildHotelDetailRow(String key) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        children: [
          const Icon(Icons.location_on, size: 12, color: Color(0xFFFFD700)),
          const SizedBox(width: 8),
          Text(
            key.toUpperCase().replaceAll('_', ' '),
            style: const TextStyle(color: Colors.white70, fontSize: 11),
          ),
        ],
      ),
    );
  }
}