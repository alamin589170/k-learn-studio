import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';
import 'words_data.dart';

class Word {
  int? id;
  String ko, pron, bn, en, ex;
  bool saved;
  Word(
      {this.id,
      required this.ko,
      this.pron = '',
      required this.bn,
      this.en = '',
      this.ex = '',
      this.saved = false});

  factory Word.fromMap(Map<String, Object?> m) => Word(
        id: m['id'] as int,
        ko: m['ko'] as String,
        pron: (m['pron'] ?? '') as String,
        bn: m['bn'] as String,
        en: (m['en'] ?? '') as String,
        ex: (m['ex'] ?? '') as String,
        saved: m['saved'] == 1,
      );

  Map<String, Object?> toMap() => {
        'ko': ko,
        'pron': pron,
        'bn': bn,
        'en': en,
        'ex': ex,
        'saved': saved ? 1 : 0,
      };
}

class Db {
  static Database? _db;

  static Future<Database> get() async {
    if (_db != null) return _db!;
    final path = p.join(await getDatabasesPath(), 'klearn.db');
    _db = await openDatabase(path, version: 1, onCreate: (db, v) async {
      await db.execute(
          'CREATE TABLE words(id INTEGER PRIMARY KEY AUTOINCREMENT, ko TEXT, pron TEXT, bn TEXT, en TEXT, ex TEXT, saved INTEGER DEFAULT 0)');
      final batch = db.batch();
      for (final r in allWords) {
        batch.insert('words', {
          'ko': r[0],
          'pron': r[1],
          'bn': r[2],
          'en': r[3],
          'ex': r[4],
          'saved': 0,
        });
      }
      await batch.commit(noResult: true);
    });
    return _db!;
  }

  static Future<List<Word>> search(String q, {bool savedOnly = false}) async {
    final db = await get();
    final where = <String>[];
    final args = <Object?>[];
    final t = q.trim();
    if (t.isNotEmpty) {
      where.add('(ko LIKE ? OR bn LIKE ? OR en LIKE ? OR pron LIKE ?)');
      args.addAll(List.filled(4, '%$t%'));
    }
    if (savedOnly) where.add('saved = 1');
    final rows = await db.query(
      'words',
      where: where.isEmpty ? null : where.join(' AND '),
      whereArgs: args.isEmpty ? null : args,
      orderBy: savedOnly ? 'id DESC' : 'id ASC',
    );
    return rows.map((m) => Word.fromMap(m)).toList();
  }

  static Future<void> insert(Word w) async {
    final db = await get();
    await db.insert('words', w.toMap());
  }

  static Future<void> update(Word w) async {
    final db = await get();
    await db.update('words', w.toMap(), where: 'id = ?', whereArgs: [w.id]);
  }

  static Future<void> delete(int id) async {
    final db = await get();
    await db.delete('words', where: 'id = ?', whereArgs: [id]);
  }
}

final FlutterTts _tts = FlutterTts();

Future<void> speakKorean(String text) async {
  try {
    await _tts.setLanguage('ko-KR');
    await _tts.setSpeechRate(0.4);
    await _tts.speak(text);
  } catch (_) {}
}

Widget? vocabPageFor(int i) {
  if (i == 5) return const WordListPage(savedOnly: false);
  if (i == 9) return const WordListPage(savedOnly: true);
  return null;
}

class WordListPage extends StatefulWidget {
  final bool savedOnly;
  const WordListPage({super.key, required this.savedOnly});
  @override
  State<WordListPage> createState() => _WordListPageState();
}

class _WordListPageState extends State<WordListPage> {
  List<Word> words = [];
  String q = '';

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    final r = await Db.search(q, savedOnly: widget.savedOnly);
    if (mounted) setState(() => words = r);
  }

  Future<void> toggleSave(Word w) async {
    w.saved = !w.saved;
    await Db.update(w);
    load();
  }

  Future<void> confirmDelete(Word w) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('শব্দটি মুছবেন?'),
        content: Text(w.ko),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(c, false),
              child: const Text('না')),
          FilledButton(
              onPressed: () => Navigator.pop(c, true),
              child: const Text('মুছুন')),
        ],
      ),
    );
    if (ok == true) {
      await Db.delete(w.id!);
      load();
    }
  }

  Widget field(TextEditingController c, String label) => Padding(
        padding: const EdgeInsets.only(top: 8),
        child: TextField(
          controller: c,
          decoration: InputDecoration(
              labelText: label, border: const OutlineInputBorder()),
        ),
      );

  Future<void> edit([Word? w]) async {
    final ko = TextEditingController(text: w?.ko ?? '');
    final pron = TextEditingController(text: w?.pron ?? '');
    final bn = TextEditingController(text: w?.bn ?? '');
    final en = TextEditingController(text: w?.en ?? '');
    final ex = TextEditingController(text: w?.ex ?? '');
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(w == null ? 'নতুন শব্দ' : 'শব্দ সম্পাদনা'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              field(ko, 'কোরিয়ান শব্দ *'),
              field(pron, 'বাংলা উচ্চারণ'),
              field(bn, 'বাংলা অর্থ *'),
              field(en, 'ইংরেজি অর্থ'),
              field(ex, 'উদাহরণ বাক্য'),
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
    if (ko.text.trim().isEmpty || bn.text.trim().isEmpty) return;
    if (w == null) {
      await Db.insert(Word(
        ko: ko.text.trim(),
        pron: pron.text.trim(),
        bn: bn.text.trim(),
        en: en.text.trim(),
        ex: ex.text.trim(),
        saved: widget.savedOnly,
      ));
    } else {
      w.ko = ko.text.trim();
      w.pron = pron.text.trim();
      w.bn = bn.text.trim();
      w.en = en.text.trim();
      w.ex = ex.text.trim();
      await Db.update(w);
    }
    load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: Text(widget.savedOnly ? 'আমার শব্দ' : 'কোরিয়ান-বাংলা অভিধান')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => edit(),
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'কোরিয়ান, বাংলা বা ইংরেজিতে খুঁজুন',
                border: OutlineInputBorder(),
              ),
              onChanged: (v) {
                q = v;
                load();
              },
            ),
          ),
          Expanded(
            child: words.isEmpty
                ? Center(
                    child: Text(
                      widget.savedOnly
                          ? 'কোনো সংরক্ষিত শব্দ নেই।\nঅভিধান থেকে ⭐ দিন বা + চেপে নতুন শব্দ যোগ করুন।'
                          : 'কোনো শব্দ পাওয়া যায়নি।',
                      textAlign: TextAlign.center,
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 80),
                    itemCount: words.length,
                    itemBuilder: (context, i) {
                      final w = words[i];
                      return Card(
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(w.ko,
                                  style: const TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold)),
                              if (w.pron.isNotEmpty)
                                Text(w.pron,
                                    style: const TextStyle(
                                        fontStyle: FontStyle.italic)),
                              const SizedBox(height: 4),
                              Text(w.bn, style: const TextStyle(fontSize: 18)),
                              if (w.en.isNotEmpty) Text(w.en),
                              if (w.ex.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 6),
                                  child: Text(w.ex,
                                      style: const TextStyle(
                                          color: Colors.grey)),
                                ),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.volume_up),
                                    onPressed: () => speakKorean(w.ko),
                                  ),
                                  IconButton(
                                    icon: Icon(
                                        w.saved ? Icons.star : Icons.star_border,
                                        color: w.saved ? Colors.amber : null),
                                    onPressed: () => toggleSave(w),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.edit),
                                    onPressed: () => edit(w),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline),
                                    onPressed: () => confirmDelete(w),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
