import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/hotel.dart';
import '../models/user.dart';
import '../widgets/modal_sheets.dart';
import '../widgets/hotel_card_widget.dart';
import '../widgets/staff_list_item_widget.dart';
import '../services/admin_dashboard_service.dart';
import 'admin_room_manifest_view.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  // ADD THIS METHOD
  void _handleLogout() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF001436),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: const Text(
            'Confirm Logout',
            style: TextStyle(color: Color(0xFFFFD700)),
          ),
          content: const Text(
            'Are you sure you want to exit?',
            style: TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('CANCEL', style: TextStyle(color: Colors.white38)),
            ),
            TextButton(
              onPressed: () async {
                final prefs = await SharedPreferences.getInstance();
                await prefs.remove('user_ref');
                
                if (!context.mounted) return;

                Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
              },
              child: const Text(
                'LOGOUT',
                style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
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
            icon: const Icon(Icons.search),
            onPressed: () {
              showSearch(
                context: context,
                delegate: GuestSearchDelegate(),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            // UPDATE THIS LINE
            onPressed: _handleLogout, 
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
      padding: const EdgeInsets.all(16), // Added consistent padding
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // FIX: Wrap the title in Expanded to prevent horizontal overflow
          Expanded(
            child: Text(
              'Master Hotel List',
              overflow: TextOverflow.ellipsis, // Adds '...' if space is too tight
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFFFFD700),
              ),
            ),
          ),
          const SizedBox(width: 8), // Add a small gap between title and chip
          FilterChip(
            label: const Text('Unassigned Only'), // Shortened label slightly to save space
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

class GuestSearchDelegate extends SearchDelegate {
@override
  List<Widget>? buildActions(BuildContext context) {
    return [
      // Only show the button if there is text to clear
      if (query.isNotEmpty)
        Padding(
          padding: const EdgeInsets.only(right: 8.0),
          child: Center(
            child: TextButton(
              onPressed: () => query = '',
              child: const Text(
                'CLEAR',
                style: TextStyle(
                  color: Color(0xFFFFD700), // Matching your gold accent color
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        ),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () => close(context, null),
    );
  }

  @override
  Widget buildResults(BuildContext context) => _buildSearchResults();

  @override
  Widget buildSuggestions(BuildContext context) => _buildSearchResults();

  Widget _buildSearchResults() {
    if (query.length < 2) {
      return const Center(
        child: Text("Enter at least 2 characters to search...",
            style: TextStyle(color: Colors.white54)),
      );
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('guests').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox();

        final results = snapshot.data!.docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final name = (data['name'] ?? '').toString().toLowerCase();
          final email = (data['email'] ?? '').toString().toLowerCase();
          final searchLower = query.toLowerCase();
          return name.contains(searchLower) || email.contains(searchLower);
        }).toList();

        if (results.isEmpty) {
          return const Center(
            child: Text("No guests found matching that search.",
                style: TextStyle(color: Colors.white54)),
          );
        }

        return ListView.builder(
          itemCount: results.length,
          itemBuilder: (context, index) {
            final guest = User.fromMap(
                results[index].id, results[index].data() as Map<String, dynamic>);

            return ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              title: Text(guest.name, 
                  style: const TextStyle(color: Color(0xFFFFD700), fontWeight: FontWeight.bold)),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(guest.email, style: const TextStyle(color: Colors.white70)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.hotel, size: 14, color: Colors.white38),
                      const SizedBox(width: 4),
                      Text("Hotel: ${guest.hotelKey ?? 'Unassigned'}", 
                          style: const TextStyle(color: Colors.white38, fontSize: 12)),
                      const SizedBox(width: 12),
                      const Icon(Icons.door_front_door, size: 14, color: Colors.white38),
                      const SizedBox(width: 4),
                      Text("Room: ${guest.roomID ?? 'N/A'}", 
                          style: const TextStyle(color: Colors.white38, fontSize: 12)),
                    ],
                  ),
                ],
              ),
              isThreeLine: true,
              onTap: () {
                close(context, null);
              },
            );
          },
        );
      },
    );
  }

  // Ensure the search page matches your dark theme
  @override
  ThemeData appBarTheme(BuildContext context) {
    return Theme.of(context).copyWith(
      appBarTheme: const AppBarTheme(backgroundColor: Color(0xFF001436)),
      inputDecorationTheme: const InputDecorationTheme(
        hintStyle: TextStyle(color: Colors.white38),
        border: InputBorder.none,
      ),
      textTheme: const TextTheme(
        titleLarge: TextStyle(color: Colors.white),
      ),
    );
  }
}