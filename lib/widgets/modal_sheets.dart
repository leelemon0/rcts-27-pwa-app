import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/hotel.dart';
import '../models/user.dart';
import '../models/broadcast.dart';

/// --- EDIT HOTEL SHEET ---
void showEditHotelSheet(BuildContext context, Hotel hotel, VoidCallback onSave, {bool canEditManager = true}) {
  final transportCtrl = TextEditingController(text: hotel.transport);
  final pickupCtrl = TextEditingController(text: hotel.pickup);
  final boardCtrl = TextEditingController(text: hotel.board);
  final checkInCtrl = TextEditingController(text: hotel.checkIn);
  final checkOutCtrl = TextEditingController(text: hotel.checkOut);

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: const Color(0xFF001436),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) => StatefulBuilder(
      builder: (context, modalSetState) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 24, right: 24, top: 24,
        ),
        // LayoutBuilder helps stabilize Web layout calculations
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Edit Hotel & Logistics',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFFFFD700)),
                  ),
                  const SizedBox(height: 16),
                  
                  if (canEditManager) ...[
                    _buildManagementTeamSection(hotel.key),
                    const SizedBox(height: 16),
                  ],

                  TextField(controller: transportCtrl, decoration: const InputDecoration(labelText: 'Transport Type', filled: true)),
                  const SizedBox(height: 12),
                  TextField(controller: pickupCtrl, decoration: const InputDecoration(labelText: 'Pickup Location', filled: true)),
                  const SizedBox(height: 12),
                  TextField(controller: boardCtrl, decoration: const InputDecoration(labelText: 'Board Basis', filled: true)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: TextField(controller: checkInCtrl, decoration: const InputDecoration(labelText: 'Check-in', filled: true))),
                      const SizedBox(width: 12),
                      Expanded(child: TextField(controller: checkOutCtrl, decoration: const InputDecoration(labelText: 'Check-out', filled: true))),
                    ],
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFFD700), 
                      foregroundColor: const Color(0xFF001436),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    onPressed: () async {
                      final updatedHotel = hotel.copyWith(
                        transport: transportCtrl.text,
                        pickup: pickupCtrl.text,
                        board: boardCtrl.text,
                        checkIn: checkInCtrl.text,
                        checkOut: checkOutCtrl.text,
                      );

                      await FirebaseFirestore.instance
                          .collection('hotels')
                          .doc(hotel.key)
                          .update(updatedHotel.toMap());

                      onSave();
                      if (context.mounted) Navigator.pop(context);
                    },
                    child: const Text('Save All Changes', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(height: 40), // Extra space for mobile keyboards
                ],
              ),
            );
          }
        ),
      ),
    ),
  );
}

/// --- TEAM MANAGEMENT WIDGET ---

