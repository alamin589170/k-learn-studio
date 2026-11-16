import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'exam_data.dart';
import 'vocab.dart';
import 'words_data.dart';

class ExamQ {
  final String q;
  final String ans;
  final List<String> opts;
  final String exp;
  final String? speak;
  ExamQ(this.q, this.ans, this.opts, this.exp, {this.speak});
}

class ExamDb {
  static Future<void> _ensure() async {
    final db = await Db.get();
    await db.execute(
        'CREATE TABLE IF NOT EXISTS exam_q(id INTEGER PRIMARY KEY AUTOINCREMENT, q TEXT NOT NULL, a TEXT NOT NULL, w1 TEXT NOT NULL, w2 TEXT NOT NULL, w3 TEXT NOT NULL, exp TEXT NOT NULL)');
    await db.execute(
        'CREATE TABLE IF NOT EXISTS exam_result(id INTEGER PRIMARY KEY AUTOINCREMENT, ts INTEGER NOT NULL, score INTEGER NOT NULL, total INTEGER NOT NULL, secs INTEGER NOT NULL)');
  }

  static Future<List<Map<String, Object?>>> myQ() async {
    await _ensure();
    final db = await Db.get();
    return db.query('exam_q', orderBy: 'id DESC');
  }

  static Future<void> addQ(List<String> v) async {
    await _ensure();
    final db = await Db.get();
    await db.insert('exam_q', {
      'q': v[0],
      'a': v[1],
      'w1': v[2],
      'w2': v[3],
      'w3': v[4],
      'exp': v[5],
    });
  }

  static Future<void> delQ(int id) async {
    await _ensure();
    final db = await Db.get();
    await db.delete('exam_q', where: 'id = ?', whereArgs: [id]);
  }

  static Future<void> addResult(int score, int total, int secs) async {
    await _ensure();
    final db = await Db.get();
    await db.insert('exam_result', {
      'ts': DateTime.now().millisecondsSinceEpoch,
      'score': score,
      'total': total,
      'secs': secs,
    });
  }

  static Future<List<Map<String, Object?>>> results() async {
    await _ensure();
    final db = await Db.get();
    return db.query('exam_result', orderBy: 'id DESC', limit: 10);
  }
}

Future<List<ExamQ>> buildTest() async {
  final rnd = Random();
  final words = (allWords as List)
      .map((e) => List<String>.from(e as List))
      .where((w) => w.length >= 3 && w[0].isNotEmpty && w[2].isNotEmpty)
      .toList();
  final pool = <ExamQ>[];
  for (final b in examBank) {
    final o = [b[1], b[2], b[3], b[4]]..shuffle(rnd);
    pool.add(ExamQ(b[0], b[1], o, b[5]));
  }
  for (final r in await ExamDb.myQ()) {
    final a = r['a'] as String;
    final o = [a, r['w1'] as String, r['w2'] as String, r['w3'] as String]
      ..shuffle(rnd);
    pool.add(ExamQ(r['q'] as String, a, o, r['exp'] as String));
  }
  pool.shuffle(rnd);
  words.shuffle(rnd);
  var wi = 0;

  ExamQ wordQ(List<String> w, bool listen) {
    final opts = <String>{w[2]};
    var g = 0;
    while (opts.length < 4 && g < 300 && words.length >= 4) {
      g++;
      opts.add(words[rnd.nextInt(words.length)][2]);
    }
    final list = opts.toList()..shuffle(rnd);
    return ExamQ(
      listen ? 'শুনুন ও সঠিক অর্থ বাছুন' : '"${w[0]}" এর অর্থ কী?',
      w[2],
      list,
      '${w[0]} = ${w[2]}',
      speak: listen ? w[0] : null,
    );
  }

  final reading = <ExamQ>[];
  for (var i = 0; i < 20 && wi < words.length; i++) {
    reading.add(wordQ(words[wi++], false));
  }
  for (final p in pool) {
    if (reading.length >= 30) break;
    reading.add(p);
  }
  while (reading.length < 30 && wi < words.length) {
    reading.add(wordQ(words[wi++], false));
  }
  reading.shuffle(rnd);
  final listening = <ExamQ>[];
  for (var i = 0; i < 10 && wi < words.length; i++) {
    listening.add(wordQ(words[wi++], true));
  }
  return [...reading, ...listening];
}

class ExamPage extends StatefulWidget {
  const ExamPage({super.key});
  @override
  State<ExamPage> createState() => _ExamPageState();
}

