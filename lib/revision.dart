import 'package:flutter/material.dart';
import 'vocab.dart';

class RevisionPage extends StatefulWidget {
  const RevisionPage({super.key});
  @override
  State<RevisionPage> createState() => _RevisionPageState();
}

class _RevisionPageState extends State<RevisionPage> {
  static const List<int> _days = [0, 1, 2, 4, 8, 16];
  final Map<int, int> _box = {};
  List<Word> _queue = [];
  int _i = 0;
  int _known = 0;
  int _total = 0;
  bool _show = false;
  bool _loading = true;
  bool _done = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final db = await Db.get();
    await db.execute(
        'CREATE TABLE IF NOT EXISTS revision(word_id INTEGER PRIMARY KEY, box INTEGER NOT NULL, due INTEGER NOT NULL)');
    final all = await Db.search('');
    final rows = await db.query('revision');
    final now = DateTime.now().millisecondsSinceEpoch;
    final dueMap = <int, int>{};
    _box.clear();
    for (final r in rows) {
      final id = r['word_id'] as int;
      _box[id] = r['box'] as int;
      dueMap[id] = r['due'] as int;
    }
    final due = <Word>[];
    final fresh = <Word>[];
    for (final w in all) {
      final id = w.id;
      if (id == null) continue;
      final d = dueMap[id];
      if (d == null) {
        fresh.add(w);
      } else if (d <= now) {
        due.add(w);
      }
    }
    due.shuffle();
    final q = <Word>[...due, ...fresh].take(10).toList();
    if (!mounted) return;
    setState(() {
      _queue = q;
      _i = 0;
      _known = 0;
      _total = 0;
      _show = false;
      _done = false;
      _loading = false;
    });
  }

  Future<void> _answer(bool known) async {
    final w = _queue[_i];
    final id = w.id!;
    final box = _box[id] ?? 0;
    final nb = known ? (box + 1 > 5 ? 5 : box + 1) : 0;
    final now = DateTime.now().millisecondsSinceEpoch;
    final due = known ? now + _days[nb] * 86400000 : now + 600000;
    _box[id] = nb;
    final db = await Db.get();
    await db.rawInsert(
        'INSERT OR REPLACE INTO revision(word_id, box, due) VALUES(?,?,?)',
        [id, nb, due]);
    if (!mounted) return;
    setState(() {
      _total++;
      if (known) {
        _known++;
      } else if (_queue.length < 20) {
        _queue.add(w);
      }
      if (_i + 1 >= _queue.length) {
        _done = true;
      } else {
        _i++;
        _show = false;
      }
    });
  }

  Widget _msg(String title, String sub, {bool again = false}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(title,
                textAlign: TextAlign.center,
                style:
                    const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Text(sub,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 18)),
            if (again) ...[
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  setState(() => _loading = true);
                  _load();
                },
                child: const Text('আবার দেখুন'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _card() {
    final w = _queue[_i];
    return Padding(
      padding: const EdgeInsets.all(16),
      child: ListView(
        children: [
          Text('শব্দ ${_i + 1} / ${_queue.length}',
              style: const TextStyle(fontSize: 16)),
          const SizedBox(height: 8),
          LinearProgressIndicator(value: (_i + 1) / _queue.length),
          const SizedBox(height: 32),
          Center(
            child: Text(w.ko,
                textAlign: TextAlign.center,
                style:
                    const TextStyle(fontSize: 40, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 8),
          Center(
            child: IconButton(
              icon: const Icon(Icons.volume_up, size: 32),
              onPressed: () => speakKorean(w.ko),
            ),
          ),
          const SizedBox(height: 16),
          if (!_show)
            SizedBox(
              height: 56,
              child: ElevatedButton(
                onPressed: () => setState(() => _show = true),
                child: const Text('অর্থ দেখুন', style: TextStyle(fontSize: 18)),
              ),
            )
          else ...[
            if (w.pron.isNotEmpty)
              Text(w.pron,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 8),
            Text(w.bn,
                textAlign: TextAlign.center,
                style:
                    const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
            if (w.en.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(w.en,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 18)),
            ],
            if (w.ex.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(w.ex,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 18)),
            ],
            const SizedBox(height: 28),
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 56,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red.shade300),
                      onPressed: () => _answer(false),
                      child: const Text('জানি না',
                          style: TextStyle(fontSize: 18)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SizedBox(
                    height: 56,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green.shade300),
                      onPressed: () => _answer(true),
                      child:
                          const Text('জানি', style: TextStyle(fontSize: 18)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget body;
    if (_loading) {
      body = const Center(child: CircularProgressIndicator());
    } else if (_queue.isEmpty) {
      body = _msg('আজকের রিভিশন শেষ!', 'এখন পড়ার মতো কোনো শব্দ নেই। পরে আবার আসুন।',
          again: true);
    } else if (_done) {
      body = _msg('রিভিশন শেষ!', 'জানা: $_known / $_total উত্তর', again: true);
    } else {
      body = _card();
    }
    return Scaffold(
      appBar: AppBar(title: const Text('স্মার্ট রিভিশন')),
      body: SafeArea(child: body),
    );
  }
}
