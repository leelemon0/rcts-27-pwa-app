class Broadcast {
  final String sender;
  final String message;
  final String target;

  const Broadcast({
    required this.sender,
    required this.message,
    this.target = 'all',
  });

  bool visibleFor(String? hotelKey) {
    return target == 'all' || target == hotelKey;
  }
}
