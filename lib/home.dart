import 'package:flutter/material.dart';
import 'flashcards.dart';
import 'hub.dart';
import 'library.dart';
import 'quiz.dart';
import 'style.dart';
import 'vocab.dart';

class HomePage extends StatefulWidget {
  final void Function(int tab) goTab;
  final VoidCallback onMenu;
  const HomePage({super.key, required this.goTab, required this.onMenu});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int total = 0;
  int saved = 0;

  @override
  void initState() {
    super.initState();
    loadStats();
  }

  Future<void> loadStats() async {
    try {
      final db = await Db.get();
      final r = await db
          .rawQuery('SELECT COUNT(*) AS c, SUM(saved) AS s FROM words');
      if (!mounted) return;
      setState(() {
        total = (r.first['c'] as int?) ?? 0;
        saved = (r.first['s'] as int?) ?? 0;
      });
    } catch (_) {}
  }

  void push(Widget p) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => p));
  }

  Widget stat(String label, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.14),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold)),
            Text(label,
                style: const TextStyle(color: Colors.white70, fontSize: 13)),
          ],
        ),
      ),
    );
  }

  Widget header() {
    final cs = Theme.of(context).colorScheme;
    final top = MediaQuery.of(context).padding.top;
    return Container(
      padding: EdgeInsets.fromLTRB(20, top + 8, 20, 24),
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(36)),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [kNavy, Color.lerp(kNavy, cs.primary, 0.55)!],
        ),
        boxShadow: softShadow(context),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.menu, color: Colors.white),
                onPressed: widget.onMenu,
              ),
              const Spacer(),
              const Icon(Icons.translate, color: kGold),
            ],
          ),
          const SizedBox(height: 8),
          const Text('K-Learn Studio',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 30,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          const Text('বাংলা থেকে কোরিয়ান, সহজে শিখুন',
              style: TextStyle(color: Colors.white70, fontSize: 15)),
          const SizedBox(height: 18),
          Row(
            children: [
              stat('মোট শব্দ', '$total'),
              const SizedBox(width: 12),
              stat('সংরক্ষিত শব্দ', '$saved'),
            ],
          ),
        ],
      ),
    );
  }

  Widget tile(IconData icon, Color color, String title, String sub,
      VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Container(
        decoration: BoxDecoration(
          color: cardBg(context),
          borderRadius: BorderRadius.circular(26),
          boxShadow: softShadow(context),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(26),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  IconCircle(icon: icon, color: color, size: 58),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title,
                            style: const TextStyle(
                                fontSize: 19, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 2),
                        Text(sub,
                            style: TextStyle(
                                fontSize: 14, color: softText(context))),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: loadStats,
      child: ListView(
        padding: const EdgeInsets.only(bottom: 30),
        children: [
          header(),
          const SizedBox(height: 18),
          tile(Icons.translate, kOrange, 'শব্দভাণ্ডার',
              'ছবি, উচ্চারণ ও অর্থসহ শব্দ', () => widget.goTab(0)),
          tile(Icons.style, const Color(0xFF00897B), '3D ফ্ল্যাশকার্ড',
              'সোয়াইপ করে শিখুন', () => push(const FlashcardPage())),
          tile(Icons.menu_book, kNavy, 'গ্রামার',
              'ব্যাকরণ, পাঠ ও PDF', () => widget.goTab(1)),
          tile(Icons.quiz, const Color(0xFF6C5CE7), 'কুইজ ও টেস্ট',
              'নিজেকে যাচাই করুন', () => push(const QuizPage())),
          tile(Icons.bookmark, kGold, 'সংরক্ষিত শব্দ',
              'আপনার বুকমার্ক করা শব্দ', () => widget.goTab(4)),
          tile(Icons.language, const Color(0xFF0984E3), 'ওয়েবসাইট হাব',
              'দরকারি লিংক', () => push(const HubPage())),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 12, 12),
            child: Row(
              children: [
                const Expanded(
                  child: Text('বইয়ের সংগ্রহ:',
                      style: TextStyle(
                          fontSize: 24, fontWeight: FontWeight.bold)),
                ),
                TextButton(
                  onPressed: () => widget.goTab(3),
                  child: const Text('সব দেখুন'),
                ),
              ],
            ),
          ),
          const BookShelf(limit: 4),
        ],
      ),
    );
  }
}
