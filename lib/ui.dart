import 'dart:io';
import 'package:flutter/material.dart';
import 'settings.dart';
import 'style.dart';
import 'vocab.dart';
import 'wordimg.dart';

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
          if (AppSettings.preset.value == 0) ...[
            Align(
                alignment: const Alignment(-0.3, -1.1),
                child: glow(const Color(0xFFD946EF), 380, 0.16)),
            Align(
                alignment: const Alignment(-1.2, 0.1),
                child: glow(const Color(0xFF14B8A6), 340, 0.14)),
          ],
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

  Future<void> _load() async {
    final w = widget.word;
    final id = w.id;
    if (id == null) return;
    try {
      final f = await WordImg.fetch(w,
          alive: () => mounted && widget.word.id == id);
      if (f != null && mounted && widget.word.id == id) {
        setState(() => file = f);
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
    return RepaintBoundary(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Image.file(
          f,
          width: widget.size,
          height: widget.size,
          cacheWidth: (widget.size * 2).round(),
          fit: BoxFit.cover,
          gaplessPlayback: true,
          errorBuilder: (c, e, s) => _fallback(),
        ),
      ),
    );
  }
}
