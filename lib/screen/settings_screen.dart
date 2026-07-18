import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsScreen extends StatefulWidget {
  final Function(bool) toggleTheme;
  final bool isDarkTheme;

  const SettingsScreen({
    super.key,
    required this.toggleTheme,
    required this.isDarkTheme,
  });

  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool isDarkTheme = false;
  double fontSize = 16;

  static const double _minFont = 12;
  static const double _maxFont = 22;

  @override
  void initState() {
    super.initState();
    isDarkTheme = widget.isDarkTheme;
    _loadFontSize();
  }

  @override
  void didUpdateWidget(SettingsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isDarkTheme != widget.isDarkTheme) {
      setState(() => isDarkTheme = widget.isDarkTheme);
    }
  }

  Future<void> _loadFontSize() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      fontSize = prefs.getDouble('fontSize') ?? 16;
    });
  }

  Future<void> _saveSettings() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setBool('isDarkTheme', isDarkTheme);
  }

  Future<void> _saveFontSize(double size) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setDouble('fontSize', size);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Настройки'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Темная тема',
                    style: TextStyle(fontSize: 16),
                  ),
                  Switch(
                    value: isDarkTheme,
                    onChanged: (bool value) {
                      setState(() {
                        isDarkTheme = value;
                      });
                      widget.toggleTheme(value);
                      _saveSettings();
                    },
                  ),
                ],
              ),
            ),
            const Divider(thickness: 1, height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Размер шрифта', style: TextStyle(fontSize: 16)),
                      Text(
                        '${fontSize.round()} пт',
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline),
                        onPressed: fontSize > _minFont
                            ? () {
                                setState(() => fontSize -= 1);
                                _saveFontSize(fontSize);
                              }
                            : null,
                      ),
                      Expanded(
                        child: Slider(
                          value: fontSize,
                          min: _minFont,
                          max: _maxFont,
                          divisions: (_maxFont - _minFont).round(),
                          onChanged: (value) {
                            setState(() => fontSize = value);
                            _saveFontSize(value);
                          },
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add_circle_outline),
                        onPressed: fontSize < _maxFont
                            ? () {
                                setState(() => fontSize += 1);
                                _saveFontSize(fontSize);
                              }
                            : null,
                      ),
                    ],
                  ),
                  Center(
                    child: Text(
                      'Пример текста статьи',
                      style: TextStyle(fontSize: fontSize, height: 1.5),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(thickness: 1, height: 10),
            ListTile(
              title: const Text('О приложении'),
              onTap: () {
                showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        content: Column(
                          mainAxisSize: MainAxisSize.min, 
                          mainAxisAlignment: MainAxisAlignment.center, 
                          crossAxisAlignment: CrossAxisAlignment.center, 
                          children: [
                            Image.asset('assets/icon/imageee.png', width: 70, height: 70),
                            const SizedBox(height: 20), 
                            const Text(
                              'Кодексы КР',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                            ),
                            const SizedBox(height: 10), 
                            const Text('Версия: 1.0.0'),
                          ],
                        ),
                        actions: [
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                            child: const Text('Закрыть'),
                          ),
                        ],
                      );
                    });
              },
            ),
          ],
        ),
      ),
    );
  }
}