Widget _buildManagementTeamSection(String hotelKey) {
  return StreamBuilder<QuerySnapshot>(
    stream: FirebaseFirestore.instance
        .collection('staff')
        .where('role', isEqualTo: 'manager')
        .snapshots(),
    builder: (context, snapshot) {
      if (!snapshot.hasData) return const LinearProgressIndicator();
      
final allManagers = snapshot.data!.docs
    .map((doc) => User.fromMap(doc.id, doc.data() as Map<String, dynamic>))
    .toList();

      // FIXED: Check if the hotelKey list CONTAINS the key, rather than being EQUAL to it
      final currentTeam = allManagers.where((m) {
        if (m.hotelKey == null) return false;
        return m.hotelKey!.split(',').map((e) => e.trim()).contains(hotelKey);
      }).toList();

      // FIXED: Available should be everyone NOT in the current team
      final available = allManagers.where((m) {
        if (m.hotelKey == null) return true; // Available if no assignment
        final assignedKeys = m.hotelKey!.split(',').map((e) => e.trim());
        return !assignedKeys.contains(hotelKey);
      }).toList();

      return Column(
        mainAxisSize: MainAxisSize.min, // Crucial for layout stability
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Management Team', style: TextStyle(color: Colors.white70, fontSize: 12)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ...currentTeam.map((m) => InputChip(
                label: Text(m.name, style: const TextStyle(color: Colors.white, fontSize: 12)),
                backgroundColor: const Color(0xFF003C82),
                deleteIcon: const Icon(Icons.close, size: 14, color: Colors.redAccent),
                onDeleted: () async {
                // 1. Get current keys, defaulting to empty string if null
                String currentKeys = m.hotelKey ?? "";
                
                // 2. Convert to list, filtering out any accidental empty strings
                List<String> keys = currentKeys
                    .split(',')
                    .map((e) => e.trim())
                    .where((e) => e.isNotEmpty)
                    .toList();
                
                // 3. Remove this specific hotel
                keys.remove(hotelKey);
                
                // 4. Join back into a clean string
                String newString = keys.join(',');

                await FirebaseFirestore.instance
                    .collection('staff')
                    .doc(m.email)
                    .update({'hotelKey': newString});
              },
              )),
              ActionChip(
                backgroundColor: const Color(0xFFFFD700),
                avatar: const Icon(Icons.add, size: 16, color: Color(0xFF001436)),
                label: const Text('Add Manager', style: TextStyle(color: Color(0xFF001436), fontSize: 12, fontWeight: FontWeight.bold)),
                onPressed: () => _showAddManagerDialog(context, hotelKey, available),
              ),
            ],
          ),
          if (currentTeam.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 8.0),
              child: Text('No managers assigned yet.', style: TextStyle(color: Colors.redAccent, fontSize: 11)),
            ),
        ],
      );
    },
  );
}

void _showAddManagerDialog(BuildContext context, String hotelKey, List<User> available) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: const Color(0xFF001436),
      title: const Text('Select Manager', style: TextStyle(color: Color(0xFFFFD700))),
      content: SizedBox(
        width: double.maxFinite,
        // Constrain the height of the dialog list
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.4),
          child: available.isEmpty 
            ? const Text('No other managers available.', style: TextStyle(color: Colors.white70))
            : ListView.builder(
                shrinkWrap: true,
                itemCount: available.length,
                itemBuilder: (context, index) {
                  final m = available[index];
                  return ListTile(
                    leading: const Icon(Icons.person_add, color: Colors.white70),
                    title: Text(m.name, style: const TextStyle(color: Colors.white)),
                    subtitle: Text(
                      m.hotelKey != null ? 'Assigned elsewhere' : 'Available', 
                      style: TextStyle(color: m.hotelKey != null ? Colors.orangeAccent : Colors.greenAccent, fontSize: 11)
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      if (m.hotelKey == null) {
                        FirebaseFirestore.instance.collection('staff').doc(m.email).update({'hotelKey': hotelKey});
                      } else {
                        _showConflictResolutionDialog(context, m, hotelKey);
                      }
                    },
                  );
                },
              ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
      ],
    ),
  );
}

/// --- CONFLICT RESOLUTION (SWAP OR ADD) ---

void _showConflictResolutionDialog(BuildContext context, User manager, String newHotelKey) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: const Color(0xFF001436),
      title: const Text('Manager Assignment', style: TextStyle(color: Color(0xFFFFD700))),
      content: Text(
        '${manager.name} is currently assigned to another hotel.\n\nWould you like to move them here, or manage both hotels?',
        style: const TextStyle(color: Colors.white),
      ),
      actions: [
        // OPTION 1: MOVE (Replace existing assignment)
        TextButton(
          onPressed: () async {
            await FirebaseFirestore.instance
                .collection('staff')
                .doc(manager.email) 
                .update({'hotelKey': newHotelKey});
            
            if (context.mounted) Navigator.pop(context);
          },
          child: const Text('MOVE HERE', style: TextStyle(color: Colors.orangeAccent)),
        ),
        
        // OPTION 2: BOTH (Append to existing string)
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFFD700)),
          onPressed: () async {
            // Get current keys, split them, add the new one, and join back
            String currentKeys = manager.hotelKey ?? "";
            List<String> keyList = currentKeys
                .split(',')
                .map((e) => e.trim())
                .where((e) => e.isNotEmpty)
                .toList();

            if (!keyList.contains(newHotelKey)) {
              keyList.add(newHotelKey);
              String updatedKeys = keyList.join(',');

              await FirebaseFirestore.instance
                  .collection('staff')
                  .doc(manager.email)
                  .update({'hotelKey': updatedKeys});
            }

            if (context.mounted) Navigator.pop(context);
          },
          child: const Text('MANAGE BOTH', style: TextStyle(color: Color(0xFF001436))),
        ),
      ],
    ),
  );
}

