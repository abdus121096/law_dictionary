import 'package:flutter/material.dart';
import 'package:law_dictionary/data/json_loader.dart';
import 'package:law_dictionary/models/law_code_model.dart';
import 'package:law_dictionary/services/history_service.dart';
import 'article_content_screen.dart';

class GlobalSearchScreen extends StatefulWidget {
  final String language;

  const GlobalSearchScreen({super.key, this.language = 'ru'});

  @override
  State<GlobalSearchScreen> createState() => _GlobalSearchScreenState();
}

class _GlobalSearchScreenState extends State<GlobalSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final HistoryService _historyService = HistoryService();

  List<LawCode> _lawCodes = [];
  List<_SearchResult> _results = [];
  List<Map<String, String>> _history = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
    _searchController.addListener(_onSearch);
  }

  Future<void> _loadData() async {
    final codes = await JsonLoader().loadLawCodes(language: widget.language);
    final history = await _historyService.getHistory();
    setState(() {
      _lawCodes = codes;
      _history = history;
      _isLoading = false;
    });
  }

  Future<void> _refreshHistory() async {
    final history = await _historyService.getHistory();
    setState(() => _history = history);
  }

  void _onSearch() {
    final query = _searchController.text.toLowerCase().trim();
    if (query.isEmpty) {
      setState(() => _results = []);
      return;
    }

    final results = <_SearchResult>[];
    for (var code in _lawCodes) {
      for (var section in code.sections) {
        for (var chapter in section.chapters) {
          for (var article in chapter.articles) {
            final titleMatch = article.title.toLowerCase().contains(query);
            final contentMatch = article.content.any((p) => p.toLowerCase().contains(query));
            if (titleMatch || contentMatch) {
              results.add(_SearchResult(
                article: article,
                codeName: code.name,
                chapterName: chapter.name,
                titleMatch: titleMatch,
              ));
            }
          }
        }
      }
    }

    results.sort((a, b) => (b.titleMatch ? 1 : 0).compareTo(a.titleMatch ? 1 : 0));
    setState(() => _results = results);
  }

  void _openArticle(Article article, String codeName, String chapterName) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ArticleContentScreen(
          article: article,
          codeName: codeName,
          chapterName: chapterName,
        ),
      ),
    ).then((_) => _refreshHistory());
  }

  Article? _findArticleByTitle(String title) {
    for (var code in _lawCodes) {
      for (var section in code.sections) {
        for (var chapter in section.chapters) {
          for (var article in chapter.articles) {
            if (article.title == title) return article;
          }
        }
      }
    }
    return null;
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
        spans.add(TextSpan(text: text.substring(start, index), style: baseStyle));
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

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = _searchController.text;

    return Scaffold(
      appBar: AppBar(
        forceMaterialTransparency: true,
        title: TextField(
          controller: _searchController,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Поиск по всем кодексам...',
            border: InputBorder.none,
          ),
          style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
        ),
        actions: [
          if (query.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () => _searchController.clear(),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : query.isEmpty
              ? _buildHistory()
              : _buildResults(query),
    );
  }

  Widget _buildHistory() {
    if (_history.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              'Введите запрос для поиска\nпо всем кодексам КР',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 8, 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Недавно просмотренные',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey[600]),
              ),
              TextButton(
                onPressed: () async {
                  await _historyService.clearHistory();
                  _refreshHistory();
                },
                child: const Text('Очистить', style: TextStyle(fontSize: 13, color: Colors.red)),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.separated(
            itemCount: _history.length,
            separatorBuilder: (_, __) => const Divider(height: 1, indent: 16, endIndent: 16),
            itemBuilder: (context, index) {
              final item = _history[index];
              final title = item['articleTitle'] ?? '';
              final codeName = item['codeName'] ?? '';
              final chapterName = item['chapterName'] ?? '';

              return ListTile(
                leading: Icon(Icons.history, color: Colors.grey[400], size: 20),
                title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
                subtitle: Text(
                  '$codeName  •  $chapterName',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                onTap: () {
                  final article = _findArticleByTitle(title);
                  if (article != null) {
                    _openArticle(article, codeName, chapterName);
                  }
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildResults(String query) {
    if (_results.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text('Ничего не найдено', style: TextStyle(fontSize: 18, color: Colors.grey[600])),
          ],
        ),
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Найдено: ${_results.length}',
              style: TextStyle(fontSize: 13, color: Colors.grey[600]),
            ),
          ),
        ),
        Expanded(
          child: ListView.separated(
            itemCount: _results.length,
            separatorBuilder: (_, __) => const Divider(height: 1, indent: 16, endIndent: 16),
            itemBuilder: (context, index) {
              final result = _results[index];
              return ListTile(
                title: _highlightText(
                  result.article.title,
                  query,
                  Theme.of(context).textTheme.bodyLarge,
                ),
                subtitle: Text(
                  '${result.codeName}  •  ${result.chapterName}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                onTap: () => _openArticle(result.article, result.codeName, result.chapterName),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _SearchResult {
  final Article article;
  final String codeName;
  final String chapterName;
  final bool titleMatch;

  _SearchResult({
    required this.article,
    required this.codeName,
    required this.chapterName,
    required this.titleMatch,
  });
}
