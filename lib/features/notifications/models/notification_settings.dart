import '../service/notification_service.dart';

class NotificationSettings {
  final NotificationTone tone;
  final bool prayerOn;
  final bool studyOn;
  final bool waterOn;
  final bool streakOn;

  final int studyHour;
  final int studyMinute;

  final int waterStartHour;
  final int waterEndHour;
  final int waterEverySeconds; // we store seconds for flexibility, default 2.5h

  final int streakHour;
  final int streakMinute;

  const NotificationSettings({
    required this.tone,
    required this.prayerOn,
    required this.studyOn,
    required this.waterOn,
    required this.streakOn,
    required this.studyHour,
    required this.studyMinute,
    required this.waterStartHour,
    required this.waterEndHour,
    required this.waterEverySeconds,
    required this.streakHour,
    required this.streakMinute,
  });

  factory NotificationSettings.defaults() => const NotificationSettings(
        tone: NotificationTone.motivational,
        prayerOn: true,
        studyOn: true,
        waterOn: true,
        streakOn: true,
        studyHour: 21,
        studyMinute: 0,
        waterStartHour: 8,
        waterEndHour: 22,
        waterEverySeconds: 9000, // 2.5 hours
        streakHour: 21,
        streakMinute: 30,
      );

  NotificationSettings copyWith({
    NotificationTone? tone,
    bool? prayerOn,
    bool? studyOn,
    bool? waterOn,
    bool? streakOn,
    int? studyHour,
    int? studyMinute,
    int? waterStartHour,
    int? waterEndHour,
    int? waterEverySeconds,
    int? streakHour,
    int? streakMinute,
  }) {
    return NotificationSettings(
      tone: tone ?? this.tone,
      prayerOn: prayerOn ?? this.prayerOn,
      studyOn: studyOn ?? this.studyOn,
      waterOn: waterOn ?? this.waterOn,
      streakOn: streakOn ?? this.streakOn,
      studyHour: studyHour ?? this.studyHour,
      studyMinute: studyMinute ?? this.studyMinute,
      waterStartHour: waterStartHour ?? this.waterStartHour,
      waterEndHour: waterEndHour ?? this.waterEndHour,
      waterEverySeconds: waterEverySeconds ?? this.waterEverySeconds,
      streakHour: streakHour ?? this.streakHour,
      streakMinute: streakMinute ?? this.streakMinute,
    );
  }

  Map<String, dynamic> toJson() => {
        'tone': tone.name,
        'prayerOn': prayerOn,
        'studyOn': studyOn,
        'waterOn': waterOn,
        'streakOn': streakOn,
        'studyHour': studyHour,
        'studyMinute': studyMinute,
        'waterStartHour': waterStartHour,
        'waterEndHour': waterEndHour,
        'waterEverySeconds': waterEverySeconds,
        'streakHour': streakHour,
        'streakMinute': streakMinute,
      };

  factory NotificationSettings.fromJson(Map json) {
    NotificationTone parseTone(String s) => NotificationTone.values.firstWhere(
          (t) => t.name == s,
          orElse: () => NotificationTone.motivational,
        );
    return NotificationSettings(
      tone: parseTone(json['tone'] as String? ?? 'motivational'),
      prayerOn: json['prayerOn'] as bool? ?? true,
      studyOn: json['studyOn'] as bool? ?? true,
      waterOn: json['waterOn'] as bool? ?? true,
      streakOn: json['streakOn'] as bool? ?? true,
      studyHour: (json['studyHour'] as num?)?.toInt() ?? 21,
      studyMinute: (json['studyMinute'] as num?)?.toInt() ?? 0,
      waterStartHour: (json['waterStartHour'] as num?)?.toInt() ?? 8,
      waterEndHour: (json['waterEndHour'] as num?)?.toInt() ?? 22,
      waterEverySeconds: (json['waterEverySeconds'] as num?)?.toInt() ?? 9000,
      streakHour: (json['streakHour'] as num?)?.toInt() ?? 21,
      streakMinute: (json['streakMinute'] as num?)?.toInt() ?? 30,
    );
  }
}
