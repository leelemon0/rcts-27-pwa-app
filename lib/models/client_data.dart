import 'hotel.dart';
import 'user.dart';

class ClientData {
  final User user;
  final Hotel? hotel;

  const ClientData({
    required this.user,
    this.hotel,
  });

  String? get hotelName => hotel?.hotelName;
  String? get address => hotel?.address;
  String? get board => hotel?.board;
  String? get transport => hotel?.transport;
  String? get pickup => hotel?.pickup;
  String? get checkIn => hotel?.checkIn;
  String? get checkOut => hotel?.checkOut;
}
