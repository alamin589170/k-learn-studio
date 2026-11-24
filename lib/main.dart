import 'package:flutter/material.dart';
import 'about.dart';
import 'connected.dart';
import 'flashcards.dart';
import 'grammar.dart';
import 'home.dart';
import 'hub.dart';
import 'library.dart';
import 'quiz.dart';
import 'settings.dart';
import 'style.dart';
import 'ui.dart';
import 'vocabulary.dart';

void main() => runApp(const KLearnApp());

ThemeData buildTheme(int seed, Brightness b) {
  final dark = b == Brightness.dark;
  final base = ColorScheme.fromSeed(seedColor: Color(seed), brightness: b);
  final cs = base.copyWith(
    surface: dark ? const Color(0xFF14243A) : kCream,
  );
  return ThemeData(
    useMaterial3: true,
    colorScheme: cs,
    scaffoldBackgroundColor: cs.surface,
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      scrolledUnderElevation: 0,
      centerTitle: true,
    ),
  );
}

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
            theme: buildTheme(seed, Brightness.light),
            darkTheme: buildTheme(seed, Brightness.dark),
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
  // ০ শব্দ, ১ গ্রামার, ২ হোম, ৩ লাইব্রেরি, ৪ সংরক্ষিত
  int tab = 2;
  final GlobalKey<ScaffoldState> key = GlobalKey<ScaffoldState>();

  static const titles = [
    'শব্দভাণ্ডার',
    'গ্রামার',
    'হোম',
    'লাইব্রেরি',
    'সংরক্ষিত শব্দ'
  ];

  void openMenu() => key.currentState?.openDrawer();

  Widget page() {
    switch (tab) {
      case 0:
        return const VocabPage();
      case 1:
        return GrammarPage(onMenu: openMenu);
      case 3:
        return const LibraryPage();
      case 4:
        return const VocabPage(savedOnly: true);
      default:
        return HomePage(goTab: (i) => setState(() => tab = i), onMenu: openMenu);
    }
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

  Widget item(IconData icon, String label, VoidCallback f,
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
                    colors: [kNavy, Color.lerp(kNavy, cs.primary, 0.6)!],
                  ),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('K-Learn Studio',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 26,
                            fontWeight: FontWeight.bold)),
                    SizedBox(height: 4),
                    Text('by MD Alamin',
                        style: TextStyle(color: Colors.white70, fontSize: 13)),
                  ],
                ),
              ),
              sectionTitle('BROWSE'),
              item(Icons.home, 'হোম', () => goTab(ctx, 2), selected: tab == 2),
              item(Icons.translate, 'শব্দভাণ্ডার', () => goTab(ctx, 0),
                  selected: tab == 0),
              item(Icons.menu_book, 'গ্রামার', () => goTab(ctx, 1),
                  selected: tab == 1),
              item(Icons.library_books, 'লাইব্রেরি (PDF বই)',
                  () => goTab(ctx, 3),
                  selected: tab == 3),
              item(Icons.bookmark, 'সংরক্ষিত শব্দ', () => goTab(ctx, 4),
                  selected: tab == 4),
              const Divider(),
              sectionTitle('PRACTICE'),
              item(Icons.quiz, 'কুইজ ও টেস্ট',
                  () => openPage(ctx, const QuizPage())),
              item(Icons.style, '3D ফ্ল্যাশকার্ড',
                  () => openPage(ctx, const FlashcardPage())),
              const Divider(),
              sectionTitle('LINKS'),
              item(Icons.language, 'ওয়েবসাইট হাব',
                  () => openPage(ctx, const HubPage())),
              item(Icons.apps, 'কানেক্টেড অ্যাপস',
                  () => openPage(ctx, const ConnectedPage())),
              const Divider(),
              sectionTitle('APP'),
              item(Icons.settings, 'সেটিংস',
                  () => openPage(ctx, const SettingsPage())),
              item(Icons.info_outline, 'অ্যাপ ও ডেভেলপার',
                  () => openPage(ctx, const AboutPage())),
            ],
          );
        },
      ),
    );
  }

  Widget navItem(int i, IconData icon, String label) {
    final cs = Theme.of(context).colorScheme;
    final sel = tab == i;
    final col = sel ? cs.primary : softText(context);
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => setState(() => tab = i),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: col, size: 26),
            const SizedBox(height: 3),
            Text(label,
                style: TextStyle(
                    fontSize: 12,
                    color: col,
                    fontWeight: sel ? FontWeight.bold : FontWeight.normal)),
          ],
        ),
      ),
    );
  }

  Widget bottomNav() {
    final cs = Theme.of(context).colorScheme;
    final selHome = tab == 2;
    return SafeArea(
      top: false,
      child: SizedBox(
        height: 108,
        child: Stack(
          children: [
            Positioned(
              left: 14,
              right: 14,
              bottom: 12,
              height: 70,
              child: Container(
                decoration: BoxDecoration(
                  color: cardBg(context),
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: softShadow(context),
                ),
                child: Row(
                  children: [
                    navItem(0, Icons.translate, 'শব্দ'),
                    navItem(1, Icons.menu_book, 'গ্রামার'),
                    const Expanded(child: SizedBox()),
                    navItem(3, Icons.library_books, 'লাইব্রেরি'),
                    navItem(4, Icons.bookmark, 'সংরক্ষিত'),
                  ],
                ),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 18,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => setState(() => tab = 2),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 62,
                      height: 62,
                      decoration: BoxDecoration(
                        color: cs.primary,
                        borderRadius: BorderRadius.circular(22),
                        boxShadow: [
                          BoxShadow(
                            color: cs.primary.withOpacity(0.45),
                            blurRadius: 16,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: const Icon(Icons.home_rounded,
                          color: Colors.white, size: 34),
                    ),
                    const SizedBox(height: 3),
                    Text('হোম',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: selHome ? cs.primary : softText(context))),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final showBar = tab == 0 || tab == 3 || tab == 4;
    return Scaffold(
      key: key,
      appBar: showBar
          ? AppBar(
              leading: IconButton(
                icon: const Icon(Icons.menu),
                onPressed: openMenu,
              ),
              title: Text(titles[tab],
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              actions: [
                IconButton(
                  icon: Icon(isDark(context)
                      ? Icons.light_mode
                      : Icons.dark_mode),
                  onPressed: () => AppSettings.setMode(
                      isDark(context) ? ThemeMode.light : ThemeMode.dark),
                ),
              ],
            )
          : null,
      drawer: drawer(),
      body: AnimatedBg(child: SafeArea(top: false, bottom: false, child: page())),
      bottomNavigationBar: bottomNav(),
    );
  }
}
