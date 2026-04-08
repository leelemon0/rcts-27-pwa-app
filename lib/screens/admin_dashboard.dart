import 'package:flutter/material.dart';

import '../services/mock_database.dart';
import '../widgets/modal_sheets.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Event Manager Portal'),
        backgroundColor: const Color(0xFF001436),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => Navigator.pushReplacementNamed(context, '/login'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Master Hotel List',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFFFFD700)),
          ),
          const SizedBox(height: 16),
          ...MockDatabase.hotels.entries.map((entry) {
            final hotel = entry.value;
            final manager = MockDatabase.managerForHotel(hotel.key);
            return Card(
              color: const Color(0xFF003C82),
              child: ListTile(
                title: Text(hotel.hotelName, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('Ref: ${hotel.hotelRef}\nManager: ${manager?.name ?? 'Unassigned'}'),
                trailing: const Icon(Icons.edit, color: Color(0xFFFFD700)),
                onTap: () {
                  showEditHotelSheet(context, hotel, () {
                    setState(() {});
                  });
                },
              ),
            );
          }),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.redAccent,
        icon: const Icon(Icons.campaign),
        label: const Text('Global Broadcast'),
        onPressed: () => showBroadcastSheet(context, 'RYDER CUP TRAVEL SERVICES'),
      ),
    );
  }
}
