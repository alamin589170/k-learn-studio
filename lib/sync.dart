import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'vocab.dart';

// প্রতিটি নতুন APK রিলিজে এই সংখ্যা ১ বাড়াবেন
const int kAppVersion = 1;
const String _base =
    'https://raw.githubusercontent.com/alamin589170/k-learn-studio/main/data/';

class SyncService {
  static bool _ran = false;

  static Future<String?> _get(String name) async {
    final c = HttpClient();
    c.connectionTimeout = const Duration(seconds: 8);
    try {
      final req = await c.getUrl(Uri.parse('$_base$name'));
      final res = await req.close().timeout(const Duration(seconds: 15));
      if (res.statusCode != 200) {
        await res.drain<void>();
        return null;
      }
      return await res.transform(utf8.decoder).join();
    } catch (_) {
      return null;
    } finally {
      c.close(force: true);
    }
  }

  static Future<void> autoOnce() async {
    if (_ran) return;
    _ran = true;
    try {
      await syncWords();
    } catch (_) {}
  }

  // নতুন শব্দের সংখ্যা; ব্যর্থ হলে -1। আপনার নিজের যোগ করা শব্দ মোছে না।
  static Future<int> syncWords() async {
    final txt = await _get('words.json');
    if (txt == null) return -1;
    final data = jsonDecode(txt);
    if (data is! List) return -1;
    final db = await Db.get();
    final have = await db.query('words', columns: ['ko']);
    final set = <String>{for (final m in have) (m['ko'] ?? '') as String};
    final batch = db.batch();
    var n = 0;
    for (final r in data) {
      if (r is! List || r.length < 3) continue;
      final ko = '${r[0]}'.trim();
      if (ko.isEmpty || set.contains(ko)) continue;
      set.add(ko);
      n++;
      batch.insert('words', {
        'ko': ko,
        'pron': '${r[1]}',
        'bn': '${r[2]}',
        'en': r.length > 3 ? '${r[3]}' : '',
        'ex': r.length > 4 ? '${r[4]}' : '',
        'saved': 0,
      });
    }
    if (n > 0) await batch.commit(noResult: true);
    return n;
  }

  // নতুন সংস্করণ থাকলে সংখ্যা, নইলে 0; ব্যর্থ হলে -1
  static Future<int> checkUpdate() async {
    final txt = await _get('version.json');
    if (txt == null) return -1;
    final m = jsonDecode(txt);
    if (m is! Map) return -1;
    final v = int.tryParse('${m['version']}') ?? 0;
    return v > kAppVersion ? v : 0;
  }
}

class SyncCard extends StatefulWidget {
  const SyncCard({super.key});
  @override
  State<SyncCard> createState() => _SyncCardState();
}

class _SyncCardState extends State<SyncCard> {
  bool _busy = false;
  String _msg = 'শব্দ ও আপডেট দেখতে বোতাম চাপুন';

  Future<void> _run() async {
    setState(() => _busy = true);
    String m;
    try {
      final n = await SyncService.syncWords();
      final u = await SyncService.checkUpdate();
      if (n < 0 && u < 0) {
        m = 'ইন্টারনেট বা ফাইল পাওয়া যায়নি';
      } else {
        m = n < 0 ? 'শব্দ ফাইল পাওয়া যায়নি' : 'নতুন শব্দ যোগ হয়েছে: $n';
        if (u > 0) m += '\nনতুন APK আছে (সংস্করণ $u)। GitHub → Actions থেকে নামান।';
      }
    } catch (_) {
      m = 'সিঙ্ক ব্যর্থ হয়েছে';
    }
    if (!mounted) return;
    setState(() {
      _busy = false;
      _msg = m;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.sync, color: Colors.green, size: 32),
        title: const Text('শব্দ-সিঙ্ক ও আপডেট'),
        subtitle: Text(_msg),
        trailing: _busy
            ? const SizedBox(
                width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
            : IconButton(icon: const Icon(Icons.download), onPressed: _run),
      ),
    );
  }
}
