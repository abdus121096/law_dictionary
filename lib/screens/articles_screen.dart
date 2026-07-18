

import 'package:flutter/material.dart';
import 'package:law_dictionary/models/law_code_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:share_plus/share_plus.dart';

import 'chat_screen.dart';

class ArticleScreen extends StatefulWidget {
  final Chapter chapter;
  final Article article;
  final String codeName;

  const ArticleScreen(
      {super.key, required this.chapter, required this.article, required this.codeName});

  @override
  State<ArticleScreen> createState() => _ArticleScreenState();
}

class _ArticleScreenState extends State<ArticleScreen> {
  List<String> favoriteArticles = [];
  bool showCustomSnackbar = false;
  String snackBarMessage = '';
  double _fontSize = 16;

  @override
  void initState() {
    super.initState();
    _loadFavorites();
    _loadFontSize();
  }

  Future<void> _loadFontSize() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    if (mounted) setState(() => _fontSize = prefs.getDouble('fontSize') ?? 16);
  }

  Future<void> _loadFavorites() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      favoriteArticles = prefs.getStringList('favorites') ?? [];
    });
  }

  Future<void> _toggleFavorites(String articleTitle) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    if (favoriteArticles.contains(articleTitle)) {
      favoriteArticles.remove(articleTitle);
      _showCustomSnackbar('Удалено из избранного');
    } else {
      favoriteArticles.add(articleTitle);
      _showCustomSnackbar('Добавлено в избранное');
    }
    await prefs.setStringList('favorites', favoriteArticles);
  }

  void _showCustomSnackbar(String message) {
    setState(() {
      snackBarMessage = message;
      showCustomSnackbar = true;
    });

    Future.delayed(const Duration(seconds: 2), () {
      setState(() {
        showCustomSnackbar = false;
      });
    });
  }

  bool _isFavorite(String articleTitle) {
    return favoriteArticles.contains(articleTitle);
  }

  void _showBottomSheet(BuildContext context, String title, String content) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.9,
          maxChildSize: 0.9,
          builder: (context, scrollController) {
            return StatefulBuilder(
              builder:
                  (BuildContext context, StateSetter setStateInBottomSheet) {
                return Stack(
                  children: [
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Text(
                            title,
                            style: TextStyle(
                              fontSize: _fontSize + 2,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Expanded(
                          child: SingleChildScrollView(
                            controller: scrollController,
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Text(
                                content,
                                style: TextStyle(fontSize: _fontSize, height: 1.5),
                              ),
                            ),
                          ),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.share),
                              onPressed: () {
                                String contentToShare =
                                    "${widget.article.title}\n\n${widget.article.content.join('\n\n')}";
                                Share.share(contentToShare,
                                    subject: widget.article.title);
                              },
                            ),
                            IconButton(
                              icon: Icon(
                                _isFavorite(title)
                                    ? Icons.star
                                    : Icons.star_border,
                                color: _isFavorite(title)
                                    ? Colors.yellow
                                    : Colors.grey,
                              ),
                              onPressed: () {
                                _toggleFavorites(title);
                                setStateInBottomSheet(() {});
                              },
                            ),
                            IconButton(
                              onPressed: () {
                                Navigator.pop(context); 
                              },
                              icon: const Icon(Icons.close),
                            ),
                            IconButton(
                              icon: Icon(Icons.question_answer, color: Colors.blue[700]),
                              onPressed: () {
                                Navigator.pop(context);
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => ChatScreen(
                                      relatedArticle: widget.article,
                                      articleCodeName: widget.codeName,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 20)
                      ],
                    ),
                    if (showCustomSnackbar)
                      Positioned(
                        bottom: 85,
                        left: 10,
                        right: 10,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              vertical: 12, horizontal: 16),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.8),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            snackBarMessage,
                            style: const TextStyle(
                              color: Colors.white,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        forceMaterialTransparency: true,
        title: Text(widget.chapter.name),
      ),
      body: ListView.builder(
        itemCount: widget.chapter.articles.length,
        itemBuilder: (context, index) {
          final title = widget.chapter.articles[index].title;
          final content = widget.chapter.articles[index].content.join('\n\n');
          return Column(
            children: [
              ListTile(
                title: Text(widget.chapter.articles[index].title),
                onTap: () {
                  _showBottomSheet(context, title, content);
                },
              ),
              const Divider(
                thickness: 1,
                height: 1,
                indent: 13,
                endIndent: 13,
              ),
            ],
          );
        },
      ),
    );
  }
}
