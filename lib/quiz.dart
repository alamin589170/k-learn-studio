import 'dart:math';
import 'package:flutter/material.dart';
import 'words_data.dart';

class QuizPage extends StatefulWidget {
  const QuizPage({super.key});
  @override
  State<QuizPage> createState() => _QuizPageState();
}

class _Q {
  final String question;
  final String answer;
  final List<String> options;
  _Q(this.question, this.answer, this.options);
}

class _QuizPageState extends State<QuizPage> {
  final Random _rnd = Random();
  List<_Q> _qs = [];
  int _i = 0;
  int _score = 0;
  String? _picked;
  bool? _mode; // true = কোরিয়ান থেকে বাংলা, false = বাংলা থেকে কোরিয়ান
  bool _done = false;

  List<List<String>> _words() {
    return (allWords as List)
        .map((e) => List<String>.from(e as List))
        .where((w) => w.length >= 3 && w[0].isNotEmpty && w[2].isNotEmpty)
        .toList();
  }

  void _start(bool kor) {
    final ws = _words();
    ws.shuffle(_rnd);
    final take = ws.take(min(10, ws.length)).toList();
    final qs = <_Q>[];
    for (final w in take) {
      final q = kor ? w[0] : w[2];
      final a = kor ? w[2] : w[0];
      final opts = <String>{a};
      var guard = 0;
      while (opts.length < 4 && guard < 200) {
        guard++;
        final o = ws[_rnd.nextInt(ws.length)];
        opts.add(kor ? o[2] : o[0]);
      }
      final list = opts.toList()..shuffle(_rnd);
      qs.add(_Q(q, a, list));
    }
    setState(() {
      _qs = qs;
      _i = 0;
      _score = 0;
      _picked = null;
      _mode = kor;
      _done = false;
    });
  }

  void _pick(String o) {
    if (_picked != null) return;
    setState(() {
      _picked = o;
      if (o == _qs[_i].answer) _score++;
    });
  }

  void _next() {
    setState(() {
      if (_i + 1 >= _qs.length) {
        _done = true;
      } else {
        _i++;
        _picked = null;
      }
    });
  }

  Widget _menu() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('কুইজ ও টেস্ট',
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('১০টি প্রশ্ন, প্রতিটিতে ৪টি উত্তর'),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () => _start(true),
                child: const Text('কোরিয়ান → বাংলা',
                    style: TextStyle(fontSize: 18)),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () => _start(false),
                child: const Text('বাংলা → কোরিয়ান',
                    style: TextStyle(fontSize: 18)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _result() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('কুইজ শেষ!',
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Text('আপনার স্কোর: $_score / ${_qs.length}',
                style: const TextStyle(fontSize: 22)),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () => _start(_mode ?? true),
                child: const Text('আবার খেলুন', style: TextStyle(fontSize: 18)),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: OutlinedButton(
                onPressed: () => setState(() {
                  _mode = null;
                  _done = false;
                }),
                child: const Text('মোড বদলান', style: TextStyle(fontSize: 18)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _question() {
    final q = _qs[_i];
    return Padding(
      padding: const EdgeInsets.all(16),
      child: ListView(
        children: [
          Text('প্রশ্ন ${_i + 1} / ${_qs.length}',
              style: const TextStyle(fontSize: 16)),
          const SizedBox(height: 8),
          LinearProgressIndicator(value: (_i + 1) / _qs.length),
          const SizedBox(height: 24),
          Center(
            child: Text(q.question,
                textAlign: TextAlign.center,
                style:
                    const TextStyle(fontSize: 30, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 24),
          for (final o in q.options)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.all(16),
                    backgroundColor: _picked == null
                        ? null
                        : (o == q.answer
                            ? Colors.green.shade300
                            : (o == _picked ? Colors.red.shade300 : null)),
                  ),
                  onPressed: () => _pick(o),
                  child: Text(o,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 18)),
                ),
              ),
            ),
          if (_picked != null) ...[
            const SizedBox(height: 8),
            Text(
              _picked == q.answer
                  ? 'সঠিক!'
                  : 'ভুল। সঠিক উত্তর: ${q.answer}',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 52,
              child: ElevatedButton(
                onPressed: _next,
                child: Text(_i + 1 >= _qs.length ? 'ফলাফল দেখুন' : 'পরের প্রশ্ন',
                    style: const TextStyle(fontSize: 18)),
              ),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget body;
    if (_mode == null) {
      body = _menu();
    } else if (_done) {
      body = _result();
    } else {
      body = _question();
    }
    return Scaffold(
      appBar: AppBar(title: const Text('কুইজ ও টেস্ট')),
      body: SafeArea(child: body),
    );
  }
}
