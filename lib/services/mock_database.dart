import 'dart:async';

import '../models/broadcast.dart';
import '../models/client_data.dart';
import '../models/hotel.dart';
import '../models/user.dart';

class MockDatabase {
  MockDatabase._();

  static final Map<String, User> users = {
    'admin@rcts.co.uk': const User(email: 'admin@rcts.co.uk', name: 'Event Director', role: 'superuser'),
    'alex@rcts.co.uk': const User(email: 'alex@rcts.co.uk', name: 'Alex Lorimer', role: 'manager', hotelKey: 'talbot_cork'),
    'richard@rcts.co.uk': const User(email: 'richard@rcts.co.uk', name: 'Richard Parker', role: 'manager', hotelKey: 'woodlands_adare'),
    'giles@rcts.co.uk': const User(email: 'giles@rcts.co.uk', name: 'Giles Toosey', role: 'manager', hotelKey: 'absolute_limerick'),
    'herring@example.com': const User(email: 'herring@example.com', name: 'Heather Herringbone', role: 'user', hotelKey: 'talbot_cork', roomID: '101', room: 'Deluxe Double', ref: '003220077342', isLead: true),
    'user1@example.com': const User(email: 'user1@example.com', name: 'John Bananatrees', role: 'user', hotelKey: 'talbot_cork', roomID: '102', room: 'Executive Double', ref: '00322007734532', isLead: true),
    'user2@example.com': const User(email: 'user2@example.com', name: 'Gregory Picketfence', role: 'user', hotelKey: 'talbot_cork', roomID: '103', room: 'Deluxe Double', ref: '003226969696', isLead: true),
    'user3@example.com': const User(email: 'user3@example.com', name: 'Jennifer Bimafahs', role: 'user', hotelKey: 'talbot_cork', roomID: '103', room: 'Deluxe Double', ref: '006740077342', isLead: false),
    'user4@example.com': const User(email: 'user4@example.com', name: 'Zelda Marmalade', role: 'user', hotelKey: 'talbot_cork', roomID: '104', room: 'Executive Double', ref: '00322007734532', isLead: true),
    'user5@example.com': const User(email: 'user5@example.com', name: 'Jeremy Pingpong', role: 'user', hotelKey: 'talbot_cork', roomID: '104', room: 'Executive Double', ref: '003226969696', isLead: false),
    'user6@example.com': const User(email: 'user6@example.com', name: 'Roberto Schadenfreude', role: 'user', hotelKey: 'talbot_cork', roomID: '105', room: 'King Double', ref: '006740077342', isLead: true),
    'user7@example.com': const User(email: 'user7@example.com', name: 'Arthur Portobello', role: 'user', hotelKey: 'talbot_cork', roomID: '106', room: 'Rubbish Single', ref: '00322007734532', isLead: true),
    'user8@example.com': const User(email: 'user8@example.com', name: 'Henrietta Poppadom', role: 'user', hotelKey: 'talbot_cork', roomID: '107', room: 'Deluxe Double', ref: '003226969696', isLead: true),
    'user9@example.com': const User(email: 'user9@example.com', name: 'Steve "Stonecold" Austin', role: 'user', hotelKey: 'talbot_cork', roomID: '107', room: 'Deluxe Double', ref: '006740077342', isLead: false),
    'user10@example.com': const User(email: 'user10@example.com', name: 'Linda Blueprince', role: 'user', hotelKey: 'talbot_cork', roomID: '107', room: 'Deluxe Double', ref: '00322007734532', isLead: false),
    'user11@example.com': const User(email: 'user11@example.com', name: 'The actor formerly known as Hulk', role: 'user', hotelKey: 'talbot_cork', roomID: '108', room: 'Penthouse Suite', ref: '003226969696', isLead: true),
    'user12@example.com': const User(email: 'user12@example.com', name: 'Spongebob Squarepants', role: 'user', hotelKey: 'talbot_cork', roomID: '109', room: 'A Pineapple Under the Sea', ref: '006740077342', isLead: true),
    'user13@example.com': const User(email: 'user13@example.com', name: 'Patrick Star', role: 'user', hotelKey: 'talbot_cork', roomID: '109', room: 'Executive Double', ref: '00322007734532', isLead: false),
    'user22@example.com': const User(email: 'user22@example.com', name: 'Sebastien Montoya', role: 'user', hotelKey: 'talbot_cork', roomID: '110', room: 'Deluxe Double', ref: '003226969696', isLead: true),
    'user33@example.com': const User(email: 'user33@example.com', name: 'Showaddywaddy', role: 'user', hotelKey: 'talbot_cork', roomID: '111', room: 'Deluxe Double', ref: '006740077342', isLead: true),
    'jack@rcts.co.uk': const User(email: 'jack@rcts.co.uk', name: 'Jack', role: 'user', hotelKey: 'adare_manor', roomID: '109', room: 'Presidential Suite', ref: '001110055999'),
  };

