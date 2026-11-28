import 'dart:convert';
import 'package:http/http.dart' as http;
import 'resume.dart';
import 'vocab.dart';

// ডেভেলপারের সম্পাদনা নিজে থেকে GitHub-এর data/catalog.json-এ জমা হয়,
// তারপর সবার অ্যাপে (rev বাড়ায়) পৌঁছায়। টোকেন শুধু ডেভেলপারের ফোনে থাকে।
class DevSync {
  static const String repo = 'alamin589170/k-learn-studio';
  static const String path = 'data/catalog.json';

  static Future<String> token() async =>
      ((await Resume.getStr('devtoken')) ?? '').trim();

  static Future<bool> enabled() async => (await token()).isNotEmpty;

  static Map<String, String> _h(String t) => {
        'Authorization': 'Bearer $t',
        'Accept': 'application/vnd.github+json',
        'User-Agent': 'KLearnStudio',
      };

  // টোকেন কাজ করছে কি না
  static Future<String> check() async {
    final t = await token();
    if (t.isEmpty) return 'টোকেন দেওয়া নেই';
    try {
      final r = await http
          .get(Uri.parse('https://api.github.com/repos/$repo/contents/$path'),
              headers: _h(t))
          .timeout(const Duration(seconds: 15));
      if (r.statusCode == 200) return 'সংযোগ ঠিক আছে ✔';
      if (r.statusCode == 401) return 'টোকেন ভুল বা মেয়াদ শেষ';
      if (r.statusCode == 404) return 'repo বা ফাইল পাওয়া যায়নি (টোকেনের অনুমতি দেখুন)';
      return 'সমস্যা: ${r.statusCode}';
    } catch (_) {
      return 'ইন্টারনেট সমস্যা';
    }
  }

  // একটি শব্দ নতুন হলে words-এ, আগের শব্দ বদলালে corrections-এ যোগ করে
  static Future<String> pushWord(
      {required String oldKo, required Word w, required bool isNew}) async {
    final t = await token();
    if (t.isEmpty) return '';
    for (var attempt = 0; attempt < 2; attempt++) {
      try {
        final url = Uri.parse('https://api.github.com/repos/$repo/contents/$path');
        final g = await http.get(url, headers: _h(t)).timeout(const Duration(seconds: 20));
        if (g.statusCode != 200) return 'সার্ভারে পাঠানো যায়নি (${g.statusCode})';
        final meta = jsonDecode(g.body) as Map;
        final sha = '${meta['sha']}';
        final text = utf8.decode(base64.decode('${meta['content']}'.replaceAll('\n', '')));
        final cat = jsonDecode(text) as Map<String, dynamic>;
        final row = [w.ko, w.pron, w.bn, w.en, w.ex];
        final words = (cat['words'] is List) ? List.of(cat['words'] as List) : <dynamic>[];
        final fixes = (cat['corrections'] is List) ? List.of(cat['corrections'] as List) : <dynamic>[];
        words.removeWhere((e) => e is List && e.isNotEmpty && '${e[0]}' == oldKo);
        fixes.removeWhere((e) => e is List && e.isNotEmpty && '${e[0]}' == oldKo);
        if (isNew || oldKo != w.ko) {
          words.add(row);
        } else {
          fixes.add(row);
        }
        cat['words'] = words;
        cat['corrections'] = fixes;
        cat['rev'] = (int.tryParse('${cat['rev']}') ?? 0) + 1;
        final out = const JsonEncoder.withIndent('  ').convert(cat);
        final p = await http
            .put(url,
                headers: _h(t),
                body: jsonEncode({
                  'message': isNew ? 'নতুন শব্দ: ${w.ko}' : 'সংশোধন: ${w.ko}',
                  'content': base64.encode(utf8.encode(out)),
                  'sha': sha,
                }))
            .timeout(const Duration(seconds: 25));
        if (p.statusCode == 200 || p.statusCode == 201) {
          return 'সবার অ্যাপের জন্য সার্ভারে জমা হয়েছে ✔';
        }
        if (p.statusCode == 409 && attempt == 0) continue;
        return 'সার্ভারে পাঠানো যায়নি (${p.statusCode})';
      } catch (_) {
        return 'সার্ভারে পাঠানো যায়নি (ইন্টারনেট?)';
      }
    }
    return 'সার্ভারে পাঠানো যায়নি';
  }
}
