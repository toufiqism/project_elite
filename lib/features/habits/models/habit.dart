class Habit {
  final String id;
  final String name;
  final String icon; // material icon name
  final bool negative; // 'no social media' type
  final DateTime createdAt;

  const Habit({
    required this.id,
    required this.name,
    required this.icon,
    required this.negative,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'icon': icon,
        'negative': negative,
        'createdAt': createdAt.toIso8601String(),
      };

  factory Habit.fromJson(Map json) => Habit(
        id: json['id'] as String,
        name: json['name'] as String,
        icon: json['icon'] as String,
        negative: json['negative'] as bool? ?? false,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );
}
