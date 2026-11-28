import 'package:flutter/material.dart';
import 'connected.dart';
import 'flags.dart';
import 'flashcards.dart';
import 'hub.dart';
import 'library.dart';
import 'quiz.dart';
import 'style.dart';
import 'notices.dart';

class HomePage extends StatefulWidget {
  final void Function(int tab) goTab;
  final VoidCallback onMenu;
  const HomePage({super.key, required this.goTab, required this.onMenu});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  void push(Widget p) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => p));
  }

  Widget header() {
    final top = MediaQuery.of(context).padding.top;
    final p = palOf(context);
    final on = Theme.of(context).colorScheme.onSurface;
    return Padding(
      padding: EdgeInsets.fromLTRB(12, top + 8, 12, 0),
      child: Glass(
        radius: 30,
        padding: const EdgeInsets.fromLTRB(8, 6, 14, 16),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withOpacity(0.10),
            p.head1.withOpacity(0.16),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                IconButton(
                  icon: Icon(Icons.menu, color: on),
                  onPressed: widget.onMenu,
                ),
                const Spacer(),
                IconButton(
                  icon: Icon(Icons.search, color: on),
                  tooltip: 'শব্দ খুঁজুন',
                  onPressed: () => widget.goTab(0),
                ),
                const LangBadge(),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(left: 10, top: 14),
              child: Text('K-Learn Studio',
                  style: TextStyle(
                      color: on, fontSize: 34, fontWeight: FontWeight.bold)),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 10, top: 4, bottom: 14),
              child: Text('বাংলা থেকে কোরিয়ান, সহজে শিখুন',
                  style: TextStyle(color: softText(context), fontSize: 16)),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 6),
              child: Column(
                children: [
                  NewsBox(
                      source: BoeslNotices.sources[0],
                      accent: const Color(0xFF34D399)),
                  const SizedBox(height: 8),
                  NewsBox(
                      source: BoeslNotices.sources[1],
                      accent: const Color(0xFFFB7185)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget tile(IconData icon, Color color, String title, String sub,
      VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Glass(
        radius: 26,
        blur: 14,
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
    final cs = Theme.of(context).colorScheme;
    return RefreshIndicator(
      onRefresh: () => BoeslNotices.ensure(force: true),
      child: ListView(
        padding: const EdgeInsets.only(bottom: 30),
        children: [
          header(),
          const SizedBox(height: 12),
          tile(Icons.translate, cs.primary, 'শব্দভাণ্ডার',
              'ছবি, উচ্চারণ ও অর্থসহ শব্দ', () => widget.goTab(0)),
          tile(Icons.style, const Color(0xFF2A7F6B), '3D ফ্ল্যাশকার্ড',
              'সোয়াইপ করে শিখুন', () => push(const FlashcardPage())),
          tile(Icons.menu_book, const Color(0xFF2F6DB5), 'গ্রামার',
              'ব্যাকরণ, পাঠ ও PDF', () => widget.goTab(1)),
          tile(Icons.quiz, const Color(0xFF6A55C8), 'কুইজ ও টেস্ট',
              'নিজেকে যাচাই করুন', () => push(const QuizPage())),
          tile(Icons.bookmark, const Color(0xFFB8860B), 'সংরক্ষিত শব্দ',
              'আপনার বুকমার্ক করা শব্দ', () => widget.goTab(4)),
          tile(Icons.apps, const Color(0xFFD0457F), 'কানেক্টেড অ্যাপস',
              'শেখার সহায়ক অ্যাপ', () => push(const ConnectedPage())),
          tile(Icons.language, const Color(0xFF3F8F4F), 'ওয়েবসাইট হাব',
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
          const BookShelf(
            limit: 4,
            emptyText: 'বই আসছে... ইন্টারনেট চালু রাখুন, লাইব্রেরি ট্যাবে বই দেখা যাবে।',
          ),
        ],
      ),
    );
  }
}
