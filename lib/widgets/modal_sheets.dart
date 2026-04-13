import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/hotel.dart';
import '../models/user.dart';
import '../models/broadcast.dart';

/// --- EDIT HOTEL SHEET ---
void showEditHotelSheet(BuildContext context, Hotel hotel, VoidCallback onSave, {bool canEditManager = true}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: const Color(0xFF001436),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) => _EditHotelForm(
      hotel: hotel,
      onSave: onSave,
      canEditManager: canEditManager,
    ),
  );
}

class _EditHotelForm extends StatefulWidget {
  final Hotel hotel;
  final VoidCallback onSave;
  final bool canEditManager;

  const _EditHotelForm({
    required this.hotel,
    required this.onSave,
    required this.canEditManager,
  });

  @override
  State<_EditHotelForm> createState() => _EditHotelFormState();
}

class _EditHotelFormState extends State<_EditHotelForm> {
  // Controllers persist here to prevent keyboard focus loss
  late TextEditingController transportCtrl;
  late TextEditingController pickupCtrl;
  late TextEditingController boardCtrl;
  late TextEditingController checkInCtrl;
  late TextEditingController checkOutCtrl;
  late TextEditingController thuCtrl;
  late TextEditingController friCtrl;
  late TextEditingController satCtrl;
  late TextEditingController sunCtrl;
  late TextEditingController guideCtrl;
  late TextEditingController scheduleCtrl;

  int expandedIndex = 0;

  @override
  void initState() {
    super.initState();
    transportCtrl = TextEditingController(text: widget.hotel.transport);
    pickupCtrl = TextEditingController(text: widget.hotel.pickup);
    boardCtrl = TextEditingController(text: widget.hotel.board);
    checkInCtrl = TextEditingController(text: widget.hotel.checkIn);
    checkOutCtrl = TextEditingController(text: widget.hotel.checkOut);
    thuCtrl = TextEditingController(text: widget.hotel.transportThursday ?? "");
    friCtrl = TextEditingController(text: widget.hotel.transportFriday ?? "");
    satCtrl = TextEditingController(text: widget.hotel.transportSaturday ?? "");
    sunCtrl = TextEditingController(text: widget.hotel.transportSunday ?? "");
    guideCtrl = TextEditingController(text: widget.hotel.experienceGuide ?? "");
    scheduleCtrl = TextEditingController(text: widget.hotel.entertainmentSchedule ?? "");
  }

  @override
  void dispose() {
    transportCtrl.dispose();
    pickupCtrl.dispose();
    boardCtrl.dispose();
    checkInCtrl.dispose();
    checkOutCtrl.dispose();
    thuCtrl.dispose();
    friCtrl.dispose();
    satCtrl.dispose();
    sunCtrl.dispose();
    guideCtrl.dispose();
    scheduleCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
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
              (widget.hotel.hotelType == 'glamping' || widget.hotel.hotelType == 'cruise')
                  ? 'Edit ${(widget.hotel.hotelType ?? '')[0].toUpperCase()}${(widget.hotel.hotelType ?? '').substring(1)} Details'
                  : 'Edit Hotel & Logistics for ${widget.hotel.hotelName}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFFFFD700)),
            ),
            const SizedBox(height: 16),
            
            if (widget.canEditManager) ...[
              _buildManagementTeamSection(widget.hotel.key),
              const SizedBox(height: 16),
            ],

            _buildExpansionTile(1, 'Hotel Details', [
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
            ]),

            _buildExpansionTile(2, 'Transport Details', [
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
              const SizedBox(height: 12),
              _buildField(friCtrl, 'Friday Schedule'),
              const SizedBox(height: 12),
              _buildField(satCtrl, 'Saturday Schedule'),
              const SizedBox(height: 12),
              _buildField(sunCtrl, 'Sunday Schedule'),
            ]),

            if (widget.hotel.hotelType == 'glamping' || widget.hotel.hotelType == 'cruise')
              _buildExpansionTile(3, 'Experience Details', [
                const SizedBox(height: 12),
                _buildField(guideCtrl, 'Experience Guide', maxLines: 4),
                const SizedBox(height: 12),
                _buildField(scheduleCtrl, 'Entertainment Schedule', maxLines: 4),
              ]),

            const SizedBox(height: 24),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFD700), 
                foregroundColor: const Color(0xFF001436),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () async {
                final updatedHotel = widget.hotel.copyWith(
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

                // Capture navigator before async gap
                final navigator = Navigator.of(context);

                await FirebaseFirestore.instance
                    .collection('hotels')
                    .doc(widget.hotel.key)
                    .update(updatedHotel.toMap());

                widget.onSave();
                
                // Guard navigation with mounted check
                if (!mounted) return;
                navigator.pop();
              },
              child: const Text('SAVE ALL CHANGES', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1)),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildExpansionTile(int index, String title, List<Widget> children) {
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        key: PageStorageKey('section_$index'),
        initiallyExpanded: expandedIndex == index,
        onExpansionChanged: (isExpanded) {
          setState(() => expandedIndex = isExpanded ? index : 0);
        },
        tilePadding: EdgeInsets.zero,
        iconColor: const Color(0xFFFFD700),
        collapsedIconColor: Colors.white54,
        title: Text(
          title,
          style: const TextStyle(color: Color(0xFFFFD700), fontSize: 15, fontWeight: FontWeight.bold),
        ),
        children: [...children, const SizedBox(height: 16)],
      ),
    );
  }

  Widget _buildField(TextEditingController controller, String label, {int maxLines = 1}) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      style: const TextStyle(color: Colors.white, fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white38),
        filled: true,
        fillColor: Colors.white.withAlpha(13),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFFFD700))),
      ),
    );
  }
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
              onPressed: () => _confirmBroadcast(context, senderName, messageCtrl.text, selectedTarget),
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

  // 1. Capture the navigator for the bottom sheet before the async gap
  final sheetNavigator = Navigator.of(context);

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

            // 2. Check if the dialog context is still valid before popping the dialog
            if (!dContext.mounted) return;
            Navigator.pop(dContext);

            // 3. Use the captured navigator to pop the bottom sheet
            sheetNavigator.pop();
            
            // 4. Use the original context with a mounted guard for the SnackBar
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Broadcast sent'), 
                  backgroundColor: Colors.green,
                ),
              );
            }
          },
          child: const Text('Yes'),
        ),
      ],
    ),
  );
}