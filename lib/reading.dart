import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:sqflite/sqflite.dart';
import 'reading_data.dart';
import 'vocab.dart';

class MyText {
  int? id;
  String title, body;
  MyText({this.id, required this.title, this.body = ''});
}

class ReadingDb {
  static Future<Database> _open() async {
    final db = await Db.get();
    await db.execute(
        'CREATE TABLE IF NOT EXISTS my_reading(id INTEGER PRIMARY KEY AUTOINCREMENT, title TEXT, body TEXT)');
    return db;
  }

  static Future<List<MyText>> all() async {
    final db = await _open();
    final rows = await db.query('my_reading', orderBy: 'id DESC');
    return rows
        .map((m) => MyText(
              id: m['id'] as int,
              title: (m['title'] ?? '') as String,
              body: (m['body'] ?? '') as String,
            ))
        .toList();
  }

  static Future<void> insert(MyText t) async {
    final db = await _open();
    await db.insert('my_reading', {'title': t.title, 'body': t.body});
  }

  static Future<void> delete(int id) async {
    final db = await _open();
    await db.delete('my_reading', where: 'id = ?', whereArgs: [id]);
  }
}

List<List<String>> parseReadLines(String s) {
  final out = <List<String>>[];
  for (final raw in s.split('\n')) {
    final line = raw.trim();
    if (line.isEmpty) continue;
    final i = line.indexOf('|');
    if (i < 0) {
      out.add(['', line, '']);
    } else {
      out.add(['', line.substring(0, i).trim(), line.substring(i + 1).trim()]);
    }
  }
  return out;
}

class PassageView extends StatefulWidget {
  final String title;
  final List<List<String>> lines;
  const PassageView({super.key, required this.title, required this.lines});
  @override
  State<PassageView> createState() => _PassageViewState();
}

class _PassageViewState extends State<PassageView> {
  final FlutterTts tts = FlutterTts();
  bool showBn = true;
  bool playing = false;
  int current = -1;

  @override
  void initState() {
    super.initState();
    initTts();
  }

  Future<void> initTts() async {
    try {
      await tts.setLanguage('ko-KR');
      await tts.setSpeechRate(0.4);
      await tts.awaitSpeakCompletion(true);
    } catch (_) {}
  }

  @override
  void dispose() {
    playing = false;
    tts.stop();
    super.dispose();
  }

  Future<void> playAll() async {
    if (playing) {
      setState(() {
        playing = false;
        current = -1;
      });
      await tts.stop();
      return;
    }
    setState(() => playing = true);
    for (var i = 0; i < widget.lines.length; i++) {
      if (!playing || !mounted) break;
      setState(() => current = i);
      try {
        await tts.speak(widget.lines[i][1]);
      } catch (_) {}
    }
    if (mounted) {
      setState(() {
        playing = false;
        current = -1;
      });
    }
  }

  Widget lineCard(int i) {
    final l = widget.lines[i];
    final isCurrent = i == current;
    final texts = <Widget>[
      Text(l[1],
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
    ];
    if (showBn && l[2].isNotEmpty) {
      texts.add(Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Text(l[2], style: const TextStyle(fontSize: 16)),
      ));
    }
    final row = <Widget>[];
    if (l[0].isNotEmpty) {
      row.add(Padding(
        padding: const EdgeInsets.only(right: 10),
        child: CircleAvatar(radius: 14, child: Text(l[0])),
      ));
    }
    row.add(Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: texts,
      ),
    ));
    row.add(IconButton(
      icon: const Icon(Icons.volume_up),
      onPressed: () => speakKorean(l[1]),
    ));
    return Card(
      color: isCurrent ? Theme.of(context).colorScheme.primaryContainer : null,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: row,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          IconButton(
            icon: Icon(showBn ? Icons.visibility : Icons.visibility_off),
            tooltip: 'অনুবাদ দেখান/লুকান',
            onPressed: () => setState(() => showBn = !showBn),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: playAll,
        icon: Icon(playing ? Icons.stop : Icons.play_arrow),
        label: Text(playing ? 'থামান' : 'সব শুনুন'),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 90),
        itemCount: widget.lines.length,
        itemBuilder: (context, i) => lineCard(i),
      ),
    );
  }
}

class ReadingPage extends StatefulWidget {
  const ReadingPage({super.key});
  @override
  State<ReadingPage> createState() => _ReadingPageState();
}

class _ReadingPageState extends State<ReadingPage> {
  List<MyText> mine = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    List<MyText> r = [];
    try {
      r = await ReadingDb.all();
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
        minLines: lines == 1 ? 1 : 4,
        maxLines: lines,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }

  Future<void> addText() async {
    final title = TextEditingController();
    final body = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('নিজের পাঠ্য যোগ'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              field(title, 'পাঠের নাম *', 1),
              field(body, 'লেখা (প্রতি লাইনে একটি) *', 10,
                  hint: 'কোরিয়ান | বাংলা অনুবাদ'),
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
    if (title.text.trim().isEmpty || body.text.trim().isEmpty) {
      toast('নাম ও লেখা দিতে হবে');
      return;
    }
    await ReadingDb.insert(
        MyText(title: title.text.trim(), body: body.text.trim()));
    load();
  }

  Future<void> confirmDelete(MyText t) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('পাঠ্যটি মুছবেন?'),
        content: Text(t.title),
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
      await ReadingDb.delete(t.id!);
      load();
    }
  }

  void open(String title, List<List<String>> lines) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PassageView(title: title, lines: lines),
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

  Widget myTile(MyText t) {
    return ListTile(
      leading: const Icon(Icons.edit_note),
      title: Text(t.title),
      onTap: () => open(t.title, parseReadLines(t.body)),
      trailing: IconButton(
        icon: const Icon(Icons.delete_outline),
        onPressed: () => confirmDelete(t),
      ),
    );
  }

  Widget builtInTile(ReadPassage p) {
    return ListTile(
      leading: Icon(p.kind == 'কথোপকথন' ? Icons.forum : Icons.article),
      title: Text(p.title),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => open(p.title, p.lines),
    );
  }

  @override
  Widget build(BuildContext context) {
    final children = <Widget>[];
    if (mine.isNotEmpty) {
      children.add(header('আমার পাঠ্য'));
      for (final t in mine) {
        children.add(myTile(t));
      }
    }
    children.add(header('কথোপকথন'));
    for (final p in readPassages) {
      if (p.kind == 'কথোপকথন') children.add(builtInTile(p));
    }
    children.add(header('অনুচ্ছেদ'));
    for (final p in readPassages) {
      if (p.kind == 'অনুচ্ছেদ') children.add(builtInTile(p));
    }
    return Scaffold(
      appBar: AppBar(title: const Text('পড়া ও শোনা')),
      floatingActionButton: FloatingActionButton(
        onPressed: addText,
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
