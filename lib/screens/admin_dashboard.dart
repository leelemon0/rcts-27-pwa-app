import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/hotel.dart';
import '../models/user.dart';
import '../widgets/modal_sheets.dart';
import '../widgets/hotel_card_widget.dart';
import '../widgets/staff_list_item_widget.dart';
import '../services/admin_dashboard_service.dart';
import 'admin_room_manifest_view.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> with SingleTickerProviderStateMixin {
  final _service = AdminDashboardService();
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Event Manager Portal'),
        backgroundColor: const Color(0xFF001436),
        automaticallyImplyLeading: false,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFFFFD700),
          labelColor: const Color(0xFFFFD700),
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(icon: Icon(Icons.hotel), text: 'Hotels'),
            Tab(icon: Icon(Icons.badge), text: 'Staff List'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => Navigator.pushReplacementNamed(context, '/login'),
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _HotelTabView(service: _service),
          _StaffTabView(service: _service),
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

/// Hotel tab view with state caching
class _HotelTabView extends StatefulWidget {
  final AdminDashboardService service;

  const _HotelTabView({
    required this.service,
  });

  @override
  State<_HotelTabView> createState() => _HotelTabViewState();
}

class _HotelTabViewState extends State<_HotelTabView>
    with AutomaticKeepAliveClientMixin {
  bool _showUnmanagedOnly = false;

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('staff').snapshots(),
      builder: (context, staffSnapshot) {
        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('hotels').snapshots(),
          builder: (context, hotelSnapshot) {
            return StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('guests').snapshots(),
              builder: (context, guestSnapshot) {
                if (hotelSnapshot.hasError ||
                    staffSnapshot.hasError ||
                    guestSnapshot.hasError) {
                  return const Center(
                    child: Text('Error loading data',
                        style: TextStyle(color: Colors.white)),
                  );
                }

                if (!hotelSnapshot.hasData ||
                    !staffSnapshot.hasData ||
                    !guestSnapshot.hasData) {
                  return const Center(
                    child: CircularProgressIndicator(color: Color(0xFFFFD700)),
                  );
                }

                // Map data outside of builder to separate business logic
                final allStaff = staffSnapshot.data!.docs
                    .map((doc) =>
                        User.fromMap(doc.id, doc.data() as Map<String, dynamic>))
                    .toList();

                final allGuests = guestSnapshot.data!.docs
                    .map((doc) =>
                        User.fromMap(doc.id, doc.data() as Map<String, dynamic>))
                    .toList();

                var hotelDocs = hotelSnapshot.data!.docs;

                if (_showUnmanagedOnly) {
                  hotelDocs = hotelDocs.where((doc) {
                    final hotelId = doc.id;
                    return !allStaff.any((s) {
                      if (s.role != 'manager' || s.hotelKey == null) return false;
                      // Check if this hotelId exists anywhere in the manager's keys
                      return s.hotelKey!.split(',').map((e) => e.trim()).contains(hotelId);
                    });
                  }).toList();
                }

                final managerAssignmentCounts =
                    widget.service.getManagerAssignmentCounts(
                        widget.service.getManagers(allStaff));

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: hotelDocs.length + 1,
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      return _buildHotelHeader();
                    }

                    final doc = hotelDocs[index - 1];
                    final hotel = Hotel.fromMap(
                        doc.id, doc.data() as Map<String, dynamic>);
                    final assignedManagers =
                        widget.service.getManagersForHotel(
                            widget.service.getManagers(allStaff), hotel.key);
                    final guestsForThisHotel =
                        widget.service.getGuestsForHotel(allGuests, hotel.key);
                    final uniqueRooms =
                        widget.service.countUniqueRooms(guestsForThisHotel);

                    return HotelCardWidget(
                      hotel: hotel,
                      assignedManagers: assignedManagers,
                      managerAssignmentCounts: managerAssignmentCounts,
                      uniqueRooms: uniqueRooms,
                      totalGuests: guestsForThisHotel.length,
                      onManifestView: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => AdminRoomManifestView(hotel: hotel),
                          ),
                        );
                      },
                      onEditHotel: () {
                        showEditHotelSheet(context, hotel, () {
                          if (mounted) setState(() {});
                        });
                      },
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildHotelHeader() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Master Hotel List',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Color(0xFFFFD700),
            ),
          ),
          FilterChip(
            label: const Text('View Unassigned Hotels Only'),
            selected: _showUnmanagedOnly,
            selectedColor: Colors.redAccent.withValues(alpha: 0.3),
            checkmarkColor: Colors.redAccent,
            labelStyle: TextStyle(
              color: _showUnmanagedOnly ? Colors.redAccent : Colors.white54,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
            backgroundColor: Colors.white10,
            onSelected: (bool selected) {
              setState(() => _showUnmanagedOnly = selected);
            },
          ),
        ],
      ),
    );
  }
}

/// Staff tab view with state caching
class _StaffTabView extends StatefulWidget {
  final AdminDashboardService service;

  const _StaffTabView({required this.service});

  @override
  State<_StaffTabView> createState() => _StaffTabViewState();
}

class _StaffTabViewState extends State<_StaffTabView>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('staff').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFFFFD700)),
          );
        }

        final staffMembers = snapshot.data!.docs
            .map((doc) =>
                User.fromMap(doc.id, doc.data() as Map<String, dynamic>))
            .toList();

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: staffMembers.length,
          separatorBuilder: (context, index) =>
              const Divider(color: Colors.white10),
          itemBuilder: (context, index) {
            return StaffListItemWidget(person: staffMembers[index]);
          },
        );
      },
    );
  }
}