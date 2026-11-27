import 'dart:convert';
import 'dart:io';
import 'package:flutter/painting.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'vocab.dart';

// শব্দের ছবি: প্রথমে বাংলা অর্থ (bn.wikipedia), তারপর ইংরেজি অর্থ
// (Pixabay 2D/ভেক্টর, না পেলে en.wikipedia)। পেলে ফোনে জমা থাকে।
class WordImg {
  static Directory? _dir;
  static Future<void> _last = Future<void>.value();
  static const Map<String, String> _ua = {
    'User-Agent': 'KLearnStudio/1.0 (Flutter learning app)'
  };

  static Future<Directory> dir() async {
    final d = _dir;
    if (d != null) return d;
    final base = await getApplicationDocumentsDirectory();
    final t = Directory('${base.path}/thumbs');
    if (!await t.exists()) await t.create(recursive: true);
    _dir = t;
    return t;
  }

  static Future<File> fileOf(int id) async =>
      File('${(await dir()).path}/${id}_hq.jpg');

  static Future<File?> cached(int id) async {
    final f = await fileOf(id);
    return await f.exists() ? f : null;
  }

  static String banglaTerm(String s) {
    final t = s.replaceAll(RegExp(r'\([^)]*\)|（[^）]*）'), ' ');
    return t.split(RegExp(r'[,;/।\n]')).first.trim();
  }

  static String englishTerm(String s) {
    var t = s.replaceAll(RegExp(r'\([^)]*\)'), ' ');
    t = t.split(RegExp(r'[,;/\n]')).first.trim().toLowerCase();
    for (final p in const ['to ', 'a ', 'an ', 'the ']) {
      if (t.startsWith(p)) t = t.substring(p.length);
    }
    return t.trim();
  }

  // ছবি আছে কি না দেখে, না থাকলে লাইনে দাঁড়িয়ে খোঁজে (একটার পর একটা)
  static Future<File?> fetch(Word w, {bool Function()? alive}) async {
    final id = w.id;
    if (id == null) return null;
    final d = await dir();
    final f = File('${d.path}/${id}_hq.jpg');
    if (await f.exists()) return f;
    if (await File('${d.path}/${id}_hq.none').exists()) return null;
    final job = _last.then<File?>((_) async {
      if (alive != null && !alive()) return null;
      try {
        return await _net(w, d, id, f);
      } catch (_) {
        return null;
      }
    });
    _last = job.then<void>((_) => Future<void>.delayed(
        const Duration(milliseconds: 250)));
    return job;
  }

  static Future<File?> _net(Word w, Directory d, int id, File out) async {
    final fail = <bool>[false];
    File? got;
    final bn = banglaTerm(w.bn);
    final en = englishTerm(w.en);
    got = await _wiki('bn', bn, out, fail);
    got ??= await _pixabay(en, out, fail);
    if (got == null && en.isNotEmpty) {
      final cap = en[0].toUpperCase() + en.substring(1);
      got = await _wiki('en', cap, out, fail);
    }
    if (got == null && !fail[0]) {
      await File('${d.path}/${id}_hq.none').writeAsString('1');
    }
    return got;
  }

  static Future<File?> _download(String url, File out, List<bool> fail) async {
    try {
      final r = await http
          .get(Uri.parse(url), headers: _ua)
          .timeout(const Duration(seconds: 15));
      if (r.statusCode != 200 || r.bodyBytes.length < 2000) {
        if (r.statusCode != 200) fail[0] = true;
        return null;
      }
      await out.writeAsBytes(r.bodyBytes);
      return out;
    } catch (_) {
      fail[0] = true;
      return null;
    }
  }

  static Future<File?> _wiki(
      String lang, String title, File out, List<bool> fail) async {
    if (title.isEmpty) return null;
    try {
      final u = Uri.https('$lang.wikipedia.org', '/w/api.php', {
        'action': 'query',
        'format': 'json',
        'redirects': '1',
        'prop': 'pageimages|pageprops',
        'piprop': 'thumbnail',
        'pithumbsize': '640',
        'pilicense': 'any',
        'ppprop': 'disambiguation',
        'titles': title,
      });
      final r = await http.get(u, headers: _ua).timeout(const Duration(seconds: 12));
      if (r.statusCode != 200) {
        fail[0] = true;
        return null;
      }
      final q = (jsonDecode(r.body) as Map)['query'];
      final pages = q is Map ? q['pages'] : null;
      if (pages is! Map) return null;
      for (final p in pages.values) {
        if (p is! Map || p.containsKey('missing')) continue;
        final props = p['pageprops'];
        if (props is Map && props.containsKey('disambiguation')) continue;
        final th = p['thumbnail'];
        if (th is! Map) continue;
        final wd = th['width'];
        if (wd is int && wd < 250) continue;
        return await _download('${th['source']}', out, fail);
      }
    } catch (_) {
      fail[0] = true;
    }
    return null;
  }

  static Future<File?> _pixabay(String q, File out, List<bool> fail) async {
    const key = String.fromEnvironment('PIXABAY_KEY');
    if (key.isEmpty || q.isEmpty) return null;
    final last = q.split(' ').last;
    for (final type in const ['vector', 'illustration']) {
      try {
        final r = await http
            .get(Uri.parse(
                'https://pixabay.com/api/?key=$key&q=${Uri.encodeQueryComponent(q)}&image_type=$type&per_page=20&safe_search=true&order=popular&min_width=500'))
            .timeout(const Duration(seconds: 12));
        if (r.statusCode != 200) {
          fail[0] = true;
          continue;
        }
        final hits = (jsonDecode(r.body) as Map)['hits'] as List;
        for (final h in hits) {
          final tags = ('${(h as Map)['tags']}')
              .toLowerCase()
              .split(',')
              .map((e) => e.trim())
              .toList();
          if (tags.contains(q) || tags.contains(last)) {
            final f = await _download('${h['webformatURL']}', out, fail);
            if (f != null) return f;
          }
        }
      } catch (_) {
        fail[0] = true;
      }
    }
    return null;
  }

  // নিজের বাছা ছবি (গ্যালারি/ক্যামেরা): স্বয়ংক্রিয় খোঁজ আর এটা বদলাবে না
  static Future<void> setFromFile(int id, String path) async {
    final d = await dir();
    final f = File('${d.path}/${id}_hq.jpg');
    if (path != f.path) await File(path).copy(f.path);
    await _rm('${d.path}/${id}_hq.none');
    await File('${d.path}/${id}_hq.manual').writeAsString('1');
    imageCache.clear();
  }

  // ছবি সরানো (আর স্বয়ংক্রিয়ভাবে খুঁজবে না)
  static Future<void> clear(int id) async {
    final d = await dir();
    await _rm('${d.path}/${id}_hq.jpg');
    await _rm('${d.path}/${id}_hq.manual');
    await File('${d.path}/${id}_hq.none').writeAsString('1');
    imageCache.clear();
  }

  // আবার স্বয়ংক্রিয়ভাবে খোঁজা। নিজের বাছা ছবি থাকলে force ছাড়া ছোঁয়া হয় না
  static Future<void> reset(int id, {bool force = false}) async {
    final d = await dir();
    if (!force && await File('${d.path}/${id}_hq.manual').exists()) return;
    await _rm('${d.path}/${id}_hq.jpg');
    await _rm('${d.path}/${id}_hq.none');
    await _rm('${d.path}/${id}_hq.manual');
    imageCache.clear();
  }

  static Future<void> _rm(String p) async {
    try {
      final f = File(p);
      if (await f.exists()) await f.delete();
    } catch (_) {}
  }
}
