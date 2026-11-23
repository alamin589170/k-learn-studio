import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'connected.dart';
import 'flashcards.dart';
import 'hub.dart';
import 'quiz.dart';
import 'vocab.dart';

class LibraryPage extends StatefulWidget {
  const LibraryPage({super.key});
  @override
  State<LibraryPage> createState() => _LibraryPageState();
}

class _LibraryPageState extends State<LibraryPage> {
  List<Map<String, Object?>> books = [];

  static const List<List<Color>> _covers = [
    [Color(0xFF0984E3), Color(0xFF74B9FF)],
    [Color(0xFF00B894), Color(0xFF55EFC4)],
    [Color(0xFF6C5CE7), Color(0xFFA29BFE)],
    [Color(0xFFE17055), Color(0xFFFAB1A0)],
    [Color(0xFFE84393), Color(0xFFFD79A8)],
  ];

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> _ensure() async {
    final db = await Db.get();
    await db.execute(
        'CREATE TABLE IF NOT EXISTS books(id INTEGER PRIMARY KEY AUTOINCREMENT, title TEXT NOT NULL, url TEXT NOT NULL)');
  }

  Future<void> load() async {
    await _ensure();
    final db = await Db.get();
    final r = await db.query('books', orderBy: 'id DESC');
    if (!mounted) return;
    setState(() => books = r);
  }

  Future<void> add() async {
    final t = TextEditingController();
    final u = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('নতুন PDF বই'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: t,
                decoration: const InputDecoration(
                    labelText: 'বইয়ের নাম *', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: u,
                keyboardType: TextInputType.url,
                decoration: const InputDecoration(
                    labelText: 'PDF-এর লিংক *',
                    hintText: 'Google Drive বা অন্য লিংক',
                    border: OutlineInputBorder()),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(c, false),
              child: const Text('বাতিল')),
          FilledButton(
              onPressed: () => Navigator.pop(c, true),
              child: const Text('সংরক্ষণ')),
        ],
      ),
    );
    if (ok != true) return;
    final title = t.text.trim();
    var url = u.text.trim();
    if (title.isEmpty || url.isEmpty) return;
    if (!url.startsWith('http')) url = 'https://$url';
    final db = await Db.get();
    await db.insert('books', {'title': title, 'url': url});
    load();
  }

  Future<void> open(String url) async {
    var okOpen = false;
    try {
      okOpen = await launchUrl(Uri.parse(url),
          mode: LaunchMode.externalApplication);
    } catch (_) {}
    if (!okOpen && mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('লিংকটি খোলা যায়নি')));
    }
  }

  Future<void> remove(Map<String, Object?> b) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('বইটি তালিকা থেকে সরাবেন?'),
        content: Text(b['title'] as String),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(c, false),
              child: const Text('না')),
          FilledButton(
              onPressed: () => Navigator.pop(c, true),
              child: const Text('সরান')),
        ],
      ),
    );
    if (ok != true) return;
    final db = await Db.get();
    await db.delete('books', where: 'id = ?', whereArgs: [b['id']]);
    load();
  }

  Widget cover(Map<String, Object?> b) {
    final id = b['id'] as int;
    final col = _covers[id % _covers.length];
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () => open(b['url'] as String),
      onLongPress: () => remove(b),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: col),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.picture_as_pdf, color: Colors.white, size: 34),
            const Spacer(),
            Text(b['title'] as String,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            const Text('PDF · চাপুন',
                style: TextStyle(color: Colors.white70, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget tile(IconData icon, String title, String sub, Widget page) {
    return Card(
      child: ListTile(
        leading: Icon(icon, size: 30),
        title: Text(title,
            style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(sub),
        trailing: const Icon(Icons.chevron_right),
        onTap: () =>
            Navigator.push(context, MaterialPageRoute(builder: (_) => page)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            const Expanded(
              child: Text('PDF বই সংগ্রহ',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            ),
            FilledButton.icon(
              onPressed: add,
              icon: const Icon(Icons.add),
              label: const Text('বই যোগ'),
            ),
          ],
        ),
        const SizedBox(height: 4),
        const Text('লিংক দিয়ে বই যোগ করুন। চাপলে PDF খুলবে, চেপে ধরলে সরবে।',
            style: TextStyle(fontSize: 13)),
        const SizedBox(height: 12),
        if (books.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Text('এখনো কোনো বই যোগ করেননি।'),
            ),
          )
        else
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 0.85,
            children: [for (final b in books) cover(b)],
          ),
        const SizedBox(height: 24),
        const Text('অনুশীলন ও লিংক',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        tile(Icons.quiz, 'কুইজ ও টেস্ট', 'নিজেকে যাচাই', const QuizPage()),
        tile(Icons.style, '3D ফ্ল্যাশকার্ড', 'শব্দ, ছবি ও অডিও',
            const FlashcardPage()),
        tile(Icons.language, 'ওয়েবসাইট হাব', 'দরকারি লিংক', const HubPage()),
        tile(Icons.apps, 'কানেক্টেড অ্যাপস', 'সমর্থিত সার্ভিস',
            const ConnectedPage()),
      ],
    );
  }
}
