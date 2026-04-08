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
  });

  Hotel copyWith({
    String? transport,
    String? pickup,
    String? board,
    String? checkIn,
    String? checkOut,
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
    );
  }

  factory Hotel.fromMap(String key, Map<String, dynamic> data) {
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
    );
  }
}
