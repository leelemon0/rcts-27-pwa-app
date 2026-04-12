import 'package:cloud_firestore/cloud_firestore.dart';

class Hotel {
  final String key;
  final String hotelRef;
  final String hotelName;
  final String address;
  final String board;
  final String transport;
  final String pickup;
  final String checkIn;
  final String checkOut;
  final String? coordinates; // New Field

  const Hotel({
    required this.key,
    required this.hotelRef,
    required this.hotelName,
    required this.address,
    required this.board,
    required this.transport,
    required this.pickup,
    required this.checkIn,
    required this.checkOut,
    this.coordinates, // New Field
  });

  Map<String, dynamic> toMap() {
    return {
      'hotelRef': hotelRef,
      'hotelName': hotelName,
      'address': address,
      'board': board,
      'transport': transport,
      'pickup': pickup,
      'checkIn': checkIn,
      'checkOut': checkOut,
      'coordinates': coordinates, // New Field
    };
  }

  Hotel copyWith({
    String? transport,
    String? pickup,
    String? board,
    String? checkIn,
    String? checkOut,
    String? coordinates, // New Field
  }) {
    return Hotel(
      key: key,
      hotelRef: hotelRef,
      hotelName: hotelName,
      address: address,
      board: board ?? this.board,
      transport: transport ?? this.transport,
      pickup: pickup ?? this.pickup,
      checkIn: checkIn ?? this.checkIn,
      checkOut: checkOut ?? this.checkOut,
      coordinates: coordinates ?? this.coordinates, // New Field
    );
  }

factory Hotel.fromMap(String key, Map<String, dynamic> data) {
  // Extract coordinates safely
  String? coordsString;
  final coordsData = data['coordinates'];

  if (coordsData is GeoPoint) {
    // Convert native GeoPoint to "lat,long" string for the URL launcher
    coordsString = '${coordsData.latitude},${coordsData.longitude}';
  } else if (coordsData is String) {
    coordsString = coordsData;
  }

    return Hotel(
      key: key,
      hotelRef: data['hotelRef'] as String? ?? '',
      hotelName: data['hotelName'] as String? ?? '',
      address: data['address'] as String? ?? '',
      board: data['board'] as String? ?? '',
      transport: data['transport'] as String? ?? '',
      pickup: data['pickup'] as String? ?? '',
      checkIn: data['checkIn'] as String? ?? '',
      checkOut: data['checkOut'] as String? ?? '',
      coordinates: coordsString, // Now it correctly receives a String
    );
  }
}