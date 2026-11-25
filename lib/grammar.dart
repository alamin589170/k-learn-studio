import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'filters.dart' show askNumber;
import 'grammar120_data.dart';
import 'grammar_data.dart';
import 'reader.dart';
import 'style.dart';
import 'vocab.dart';

class MyLesson {
  int? id;
  String title, intro, examples;
  MyLesson(
      {this.id, required this.title, this.intro = '', this.examples = ''});
}

class GrammarDb {
  static Future<Database> _open() async {
    final db = await Db.get();
    await db.execute(
        'CREATE TABLE IF NOT EXISTS my_grammar(id INTEGER PRIMARY KEY AUTOINCREMENT, title TEXT, intro TEXT, examples TEXT)');
    await db.execute(
        'CREATE TABLE IF NOT EXISTS grammar_pdfs(id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL, path TEXT NOT NULL, ts INTEGER NOT NULL)');
    return db;
  }

  static Future<List<MyLesson>> all() async {
    final db = await _open();
    final rows = await db.query('my_grammar', orderBy: 'id DESC');
    return rows
        .map((m) => MyLesson(
              id: m['id'] as int,
              title: (m['title'] ?? '') as String,
              intro: (m['intro'] ?? '') as String,
              examples: (m['examples'] ?? '') as String,
            ))
        .toList();
  }

  static Future<void> insert(MyLesson l) async {
    final db = await _open();
    await db.insert('my_grammar',
        {'title': l.title, 'intro': l.intro, 'examples': l.examples});
  }

  static Future<void> update(MyLesson l) async {
    final db = await _open();
    await db.update('my_grammar',
        {'title': l.title, 'intro': l.intro, 'examples': l.examples},
        where: 'id = ?', whereArgs: [l.id]);
  }

  static Future<void> delete(int id) async {
    final db = await _open();
    await db.delete('my_grammar', where: 'id = ?', whereArgs: [id]);
  }

  static Future<List<Map<String, Object?>>> pdfs() async {
    final db = await _open();
    return db.query('grammar_pdfs', orderBy: 'id DESC');
  }

  static Future<void> addPdf(String name, String path) async {
    final db = await _open();
    await db.insert('grammar_pdfs', {
      'name': name,
      'path': path,
      'ts': DateTime.now().millisecondsSinceEpoch,
    });
  }

  static Future<void> deletePdf(int id) async {
    final db = await _open();
    await db.delete('grammar_pdfs', where: 'id = ?', whereArgs: [id]);
  }
}

List<List<String>> parseExamples(String s) {
  final out = <List<String>>[];
  for (final raw in s.split('\n')) {
    final line = raw.trim();
    if (line.isEmpty) continue;
    final parts = line.split('|').map((e) => e.trim()).toList();
    while (parts.length < 3) {
      parts.add('');
    }
    out.add(parts.sublist(0, 3));
  }
  return out;
}

class LessonView extends StatelessWidget {
  final String title;
  final String intro;
  final List<List<String>> examples;
  const LessonView(
      {super.key,
      required this.title,
      required this.intro,
      required this.examples});

  Widget exampleCard(List<String> e) {
    final sub = <String>[];
    if (e[1].isNotEmpty) sub.add(e[1]);
    if (e[2].isNotEmpty) sub.add(e[2]);
    return Card(
      child: ListTile(
        title: Text(e[0],
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        subtitle: sub.isEmpty ? null : Text(sub.join('\n')),
        trailing: IconButton(
          icon: const Icon(Icons.volume_up),
          onPressed: () => speakKorean(e[0]),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final children = <Widget>[];
    if (intro.isNotEmpty) {
      children.add(
          SelectableText(intro, style: const TextStyle(fontSize: 17, height: 1.5)));
      children.add(const SizedBox(height: 16));
    }
    if (examples.isNotEmpty) {
      children.add(const Text('উদাহরণ',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)));
      children.add(const SizedBox(height: 8));
      for (final e in examples) {
        children.add(exampleCard(e));
      }
    }
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: children,
      ),
    );
  }
}

// ---------- মূল পেজ (৩টি ট্যাব) ----------

class GrammarPage extends StatelessWidget {
  final VoidCallback? onMenu;
  const GrammarPage({super.key, this.onMenu});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          scrolledUnderElevation: 0,
          centerTitle: true,
          leading: onMenu == null
              ? null
              : IconButton(icon: const Icon(Icons.menu), onPressed: onMenu),
          title: const Text('গ্রামার',
              style: TextStyle(fontWeight: FontWeight.bold)),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'EPS ব্যাকরণ'),
              Tab(text: 'পাঠ'),
              Tab(text: 'PDF'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _G120Tab(),
            _LessonsTab(),
            _PdfTab(),
          ],
        ),
      ),
    );
  }
}

