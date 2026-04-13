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
  final String? coordinates;
  final String? transportThursday;
  final String? transportFriday;
  final String? transportSaturday;
  final String? transportSunday;
  final String? hotelType; // 'Glamping', 'Cruise', or null
  final String? experienceGuide;
  final String? entertainmentSchedule;

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
    this.coordinates,
    this.transportThursday,
    this.transportFriday,
    this.transportSaturday,
    this.transportSunday,
    this.hotelType,
    this.experienceGuide,
    this.entertainmentSchedule,
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
      'coordinates': coordinates,
      'transportThursday': transportThursday,
      'transportFriday': transportFriday,
      'transportSaturday': transportSaturday,
      'transportSunday': transportSunday,
      'hotelType': hotelType,
      'experienceGuide': experienceGuide,
      'entertainmentSchedule': entertainmentSchedule,
    };
  }

  Hotel copyWith({
    String? transport,
    String? pickup,
    String? board,
    String? checkIn,
    String? checkOut,
    String? coordinates,
    String? transportThursday,
    String? transportFriday,
    String? transportSaturday,
    String? transportSunday,
    String? hotelType,
    String? experienceGuide,
    String? entertainmentSchedule,
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
      coordinates: coordinates ?? this.coordinates,
      transportThursday: transportThursday ?? this.transportThursday,
      transportFriday: transportFriday ?? this.transportFriday,
      transportSaturday: transportSaturday ?? this.transportSaturday,
      transportSunday: transportSunday ?? this.transportSunday,
      hotelType: hotelType ?? this.hotelType,
      experienceGuide: experienceGuide ?? this.experienceGuide,
      entertainmentSchedule: entertainmentSchedule ?? this.entertainmentSchedule,
    );
  }

  factory Hotel.fromMap(String key, Map<String, dynamic> data) {
    String? coordsString;
    final coordsData = data['coordinates'];

    if (coordsData is GeoPoint) {
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
      coordinates: coordsString,
      transportThursday: data['transportThursday'] as String?,
      transportFriday: data['transportFriday'] as String?,
      transportSaturday: data['transportSaturday'] as String?,
      transportSunday: data['transportSunday'] as String?,
      // Use null if empty string or missing to simplify UI logic
      hotelType: data['hotelType']?.toString().isEmpty ?? true ? null : data['hotelType'],
      experienceGuide: data['experienceGuide'] as String?,
      entertainmentSchedule: data['entertainmentSchedule'] as String?,
    );
  }
}