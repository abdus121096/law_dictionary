import 'package:flutter/material.dart';
import 'package:law_dictionary/screen/favorite_screen.dart';
import 'package:law_dictionary/screen/law_code_screen.dart';
import 'package:law_dictionary/screen/settings_screen.dart';
import 'package:law_dictionary/screens/onboarding_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: ".env");

  SharedPreferences prefs = await SharedPreferences.getInstance();
  bool isDarkTheme = prefs.getBool('isDarkTheme') ?? false;
  bool onboardingDone = prefs.getBool('onboarding_done') ?? false;
  String language = prefs.getString('language') ?? 'ru';

  runApp(LawDictionaryApp(
    isDarkTheme: isDarkTheme,
    showOnboarding: !onboardingDone,
    language: language,
  ));
}

class LawDictionaryApp extends StatefulWidget {
  final bool isDarkTheme;
  final bool showOnboarding;
  final String language;

  const LawDictionaryApp({
    super.key,
    required this.isDarkTheme,
    required this.showOnboarding,
    required this.language,
  });

  @override
  State<LawDictionaryApp> createState() => _LawDictionaryAppState();
}

class _LawDictionaryAppState extends State<LawDictionaryApp> {
  bool isDarkTheme = false;
  bool _showOnboarding = false;
  int _selectedIndex = 0;
  String _language = 'ru';

  @override
  void initState() {
    super.initState();
    isDarkTheme = widget.isDarkTheme;
    _showOnboarding = widget.showOnboarding;
    _language = widget.language;
  }

  void toggleTheme(bool isDark) {
    setState(() {
      isDarkTheme = isDark;
      _saveThemePreference(isDark);
    });
  }

  void toggleLanguage(String lang) {
    setState(() => _language = lang);
  }

  Future<void> _saveThemePreference(bool isDark) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setBool('isDarkTheme', isDark);
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _onOnboardingDone() {
    setState(() => _showOnboarding = false);
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> screens = [
      LawCodeScreen(language: _language),
      FavoriteScreen(isActive: _selectedIndex == 1),
      SettingsScreen(
        toggleTheme: toggleTheme,
        isDarkTheme: isDarkTheme,
      ),
    ];

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Law Dictionary',
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
      themeMode: isDarkTheme ? ThemeMode.dark : ThemeMode.light,
      home: _showOnboarding
          ? OnboardingScreen(onDone: _onOnboardingDone)
          : Scaffold(
              body: IndexedStack(index: _selectedIndex, children: screens),
              bottomNavigationBar: BottomNavigationBar(
                items: const <BottomNavigationBarItem>[
                  BottomNavigationBarItem(
                    icon: Icon(Icons.book),
                    label: 'Кодексы',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.star_outline),
                    label: 'Избранное',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.settings),
                    label: 'Настройки',
                  ),
                ],
                currentIndex: _selectedIndex,
                selectedItemColor: Colors.blue,
                onTap: _onItemTapped,
              ),
            ),
    );
  }
}