// ---------- ট্যাব ১: PDF-এর ব্যাকরণ তালিকা ----------

List<String> _splitTitle(String t) {
  final i = t.indexOf(' (');
  if (i < 0) return [t, ''];
  var sub = t.substring(i + 2).trim();
  if (sub.endsWith(')')) sub = sub.substring(0, sub.length - 1);
  return [t.substring(0, i).trim(), sub];
}

class _G120Tab extends StatefulWidget {
  const _G120Tab();
  @override
  State<_G120Tab> createState() => _G120TabState();
}

class _G120TabState extends State<_G120Tab> {
  final ScrollController sc = ScrollController();
  String q = '';
  static const double rowH = 80;

  List<G120> get shown {
    final t = q.trim().toLowerCase();
    if (t.isEmpty) return grammar120;
    final n = parseNum(t);
    return grammar120
        .where((g) => g.title.toLowerCase().contains(t) || g.n == n)
        .toList();
  }

  @override
  void dispose() {
    sc.dispose();
    super.dispose();
  }

  Future<void> jump(int total) async {
    final n = await askNumber(context, total);
    if (n == null || !sc.hasClients) return;
    final target =
        ((n - 1) * rowH).clamp(0.0, sc.position.maxScrollExtent).toDouble();
    sc.animateTo(target,
        duration: const Duration(milliseconds: 400), curve: Curves.easeOut);
  }

  @override
  Widget build(BuildContext context) {
    final list = shown;
    final cs = Theme.of(context).colorScheme;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  onChanged: (v) => setState(() => q = v),
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.search),
                    hintText: 'নাম বা নম্বর দিয়ে খুঁজুন',
                    filled: true,
                    fillColor: cardBg(context),
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(28),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filledTonal(
                icon: const Icon(Icons.tag),
                tooltip: 'নম্বরে যান',
                onPressed: () => jump(list.length),
              ),
            ],
          ),
        ),
        Expanded(
          child: list.isEmpty
              ? const Center(child: Text('কিছু পাওয়া যায়নি'))
              : ListView.builder(
                  controller: sc,
                  itemExtent: rowH,
                  padding: const EdgeInsets.only(bottom: 90),
                  itemCount: list.length,
                  itemBuilder: (c, i) {
                    final g = list[i];
                    final t = _splitTitle(g.title);
                    return Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                      child: Container(
                        decoration: cardDeco(context, 22),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(22),
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    GrammarDetail(list: list, start: i),
                              ),
                            ),
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 12),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    backgroundColor: cs.primary,
                                    foregroundColor: Colors.white,
                                    child: Text('${g.n}',
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13)),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(t[0],
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold)),
                                        if (t[1].isNotEmpty)
                                          Text(t[1],
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                  fontSize: 13,
                                                  color: softText(context))),
                                      ],
                                    ),
                                  ),
                                  const Icon(Icons.chevron_right),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class GrammarDetail extends StatefulWidget {
  final List<G120> list;
  final int start;
  const GrammarDetail({super.key, required this.list, required this.start});
  @override
  State<GrammarDetail> createState() => _GrammarDetailState();
}

class _GrammarDetailState extends State<GrammarDetail> {
  late final PageController pc = PageController(initialPage: widget.start);
  late int cur = widget.start;

  @override
  void dispose() {
    pc.dispose();
    super.dispose();
  }

