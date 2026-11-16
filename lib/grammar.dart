import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'grammar_data.dart';
import 'vocab.dart';

class MyLesson {
  int? id;
  String title, intro, examples;
  MyLesson(
      {this.id, required this.title, this.intro = '', this.examples = ''});
}

class GrammarDb {
  static Future<Database> _open() async {
    final db = await Db.get();
    await db.execute(
        'CREATE TABLE IF NOT EXISTS my_grammar(id INTEGER PRIMARY KEY AUTOINCREMENT, title TEXT, intro TEXT, examples TEXT)');
    return db;
  }

  static Future<List<MyLesson>> all() async {
    final db = await _open();
    final rows = await db.query('my_grammar', orderBy: 'id DESC');
    return rows
        .map((m) => MyLesson(
              id: m['id'] as int,
              title: (m['title'] ?? '') as String,
              intro: (m['intro'] ?? '') as String,
              examples: (m['examples'] ?? '') as String,
            ))
        .toList();
  }

  static Future<void> insert(MyLesson l) async {
    final db = await _open();
    await db.insert('my_grammar',
        {'title': l.title, 'intro': l.intro, 'examples': l.examples});
  }

  static Future<void> update(MyLesson l) async {
    final db = await _open();
    await db.update('my_grammar',
        {'title': l.title, 'intro': l.intro, 'examples': l.examples},
        where: 'id = ?', whereArgs: [l.id]);
  }

  static Future<void> delete(int id) async {
    final db = await _open();
    await db.delete('my_grammar', where: 'id = ?', whereArgs: [id]);
  }
}

List<List<String>> parseExamples(String s) {
  final out = <List<String>>[];
  for (final raw in s.split('\n')) {
    final line = raw.trim();
    if (line.isEmpty) continue;
    final parts = line.split('|').map((e) => e.trim()).toList();
    while (parts.length < 3) {
      parts.add('');
    }
    out.add(parts.sublist(0, 3));
  }
  return out;
}

class LessonView extends StatelessWidget {
  final String title;
  final String intro;
  final List<List<String>> examples;
  const LessonView(
      {super.key,
      required this.title,
      required this.intro,
      required this.examples});

  Widget exampleCard(List<String> e) {
    final sub = <String>[];
    if (e[1].isNotEmpty) sub.add(e[1]);
    if (e[2].isNotEmpty) sub.add(e[2]);
    return Card(
      child: ListTile(
        title: Text(e[0],
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        subtitle: sub.isEmpty ? null : Text(sub.join('\n')),
        trailing: IconButton(
          icon: const Icon(Icons.volume_up),
          onPressed: () => speakKorean(e[0]),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final children = <Widget>[];
    if (intro.isNotEmpty) {
      children.add(Text(intro, style: const TextStyle(fontSize: 17, height: 1.5)));
      children.add(const SizedBox(height: 16));
    }
    if (examples.isNotEmpty) {
      children.add(const Text('উদাহরণ',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)));
      children.add(const SizedBox(height: 8));
      for (final e in examples) {
        children.add(exampleCard(e));
      }
    }
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: children,
      ),
    );
  }
}

class GrammarPage extends StatefulWidget {
  const GrammarPage({super.key});
  @override
  State<GrammarPage> createState() => _GrammarPageState();
}

class _GrammarPageState extends State<GrammarPage> {
  List<MyLesson> mine = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    List<MyLesson> r = [];
    try {
      r = await GrammarDb.all();
    } catch (_) {}
    if (!mounted) return;
    setState(() {
      mine = r;
      loading = false;
    });
  }

  void toast(String m) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));
  }

  Widget field(TextEditingController c, String label, int lines,
      {String? hint}) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: TextField(
        controller: c,
        minLines: lines == 1 ? 1 : 3,
        maxLines: lines,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }

  Future<void> edit([MyLesson? l]) async {
    final title = TextEditingController(text: l?.title ?? '');
    final intro = TextEditingController(text: l?.intro ?? '');
    final ex = TextEditingController(text: l?.examples ?? '');
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(l == null ? 'নতুন পাঠ' : 'পাঠ সম্পাদনা'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              field(title, 'পাঠের নাম *', 1),
              field(intro, 'ব্যাখ্যা (বাংলায়)', 6),
              field(
                ex,
                'উদাহরণ (প্রতি লাইনে একটি)',
                8,
                hint: 'কোরিয়ান | উচ্চারণ | অর্থ',
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
    if (title.text.trim().isEmpty) {
      toast('পাঠের নাম দিতে হবে');
      return;
    }
    if (l == null) {
      await GrammarDb.insert(MyLesson(
          title: title.text.trim(),
          intro: intro.text.trim(),
          examples: ex.text.trim()));
    } else {
      l.title = title.text.trim();
      l.intro = intro.text.trim();
      l.examples = ex.text.trim();
      await GrammarDb.update(l);
    }
    load();
  }

  Future<void> confirmDelete(MyLesson l) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('পাঠটি মুছবেন?'),
        content: Text(l.title),
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
      await GrammarDb.delete(l.id!);
      load();
    }
  }

  void openLesson(String title, String intro, List<List<String>> ex) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => LessonView(title: title, intro: intro, examples: ex),
      ),
    );
  }

  Widget header(String t) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(t,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
    );
  }

  Widget myTile(MyLesson l) {
    return ListTile(
      leading: const Icon(Icons.edit_note),
      title: Text(l.title),
      onTap: () => openLesson(l.title, l.intro, parseExamples(l.examples)),
      trailing: PopupMenuButton<String>(
        onSelected: (v) {
          if (v == 'edit') edit(l);
          if (v == 'del') confirmDelete(l);
        },
        itemBuilder: (c) => const [
          PopupMenuItem(value: 'edit', child: Text('সম্পাদনা')),
          PopupMenuItem(value: 'del', child: Text('মুছুন')),
        ],
      ),
    );
  }

  Widget builtInTile(Lesson l) {
    return ListTile(
      leading: const Icon(Icons.menu_book),
      title: Text(l.title),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => openLesson(l.title, l.intro, l.examples),
    );
  }

  @override
  Widget build(BuildContext context) {
    final children = <Widget>[];
    children.add(const Padding(
      padding: EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Text(
        'নিজের পাঠ যোগ করতে নিচের + চাপুন। বই বা ওয়েবসাইট থেকে লেখা কপি করে বসানো যায়।',
        style: TextStyle(color: Colors.grey),
      ),
    ));
    if (mine.isNotEmpty) {
      children.add(header('আমার পাঠ'));
      for (final l in mine) {
        children.add(myTile(l));
      }
    }
    children.add(header('মূল পাঠ'));
    for (final l in grammarLessons) {
      children.add(builtInTile(l));
    }
    return Scaffold(
      appBar: AppBar(title: const Text('গ্রামার সেন্টার')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => edit(),
        child: const Icon(Icons.add),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.only(bottom: 80),
              children: children,
            ),
    );
  }
}
