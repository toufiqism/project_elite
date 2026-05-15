/// One self-rating per day. Rating ranges 1..5.
class SocialRating {
  final DateTime date;
  final int rating;

  const SocialRating({required this.date, required this.rating});

  Map<String, dynamic> toJson() => {
        'date': date.toIso8601String(),
        'rating': rating,
      };

  factory SocialRating.fromJson(Map json) => SocialRating(
        date: DateTime.parse(json['date'] as String),
        rating: (json['rating'] as num).toInt(),
      );
}