  Widget heading(String t) => Padding(
        padding: const EdgeInsets.fromLTRB(2, 18, 2, 8),
        child: Text(t,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      );

  Widget body(G120 g) {
    final t = _splitTitle(g.title);
    final cs = Theme.of(context).colorScheme;
    final border = isDark(context) ? Colors.white24 : Colors.black26;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: headGradient(context),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('ব্যাকরণ ${g.n}',
                  style: const TextStyle(color: Colors.white70, fontSize: 13)),
              const SizedBox(height: 4),
              SelectableText(t[0],
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold)),
              if (t[1].isNotEmpty)
                SelectableText(t[1],
                    style: const TextStyle(color: Colors.white, fontSize: 15)),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cardBg(context),
            borderRadius: BorderRadius.circular(20),
          ),
          child: SelectableText(
              g.desc.isEmpty ? 'ব্যাখ্যা নেই।' : g.desc,
              style: const TextStyle(fontSize: 17, height: 1.6)),
        ),
        if (g.rule.isNotEmpty) ...[
          heading('নিয়ম'),
          Container(
            decoration: BoxDecoration(
              color: cardBg(context),
              borderRadius: BorderRadius.circular(16),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Table(
                border: TableBorder.all(color: border),
                columnWidths: const {
                  0: FlexColumnWidth(1.4),
                  1: FlexColumnWidth(1),
                  2: FlexColumnWidth(1.4),
                },
                children: [
                  for (var r = 0; r < g.rule.length; r++)
                    TableRow(
                      decoration: BoxDecoration(
                          color: r == 0 ? cs.primary.withOpacity(0.18) : null),
                      children: [
                        for (var k = 0; k < 3; k++)
                          Padding(
                            padding: const EdgeInsets.all(10),
                            child: SelectableText(
                              k < g.rule[r].length ? g.rule[r][k] : '',
                              style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: r == 0
                                      ? FontWeight.bold
                                      : FontWeight.normal),
                            ),
                          ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ],
        if (g.ex.isNotEmpty) ...[
          heading('উদাহরণ'),
          for (final e in g.ex)
            Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.fromLTRB(16, 10, 6, 10),
              decoration: cardDeco(context, 18),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SelectableText(e[0],
                            style: const TextStyle(
                                fontSize: 19, fontWeight: FontWeight.bold)),
                        if (e[1].isNotEmpty)
                          SelectableText(e[1],
                              style: TextStyle(
                                  fontSize: 15, color: softText(context))),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.volume_up),
                    onPressed: () => speakKorean(e[0]),
                  ),
                ],
              ),
            ),
        ],
        if (g.rule.isEmpty && g.ex.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Text('PDF-এ এই ব্যাকরণের নিয়ম ও উদাহরণ অসম্পূর্ণ ছিল।',
                style: TextStyle(color: softText(context))),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final total = widget.list.length;
    return Scaffold(
      appBar: AppBar(
        title: Text('${cur + 1} / $total'),
        actions: [
          IconButton(
            icon: const Icon(Icons.tag),
            tooltip: 'নম্বরে যান',
            onPressed: () async {
              final n = await askNumber(context, total);
              if (n != null) pc.jumpToPage(n - 1);
            },
          ),
        ],
      ),
      body: SafeArea(
        child: PageView.builder(
          controller: pc,
          itemCount: total,
          onPageChanged: (i) => setState(() => cur = i),
          itemBuilder: (c, i) => body(widget.list[i]),
        ),
      ),
    );
  }
}

// ---------- ট্যাব ২: নিজের পাঠ ও মূল পাঠ ----------

class _LessonsTab extends StatefulWidget {
  const _LessonsTab();
  @override
  State<_LessonsTab> createState() => _LessonsTabState();
}

