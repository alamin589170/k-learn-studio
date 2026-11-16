import 'package:flutter/material.dart';
import 'flipcard.dart';
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
    if (!mounted) return;
    setState(() {
      words = r;
      loading = false;
    });
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
    final ko = TextEditingController();
    final pron = TextEditingController();
    final bn = TextEditingController();
    final en = TextEditingController();
    final ex = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('নতুন শব্দ'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              field(ko, 'কোরিয়ান শব্দ *'),
              field(pron, 'বাংলা উচ্চারণ'),
              field(bn, 'বাংলা অর্থ *'),
              field(en, 'ইংরেজি অর্থ (ছবি খোঁজার জন্য)'),
              field(ex, 'উদাহরণ বাক্য'),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(c, false),
              child: const Text('বাতিল')),
          FilledButton(
              onPressed: () => Navigator.pop(c, true),
              child: const Text('সংরক্ষণ')),
        ],
      ),
    );
    if (ok != true) return;
    if (ko.text.trim().isEmpty || bn.text.trim().isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('কোরিয়ান শব্দ ও বাংলা অর্থ দিতে হবে')));
      }
      return;
    }
    await Db.insert(Word(
      ko: ko.text.trim(),
      pron: pron.text.trim(),
      bn: bn.text.trim(),
      en: en.text.trim(),
      ex: ex.text.trim(),
    ));
    final r = await Db.search('');
    if (!mounted) return;
    setState(() {
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
          key: ValueKey('${words[i].id}-$i'),
          word: words[i],
        ),
      ),
    );
  }

  Widget bottomBar(Word w) {
    return Padding(
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

  @override
  Widget build(BuildContext context) {
    final appBar = AppBar(
      title: const Text('3D ফ্ল্যাশকার্ড'),
      actions: [
        IconButton(
          icon: const Icon(Icons.add),
          tooltip: 'নতুন শব্দ',
          onPressed: addWord,
        ),
      ],
    );
    if (loading) {
      return Scaffold(
        appBar: appBar,
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    if (words.isEmpty) {
      return Scaffold(
        appBar: appBar,
        body: const Center(child: Text('কোনো শব্দ নেই।')),
      );
    }
    if (index >= words.length) index = words.length - 1;
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
                itemBuilder: (context, i) => page(i),
              ),
            ),
            Text('${index + 1} / ${words.length}   (সোয়াইপ করুন)'),
            bottomBar(w),
          ],
        ),
      ),
    );
  }
}
