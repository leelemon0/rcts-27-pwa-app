import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user.dart';
import '../models/hotel.dart';

class AdminDashboardData {
  final List<User> staff;
  final List<Hotel> hotels;
  final List<User> guests;

  const AdminDashboardData({
    required this.staff,
    required this.hotels,
    required this.guests,
  });
}

class AdminDashboardService {
  static final _instance = AdminDashboardService._internal();

  factory AdminDashboardService() {
    return _instance;
  }

  AdminDashboardService._internal();

  /// Provides individual streams for admin dashboard data
  /// Call this once and reuse across the widget lifecycle
  Future<AdminDashboardData> initialiseData() async {
    try {
      final staffSnapshot = await FirebaseFirestore.instance.collection('staff').get();
      final hotelSnapshot = await FirebaseFirestore.instance.collection('hotels').get();
      final guestSnapshot = await FirebaseFirestore.instance.collection('guests').get();

      final staff = staffSnapshot.docs
          .map((doc) => User.fromMap(doc.id, doc.data()))
          .toList();

      final hotels = hotelSnapshot.docs
          .map((doc) => Hotel.fromMap(doc.id, doc.data()))
          .toList();

      final guests = guestSnapshot.docs
          .map((doc) => User.fromMap(doc.id, doc.data()))
          .toList();

      return AdminDashboardData(staff: staff, hotels: hotels, guests: guests);
    } catch (e) {
      rethrow;
    }
  }

  /// Provides a combined snapshot stream that updates all data sources together
  /// This prevents waterfall rebuilds by efficiently combining three streams
  /// Note: When ready to optimise further, consider implementing CombineLatest from rxdart package
  Stream<AdminDashboardData> getStreamedDashboardData() {
    // Placeholder for future optimisation with CombineLatest
    throw UnimplementedError(
      'Use individual stream builders in the UI layer for now. '
      'Future enhancement: Add rxdart dependency for CombineLatest.'
    );
  }

  /// Filter managers from staff
  List<User> getManagers(List<User> staff) {
    return staff.where((s) => s.role == 'manager').toList();
  }

/// Get assignment counts for multi-assignment warnings
  Map<String, int> getManagerAssignmentCounts(List<User> managers) {
    final Map<String, int> counts = {};
    for (var manager in managers) {
      if (manager.hotelKey != null && manager.hotelKey!.isNotEmpty) {
        // Split and count how many individual keys exist
        final keys = manager.hotelKey!.split(',').where((k) => k.trim().isNotEmpty);
        counts[manager.name] = keys.length;
      }
    }
    return counts;
  }

  /// Get managers assigned to a specific hotel
  List<User> getManagersForHotel(List<User> managers, String hotelKey) {
    return managers.where((m) {
      if (m.hotelKey == null) return false;
      // Split the string and check if this specific hotelKey is in the list
      return m.hotelKey!.split(',').map((e) => e.trim()).contains(hotelKey);
    }).toList();
  }

  /// Get guests assigned to a specific hotel
  List<User> getGuestsForHotel(List<User> guests, String hotelKey) {
    return guests.where((g) => g.hotelKey == hotelKey).toList();
  }

  /// Calculate unique rooms for a hotel
  int countUniqueRooms(List<User> hotelGuests) {
    return hotelGuests.map((g) => g.roomID).where((r) => r != null).toSet().length;
  }

  /// Get staff members for a specific role
  List<User> getStaffByRole(List<User> staff, String role) {
    return staff.where((s) => s.role == role).toList();
  }

/// Filter hotels that have no manager assignments
List<Hotel> filterUnmanagedHotels(List<Hotel> hotels, List<User> managers) {
  return hotels.where((hotel) {
    // Check if ANY manager has this hotel's key in their comma-separated list
    return !managers.any((m) {
      if (m.hotelKey == null) return false;
      return m.hotelKey!
          .split(',')
          .map((e) => e.trim())
          .contains(hotel.key);
    });
  }).toList();
  }
}