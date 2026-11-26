import 'package:flutter/material.dart';
import 'about.dart';
import 'catalog.dart';
import 'connected.dart';
import 'flashcards.dart';
import 'grammar.dart';
import 'home.dart';
import 'hub.dart';
import 'library.dart';
import 'quiz.dart';
import 'settings.dart';
import 'style.dart';
import 'sync.dart';
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
    Catalog.autoOnce();
    SyncService.autoOnce();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge(
          [AppSettings.preset, AppSettings.accent, AppSettings.textScale]),
      builder: (context, _) => MaterialApp(
        title: 'K-Learn Studio',
        debugShowCheckedModeBanner: false,
        theme: buildTheme(
            kPresets[AppSettings.preset.value], AppSettings.accent.value),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
              textScaler: TextScaler.linear(AppSettings.textScale.value)),
          child: Stack(
            children: [
              const Positioned.fill(child: AnimatedBg()),
              Positioned.fill(child: child!),
              Positioned.fill(
                child: ListenableBuilder(
                  listenable:
                      Listenable.merge([AppSettings.warm, AppSettings.dim]),
                  builder: (c, _) => IgnorePointer(
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: ColoredBox(
                            color: const Color(0xFFFF9A3C)
                                .withOpacity(AppSettings.warm.value * 0.30),
                          ),
                        ),
                        Positioned.fill(
                          child: ColoredBox(
                            color: Colors.black
                                .withOpacity(AppSettings.dim.value),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        home: const Shell(),
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
        return const VocabPage(key: ValueKey('vocab-all'));
      case 1:
        return GrammarPage(key: const ValueKey('grammar'), onMenu: openMenu);
      case 3:
        return const LibraryPage(key: ValueKey('library'));
      case 4:
        return const VocabPage(key: ValueKey('vocab-saved'), savedOnly: true);
      default:
        return HomePage(
            key: const ValueKey('home'),
            goTab: (i) => setState(() => tab = i),
            onMenu: openMenu);
    }
  }

  void goTab(BuildContext ctx, int i) {
    setState(() => tab = i);
    key.currentState?.closeDrawer();
  }

  void openPage(BuildContext ctx, Widget p) {
    final nav = Navigator.of(context);
    key.currentState?.closeDrawer();
    Future<void>.delayed(const Duration(milliseconds: 220), () {
      if (mounted) nav.push(MaterialPageRoute(builder: (_) => p));
    });
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
      backgroundColor: Theme.of(context).colorScheme.surface.withOpacity(0.94),
      child: Builder(
        builder: (ctx) {
          return ListView(
            padding: EdgeInsets.zero,
            children: [
              Container(
                padding: const EdgeInsets.fromLTRB(20, 60, 20, 24),
                decoration: BoxDecoration(gradient: headGradient(ctx)),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('K-Learn Studio',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 26,
                            fontWeight: FontWeight.bold)),
                    SizedBox(height: 8),
                    Text('MD Alamin Shagor',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w600)),
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
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
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
          clipBehavior: Clip.none,
          children: [
            Positioned(
              left: 14,
              right: 14,
              bottom: 12,
              height: 70,
              child: Glass(
                radius: 30,
                blur: 20,
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
              bottom: 18,
              left: 0,
              right: 0,
              child: Align(
                alignment: Alignment.bottomCenter,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => setState(() => tab = 2),
                  child: SizedBox(
                    width: 74,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 62,
                          height: 62,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(22),
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [cs.primary, head2(context)],
                            ),
                            border: Border.all(
                                color: Colors.white.withOpacity(0.55)),
                            boxShadow: [
                              BoxShadow(
                                color: cs.primary.withOpacity(0.5),
                                blurRadius: 18,
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
                                color:
                                    selHome ? cs.primary : softText(context))),
                      ],
                    ),
                  ),
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
            )
          : null,
      drawer: drawer(),
      body: SafeArea(top: false, bottom: false, child: page()),
      bottomNavigationBar: bottomNav(),
    );
  }
}
