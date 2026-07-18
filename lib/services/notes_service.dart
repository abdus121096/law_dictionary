import 'package:shared_preferences/shared_preferences.dart';

class NotesService {
  static final NotesService _instance = NotesService._internal();
  factory NotesService() => _instance;
  NotesService._internal();

  static const String _prefix = 'note_';

  String _key(String articleTitle) =>
      '$_prefix${articleTitle.replaceAll(' ', '_')}';

  Future<String?> getNote(String articleTitle) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_key(articleTitle));
  }

  Future<void> saveNote(String articleTitle, String note) async {
    final prefs = await SharedPreferences.getInstance();
    if (note.trim().isEmpty) {
      await prefs.remove(_key(articleTitle));
    } else {
      await prefs.setString(_key(articleTitle), note.trim());
    }
  }

  Future<void> deleteNote(String articleTitle) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key(articleTitle));
  }
}
