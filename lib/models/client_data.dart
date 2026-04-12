import 'hotel.dart';
import 'user.dart';

class ClientData {
  final User user;
  final Hotel? hotel;

  const ClientData({
    required this.user,
    this.hotel,
  });

  // Helper getters to simplify UI code in the Itinerary Screen
  String? get hotelName => hotel?.hotelName;
  String? get address => hotel?.address;
  String? get board => hotel?.board;
  String? get transport => hotel?.transport;
  String? get pickup => hotel?.pickup;
  String? get checkIn => hotel?.checkIn;
  String? get checkOut => hotel?.checkOut;

  /// Optional: A factory to create ClientData from a user and a nullable hotel map
  /// This is useful if you fetch them both during the login process.
  factory ClientData.combine(User user, Hotel? hotel) {
    return ClientData(
      user: user,
      hotel: hotel,
    );
  }
}