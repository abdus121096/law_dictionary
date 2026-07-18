import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:law_dictionary/models/law_code_model.dart';
import 'package:law_dictionary/data/json_loader.dart';

class AIService {
  static final AIService _instance = AIService._internal();
  factory AIService() => _instance;
  AIService._internal();

  final String _apiKey = '';
  List<LawCode>? _cachedLawCodes;

 
  bool isLegalQuestion(String question) {
    final q = question.toLowerCase();

    final legalKeywords = [
      'закон', 'право', 'статья', 'кодекс', 'юридический', 'юрист',
      'суд', 'иск', 'ответственность', 'наказание', 'штраф',

      'преступление', 'уголовный', 'кража', 'мошенничество', 'убийство',
      'грабеж', 'разбой', 'наркотики', 'взятка', 'коррупция',

      'договор', 'сделка', 'купля', 'продажа', 'аренда', 'наследство',
      'собственность', 'имущество', 'долг', 'кредит', 'займ',

      'брак', 'развод', 'алименты', 'опека', 'усыновление', 'дети',

      'работа', 'увольнение', 'зарплата', 'отпуск', 'больничный',
      'трудовой', 'работодатель', 'сотрудник', 'контракт',

      'административный', 'правонарушение', 'пдд', 'гибдд', 'протокол',

      'налог', 'ндс', 'подоходный', 'декларация', 'налоговая',

      'подать', 'жалоба', 'заявление', 'обжаловать', 'апелляция',
      'документы', 'справка', 'нотариус', 'доверенность',

      'как оформить', 'что делать если', 'какое наказание',
      'какой штраф', 'имею ли право', 'могу ли я', 'законно ли',
      'что грозит', 'куда обратиться', 'какие документы'
    ];

    for (String keyword in legalKeywords) {
      if (q.contains(keyword)) {
        return true;
      }
    }

    if (q.contains('прав') || q.contains('обязан') || q.contains('можно') ||
        q.contains('нельзя') || q.contains('разрешено') || q.contains('запрещено')) {
      return true;
    }

    return false;
  }

  bool isInappropriateQuestion(String question) {
    final q = question.toLowerCase();

    final inappropriateTopics = [
      'лечение', 'лекарство', 'болезнь', 'симптом', 'диагноз',

      'инвестиции', 'акции', 'биткоин', 'криптовалюта', 'форекс',

      'люблю', 'отношения', 'психология', 'депрессия',

      'программирование', 'компьютер', 'windows', 'android',

      'решить задачу', 'написать сочинение', 'математика', 'физика'
    ];

    for (String topic in inappropriateTopics) {
      if (q.contains(topic) && !q.contains('договор') && !q.contains('право')) {
        return true;
      }
    }

    return false;
  }

  Future<AIResponse> getAIResponse({
    required String question,
    String? category,
    Article? relatedArticle,
  }) async {
    if (!isLegalQuestion(question)) {
      return AIResponse(
        text: '''Извините, я могу помочь только с юридическими вопросами по законодательству Кыргызской Республики.

Я могу ответить на вопросы о:
• Уголовном праве (преступления, наказания)
• Гражданском праве (договоры, собственность, наследство)
• Семейном праве (брак, развод, алименты)
• Трудовом праве (увольнение, отпуск, зарплата)
• Административном праве (штрафы, нарушения)
• Налоговом праве

Пожалуйста, задайте вопрос, связанный с правовыми вопросами.''',
        isSuccess: false,
        references: [],
      );
    }

    if (isInappropriateQuestion(question)) {
      return AIResponse(
        text: 'Я специализируюсь только на юридических консультациях по законодательству КР. Для вопросов по медицине, психологии, инвестициям и другим темам, пожалуйста, обратитесь к соответствующим специалистам.',
        isSuccess: false,
        references: [],
      );
    }

    try {
      final relevantArticles = await searchRelevantArticles(question);
      String context = _buildContext(relevantArticles, relatedArticle);
      String detectedCategory = category ?? _detectCategory(question);
      final response = await http.post(
        Uri.parse('https://api.openai.com/v1/chat/completions'),
        headers: {
          'Authorization': 'Bearer $_apiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'model': 'gpt-3.5-turbo',
          'messages': [
            {
              'role': 'system',
              'content': '''Ты юридический консультант ТОЛЬКО по законодательству Кыргызской Республики.

СТРОГИЕ ПРАВИЛА:
1. Отвечай ТОЛЬКО на юридические вопросы
2. Если вопрос не касается права - вежливо откажи и предложи задать юридический вопрос
3. НЕ давай советов по: медицине, психологии, финансам (кроме юридических аспектов), личным отношениям, техническим вопросам
4. Всегда ссылайся на конкретные статьи кодексов КР
5. Если вопрос о другой стране - объясни, что консультируешь только по праву КР
6. НЕ помогай в незаконной деятельности
7. При сомнениях рекомендуй обратиться к юристу лично

Категория вопроса: $detectedCategory

Контекст из кодексов КР:
$context

ВАЖНО: Если вопрос не юридический, ответь: "Я могу помочь только с юридическими вопросами по законодательству КР. Пожалуйста, задайте вопрос о праве."'''
            },
            {
              'role': 'user',
              'content': question
            }
          ],
          'temperature': 0.7,
          'max_tokens': 1000,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final answer = data['choices'][0]['message']['content'];

        if (_isResponseAppropriate(answer)) {
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
          return AIResponse(
            text: 'Извините, я могу консультировать только по юридическим вопросам законодательства Кыргызской Республики.',
            isSuccess: false,
            references: [],
          );
        }
      } else {
        throw Exception('API Error: ${response.statusCode}');
      }
    } catch (e) {
      print('Error in getAIResponse: $e');
      return AIResponse(
        text: _getErrorMessage(e),
        isSuccess: false,
        references: [],
      );
    }
  }

  bool _isResponseAppropriate(String response) {
    final r = response.toLowerCase();

    if (r.contains('не могу помочь') && r.contains('юридическ')) {
      return true;
    }
    final legalTerms = ['статья', 'кодекс', 'закон', 'право', 'ответственность'];
    int legalTermCount = 0;

    for (String term in legalTerms) {
      if (r.contains(term)) {
        legalTermCount++;
      }
    }
    return legalTermCount >= 1;
  }

  Future<List<LawCode>> _getLawCodes() async {
    _cachedLawCodes ??= await JsonLoader().loadLawCodes();
    return _cachedLawCodes!;
  }

  Future<List<Map<String, dynamic>>> searchRelevantArticles(String query) async {
    if (!isLegalQuestion(query)) {
      return [];
    }

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
              if (titleLower.contains(keyword)) {
                relevanceScore += 3;
              }
            }
            final contentLower = article.content.join(' ').toLowerCase();
            for (var keyword in keywords) {
              if (contentLower.contains(keyword)) {
                relevanceScore += 1;
              }
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
        final codeName = item['codeName'];

        context += 'Кодекс: $codeName\n';
        context += 'Статья: ${article.title}\n';
        context += 'Содержание: ${article.content.take(2).join(' ')}\n\n';
      }
    }

