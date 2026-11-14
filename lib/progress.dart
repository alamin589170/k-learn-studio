import 'package:flutter/material.dart';
import 'vocab.dart';

class ProgressPage extends StatefulWidget {
  const ProgressPage({super.key});
  @override
  State<ProgressPage> createState() => _ProgressPageState();
}

class _ProgressPageState extends State<ProgressPage> {
  bool _loading = true;
  int _total = 0;
  int _saved = 0;
  int _started = 0;
  int _learned = 0;
  int _dueNow = 0;
  int _todayDone = 0;
  List<int> _boxes = [0, 0, 0, 0, 0, 0];

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
    final boxes = [0, 0, 0, 0, 0, 0];
    var learned = 0;
    var due = 0;
    for (final r in rows) {
      final b = (r['box'] as int).clamp(0, 5);
      boxes[b]++;
      if (b >= 3) learned++;
      if ((r['due'] as int) <= now) due++;
    }
    if (!mounted) return;
    setState(() {
      _total = all.length;
      _saved = all.where((w) => w.saved).length;
      _started = rows.length;
      _learned = learned;
      _dueNow = due;
      _boxes = boxes;
      _loading = false;
    });
  }

  Widget _stat(IconData icon, String label, String value, Color color) {
    return Card(
      child: ListTile(
        leading: Icon(icon, color: color, size: 32),
        title: Text(label, style: const TextStyle(fontSize: 16)),
        trailing: Text(value,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pct = _total == 0 ? 0.0 : _learned / _total;
    return Scaffold(
      appBar: AppBar(
        title: const Text('আমার অগ্রগতি'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() => _loading = true);
              _load();
            },
          ),
        ],
      ),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Text('শেখা শব্দ: $_learned / $_total',
                      style: const TextStyle(
                          fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(value: pct, minHeight: 12),
                  const SizedBox(height: 16),
                  _stat(Icons.menu_book, 'মোট শব্দ', '$_total', Colors.blue),
                  _stat(Icons.star, 'সংরক্ষিত শব্দ', '$_saved', Colors.amber),
                  _stat(Icons.play_circle, 'রিভিশন শুরু হয়েছে', '$_started',
                      Colors.teal),
                  _stat(Icons.check_circle, 'ভালো শিখেছি (৩+ ধাপ)', '$_learned',
                      Colors.green),
                  _stat(Icons.schedule, 'এখন রিভিশনের সময়', '$_dueNow',
                      Colors.orange),
                  const SizedBox(height: 16),
                  const Text('ধাপ অনুযায়ী শব্দ',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  for (var i = 0; i < 6; i++)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Row(
                        children: [
                          SizedBox(width: 70, child: Text('ধাপ $i')),
                          Expanded(
                            child: LinearProgressIndicator(
                              value: _started == 0 ? 0 : _boxes[i] / _started,
                              minHeight: 8,
                            ),
                          ),
                          SizedBox(
                              width: 40,
                              child: Text('${_boxes[i]}',
                                  textAlign: TextAlign.right)),
                        ],
                      ),
                    ),
                ],
              ),
      ),
    );
  }
}
