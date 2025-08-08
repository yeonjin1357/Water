class WaterIntake {
  final String id;
  final int amount;
  final DateTime timestamp;
  final String? note;
  final String drinkType;

  WaterIntake({
    required this.id,
    required this.amount,
    required this.timestamp,
    this.note,
    this.drinkType = 'water',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'amount': amount,
      'timestamp': timestamp.toIso8601String(),
      'note': note,
      'drinkType': drinkType,
    };
  }

  factory WaterIntake.fromMap(Map<String, dynamic> map) {
    return WaterIntake(
      id: map['id'],
      amount: map['amount'],
      timestamp: DateTime.parse(map['timestamp']),
      note: map['note'],
      drinkType: map['drinkType'] ?? 'water',
    );
  }
}