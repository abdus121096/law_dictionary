import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/law_code_model.dart';
import '../services/history_service.dart';
import '../services/notes_service.dart';

class ArticleContentScreen extends StatefulWidget {
  final Article article;
  final String codeName;
  final String chapterName;

  const ArticleContentScreen({
    super.key,
    required this.article,
    this.codeName = '',
    this.chapterName = '',
  });

  @override
  State<ArticleContentScreen> createState() => _ArticleContentScreenState();
}

class _ArticleContentScreenState extends State<ArticleContentScreen> {
  double _fontSize = 16;
  String? _note;
  List<String> _favorites = [];
  final NotesService _notesService = NotesService();

  @override
  void initState() {
    super.initState();
    _loadFontSize();
    _loadNote();
    _loadFavorites();
    if (widget.codeName.isNotEmpty) {
      HistoryService().addToHistory(
        articleTitle: widget.article.title,
        codeName: widget.codeName,
        chapterName: widget.chapterName,
      );
    }
  }

  Future<void> _loadFontSize() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _fontSize = prefs.getDouble('fontSize') ?? 16;
    });
  }

  Future<void> _loadFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _favorites = prefs.getStringList('favorites') ?? [];
    });
  }

  Future<void> _toggleFavorite() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    final title = widget.article.title;
    setState(() {
      if (_favorites.contains(title)) {
        _favorites.remove(title);
      } else {
        _favorites.add(title);
      }
    });
    await prefs.setStringList('favorites', _favorites);
  }

  Future<void> _loadNote() async {
    final note = await _notesService.getNote(widget.article.title);
    if (!mounted) return;
    setState(() => _note = note);
  }

  void _openNoteEditor() {
    final controller = TextEditingController(text: _note ?? '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: DraggableScrollableSheet(
            expand: false,
            initialChildSize: 0.6,
            maxChildSize: 0.9,
            builder: (context, scrollController) {
              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 8, 0),
                    child: Row(
                      children: [
                        const Icon(Icons.edit_note, color: Colors.blue),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            'Заметка',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        ),
                        if (_note != null && _note!.isNotEmpty)
                          IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.red),
                            tooltip: 'Удалить заметку',
                            onPressed: () async {
                              await _notesService.deleteNote(widget.article.title);
                              setState(() => _note = null);
                              Navigator.pop(context);
                            },
                          ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 8),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: TextField(
                        controller: controller,
                        maxLines: null,
                        expands: true,
                        autofocus: true,
                        textAlignVertical: TextAlignVertical.top,
                        decoration: const InputDecoration(
                          hintText: 'Напишите заметку к этой статье...',
                          border: InputBorder.none,
                        ),
                        style: const TextStyle(fontSize: 15, height: 1.5),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () async {
                          await _notesService.saveNote(
                            widget.article.title,
                            controller.text,
                          );
                          setState(() {
                            _note = controller.text.trim().isEmpty
                                ? null
                                : controller.text.trim();
                          });
                          Navigator.pop(context);
                        },
                        child: const Text('Сохранить'),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        forceMaterialTransparency: true,
        title: Text(widget.article.title, overflow: TextOverflow.ellipsis),
        actions: [
          IconButton(
            icon: Icon(
              _favorites.contains(widget.article.title)
                  ? Icons.star
                  : Icons.star_border,
              color: _favorites.contains(widget.article.title)
                  ? Colors.amber
                  : null,
            ),
            tooltip: 'Избранное',
            onPressed: _toggleFavorite,
          ),
          IconButton(
            icon: Icon(
              _note != null && _note!.isNotEmpty
                  ? Icons.edit_note
                  : Icons.note_add_outlined,
              color: _note != null && _note!.isNotEmpty ? Colors.blue : null,
            ),
            tooltip: 'Заметка',
            onPressed: _openNoteEditor,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.article.title,
              style: TextStyle(
                fontSize: _fontSize + 6,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (widget.codeName.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                '${widget.codeName}  •  ${widget.chapterName}',
                style: TextStyle(fontSize: 13, color: Colors.grey[600]),
              ),
            ],
            const SizedBox(height: 16),
            Text(
              widget.article.content.join('\n\n'),
              style: TextStyle(fontSize: _fontSize, height: 1.5),
            ),

            // Блок заметки
            if (_note != null && _note!.isNotEmpty) ...[
              const SizedBox(height: 24),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.yellow[900]!.withOpacity(0.3)
                      : Colors.yellow[50],
                  border: Border.all(
                    color: isDark ? Colors.yellow[700]! : Colors.yellow[300]!,
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.edit_note, size: 16, color: Colors.orange[700]),
                        const SizedBox(width: 6),
                        Text(
                          'Моя заметка',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.orange[700],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _note!,
                      style: TextStyle(fontSize: _fontSize - 1, height: 1.5),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
