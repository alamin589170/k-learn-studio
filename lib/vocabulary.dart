import 'package:flutter/material.dart';
import 'filters.dart';
import 'word_editor.dart';
import 'resume.dart';
import 'style.dart';
import 'ui.dart';
import 'vocab.dart';

class VocabPage extends StatefulWidget {
  final bool savedOnly;
  const VocabPage({super.key, this.savedOnly = false});
  @override
  State<VocabPage> createState() => _VocabPageState();
}

class _VocabPageState extends State<VocabPage> {
  List<Word> all = [];
  List<Word> words = [];
  final WordFilter filter = WordFilter();
  final ScrollController sc = ScrollController();
  String q = '';
  bool loading = true;
  static const double rowH = 132;
  bool restored = false;
  String get _key => widget.savedOnly ? 'vocab_saved' : 'vocab';

  @override
  void initState() {
    super.initState();
    load();
  }

  @override
  void dispose() {
    sc.dispose();
    super.dispose();
  }

  Future<void> load() async {
    final my = q;
    final r = await Db.search(my, savedOnly: widget.savedOnly);
    if (!mounted || my != q) return;
    setState(() {
      all = r;
      words = applyFilter(r, filter);
      loading = false;
    });
    if (!restored) {
      restored = true;
      final idx = await Resume.getInt(_key);
      if (idx != null && idx > 0 && mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!sc.hasClients) return;
          final t = (idx * rowH).clamp(0.0, sc.position.maxScrollExtent).toDouble();
          sc.jumpTo(t);
        });
      }
    }
  }

  void refilter() {
    setState(() => words = applyFilter(all, filter));
    if (sc.hasClients) sc.jumpTo(0);
  }

  Future<void> jump() async {
    final n = await askNumber(context, words.length);
    if (n == null || !sc.hasClients) return;
    final maxExt = sc.position.maxScrollExtent;
    final target = ((n - 1) * rowH).clamp(0.0, maxExt).toDouble();
    sc.animateTo(target,
        duration: const Duration(milliseconds: 450), curve: Curves.easeOut);
  }

  Future<void> toggle(Word w) async {
    w.saved = !w.saved;
    await Db.update(w);
    if (!mounted) return;
    setState(() {
      if (widget.savedOnly && !w.saved) {
        words.remove(w);
        all.remove(w);
      }
    });
  }

  Future<void> confirmDelete(Word w) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('শব্দটি মুছবেন?'),
        content: Text(w.ko),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(c, false),
              child: const Text('না')),
          FilledButton(
              onPressed: () => Navigator.pop(c, true),
              child: const Text('মুছুন')),
        ],
      ),
    );
    if (ok == true) {
      await Db.delete(w.id!);
      load();
    }
  }

  Widget field(TextEditingController c, String label) => Padding(
        padding: const EdgeInsets.only(top: 8),
        child: TextField(
          controller: c,
          decoration: InputDecoration(
              labelText: label, border: const OutlineInputBorder()),
        ),
      );

  Future<void> edit([Word? w]) async {
    if (await showWordEditor(context, word: w)) load();
  }

  void detail(Word w) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (c) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  WordThumb(word: w, size: 72),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(w.ko,
                        style: const TextStyle(
                            fontSize: 30, fontWeight: FontWeight.bold)),
                  ),
                  IconButton(
                      iconSize: 32,
                      icon: const Icon(Icons.volume_up),
                      onPressed: () => speakKorean(w.ko)),
                ],
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                children: [
                  Chip(label: Text(posName(posOf(w)))),
                  Chip(label: Text(catName(catOf(w)))),
                ],
              ),
              if (w.pron.isNotEmpty)
                Text(w.pron,
                    style: const TextStyle(
                        fontSize: 16, fontStyle: FontStyle.italic)),
              const SizedBox(height: 8),
              SelectableText(w.bn,
                  style: const TextStyle(
                      fontSize: 22, fontWeight: FontWeight.bold)),
              if (w.en.isNotEmpty)
                SelectableText(w.en, style: const TextStyle(fontSize: 16)),
              if (w.ex.isNotEmpty) ...[
                const SizedBox(height: 10),
                SelectableText(w.ex, style: const TextStyle(fontSize: 16)),
              ],
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  icon: const Icon(Icons.edit),
                  label: const Text('সম্পাদনা'),
                  onPressed: () {
                    Navigator.pop(c);
                    edit(w);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget card(Word w, int i) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Container(
        decoration: flatDeco(context, 24),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(24),
            onTap: () => detail(w),
            onLongPress: () => confirmDelete(w),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 4, 8),
              child: Row(
                children: [
                  WordThumb(word: w, size: 68),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${i + 1}. ${w.ko}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontSize: 20, fontWeight: FontWeight.bold)),
                        if (w.pron.isNotEmpty)
                          Text(w.pron,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                  fontSize: 13,
                                  fontStyle: FontStyle.italic,
                                  color: cs.primary)),
                        Text(w.bn,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w600)),
                        if (w.en.isNotEmpty)
                          Text(w.en,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                  fontSize: 13, color: softText(context))),
                      ],
                    ),
                  ),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                          visualDensity: VisualDensity.compact,
                          icon: const Icon(Icons.volume_up),
                          onPressed: () => speakKorean(w.ko)),
                      IconButton(
                          visualDensity: VisualDensity.compact,
                          icon: Icon(
                              w.saved ? Icons.bookmark : Icons.bookmark_border,
                              color: w.saved ? cs.primary : null),
                          onPressed: () => toggle(w)),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: TextField(
                onChanged: (v) {
                  q = v;
                  load();
                },
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search),
                  hintText: 'শব্দ খুঁজুন...',
                  filled: true,
                  fillColor: cardBg(context),
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(28),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            FilterBar(
              filter: filter,
              total: words.length,
              onChanged: refilter,
              onJump: jump,
            ),
            Expanded(
              child: loading
                  ? const Center(child: CircularProgressIndicator())
                  : words.isEmpty
                      ? Center(
                          child: Text(widget.savedOnly
                              ? 'কোনো সংরক্ষিত শব্দ নেই'
                              : 'কোনো শব্দ পাওয়া যায়নি'))
                      : NotificationListener<ScrollEndNotification>(
                          onNotification: (n) {
                            if (q.isEmpty && !filter.active && sc.hasClients) {
                              Resume.setInt(_key, (sc.offset / rowH).round());
                            }
                            return false;
                          },
                          child: ListView.builder(
                          controller: sc,
                          itemExtent: rowH,
                          cacheExtent: 400,
                          addAutomaticKeepAlives: false,
                          padding: const EdgeInsets.only(bottom: 90),
                          itemCount: words.length,
                          itemBuilder: (c, i) => card(words[i], i),
                        )),
            ),
          ],
        ),
        if (!widget.savedOnly)
          Positioned(
            right: 16,
            bottom: 16,
            child: FloatingActionButton.small(
              heroTag: 'add_word_fab',
              onPressed: () => edit(),
              child: const Icon(Icons.add),
            ),
          ),
      ],
    );
  }
}
