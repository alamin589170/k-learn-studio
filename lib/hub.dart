import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sqflite/sqflite.dart';
import 'package:url_launcher/url_launcher.dart';
import 'catalog.dart';
import 'links_data.dart';
import 'style.dart';
import 'ui.dart';
import 'vocab.dart';

class SiteLink {
  int? id;
  bool shared;
  String cat, title, sub, url;
  SiteLink(
      {this.id,
      this.shared = false,
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
    await openBookDb();
    final rows = await db.query('websites', orderBy: 'id ASC');
    final shared = await db.query('cat_links', orderBy: 'id ASC');
    return [
      ...shared.map((m) => SiteLink(
            shared: true,
            cat: (m['cat'] ?? '') as String,
            title: (m['title'] ?? '') as String,
            sub: (m['sub'] ?? '') as String,
            url: (m['url'] ?? '') as String,
          )),
      ...rows.map((m) => SiteLink.fromMap(m)),
    ];
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
    Catalog.changed.addListener(load);
    load();
  }

  @override
  void dispose() {
    Catalog.changed.removeListener(load);
    super.dispose();
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

  void options(SiteLink s) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (c) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(s.title,
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold)),
                  if (s.sub.isNotEmpty) Text(s.sub),
                  Text(s.url,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 12, color: softText(context))),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.open_in_new),
              title: const Text('খুলুন'),
              onTap: () {
                Navigator.pop(c);
                open(s);
              },
            ),
            ListTile(
              leading: const Icon(Icons.copy),
              title: const Text('ঠিকানা কপি'),
              onTap: () {
                Navigator.pop(c);
                copy(s);
              },
            ),
            if (!s.shared) ...[
              ListTile(
                leading: const Icon(Icons.edit),
                title: const Text('সম্পাদনা'),
                onTap: () {
                  Navigator.pop(c);
                  edit(s);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete_outline),
                title: const Text('মুছুন'),
                onTap: () {
                  Navigator.pop(c);
                  confirmDelete(s);
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget icon(SiteLink s, double size) {
    final host = Uri.tryParse(s.url)?.host ?? '';
    final gen = GenLogo(name: s.title, hint: s.url, size: size);
    if (host.isEmpty) return gen;
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        children: [
          gen,
          Positioned.fill(
            child: Image.network(
              'https://t3.gstatic.com/faviconV2?client=SOCIAL&type=FAVICON&url=https://$host&size=128',
              fit: BoxFit.contain,
              errorBuilder: (c, e, st) => const SizedBox.shrink(),
              frameBuilder: (c, child, frame, sync) {
                if (frame == null) return const SizedBox.shrink();
                return Container(
                  padding: EdgeInsets.all(size * 0.14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(size * 0.28),
                    border: Border.all(color: Colors.white70),
                  ),
                  child: child,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget tile(SiteLink s) {
    final pr = Theme.of(context).colorScheme.primary;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => open(s),
      onLongPress: () => options(s),
      child: Column(
        children: [
          Glass(
            radius: 26,
            blur: 12,
            padding: const EdgeInsets.all(10),
            child: icon(s, 64),
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              color: pr.withOpacity(0.18),
              border: Border.all(color: pr.withOpacity(0.45)),
            ),
            child: Text(s.title,
                maxLines: 2,
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    fontSize: 12.5, fontWeight: FontWeight.w700, height: 1.15)),
          ),
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
      children.add(Padding(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 10),
        child: Text(c,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
      ));
      children.add(GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          mainAxisSpacing: 14,
          crossAxisSpacing: 12,
          mainAxisExtent: 150,
        ),
        itemCount: items.length,
        itemBuilder: (c, i) => tile(items[i]),
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
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: TextField(
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: 'লিংক খুঁজুন',
                filled: true,
                fillColor: cardBg(context),
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(28),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (v) => setState(() => q = v),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 2, 20, 0),
            child: Text('চাপলে খুলবে, চেপে ধরলে কপি, সম্পাদনা বা মোছার অপশন আসবে।',
                style: TextStyle(fontSize: 12, color: softText(context))),
          ),
          Expanded(
            child: loading
                ? const Center(child: CircularProgressIndicator())
                : children.isEmpty
                    ? const Center(child: Text('কোনো লিংক পাওয়া যায়নি।'))
                    : ListView(
                        padding: const EdgeInsets.only(bottom: 90),
                        children: children,
                      ),
          ),
        ],
      ),
    );
  }
}
