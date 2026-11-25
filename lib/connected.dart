import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:url_launcher/url_launcher.dart';
import 'catalog.dart';
import 'style.dart';

// [নাম, ছোট বিবরণ, Play Store প্যাকেজ, ওয়েব ঠিকানা]
const List<List<String>> _starterApps = [
  ['Papago', 'Naver-এর অনুবাদ', 'com.naver.labs.translator', 'https://papago.naver.com'],
  ['Naver Dictionary', 'কোরিয়ান শব্দের অর্থ', 'com.nhn.android.naverdic', 'https://dict.naver.com'],
  ['Google Translate', 'বাংলা-কোরিয়ান অনুবাদ', 'com.google.android.apps.translate', 'https://translate.google.com'],
  ['Duolingo', 'গেমের মতো ভাষা শেখা', 'com.duolingo', ''],
  ['LingoDeer', 'কোরিয়ান কোর্স', 'com.lingodeer', ''],
  ['Memrise', 'শব্দ মুখস্থ করা', 'com.memrise.android.memrisecompanion', ''],
  ['HelloTalk', 'ভাষা বিনিময় চ্যাট', 'com.hellotalk', ''],
  ['EPS Books', 'EPS-TOPIK বই', 'com.coderebornx.epsbooks', ''],
  ['YouTube', 'কোরিয়ান শেখার ভিডিও', 'com.google.android.youtube', 'https://www.youtube.com/results?search_query=learn+korean'],
  ['TOPIK অফিসিয়াল', 'পরীক্ষার তথ্য', '', 'https://www.topik.go.kr'],
];

class AppItem {
  int? id;
  bool mine;
  String name, sub, pkg, url, icon;
  AppItem(
      {this.id,
      this.mine = false,
      required this.name,
      this.sub = '',
      this.pkg = '',
      this.url = '',
      this.icon = ''});
}

class ConnectedPage extends StatefulWidget {
  const ConnectedPage({super.key});
  @override
  State<ConnectedPage> createState() => _ConnectedPageState();
}

class _ConnectedPageState extends State<ConnectedPage> {
  List<AppItem> apps = [];
  bool loading = true;

  static const List<Color> _cols = [
    Color(0xFFB4532A),
    Color(0xFF2A7F6B),
    Color(0xFF2F6DB5),
    Color(0xFF6A55C8),
    Color(0xFFD0457F),
    Color(0xFF8A6D1F),
  ];

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

  Future<Database> _db() async {
    final db = await openBookDb();
    await db.execute(
        'CREATE TABLE IF NOT EXISTS my_apps(id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT, sub TEXT, pkg TEXT, url TEXT)');
    return db;
  }

  Future<void> load() async {
    final out = <AppItem>[];
    try {
      final db = await _db();
      final shared = await db.query('cat_apps', orderBy: 'id ASC');
      final mine = await db.query('my_apps', orderBy: 'id ASC');
      final seen = <String>{};
      for (final m in shared) {
        final it = AppItem(
          name: '${m['name']}',
          sub: '${m['sub'] ?? ''}',
          pkg: '${m['pkg'] ?? ''}',
          url: '${m['url'] ?? ''}',
          icon: '${m['icon'] ?? ''}',
        );
        seen.add(it.name.toLowerCase());
        out.add(it);
      }
      for (final r in _starterApps) {
        if (seen.contains(r[0].toLowerCase())) continue;
        out.add(AppItem(name: r[0], sub: r[1], pkg: r[2], url: r[3]));
      }
      for (final m in mine) {
        out.add(AppItem(
          id: m['id'] as int,
          mine: true,
          name: '${m['name']}',
          sub: '${m['sub'] ?? ''}',
          pkg: '${m['pkg'] ?? ''}',
          url: '${m['url'] ?? ''}',
        ));
      }
    } catch (_) {
      for (final r in _starterApps) {
        out.add(AppItem(name: r[0], sub: r[1], pkg: r[2], url: r[3]));
      }
    }
    if (!mounted) return;
    setState(() {
      apps = out;
      loading = false;
    });
  }

