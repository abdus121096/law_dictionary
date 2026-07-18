import 'package:flutter/material.dart';
import 'package:law_dictionary/data/json_loader.dart';
import '../models/law_code_model.dart';
import '../screens/chat_screen.dart';
import '../screens/code_chapter_screen.dart';
import '../screens/global_search_screen.dart';


class LawCodeScreen extends StatefulWidget {
  final String language;

  const LawCodeScreen({super.key, this.language = 'ru'});

  @override
  State<LawCodeScreen> createState() => _LawCodeScreenState();
}

class _LawCodeScreenState extends State<LawCodeScreen> {
  late Future<List<LawCode>> _future;

  @override
  void initState() {
    super.initState();
    _future = JsonLoader().loadLawCodes(language: widget.language);
  }

  @override
  void didUpdateWidget(LawCodeScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.language != widget.language) {
      _future = JsonLoader().loadLawCodes(language: widget.language);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        forceMaterialTransparency: true,
        title: const Text('Кодексы'),
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => GlobalSearchScreen(language: widget.language),
                ),
              );
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => ChatScreen()),
          );
        },
        label: const Text(
          'AI Консультант',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        icon: const Icon(Icons.chat, color: Colors.white),
        backgroundColor: Colors.blue[700],
      ),

      body: FutureBuilder<List<LawCode>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Ошибка загрузки: ${snapshot.error}'));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          List<LawCode> lawCodes = snapshot.data!;

          return ListView.builder(
            itemCount: lawCodes.length,
            itemBuilder: (context, index) {
              final lawCode = lawCodes[index];

              return Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 4,
                  child: InkWell(
                      onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ChapterScreen(lawCode: lawCode),
                        ),
                      );
                    },
                    // onTap: () {
                    //   Navigator.push(
                    //     context,
                    //     MaterialPageRoute(
                    //       builder: (context) => SectionScreen(lawCode: lawCode),
                    //     ),
                    //   );
                    // },
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: Colors.blue.shade50,
                            radius: 20,
                            child: Icon(Icons.book,
                                color: Colors.blue.shade800, size: 20),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  lawCode.name,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Откройте разделы',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(
                            Icons.arrow_forward_ios,
                            color: Colors.blue,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
