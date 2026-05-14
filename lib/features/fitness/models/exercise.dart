/// One exercise from ExerciseDB (https://exercisedb.p.rapidapi.com).
///
/// We cache these in Hive after fetching so the app keeps working offline
/// and so we don't burn the RapidAPI free-tier quota.
class Exercise {
  final String id;
  final String name;
  final String bodyPart;
  final String equipment;
  final String target;
  final String gifUrl;
  final List<String> secondaryMuscles;
  final List<String> instructions;

  const Exercise({
    required this.id,
    required this.name,
    required this.bodyPart,
    required this.equipment,
    required this.target,
    required this.gifUrl,
    required this.secondaryMuscles,
    required this.instructions,
  });

  bool get isBodyweight {
    final eq = equipment.toLowerCase();
    return eq == 'body weight' || eq == 'bodyweight' || eq == 'none';
  }

  bool get isCardio => bodyPart.toLowerCase() == 'cardio';

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'bodyPart': bodyPart,
        'equipment': equipment,
        'target': target,
        'gifUrl': gifUrl,
        'secondaryMuscles': secondaryMuscles,
        'instructions': instructions,
      };

  factory Exercise.fromJson(Map json) => Exercise(
        id: json['id']?.toString() ?? '',
        name: (json['name'] as String?) ?? '',
        bodyPart: (json['bodyPart'] as String?) ?? '',
        equipment: (json['equipment'] as String?) ?? '',
        target: (json['target'] as String?) ?? '',
        gifUrl: (json['gifUrl'] as String?) ?? '',
        secondaryMuscles:
            ((json['secondaryMuscles'] as List?) ?? const []).cast<String>(),
        instructions:
            ((json['instructions'] as List?) ?? const []).cast<String>(),
      );
}
