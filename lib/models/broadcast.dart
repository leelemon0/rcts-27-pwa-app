import 'package:cloud_firestore/cloud_firestore.dart';

class Broadcast {
  final String sender;
  final String message;
  final String target;
  final DateTime? timestamp; // Added to help with sorting

  const Broadcast({
    required this.sender,
    required this.message,
    this.target = 'all',
    this.timestamp,
  });

  // Factory to create a Broadcast from a Firestore document
  factory Broadcast.fromMap(Map<String, dynamic> map) {
    return Broadcast(
      sender: map['sender'] ?? 'RCTS',
      message: map['message'] ?? '',
      target: map['target'] ?? 'all',
      // Handles Firestore Timestamp conversion to Dart DateTime
      timestamp: (map['timestamp'] as Timestamp?)?.toDate(),
    );
  }

  // Method to convert Broadcast to a Map for saving to Firestore
  Map<String, dynamic> toMap() {
    return {
      'sender': sender,
      'message': message,
      'target': target,
      'timestamp': timestamp ?? FieldValue.serverTimestamp(),
    };
  }

  bool visibleFor(String? hotelKey) {
    return target == 'all' || target == hotelKey;
  }
}