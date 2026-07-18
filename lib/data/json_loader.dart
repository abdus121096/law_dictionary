import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:law_dictionary/models/law_code_model.dart';

class JsonLoader {
  static const Map<String, List<String>> _files = {
    'ru': [
      'assets/json/admin.json',
      'assets/json/criminal_code.json',
      'assets/json/nalog.json',
      'assets/json/narushenie.json',
      'assets/json/trudovoi.json',
    ],
    'ky': [
      
    ],
  };

  Future<List<LawCode>> loadLawCodes({String language = 'ru'}) async {
    final files = _files[language] ?? _files['ru']!;

    final filesToLoad = files.isNotEmpty ? files : _files['ru']!;

    List<LawCode> lawCodes = [];
    for (var file in filesToLoad) {
      String jsonString = await rootBundle.loadString(file);
      Map<String, dynamic> jsonMap = json.decode(jsonString);
      lawCodes.add(LawCode.fromJson(jsonMap));
    }

    return lawCodes;
  }
}