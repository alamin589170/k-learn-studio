import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

class Images {
  static const String _pixKey = String.fromEnvironment('PIXABAY_KEY');
  static const String _pexKey = String.fromEnvironment('PEXELS_KEY');
  static Map<String, String>? _map;
  static final Set<int> tried = {};
  static final Map<int, int> _cursor = {};
  static const Map<String, String> _ua = {
    'User-Agent': 'KLearnStudio/1.0 (Korean learning app)'
  };

  static Future<File> _mapFile() async {
    final d = await getApplicationDocumentsDirectory();
    return File('${d.path}/images3.json');
  }

  static Future<void> _load() async {
    if (_map != null) return;
    try {
      final f = await _mapFile();
      if (await f.exists()) {
        final j = jsonDecode(await f.readAsString()) as Map<String, dynamic>;
        _map = j.map((k, v) => MapEntry(k, v as String));
        return;
      }
    } catch (_) {}
    _map = {};
  }

  static Future<void> _save() async {
    try {
      final f = await _mapFile();
      await f.writeAsString(jsonEncode(_map));
    } catch (_) {}
  }

  static Future<String?> get(int id) async {
    await _load();
    final p = _map!['$id'];
    if (p != null && await File(p).exists()) return p;
    return null;
  }

  static Future<void> _set(int id, String path) async {
    await _load();
    _map!['$id'] = path;
    await _save();
  }

  static Future<void> remove(int id) async {
    await _load();
    _map!.remove('$id');
    await _save();
  }

  static String query(String en) {
    var q = en.split('/').first.split('(').first.trim();
    if (q.toLowerCase().startsWith('to ')) q = q.substring(3).trim();
    return q;
  }

  static Future<List<String>> _pixabay(String q) async {
    if (_pixKey.isEmpty) return [];
    try {
      final uri = Uri.https('pixabay.com', '/api/', {
        'key': _pixKey,
        'q': q,
        'image_type': 'photo',
        'safesearch': 'true',
        'per_page': '15',
      });
      final r =
          await http.get(uri, headers: _ua).timeout(const Duration(seconds: 12));
      if (r.statusCode != 200) return [];
      final j = jsonDecode(r.body);
      final out = <String>[];
      final hits = j['hits'];
      if (hits is List) {
        for (final h in hits) {
          final u = h['webformatURL'];
          if (u is String) out.add(u);
        }
      }
      return out;
    } catch (_) {
      return [];
    }
  }

  static Future<List<String>> _pexels(String q) async {
    if (_pexKey.isEmpty) return [];
    try {
      final uri = Uri.https('api.pexels.com', '/v1/search', {
        'query': q,
        'per_page': '15',
      });
      final r = await http
          .get(uri, headers: {..._ua, 'Authorization': _pexKey})
          .timeout(const Duration(seconds: 12));
      if (r.statusCode != 200) return [];
      final j = jsonDecode(r.body);
      final out = <String>[];
      final photos = j['photos'];
      if (photos is List) {
        for (final p in photos) {
          final u = p['src']?['medium'];
          if (u is String) out.add(u);
        }
      }
      return out;
    } catch (_) {
      return [];
    }
  }

  static Future<List<String>> _openverse(String q) async {
    try {
      final uri = Uri.https('api.openverse.org', '/v1/images/', {
        'q': q,
        'page_size': '15',
        'category': 'photograph',
      });
      final r =
          await http.get(uri, headers: _ua).timeout(const Duration(seconds: 12));
      if (r.statusCode != 200) return [];
      final j = jsonDecode(r.body);
      final out = <String>[];
      final results = j['results'];
      if (results is List) {
        for (final x in results) {
          final u = x['thumbnail'];
          if (u is String) out.add(u);
        }
      }
      return out;
    } catch (_) {
      return [];
    }
  }

  static Future<List<String>> searchUrls(String q) async {
    if (q.trim().isEmpty) return [];
    final lists = await Future.wait([_pixabay(q), _pexels(q), _openverse(q)]);
    final out = <String>[];
    var i = 0;
    var more = true;
    while (more) {
      more = false;
      for (final l in lists) {
        if (i < l.length) {
          final u = l[i];
          if (!out.contains(u)) out.add(u);
          more = true;
        }
      }
      i++;
    }
    return out;
  }

  static Future<String?> _download(int id, String url) async {
    try {
      final r = await http
          .get(Uri.parse(url), headers: _ua)
          .timeout(const Duration(seconds: 20));
      if (r.statusCode != 200 || r.bodyBytes.isEmpty) return null;
      final d = await getApplicationDocumentsDirectory();
      final f = File(
          '${d.path}/img_${id}_${DateTime.now().millisecondsSinceEpoch}.jpg');
      await f.writeAsBytes(r.bodyBytes);
      await _set(id, f.path);
      return f.path;
    } catch (_) {
      return null;
    }
  }

  static Future<String?> auto(int id, String q) async {
    if (tried.contains(id)) return null;
    tried.add(id);
    final urls = await searchUrls(q);
    if (urls.isEmpty) return null;
    return _download(id, urls.first);
  }

  static Future<String?> nextOnline(int id, String q) async {
    final urls = await searchUrls(q);
    if (urls.isEmpty) return null;
    final i = ((_cursor[id] ?? 0) + 1) % urls.length;
    _cursor[id] = i;
    return _download(id, urls[i]);
  }

  static Future<String?> pick(int id, ImageSource s) async {
    try {
      final x = await ImagePicker()
          .pickImage(source: s, maxWidth: 1000, imageQuality: 85);
      if (x == null) return null;
      final d = await getApplicationDocumentsDirectory();
      final f = File(
          '${d.path}/img_${id}_${DateTime.now().millisecondsSinceEpoch}.jpg');
      await File(x.path).copy(f.path);
      await _set(id, f.path);
      return f.path;
    } catch (_) {
      return null;
    }
  }
}
