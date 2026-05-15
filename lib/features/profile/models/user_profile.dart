class UserProfile {
  final String name;
  final int age;
  final String gender;
  final double heightCm;
  final double weightKg;
  final double goalWeightKg;
  final String fitnessLevel;

  final String studyMode;
  final String caLevel;
  final List<String> caSubjects;

  final String occupation;
  final double dailyFreeHours;
  final String sleepSchedule;
  final double studyGoalHoursPerDay;
  final double workoutGoalMinutesPerDay;
  final int stressLevel; // 1..5
  final double waterGoalLiters;
  final bool prayerRemindersOn;
  final String preferredWorkoutType;

  final double? latitude;
  final double? longitude;

  final DateTime createdAt;

  const UserProfile({
    required this.name,
    required this.age,
    required this.gender,
    required this.heightCm,
    required this.weightKg,
    required this.goalWeightKg,
    required this.fitnessLevel,
    required this.studyMode,
    required this.caLevel,
    required this.caSubjects,
    required this.occupation,
    required this.dailyFreeHours,
    required this.sleepSchedule,
    required this.studyGoalHoursPerDay,
    required this.workoutGoalMinutesPerDay,
    required this.stressLevel,
    required this.waterGoalLiters,
    required this.prayerRemindersOn,
    required this.preferredWorkoutType,
    required this.createdAt,
    this.latitude,
    this.longitude,
  });

  double get bmi {
    if (heightCm <= 0) return 0;
    final m = heightCm / 100.0;
    return weightKg / (m * m);
  }

  UserProfile copyWith({
    String? name,
    int? age,
    String? gender,
    double? heightCm,
    double? weightKg,
    double? goalWeightKg,
    String? fitnessLevel,
    String? studyMode,
    String? caLevel,
    List<String>? caSubjects,
    String? occupation,
    double? dailyFreeHours,
    String? sleepSchedule,
    double? studyGoalHoursPerDay,
    double? workoutGoalMinutesPerDay,
    int? stressLevel,
    double? waterGoalLiters,
    bool? prayerRemindersOn,
    String? preferredWorkoutType,
    double? latitude,
    double? longitude,
  }) {
    return UserProfile(
      name: name ?? this.name,
      age: age ?? this.age,
      gender: gender ?? this.gender,
      heightCm: heightCm ?? this.heightCm,
      weightKg: weightKg ?? this.weightKg,
      goalWeightKg: goalWeightKg ?? this.goalWeightKg,
      fitnessLevel: fitnessLevel ?? this.fitnessLevel,
      studyMode: studyMode ?? this.studyMode,
      caLevel: caLevel ?? this.caLevel,
      caSubjects: caSubjects ?? this.caSubjects,
      occupation: occupation ?? this.occupation,
      dailyFreeHours: dailyFreeHours ?? this.dailyFreeHours,
      sleepSchedule: sleepSchedule ?? this.sleepSchedule,
      studyGoalHoursPerDay: studyGoalHoursPerDay ?? this.studyGoalHoursPerDay,
      workoutGoalMinutesPerDay:
          workoutGoalMinutesPerDay ?? this.workoutGoalMinutesPerDay,
      stressLevel: stressLevel ?? this.stressLevel,
      waterGoalLiters: waterGoalLiters ?? this.waterGoalLiters,
      prayerRemindersOn: prayerRemindersOn ?? this.prayerRemindersOn,
      preferredWorkoutType: preferredWorkoutType ?? this.preferredWorkoutType,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'age': age,
        'gender': gender,
        'heightCm': heightCm,
        'weightKg': weightKg,
        'goalWeightKg': goalWeightKg,
        'fitnessLevel': fitnessLevel,
        'studyMode': studyMode,
        'caLevel': caLevel,
        'caSubjects': caSubjects,
        'occupation': occupation,
        'dailyFreeHours': dailyFreeHours,
        'sleepSchedule': sleepSchedule,
        'studyGoalHoursPerDay': studyGoalHoursPerDay,
        'workoutGoalMinutesPerDay': workoutGoalMinutesPerDay,
        'stressLevel': stressLevel,
        'waterGoalLiters': waterGoalLiters,
        'prayerRemindersOn': prayerRemindersOn,
        'preferredWorkoutType': preferredWorkoutType,
        'latitude': latitude,
        'longitude': longitude,
        'createdAt': createdAt.toIso8601String(),
      };

  factory UserProfile.fromJson(Map json) => UserProfile(
        name: json['name'] as String,
        age: (json['age'] as num).toInt(),
        gender: json['gender'] as String,
        heightCm: (json['heightCm'] as num).toDouble(),
        weightKg: (json['weightKg'] as num).toDouble(),
        goalWeightKg: (json['goalWeightKg'] as num).toDouble(),
        fitnessLevel: json['fitnessLevel'] as String,
        studyMode: json['studyMode'] as String? ?? 'ca',
        caLevel: json['caLevel'] as String,
        caSubjects: (json['caSubjects'] as List).cast<String>(),
        occupation: json['occupation'] as String,
        dailyFreeHours: (json['dailyFreeHours'] as num).toDouble(),
        sleepSchedule: json['sleepSchedule'] as String,
        studyGoalHoursPerDay:
            (json['studyGoalHoursPerDay'] as num).toDouble(),
        workoutGoalMinutesPerDay:
            (json['workoutGoalMinutesPerDay'] as num).toDouble(),
        stressLevel: (json['stressLevel'] as num).toInt(),
        waterGoalLiters: (json['waterGoalLiters'] as num).toDouble(),
        prayerRemindersOn: json['prayerRemindersOn'] as bool,
        preferredWorkoutType: json['preferredWorkoutType'] as String,
        latitude: (json['latitude'] as num?)?.toDouble(),
        longitude: (json['longitude'] as num?)?.toDouble(),
        createdAt: DateTime.parse(json['createdAt'] as String),
      );
}
