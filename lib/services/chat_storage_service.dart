// lib/services/chat_storage_service.dart
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:law_dictionary/models/chat_models.dart';

class ChatStorageService {
  static final ChatStorageService _instance = ChatStorageService._internal();
  factory ChatStorageService() => _instance;
  ChatStorageService._internal();

  static const String _sessionsKey = 'chat_sessions';
  static const String _currentSessionKey = 'current_chat_session';

  Future<void> saveSession(ChatSession session) async {
    final prefs = await SharedPreferences.getInstance();

    final sessions = await getAllSessions();

    final existingIndex = sessions.indexWhere((s) => s.id == session.id);

    if (existingIndex != -1) {
      sessions[existingIndex] = session;
    } else {
      sessions.insert(0, session); 
    }

    if (sessions.length > 50) {
      sessions.removeRange(50, sessions.length);
    }

    final sessionsJson = sessions.map((s) => jsonEncode(s.toJson())).toList();
    await prefs.setStringList(_sessionsKey, sessionsJson);
  }

  Future<List<ChatSession>> getAllSessions() async {
    final prefs = await SharedPreferences.getInstance();
    final sessionsJson = prefs.getStringList(_sessionsKey) ?? [];

    return sessionsJson.map((json) {
      try {
        return ChatSession.fromJson(jsonDecode(json));
      } catch (e) {
        print('Error parsing session: $e');
        return null;
      }
    }).where((s) => s != null).cast<ChatSession>().toList();
  }

  Future<ChatSession?> getSessionById(String id) async {
    final sessions = await getAllSessions();
    try {
      return sessions.firstWhere((s) => s.id == id);
    } catch (e) {
      return null;
    }
  }

  Future<void> deleteSession(String id) async {
    final sessions = await getAllSessions();
    sessions.removeWhere((s) => s.id == id);

    final prefs = await SharedPreferences.getInstance();
    final sessionsJson = sessions.map((s) => jsonEncode(s.toJson())).toList();
    await prefs.setStringList(_sessionsKey, sessionsJson);
  }

  Future<void> clearAllSessions() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_sessionsKey);
    await prefs.remove(_currentSessionKey);
  }

  Future<void> saveCurrentSessionId(String id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_currentSessionKey, id);
  }

  Future<String?> getCurrentSessionId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_currentSessionKey);
  }

  Future<List<ChatSession>> searchSessions(String query) async {
    final sessions = await getAllSessions();
    final queryLower = query.toLowerCase();

    return sessions.where((session) {
      if (session.title.toLowerCase().contains(queryLower)) {
        return true;
      }

      return session.messages.any((message) =>
          message.text.toLowerCase().contains(queryLower)
      );
    }).toList();
  }

  Future<Map<String, dynamic>> getStatistics() async {
    final sessions = await getAllSessions();

    int totalMessages = 0;
    int userMessages = 0;
    int aiMessages = 0;

    for (var session in sessions) {
      totalMessages += session.messages.length;
      userMessages += session.messages.where((m) => m.isUser).length;
      aiMessages += session.messages.where((m) => !m.isUser).length;
    }

    return {
      'totalSessions': sessions.length,
      'totalMessages': totalMessages,
      'userMessages': userMessages,
      'aiMessages': aiMessages,
      'averageMessagesPerSession': sessions.isEmpty ? 0 : totalMessages ~/ sessions.length,
    };
  }
}