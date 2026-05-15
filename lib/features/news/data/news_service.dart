import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/config/api_keys.dart';
import '../models/news_article.dart';

class NewsService {
  static const _base = 'https://newsapi.org/v2';
  static const _intlSources = 'bbc-news,reuters,cnn,al-jazeera-english';

  static Future<List<NewsArticle>> fetchLocal(String countryCode) async {
    final uri = Uri.parse('$_base/top-headlines').replace(
      queryParameters: {
        'country': countryCode.toLowerCase(),
        'pageSize': '30',
        'apiKey': kNewsApiKey,
      },
    );
    return _fetch(uri);
  }

  static Future<List<NewsArticle>> fetchInternational() async {
    final uri = Uri.parse('$_base/top-headlines').replace(
      queryParameters: {
        'sources': _intlSources,
        'pageSize': '30',
        'apiKey': kNewsApiKey,
      },
    );
    return _fetch(uri);
  }

  static Future<List<NewsArticle>> _fetch(Uri uri) async {
    final res = await http.get(uri).timeout(const Duration(seconds: 12));
    if (res.statusCode != 200) {
      throw Exception('NewsAPI returned ${res.statusCode}');
    }
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    if ((body['status'] as String?) != 'ok') {
      throw Exception(body['message'] ?? 'NewsAPI error');
    }
    return (body['articles'] as List)
        .cast<Map<String, dynamic>>()
        .map(NewsArticle.fromJson)
        .where((a) =>
            a.title.isNotEmpty &&
            a.url.isNotEmpty &&
            a.title != '[Removed]')
        .toList();
  }
}
