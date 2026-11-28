import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'style.dart';

class Notice {
  final String title, url;
  const Notice(this.title, this.url);
}

class NewsSource {
  final String key, label, url;
  const NewsSource(this.key, this.label, this.url);
}

// BOESL (boesl.gov.bd) এর দুটি তালিকা। ইন্টারনেট থাকলে আনে, ফোনে জমা রাখে,
// অফলাইনে জমা থাকা তালিকা দেখায়। কমপক্ষে ২ ঘণ্টা পরপর আনে।
class BoeslNotices {
  static const String home = 'https://boesl.gov.bd/';
  static const String rawUrl =
      'https://raw.githubusercontent.com/alamin589170/k-learn-studio/main/data/notices.json';
  static const List<NewsSource> sources = [
    NewsSource('news', 'সর্বশেষ খবর', 'https://boesl.gov.bd/pages/news/'),
    NewsSource('board', 'নোটিশ বোর্ড', 'https://boesl.gov.bd/views/latest-news'),
  ];
  static final ValueNotifier<bool> failed = ValueNotifier(false);
  static const Duration _every = Duration(hours: 2);
  static final Map<String, ValueNotifier<List<Notice>>> lists = {
    for (final s in sources) s.key: ValueNotifier<List<Notice>>(const [])
  };
  static bool _loadedCache = false;
  static bool _busy = false;
  static DateTime? _lastTry;

  static Future<File> _file() async {
    final d = await getApplicationDocumentsDirectory();
    return File('${d.path}/boesl_notices2.json');
  }

  static Future<void> _readCache() async {
    if (_loadedCache) return;
    _loadedCache = true;
    try {
      final f = await _file();
      if (!await f.exists()) return;
      final m = jsonDecode(await f.readAsString()) as Map;
      for (final s in sources) {
        final raw = m[s.key];
        if (raw is List) {
          final l = raw
              .map((e) => Notice('${(e as Map)['t']}', '${e['u']}'))
              .toList();
          final cl = _onlyNotices(l);
          if (cl.isNotEmpty) lists[s.key]!.value = cl;
        }
      }
      final ts = int.tryParse('${m['ts']}');
      if (ts != null) _lastTry = DateTime.fromMillisecondsSinceEpoch(ts);
    } catch (_) {}
  }

  // GitHub-এর data/notices.json (Actions নিজে আপডেট করে) থেকে পড়ে
  static Future<bool> _fromRepo() async {
    try {
      final r = await http
          .get(Uri.parse('$rawUrl?t=${DateTime.now().millisecondsSinceEpoch}'))
          .timeout(const Duration(seconds: 12));
      if (r.statusCode != 200) return false;
      final m = jsonDecode(utf8.decode(r.bodyBytes)) as Map;
      final boxes = m['boxes'];
      if (boxes is! Map) return false;
      var any = false;
      for (final s in sources) {
        final raw = boxes[s.key];
        if (raw is List && raw.isNotEmpty) {
          final cl = _onlyNotices([
            for (final e in raw) Notice('${(e as Map)['t']}', '${e['u']}')
          ]);
          if (cl.isEmpty) continue;
          lists[s.key]!.value = cl;
          any = true;
        }
      }
      return any;
    } catch (_) {
      return false;
    }
  }

  static Future<void> ensure({bool force = false}) async {
    await _readCache();
    if (_busy) return;
    final lt = _lastTry;
    if (!force && lt != null && DateTime.now().difference(lt) < _every) return;
    _busy = true;
    try {
      var any = await _fromRepo();
      if (!any) {
        // লুকানো ব্রাউজারে পাতা খুলে পড়া (জাভাস্ক্রিপ্টে তৈরি পাতাও পড়া যায়)
        for (final s in sources) {
          var l = await _viaWebView(s.url);
          if (l.isEmpty) l = await _fetch(s.url);
          l = _onlyNotices(l);
          if (l.isNotEmpty) {
            lists[s.key]!.value = l;
            any = true;
          }
        }
      }
      if (any) {
        final f = await _file();
        await f.writeAsString(jsonEncode({
          'ts': DateTime.now().millisecondsSinceEpoch,
          for (final s in sources)
            s.key: [
              for (final n in lists[s.key]!.value) {'t': n.title, 'u': n.url}
            ],
        }));
        _lastTry = DateTime.now();
      }
      failed.value = lists.values.every((v) => v.value.isEmpty);
    } catch (_) {
    } finally {
      _busy = false;
    }
  }