class _ExamPageState extends State<ExamPage> {
  List<Map<String, Object?>> results = [];
  int myCount = 0;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    final r = await ExamDb.results();
    final m = await ExamDb.myQ();
    if (!mounted) return;
    setState(() {
      results = r;
      myCount = m.length;
      loading = false;
    });
  }

  String fmt(int ts) {
    final d = DateTime.fromMillisecondsSinceEpoch(ts);
    final h = d.hour.toString().padLeft(2, '0');
    final m = d.minute.toString().padLeft(2, '0');
    return '${d.day}/${d.month} $h:$m';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('TOPIK / EPS টেস্ট')),
      body: SafeArea(
        child: loading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  const Text('মডেল টেস্ট',
                      style:
                          TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  const Text(
                      '৪০টি প্রশ্ন, ২৫ মিনিট। শেষ ১০টি শোনার প্রশ্ন (আওয়াজ চালু রাখুন)। অনুশীলনের জন্য, আসল পরীক্ষার হুবহু নয়।'),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 56,
                    child: ElevatedButton(
                      onPressed: () async {
                        await Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const ExamRunPage()));
                        load();
                      },
                      child: const Text('টেস্ট শুরু করুন',
                          style: TextStyle(fontSize: 18)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 52,
                    child: OutlinedButton(
                      onPressed: () async {
                        await Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const MyQuestionsPage()));
                        load();
                      },
                      child: Text('আমার প্রশ্ন ($myCount)',
                          style: const TextStyle(fontSize: 18)),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text('আগের ফল',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  if (results.isEmpty) const Text('এখনো কোনো টেস্ট দেননি।'),
                  for (final r in results)
                    Card(
                      child: ListTile(
                        leading: const Icon(Icons.assignment_turned_in),
                        title: Text('${r['score']} / ${r['total']}',
                            style: const TextStyle(
                                fontSize: 20, fontWeight: FontWeight.bold)),
                        subtitle: Text(
                            '${fmt(r['ts'] as int)}  •  ${((r['secs'] as int) / 60).ceil()} মিনিট'),
                      ),
                    ),
                ],
              ),
      ),
    );
  }
}

class ExamRunPage extends StatefulWidget {
  const ExamRunPage({super.key});
  @override
  State<ExamRunPage> createState() => _ExamRunPageState();
}

class _ExamRunPageState extends State<ExamRunPage> {
  static const int total = 25 * 60;
  List<ExamQ> qs = [];
  List<String?> ans = [];
  int i = 0;
  int left = total;
  Timer? t;
  bool loading = true;
  bool done = false;
  int score = 0;
  int used = 0;

  @override
  void initState() {
    super.initState();
    start();
  }

  @override
  void dispose() {
    t?.cancel();
    super.dispose();
  }

