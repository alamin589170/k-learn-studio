import 'package:flutter/material.dart';
import 'style.dart';
import 'vocab.dart';
import 'word_meta.dart';

class WordFilter {
  String pos = 'all';
  String cat = 'all';
  bool get active => pos != 'all' || cat != 'all';
  void clear() {
    pos = 'all';
    cat = 'all';
  }
}

String _metaOf(Word w) => wordMeta[w.ko] ?? 'other|other';
String posOf(Word w) => _metaOf(w).split('|').first;
String catOf(Word w) => _metaOf(w).split('|').last;

String posName(String code) {
  for (final p in wordPos) {
    if (p[0] == code) return p[1];
  }
  return 'Other';
}

String catName(String code) {
  for (final c in wordCats) {
    if (c[0] == code) return c[1];
  }
  return 'Other';
}

List<Word> applyFilter(List<Word> src, WordFilter f) {
  if (!f.active) return src;
  return src
      .where((w) =>
          (f.pos == 'all' || posOf(w) == f.pos) &&
          (f.cat == 'all' || catOf(w) == f.cat))
      .toList();
}

Future<int?> askNumber(BuildContext context, int max,
    {String title = 'কত নম্বরে যাবেন?'}) async {
  if (max <= 0) return null;
  final c = TextEditingController();
  final r = await showDialog<int>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: TextField(
        controller: c,
        autofocus: true,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(
            hintText: '1 – $max', border: const OutlineInputBorder()),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('বাতিল')),
        FilledButton(
            onPressed: () => Navigator.pop(ctx, parseNum(c.text)),
            child: const Text('যান')),
      ],
    ),
  );
  if (r == null) return null;
  return r.clamp(1, max).toInt();
}

Future<bool> showFilterSheet(BuildContext context, WordFilter f) async {
  var changed = false;
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, set) {
        Widget head(String t) => Padding(
              padding: const EdgeInsets.fromLTRB(0, 16, 0, 8),
              child: Text(t,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold)),
            );
        return SizedBox(
          height: MediaQuery.of(ctx).size.height * 0.8,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text('ফিল্টার',
                        style: TextStyle(
                            fontSize: 22, fontWeight: FontWeight.bold)),
                  ),
                  TextButton(
                    onPressed: () {
                      f.clear();
                      changed = true;
                      set(() {});
                    },
                    child: const Text('পরিষ্কার'),
                  ),
                ],
              ),
              head('Part of speech'),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ChoiceChip(
                    label: const Text('All'),
                    selected: f.pos == 'all',
                    onSelected: (_) {
                      f.pos = 'all';
                      changed = true;
                      set(() {});
                    },
                  ),
                  for (final p in wordPos)
                    ChoiceChip(
                      label: Text(p[1]),
                      selected: f.pos == p[0],
                      onSelected: (_) {
                        f.pos = p[0];
                        changed = true;
                        set(() {});
                      },
                    ),
                ],
              ),
              head('Category'),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ChoiceChip(
                    label: const Text('All categories'),
                    selected: f.cat == 'all',
                    onSelected: (_) {
                      f.cat = 'all';
                      changed = true;
                      set(() {});
                    },
                  ),
                  for (final c in wordCats)
                    ChoiceChip(
                      label: Text(c[1]),
                      selected: f.cat == c[0],
                      onSelected: (_) {
                        f.cat = c[0];
                        changed = true;
                        set(() {});
                      },
                    ),
                ],
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('শব্দ দেখান'),
              ),
            ],
          ),
        );
      },
    ),
  );
  return changed;
}

class FilterBar extends StatelessWidget {
  final WordFilter filter;
  final int total;
  final VoidCallback onChanged;
  final VoidCallback onJump;
  const FilterBar(
      {super.key,
      required this.filter,
      required this.total,
      required this.onChanged,
      required this.onJump});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    Widget chip(String code, String label) => Padding(
          padding: const EdgeInsets.only(right: 8),
          child: ChoiceChip(
            label: Text(label),
            selected: filter.pos == code,
            selectedColor: cs.primary,
            labelStyle: TextStyle(
                color: filter.pos == code ? Colors.white : null,
                fontWeight: FontWeight.w600),
            onSelected: (_) {
              filter.pos = code;
              onChanged();
            },
          ),
        );
    return Column(
      children: [
        SizedBox(
          height: 42,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              chip('all', 'All'),
              for (final p in wordPos) chip(p[0], p[1]),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
          child: Row(
            children: [
              FilledButton.tonalIcon(
                icon: const Icon(Icons.tune, size: 18),
                label: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 120),
                  child: Text(
                    filter.cat == 'all' ? 'Category' : catName(filter.cat),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                onPressed: () async {
                  if (await showFilterSheet(context, filter)) onChanged();
                },
              ),
              const Spacer(),
              Text('$total শব্দ',
                  style: TextStyle(color: softText(context), fontSize: 13)),
              const Spacer(),
              FilledButton.tonalIcon(
                icon: const Icon(Icons.tag, size: 18),
                label: const Text('নম্বরে যান'),
                onPressed: onJump,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
