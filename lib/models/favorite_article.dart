class FavoriteArticle {
  final String codeName;
  final String articleTitle;
  final String content;

  FavoriteArticle({
    required this.codeName,
    required this.articleTitle,
    required this.content,
  });

  
  Map<String, dynamic> toMap() {
    return {
      'codeName': codeName,
      'articleTitle': articleTitle,
      'content': content,
    };
  }

  
  factory FavoriteArticle.fromMap(Map<String, dynamic> map) {
    return FavoriteArticle(
      codeName: map['codeName'],
      articleTitle: map['articleTitle'],
      content: map['content'],
    );
  }
}