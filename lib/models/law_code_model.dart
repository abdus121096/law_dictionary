class Article {
  final String title;
  final List<String> content;

  Article({required this.title, required this.content});

  factory Article.fromJson(Map<String, dynamic> json) {
    return Article(
      title: json['article_title'] as String,
      content: List<String>.from(json['content']),
    );
  }
}

class Chapter {
  final String name;
  final List<Article> articles;

  Chapter({required this.name, required this.articles});

  factory Chapter.fromJson(Map<String, dynamic> json) {
    return Chapter(
      name: json['chapter_name'] as String,
      articles: (json['articles'] as List)
          .map((article) => Article.fromJson(article))
          .toList(),
    );
  }
}

class Section {
  final String name;
  final List<Chapter> chapters;

  Section({required this.name, required this.chapters});

  factory Section.fromJson(Map<String, dynamic> json) {
    return Section(
      name: json['section_name'] as String,
      chapters: (json['chapters'] as List)
          .map((chapter) => Chapter.fromJson(chapter))
          .toList(),
    );
  }
}

class LawCode {
  final String name;
  final List<Section> sections;

  LawCode({required this.name, required this.sections});

  factory LawCode.fromJson(Map<String, dynamic> json) {
    return LawCode(
      name: json['code_name'] as String,
      sections: (json['sections'] as List)
          .map((section) => Section.fromJson(section))
          .toList(),
    );
  }
}