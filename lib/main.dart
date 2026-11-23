import 'package:flutter/material.dart';
import 'connected.dart';
import 'flashcards.dart';
import 'grammar.dart';
import 'hub.dart';
import 'library.dart';
import 'quiz.dart';
import 'settings.dart';
import 'ui.dart';
import 'vocabulary.dart';

void main() => runApp(const KLearnApp());

class KLearnApp extends StatefulWidget {
  const KLearnApp({super.key});
  @override
  State<KLearnApp> createState() => _KLearnAppState();
}

class _KLearnAppState extends State<KLearnApp> {
  @override
  void initState() {
    super.initState();
    AppSettings.load().catchError((_) {});
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: AppSettings.seed,
      builder: (c1, seed, _) => ValueListenableBuilder<ThemeMode>(
        valueListenable: AppSettings.mode,
        builder: (c2, mode, __) => ValueListenableBuilder<double>(
          valueListenable: AppSettings.textScale,
          builder: (c3, scale, ___) => MaterialApp(
            title: 'K-Learn Studio',
            debugShowCheckedModeBanner: false,
            themeMode: mode,
            theme: ThemeData(
              useMaterial3: true,
              colorSchemeSeed: Color(seed),
              brightness: Brightness.light,
            ),
            darkTheme: ThemeData(
              useMaterial3: true,
              colorSchemeSeed: Color(seed),
              brightness: Brightness.dark,
            ),
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context)
                  .copyWith(textScaler: TextScaler.linear(scale)),
              child: child!,
            ),
            home: const Shell(),
          ),
        ),
      ),
    );
  }
}

class Shell extends StatefulWidget {
  const Shell({super.key});
  @override
  State<Shell> createState() => _ShellState();
}

class _ShellState extends State<Shell> {
  int tab = 0;

  static const titles = ['শব্দভাণ্ডার', 'গ্রামার', 'লাইব্রেরি', 'সংরক্ষিত শব্দ'];

  Widget page() {
    switch (tab) {
      case 1:
        return const GrammarPage();
      case 2:
        return const LibraryPage();
      case 3:
        return const VocabPage(savedOnly: true);
      default:
        return const VocabPage();
    }
  }

  void toggleTheme(bool isDark) {
    AppSettings.setMode(isDark ? ThemeMode.light : ThemeMode.dark);
  }

  void goTab(BuildContext ctx, int i) {
    Navigator.pop(ctx);
    setState(() => tab = i);
  }

  void openPage(BuildContext ctx, Widget p) {
    final nav = Navigator.of(ctx);
    nav.pop();
    nav.push(MaterialPageRoute(builder: (_) => p));
  }

  Widget item(BuildContext ctx, IconData icon, String label, VoidCallback f,
      {bool selected = false}) {
    return ListTile(
      leading: Icon(icon),
      title: Text(label),
      selected: selected,
      onTap: f,
    );
  }

  Widget sectionTitle(String t) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
        child: Text(t,
            style: const TextStyle(
                fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
      );

  Widget drawer() {
    return Drawer(
      child: Builder(
        builder: (ctx) {
          final cs = Theme.of(ctx).colorScheme;
          return ListView(
            padding: EdgeInsets.zero,
            children: [
              Container(
                padding: const EdgeInsets.fromLTRB(20, 60, 20, 24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [cs.primary, cs.primary.withOpacity(0.7)],
                  ),
                ),
                child: const Text('K-Learn Studio',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.bold)),
              ),
              sectionTitle('BROWSE'),
              item(ctx, Icons.home, 'শব্দভাণ্ডার', () => goTab(ctx, 0),
                  selected: tab == 0),
              item(ctx, Icons.menu_book, 'গ্রামার', () => goTab(ctx, 1),
                  selected: tab == 1),
              item(ctx, Icons.library_books, 'লাইব্রেরি (PDF)',
                  () => goTab(ctx, 2),
                  selected: tab == 2),
              item(ctx, Icons.bookmark, 'সংরক্ষিত শব্দ', () => goTab(ctx, 3),
                  selected: tab == 3),
              const Divider(),
              sectionTitle('PRACTICE'),
              item(ctx, Icons.quiz, 'কুইজ ও টেস্ট',
                  () => openPage(ctx, const QuizPage())),
              item(ctx, Icons.style, '3D ফ্ল্যাশকার্ড',
                  () => openPage(ctx, const FlashcardPage())),
              const Divider(),
              sectionTitle('LINKS'),
              item(ctx, Icons.language, 'ওয়েবসাইট হাব',
                  () => openPage(ctx, const HubPage())),
              item(ctx, Icons.apps, 'কানেক্টেড অ্যাপস',
                  () => openPage(ctx, const ConnectedPage())),
              const Divider(),
              sectionTitle('APP'),
              item(ctx, Icons.settings, 'সেটিংস',
                  () => openPage(ctx, const SettingsPage())),
              item(ctx, Icons.info_outline, 'About', () {
                Navigator.pop(ctx);
                showAboutDialog(
                  context: context,
                  applicationName: 'K-Learn Studio',
                  applicationVersion: '1.0',
                  children: const [
                    Text('বাংলা ভাষীদের জন্য কোরিয়ান শেখার অ্যাপ।'),
                  ],
                );
              }),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: tab == 1
          ? null
          : AppBar(
              backgroundColor: Colors.transparent,
              scrolledUnderElevation: 0,
              centerTitle: true,
              leading: Builder(
                builder: (c) => IconButton(
                  icon: const Icon(Icons.menu),
                  onPressed: () => Scaffold.of(c).openDrawer(),
                ),
              ),
              title: Text(titles[tab],
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              actions: [
                IconButton(
                  icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode),
                  onPressed: () => toggleTheme(isDark),
                ),
              ],
            ),
      drawer: drawer(),
      body: AnimatedBg(child: SafeArea(top: false, child: page())),
      bottomNavigationBar: NavigationBar(
        selectedIndex: tab,
        onDestinationSelected: (i) => setState(() => tab = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'হোম'),
          NavigationDestination(icon: Icon(Icons.menu_book_outlined), selectedIcon: Icon(Icons.menu_book), label: 'গ্রামার'),
          NavigationDestination(icon: Icon(Icons.library_books_outlined), selectedIcon: Icon(Icons.library_books), label: 'লাইব্রেরি'),
          NavigationDestination(icon: Icon(Icons.bookmark_border), selectedIcon: Icon(Icons.bookmark), label: 'সংরক্ষিত'),
        ],
      ),
    );
  }
}