class _LessonsTabState extends State<_LessonsTab> {
  List<MyLesson> mine = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    List<MyLesson> r = [];
    try {
      r = await GrammarDb.all();
    } catch (_) {}
    if (!mounted) return;
    setState(() {
      mine = r;
      loading = false;
    });
  }

  void toast(String m) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));
  }

  Widget field(TextEditingController c, String label, int lines,
      {String? hint}) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: TextField(
        controller: c,
        minLines: lines == 1 ? 1 : 3,
        maxLines: lines,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }

  Future<void> edit([MyLesson? l]) async {
    final title = TextEditingController(text: l?.title ?? '');
    final intro = TextEditingController(text: l?.intro ?? '');
    final ex = TextEditingController(text: l?.examples ?? '');
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(l == null ? 'নতুন পাঠ' : 'পাঠ সম্পাদনা'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              field(title, 'পাঠের নাম *', 1),
              field(intro, 'ব্যাখ্যা (বাংলায়)', 6),
              field(
                ex,
                'উদাহরণ (প্রতি লাইনে একটি)',
                8,
                hint: 'কোরিয়ান | উচ্চারণ | অর্থ',
              ),
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
    if (title.text.trim().isEmpty) {
      toast('পাঠের নাম দিতে হবে');
      return;
    }
    if (l == null) {
      await GrammarDb.insert(MyLesson(
          title: title.text.trim(),
          intro: intro.text.trim(),
          examples: ex.text.trim()));
    } else {
      l.title = title.text.trim();
      l.intro = intro.text.trim();
      l.examples = ex.text.trim();
      await GrammarDb.update(l);
    }
    load();
  }

  Future<void> confirmDelete(MyLesson l) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('পাঠটি মুছবেন?'),
        content: Text(l.title),
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
      await GrammarDb.delete(l.id!);
      load();
    }
  }

  void openLesson(String title, String intro, List<List<String>> ex) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => LessonView(title: title, intro: intro, examples: ex),
      ),
    );
  }

  Widget header(String t) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(t,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
    );
  }

  Widget myTile(MyLesson l) {
    return ListTile(
      leading: const Icon(Icons.edit_note),
      title: Text(l.title),
      onTap: () => openLesson(l.title, l.intro, parseExamples(l.examples)),
      trailing: PopupMenuButton<String>(
        onSelected: (v) {
          if (v == 'edit') edit(l);
          if (v == 'del') confirmDelete(l);
        },
        itemBuilder: (c) => const [
          PopupMenuItem(value: 'edit', child: Text('সম্পাদনা')),
          PopupMenuItem(value: 'del', child: Text('মুছুন')),
        ],
      ),
    );
  }

  Widget builtInTile(Lesson l) {
    return ListTile(
      leading: const Icon(Icons.menu_book),
      title: Text(l.title),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => openLesson(l.title, l.intro, l.examples),
    );
  }

  @override
  Widget build(BuildContext context) {
    final children = <Widget>[];
    children.add(Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Text(
        'নিজের পাঠ যোগ করতে নিচের + চাপুন। বই বা ওয়েবসাইট থেকে লেখা কপি করে বসানো যায়।',
        style: TextStyle(color: softText(context)),
      ),
    ));
    if (mine.isNotEmpty) {
      children.add(header('আমার পাঠ'));
      for (final l in mine) {
        children.add(myTile(l));
      }
    }
    children.add(header('মূল পাঠ'));
    for (final l in grammarLessons) {
      children.add(builtInTile(l));
    }
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton(
        heroTag: 'g_lessons_fab',
        onPressed: () => edit(),
        child: const Icon(Icons.add),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.only(bottom: 90),
              children: children,
            ),
    );
  }
}

// ---------- ট্যাব ৩: নিজের গ্রামার PDF ----------

class _PdfTab extends StatefulWidget {
  const _PdfTab();
  @override
  State<_PdfTab> createState() => _PdfTabState();
}

class _PdfTabState extends State<_PdfTab> {
  List<Map<String, Object?>> items = [];
  bool loading = true;
  bool busy = false;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    List<Map<String, Object?>> r = [];
    try {
      r = await GrammarDb.pdfs();
    } catch (_) {}
    if (!mounted) return;
    setState(() {
      items = r;
      loading = false;
    });
  }

  Future<void> add() async {
    if (busy) return;
    setState(() => busy = true);
    try {
      final r = await pickAndCopyPdf();
      if (r != null) await GrammarDb.addPdf(r.name, r.path);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('PDF যোগ করা যায়নি')));
      }
    }
    if (mounted) setState(() => busy = false);
    load();
  }

  Future<void> remove(Map<String, Object?> r) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('তালিকা থেকে সরাবেন?'),
        content: Text('${r['name']}'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('না')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('সরান')),
        ],
      ),
    );
    if (ok != true) return;
    await GrammarDb.deletePdf(r['id'] as int);
    load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'g_pdf_fab',
        onPressed: busy ? null : add,
        icon: const Icon(Icons.upload_file),
        label: Text(busy ? 'অপেক্ষা করুন...' : 'গ্রামার PDF যোগ'),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : items.isEmpty
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Text(
                        'এখনো কোনো গ্রামার PDF নেই।\nনিচের বাটনে চেপে আপনার PDF যোগ করুন। এখানেই পড়া ও লেখা কপি করা যাবে।',
                        textAlign: TextAlign.center),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                  itemCount: items.length,
                  itemBuilder: (c, i) {
                    final r = items[i];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: cardDeco(context, 20),
                      child: ListTile(
                        leading: const Icon(Icons.picture_as_pdf,
                            color: Colors.red, size: 34),
                        title: Text('${r['name']}',
                            maxLines: 2, overflow: TextOverflow.ellipsis),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => PdfReaderPage(
                                title: '${r['name']}',
                                path: r['path'] as String),
                          ),
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () => remove(r),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