  // সেটিংসের "নোটিশ পরীক্ষা" বাটনের জন্য: কী আসছে তার রিপোর্ট
  static Future<String> diagnose() async {
    final b = StringBuffer();
    b.writeln('● GitHub তালিকা: ${await _fromRepo() ? "পাওয়া গেছে" : "পাওয়া যায়নি"}\n');
    for (final s in sources) {
      b.writeln('● ${s.label}\n${s.url}');
      try {
        final r = await http.get(Uri.parse(s.url), headers: _headers)
            .timeout(const Duration(seconds: 15));
        final body = utf8.decode(r.bodyBytes, allowMalformed: true);
        final l = parse(body, Uri.parse(s.url));
        b.writeln('স্ট্যাটাস ${r.statusCode}, আকার ${body.length}, পাওয়া ${l.length}টি');
        for (final n in l.take(3)) {
          b.writeln('  - ${n.title}');
        }
        if (l.isEmpty) {
          final t = body.replaceAll(RegExp(r'\s+'), ' ');
          b.writeln('শুরুর অংশ: ${t.substring(0, t.length > 350 ? 350 : t.length)}');
        }
      } catch (e) {
        b.writeln('ব্যর্থ: $e');
      }
      b.writeln();
    }
    return b.toString();
  }

  static const Map<String, String> _headers = {
    'User-Agent':
        'Mozilla/5.0 (Linux; Android 13) AppleWebKit/537.36 Chrome/120 Mobile Safari/537.36',
    'Accept-Language': 'bn,en;q=0.8',
  };

