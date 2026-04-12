import 'package:flutter/material.dart';
import '../models/user.dart';

/// Reusable widget for displaying individual guest information.
class GuestRowWidget extends StatelessWidget {
  final User guest;

  const GuestRowWidget({
    super.key,
    required this.guest,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  guest.name,
                  style: TextStyle(
                    color: guest.isLeadGuest ? const Color(0xFFFFD700) : Colors.white,
                    fontWeight: guest.isLeadGuest ? FontWeight.bold : FontWeight.normal,
                    fontSize: 14,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  guest.email,
                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          SizedBox(
            width: 120,
            child: Row(
              mainAxisSize: MainAxisSize.max,
              children: [
                if (guest.hasTicket)
                  const SizedBox(
                    width: 14,
                    height: 14,
                    child: Center(
                      child: Icon(Icons.confirmation_number, size: 14, color: Color(0xFFFFD700)),
                    ),
                  )
                else
                  const SizedBox(width: 14, height: 14),
                const SizedBox(width: 6),
                if (guest.hasTransport)
                  const SizedBox(
                    width: 14,
                    height: 14,
                    child: Center(
                      child: Icon(Icons.directions_bus, size: 14, color: Color(0xFFFFD700)),
                    ),
                  )
                else
                  const SizedBox(width: 14, height: 14),
                const SizedBox(width: 8),
                if (guest.isLeadGuest)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFD700).withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'Lead Guest',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Color(0xFFFFD700), fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
