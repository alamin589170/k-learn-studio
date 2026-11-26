import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'settings.dart';
import 'style.dart';
import 'vocab.dart';

// স্থির (এনিমেশনহীন) গ্রেডিয়েন্ট ব্যাকগ্রাউন্ড: হালকা ও দ্রুত
class AnimatedBg extends StatelessWidget {
  const AnimatedBg({super.key});

  @override
  Widget build(BuildContext context) {
    final cur = kPresets[AppSettings.preset.value.clamp(0, kPresets.length - 1)];
    final pr = Theme.of(context).colorScheme.primary;
    final h2 = palOf(context).head2;
    Widget glow(Color col, double size, double a) => Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
                colors: [col.withOpacity(a), col.withOpacity(0)]),
          ),
        );
    return RepaintBoundary(
      child: Stack(
        fit: StackFit.expand,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [cur.bg1, cur.bg2],
              ),
            ),
          ),
          Align(
              alignment: const Alignment(-1, -0.8),
              child: glow(pr, 420, cur.dark ? 0.28 : 0.20)),
          Align(
              alignment: const Alignment(1, 0.9),
              child: glow(h2, 380, cur.dark ? 0.24 : 0.16)),
        ],
      ),
    );
  }
}

// চালু/বন্ধ সূর্য-চাঁদ বাটন, সব পেজে ভাসমান, টেনে সরানো যায়
class DayNightFab extends StatefulWidget {
  const DayNightFab({super.key});
  @override
  State<DayNightFab> createState() => _DayNightFabState();
}

class _DayNightFabState extends State<DayNightFab> {
  Offset? pos;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (ctx, box) {
        final size = box.biggest;
        final top = MediaQuery.of(ctx).padding.top;
        final base = pos ?? Offset(size.width - 52, size.height * 0.30);
        final x = base.dx.clamp(4.0, size.width - 48.0).toDouble();
        final y = base.dy.clamp(top + 4, size.height - 120.0).toDouble();
        final dark = isDark(ctx);
        final pr = Theme.of(ctx).colorScheme.primary;
        return Stack(
          children: [
            Positioned(
              left: x,
              top: y,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => AppSettings.toggleDayNight(dark),
                onPanUpdate: (d) => setState(() => pos = Offset(x, y) + d.delta),
                child: Opacity(
                  opacity: 0.92,
                  child: Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          pr.withOpacity(0.95),
                          palOf(ctx).head2.withOpacity(0.85)
                        ],
                      ),
                      border: Border.all(
                          color: Colors.white.withOpacity(0.5), width: 1),
                      boxShadow: [
                        BoxShadow(
                            color: pr.withOpacity(0.4),
                            blurRadius: 12,
                            offset: const Offset(0, 4)),
                      ],
                    ),
                    child: Icon(dark ? Icons.light_mode : Icons.dark_mode,
                        color: Colors.white, size: 22),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

// ওয়েবসাইট/অ্যাপের নামের সঙ্গে মেলানো নিজস্ব লোগো
class GenLogo extends StatelessWidget {
  final String name;
  final String hint;
  final double size;
  const GenLogo({super.key, required this.name, this.hint = '', this.size = 56});

  IconData? _icon(String k) {
    bool has(List<String> w) => w.any((e) => k.contains(e));
    if (has(['dict', 'অভিধান', 'শব্দ'])) return Icons.menu_book;
    if (has(['translat', 'papago', 'অনুবাদ'])) return Icons.translate;
    if (has(['youtube', 'video', 'ভিডিও'])) return Icons.play_circle_fill;
    if (has(['topik', 'exam', 'test', 'পরীক্ষা', 'eps'])) return Icons.school;
    if (has(['grammar', 'ব্যাকরণ', 'গ্রামার'])) return Icons.rule;
    if (has(['news', 'খবর'])) return Icons.newspaper;
    if (has(['music', 'song', 'গান'])) return Icons.music_note;
    if (has(['chat', 'talk', 'চ্যাট'])) return Icons.chat_bubble;
    if (has(['book', 'বই', 'pdf'])) return Icons.auto_stories;
    return null;
  }

  @override
  Widget build(BuildContext context) {
    var h = 0;
    for (final r in name.runes) {
      h = (h * 31 + r) & 0x7fffffff;
    }
    final hue = (h % 360).toDouble();
    final c1 = HSLColor.fromAHSL(1, hue, 0.62, 0.50).toColor();
    final c2 = HSLColor.fromAHSL(1, (hue + 45) % 360, 0.70, 0.38).toColor();
    final ic = _icon('${name.toLowerCase()} ${hint.toLowerCase()}');
    final letter = name.trim().isEmpty ? '?' : name.trim().characters.first.toUpperCase();
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * 0.28),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [c1, c2],
        ),
        border: Border.all(color: Colors.white.withOpacity(0.35)),
        boxShadow: [
          BoxShadow(
              color: c2.withOpacity(0.35),
              blurRadius: 8,
              offset: const Offset(0, 3)),
        ],
      ),
      child: ic != null
          ? Icon(ic, color: Colors.white, size: size * 0.55)
          : Text(letter,
              style: TextStyle(
                  color: Colors.white,
                  fontSize: size * 0.5,
                  fontWeight: FontWeight.bold)),
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
