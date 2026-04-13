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
  
  final thuCtrl = TextEditingController(text: hotel.transportThursday ?? "");
  final friCtrl = TextEditingController(text: hotel.transportFriday ?? "");
  final satCtrl = TextEditingController(text: hotel.transportSaturday ?? "");
  final sunCtrl = TextEditingController(text: hotel.transportSunday ?? "");
  
  final guideCtrl = TextEditingController(text: hotel.experienceGuide ?? "");
  final scheduleCtrl = TextEditingController(text: hotel.entertainmentSchedule ?? "");

  // Track which section is expanded (0 = none, 1 = Hotel, 2 = Transport, 3 = Experience)
  int expandedIndex = 0;

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: const Color(0xFF001436),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) => StatefulBuilder(
      builder: (context, setModalState) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 24, right: 24, top: 24,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                (hotel.hotelType == 'glamping' || hotel.hotelType == 'cruise')
                    ? 'Edit ${(hotel.hotelType ?? '')[0].toUpperCase()}${(hotel.hotelType ?? '').substring(1)} Details'
                    : 'Edit Hotel & Logistics for ${hotel.hotelName}',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFFFFD700)),
              ),
              const SizedBox(height: 16),
              
              if (canEditManager) ...[
                _buildManagementTeamSection(hotel.key),
                const SizedBox(height: 16),
              ],

              // --- SECTION 1: HOTEL DETAILS ---
              Theme(
                data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                child: ExpansionTile(
                  key: GlobalKey(),
                  initiallyExpanded: expandedIndex == 1,
                  onExpansionChanged: (isExpanded) {
                    if (isExpanded) {
                      setModalState(() => expandedIndex = 1);
                    } else if (expandedIndex == 1) {
                      setModalState(() => expandedIndex = 0);
                    }
                  },
                  tilePadding: EdgeInsets.zero,
                  iconColor: const Color(0xFFFFD700),
                  collapsedIconColor: Colors.white54,
                  title: const Text(
                    'Hotel Details',
                    style: TextStyle(color: Color(0xFFFFD700), fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                  children: [
                    const SizedBox(height: 12),
                    _buildField(boardCtrl, 'Board Basis'),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(child: _buildField(checkInCtrl, 'Check-in Time')),
                        const SizedBox(width: 12),
                        Expanded(child: _buildField(checkOutCtrl, 'Check-out Time')),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),

              // --- SECTION 2: TRANSPORT DETAILS ---
              Theme(
                data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                child: ExpansionTile(
                  key: GlobalKey(),
                  initiallyExpanded: expandedIndex == 2,
                  onExpansionChanged: (isExpanded) {
                    if (isExpanded) {
                      setModalState(() => expandedIndex = 2);
                    } else if (expandedIndex == 2) {
                      setModalState(() => expandedIndex = 0);
                    }
                  },
                  tilePadding: EdgeInsets.zero,
                  iconColor: const Color(0xFFFFD700),
                  collapsedIconColor: Colors.white54,
                  title: const Text(
                    'Transport Details',
                    style: TextStyle(color: Color(0xFFFFD700), fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                  children: [
                    const SizedBox(height: 12),
                    _buildField(transportCtrl, 'Transport Type'),
                    const SizedBox(height: 12),
                    _buildField(pickupCtrl, 'Pickup Location'),
                    const SizedBox(height: 20),
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text('Daily Shuttle Times', 
                        style: TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.w600)),
                    ),
                    const SizedBox(height: 12),
                    _buildField(thuCtrl, 'Thursday Schedule'),
                    const SizedBox(height: 12), // Spacing standardised to match other fields
                    _buildField(friCtrl, 'Friday Schedule'),
                    const SizedBox(height: 12),
                    _buildField(satCtrl, 'Saturday Schedule'),
                    const SizedBox(height: 12),
                    _buildField(sunCtrl, 'Sunday Schedule'),
                    const SizedBox(height: 16),
                  ],
                ),
              ),

              // --- SECTION 3: EXPERIENCE DETAILS (Glamping/Cruise Only) ---
              if (hotel.hotelType == 'glamping' || hotel.hotelType == 'cruise')
                Theme(
                  data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                  child: ExpansionTile(
                    key: GlobalKey(),
                    initiallyExpanded: expandedIndex == 3,
                    onExpansionChanged: (isExpanded) {
                      if (isExpanded) {
                        setModalState(() => expandedIndex = 3);
                      } else if (expandedIndex == 3) {
                        setModalState(() => expandedIndex = 0);
                      }
                    },
                    tilePadding: EdgeInsets.zero,
                    iconColor: const Color(0xFFFFD700),
                    collapsedIconColor: Colors.white54,
                    title: const Text(
                      'Experience Details',
                      style: TextStyle(color: Color(0xFFFFD700), fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                    children: [
                      const SizedBox(height: 12),
                      _buildField(guideCtrl, 'Experience Guide', maxLines: 4),
                      const SizedBox(height: 12),
                      _buildField(scheduleCtrl, 'Entertainment Schedule', maxLines: 4),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),

              const SizedBox(height: 24),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFFD700), 
                  foregroundColor: const Color(0xFF001436),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () async {
                  final updatedHotel = hotel.copyWith(
                    transport: transportCtrl.text.trim(),
                    pickup: pickupCtrl.text.trim(),
                    board: boardCtrl.text.trim(),
                    checkIn: checkInCtrl.text.trim(),
                    checkOut: checkOutCtrl.text.trim(),
                    experienceGuide: guideCtrl.text.trim(),
                    entertainmentSchedule: scheduleCtrl.text.trim(),
                    transportThursday: thuCtrl.text.trim(),
                    transportFriday: friCtrl.text.trim(),
                    transportSaturday: satCtrl.text.trim(),
                    transportSunday: sunCtrl.text.trim(),
                  );

                  await FirebaseFirestore.instance
                      .collection('hotels')
                      .doc(hotel.key)
                      .update(updatedHotel.toMap());

                  onSave();
                  if (context.mounted) Navigator.pop(context);
                },
                child: const Text('SAVE ALL CHANGES', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1)),
              ),
              const SizedBox(height: 40),
            ],
          ),
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

      final currentTeam = allManagers.where((m) {
        if (m.hotelKey == null) return false;
        return m.hotelKey!.split(',').map((e) => e.trim()).contains(hotelKey);
      }).toList();

      final available = allManagers.where((m) {
        if (m.hotelKey == null) return true;
        return !m.hotelKey!.split(',').map((e) => e.trim()).contains(hotelKey);
      }).toList();

      return Column(
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
                  List<String> keys = (m.hotelKey ?? "")
                      .split(',')
                      .map((e) => e.trim())
                      .where((e) => e.isNotEmpty && e != hotelKey)
                      .toList();
                  
                  await FirebaseFirestore.instance
                      .collection('staff')
                      .doc(m.email)
                      .update({'hotelKey': keys.isEmpty ? null : keys.join(',')});
                },
              )),
              ActionChip(
                backgroundColor: const Color(0xFFFFD700),
                avatar: const Icon(Icons.add, size: 16, color: Color(0xFF001436)),
                label: const Text('Add Manager', style: TextStyle(color: Color(0xFF001436), fontSize: 11, fontWeight: FontWeight.bold)),
                onPressed: () => _showAddManagerDialog(context, hotelKey, available),
              ),
            ],
          ),
          if (currentTeam.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 8.0),
              child: Text('No managers assigned yet.', style: TextStyle(color: Colors.orangeAccent, fontSize: 11)),
            ),
        ],
      );
    },
  );
}

