import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:law_dictionary/data/json_loader.dart';
import '../models/law_code_model.dart'; // Модель статьи

class FavoriteScreen extends StatefulWidget {
  final bool isActive;

  const FavoriteScreen({super.key, required this.isActive});

  @override
  State<FavoriteScreen> createState() => _FavoriteScreenState();
}

class _FavoriteScreenState extends State<FavoriteScreen> {
  List<String> favorites = [];
  List<LawCode> lawCodes = [];

  @override
  void initState() {
    super.initState();
    _loadFavorites();
    _loadLawCodes();
  }

  @override
  void didUpdateWidget(FavoriteScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.isActive && widget.isActive) {
      _loadFavorites();
    }
  }

  Future<void> _loadFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      favorites = prefs.getStringList('favorites') ?? [];
    });
  }

  Future<void> _loadLawCodes() async {
    final loadedLawCodes = await JsonLoader().loadLawCodes();
    if (!mounted) return;
    setState(() {
      lawCodes = loadedLawCodes;
    });
  }

  
  Map<String, List<Article>> _groupFavoritesByCode() {
    Map<String, List<Article>> groupedFavorites = {};

    for (var favorite in favorites) {
      var articleData = _getArticleByTitle(favorite);
      if (articleData != null) {
        final article = articleData['article'] as Article;
        final codeName = articleData['codeName'] as String;

        if (!groupedFavorites.containsKey(codeName)) {
          groupedFavorites[codeName] = [];
        }
        groupedFavorites[codeName]!.add(article);
      }
    }
    return groupedFavorites;
  }

  Map<String, dynamic>? _getArticleByTitle(String title) {
    for (var lawCode in lawCodes) {
      for (var section in lawCode.sections) {
        for (var chapter in section.chapters) {
          for (var article in chapter.articles) {
            if (article.title == title) {
              return {'article': article, 'codeName': lawCode.name};
            }
          }
        }
      }
    }
    return null; 
  }

  Future<void> _removeFromFavorites(String articleTitle) async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      favorites.remove(articleTitle);
      prefs.setStringList('favorites', favorites);
    });
  }

  void _clearAllFavorites() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Очистить избранное?'),
        content: const Text('Все сохранённые статьи будут удалены.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final prefs = await SharedPreferences.getInstance();
              setState(() {
                favorites.clear();
                prefs.remove('favorites');
              });
            },
            child: const Text('Очистить', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showBottomSheet(BuildContext context, String title, String content) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.9,
          maxChildSize: 0.9,
          builder: (context, scrollController) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    title,  
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    controller: scrollController,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(content),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      IconButton(
                        onPressed: () {
                          String contentToShare = "$title\n\n$content";
                          Share.share(contentToShare, subject: title);
                        },
                        icon: const Icon(Icons.share),
                      ),
                      IconButton(
                        onPressed: () {
                          Navigator.pop(context); 
                        },
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                )
              ],
            );
          },
        );
      },
      isScrollControlled: true, 
    );
  }

  @override
  Widget build(BuildContext context) {
    final groupedFavorites = _groupFavoritesByCode(); 

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        forceMaterialTransparency: true,
        title: const Text('Избранное'),
        actions: [
          if (groupedFavorites.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep),
              tooltip: 'Очистить избранное',
              onPressed: _clearAllFavorites,
            ),
        ],
      ),
      body: groupedFavorites.isEmpty
          ? const Center(child: Text('Нет избранных статей'))
          : ListView.builder(
        itemCount: groupedFavorites.length,
        itemBuilder: (context, index) {
          String codeName = groupedFavorites.keys.elementAt(index);
          List<Article> articles = groupedFavorites[codeName]!;

          return Card(
            margin: const EdgeInsets.all(10.0),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 10.0),
                    child: Text(
                      codeName, 
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 10),
                  ...articles.map((article) {
                    return Column(
                      children: [
                        ListTile(
                          title: Text(article.title),
                          onTap: () {
                            _showBottomSheet(
                              context,
                              article.title,
                              article.content.join('\n\n'),
                            );
                          },
                          trailing: IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () {
                              _removeFromFavorites(article.title);
                            },
                          ),
                        ),
                        const Divider(
                          thickness: 1,
                          height: 1,
                          indent: 13,
                          endIndent: 13,
                        ),
                      ],
                    );
                  }).toList(),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}