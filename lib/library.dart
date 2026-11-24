import 'dart:io';
import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'reader.dart';
import 'style.dart';
import 'vocab.dart';

class BookDb {
  static Future<Database> _db() async {
    final db = await Db.get();
    await db.execute(
        'CREATE TABLE IF NOT EXISTS pdf_books(id INTEGER PRIMARY KEY AUTOINCREMENT, title TEXT NOT NULL, path TEXT, url TEXT, chapters INTEGER NOT NULL DEFAULT 60, ts INTEGER NOT NULL)');
    await db.execute(
        'CREATE TABLE IF NOT EXISTS book_chapters(book_id INTEGER NOT NULL, no INTEGER NOT NULL, title TEXT NOT NULL, page INTEGER NOT NULL DEFAULT 0, done INTEGER NOT NULL DEFAULT 0, PRIMARY KEY(book_id, no))');
    return db;
  }

  static Future<List<Map<String, Object?>>> books() async {
    final db = await _db();
    return db.rawQuery(
        'SELECT b.*, (SELECT COUNT(*) FROM book_chapters c WHERE c.book_id = b.id AND c.done = 1 AND c.no <= b.chapters) AS donec FROM pdf_books b ORDER BY b.id DESC');
  }

  static Future<void> add(
      String title, String? path, String? url, int chapters) async {
    final db = await _db();
    await db.insert('pdf_books', {
      'title': title,
      'path': path,
      'url': url,
      'chapters': chapters,
      'ts': DateTime.now().millisecondsSinceEpoch,
    });
  }

  static Future<void> delete(Map<String, Object?> b) async {
    final db = await _db();
    final path = b['path'] as String?;
    if (path != null && path.isNotEmpty) {
      try {
        final f = File(path);
        if (await f.exists()) await f.delete();
      } catch (_) {}
    }
    await db.delete('book_chapters',
        where: 'book_id = ?', whereArgs: [b['id']]);
    await db.delete('pdf_books', where: 'id = ?', whereArgs: [b['id']]);
  }

  static Future<void> setCount(int id, int n) async {
    final db = await _db();
    await db.update('pdf_books', {'chapters': n},
        where: 'id = ?', whereArgs: [id]);
  }

  static Future<List<Map<String, Object?>>> chapters(int id, int n) async {
    final db = await _db();
    final batch = db.batch();
    for (var i = 1; i <= n; i++) {
      batch.insert(
          'book_chapters',
          {'book_id': id, 'no': i, 'title': 'অধ্যায় $i', 'page': 0, 'done': 0},
          conflictAlgorithm: ConflictAlgorithm.ignore);
    }
    await batch.commit(noResult: true);
    return db.query('book_chapters',
        where: 'book_id = ? AND no <= ?',
        whereArgs: [id, n],
        orderBy: 'no ASC');
  }

  static Future<void> setDone(int id, int no, bool done) async {
    final db = await _db();
    await db.update('book_chapters', {'done': done ? 1 : 0},
        where: 'book_id = ? AND no = ?', whereArgs: [id, no]);
  }

  static Future<void> setChapter(
      int id, int no, String title, int page) async {
    final db = await _db();
    await db.update('book_chapters', {'title': title, 'page': page},
        where: 'book_id = ? AND no = ?', whereArgs: [id, no]);
  }
}

const List<List<Color>> _covers = [
  [Color(0xFF1B2F4A), Color(0xFF3D5A80)],
  [Color(0xFFC05A2B), Color(0xFFE8955F)],
  [Color(0xFF00897B), Color(0xFF4DB6AC)],
  [Color(0xFF6C5CE7), Color(0xFFA29BFE)],
  [Color(0xFFE84393), Color(0xFFFD79A8)],
];