  static String _clean(String s) {
    var t = s.replaceAll(RegExp(r'<[^>]*>'), ' ');
    t = t
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>');
    t = t.replaceAllMapped(RegExp(r'&#(\d+);'), (m) {
      final c = int.tryParse(m.group(1)!);
      return c == null ? '' : String.fromCharCode(c);
    });
    return t.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  static const Set<String> _skip = {
    'সকল', 'সব', 'বিস্তারিত', 'আরও', 'আরো', 'সকল নোটিশ দেখুন', 'হোম', 'Home',
    'আরও দেখুন', 'বিস্তারিত দেখুন', 'Read More', 'more',
  };

  static void _walk(dynamic d, Uri base, List<Notice> out) {
    if (d is List) {
      for (final e in d) {
        _walk(e, base, out);
      }
    } else if (d is Map) {
      String? title;
      String? link;
      for (final k in const ['title', 'subject', 'heading', 'name', 'title_bn']) {
        final v = d[k];
        if (v is String && v.trim().length > 6) {
          title = _clean(v);
          break;
        }
      }
      for (final k in const ['url', 'link', 'href', 'file', 'slug']) {
        final v = d[k];
        if (v is String && v.isNotEmpty) {
          link = v;
          break;
        }
      }
      if (title != null) {
        out.add(Notice(title, base.resolve(link ?? base.toString()).toString()));
      }
      for (final v in d.values) {
        if (v is List || v is Map) _walk(v, base, out);
      }
    }
  }

  static List<Notice> parse(String body, Uri base) {
    final out = <Notice>[];
    final tb = body.trimLeft();
    if (tb.startsWith('{') || tb.startsWith('[')) {
      try {
        _walk(jsonDecode(tb), base, out);
      } catch (_) {}
      if (out.isNotEmpty) return _dedupe(out);
    }
    final re = RegExp(r'<a\b[^>]*?href\s*=\s*["\x27]([^"\x27]+)["\x27][^>]*>(.*?)</a>',
        caseSensitive: false, dotAll: true);
    final all = <Notice>[];
    final likely = <Notice>[];
    for (final m in re.allMatches(body)) {
      final href = m.group(1)!.trim();
      if (href.startsWith('#') ||
          href.startsWith('javascript') ||
          href.startsWith('mailto') ||
          href.startsWith('tel')) {
        continue;
      }
      final t = _clean(m.group(2)!);
      if (t.length < 12 || _skip.contains(t)) continue;
      final n = Notice(t, base.resolve(href).toString());
      all.add(n);
      if (RegExp(r'news|notice|detail|view|id=|/\d{2,}', caseSensitive: false)
          .hasMatch(href)) {
        likely.add(n);
      }
    }
    var res = likely.length >= 3 ? likely : all;
    if (res.isEmpty) {
      final li = RegExp(r'<li\b[^>]*>(.*?)</li>', caseSensitive: false, dotAll: true);
      for (final m in li.allMatches(body)) {
        final t = _clean(m.group(1)!);
        if (t.length >= 15 && !_skip.contains(t)) res.add(Notice(t, base.toString()));
      }
    }
    return _dedupe(res);
  }

  // নোটিশ নয় এমন লিংক (স্ক্রিন রিডার, ফাইল ডাউনলোড, বাইরের সাইট) বাদ
  static List<Notice> _onlyNotices(List<Notice> l) {
    final bad = RegExp(r'স্ক্রিন\s*রিডার|screen\s*reader|nvda|nvaccess',
        caseSensitive: false);
    final file = RegExp(r'\.(exe|apk|zip|msi|dmg)(\?|$)', caseSensitive: false);
    return [
      for (final n in l)
        if (!bad.hasMatch(n.title) &&
            !bad.hasMatch(n.url) &&
            !file.hasMatch(n.url))
          n
    ];
  }

  static List<Notice> _dedupe(List<Notice> l) {
    final seen = <String>{};
    final out = <Notice>[];
    for (final n in l) {
      if (!seen.add(n.title)) continue;
      out.add(n);
      if (out.length >= 20) break;
    }
    return out;
  }

  static const String _js = r'''(function(){var skip=['সকল','সব','বিস্তারিত','আরও','আরো','হোম'];var items=[],loose=[],seen={};document.querySelectorAll('a[href]').forEach(function(a){var t=(a.innerText||a.textContent||'').replace(/\s+/g,' ').trim();var h=a.href;if(!t||h.indexOf('javascript')==0||h.slice(-1)=='#')return;if(t.length<12||skip.indexOf(t)>=0||seen[t])return;seen[t]=1;var bad=a.closest('nav,header,footer,aside,[class*="menu"],[class*="nav"],[id*="menu"],[id*="nav"],[class*="footer"],[class*="breadcrumb"]');loose.push({t:t,u:h});if(!bad)items.push({t:t,u:h});});var r=items.length?items:loose;return JSON.stringify(r.slice(0,20));})()''';

  static Future<List<Notice>> _viaWebView(String page) async {
    final done = Completer<List<Notice>>();
    try {
      late final WebViewController c;
      c = WebViewController();
      await c.setJavaScriptMode(JavaScriptMode.unrestricted);
      await c.setNavigationDelegate(NavigationDelegate(onPageFinished: (_) async {
        await Future<void>.delayed(const Duration(seconds: 3));
        try {
          final r = await c.runJavaScriptReturningResult(_js);
          var t = r.toString();
          if (t.startsWith('"')) t = jsonDecode(t) as String;
          final l = (jsonDecode(t) as List)
              .map((e) => Notice('${(e as Map)['t']}', '${e['u']}'))
              .toList();
          if (!done.isCompleted) done.complete(l);
        } catch (_) {
          if (!done.isCompleted) done.complete(const <Notice>[]);
        }
      }));
      await c.loadRequest(Uri.parse(page));
      return await done.future
          .timeout(const Duration(seconds: 35), onTimeout: () => const <Notice>[]);
    } catch (_) {
      return const [];
    }
  }

  static Future<List<Notice>> _fetch(String page) async {
    try {
      final r = await http
          .get(Uri.parse(page), headers: _headers)
          .timeout(const Duration(seconds: 15));
      if (r.statusCode != 200) return const [];
      return parse(utf8.decode(r.bodyBytes, allowMalformed: true), Uri.parse(page));
    } catch (_) {
      return const [];
    }
  }
}

// চিকন এক লাইনের বাক্স: লেখা ডান থেকে বামে চলে; শেষ হলে পরের নোটিশ নিচ থেকে ওপরে ওঠে
class NewsBox extends StatefulWidget {
  final NewsSource source;
  final Color accent;
  const NewsBox({super.key, required this.source, required this.accent});
  @override
  State<NewsBox> createState() => _NewsBoxState();
}

class _NewsBoxState extends State<NewsBox> {
  int idx = 0;
  int round = 0;
  late final ValueNotifier<List<Notice>> data = BoeslNotices.lists[widget.source.key]!;