  Future<void> start() async {
    final q = await buildTest();
    if (!mounted) return;
    setState(() {
      qs = q;
      ans = List<String?>.filled(q.length, null);
      loading = false;
    });
    t = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted || done) return;
      if (left <= 1) {
        setState(() => left = 0);
        finish();
      } else {
        setState(() => left--);
      }
    });
    speakCur();
  }

  void speakCur() {
    if (qs.isNotEmpty && i < qs.length && qs[i].speak != null) {
      speakKorean(qs[i].speak!);
    }
  }

  Future<void> finish() async {
    if (done) return;
    t?.cancel();
    var s = 0;
    for (var k = 0; k < qs.length; k++) {
      if (ans[k] == qs[k].ans) s++;
    }
    final u = total - left;
    setState(() {
      done = true;
      score = s;
      used = u;
    });
    try {
      await ExamDb.addResult(s, qs.length, u);
    } catch (_) {}
  }

  void go(int d) {
    final n = i + d;
    if (n < 0) return;
    if (n >= qs.length) {
      finish();
      return;
    }
    setState(() => i = n);
    speakCur();
  }

  String clock(int s) {
    final m = (s ~/ 60).toString().padLeft(2, '0');
    final r = (s % 60).toString().padLeft(2, '0');
    return '$m:$r';
  }

  Widget question() {
    final q = qs[i];
    final cs = Theme.of(context).colorScheme;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            Text('প্রশ্ন ${i + 1} / ${qs.length}',
                style: const TextStyle(fontSize: 16)),
            const Spacer(),
            Chip(
              avatar: const Icon(Icons.timer, size: 18),
              label: Text(clock(left),
                  style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        LinearProgressIndicator(value: (i + 1) / qs.length),
        const SizedBox(height: 20),
        Text(q.q,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        if (q.speak != null)
          Center(
            child: IconButton(
              iconSize: 44,
              icon: const Icon(Icons.volume_up),
              onPressed: () => speakKorean(q.speak!),
            ),
          ),
        const SizedBox(height: 16),
        for (final o in q.opts)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                  backgroundColor:
                      ans[i] == o ? cs.primaryContainer : null,
                ),
                onPressed: () => setState(() => ans[i] = o),
                child: Text(o,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 18)),
              ),
            ),
          ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: i == 0 ? null : () => go(-1),
                child: const Text('আগের'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton(
                onPressed: () => go(1),
                child: Text(i + 1 >= qs.length ? 'জমা দিন' : 'পরের'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget result() {
    final wrong = <int>[];
    for (var k = 0; k < qs.length; k++) {
      if (ans[k] != qs[k].ans) wrong.add(k);
    }
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('টেস্ট শেষ!',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Text('স্কোর: $score / ${qs.length}',
            textAlign: TextAlign.center, style: const TextStyle(fontSize: 22)),
        Text('সময় লেগেছে: ${clock(used)}',
            textAlign: TextAlign.center, style: const TextStyle(fontSize: 16)),
        const SizedBox(height: 16),
        if (wrong.isNotEmpty)
          const Text('ভুল বা বাদ পড়া প্রশ্ন',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        for (final k in wrong)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                      '${k + 1}. ${qs[k].speak != null ? '🔊 ${qs[k].speak}' : qs[k].q}',
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text('আপনার উত্তর: ${ans[k] ?? 'দেননি'}'),
                  Text('সঠিক উত্তর: ${qs[k].ans}',
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  if (qs[k].exp.isNotEmpty) Text(qs[k].exp),
                ],
              ),
            ),
          ),
        const SizedBox(height: 12),
        FilledButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('ফিরে যান'),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget body;
    if (loading) {
      body = const Center(child: CircularProgressIndicator());
    } else if (done) {
      body = result();
    } else {
      body = question();
    }
    return Scaffold(
      appBar: AppBar(title: const Text('মডেল টেস্ট')),
      body: SafeArea(child: body),
    );
  }
}

class MyQuestionsPage extends StatefulWidget {
  const MyQuestionsPage({super.key});
  @override
  State<MyQuestionsPage> createState() => _MyQuestionsPageState();
}

class _MyQuestionsPageState extends State<MyQuestionsPage> {
  List<Map<String, Object?>> rows = [];

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    final r = await ExamDb.myQ();
    if (!mounted) return;
    setState(() => rows = r);
  }

  Widget field(TextEditingController c, String label) => Padding(
        padding: const EdgeInsets.only(top: 8),
        child: TextField(
          controller: c,
          decoration: InputDecoration(
              labelText: label, border: const OutlineInputBorder()),
        ),
      );

  Future<void> add() async {
    final q = TextEditingController();
    final a = TextEditingController();
    final w1 = TextEditingController();
    final w2 = TextEditingController();
    final w3 = TextEditingController();
    final e = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('নতুন প্রশ্ন'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              field(q, 'প্রশ্ন *'),
              field(a, 'সঠিক উত্তর *'),
              field(w1, 'ভুল উত্তর ১ *'),
              field(w2, 'ভুল উত্তর ২ *'),
              field(w3, 'ভুল উত্তর ৩ *'),
              field(e, 'ব্যাখ্যা (ঐচ্ছিক)'),
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
    final v = [q, a, w1, w2, w3, e].map((x) => x.text.trim()).toList();
    if (v.sublist(0, 5).any((x) => x.isEmpty)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('* চিহ্নিত ঘরগুলো পূরণ করুন')));
      return;
    }
    await ExamDb.addQ(v);
    load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('আমার প্রশ্ন')),
      floatingActionButton:
          FloatingActionButton(onPressed: add, child: const Icon(Icons.add)),
      body: SafeArea(
        child: rows.isEmpty
            ? const Center(child: Text('এখনো কোনো প্রশ্ন যোগ করেননি।'))
            : ListView(
                padding: const EdgeInsets.all(12),
                children: [
                  for (final r in rows)
                    Card(
                      child: ListTile(
                        title: Text(r['q'] as String),
                        subtitle: Text('উত্তর: ${r['a']}'),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () async {
                            await ExamDb.delQ(r['id'] as int);
                            load();
                          },
                        ),
                      ),
                    ),
                ],
              ),
      ),
    );
  }
}
