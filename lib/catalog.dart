import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'vocab.dart';

// Google Drive লিংক বা আইডি থেকে ফাইল আইডি
String? driveId(String s) {
  final t = s.trim();
  if (t.isEmpty) return null;
  final a = RegExp(r'/d/([A-Za-z0-9_-]{10,})').firstMatch(t);
  if (a != null) return a.group(1);
  final b = RegExp(r'[?&]id=([A-Za-z0-9_-]{10,})').firstMatch(t);
  if (b != null) return b.group(1);
  if (RegExp(r'^[A-Za-z0-9_-]{20,}$').hasMatch(t)) return t;
  return null;
}

String driveThumb(String id) =>
    'https://drive.google.com/thumbnail?id=$id&sz=w500';

bool _tablesOk = false;

// বই, অ্যাপ ও লিংকের টেবিল তৈরি
Future<Database> openBookDb() async {
  final db = await Db.get();
  if (!_tablesOk) {
    await db.execute(
        'CREATE TABLE IF NOT EXISTS pdf_books(id INTEGER PRIMARY KEY AUTOINCREMENT, title TEXT NOT NULL, path TEXT, url TEXT, chapters INTEGER NOT NULL DEFAULT 60, ts INTEGER NOT NULL, cid TEXT, thumb TEXT)');
    for (final col in ['cid TEXT', 'thumb TEXT']) {
      try {
        await db.execute('ALTER TABLE pdf_books ADD COLUMN $col');
      } catch (_) {}
    }
    await db.execute(
        'CREATE TABLE IF NOT EXISTS book_chapters(book_id INTEGER NOT NULL, no INTEGER NOT NULL, title TEXT NOT NULL, page INTEGER NOT NULL DEFAULT 0, done INTEGER NOT NULL DEFAULT 0, PRIMARY KEY(book_id, no))');
    await db.execute(
        'CREATE TABLE IF NOT EXISTS cat_apps(id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT, sub TEXT, pkg TEXT, url TEXT, icon TEXT)');
    await db.execute(
        'CREATE TABLE IF NOT EXISTS cat_links(id INTEGER PRIMARY KEY AUTOINCREMENT, cat TEXT, title TEXT, sub TEXT, url TEXT)');
    await db.execute(
        'CREATE TABLE IF NOT EXISTS hub_meta(k TEXT PRIMARY KEY, v TEXT)');
    _tablesOk = true;
  }
  return db;
}

class Catalog {
  static const String url =
      'https://raw.githubusercontent.com/alamin589170/k-learn-studio/main/data/catalog.json';
  static final ValueNotifier<int> changed = ValueNotifier(0);
  static bool _ran = false;

  static Future<Map<String, dynamic>?> _fetch() async {
    try {
      final r = await http
          .get(Uri.parse('$url?t=${DateTime.now().millisecondsSinceEpoch}'))
          .timeout(const Duration(seconds: 12));
      if (r.statusCode != 200) return null;
      final d = jsonDecode(utf8.decode(r.bodyBytes));
      return d is Map<String, dynamic> ? d : null;
    } catch (_) {
      return null;
    }
  }

  static Future<void> autoOnce() async {
    if (_ran) return;
    _ran = true;
    await sync();
  }

  // সফল হলে true
  static Future<bool> sync() async {
    final d = await _fetch();
    if (d == null) return false;
    try {
      await _apply(d);
    } catch (_) {
      return false;
    }
    changed.value++;
    return true;
  }