    if (context.isEmpty) {
      context = 'Конкретные статьи не найдены. Используй общие знания о законодательстве КР.';
    }

    return context;
  }

  String _detectCategory(String question) {
    final q = question.toLowerCase();

    if (q.contains('налог') || q.contains('ндс') || q.contains('подоход')) {
      return 'Налоговый кодекс';
    } else if (q.contains('уголов') || q.contains('преступ') || q.contains('наказан') ||
        q.contains('кража') || q.contains('мошенн') || q.contains('убий')) {
      return 'Уголовный кодекс';
    } else if (q.contains('труд') || q.contains('работ') || q.contains('увольн') ||
        q.contains('зарплат') || q.contains('отпуск')) {
      return 'Трудовой кодекс';
    } else if (q.contains('админ') || q.contains('штраф') || q.contains('наруш') ||
        q.contains('пдд')) {
      return 'Административный кодекс';
    } else if (q.contains('брак') || q.contains('развод') || q.contains('алимент') ||
        q.contains('семей') || q.contains('ребен') || q.contains('дет')) {
      return 'Семейное право';
    } else if (q.contains('договор') || q.contains('сделк') || q.contains('купл') ||
        q.contains('прода') || q.contains('аренд') || q.contains('наслед')) {
      return 'Гражданское право';
    }

    return 'Общие вопросы права';
  }

  String _getErrorMessage(dynamic error) {
    if (error.toString().contains('API')) {
      return 'Ошибка подключения к AI сервису. Проверьте интернет-соединение и попробуйте позже.';
    } else if (error.toString().contains('key')) {
      return 'Ошибка авторизации. Обратитесь к разработчику приложения.';
    } else {
      return 'Произошла ошибка при обработке запроса. Попробуйте переформулировать вопрос или обратитесь позже.';
    }
  }

  List<String> getExampleQuestions(String? category) {
    Map<String, List<String>> examples = {
      'Уголовный кодекс': [
        'Какое наказание за кражу до 10000 сом?',
        'Что считается мошенничеством по УК КР?',
        'Каков срок давности по уголовным делам?',
        'Что грозит за причинение легкого вреда здоровью?',
      ],
      'Налоговый кодекс': [
        'Как рассчитать подоходный налог в КР?',
        'Какие налоговые льготы для ИП?',
        'Какие штрафы за неуплату налогов?',
        'Как оформить патент на торговлю?',
      ],
      'Трудовой кодекс': [
        'Как правильно уволить сотрудника по ТК КР?',
        'Какие права при сокращении штата?',
        'Как оплачивается больничный лист?',
        'Сколько дней отпуска положено по закону?',
      ],
      'Административный': [
        'Какой штраф за превышение скорости?',
        'Что делать при ДТП по закону КР?',
        'Как обжаловать штраф ГИБДД?',
        'Какая ответственность за шум после 23:00?',
      ],
      'default': [
        'Как оформить развод в КР?',
        'Порядок вступления в наследство?',
        'Как взыскать долг через суд?',
        'Какие документы для регистрации ИП?',
      ],
    };

    return examples[category] ?? examples['default']!;
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