  static final Map<String, Hotel> hotels = {
    'talbot_cork': const Hotel(
      key: 'talbot_cork',
      hotelRef: 'LMK0062',
      hotelName: 'Talbot Hotel Cork',
      address: 'Main St, Ballincollig, Cork, P31 NY02',
      board: 'Breakfast Included',
      transport: 'Executive Coach (Silver)',
      pickup: 'Hotel Lobby Entrance',
      checkIn: '15:00',
      checkOut: '11:00',
    ),
    'adare_manor': const Hotel(
      key: 'adare_manor',
      hotelRef: 'LMK0001',
      hotelName: 'Adare Manor',
      address: 'Adare, Co. Limerick, V94 W8P3',
      board: 'Breakfast Included',
      transport: 'Private Helicopter Transfer',
      pickup: 'Helipad outside spa',
      checkIn: '15:00',
      checkOut: '12:00',
    ),
    'woodlands_adare': const Hotel(
      key: 'woodlands_adare',
      hotelRef: 'LMK2027',
      hotelName: 'Glamping at the Woodlands',
      address: 'Fitzgeralds Woodlands House Hotel, Knockanes, Adare, Co. Limerick, V94 F1P9',
      board: 'All-Inclusive',
      transport: 'Your own two feet',
      pickup: 'Bottomless coffee',
      checkIn: '12:00',
      checkOut: '11:00',
    ),
    'absolute_limerick': const Hotel(
      key: 'absolute_limerick',
      hotelRef: 'LMK0003',
      hotelName: 'Absolute Hotel Limerick',
      address: "Sir Harry's Mall, St. Francis Abbey, Limerick",
      board: 'Bed & Breakfast',
      transport: 'Coach',
      pickup: 'Round the corner to the right',
      checkIn: '15:00',
      checkOut: '11:00',
    ),
  };

  static final List<Broadcast> broadcasts = [
    const Broadcast(sender: 'System', message: 'Welcome to the Ryder Cup 2027!'),
  ];

  static List<User> get managers => users.values.where((user) => user.role == 'manager').toList();

  static User? managerForHotel(String hotelKey) {
    for (final user in users.values) {
      if (user.role == 'manager' && user.hotelKey == hotelKey) {
        return user;
      }
    }
    return null;
  }

  static void assignManagerToHotel(String hotelKey, String? managerEmail) {
    // Unassign any current manager from this hotel.
    for (final entry in users.entries) {
      final user = entry.value;
      if (user.role == 'manager' && user.hotelKey == hotelKey) {
        users[entry.key] = user.copyWith(hotelKey: null);
      }
    }

    if (managerEmail == null) return;
    final manager = users[managerEmail];
    if (manager == null || manager.role != 'manager') return;
    users[managerEmail] = manager.copyWith(hotelKey: hotelKey);
  }

  static Future<ClientData?> getClientData(String email) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final normalizedEmail = email.toLowerCase().trim();
    final user = users[normalizedEmail];
    if (user == null) return null;

    final hotel = user.hotelKey == null ? null : hotels[user.hotelKey!];
    return ClientData(user: user, hotel: hotel);
  }

  static void updateHotel(
    String key, {
    required String transport,
    required String pickup,
    required String board,
    required String checkIn,
    required String checkOut,
  }) {
    final hotel = hotels[key];
    if (hotel == null) return;
    hotels[key] = hotel.copyWith(
      transport: transport,
      pickup: pickup,
      board: board,
      checkIn: checkIn,
      checkOut: checkOut,
    );
  }

  static void sendBroadcast(String sender, String message, {String target = 'all'}) {
    broadcasts.insert(0, Broadcast(sender: sender, message: message, target: target));
  }
}