Future<bool> addBookDialog(BuildContext context) async {
  final t = TextEditingController();
  final n = TextEditingController(text: '60');
  final u = TextEditingController();
  PickedPdf? picked;
  var busy = false;
  final ok = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, set) => AlertDialog(
        title: const Text('নতুন PDF বই'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: t,
                decoration: const InputDecoration(
                    labelText: 'বইয়ের নাম *', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: n,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                    labelText: 'অধ্যায় সংখ্যা',
                    border: OutlineInputBorder()),
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                icon: const Icon(Icons.picture_as_pdf),
                label: Text(
                  busy
                      ? 'কপি হচ্ছে...'
                      : (picked?.name ?? 'ফোন থেকে PDF বাছুন'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                onPressed: busy
                    ? null
                    : () async {
                        set(() => busy = true);
                        try {
                          final r = await pickAndCopyPdf();
                          if (r != null) {
                            picked = r;
                            if (t.text.trim().isEmpty) {
                              t.text = r.name.replaceAll(
                                  RegExp(r'\.pdf$', caseSensitive: false), '');
                            }
                          }
                        } catch (_) {}
                        set(() => busy = false);
                      },
              ),
              const SizedBox(height: 10),
              const Text('অথবা PDF-এর লিংক দিন'),
              const SizedBox(height: 6),
              TextField(
                controller: u,
                keyboardType: TextInputType.url,
                decoration: const InputDecoration(
                    hintText: 'https://...', border: OutlineInputBorder()),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('বাতিল')),
          FilledButton(
              onPressed: busy ? null : () => Navigator.pop(ctx, true),
              child: const Text('সংরক্ষণ')),
        ],
      ),
    ),
  );
  if (ok != true) return false;
  final title = t.text.trim();
  var url = u.text.trim();
  if (title.isEmpty || (picked == null && url.isEmpty)) return false;
  if (url.isNotEmpty && !url.startsWith('http')) url = 'https://$url';
  final cnt = (parseNum(n.text) ?? 60).clamp(1, 500).toInt();
  await BookDb.add(title, picked?.path, url.isEmpty ? null : url, cnt);
  return true;
}

class BookShelf extends StatefulWidget {
  final int? limit;
  const BookShelf({super.key, this.limit});
  @override
  State<BookShelf> createState() => BookShelfState();
}

class BookShelfState extends State<BookShelf> {
  List<Map<String, Object?>> books = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    reload();
  }

  Future<void> reload() async {
    List<Map<String, Object?>> r = [];
    try {
      r = await BookDb.books();
    } catch (_) {}
    if (!mounted) return;
    setState(() {
      books = widget.limit == null ? r : r.take(widget.limit!).toList();
      loading = false;
    });
  }

  Future<void> open(Map<String, Object?> b) async {
    await Navigator.push(
        context, MaterialPageRoute(builder: (_) => BookPage(book: b)));
    reload();
  }

  Widget cover(Map<String, Object?> b) {
    final id = b['id'] as int;
    final total = (b['chapters'] as int?) ?? 60;
    final done = (b['donec'] as int?) ?? 0;
    final col = _covers[id % _covers.length];
    return GestureDetector(
      onTap: () => open(b),
      child: Container(
        decoration: BoxDecoration(
          color: cardBg(context),
          borderRadius: BorderRadius.circular(24),
          boxShadow: softShadow(context),
        ),
        child: Column(
          children: [
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(24)),
                  gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: col),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.picture_as_pdf,
                        color: Colors.white, size: 30),
                    const Spacer(),
                    Text('${b['title']}',
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
              child: Column(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: total == 0 ? 0 : done / total,
                      minHeight: 8,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text('$done/$total অধ্যায়',
                      style: TextStyle(fontSize: 13, color: softText(context))),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (books.isEmpty) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: cardBg(context),
          borderRadius: BorderRadius.circular(24),
        ),
        child: const Text(
            'এখনো কোনো বই নেই। লাইব্রেরি ট্যাবে গিয়ে "বই যোগ" চাপুন এবং আপনার PDF বই বেছে নিন।'),
      );
    }
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      crossAxisCount: 2,
      mainAxisSpacing: 14,
      crossAxisSpacing: 14,
      childAspectRatio: 0.78,
      children: [for (final b in books) cover(b)],
    );
  }
}

