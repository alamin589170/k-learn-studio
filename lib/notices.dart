import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'style.dart';

class Notice {
  final String title, url;
  const Notice(this.title, this.url);
}

// BOESL (boesl.gov.bd) এর সর্বশেষ নোটিশ। ইন্টারনেট থাকলে আনে, ফোনে জমা রাখে,
// অফলাইনে জমা থাকা নোটিশ দেখায়। বারবার আনে না: কমপক্ষে ২ ঘণ্টা পরপর।
class BoeslNotices {
  static const String home = 'https://boesl.gov.bd/';
  static const List<String> _pages = [
    'https://boesl.gov.bd/site/view/notices',
    'https://boesl.gov.bd/',
  ];
  static const Duration _every = Duration(hours: 2);
  static final ValueNotifier<List<Notice>> items = ValueNotifier(const []);
  static bool _loadedCache = false;
  static bool _busy = false;
  static DateTime? _lastTry;

  static Future<File> _file() async {
    final d = await getApplicationDocumentsDirectory();
    return File('${d.path}/boesl_notices.json');
  }

  static Future<void> _readCache() async {
    if (_loadedCache) return;
    _loadedCache = true;
    try {
      final f = await _file();
      if (!await f.exists()) return;
      final m = jsonDecode(await f.readAsString()) as Map;
      final l = (m['items'] as List)
          .map((e) => Notice('${(e as Map)['t']}', '${e['u']}'))
          .toList();
      if (l.isNotEmpty) items.value = l;
      final ts = int.tryParse('${m['ts']}');
      if (ts != null) _lastTry = DateTime.fromMillisecondsSinceEpoch(ts);
    } catch (_) {}
  }

  static Future<void> ensure({bool force = false}) async {
    await _readCache();
    if (_busy) return;
    final lt = _lastTry;
    if (!force && lt != null && DateTime.now().difference(lt) < _every) return;
    _busy = true;
    try {
      for (final p in _pages) {
        final l = await _fetch(p);
        if (l.length >= 2) {
          items.value = l;
          final f = await _file();
          await f.writeAsString(jsonEncode({
            'ts': DateTime.now().millisecondsSinceEpoch,
            'items': [
              for (final n in l) {'t': n.title, 'u': n.url}
            ],
          }));
          _lastTry = DateTime.now();
          break;
        }
      }
    } catch (_) {
    } finally {
      _busy = false;
    }
  }

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

  static Future<List<Notice>> _fetch(String page) async {
    try {
      final r = await http.get(Uri.parse(page), headers: {
        'User-Agent': 'Mozilla/5.0 (Android) KLearnStudio',
        'Accept-Language': 'bn,en;q=0.8',
      }).timeout(const Duration(seconds: 15));
      if (r.statusCode != 200) return const [];
      final body = utf8.decode(r.bodyBytes, allowMalformed: true);
      final base = Uri.parse(page);
      final re = RegExp(r'<a\b[^>]*?href\s*=\s*"([^"]+)"[^>]*>(.*?)</a>',
          caseSensitive: false, dotAll: true);
      final seen = <String>{};
      final out = <Notice>[];
      for (final m in re.allMatches(body)) {
        final href = m.group(1)!.trim();
        if (!RegExp(r'/(site/)?notice', caseSensitive: false).hasMatch(href)) {
          continue;
        }
        if (href.contains('view/notices') || href.endsWith('/notices')) continue;
        final t = _clean(m.group(2)!);
        if (t.length < 8 || t == 'সকল' || t == 'বিস্তারিত') continue;
        final u = base.resolve(href).toString();
        if (!seen.add(u)) continue;
        out.add(Notice(t, u));
        if (out.length >= 15) break;
      }
      return out;
    } catch (_) {
      return const [];
    }
  }
}

// এক লাইনের চলমান নোটিশ: একটি করে নোটিশ ডান থেকে বাঁয়ে সরে যায়, চাপলে মূল নোটিশ খোলে
class NoticeTicker extends StatefulWidget {
  const NoticeTicker({super.key});
  @override
  State<NoticeTicker> createState() => _NoticeTickerState();
}

class _NoticeTickerState extends State<NoticeTicker>
    with SingleTickerProviderStateMixin {
  late final AnimationController c =
      AnimationController(vsync: this, duration: const Duration(seconds: 12));
  int idx = 0;
  double boxW = 0, textW = 0;
  String shownKey = '';

  static const TextStyle _st =
      TextStyle(fontSize: 14, fontWeight: FontWeight.w600);

  @override
  void initState() {
    super.initState();
    c.addStatusListener((s) {
      if (s == AnimationStatus.completed && mounted) {
        final n = BoeslNotices.items.value.length;
        if (n <= 1) {
          c.forward(from: 0);
        } else {
          setState(() => idx = (idx + 1) % n);
        }
      }
    });
    BoeslNotices.items.addListener(_changed);
    BoeslNotices.ensure();
  }

  void _changed() {
    if (mounted) setState(() => idx = 0);
  }

  @override
  void dispose() {
    BoeslNotices.items.removeListener(_changed);
    c.dispose();
    super.dispose();
  }

  Notice get cur {
    final l = BoeslNotices.items.value;
    if (l.isEmpty) {
      return const Notice(
          'BOESL-এর সর্বশেষ নোটিশ দেখতে এখানে চাপুন', BoeslNotices.home);
    }
    return l[idx % l.length];
  }

  void _restart(double w) {
    final n = cur;
    final tp = TextPainter(
        text: TextSpan(text: n.title, style: _st),
        maxLines: 1,
        textDirection: TextDirection.ltr)
      ..layout();
    textW = tp.width;
    boxW = w;
    final secs = ((w + textW) / 55).clamp(6, 40).toDouble();
    c.duration = Duration(milliseconds: (secs * 1000).round());
    c.forward(from: 0);
  }

  Future<void> open() async {
    try {
      await launchUrl(Uri.parse(cur.url), mode: LaunchMode.externalApplication);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final pr = Theme.of(context).colorScheme.primary;
    final n = cur;
    return GestureDetector(
      onTap: open,
      child: Container(
        height: 44,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: pr.withOpacity(0.55)),
          color: Colors.white.withOpacity(0.06),
        ),
        child: Row(
          children: [
            Icon(Icons.campaign_rounded, color: pr, size: 22),
            const SizedBox(width: 8),
            Expanded(
              child: LayoutBuilder(
                builder: (ctx, box) {
                  final key = '${n.url}|${box.maxWidth.round()}';
                  if (key != shownKey) {
                    shownKey = key;
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted) _restart(box.maxWidth);
                    });
                  }
                  return ClipRect(
                    child: AnimatedBuilder(
                      animation: c,
                      builder: (context, _) {
                        final x = box.maxWidth -
                            (box.maxWidth + textW) * c.value;
                        return OverflowBox(
                          alignment: Alignment.centerLeft,
                          minWidth: 0,
                          maxWidth: double.infinity,
                          child: Transform.translate(
                            offset: Offset(x, 0),
                            child: Text(n.title,
                                maxLines: 1,
                                softWrap: false,
                                style: _st.copyWith(color: Theme.of(context).colorScheme.onSurface)),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
