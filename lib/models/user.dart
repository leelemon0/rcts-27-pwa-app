class User {
  final String email;
  final String name;
  final String role;
  final String? hotelKey;
  final String? roomID;
  final String? room;
  final String? ref;
  final bool? isLead;

  const User({
    required this.email,
    required this.name,
    required this.role,
    this.hotelKey,
    this.roomID,
    this.room,
    this.ref,
    this.isLead,
  });

  bool get isLeadGuest => isLead == true;

  User copyWith({
    String? name,
    String? role,
    String? hotelKey,
    String? roomID,
    String? room,
    String? ref,
    bool? isLead,
  }) {
    return User(
      email: email,
      name: name ?? this.name,
      role: role ?? this.role,
      hotelKey: hotelKey ?? this.hotelKey,
      roomID: roomID ?? this.roomID,
      room: room ?? this.room,
      ref: ref ?? this.ref,
      isLead: isLead ?? this.isLead,
    );
  }

  factory User.fromMap(String email, Map<String, dynamic> data) {
    return User(
      email: email,
      name: data['name'] as String? ?? '',
      role: data['role'] as String? ?? 'user',
      hotelKey: data['hotelKey'] as String?,
      roomID: data['roomID'] as String?,
      room: data['room'] as String?,
      ref: data['ref'] as String?,
      isLead: data['isLead'] as bool?,
    );
  }
}
