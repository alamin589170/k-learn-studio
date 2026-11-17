import 'package:audioplayers/audioplayers.dart' as ap;
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart' as rc;
import 'vocab.dart' show Db;

class PronouncePage extends StatefulWidget {
  const PronouncePage({super.key});
  @override
  State<PronouncePage> createState() => _PronouncePageState();
}

class _PronouncePageState extends State<PronouncePage> {
  final rc.AudioRecorder _rec = rc.AudioRecorder();
  final ap.AudioPlayer _player = ap.AudioPlayer();
  final FlutterTts _tts = FlutterTts();
  List<Map<String, Object?>> _words = [];
  int _i = 0;
  bool _recording = false;
  String? _file;
  String _msg = '';

  @override
  void initState() {
    super.initState();
    _tts.setLanguage('ko-KR');
    _load();
  }

  @override
  void dispose() {
    _rec.dispose();
    _player.dispose();
    _tts.stop();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final db = await Db.get();
      final rows = await db.query('words',
          columns: ['ko', 'pron', 'bn'], orderBy: 'RANDOM()', limit: 30);
      if (!mounted) return;
      setState(() => _words = rows);
    } catch (_) {}
  }

  Future<void> _toggle() async {
    try {
      if (_recording) {
        final path = await _rec.stop();
        if (!mounted) return;
        setState(() {
          _recording = false;
          _file = path;
          _msg = 'রেকর্ড হয়েছে। ▶ চেপে নিজের উচ্চারণ শুনুন।';
        });
        return;
      }
      if (!await _rec.hasPermission()) {
        if (mounted) setState(() => _msg = 'মাইক্রোফোনের অনুমতি দিন (সেটিংস → অ্যাপ)');
        return;
      }
      final dir = await getTemporaryDirectory();
      final path =
          p.join(dir.path, 'rec_${DateTime.now().millisecondsSinceEpoch}.m4a');
      await _rec.start(const rc.RecordConfig(), path: path);
      if (mounted) {
        setState(() {
          _recording = true;
          _msg = 'রেকর্ড চলছে... শেষ হলে আবার চাপুন';
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _recording = false;
          _msg = 'রেকর্ড করা যায়নি';
        });
      }
    }
  }

  Future<void> _playMine() async {
    final f = _file;
    if (f == null) return;
    try {
      await _player.play(ap.DeviceFileSource(f));
    } catch (_) {
      if (mounted) setState(() => _msg = 'চালানো যায়নি');
    }
  }

  void _next() {
    if (_recording || _words.isEmpty) return;
    setState(() {
      _i = (_i + 1) % _words.length;
      _file = null;
      _msg = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_words.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('উচ্চারণ অনুশীলন')),
        body: const Center(child: Text('শব্দ লোড হচ্ছে...')),
      );
    }
    final w = _words[_i];
    final ko = '${w['ko'] ?? ''}';
    return Scaffold(
      appBar: AppBar(title: const Text('উচ্চারণ অনুশীলন')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(children: [
                  Text(ko,
                      style: const TextStyle(
                          fontSize: 40, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text('${w['pron'] ?? ''}', style: const TextStyle(fontSize: 18)),
                  const SizedBox(height: 4),
                  Text('${w['bn'] ?? ''}', style: const TextStyle(fontSize: 20)),
                ]),
              ),
            ),
            const SizedBox(height: 16),
            Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
              Column(children: [
                IconButton.filled(
                  iconSize: 36,
                  onPressed: () => _tts.speak(ko),
                  icon: const Icon(Icons.volume_up),
                ),
                const Text('আসল শুনুন'),
              ]),
              Column(children: [
                IconButton.filled(
                  iconSize: 36,
                  style: IconButton.styleFrom(
                      backgroundColor: _recording ? Colors.red : null),
                  onPressed: _toggle,
                  icon: Icon(_recording ? Icons.stop : Icons.mic),
                ),
                Text(_recording ? 'থামুন' : 'রেকর্ড'),
              ]),
              Column(children: [
                IconButton.filled(
                  iconSize: 36,
                  onPressed: _file == null ? null : _playMine,
                  icon: const Icon(Icons.play_arrow),
                ),
                const Text('আমারটা শুনুন'),
              ]),
            ]),
            const SizedBox(height: 16),
            Text(_msg, textAlign: TextAlign.center),
            const SizedBox(height: 8),
            const Text(
              'আসল উচ্চারণ শুনে নিজেরটা রেকর্ড করে মিলিয়ে দেখুন। অ্যাপ নিজে নম্বর দেয় না।',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _next, child: const Text('পরের শব্দ')),
          ],
        ),
      ),
    );
  }
}
