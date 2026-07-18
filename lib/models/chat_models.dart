import 'package:uuid/uuid.dart';

class ChatSession {
  final String id;
  final String title;
  final DateTime createdAt;
  final List<ChatMessage> messages;

  ChatSession({
    String? id,
    required this.title,
    DateTime? createdAt,
    List<ChatMessage>? messages,
  }) : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now(),
        messages = messages ?? [];

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'createdAt': createdAt.toIso8601String(),
    'messages': messages.map((m) => m.toJson()).toList(),
  };

  factory ChatSession.fromJson(Map<String, dynamic> json) => ChatSession(
    id: json['id'],
    title: json['title'],
    createdAt: DateTime.parse(json['createdAt']),
    messages: (json['messages'] as List)
        .map((m) => ChatMessage.fromJson(m))
        .toList(),
  );
}

class ChatMessage {
  final String id;
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final MessageType type;
  final List<ArticleInfo>? references;

  ChatMessage({
    String? id,
    required this.text,
    required this.isUser,
    DateTime? timestamp,
    this.type = MessageType.text,
    this.references,
  }) : id = id ?? const Uuid().v4(),
        timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toJson() => {
    'id': id,
    'text': text,
    'isUser': isUser,
    'timestamp': timestamp.toIso8601String(),
    'type': type.toString(),
    'references': references?.map((r) => r.toJson()).toList(),
  };

  factory ChatMessage.fromJson(Map<String, dynamic> json) => ChatMessage(
    id: json['id'],
    text: json['text'],
    isUser: json['isUser'],
    timestamp: DateTime.parse(json['timestamp']),
    type: MessageType.values.firstWhere(
          (e) => e.toString() == json['type'],
      orElse: () => MessageType.text,
    ),
    references: json['references'] != null
        ? (json['references'] as List)
        .map((r) => ArticleInfo.fromJson(r))
        .toList()
        : null,
  );
}

enum MessageType {
  text,       
  loading,    
  error,      
  welcome,    
}

class ArticleInfo {
  final String codeName;
  final String articleTitle;
  final String? sectionName;
  final String? chapterName;

  ArticleInfo({
    required this.codeName,
    required this.articleTitle,
    this.sectionName,
    this.chapterName,
  });

  Map<String, dynamic> toJson() => {
    'codeName': codeName,
    'articleTitle': articleTitle,
    'sectionName': sectionName,
    'chapterName': chapterName,
  };

  factory ArticleInfo.fromJson(Map<String, dynamic> json) => ArticleInfo(
    codeName: json['codeName'],
    articleTitle: json['articleTitle'],
    sectionName: json['sectionName'],
    chapterName: json['chapterName'],
  );
}