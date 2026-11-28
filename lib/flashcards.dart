import 'package:flutter/material.dart';
import 'filters.dart';
import 'flipcard.dart';
import 'style.dart';
import 'report.dart';
import 'resume.dart';
import 'vocab.dart';
import 'word_editor.dart';
import 'wordimg.dart';

class FlashcardPage extends StatefulWidget {
  const FlashcardPage({super.key});
  @override
  State<FlashcardPage> createState() => _FlashcardPageState();
}

class _FlashcardPageState extends State<FlashcardPage> {
  final PageController pc = PageController();
  final WordFilter filter = WordFilter();
  List<Word> all = [];
  List<Word> words = [];
  int index = 0;
  int ver = 0;
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
    final last = await Resume.getInt('flash');
    if (!mounted) return;
    var start = 0;
    final ws = applyFilter(r, filter);
    if (last != null) {
      final k = ws.indexWhere((w) => w.id == last);
      if (k > 0) start = k;
    }
    setState(() {
      all = r;
      words = ws;
      loading = false;
      index = start;
    });
    if (start > 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (pc.hasClients) pc.jumpToPage(start);
      });
    }
  }

  void refilter() {
    if (pc.hasClients) pc.jumpToPage(0);
    setState(() {
      words = applyFilter(all, filter);
      index = 0;
    });
  }

  Future<void> openFilter() async {
    if (await showFilterSheet(context, filter)) refilter();
  }

  Future<void> jump() async {
    final n = await askNumber(context, words.length);
    if (n == null) return;
    if (pc.hasClients) pc.jumpToPage(n - 1);
    setState(() => index = n - 1);
  }

  void shuffle() {
    words = List<Word>.of(words)..shuffle();
    if (pc.hasClients) pc.jumpToPage(0);
    setState(() => index = 0);
  }

  Future<void> editCurrent() async {
    if (words.isEmpty) return;
    final w = words[index.clamp(0, words.length - 1).toInt()];
    if (await showWordEditor(context, word: w)) {
      if (!mounted) return;
      setState(() => ver++);
    }
  }

  void prefetch(int i) {
    for (final j in [i + 1, i + 2]) {
      if (j >= 0 && j < words.length) {
        WordImg.fetch(words[j]);
      }
    }
  }

  Future<void> toggleSave() async {
    final w = words[index];
    w.saved = !w.saved;
    await Db.update(w);
    setState(() {});
  }

  Widget field(TextEditingController c, String label) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: TextField(
        controller: c,
        decoration: InputDecoration(
            labelText: label, border: const OutlineInputBorder()),
      ),
    );
  }

  Future<void> addWord() async {
    if (!await showWordEditor(context)) return;
    filter.clear();
    final r = await Db.search('');
    if (!mounted) return;
    setState(() {
      all = r;
      words = r;
      loading = false;
      index = r.length - 1;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (pc.hasClients && words.isNotEmpty) {
        pc.jumpToPage(words.length - 1);
      }
    });
  }

  Widget page(int i) {
    return AnimatedBuilder(
      animation: pc,
      builder: (context, child) {
        double d = (index - i).toDouble();
        if (pc.hasClients && pc.position.haveDimensions) {
          d = (pc.page ?? i.toDouble()) - i;
        }
        d = d.clamp(-1.0, 1.0).toDouble();
        return Transform(
          alignment: d > 0 ? Alignment.centerRight : Alignment.centerLeft,
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.001)
            ..rotateY(d * 0.8),
          child: child,
        );
      },
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 8, 14, 8),
        child: FlipCard(
          key: ValueKey('${words[i].id}-$i-$ver'),
          word: words[i],
        ),
      ),
    );
  }

  Widget bottomBar(Word w) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
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
            icon: Icon(
              w.saved ? Icons.star : Icons.star_border,
              color: w.saved ? Colors.amber : null,
            ),
            onPressed: toggleSave,
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget bar() {
    return AppBar(
      title: const Text('3D ফ্ল্যাশকার্ড'),
      actions: [
        IconButton(
          icon: Badge(
            isLabelVisible: filter.active,
            child: const Icon(Icons.tune),
          ),
          tooltip: 'ফিল্টার',
          onPressed: openFilter,
        ),
        IconButton(
          icon: const Icon(Icons.tag),
          tooltip: 'নম্বরে যান',
          onPressed: jump,
        ),
        IconButton(
          icon: const Icon(Icons.flag_outlined),
          tooltip: 'ভুল জানান',
          onPressed: () {
            if (words.isEmpty) return;
            final w = words[index.clamp(0, words.length - 1).toInt()];
            showReportDialog(context,
                'ফ্ল্যাশকার্ড #${index + 1}: ${w.ko} — ${w.bn}');
          },
        ),
        IconButton(
          icon: const Icon(Icons.edit),
          tooltip: 'এই কার্ড সম্পাদনা',
          onPressed: editCurrent,
        ),
        IconButton(
          icon: const Icon(Icons.add),
          tooltip: 'নতুন শব্দ',
          onPressed: addWord,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return Scaffold(
        appBar: bar(),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    if (words.isEmpty) {
      return Scaffold(
        appBar: bar(),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('এই ফিল্টারে কোনো শব্দ নেই।'),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () {
                  filter.clear();
                  refilter();
                },
                child: const Text('ফিল্টার পরিষ্কার করুন'),
              ),
            ],
          ),
        ),
      );
    }
    if (index >= words.length) index = words.length - 1;
    final w = words[index];
    return Scaffold(
      appBar: bar(),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: pc,
                itemCount: words.length,
                onPageChanged: (i) {
                  setState(() => index = i);
                  prefetch(i);
                  final id = words[i].id;
                  if (id != null) Resume.setInt('flash', id);
                },
                itemBuilder: (context, i) => page(i),
              ),
            ),
            InkWell(
              onTap: jump,
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                child: Column(
                  children: [
                    Text('${index + 1} / ${words.length}   ▸ নম্বরে যান',
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text('${posName(posOf(w))} · ${catName(catOf(w))}',
                        style:
                            TextStyle(fontSize: 12, color: softText(context))),
                  ],
                ),
              ),
            ),
            bottomBar(w),
          ],
        ),
      ),
    );
  }
}
