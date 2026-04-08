import 'package:flutter/material.dart';
import '../models/hotel.dart';
import '../services/mock_database.dart';

void showEditHotelSheet(BuildContext context, Hotel hotel, VoidCallback onSave, {bool canEditManager = true}) {
  final transportCtrl = TextEditingController(text: hotel.transport);
  final pickupCtrl = TextEditingController(text: hotel.pickup);
  final boardCtrl = TextEditingController(text: hotel.board);
  final checkInCtrl = TextEditingController(text: hotel.checkIn);
  final checkOutCtrl = TextEditingController(text: hotel.checkOut);
  String? selectedManagerEmail = MockDatabase.managerForHotel(hotel.key)?.email;
  final allManagers = MockDatabase.managers;

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
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Edit Hotel & Logistics',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFFFFD700)),
              ),
              const SizedBox(height: 16),
              if (canEditManager && allManagers.isNotEmpty) ...[
                const Text('Hotel Manager', style: TextStyle(color: Colors.white70, fontSize: 12)),
                const SizedBox(height: 8),
                DropdownButton<String?>(
                  value: selectedManagerEmail,
                  isExpanded: true,
                  dropdownColor: const Color(0xFF003C82),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('Unassigned')),
                    ...allManagers.map(
                      (manager) => DropdownMenuItem(
                        value: manager.email,
                        child: Text('${manager.name} (${manager.email})'),
                      ),
                    ),
                  ],
                  onChanged: (value) {
                    modalSetState(() {
                      selectedManagerEmail = value;
                    });
                  },
                ),
                const SizedBox(height: 12),
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
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFFD700), foregroundColor: const Color(0xFF001436)),
                onPressed: () {
                  MockDatabase.updateHotel(
                    hotel.key,
                    transport: transportCtrl.text,
                    pickup: pickupCtrl.text,
                    board: boardCtrl.text,
                    checkIn: checkInCtrl.text,
                    checkOut: checkOutCtrl.text,
                  );
                  if (canEditManager) {
                    MockDatabase.assignManagerToHotel(hotel.key, selectedManagerEmail);
                  }
                  onSave();
                  Navigator.pop(context);
                },
                child: const Text('Save All Changes'),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    ),
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
          left: 24,
          right: 24,
          top: 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Broadcast Alert', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFFFFD700))),
            const SizedBox(height: 16),
            if (fixedHotelKey == null) ...[
              const Text('Select Recipient Group:', style: TextStyle(color: Colors.white70, fontSize: 12)),
              DropdownButton<String>(
                value: selectedTarget,
                isExpanded: true,
                dropdownColor: const Color(0xFF003C82),
                items: [
                  const DropdownMenuItem(value: 'all', child: Text('All Guests (Global)')),
                  ...MockDatabase.hotels.entries.map(
                    (entry) => DropdownMenuItem(value: entry.key, child: Text('Guests at ${entry.value.hotelName}')),
                  ),
                ],
                onChanged: (value) {
                  if (value != null) {
                    modalSetState(() {
                      selectedTarget = value;
                    });
                  }
                },
              ),
              const SizedBox(height: 16),
            ],
            TextField(
              controller: messageCtrl,
              maxLines: 3,
              decoration: const InputDecoration(hintText: 'Enter message...', filled: true, fillColor: Colors.white10),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
              icon: const Icon(Icons.send),
              label: const Text('Send Priority Alert'),
              onPressed: () {
                final messageText = messageCtrl.text.trim();
                if (messageText.isEmpty) return;

                final targetLabel = selectedTarget == 'all'
                    ? 'All Guests (Global)'
                    : 'Guests at ${MockDatabase.hotels[selectedTarget]?.hotelName ?? selectedTarget}';

                showDialog(
                  context: context,
                  builder: (dialogContext) => AlertDialog(
                    backgroundColor: const Color(0xFF001436),
                    title: const Text('Ready to send?'),
                    content: Text('Send this alert to $targetLabel?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(dialogContext),
                        child: const Text('No'),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
                        onPressed: () {
                          MockDatabase.sendBroadcast(senderName, messageText, target: selectedTarget);
                          Navigator.pop(dialogContext);
                          Navigator.pop(parentContext);
                          ScaffoldMessenger.of(parentContext).showSnackBar(
                            SnackBar(
                              content: Text('Broadcast sent to $targetLabel'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        },
                        child: const Text('Yes'),
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    ),
  );
}