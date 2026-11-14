import 'package:flutter/material.dart';
import 'vocab.dart';

class PlannerPage extends StatefulWidget {
  const PlannerPage({super.key});
  @override
  State<PlannerPage> createState() => _PlannerPageState();
}

class _PlannerPageState extends State<PlannerPage> {
  bool _loading = true;
  int _goal = 25;
  int _doneToday = 0;
  int _streak = 0;
  int _remaining = 0;
  List<Word> _queue = [];
  int _i = 0;
  bool _show = false;
  bool _running = false;

  String _fmt(DateTime n) =>
      '${n.year}-${n.month.toString().padLeft(2, '0')}-${n.day.toString().padLeft(2, '0')}';
  String _today() => _fmt(DateTime.now());
  String _yesterday() =>
      _fmt(DateTime.now().subtract(const Duration(days: 1)));

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _ensure() async {
    final db = await Db.get();
    await db.execute(
        'CREATE TABLE IF NOT EXISTS revision(word_id INTEGER PRIMARY KEY, box INTEGER NOT NULL, due INTEGER NOT NULL)');
    await db.execute(
        'CREATE TABLE IF NOT EXISTS planner(k TEXT PRIMARY KEY, v TEXT NOT NULL)');
  }

  Future<String?> _get(String k) async {
    final db = await Db.get();
    final r = await db.query('planner', where: 'k = ?', whereArgs: [k]);
    if (r.isEmpty) return null;
    return r.first['v'] as String;
  }

  Future<void> _set(String k, String v) async {
    final db = await Db.get();
    await db.rawInsert(
        'INSERT OR REPLACE INTO planner(k, v) VALUES(?,?)', [k, v]);
  }

  Future<void> _load() async {
    await _ensure();
    final goal = int.tryParse(await _get('goal') ?? '') ?? 25;
    final day = await _get('day');
    var done = int.tryParse(await _get('done') ?? '') ?? 0;
    var streak = int.tryParse(await _get('streak') ?? '') ?? 0;
    final lastMet = await _get('last_met');
    if (day != _today()) {
      done = 0;
      await _set('day', _today());
      await _set('done', '0');
    }
    if (lastMet != null && lastMet != _today() && lastMet != _yesterday()) {
      streak = 0;
      await _set('streak', '0');
    }
    final db = await Db.get();
    final all = await Db.search('');
    final rows = await db.query('revision');
    final started = rows.map((r) => r['word_id'] as int).toSet();
    final fresh =
        all.where((w) => w.id != null && !started.contains(w.id)).toList();
    final need = goal - done;
    if (!mounted) return;
    setState(() {
      _goal = goal;
      _doneToday = done;
      _streak = streak;
      _remaining = fresh.length;
      _queue = fresh.take(need < 0 ? 0 : need).toList();
      _i = 0;
      _show = false;
      _running = false;
      _loading = false;
    });
  }

  Future<void> _changeGoal(int d) async {
    final g = (_goal + d).clamp(5, 100);
    await _set('goal', '$g');
    await _load();
  }

  Future<void> _learned() async {
    final w = _queue[_i];
    final db = await Db.get();
    final now = DateTime.now().millisecondsSinceEpoch;
    await db.rawInsert(
        'INSERT OR REPLACE INTO revision(word_id, box, due) VALUES(?,?,?)',
        [w.id!, 1, now + 86400000]);
    final done = _doneToday + 1;
    await _set('done', '$done');
    await _set('day', _today());
    var streak = _streak;
    if (done == _goal) {
      final lastMet = await _get('last_met');
      if (lastMet != _today()) {
        streak = (lastMet == _yesterday()) ? streak + 1 : 1;
        await _set('streak', '$streak');
        await _set('last_met', _today());
      }
    }
    if (!mounted) return;
    setState(() {
      _doneToday = done;
      _streak = streak;
      _remaining = _remaining > 0 ? _remaining - 1 : 0;
      if (_i + 1 >= _queue.length) {
        _running = false;
        _queue = [];
      } else {
        _i++;
        _show = false;
      }
    });
  }

  Widget _runner() {
    final w = _queue[_i];
    return ListView(
      padding: const EdgeInsets.all(16),
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
        Center(
          child: IconButton(
            icon: const Icon(Icons.volume_up, size: 32),
            onPressed: () => speakKorean(w.ko),
          ),
        ),
        const SizedBox(height: 12),
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
          SizedBox(
            height: 56,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade300),
              onPressed: _learned,
              child: const Text('শিখেছি', style: TextStyle(fontSize: 18)),
            ),
          ),
        ],
      ],
    );
  }

  Widget _home() {
    final pct = _goal == 0 ? 0.0 : (_doneToday / _goal).clamp(0.0, 1.0);
    final met = _doneToday >= _goal;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('আজকের লক্ষ্য: $_doneToday / $_goal নতুন শব্দ',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        LinearProgressIndicator(value: pct, minHeight: 14),
        const SizedBox(height: 16),
        Card(
          child: ListTile(
            leading: const Icon(Icons.local_fire_department,
                color: Colors.orange, size: 32),
            title: const Text('পরপর লক্ষ্য পূরণের দিন'),
            trailing: Text('$_streak',
                style:
                    const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          ),
        ),
        Card(
          child: ListTile(
            leading: const Icon(Icons.menu_book, color: Colors.blue, size: 32),
            title: const Text('এখনো না-শেখা শব্দ'),
            trailing: Text('$_remaining',
                style:
                    const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          ),
        ),
        Card(
          child: ListTile(
            title: const Text('দৈনিক লক্ষ্য (নতুন শব্দ)'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                    icon: const Icon(Icons.remove_circle_outline),
                    onPressed: () => _changeGoal(-5)),
                Text('$_goal',
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold)),
                IconButton(
                    icon: const Icon(Icons.add_circle_outline),
                    onPressed: () => _changeGoal(5)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        if (met)
          const Center(
            child: Text('আজকের লক্ষ্য পূরণ হয়েছে! 🎉',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          )
        else if (_queue.isEmpty)
          const Center(
            child: Text('আজ শেখার মতো নতুন শব্দ নেই। আরও শব্দ যোগ করুন।',
                textAlign: TextAlign.center, style: TextStyle(fontSize: 18)),
          )
        else
          SizedBox(
            height: 56,
            child: ElevatedButton(
              onPressed: () => setState(() => _running = true),
              child: Text(
                  _doneToday == 0 ? 'আজকের শব্দ শুরু করুন' : 'চালিয়ে যান',
                  style: const TextStyle(fontSize: 18)),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget body;
    if (_loading) {
      body = const Center(child: CircularProgressIndicator());
    } else if (_running && _queue.isNotEmpty) {
      body = _runner();
    } else {
      body = _home();
    }
    return Scaffold(
      appBar: AppBar(title: const Text('স্টাডি প্ল্যানার')),
      body: SafeArea(child: body),
    );
  }
}
