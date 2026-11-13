import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'vocab.dart';

class FlashcardPage extends StatefulWidget {
  const FlashcardPage({super.key});
  @override
  State<FlashcardPage> createState() => _FlashcardPageState();
}

class _FlashcardPageState extends State<FlashcardPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 450));
  List<Word> words = [];
  int index = 0;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    load();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  Future<void> load() async {
    final r = await Db.search('');
    if (mounted) {
      setState(() {
        words = r;
        loading = false;
      });
    }
  }

  void flip() {
    if (_c.value >= 0.5) {
      _c.reverse();
    } else {
      _c.forward();
    }
  }

  void go(int d) {
    if (words.isEmpty) return;
    _c.value = 0;
    setState(() => index = (index + d + words.length) % words.length);
  }

  void shuffle() {
    _c.value = 0;
    setState(() {
      words.shuffle();
      index = 0;
    });
  }

  Future<void> toggleSave() async {
    final w = words[index];
    w.saved = !w.saved;
    await Db.update(w);
    setState(() {});
  }

  Widget face(Widget child, Color color) => Container(
        width: double.infinity,
        height: 360,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Center(child: child),
      );

  @override
  Widget build(BuildContext context) {
    final appBar = AppBar(
      title: const Text('3D ফ্ল্যাশকার্ড'),
      actions: [
        IconButton(icon: const Icon(Icons.shuffle), onPressed: shuffle),
      ],
    );
    if (loading) {
      return Scaffold(
          appBar: appBar,
          body: const Center(child: CircularProgressIndicator()));
    }
    if (words.isEmpty) {
      return Scaffold(
          appBar: appBar,
          body: const Center(child: Text('কোনো শব্দ নেই।')));
    }
    final w = words[index];
    final front = face(
      Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(w.ko,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 44,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          const Text('উল্টাতে কার্ডে চাপুন',
              style: TextStyle(color: Colors.white70)),
        ],
      ),
      const Color(0xFF6C5CE7),
    );
    final back = face(
      SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (w.pron.isNotEmpty)
              Text(w.pron,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 18,
                      fontStyle: FontStyle.italic)),
            const SizedBox(height: 8),
            Text(w.bn,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 30,
                    fontWeight: FontWeight.bold)),
            if (w.en.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(w.en,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white, fontSize: 18)),
            ],
            if (w.ex.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(w.ex,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white70, fontSize: 16)),
            ],
          ],
        ),
      ),
      const Color(0xFF00B894),
    );

    return Scaffold(
      appBar: appBar,
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text('${index + 1} / ${words.length}',
                style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: flip,
              child: AnimatedBuilder(
                animation: _c,
                builder: (context, _) {
                  final angle = _c.value * math.pi;
                  final showBack = angle > math.pi / 2;
                  return Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.identity()
                      ..setEntry(3, 2, 0.001)
                      ..rotateY(angle),
                    child: showBack
                        ? Transform(
                            alignment: Alignment.center,
                            transform: Matrix4.rotationY(math.pi),
                            child: back,
                          )
                        : front,
                  );
                },
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton.filledTonal(
                  iconSize: 32,
                  icon: const Icon(Icons.chevron_left),
                  onPressed: () => go(-1),
                ),
                IconButton.filledTonal(
                  iconSize: 32,
                  icon: const Icon(Icons.volume_up),
                  onPressed: () => speakKorean(w.ko),
                ),
                IconButton.filledTonal(
                  iconSize: 32,
                  icon: Icon(w.saved ? Icons.star : Icons.star_border,
                      color: w.saved ? Colors.amber : null),
                  onPressed: toggleSave,
                ),
                IconButton.filledTonal(
                  iconSize: 32,
                  icon: const Icon(Icons.chevron_right),
                  onPressed: () => go(1),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
