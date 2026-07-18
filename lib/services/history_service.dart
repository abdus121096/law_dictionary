import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class HistoryService {
  static final HistoryService _instance = HistoryService._internal();
  factory HistoryService() => _instance;
  HistoryService._internal();

  static const String _key = 'view_history';
  static const int _maxItems = 20;

  Future<void> addToHistory({
    required String articleTitle,
    required String codeName,
    required String chapterName,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final items = await getHistory();

    items.removeWhere((e) => e['articleTitle'] == articleTitle);

    items.insert(0, {
      'articleTitle': articleTitle,
      'codeName': codeName,
      'chapterName': chapterName,
      'viewedAt': DateTime.now().toIso8601String(),
    });

    if (items.length > _maxItems) {
      items.removeRange(_maxItems, items.length);
    }

    final encoded = items.map((e) => jsonEncode(e)).toList();
    await prefs.setStringList(_key, encoded);
  }

  Future<List<Map<String, String>>> getHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_key) ?? [];
    return raw.map((e) {
      final map = jsonDecode(e) as Map<String, dynamic>;
      return map.map((k, v) => MapEntry(k, v.toString()));
    }).toList();
  }

  Future<void> clearHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
