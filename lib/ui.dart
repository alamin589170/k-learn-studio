import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'settings.dart';
import 'vocab.dart';

class AnimatedBg extends StatefulWidget {
  final Widget child;
  const AnimatedBg({super.key, required this.child});
  @override
  State<AnimatedBg> createState() => _AnimatedBgState();
}

class _AnimatedBgState extends State<AnimatedBg>
    with SingleTickerProviderStateMixin {
  late final AnimationController c;

  @override
  void initState() {
    super.initState();
    c = AnimationController(
        vsync: this, duration: Duration(seconds: AppSettings.animSecs.value));
    AppSettings.animate.addListener(_sync);
    AppSettings.animSecs.addListener(_sync);
    _sync();
  }

  void _sync() {
    c.duration = Duration(seconds: AppSettings.animSecs.value);
    if (AppSettings.animate.value) {
      c.repeat(reverse: true);
    } else {
      c.stop();
    }
  }

  @override
  void dispose() {
    AppSettings.animate.removeListener(_sync);
    AppSettings.animSecs.removeListener(_sync);
    c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: c,
      builder: (ctx, _) {
        final cs = Theme.of(ctx).colorScheme;
        final base = HSVColor.fromColor(cs.primary);
        final t = AppSettings.animate.value ? c.value : 0.0;
        Color tint(double shift, double amt) => Color.lerp(
            cs.surface,
            base.withHue((base.hue + shift + 360) % 360).toColor(),
            amt)!;
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment(-1 + t, -1),
              end: Alignment(1 - t, 1),
              colors: [
                tint(40 * t, 0.10),
                tint(20 - 30 * t, 0.24),
                tint(70 * t, 0.12),
              ],
            ),
          ),
          child: widget.child,
        );
      },
    );
  }
}

class WordThumb extends StatefulWidget {
  final Word word;
  final double size;
  const WordThumb({super.key, required this.word, this.size = 64});
  @override
  State<WordThumb> createState() => _WordThumbState();
}

class _WordThumbState extends State<WordThumb> {
  File? file;
  static Directory? _dir;
  static Future<void> _last = Future<void>.value();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(WordThumb old) {
    super.didUpdateWidget(old);
    if (old.word.id != widget.word.id) {
      file = null;
      _load();
    }
  }

  Future<Directory> _thumbDir() async {
    final d = _dir;
    if (d != null) return d;
    final base = await getApplicationDocumentsDirectory();
    final t = Directory('${base.path}/thumbs');
    if (!await t.exists()) await t.create(recursive: true);
    _dir = t;
    return t;
  }

  String _query(Word w) {
    if (w.en.isEmpty) return '';
    return w.en.split(RegExp(r'[,/;(]')).first.trim();
  }

  Future<File?> _fetch(Directory dir, int id, String key, String q) async {
    if (!mounted || widget.word.id != id) return null;
    try {
      final r = await http
          .get(Uri.parse(
              'https://pixabay.com/api/?key=$key&q=${Uri.encodeQueryComponent(q)}&per_page=3&safe_search=true'))
          .timeout(const Duration(seconds: 12));
      if (r.statusCode != 200) return null;
      final data = jsonDecode(r.body) as Map<String, dynamic>;
      final hits = data['hits'] as List;
      if (hits.isEmpty) {
        await File('${dir.path}/$id.none').writeAsString('1');
        return null;
      }
      final url = (hits.first as Map)['previewURL'] as String;
      final img =
          await http.get(Uri.parse(url)).timeout(const Duration(seconds: 12));
      if (img.statusCode != 200) return null;
      final f = File('${dir.path}/$id.jpg');
      await f.writeAsBytes(img.bodyBytes);
      return f;
    } catch (_) {
      return null;
    }
  }

  Future<void> _load() async {
    final id = widget.word.id;
    if (id == null) return;
    try {
      final dir = await _thumbDir();
      final f = File('${dir.path}/$id.jpg');
      if (await f.exists()) {
        if (mounted) setState(() => file = f);
        return;
      }
      if (await File('${dir.path}/$id.none').exists()) return;
      const key = String.fromEnvironment('PIXABAY_KEY');
      final q = _query(widget.word);
      if (key.isEmpty || q.isEmpty) return;
      final job = _last.then((_) => _fetch(dir, id, key, q));
      _last = job.then<void>(
          (_) => Future<void>.delayed(const Duration(milliseconds: 700)));
      final got = await job;
      if (got != null && mounted && widget.word.id == id) {
        setState(() => file = got);
      }
    } catch (_) {}
  }

  static const List<Color> _tints = [
    Color(0xFF0984E3),
    Color(0xFF00B894),
    Color(0xFF6C5CE7),
    Color(0xFFE17055),
    Color(0xFFE84393),
  ];

  Widget _fallback() {
    final id = widget.word.id ?? 0;
    final col = _tints[id % _tints.length];
    final ch = widget.word.ko.isEmpty ? '?' : widget.word.ko.characters.first;
    return Container(
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(
        color: col.withOpacity(0.15),
        borderRadius: BorderRadius.circular(16),
      ),
      alignment: Alignment.center,
      child: Text(ch,
          style: TextStyle(
              fontSize: widget.size * 0.45,
              fontWeight: FontWeight.bold,
              color: col)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final f = file;
    if (f == null) return _fallback();
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Image.file(
        f,
        width: widget.size,
        height: widget.size,
        fit: BoxFit.cover,
        errorBuilder: (c, e, s) => _fallback(),
      ),
    );
  }
}
