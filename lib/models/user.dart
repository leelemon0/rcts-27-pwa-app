class User {
  final String email;
  final String name;
  final String role;
  final String? hotelKey;
  final List<String>? hotelKeys; // Added to support multiple hotels
  final String? roomID;
  final String? room;
  final String? ref;
  final bool? isLead;
  final bool hasTicket;
  final bool hasTransport;

  const User({
    required this.email,
    required this.name,
    required this.role,
    this.hotelKey,
    this.hotelKeys, // New field in constructor
    this.roomID,
    this.room,
    this.ref,
    this.isLead,
    this.hasTicket = false,
    this.hasTransport = false,
  });

  bool get isLeadGuest => isLead == true;

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'role': role,
      'hotelKey': hotelKey,
      'hotelKeys': hotelKeys, // Added to map
      'roomID': roomID,
      'room': room,
      'ref': ref,
      'isLead': isLead,
      'hasTicket': hasTicket,
      'hasTransport': hasTransport,
    };
  }

  User copyWith({
    String? name,
    String? role,
    String? hotelKey,
    List<String>? hotelKeys, // Added to copyWith
    String? roomID,
    String? room,
    String? ref,
    bool? isLead,
    bool? hasTicket,
    bool? hasTransport,
  }) {
    return User(
      email: email,
      name: name ?? this.name,
      role: role ?? this.role,
      hotelKey: hotelKey ?? this.hotelKey,
      hotelKeys: hotelKeys ?? this.hotelKeys, // Added to return
      roomID: roomID ?? this.roomID,
      room: room ?? this.room,
      ref: ref ?? this.ref,
      isLead: isLead ?? this.isLead,
      hasTicket: hasTicket ?? this.hasTicket,
      hasTransport: hasTransport ?? this.hasTransport,
    );
  }

  factory User.fromMap(String email, Map<String, dynamic> data) {
    // Handle the hotelKeys field if it's a comma-separated string
    final rawHotelKeys = data['hotelKeys'] as String?;
    List<String>? parsedKeys;
    
    if (rawHotelKeys != null && rawHotelKeys.isNotEmpty) {
      // Splits "key1, key2" into ["key1", "key2"] and removes extra whitespace
      parsedKeys = rawHotelKeys.split(',').map((e) => e.trim()).toList();
    }

    return User(
      email: email,
      name: data['name'] as String? ?? '',
      role: data['role'] as String? ?? 'user',
      hotelKey: data['hotelKey'] as String?,
      hotelKeys: parsedKeys, // Now a proper List<String>
      roomID: data['roomID']?.toString(),
      room: data['room'] as String?,
      ref: data['ref'] as String?,
      isLead: data['isLead'] as bool?,
      hasTicket: data['hasTicket'] == true,
      hasTransport: data['hasTransport'] == true,
    );
  }
}