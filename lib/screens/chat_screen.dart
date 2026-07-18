// lib/screens/chat_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:law_dictionary/models/chat_models.dart';
import 'package:law_dictionary/models/law_code_model.dart';
import 'package:law_dictionary/services/ai_service.dart';
import 'package:law_dictionary/services/chat_storage_service.dart';
import 'package:intl/intl.dart';

class ChatScreen extends StatefulWidget {
  final Article? relatedArticle;
  final String? articleCodeName;

  const ChatScreen({
    Key? key,
    this.relatedArticle,
    this.articleCodeName,
  }) : super(key: key);

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final AIService _aiService = AIService();
  final ChatStorageService _storageService = ChatStorageService();

  late ChatSession _currentSession;
  bool _isTyping = false;

  @override
  void initState() {
    super.initState();
    _initializeChat();
  }

  void _initializeChat() {
    _currentSession = ChatSession(
      title: widget.relatedArticle != null
          ? 'Вопрос по: ${widget.relatedArticle!.title}'
          : 'Новая консультация ${DateFormat('dd.MM').format(DateTime.now())}',
    );

    final welcomeMessage = ChatMessage(
      text: widget.relatedArticle != null
          ? 'Здравствуйте! Вижу, что у вас вопрос по статье:\n\n**${widget.relatedArticle!.title}**\n\nЧем могу помочь?'
          : 'Здравствуйте! Я AI-консультант по законодательству Кыргызской Республики.\n\nЗадайте ваш вопрос, и я постараюсь помочь!',
      isUser: false,
      type: MessageType.welcome,
    );

    setState(() {
      _currentSession = ChatSession(
        title: _currentSession.title,
      );
      _currentSession.messages.add(welcomeMessage);
    });

    if (widget.relatedArticle != null) {
      _controller.text = 'Объясните подробнее статью: ${widget.relatedArticle!.title}';
    }
  }

  void _sendMessage() async {
    if (_controller.text.trim().isEmpty) return;

    final userMessage = ChatMessage(
      text: _controller.text.trim(),
      isUser: true,
    );

    setState(() {
      _currentSession.messages.add(userMessage);
      _isTyping = true;
    });

    final questionText = _controller.text;
    _controller.clear();
    _scrollToBottom();

    await _storageService.saveSession(_currentSession);

    final response = await _aiService.getAIResponse(
      question: questionText,
      relatedArticle: widget.relatedArticle,
    );

    final aiMessage = ChatMessage(
      text: response.text,
      isUser: false,
      type: response.isSuccess ? MessageType.text : MessageType.error,
      references: response.references.map((ref) => ArticleInfo(
        codeName: ref.codeName,
        articleTitle: ref.articleTitle,
        sectionName: ref.sectionName,
        chapterName: ref.chapterName,
      )).toList(),
    );

    setState(() {
      _currentSession.messages.add(aiMessage);
      _isTyping = false;
    });

    _scrollToBottom();
    await _storageService.saveSession(_currentSession);
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _copyMessage(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Скопировано в буфер обмена'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        forceMaterialTransparency: true,
        title: const Text('AI Консультант'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => ChatHistoryScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Начать новый чат?'),
                  content: const Text('Текущая переписка будет сохранена в истории.'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Отмена'),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _initializeChat();
                      },
                      child: const Text('Начать новый'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _currentSession.messages.length + (_isTyping ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _currentSession.messages.length && _isTyping) {
                  return const _TypingIndicator();
                }
                return _buildMessage(_currentSession.messages[index]);
              },
            ),
          ),

          if (_currentSession.messages.length <= 1)
            _buildExampleQuestions(),

          _buildInputArea(isDark),
        ],
      ),
    );
  }

  Widget _buildMessage(ChatMessage message) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Align(
      alignment: message.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.all(12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.8,
        ),
        decoration: BoxDecoration(
          color: message.isUser
              ? Colors.blue[700]
              : (isDark ? Colors.grey[800] : Colors.grey[200]),
          borderRadius: BorderRadius.circular(16).copyWith(
            bottomLeft: message.isUser ? const Radius.circular(16) : const Radius.circular(4),
            bottomRight: message.isUser ? const Radius.circular(4) : const Radius.circular(16),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (message.type == MessageType.error)
              const Padding(
                padding: EdgeInsets.only(bottom: 8),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.error_outline, size: 16, color: Colors.red),
                    SizedBox(width: 4),
                    Text('Ошибка', style: TextStyle(fontSize: 12, color: Colors.red, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),

            message.isUser
                ? Text(message.text, style: const TextStyle(color: Colors.white))
                : MarkdownBody(
                    data: message.text,
                    styleSheet: MarkdownStyleSheet(
                      p: TextStyle(
                        color: isDark ? Colors.white : Colors.black87,
                        height: 1.4,
                      ),
                      strong: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                      listBullet: TextStyle(
                        color: isDark ? Colors.white70 : Colors.black54,
                      ),
                    ),
                  ),

            if (message.references != null && message.references!.isNotEmpty)
              Container(
                margin: const EdgeInsets.only(top: 10),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey[900] : Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.article_outlined, size: 14, color: Colors.blue[700]),
                        const SizedBox(width: 4),
                        Text(
                          'Упомянутые статьи:',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.blue[700]),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    ...message.references!.map((ref) => Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        '• ${ref.codeName}: ${ref.articleTitle}',
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? Colors.white70 : Colors.black54,
                        ),
                      ),
                    )),
                  ],
                ),
              ),

            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    DateFormat('HH:mm').format(message.timestamp),
                    style: TextStyle(
                      fontSize: 10,
                      color: message.isUser ? Colors.white54 : (isDark ? Colors.white38 : Colors.black38),
                    ),
                  ),
                ),
                if (!message.isUser) ...[
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => _copyMessage(message.text),
                    child: Icon(
                      Icons.copy,
                      size: 14,
                      color: isDark ? Colors.white38 : Colors.black38,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExampleQuestions() {
    final examples = _aiService.getExampleQuestions();

    return SizedBox(
      height: 40,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: examples.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ActionChip(
              label: Text(examples[index], style: const TextStyle(fontSize: 12)),
              onPressed: () => _controller.text = examples[index],
              avatar: Icon(Icons.touch_app, size: 16, color: Colors.blue[700]),
            ),
          );
        },
      ),
    );
  }

  Widget _buildInputArea(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[900] : Colors.white,
        boxShadow: [
          BoxShadow(
            offset: const Offset(0, -2),
            blurRadius: 4,
            color: Colors.black.withValues(),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                decoration: InputDecoration(
                  hintText: 'Задайте ваш вопрос...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide(
                      color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
                    ),
                  ),
                  filled: true,
                  fillColor: isDark ? Colors.grey[800] : Colors.grey[50],
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                ),
                maxLines: null,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) { if (!_isTyping) _sendMessage(); },
              ),
            ),
            const SizedBox(width: 8),
            CircleAvatar(
              backgroundColor: Colors.blue[700],
              radius: 24,
              child: IconButton(
                icon: Icon(
                  _isTyping ? Icons.hourglass_top : Icons.send,
                  color: Colors.white,
                  size: 20,
                ),
                onPressed: _isTyping ? null : _sendMessage,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}


class _TypingIndicator extends StatefulWidget {
  const _TypingIndicator();

  @override
  State<_TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<_TypingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isDark ? Colors.grey[800] : Colors.grey[200],
          borderRadius: BorderRadius.circular(16).copyWith(
            bottomLeft: const Radius.circular(4),
          ),
        ),
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(3, (i) {
                final offset = ((_controller.value * 3) - i).clamp(0.0, 1.0);
                final opacity = (offset < 0.5 ? offset : 1.0 - offset) * 2;
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: Colors.grey[600]!.withOpacity(0.3 + opacity * 0.7),
                    shape: BoxShape.circle,
                  ),
                );
              }),
            );
          },
        ),
      ),
    );
  }
}


