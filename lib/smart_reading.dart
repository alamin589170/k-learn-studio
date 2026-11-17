import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'vocab.dart' show Db;

class SmartReadingPage extends StatefulWidget {
  final String initialText;
  const SmartReadingPage({super.key, this.initialText = ''});
  @override
  State<SmartReadingPage> createState() => _SmartReadingPageState();
}

class _SmartReadingPageState extends State<SmartReadingPage> {
  late final TextEditingController _c =
      TextEditingController(text: widget.initialText);
  final FlutterTts _tts = FlutterTts();
  List<String> _words = [];

  @override
  void initState() {
    super.initState();
    _tts.setLanguage('ko-KR');
    _words = _extract();
  }

  @override
  void dispose() {
    _c.dispose();
    _tts.stop();
    super.dispose();
  }

  List<String> _extract() {
    final seen = <String>{};
    final list = <String>[];
    for (final m in RegExp(r'[가-힣]+').allMatches(_c.text)) {
      final w = m.group(0)!;
      if (seen.add(w)) list.add(w);
    }
    return list;
  }

  Future<Map<String, Object?>?> _find(String w) async {
    try {
      final db = await Db.get();
      for (var n = w.length; n >= 1 && w.length - n < 4; n--) {
        final rows = await db.query('words',
            where: 'ko = ?', whereArgs: [w.substring(0, n)], limit: 1);
        if (rows.isNotEmpty) return rows.first;
      }
    } catch (_) {}
    return null;
  }

  String _f(Map<String, Object?> m, String k) => '${m[k] ?? ''}';

  Future<void> _open(String w) async {
    final row = await _find(w);
    if (!mounted) return;
    final ko = row == null ? w : _f(row, 'ko');
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(ko,
                  style: const TextStyle(
                      fontSize: 26, fontWeight: FontWeight.bold)),
              if (row != null && _f(row, 'pron').isNotEmpty)
                Text(_f(row, 'pron')),
              const SizedBox(height: 8),
              Text(
                  row == null
                      ? 'অভিধানে এই শব্দ পাওয়া যায়নি (রূপ বদলানো হতে পারে)'
                      : _f(row, 'bn'),
                  style: const TextStyle(fontSize: 18)),
              if (row != null && _f(row, 'en').isNotEmpty) Text(_f(row, 'en')),
              if (row != null && _f(row, 'ex').isNotEmpty) Text(_f(row, 'ex')),
              const SizedBox(height: 8),
              ElevatedButton.icon(
                onPressed: () => _tts.speak(ko),
                icon: const Icon(Icons.volume_up),
                label: const Text('শুনুন'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('স্মার্ট রিডিং')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextField(
              controller: _c,
              minLines: 4,
              maxLines: 10,
              style: const TextStyle(fontSize: 18),
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'কোরিয়ান লেখা এখানে পেস্ট করুন বা লিখুন',
              ),
            ),
            const SizedBox(height: 8),
            Row(children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () => setState(() => _words = _extract()),
                  child: const Text('শব্দ দেখান'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    if (_c.text.trim().isNotEmpty) _tts.speak(_c.text);
                  },
                  child: const Text('সব পড়ুন'),
                ),
              ),
            ]),
            const SizedBox(height: 12),
            if (_words.isNotEmpty) const Text('শব্দে চাপ দিলে অর্থ দেখাবে:'),
            const SizedBox(height: 8),
            Wrap(spacing: 8, runSpacing: 8, children: [
              for (final w in _words)
                ActionChip(
                  label: Text(w, style: const TextStyle(fontSize: 18)),
                  onPressed: () => _open(w),
                ),
            ]),
          ],
        ),
      ),
    );
  }
}
