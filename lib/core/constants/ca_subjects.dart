class StudyMode {
  static const ca = 'ca';
  static const custom = 'custom';
}

class CALevel {
  static const certificate = 'Certificate';
  static const professional = 'Professional';
  static const advance = 'Advance';

  static const all = [certificate, professional, advance];
}

class CASubjects {
  static const Map<String, List<String>> byLevel = {
    CALevel.certificate: [
      'Assurance',
      'Accounting',
      'Business Technology and Finance',
      'Information Technology',
      'Management Information',
      'Principal of Taxation',
      'Business Law',
    ],
    CALevel.professional: [
      'Audit and Assurance',
      'Financial Accounting and Reporting',
      'Business Strategy and Technology',
      'Information Technology Governance',
      'Financial Management',
      'Business Planning: Taxation and Compliance',
      'Corporate Laws and Practices',
    ],
    CALevel.advance: [
      'Strategic Business Management',
      'Corporate Reporting',
      'Case Study',
    ],
  };

  static List<String> subjectsFor(String? level) {
    if (level == null) return const [];
    return byLevel[level] ?? const [];
  }
}

class FitnessLevel {
  static const beginner = 'Beginner';
  static const intermediate = 'Intermediate';
  static const advance = 'Advance';
  static const all = [beginner, intermediate, advance];
}

class WorkoutType {
  static const home = 'Home';
  static const gym = 'Gym';
  static const walking = 'Walking';
  static const bodyweight = 'Bodyweight';
  static const all = [home, gym, walking, bodyweight];
}

class OccupationType {
  static const student = 'Student';
  static const job = 'Job';
  static const both = 'Both';
  static const all = [student, job, both];
}

class Gender {
  static const male = 'Male';
  static const female = 'Female';
  static const other = 'Other';
  static const all = [male, female, other];
}