class LibraryPage extends StatefulWidget {
  const LibraryPage({super.key});
  @override
  State<LibraryPage> createState() => _LibraryPageState();
}

class _LibraryPageState extends State<LibraryPage> {
  final GlobalKey<BookShelfState> shelf = GlobalKey<BookShelfState>();

  Future<void> add() async {
    final done = await addBookDialog(context);
    if (done) shelf.currentState?.reload();
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.only(top: 8, bottom: 40),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              const Expanded(
                child: Text('বইয়ের সংগ্রহ',
                    style:
                        TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              ),
              FilledButton.icon(
                onPressed: add,
                icon: const Icon(Icons.add),
                label: const Text('বই যোগ'),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 14),
          child: Text(
              'বই চাপলে অধ্যায়ের তালিকা খুলবে। PDF অ্যাপের ভেতরেই পড়া যায় এবং লেখা সিলেক্ট করে কপি করা যায়।',
              style: TextStyle(fontSize: 13, color: softText(context))),
        ),
        BookShelf(key: shelf),
      ],
    );
  }
}

class BookPage extends StatefulWidget {
  final Map<String, Object?> book;
  const BookPage({super.key, required this.book});
  @override
  State<BookPage> createState() => _BookPageState();
}

class _BookPageState extends State<BookPage> {
  List<Map<String, Object?>> list = [];
  late int count = (widget.book['chapters'] as int?) ?? 60;
  bool loading = true;
  bool hinted = false;