  @override
  void initState() {
    super.initState();
    data.addListener(_changed);
    BoeslNotices.failed.addListener(_changed);
    BoeslNotices.ensure();
  }

  void _changed() {
    if (mounted) {
      setState(() {
        idx = 0;
        round++;
      });
    }
  }

  void _next() {
    if (!mounted) return;
    setState(() {
      final n = data.value.length;
      if (n > 0) idx = (idx + 1) % n;
      round++;
    });
  }

  @override
  void dispose() {
    data.removeListener(_changed);
    BoeslNotices.failed.removeListener(_changed);
    super.dispose();
  }

  Future<void> open(String u) async {
    try {
      await launchUrl(Uri.parse(u), mode: LaunchMode.externalApplication);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final l = data.value;
    final empty = l.isEmpty;
    final Notice n = empty
        ? Notice(
            BoeslNotices.failed.value
                ? 'এখন আনা যায়নি — সাইট খুলতে চাপুন'
                : 'লোড হচ্ছে…',
            widget.source.url)
        : l[idx % l.length];
    final cur = ValueKey<String>('${widget.source.key}-$idx-$round-${l.length}');
    return GestureDetector(
      onTap: () => open(n.url),
      child: Container(
        height: 42,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: widget.accent.withOpacity(0.55)),
          color: widget.accent.withOpacity(0.08),
        ),
        child: Row(
          children: [
            Icon(Icons.campaign_rounded, size: 18, color: widget.accent),
            const SizedBox(width: 6),
            Text(widget.source.label,
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: widget.accent)),
            const SizedBox(width: 8),
            Expanded(
              child: ClipRect(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 450),
                  transitionBuilder: (child, anim) {
                    final incoming = child.key == cur;
                    return SlideTransition(
                      position: Tween<Offset>(
                        begin: incoming ? const Offset(0, 1) : const Offset(0, -1),
                        end: Offset.zero,
                      ).animate(anim),
                      child: child,
                    );
                  },
                  child: _Line(
                    key: cur,
                    text: n.title,
                    onDone: empty ? null : _next,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// একটি লাইন: ছোট হলে স্থির থাকে, বড় হলে ডান থেকে বামে চলে, তারপর onDone
class _Line extends StatefulWidget {
  final String text;
  final VoidCallback? onDone;
  const _Line({super.key, required this.text, this.onDone});
  @override
  State<_Line> createState() => _LineState();
}

class _LineState extends State<_Line> with SingleTickerProviderStateMixin {
  static const style = TextStyle(fontSize: 13.5);
  late final AnimationController ctl = AnimationController(vsync: this);
  bool started = false;
  bool dead = false;

  @override
  void dispose() {
    dead = true;
    ctl.dispose();
    super.dispose();
  }

  Future<void> run(double overflow) async {
    await Future.delayed(const Duration(milliseconds: 1200));
    if (dead) return;
    if (overflow > 0) {
      final ms = (overflow / 45 * 1000).round().clamp(2000, 60000);
      try {
        await ctl.animateTo(1,
            duration: Duration(milliseconds: ms), curve: Curves.linear);
      } catch (_) {
        return;
      }
      if (dead) return;
      await Future.delayed(const Duration(milliseconds: 1000));
    } else {
      await Future.delayed(const Duration(milliseconds: 1800));
    }
    if (dead) return;
    widget.onDone?.call();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      final tp = TextPainter(
        text: TextSpan(text: widget.text, style: style),
        maxLines: 1,
        textDirection: TextDirection.ltr,
      )..layout();
      final over = tp.width - c.maxWidth;
      if (!started && widget.onDone != null) {
        started = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!dead) run(over);
        });
      }
      return Align(
        alignment: Alignment.centerLeft,
        child: AnimatedBuilder(
          animation: ctl,
          builder: (context, _) => Transform.translate(
            offset: Offset(over > 0 ? -over * ctl.value : 0, 0),
            child: OverflowBox(
              alignment: Alignment.centerLeft,
              minWidth: 0,
              maxWidth: double.infinity,
              child: Text(widget.text,
                  maxLines: 1, softWrap: false, style: style),
            ),
          ),
        ),
      );
    });
  }
}
