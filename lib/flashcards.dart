import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'vocab.dart';

class FlashcardPage extends StatefulWidget {
  const FlashcardPage({super.key});
  @override
  State<FlashcardPage> createState() => _FlashcardPageState();
}

class _FlashcardPageState extends State<FlashcardPage> {
  final PageController pc = PageController();
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
    pc.dispose();
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

  void shuffle() {
    words.shuffle();
    index = 0;
    if (pc.hasClients) pc.jumpToPage(0);
    setState(() {});
  }

  Future<void> toggleSave() async {
    final w = words[index];
    w.saved = !w.saved;
    await Db.update(w);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final appBar = AppBar(title: const Text('3D ফ্ল্যাশকার্ড'));
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
    return Scaffold(
      appBar: appBar,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: pc,
                itemCount: words.length,
                onPageChanged: (i) => setState(() => index = i),
                itemBuilder: (context, i) {
                  return AnimatedBuilder(
                    animation: pc,
                    builder: (context, child) {
                      double d = 0;
                      if (pc.hasClients && pc.position.haveDimensions) {
                        d = pc.page! - i;
                      } else {
                        d = (index - i).toDouble();
                      }
                      d = d.clamp(-1.0, 1.0).toDouble();
                      return Transform(
                        alignment:
                            d > 0 ? Alignment.centerRight : Alignment.centerLeft,
                        transform: Matrix4.identity()
                          ..setEntry(3, 2, 0.001)
                          ..rotateY(d * 0.8),
                        child: child,
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(14, 8, 14, 8),
                      child: _FlipCard(
                          key: ValueKey('${words[i].id}-$i'), word: words[i]),
                    ),
                  );
                },
              ),
            ),
            Text('${index + 1} / ${words.length}   (সোয়াইপ করুন)',
                style: const TextStyle(fontSize: 14)),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  IconButton.filledTonal(
                    iconSize: 30,
                    icon: const Icon(Icons.shuffle),
                    onPressed: shuffle,
                  ),
                  IconButton.filledTonal(
                    iconSize: 30,
                    icon: const Icon(Icons.volume_up),
                    onPressed: () => speakKorean(w.ko),
                  ),
                  IconButton.filledTonal(
                    iconSize: 30,
                    icon: Icon(w.saved ? Icons.star : Icons.star_border,
                        color: w.saved ? Colors.amber : null),
                    onPressed: toggleSave,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FlipCard extends StatefulWidget {
  final Word word;
  const _FlipCard({super.key, required this.word});
  @override
  State<_FlipCard> createState() => _FlipCardState();
}

class _FlipCardState extends State<_FlipCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController c = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 500));

  @override
  void dispose() {
    c.dispose();
    super.dispose();
  }

  void flip() {
    if (c.status == AnimationStatus.completed ||
        c.status == AnimationStatus.forward) {
      c.reverse();
    } else {
      c.forward();
    }
  }

  Widget face(Widget child, Color a, Color b) => Container(
        width: double.infinity,
        height: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [a, b],
          ),
          boxShadow: const [
            BoxShadow(
                color: Colors.black26, blurRadius: 16, offset: Offset(0, 8)),
          ],
        ),
        child: Center(child: child),
      );

  @override
  Widget build(BuildContext context) {
    final w = widget.word;
    final front = face(
      Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(w.ko,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 54,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          const Text('উল্টাতে চাপুন',
              style: TextStyle(color: Colors.white70, fontSize: 15)),
        ],
      ),
      const Color(0xFF6C5CE7),
      const Color(0xFFA29BFE),
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
                      fontSize: 20,
                      fontStyle: FontStyle.italic)),
            const SizedBox(height: 12),
            Text(w.bn,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 34,
                    fontWeight: FontWeight.bold)),
            if (w.en.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(w.en,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white, fontSize: 20)),
            ],
            if (w.ex.isNotEmpty) ...[
              const SizedBox(height: 24),
              Text(w.ex,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white70, fontSize: 18)),
            ],
          ],
        ),
      ),
      const Color(0xFF00B894),
      const Color(0xFF55EFC4),
    );

    return GestureDetector(
      onTap: flip,
      child: AnimatedBuilder(
        animation: c,
        builder: (context, _) {
          final t = Curves.easeInOut.transform(c.value);
          final angle = t * math.pi;
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
      