  void toast(String m) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));
  }

  Future<void> go(String url) async {
    var ok = false;
    try {
      ok = await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } catch (_) {}
    if (!ok && mounted) toast('খোলা যায়নি');
  }

  String playUrl(String pkg) =>
      'https://play.google.com/store/apps/details?id=$pkg';

  void openApp(AppItem a) {
    if (a.pkg.isEmpty && a.url.isNotEmpty) {
      go(a.url);
      return;
    }
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (c) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(a.name,
                  style: const TextStyle(
                      fontSize: 22, fontWeight: FontWeight.bold)),
              if (a.sub.isNotEmpty)
                Text(a.sub, style: TextStyle(color: softText(context))),
              const SizedBox(height: 14),
              FilledButton.icon(
                icon: const Icon(Icons.shop),
                label: const Text('Play Store-এ খুলুন (ইনস্টল থাকলে Open চাপুন)'),
                onPressed: () {
                  Navigator.pop(c);
                  go(playUrl(a.pkg));
                },
              ),
              if (a.url.isNotEmpty) ...[
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  icon: const Icon(Icons.language),
                  label: const Text('ওয়েবসাইটে খুলুন (ইনস্টল ছাড়া)'),
                  onPressed: () {
                    Navigator.pop(c);
                    go(a.url);
                  },
                ),
              ],
              if (a.mine) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    TextButton.icon(
                      icon: const Icon(Icons.edit),
                      label: const Text('সম্পাদনা'),
                      onPressed: () {
                        Navigator.pop(c);
                        edit(a);
                      },
                    ),
                    TextButton.icon(
                      icon: const Icon(Icons.delete_outline),
                      label: const Text('মুছুন'),
                      onPressed: () {
                        Navigator.pop(c);
                        remove(a);
                      },
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> remove(AppItem a) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('তালিকা থেকে সরাবেন?'),
        content: Text(a.name),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(c, false),
              child: const Text('না')),
          FilledButton(
              onPressed: () => Navigator.pop(c, true),
              child: const Text('সরান')),
        ],
      ),
    );
    if (ok != true) return;
    final db = await _db();
    await db.delete('my_apps', where: 'id = ?', whereArgs: [a.id]);
    load();
  }

  Future<void> edit([AppItem? a]) async {
    final name = TextEditingController(text: a?.name ?? '');
    final sub = TextEditingController(text: a?.sub ?? '');
    final link = TextEditingController(
        text: a == null ? '' : (a.pkg.isEmpty ? '' : playUrl(a.pkg)));
    final web = TextEditingController(text: a?.url ?? '');
    Widget f(TextEditingController c, String label, {String? hint}) => Padding(
          padding: const EdgeInsets.only(top: 8),
          child: TextField(
            controller: c,
            decoration: InputDecoration(
                labelText: label,
                hintText: hint,
                border: const OutlineInputBorder()),
          ),
        );
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(a == null ? 'নতুন অ্যাপ' : 'অ্যাপ সম্পাদনা'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              f(name, 'অ্যাপের নাম *'),
              f(link, 'Play Store লিংক বা প্যাকেজ',
                  hint: 'https://play.google.com/store/apps/details?id=...'),
              f(web, 'ওয়েব ঠিকানা (থাকলে)'),
              f(sub, 'ছোট বিবরণ'),
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
    final n = name.text.trim();
    var pkg = link.text.trim();
    final m = RegExp(r'[?&]id=([A-Za-z0-9._]+)').firstMatch(pkg);
    if (m != null) pkg = m.group(1)!;
    var w = web.text.trim();
    if (w.isNotEmpty && !w.startsWith('http')) w = 'https://$w';
    if (n.isEmpty || (pkg.isEmpty && w.isEmpty)) {
      toast('নাম এবং Play Store লিংক বা ওয়েব ঠিকানা দিতে হবে');
      return;
    }
    final db = await _db();
    final vals = {'name': n, 'sub': sub.text.trim(), 'pkg': pkg, 'url': w};
    if (a == null) {
      await db.insert('my_apps', vals);
    } else {
      await db.update('my_apps', vals, where: 'id = ?', whereArgs: [a.id]);
    }
    load();
  }

  Widget icon(AppItem a, int i) {
    final col = _cols[i % _cols.length];
    final letter = a.name.isEmpty ? '?' : a.name.characters.first.toUpperCase();
    final fallback = Container(
      width: 60,
      height: 60,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [col, col.withOpacity(0.7)],
        ),
      ),
      child: Text(letter,
          style: const TextStyle(
              color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
    );
    if (a.icon.isEmpty) return fallback;
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: Image.network(a.icon,
          width: 60,
          height: 60,
          fit: BoxFit.cover,
          errorBuilder: (c, e, s) => fallback),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('কানেক্টেড অ্যাপস')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => edit(),
        child: const Icon(Icons.add),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.only(bottom: 90),
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                  child: Text(
                      'কোরিয়ান শেখার সহায়ক অ্যাপ। চাপলে Play Store-এর পাতা খুলবে, ইনস্টল করা থাকলে সেখানে Open চাপুন। যেগুলোর ওয়েবসাইট আছে সেগুলো ইনস্টল ছাড়াই খোলা যায়।',
                      style: TextStyle(fontSize: 13, color: softText(context))),
                ),
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  crossAxisCount: 3,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 8,
                  childAspectRatio: 0.85,
                  children: [
                    for (var i = 0; i < apps.length; i++)
                      GestureDetector(
                        onTap: () => openApp(apps[i]),
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: cardDeco(context, 24),
                              child: icon(apps[i], i),
                            ),
                            const SizedBox(height: 6),
                            Text(apps[i].name,
                                maxLines: 2,
                                textAlign: TextAlign.center,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    fontSize: 13, fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                  ],
                ),
              ],
            ),
    );
  }
}