class ChatHistoryScreen extends StatefulWidget {
  @override
  _ChatHistoryScreenState createState() => _ChatHistoryScreenState();
}

class _ChatHistoryScreenState extends State<ChatHistoryScreen> {
  final ChatStorageService _storageService = ChatStorageService();
  List<ChatSession> _sessions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSessions();
  }

  Future<void> _loadSessions() async {
    final sessions = await _storageService.getAllSessions();
    setState(() {
      _sessions = sessions;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        forceMaterialTransparency: true,
        title: const Text('История консультаций'),
        centerTitle: true,
        actions: [
          if (_sessions.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Очистить историю?'),
                    content: const Text('Все сохраненные консультации будут удалены.'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Отмена'),
                      ),
                      TextButton(
                        onPressed: () async {
                          await _storageService.clearAllSessions();
                          Navigator.pop(context);
                          _loadSessions();
                        },
                        child: const Text('Очистить', style: TextStyle(color: Colors.red)),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _sessions.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.history, size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text('История пуста', style: TextStyle(fontSize: 18, color: Colors.grey[600])),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: _sessions.length,
                  itemBuilder: (context, index) {
                    final session = _sessions[index];
                    final messageCount = session.messages.where((m) => m.isUser).length;
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.blue[700],
                          child: Text(
                            '$messageCount',
                            style: const TextStyle(color: Colors.white, fontSize: 13),
                          ),
                        ),
                        title: Text(session.title),
                        subtitle: Text(DateFormat('dd.MM.yyyy HH:mm').format(session.createdAt)),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ChatSessionViewScreen(session: session),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
    );
  }
}


class ChatSessionViewScreen extends StatelessWidget {
  final ChatSession session;

  const ChatSessionViewScreen({Key? key, required this.session}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        forceMaterialTransparency: true,
        title: Text(session.title, overflow: TextOverflow.ellipsis),
        centerTitle: true,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: session.messages.length,
        itemBuilder: (context, index) {
          final message = session.messages[index];
          return Align(
            alignment: message.isUser ? Alignment.centerRight : Alignment.centerLeft,
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 6),
              padding: const EdgeInsets.all(12),
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.8,
              ),
              decoration: BoxDecoration(
                color: message.isUser
                    ? Colors.blue[700]
                    : (isDark ? Colors.grey[800] : Colors.grey[200]),
                borderRadius: BorderRadius.circular(16).copyWith(
                  bottomLeft: message.isUser ? const Radius.circular(16) : const Radius.circular(4),
                  bottomRight: message.isUser ? const Radius.circular(4) : const Radius.circular(16),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  message.isUser
                      ? Text(message.text, style: const TextStyle(color: Colors.white))
                      : MarkdownBody(
                          data: message.text,
                          styleSheet: MarkdownStyleSheet(
                            p: TextStyle(color: isDark ? Colors.white : Colors.black87, height: 1.4),
                            strong: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87),
                          ),
                        ),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat('HH:mm').format(message.timestamp),
                    style: TextStyle(
                      fontSize: 10,
                      color: message.isUser ? Colors.white54 : (isDark ? Colors.white38 : Colors.black38),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
