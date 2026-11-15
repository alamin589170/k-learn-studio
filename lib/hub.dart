import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sqflite/sqflite.dart';
import 'package:url_launcher/url_launcher.dart';
import 'links_data.dart';
import 'vocab.dart';

class SiteLink {
  int? id;
  String cat, title, sub, url;
  SiteLink(
      {this.id,
      required this.cat,
      required this.title,
      this.sub = '',
      required this.url});

  factory SiteLink.fromMap(Map<String, Object?> m) => SiteLink(
        id: m['id'] as int,
        cat: (m['cat'] ?? '') as String,
        title: (m['title'] ?? '') as String,
        sub: (m['sub'] ?? '') as String,
        url: (m['url'] ?? '') as String,
      );

  Map<String, Object?> toMap() =>
      {'cat': cat, 'title': title, 'sub': sub, 'url': url};
}

class HubDb {
  static Future<Database> _open() async {
    final db = await Db.get();
    await db.execute(
        'CREATE TABLE IF NOT EXISTS websites(id INTEGER PRIMARY KEY AUTOINCREMENT, cat TEXT, title TEXT, sub TEXT, url TEXT)');
    await db.execute(
        'CREATE TABLE IF NOT EXISTS hub_meta(k TEXT PRIMARY KEY, v TEXT)');
    final seeded =
        await db.query('hub_meta', where: 'k = ?', whereArgs: ['seeded']);
    if (seeded.isEmpty) {
      final batch = db.batch();
      for (final r in defaultLinks) {
        batch.insert(
            'websites', {'cat': r[0], 'title': r[1], 'sub': r[2], 'url': r[3]});
      }
      batch.insert('hub_meta', {'k': 'seeded', 'v': '1'});
      await batch.commit(noResult: true);
    }
    return db;
  }

  static Future<List<SiteLink>> all() async {
    final db = await _open();
    final rows = await db.query('websites', orderBy: 'id ASC');
    return rows.map((m) => SiteLink.fromMap(m)).toList();
  }

  static Future<void> insert(SiteLink s) async {
    final db = await _open();
    await db.insert('websites', s.toMap());
  }

  static Future<void> update(SiteLink s) async {
    final db = await _open();
    await db.update('websites', s.toMap(), where: 'id = ?', whereArgs: [s.id]);
  }

  static Future<void> delete(int id) async {
    final db = await _open();
    await db.delete('websites', where: 'id = ?', whereArgs: [id]);
  }
}

class HubPage extends StatefulWidget {
  const HubPage({super.key});
  @override
  State<HubPage> createState() => _HubPageState();
}

class _HubPageState extends State<HubPage> {
  List<SiteLink> links = [];
  String q = '';
  bool loading = true;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    final r = await HubDb.all();
    if (!mounted) return;
    setState(() {
      links = r;
      loading = false;
    });
  }

  String fixUrl(String u) {
    final t = u.trim();
    if (t.isEmpty) return '';
    if (t.startsWith('http://') || t.startsWith('https://')) return t;
    return 'https://$t';
  }

  void toast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> open(SiteLink s) async {
    var ok = false;
    try {
      ok = await launchUrl(Uri.parse(s.url),
          mode: LaunchMode.externalApplication);
    } catch (_) {}
    if (!ok && mounted) toast('লিংকটি খোলা যায়নি');
  }

  Future<void> copy(SiteLink s) async {
    await Clipboard.setData(ClipboardData(text: s.url));
    if (mounted) toast('ঠিকানা কপি হয়েছে');
  }

  Future<void> confirmDelete(SiteLink s) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('লিংকটি মুছবেন?'),
        content: Text(s.title),
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
      await HubDb.delete(s.id!);
      load();
    }
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

  Future<void> edit([SiteLink? s]) async {
    final cat = TextEditingController(text: s?.cat ?? 'আমার লিংক');
    final title = TextEditingController(text: s?.title ?? '');
    final sub = TextEditingController(text: s?.sub ?? '');
    final url = TextEditingController(text: s?.url ?? '');
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(s == null ? 'নতুন লিংক' : 'লিংক সম্পাদনা'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              field(title, 'নাম *'),
              field(url, 'ঠিকানা (https://...) *'),
              field(cat, 'ক্যাটাগরি'),
              field(sub, 'ছোট বিবরণ'),
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
    final fixed = fixUrl(url.text);
    if (title.text.trim().isEmpty || fixed.isEmpty) {
      toast('নাম ও ঠিকানা দিতে হবে');
      return;
    }
    final category = cat.text.trim().isEmpty ? 'আমার লিংক' : cat.text.trim();
    if (s == null) {
      await HubDb.insert(SiteLink(
          cat: category,
          title: title.text.trim(),
          sub: sub.text.trim(),
          url: fixed));
    } else {
      s.cat = category;
      s.title = title.text.trim();
      s.sub = sub.text.trim();
      s.url = fixed;
      await HubDb.update(s);
    }
    load();
  }

  Widget tile(SiteLink s) {
    return ListTile(
      leading: const Icon(Icons.language),
      title: Text(s.title),
      subtitle: Text(
        s.sub.isEmpty ? s.url : '${s.sub}\n${s.url}',
        maxLines: 3,
        overflow: TextOverflow.ellipsis,
      ),
      isThreeLine: s.sub.isNotEmpty,
      onTap: () => open(s),
      trailing: PopupMenuButton<String>(
        onSelected: (v) {
          if (v == 'copy') copy(s);
          if (v == 'edit') edit(s);
          if (v == 'del') confirmDelete(s);
        },
        itemBuilder: (c) => const [
          PopupMenuItem(value: 'copy', child: Text('ঠিকানা কপি')),
          PopupMenuItem(value: 'edit', child: Text('সম্পাদনা')),
          PopupMenuItem(value: 'del', child: Text('মুছুন')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = q.trim().toLowerCase();
    final shown = links.where((s) {
      if (t.isEmpty) return true;
      return s.title.toLowerCase().contains(t) ||
          s.sub.toLowerCase().contains(t) ||
          s.url.toLowerCase().contains(t) ||
          s.cat.toLowerCase().contains(t);
    }).toList();
    final cats = <String>[];
    for (final s in shown) {
      if (!cats.contains(s.cat)) cats.add(s.cat);
    }

    final children = <Widget>[];
    for (final c in cats) {
      final items = shown.where((s) => s.cat == c).toList();
      children.add(ExpansionTile(
        key: PageStorageKey('$c-$t'),
        initiallyExpanded: true,
        title: Text(c, style: const TextStyle(fontWeight: FontWeight.bold)),
        children: items.map((s) => tile(s)).toList(),
      ));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('ওয়েবসাইট হাব')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => edit(),
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'লিংক খুঁজুন',
                border: OutlineInputBorder(),
              ),
              onChanged: (v) => setState(() => q = v),
            ),
          ),
          Expanded(
            child: loading
                ? const Center(child: CircularProgressIndicator())
                : children.isEmpty
                    ? const Center(child: Text('কোনো লিংক পাওয়া যায়নি।'))
                    : ListView(
                        padding: const EdgeInsets.only(bottom: 80),
                        children: children,
                      ),
          ),
        ],
      ),
    );
  }
}
