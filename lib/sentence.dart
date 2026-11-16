import 'dart:math';
import 'package:flutter/material.dart';

const List<List<String>> _sentences = [
  ['저는 매일 한국어를 공부합니다', 'আমি প্রতিদিন কোরিয়ান ভাষা পড়ি'],
  ['저는 물을 마십니다', 'আমি পানি পান করি'],
  ['오늘 날씨가 좋습니다', 'আজ আবহাওয়া ভালো'],
  ['저는 학교에 갑니다', 'আমি স্কুলে যাই'],
  ['이것은 책입니다', 'এটি একটি বই'],
  ['저는 밥을 먹습니다', 'আমি ভাত খাই'],
  ['저는 친구를 만납니다', 'আমি বন্ধুর সাথে দেখা করি'],
  ['저는 한국에 가고 싶습니다', 'আমি কোরিয়া যেতে চাই'],
  ['내일 시장에 갑니다', 'আগামীকাল বাজারে যাই'],
  ['어머니는 요리를 합니다', 'মা রান্না করেন'],
  ['저는 커피를 좋아합니다', 'আমি কফি পছন্দ করি'],
  ['지금 몇 시입니까', 'এখন কটা বাজে'],
  ['한국어는 재미있습니다', 'কোরিয়ান ভাষা মজার'],
  ['저는 버스를 탑니다', 'আমি বাসে চড়ি'],
  ['도서관에서 책을 읽습니다', 'লাইব্রেরিতে বই পড়ি'],
  ['우리는 같이 영화를 봅니다', 'আমরা একসাথে সিনেমা দেখি'],
  ['저는 병원에 갑니다', 'আমি হাসপাতালে যাই'],
  ['아버지는 회사에 다닙니다', 'বাবা অফিসে কাজ করেন'],
];

class SentencePage extends StatefulWidget {
  const SentencePage({super.key});
  @override
  State<SentencePage> createState() => _SentencePageState();
}

class _SentencePageState extends State<SentencePage> {
  final Random _rnd = Random();
  late List<int> _deck;
  int _pos = 0;
  List<String> _pool = [];
  List<String> _picked = [];
  bool _checked = false;
  bool _ok = false;
  int _right = 0;
  int _total = 0;

  @override
  void initState() {
    super.initState();
    _deck = List.generate(_sentences.length, (i) => i)..shuffle(_rnd);
    _setup();
  }

  void _setup() {
    final s = _sentences[_deck[_pos]][0].split(' ');
    s.shuffle(_rnd);
    _pool = s;
    _picked = [];
    _checked = false;
    _ok = false;
  }

  void _pick(int i) => setState(() => _picked.add(_pool.removeAt(i)));
  void _unpick(int i) => setState(() => _pool.add(_picked.removeAt(i)));

  void _check() {
    final ok = _picked.join(' ') == _sentences[_deck[_pos]][0];
    setState(() {
      _checked = true;
      _ok = ok;
      _total++;
      if (ok) _right++;
    });
  }

  void _next() {
    setState(() {
      _pos++;
      if (_pos >= _deck.length) {
        _deck.shuffle(_rnd);
        _pos = 0;
      }
      _setup();
    });
  }

  Widget _chip(String t, VoidCallback? f) => ActionChip(
      label: Text(t, style: const TextStyle(fontSize: 18)), onPressed: f);

  @override
  Widget build(BuildContext context) {
    final ans = _sentences[_deck[_pos]];
    return Scaffold(
      appBar: AppBar(title: const Text('বাক্য নির্মাতা')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text('সঠিক: $_right / $_total'),
            const SizedBox(height: 12),
            Text(ans[1],
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Container(
              constraints: const BoxConstraints(minHeight: 80),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8)),
              child: Wrap(spacing: 8, runSpacing: 8, children: [
                for (var i = 0; i < _picked.length; i++)
                  _chip(_picked[i], _checked ? null : () => _unpick(i)),
              ]),
            ),
            const SizedBox(height: 16),
            Wrap(spacing: 8, runSpacing: 8, children: [
              for (var i = 0; i < _pool.length; i++)
                _chip(_pool[i], _checked ? null : () => _pick(i)),
            ]),
            const SizedBox(height: 16),
            if (_checked)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(_ok ? '✅ সঠিক!' : '❌ ভুল। সঠিক: ${ans[0]}',
                    style: TextStyle(
                        fontSize: 18, color: _ok ? Colors.green : Colors.red)),
              ),
            Row(children: [
              Expanded(
                child: ElevatedButton(
                    onPressed: (_checked || _pool.isNotEmpty) ? null : _check,
                    child: const Text('যাচাই')),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                    onPressed: _checked ? _next : () => setState(_setup),
                    child: Text(_checked ? 'পরের বাক্য' : 'আবার')),
              ),
            ]),
          ],
        ),
      ),
    );
  }
}
