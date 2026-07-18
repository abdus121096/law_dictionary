// lib/services/ai_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:law_dictionary/models/law_code_model.dart';
import 'package:law_dictionary/data/json_loader.dart';

class AIService {
  static final AIService _instance = AIService._internal();
  factory AIService() => _instance;
  AIService._internal();

  final String _apiKey = dotenv.env['ANTHROPIC_API_KEY'] ?? '';
  List<LawCode>? _cachedLawCodes;

  Future<List<LawCode>> _getLawCodes() async {
    _cachedLawCodes ??= await JsonLoader().loadLawCodes();
    return _cachedLawCodes!;
  }

  Future<List<Map<String, dynamic>>> searchRelevantArticles(String query) async {
    final lawCodes = await _getLawCodes();
    List<Map<String, dynamic>> results = [];

    final keywords = query.toLowerCase().split(' ')
        .where((word) => word.length > 3)
        .toList();

    for (var code in lawCodes) {
      for (var section in code.sections) {
        for (var chapter in section.chapters) {
          for (var article in chapter.articles) {
            int relevanceScore = 0;

            final titleLower = article.title.toLowerCase();
            for (var keyword in keywords) {
              if (titleLower.contains(keyword)) relevanceScore += 3;
            }

            final contentLower = article.content.join(' ').toLowerCase();
            for (var keyword in keywords) {
              if (contentLower.contains(keyword)) relevanceScore += 1;
            }

            if (relevanceScore > 0) {
              results.add({
                'article': article,
                'codeName': code.name,
                'sectionName': section.name,
                'chapterName': chapter.name,
                'relevanceScore': relevanceScore,
              });
            }
          }
        }
      }
    }

    results.sort((a, b) => b['relevanceScore'].compareTo(a['relevanceScore']));
    return results.take(5).toList();
  }

  Future<AIResponse> getAIResponse({
    required String question,
    Article? relatedArticle,
  }) async {
    try {
      final relevantArticles = await searchRelevantArticles(question);
      String context = _buildContext(relevantArticles, relatedArticle);

      final response = await http.post(
        Uri.parse('https://api.anthropic.com/v1/messages'),
        headers: {
          'x-api-key': _apiKey,
          'anthropic-version': '2023-06-01',
          'content-type': 'application/json',
        },
        body: jsonEncode({
          'model': 'claude-haiku-4-5-20251001',
          'max_tokens': 1024,
          'system': '''Ты опытный юридический консультант по законодательству Кыргызской Республики.

ВАЖНЫЕ ПРАВИЛА:
1. Всегда ссылайся на конкретные статьи кодексов КР
2. Объясняй простым и понятным языком
3. Давай практические рекомендации
4. Предупреждай о возможных рисках и последствиях
5. Если вопрос сложный, рекомендуй консультацию с юристом
6. Не давай заведомо ложную информацию
7. Если не уверен, так и скажи

Контекст из кодексов КР:
$context''',
          'messages': [
            {'role': 'user', 'content': question}
          ],
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final answer = data['content'][0]['text'];

        return AIResponse(
          text: answer,
          isSuccess: true,
          references: relevantArticles.map((item) {
            final article = item['article'] as Article;
            return ArticleReference(
              codeName: item['codeName'],
              sectionName: item['sectionName'],
              chapterName: item['chapterName'],
              articleTitle: article.title,
            );
          }).toList(),
        );
      } else {
        throw Exception('API Error: ${response.statusCode} ${response.body}');
      }
    } catch (e) {
      return AIResponse(
        text: _getErrorMessage(e),
        isSuccess: false,
        references: [],
      );
    }
  }

  String _buildContext(List<Map<String, dynamic>> relevantArticles, Article? specificArticle) {
    String context = '';

    if (specificArticle != null) {
      context += 'СТАТЬЯ ПО КОТОРОЙ ЗАДАН ВОПРОС:\n';
      context += '${specificArticle.title}\n';
      context += '${specificArticle.content.take(3).join('\n')}\n\n';
    }

    if (relevantArticles.isNotEmpty) {
      context += 'РЕЛЕВАНТНЫЕ СТАТЬИ ИЗ КОДЕКСОВ:\n\n';
      for (var item in relevantArticles.take(3)) {
        final article = item['article'] as Article;
        context += 'Кодекс: ${item['codeName']}\n';
        context += 'Статья: ${article.title}\n';
        context += 'Содержание: ${article.content.take(2).join(' ')}\n\n';
      }
    }

    if (context.isEmpty) {
      context = 'Конкретные статьи не найдены. Используй общие знания о законодательстве КР.';
    }

    return context;
  }

  String _getErrorMessage(dynamic error) {
    final msg = error.toString();
    if (msg.contains('401') || msg.contains('403')) {
      return 'Ошибка авторизации. Проверьте API ключ.';
    } else if (msg.contains('529') || msg.contains('overloaded')) {
      return 'Сервер временно перегружен. Попробуйте через несколько секунд.';
    } else if (msg.contains('insufficient_quota') || msg.contains('429') || msg.contains('credit')) {
      return 'Исчерпан лимит запросов. Пополните баланс на console.anthropic.com.';
    } else if (msg.contains('SocketException') || msg.contains('connection')) {
      return 'Нет подключения к интернету. Проверьте соединение и попробуйте снова.';
    }
    return 'Произошла ошибка при обработке запроса. Попробуйте позже.';
  }

  List<String> getExampleQuestions() {
    return [
      'Как оформить развод?',
      'Порядок наследования имущества?',
      'Как взыскать долг?',
      'Права потребителя при возврате товара?',
      'Какое наказание за кражу?',
      'Как правильно уволить сотрудника?',
      'Штраф за нарушение ПДД?',
    ];
  }
}

class AIResponse {
  final String text;
  final bool isSuccess;
  final List<ArticleReference> references;

  AIResponse({
    required this.text,
    required this.isSuccess,
    required this.references,
  });
}

class ArticleReference {
  final String codeName;
  final String sectionName;
  final String chapterName;
  final String articleTitle;

  ArticleReference({
    required this.codeName,
    required this.sectionName,
    required this.chapterName,
    required this.articleTitle,
  });

  Map<String, dynamic> toJson() => {
    'codeName': codeName,
    'sectionName': sectionName,
    'chapterName': chapterName,
    'articleTitle': articleTitle,
  };

  factory ArticleReference.fromJson(Map<String, dynamic> json) =>
      ArticleReference(
        codeName: json['codeName'],
        sectionName: json['sectionName'],
        chapterName: json['chapterName'],
        articleTitle: json['articleTitle'],
      );
}
