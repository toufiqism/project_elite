class Dua {
  final String id;
  final String category;
  final String title;
  final String arabic;
  final String transliteration;
  final String meaning;
  final String reference;

  const Dua({
    required this.id,
    required this.category,
    required this.title,
    required this.arabic,
    required this.transliteration,
    required this.meaning,
    required this.reference,
  });

  factory Dua.fromJson(Map<String, dynamic> json) => Dua(
        id: json['id'] as String,
        category: json['category'] as String,
        title: json['title'] as String,
        arabic: json['arabic'] as String,
        transliteration: json['transliteration'] as String,
        meaning: json['meaning'] as String,
        reference: (json['reference'] as String?) ?? '',
      );
}