  int get id => widget.book['id'] as int;
  String get title => '${widget.book['title']}';

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    final r = await BookDb.chapters(id, count);
    if (!mounted) return;
    setState(() {
      list = r;
      loading = false;
    });
  }

  void openReader(int page, String sub) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PdfReaderPage(
          title: sub.isEmpty ? title : '$title – $sub',
          path: widget.book['path'] as String?,
          url: widget.book['url'] as String?,
          startPage: page < 1 ? 1 : page,
        ),
      ),
    );
  }

  void openChapter(Map<String, Object?> c) {
    final page = (c['page'] as int?) ?? 0;
    if (page < 1 && !hinted) {
      hinted = true;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text(
              'এই অধ্যায়ের পৃষ্ঠা নম্বর দেওয়া নেই। অধ্যায় চেপে ধরে পৃষ্ঠা নম্বর বসান।')));
    }
    openReader(page, '${c['title']}');
  }

  Future<void> toggleDone(Map<String, Object?> c) async {
    final now = (c['done'] as int?) == 1;
    await BookDb.setDone(id, c['no'] as int, !now);
    load();
  }

  Future<void> editChapter(Map<String, Object?> c) async {
    final t = TextEditingController(text: '${c['title']}');
    final pg = TextEditingController(
        text: ((c['page'] as int?) ?? 0) > 0 ? '${c['page']}' : '');
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('অধ্যায় ${c['no']}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: t,
              decoration: const InputDecoration(
                  labelText: 'অধ্যায়ের নাম', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: pg,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                  labelText: 'PDF-এর কত নম্বর পৃষ্ঠা থেকে শুরু',
                  border: OutlineInputBorder()),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('বাতিল')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('সংরক্ষণ')),
        ],
      ),
    );
    if (ok != true) return;
    final name = t.text.trim().isEmpty ? 'অধ্যায় ${c['no']}' : t.text.trim();
    await BookDb.setChapter(id, c['no'] as int, name, parseNum(pg.text) ?? 0);
    load();
  }

  Future<void> bulk() async {
    final t = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('সব অধ্যায় একসঙ্গে বসান'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                  'প্রতি লাইনে একটি অধ্যায়। আগে পৃষ্ঠা নম্বর, তারপর | চিহ্ন, তারপর নাম। উদাহরণ:\n5|한글 익히기 I\n12|한글 익히기 II\n20|교실 한국어',
                  style: TextStyle(fontSize: 13)),
              const SizedBox(height: 10),
              TextField(
                controller: t,
                minLines: 6,
                maxLines: 12,
                decoration: const InputDecoration(border: OutlineInputBorder()),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('বাতিল')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('প্রয়োগ')),
        ],
      ),
    );
    if (ok != true) return;
    final lines = t.text
        .split('\n')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
    for (var i = 0; i < lines.length && i < count; i++) {
      final parts = lines[i].split('|');
      var page = 0;
      var name = lines[i];
      if (parts.length >= 2) {
        page = parseNum(parts.first) ?? 0;
        name = parts.sublist(1).join('|').trim();
      }
      if (name.isEmpty) name = 'অধ্যায় ${i + 1}';
      await BookDb.setChapter(id, i + 1, name, page);
    }
    load();
  }

  Future<void> changeCount() async {
    final c = TextEditingController(text: '$count');
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('অধ্যায় সংখ্যা'),
        content: TextField(
          controller: c,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('বাতিল')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('সংরক্ষণ')),
        ],
      ),
    );
    if (ok != true) return;
    final n = (parseNum(c.text) ?? count).clamp(1, 500).toInt();
    await BookDb.setCount(id, n);
    count = n;
    load();
  }

  Future<void> deleteBook() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('বইটি মুছবেন?'),
        content: Text(title),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('না')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('মুছুন')),
        ],
      ),
    );
    if (ok != true) return;
    await BookDb.delete(widget.book);
    if (mounted) Navigator.pop(context);
  }

  Widget tile(Map<String, Object?> c) {
    final done = (c['done'] as int?) == 1;
    final dark = isDark(context);
    final bg = done
        ? (dark ? const Color(0xFF2F6B45) : const Color(0xFFD8EBCB))
        : cardBg(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Container(
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(24),
          boxShadow: softShadow(context),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(24),
            onTap: () => openChapter(c),
            onLongPress: () => editChapter(c),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                children: [
                  SizedBox(
                    width: 48,
                    child: Text('${c['no']}',
                        style: const TextStyle(
                            fontSize: 26, fontWeight: FontWeight.bold)),
                  ),
                  Container(
                      width: 2,
                      height: 34,
                      margin: const EdgeInsets.only(right: 16),
                      color: Colors.black26),
                  Expanded(
                    child: Text('${c['title']}',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 19, fontWeight: FontWeight.w600)),
                  ),
                  IconButton(
                    icon: Icon(
                      done ? Icons.check_circle : Icons.radio_button_unchecked,
                      color: done ? const Color(0xFF00B000) : Colors.grey,
                      size: 32,
                    ),
                    onPressed: () => toggleDone(c),
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
    return Scaffold(
      appBar: AppBar(
        title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
        actions: [
          IconButton(
            icon: const Icon(Icons.menu_book),
            tooltip: 'PDF পড়ুন',
            onPressed: () => openReader(1, ''),
          ),
          PopupMenuButton<String>(
            onSelected: (v) {
              if (v == 'bulk') bulk();
              if (v == 'count') changeCount();
              if (v == 'del') deleteBook();
            },
            itemBuilder: (c) => const [
              PopupMenuItem(value: 'bulk', child: Text('অধ্যায়ের নাম একসঙ্গে বসান')),
              PopupMenuItem(value: 'count', child: Text('অধ্যায় সংখ্যা বদলান')),
              PopupMenuItem(value: 'del', child: Text('বই মুছুন')),
            ],
          ),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.only(top: 8, bottom: 30),
              itemCount: list.length,
              itemBuilder: (c, i) => tile(list[i]),
            ),
    );
  }
}