/// --- BROADCAST HELPERS (UNCHANGED) ---

Widget _buildHotelTargetDropdown(String selected, Function(String?) onChanged) {
  return StreamBuilder<QuerySnapshot>(
    stream: FirebaseFirestore.instance.collection('hotels').snapshots(),
    builder: (context, snapshot) {
      if (!snapshot.hasData) return const SizedBox();
      return DropdownButton<String>(
        value: selected,
        isExpanded: true,
        dropdownColor: const Color(0xFF003C82),
        style: const TextStyle(color: Colors.white),
        items: [
          const DropdownMenuItem(value: 'all', child: Text('All Guests (Global)')),
          ...snapshot.data!.docs.map((doc) => DropdownMenuItem(
            value: doc.id, 
            child: Text('Guests at ${doc['hotelName']}')
          )),
        ],
        onChanged: onChanged,
      );
    },
  );
}

void showBroadcastSheet(BuildContext context, String senderName, {String? fixedHotelKey}) {
  final parentContext = context;
  final messageCtrl = TextEditingController();
  String selectedTarget = fixedHotelKey ?? 'all';

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: const Color(0xFF001436),
    builder: (context) => StatefulBuilder(
      builder: (context, modalSetState) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 24, right: 24, top: 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Broadcast Alert', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFFFFD700))),
            const SizedBox(height: 16),
            if (fixedHotelKey == null) ...[
              const Text('Select Recipient Group:', style: TextStyle(color: Colors.white70, fontSize: 12)),
              _buildHotelTargetDropdown(selectedTarget, (value) {
                modalSetState(() => selectedTarget = value!);
              }),
              const SizedBox(height: 16),
            ],
            TextField(
              controller: messageCtrl,
              maxLines: 3,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(hintText: 'Enter message...', filled: true, fillColor: Colors.white10, hintStyle: TextStyle(color: Colors.white38)),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
              icon: const Icon(Icons.send),
              label: const Text('Send Priority Alert'),
              onPressed: () => _confirmBroadcast(parentContext, senderName, messageCtrl.text, selectedTarget),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    ),
  );
}

void _confirmBroadcast(BuildContext context, String sender, String message, String target) {
  if (message.trim().isEmpty) return;
  
  showDialog(
    context: context,
    builder: (dContext) => AlertDialog(
      backgroundColor: const Color(0xFF001436),
      title: const Text('Ready to send?', style: TextStyle(color: Colors.white)),
      content: Text('Send this alert to $target?', style: const TextStyle(color: Colors.white70)),
      actions: [
        TextButton(onPressed: () => Navigator.pop(dContext), child: const Text('No')),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
          onPressed: () async {
            final broadcast = Broadcast(
              sender: sender,
              message: message,
              target: target,
              timestamp: DateTime.now(),
            );

            await FirebaseFirestore.instance.collection('broadcasts').add(broadcast.toMap());
            
            if (context.mounted) {
              Navigator.pop(dContext);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Broadcast sent'), backgroundColor: Colors.green)
              );
            }
          },
          child: const Text('Yes'),
        ),
      ],
    ),
  );
}