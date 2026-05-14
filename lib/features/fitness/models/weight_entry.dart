class WeightEntry {
  final String id;
  final DateTime date;
  final double weightKg;

  const WeightEntry({
    required this.id,
    required this.date,
    required this.weightKg,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'date': date.toIso8601String(),
        'weightKg': weightKg,
      };

  factory WeightEntry.fromJson(Map json) => WeightEntry(
        id: json['id'] as String,
        date: DateTime.parse(json['date'] as String),
        weightKg: (json['weightKg'] as num).toDouble(),
      );
}
