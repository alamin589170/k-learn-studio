import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'vocab.dart' show Db;

const String _url = String.fromEnvironment('SUPABASE_URL');
const String _key = String.fromEnvironment('SUPABASE_KEY');

class Cloud {
  static bool get ready => _url.isNotEmpty && _key.isNotEmpty;
  static String get _base =>
      _url.endsWith('/') ? _url.substring(0, _url.length - 1) : _url;
  static Map<String, String> get _h =>
      {'apikey': _key, 'Content-Type': 'application/json'};

  static Future<bool> suggest(
      String ko, String pron, String bn, String en, String ex) async {
    if (!ready) return false;
    try {
      final r = await http
          .post(
            Uri.parse('$_base/rest/v1/word_suggestions'),
            headers: {..._h, 'Prefer': 'return=minimal'},
            body: jsonEncode(
                {'ko': ko, 'pron': pron, 'bn': bn, 'en': en, 'ex': ex}),
          )
          .timeout(const Duration(seconds: 15));
      return r.statusCode == 201;
    } catch (_) {
      return false;
    }
  }

  // নতুন শব্দের সংখ্যা; ব্যর্থ হলে -1
  static Future<int> pullApproved() async {
    if (!ready) return -1;
    try {
      final r = await http
          .get(
            Uri.parse(
                '$_base/rest/v1/word_suggestions?approved=eq.true&select=ko,pron,bn,en,ex&order=id.asc&limit=1000'),
            headers: _h,
          )
          .timeout(const Duration(seconds: 20));
      if (r.statusCode != 200) return -1;
      final data = jsonDecode(utf8.decode(r.bodyBytes));
      if (data is! List) return -1;
      final db = await Db.get();
      final have = await db.query('words', columns: ['ko']);
      final set = <String>{for (final m in have) '${m['ko'] ?? ''}'};
      final batch = db.batch();
      var n = 0;
      for (final m in data) {
        if (m is! Map) continue;
        final ko = '${m['ko'] ?? ''}'.trim();
        final bn = '${m['bn'] ?? ''}'.trim();
        if (ko.isEmpty || bn.isEmpty || set.contains(ko)) continue;
        set.add(ko);
        n++;
        batch.insert('words', {
          'ko': ko,
          'pron': '${m['pron'] ?? ''}',
          'bn': bn,
          'en': '${m['en'] ?? ''}',
          'ex': '${m['ex'] ?? ''}',
          'saved': 0,
        });
      }
      if (n > 0) await batch.commit(noResult: true);
      return n;
    } catch (_) {
      return -1;
    }
  }
}

class SuggestWordPage extends StatefulWidget {
  const SuggestWordPage({super.key});
  @override
  State<SuggestWordPage> createState() => _SuggestWordPageState();
}

class _SuggestWordPageState extends State<SuggestWordPage> {
  final _ko = TextEditingController();
  final _pron = TextEditingController();
  final _bn = TextEditingController();
  final _en = TextEditingController();
  final _ex = TextEditingController();
  bool _busy = false;
  String _msg = '';

  @override
  void dispose() {
    for (final c in [_ko, _pron, _bn, _en, _ex]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _send() async {
    final ko = _ko.text.trim(), bn = _bn.text.trim();
    if (!RegExp(r'[가-힣]').hasMatch(ko) || ko.length > 40) {
      setState(() => _msg = 'কোরিয়ান শব্দ লিখুন (সর্বোচ্চ ৪০ অক্ষর)');
      return;
    }
    if (bn.isEmpty ||
        bn.length > 120 ||
        _pron.text.length > 80 ||
        _en.text.length > 120 ||
        _ex.text.length > 200) {
      setState(() => _msg = 'বাংলা অর্থ দিন; লেখা বেশি লম্বা হলে ছোট করুন');
      return;
    }
    setState(() {
      _busy = true;
      _msg = '';
    });
    final ok = await Cloud.suggest(
        ko, _pron.text.trim(), bn, _en.text.trim(), _ex.text.trim());
    if (!mounted) return;
    setState(() {
      _busy = false;
      _msg = ok
          ? 'পাঠানো হয়েছে। অনুমোদনের পর সবার কাছে যাবে।'
          : (Cloud.ready
              ? 'পাঠানো যায়নি, পরে চেষ্টা করুন'
              : 'সার্ভার এখনো চালু নেই');
      if (ok) {
        for (final c in [_ko, _pron, _bn, _en, _ex]) {
          c.clear();
        }
      }
    });
  }

  Widget _f(TextEditingController c, String label) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: TextField(
          controller: c,
          decoration: InputDecoration(
              border: const OutlineInputBorder(), labelText: label),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('শব্দ পাঠান')),
      body: SafeArea(
        child: ListView(padding: const EdgeInsets.all(16), children: [
          const Text(
              'আপনার পাঠানো শব্দ অনুমোদনের পর সবার অ্যাপে যাবে। ব্যক্তিগত তথ্য লিখবেন না।'),
          const SizedBox(height: 12),
          _f(_ko, 'কোরিয়ান শব্দ *'),
          _f(_pron, 'উচ্চারণ (বাংলায়)'),
          _f(_bn, 'বাংলা অর্থ *'),
          _f(_en, 'English'),
          _f(_ex, 'উদাহরণ বাক্য'),
          ElevatedButton(
              onPressed: _busy ? null : _send,
              child: Text(_busy ? 'পাঠানো হচ্ছে...' : 'পাঠান')),
          const SizedBox(height: 8),
          Text(_msg),
        ]),
      ),
    );
  }
}

class CloudCard extends StatefulWidget {
  const CloudCard({super.key});
  @override
  State<CloudCard> createState() => _CloudCardState();
}

class _CloudCardState extends State<CloudCard> {
  bool _busy = false;
  String _msg = Cloud.ready
      ? 'সবার পাঠানো নতুন শব্দ আনুন বা নিজের শব্দ পাঠান'
      : 'সার্ভার এখনো চালু নেই';

  Future<void> _pull() async {
    setState(() => _busy = true);
    final n = await Cloud.pullApproved();
    if (!mounted) return;
    setState(() {
      _busy = false;
      _msg = n < 0 ? 'আনা যায়নি' : 'নতুন শব্দ যোগ হয়েছে: $n';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.cloud, color: Colors.blue, size: 32),
        title: const Text('ইউজারদের শব্দ'),
        subtitle: Text(_msg),
        trailing: _busy
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2))
            : Row(mainAxisSize: MainAxisSize.min, children: [
                IconButton(
                  icon: const Icon(Icons.add_circle_outline),
                  onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const SuggestWordPage())),
                ),
                IconButton(icon: const Icon(Icons.download), onPressed: _pull),
              ]),
      ),
    );
  }
}