  static Future<void> _apply(Map<String, dynamic> d) async {
    final db = await openBookDb();
    final now = DateTime.now().millisecondsSinceEpoch;

    final books = d['books'];
    if (books is List) {
      final keep = <String>{};
      for (final e in books) {
        if (e is! Map) continue;
        final id = driveId('${e['drive'] ?? e['id'] ?? ''}');
        final title = '${e['title'] ?? ''}'.trim();
        if (id == null || title.isEmpty) continue;
        keep.add(id);
        final cl = e['chapter_list'];
        var count = int.tryParse('${e['chapters']}') ?? 0;
        if (cl is List && cl.length > count) count = cl.length;
        if (count < 1) count = 1;
        final th = '${e['thumb'] ?? ''}'.trim();
        final thumb = th.isEmpty ? driveThumb(id) : th;
        final ex = await db.query('pdf_books',
            columns: ['id'], where: 'cid = ?', whereArgs: [id]);
        int bid;
        if (ex.isEmpty) {
          bid = await db.insert('pdf_books', {
            'title': title,
            'chapters': count,
            'ts': now,
            'cid': id,
            'thumb': thumb,
          });
        } else {
          bid = ex.first['id'] as int;
          await db.update(
              'pdf_books', {'title': title, 'chapters': count, 'thumb': thumb},
              where: 'id = ?', whereArgs: [bid]);
        }
        if (cl is List) {
          final batch = db.batch();
          for (var i = 0; i < cl.length; i++) {
            final row = cl[i];
            var t = '';
            var pg = 0;
            if (row is List && row.isNotEmpty) {
              t = '${row[0]}';
              pg = row.length > 1 ? (int.tryParse('${row[1]}') ?? 0) : 0;
            } else {
              t = '$row';
            }
            batch.insert(
                'book_chapters',
                {
                  'book_id': bid,
                  'no': i + 1,
                  'title': 'অধ্যায় ${i + 1}',
                  'page': 0,
                  'done': 0
                },
                conflictAlgorithm: ConflictAlgorithm.ignore);
            batch.update('book_chapters', {'title': t, 'page': pg},
                where: 'book_id = ? AND no = ?', whereArgs: [bid, i + 1]);
          }
          await batch.commit(noResult: true);
        }
      }
      final old = await db.query('pdf_books', where: 'cid IS NOT NULL');
      for (final r in old) {
        if (keep.contains(r['cid'])) continue;
        final path = r['path'] as String?;
        if (path != null && path.isNotEmpty) {
          try {
            final f = File(path);
            if (await f.exists()) await f.delete();
          } catch (_) {}
        }
        await db.delete('book_chapters',
            where: 'book_id = ?', whereArgs: [r['id']]);
        await db.delete('pdf_books', where: 'id = ?', whereArgs: [r['id']]);
      }
    }

    final apps = d['apps'];
    if (apps is List) {
      await db.delete('cat_apps');
      for (final e in apps) {
        if (e is! Map) continue;
        final name = '${e['name'] ?? ''}'.trim();
        if (name.isEmpty) continue;
        await db.insert('cat_apps', {
          'name': name,
          'sub': '${e['sub'] ?? ''}',
          'pkg': '${e['package'] ?? ''}',
          'url': '${e['url'] ?? ''}',
          'icon': '${e['icon'] ?? ''}',
        });
      }
    }

    final links = d['links'];
    if (links is List) {
      await db.delete('cat_links');
      for (final e in links) {
        if (e is! Map) continue;
        final title = '${e['title'] ?? ''}'.trim();
        final u = '${e['url'] ?? ''}'.trim();
        if (title.isEmpty || u.isEmpty) continue;
        await db.insert('cat_links', {
          'cat': '${e['cat'] ?? 'শেয়ার করা লিংক'}',
          'title': title,
          'sub': '${e['sub'] ?? ''}',
          'url': u,
        });
      }
    }

    // নতুন শব্দ ও সংশোধন (rev বাড়ালে একবার প্রয়োগ হয়)
    final rev = int.tryParse('${d['rev']}') ?? 0;
    final cur =
        await db.query('hub_meta', where: 'k = ?', whereArgs: ['catrev']);
    final have = cur.isEmpty ? 0 : (int.tryParse('${cur.first['v']}') ?? 0);
    if (rev > have) {
      final nw = d['words'];
      if (nw is List) {
        final haveKo = <String>{
          for (final m in await db.query('words', columns: ['ko']))
            (m['ko'] ?? '') as String
        };
        for (final r in nw) {
          if (r is! List || r.length < 3) continue;
          final ko = '${r[0]}'.trim();
          if (ko.isEmpty || haveKo.contains(ko)) continue;
          haveKo.add(ko);
          await db.insert('words', {
            'ko': ko,
            'pron': '${r[1]}',
            'bn': '${r[2]}',
            'en': r.length > 3 ? '${r[3]}' : '',
            'ex': r.length > 4 ? '${r[4]}' : '',
            'saved': 0,
          });
        }
      }
      final fx = d['corrections'];
      if (fx is List) {
        for (final r in fx) {
          if (r is! List || r.length < 3) continue;
          final vals = <String, Object?>{'pron': '${r[1]}', 'bn': '${r[2]}'};
          if (r.length > 3 && '${r[3]}'.isNotEmpty) vals['en'] = '${r[3]}';
          if (r.length > 4 && '${r[4]}'.isNotEmpty) vals['ex'] = '${r[4]}';
          await db.update('words', vals,
              where: 'ko = ?', whereArgs: ['${r[0]}'.trim()]);
        }
      }
      await db.insert('hub_meta', {'k': 'catrev', 'v': '$rev'},
          conflictAlgorithm: ConflictAlgorithm.replace);
    }
  }
}

Future<bool> _isPdf(File f) async {
  try {
    final raf = await f.open();
    final b = await raf.read(5);
    await raf.close();
    return String.fromCharCodes(b) == '%PDF-';
  } catch (_) {
    return false;
  }
}

// Google Drive থেকে PDF নামিয়ে ফোনে রাখে; সফল হলে ফাইলের পথ
Future<String?> downloadDrivePdf(
    BuildContext context, String cid, String title) async {
  final dir = await getApplicationDocumentsDirectory();
  final folder = Directory(p.join(dir.path, 'pdfs'));
  await folder.create(recursive: true);
  final dest = p.join(folder.path, 'cloud_$cid.pdf');
  final progress = ValueNotifier<double?>(null);
  var cancelled = false;
  showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => AlertDialog(
      title: const Text('ডাউনলোড হচ্ছে...'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, maxLines: 2, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 14),
          ValueListenableBuilder<double?>(
            valueListenable: progress,
            builder: (c, v, _) => LinearProgressIndicator(value: v),
          ),
        ],
      ),
      actions: [
        TextButton(
            onPressed: () => cancelled = true, child: const Text('বাতিল')),
      ],
    ),
  );
  String? result;
  final client = http.Client();
  try {
    final req = http.Request(
        'GET',
        Uri.parse(
            'https://drive.usercontent.google.com/download?id=$cid&export=download&confirm=t'));
    final res = await client.send(req).timeout(const Duration(seconds: 30));
    if (res.statusCode == 200) {
      final total = res.contentLength ?? 0;
      var got = 0;
      final tmp = File('$dest.part');
      final sink = tmp.openWrite();
      await for (final chunk in res.stream) {
        if (cancelled) break;
        sink.add(chunk);
        got += chunk.length;
        if (total > 0) progress.value = got / total;
      }
      await sink.close();
      if (!cancelled && await _isPdf(tmp)) {
        await tmp.rename(dest);
        result = dest;
      } else {
        try {
          await tmp.delete();
        } catch (_) {}
      }
    }
  } catch (_) {
  } finally {
    client.close();
  }
  if (context.mounted) Navigator.of(context, rootNavigator: true).pop();
  return result;
}
