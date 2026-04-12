import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/broadcast.dart';

class BroadcastService {
  static String? _lastBroadcastId;

  static void listenForAlerts(BuildContext context, String? userHotelKey) {
    FirebaseFirestore.instance
        .collection('broadcasts')
        .orderBy('timestamp', descending: true)
        .limit(1)
        .snapshots()
        .listen((snapshot) {
      if (!context.mounted || snapshot.docs.isEmpty) return;

      final doc = snapshot.docs.first;
      final broadcast = Broadcast.fromMap(doc.data());

      // Check visibility and ensure we haven't shown THIS specific doc ID in this session
      if (broadcast.visibleFor(userHotelKey) && _lastBroadcastId != doc.id) {
        final ts = broadcast.timestamp;

        if (ts != null) {
          final ageInMinutes = DateTime.now().difference(ts).inMinutes;

          // Only pop up if the alert was sent in the last 5 minutes
          if (ageInMinutes < 5) {
            _lastBroadcastId = doc.id;
            _showPopup(context, broadcast);
          }
        }
      }
    });
  }

  static void _showPopup(BuildContext context, Broadcast broadcast) {
    if (!context.mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF001436),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: Color(0xFFFFD700)),
        ),
        title: Row(
          children: [
            const Icon(Icons.campaign, color: Color(0xFFFFD700)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                broadcast.sender,
                style: const TextStyle(color: Color(0xFFFFD700)),
              ),
            ),
          ],
        ),
        content: Text(
          broadcast.message,
          style: const TextStyle(color: Colors.white, fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'DISMISS',
              style: TextStyle(
                color: Color(0xFFFFD700),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}