import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'vocab.dart';
import 'hub.dart';
import 'grammar_data.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});
  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  String q = '';
  List<Word> words = [];
  List<Lesson> lessons = [];
  List<SiteLink> links = [];
  bool searched = false;

  Future<void> run(String text) async {
    final t = text.trim();
    q = t;
    if (t.isEmpty) {
      setState(() {
        words = [];
        lessons = [];
        links = [];
        searched = false;
      });
      return;
    }
    final w = await Db.search(t);
    final low = t.toLowerCase();
    final l = grammarLessons
        .where((x) =>
            x.title.toLowerCase().contains(low) ||
            x.intro.toLowerCase().contains(low))
        .toList();
    List<SiteLink> s = [];
    try {
      final all = await HubDb.all();
      s = all
          .where((x) =>
              x.title.toLowerCase().contains(low) ||
              x.sub.toLowerCase().contains(low))
          .toList();
    } catch (_) {}
    if (!mounted || q != t) return;
    setState(() {
      words = w;
      lessons = l;
      links = s;
      searched = true;
    });
  }

  Widget head(String t) => Padding(
        padding: const EdgeInsets.fromLTRB(4, 16, 4, 6),
        child: Text(t,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      );

  void showWord(Word w) {
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(w.ko),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (w.pron.isNotEmpty) Text(w.pron),
            Text(w.bn, style: const TextStyle(fontSize: 20)),
            if (w.en.isNotEmpty) Text(w.en),
            if (w.ex.isNotEmpty) Text(w.ex),
          ],
        ),
        actions: [
          IconButton(
              icon: const Icon(Icons.volume_up),
              onPressed: () => speakKorean(w.ko)),
          TextButton(
              onPressed: () => Navigator.pop(c), child: const Text('বন্ধ')),
        ],
      ),
    );
  }

  void showLesson(Lesson l) {
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(l.title),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l.intro),
              const SizedBox(height: 12),
              for (final e in l.examples)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text('${e[0]}\n${e[1]}\n${e[2]}'),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(c), child: const Text('বন্ধ')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('সার্চ')),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: TextField(
                autofocus: true,
                onChanged: run,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search),
                  hintText: 'শব্দ, গ্রামার বা লিংক খুঁজুন',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            Expanded(
              child: !searched
                  ? const Center(child: Text('উপরে লিখে খুঁজুন'))
                  : (words.isEmpty && lessons.isEmpty && links.isEmpty)
                      ? const Center(child: Text('কিছু পাওয়া যায়নি'))
                      : ListView(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          children: [
                            if (words.isNotEmpty) head('শব্দ (${words.length})'),
                            for (final w in words.take(30))
                              ListTile(
                                title: Text(w.ko),
                                subtitle: Text(w.bn),
                                onTap: () => showWord(w),
                              ),
                            if (lessons.isNotEmpty)
                              head('গ্রামার (${lessons.length})'),
                            for (final l in lessons)
                              ListTile(
                                title: Text(l.title),
                                onTap: () => showLesson(l),
                              ),
                            if (links.isNotEmpty)
                              head('লিংক (${links.length})'),
                            for (final s in links)
                              ListTile(
                                title: Text(s.title),
                                subtitle: Text(s.sub),
                                onTap: () async {
                                  try {
                                    await launchUrl(Uri.parse(s.url),
                                        mode: LaunchMode.externalApplication);
                                  } catch (_) {}
                                },
                              ),
                            const SizedBox(height: 20),
                          ],
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
