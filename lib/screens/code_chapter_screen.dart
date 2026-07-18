import 'package:flutter/material.dart';
import 'package:law_dictionary/models/law_code_model.dart';
import 'article_content_screen.dart';
import 'articles_screen.dart';

class ChapterScreen extends StatefulWidget {
  final LawCode lawCode;

  const ChapterScreen({super.key, required this.lawCode});

  @override
  _ChapterScreenState createState() => _ChapterScreenState();
}

class _ChapterScreenState extends State<ChapterScreen> {
  TextEditingController searchController = TextEditingController();
  List<Article> filteredArticles = [];
  bool isSearching = false;

  @override
  void initState() {
    super.initState();
    searchController.addListener(_filterArticles);
  }

  void _filterArticles() {
    String query = searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        filteredArticles = [];
      } else {
        isSearching = true;
        filteredArticles = [];
        for (var section in widget.lawCode.sections) {
          for (var chapter in section.chapters) {
            for (var article in chapter.articles) {
              if (article.title.toLowerCase().contains(query) ||
                  article.content.any(
                      (paragraph) => paragraph.toLowerCase().contains(query))) {
                filteredArticles.add(article);
              }
            }
          }
        }
      }
    });
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  void _toggleSearch() {
    setState(() {
      isSearching = !isSearching;
      if (!isSearching) {
        searchController.clear();
        filteredArticles.clear();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        forceMaterialTransparency: true,
        title: isSearching
            ? TextField(
                controller: searchController,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Поиск статей',
                  border: InputBorder.none,
                ),
                style: TextStyle(
                    color: Theme.of(context).textTheme.bodyLarge?.color),
              )
            : Text(widget.lawCode.name),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: _toggleSearch,
            icon: Icon(isSearching ? Icons.clear : Icons.search),
          ),
        ],
      ),
      body: isSearching
          ? searchController.text.isEmpty
              ? const Center(
                  child: Text(
                    'Введите запрос для поиска',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                )
              : filteredArticles.isEmpty
                  ? const Center(
                      child: Text(
                        'Ничего не найдено',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    )
                  : ListView.builder(
                      itemCount: filteredArticles.length,
                      itemBuilder: (context, index) {
                        final article = filteredArticles[index];
                        return ListTile(
                          title: _highlightText(
                            article.title,
                            searchController.text,
                            Theme.of(context).textTheme.bodyLarge,
                          ),
                          onTap: () {
                            var chapter = _findChapterByArticle(article);
                            if (chapter != null) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ArticleContentScreen(
                                    article: article,
                                    codeName: widget.lawCode.name,
                                    chapterName: chapter.name,
                                  ),
                                ),
                              );
                            }
                          },
                        );
                      },
                    )
          : ListView.builder(
              itemCount: widget.lawCode.sections.length,
              itemBuilder: (context, sectionIndex) {
                final section = widget.lawCode.sections[sectionIndex];
                return Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            section.name,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Column(
                            children: section.chapters.map((chapter) {
                              return Column(
                                children: [
                                  const Divider(
                                    thickness: 1,
                                    height: 1,
                                    indent: 13,
                                    endIndent: 13,
                                  ),
                                  ListTile(
                                    title: Text(chapter.name),
                                    onTap: chapter.articles.isEmpty
                                        ? null
                                        : () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) =>
                                                    ArticleScreen(
                                                  chapter: chapter,
                                                  article:
                                                      chapter.articles.first,
                                                  codeName: widget.lawCode.name,
                                                ),
                                              ),
                                            );
                                          },
                                  ),
                                ],
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }

  Widget _highlightText(String text, String query, TextStyle? baseStyle) {
    if (query.isEmpty) return Text(text, style: baseStyle);
    final lowerText = text.toLowerCase();
    final lowerQuery = query.toLowerCase();
    final spans = <TextSpan>[];
    int start = 0;
    int index;
    while ((index = lowerText.indexOf(lowerQuery, start)) != -1) {
      if (index > start) {
        spans.add(
            TextSpan(text: text.substring(start, index), style: baseStyle));
      }
      spans.add(TextSpan(
        text: text.substring(index, index + query.length),
        style: (baseStyle ?? const TextStyle()).copyWith(
          color: Colors.blue,
          fontWeight: FontWeight.bold,
        ),
      ));
      start = index + query.length;
    }
    if (start < text.length) {
      spans.add(TextSpan(text: text.substring(start), style: baseStyle));
    }
    return RichText(text: TextSpan(children: spans));
  }

  Chapter? _findChapterByArticle(Article article) {
    for (var section in widget.lawCode.sections) {
      for (var chapter in section.chapters) {
        if (chapter.articles.contains(article)) {
          return chapter;
        }
      }
    }
    return null;
  }
}
