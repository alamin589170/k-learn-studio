import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'style.dart';
import 'vocab.dart';
import 'wordimg.dart';

// নতুন শব্দ যোগ ও আগের শব্দ (ফ্ল্যাশকার্ড) সম্পাদনা: একই পর্দা
// সংরক্ষিত হলে true ফেরে। word দিলে সেই শব্দই বদলায়, নতুন কার্ড হয় না।
Future<bool> showWordEditor(BuildContext context, {Word? word}) async {
  final r = await showDialog<bool>(
    context: context,
    builder: (_) => _WordEditor(word: word),
  );
  return r == true;
}

class _WordEditor extends StatefulWidget {
  final Word? word;
  const _WordEditor({this.word});
  @override
  State<_WordEditor> createState() => _WordEditorState();
}

class _WordEditorState extends State<_WordEditor> {
  late final TextEditingController ko =
      TextEditingController(text: widget.word?.ko ?? '');
  late final TextEditingController pron =
      TextEditingController(text: widget.word?.pron ?? '');
  late final TextEditingController bn =
      TextEditingController(text: widget.word?.bn ?? '');
  late final TextEditingController en =
      TextEditingController(text: widget.word?.en ?? '');
  late final TextEditingController ex =
      TextEditingController(text: widget.word?.ex ?? '');
  File? current;
  String? picked;
  bool removed = false;
  bool research = false;
  String? error;

  @override
  void initState() {
    super.initState();
    final id = widget.word?.id;
    if (id != null) {
      WordImg.cached(id).then((f) {
        if (mounted) setState(() => current = f);
      });
    }
  }

  @override
  void dispose() {
    ko.dispose();
    pron.dispose();
    bn.dispose();
    en.dispose();
    ex.dispose();
    super.dispose();
  }

  Future<void> pick(ImageSource s) async {
    try {
      final x = await ImagePicker()
          .pickImage(source: s, maxWidth: 1280, imageQuality: 90);
      if (x == null || !mounted) return;
      setState(() {
        picked = x.path;
        removed = false;
        research = false;
      });
    } catch (_) {
      if (mounted) setState(() => error = 'ছবি আনা গেল না');
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

  Widget preview() {
    Widget inner;
    if (picked != null) {
      inner = Image.file(File(picked!), fit: BoxFit.cover);
    } else if (removed || research) {
      inner = Icon(removed ? Icons.hide_image_outlined : Icons.travel_explore,
          size: 40, color: softText(context));
    } else if (current != null) {
      inner = Image.file(current!, fit: BoxFit.cover, cacheWidth: 400);
    } else {
      inner = Icon(Icons.image_outlined, size: 40, color: softText(context));
    }
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: palOf(context).border),
      ),
      clipBehavior: Clip.antiAlias,
      alignment: Alignment.center,
      child: inner,
    );
  }

  Future<void> save() async {
    final k = ko.text.trim(), b = bn.text.trim();
    if (k.isEmpty || b.isEmpty) {
      setState(() => error = 'কোরিয়ান শব্দ ও বাংলা অর্থ দিতে হবে');
      return;
    }
    final old = widget.word;
    int? id = old?.id;
    var meaningChanged = false;
    if (old == null) {
      await Db.insert(Word(
          ko: k,
          pron: pron.text.trim(),
          bn: b,
          en: en.text.trim(),
          ex: ex.text.trim()));
      final db = await Db.get();
      final r = await db.rawQuery('SELECT MAX(id) AS m FROM words');
      id = (r.first['m'] as int?);
    } else {
      meaningChanged = old.bn != b || old.en != en.text.trim();
      old.ko = k;
      old.pron = pron.text.trim();
      old.bn = b;
      old.en = en.text.trim();
      old.ex = ex.text.trim();
      await Db.update(old);
    }
    if (id != null) {
      if (picked != null) {
        await WordImg.setFromFile(id, picked!);
      } else if (removed) {
        await WordImg.clear(id);
      } else if (research) {
        await WordImg.reset(id, force: true);
      } else if (meaningChanged) {
        await WordImg.reset(id);
      }
    }
    if (mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final isNew = widget.word == null;
    return AlertDialog(
      title: Text(isNew ? 'নতুন শব্দ' : 'শব্দ সম্পাদনা'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            preview(),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 0,
              alignment: WrapAlignment.center,
              children: [
                ActionChip(
                  avatar: const Icon(Icons.photo_library, size: 18),
                  label: const Text('গ্যালারি'),
                  onPressed: () => pick(ImageSource.gallery),
                ),
                ActionChip(
                  avatar: const Icon(Icons.photo_camera, size: 18),
                  label: const Text('ক্যামেরা'),
                  onPressed: () => pick(ImageSource.camera),
                ),
                if (!isNew)
                  ActionChip(
                    avatar: const Icon(Icons.travel_explore, size: 18),
                    label: const Text('অটো ছবি'),
                    onPressed: () => setState(() {
                      research = true;
                      picked = null;
                      removed = false;
                    }),
                  ),
                ActionChip(
                  avatar: const Icon(Icons.delete_outline, size: 18),
                  label: const Text('সরান'),
                  onPressed: () => setState(() {
                    removed = true;
                    picked = null;
                    research = false;
                  }),
                ),
              ],
            ),
            field(ko, 'কোরিয়ান শব্দ *'),
            field(pron, 'বাংলা উচ্চারণ'),
            field(bn, 'বাংলা অর্থ *'),
            field(en, 'ইংরেজি অর্থ'),
            field(ex, 'উদাহরণ বাক্য'),
            if (error != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(error!,
                    style: TextStyle(color: Theme.of(context).colorScheme.error)),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('বাতিল')),
        FilledButton(onPressed: save, child: const Text('সংরক্ষণ')),
      ],
    );
  }
}