// Global helper for styling TextFields
Widget _buildField(TextEditingController controller, String label, {int maxLines = 1}) {
  return TextField(
    controller: controller,
    maxLines: maxLines,
    style: const TextStyle(color: Colors.white, fontSize: 14),
    decoration: InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white38),
      filled: true,
      fillColor: Colors.white.withValues(alpha: 0.05),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFFFD700))),
    ),
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
                      subtitle: Text(m.hotelKey != null ? 'Assigned elsewhere' : 'Available',
                          style: TextStyle(
                              color: m.hotelKey != null ? Colors.orangeAccent : Colors.greenAccent, fontSize: 11)),
                      onTap: () {
                        Navigator.pop(context);
                        if (m.hotelKey == null || m.hotelKey!.isEmpty) {
                          FirebaseFirestore.instance
                              .collection('staff')
                              .doc(m.email)
                              .update({'hotelKey': hotelKey});
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
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFFD700)),
          onPressed: () async {
            List<String> keyList = (manager.hotelKey ?? "")
                .split(',')
                .map((e) => e.trim())
                .where((e) => e.isNotEmpty)
                .toList();

            if (!keyList.contains(newHotelKey)) {
              keyList.add(newHotelKey);
              await FirebaseFirestore.instance
                  .collection('staff')
                  .doc(manager.email)
                  .update({'hotelKey': keyList.join(',')});
            }
            if (context.mounted) Navigator.pop(context);
          },
          child: const Text('MANAGE BOTH', style: TextStyle(color: Color(0xFF001436))),
        ),
      ],
    ),
  );
}

/// --- BROADCAST ALERTS ---
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
          left: 24,
          right: 24,
          top: 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Broadcast Alert',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFFFFD700))),
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
              decoration: const InputDecoration(
                  hintText: 'Enter message...',
                  filled: true,
                  fillColor: Colors.white10,
                  hintStyle: TextStyle(color: Colors.white38)),
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
              value: doc.id, child: Text('Guests at ${doc['hotelName']}'))),
        ],
        onChanged: onChanged,
      );
    },
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
                  const SnackBar(content: Text('Broadcast sent'), backgroundColor: Colors.green));
            }
          },
          child: const Text('Yes'),
        ),
      ],
    ),
  );
}