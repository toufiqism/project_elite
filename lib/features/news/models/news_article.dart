class NewsArticle {
  final String title;
  final String? description;
  final String url;
  final String? urlToImage;
  final String sourceName;
  final DateTime publishedAt;

  const NewsArticle({
    required this.title,
    required this.url,
    required this.sourceName,
    required this.publishedAt,
    this.description,
    this.urlToImage,
  });

  factory NewsArticle.fromJson(Map<String, dynamic> json) => NewsArticle(
        title: (json['title'] as String?) ?? '',
        description: json['description'] as String?,
        url: (json['url'] as String?) ?? '',
        urlToImage: json['urlToImage'] as String?,
        sourceName:
            (json['source'] as Map?)?['name'] as String? ?? 'Unknown',
        publishedAt:
            DateTime.tryParse((json['publishedAt'] as String?) ?? '') ??
                DateTime.now(),
      );
}
