import 'package:flutter/material.dart';
import 'about.dart';
import 'vocab.dart';

class AppSettings {
  static final ValueNotifier<ThemeMode> mode = ValueNotifier(ThemeMode.light);
  static final ValueNotifier<double> textScale = ValueNotifier(1.0);
  static final ValueNotifier<int> seed = ValueNotifier(0xFFC05A2B);
  static final ValueNotifier<double> speech = ValueNotifier(0.4);
  static final ValueNotifier<bool> animate = ValueNotifier(true);
  static final ValueNotifier<int> animSecs = ValueNotifier(14);

  static const List<int> colors = [
    0xFFC05A2B,
    0xFF1B2F4A,
    0xFF00897B,
    0xFF6C5CE7,
    0xFFE84393,
    0xFF2E7D32,
  ];
  static const List<int> speeds = [24, 14, 7];

  static Future<void> _ensure() async {
    final db = await Db.get();
    await db.execute(
        'CREATE TABLE IF NOT EXISTS settings(k TEXT PRIMARY KEY, v TEXT NOT NULL)');
  }

  static Future<void> load() async {
    await _ensure();
    final db = await Db.get();
    final rows = await db.query('settings');
    final m = <String, String>{};
    for (final r in rows) {
      m[r['k'] as String] = r['v'] as String;
    }
    final t = m['mode'];
    mode.value = t == 'dark'
        ? ThemeMode.dark
        : (t == 'system' ? ThemeMode.system : ThemeMode.light);
    textScale.value = double.tryParse(m['scale'] ?? '') ?? 1.0;
    seed.value = int.tryParse(m['seed2'] ?? '') ?? 0xFFC05A2B;
    speech.value = double.tryParse(m['speech'] ?? '') ?? 0.4;
    animate.value = (m['anim'] ?? '1') == '1';
    final s = int.tryParse(m['animsecs'] ?? '') ?? 14;
    animSecs.value = speeds.contains(s) ? s : 14;
  }

  static Future<void> save(String k, String v) async {
    await _ensure();
    final db = await Db.get();
    await db.rawInsert(
        'INSERT OR REPLACE INTO settings(k, v) VALUES(?,?)', [k, v]);
  }

  static String _modeName(ThemeMode m) =>
      m == ThemeMode.dark ? 'dark' : (m == ThemeMode.system ? 'system' : 'light');

  static Future<void> setMode(ThemeMode m) async {
    mode.value = m;
    await save('mode', _modeName(m));
  }

  static Future<void> setScale(double s) async {
    textScale.value = s;
    await save('scale', '$s');
  }

  static Future<void> setSeed(int c) async {
    seed.value = c;
    await save('seed2', '$c');
  }

  static Future<void> setSpeech(double v) async {
    speech.value = v;
    await save('speech', '$v');
  }

  static Future<void> setAnimate(bool v) async {
    animate.value = v;
    await save('anim', v ? '1' : '0');
  }

  static Future<void> setAnimSecs(int v) async {
    animSecs.value = v;
    await save('animsecs', '$v');
  }
}

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  Widget _title(String t) => Padding(
        padding: const EdgeInsets.fromLTRB(4, 20, 4, 8),
        child: Text(t,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('সেটিংস')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _title('থিম'),
            ValueListenableBuilder<ThemeMode>(
              valueListenable: AppSettings.mode,
              builder: (c, m, _) => SegmentedButton<ThemeMode>(
                segments: const [
                  ButtonSegment(value: ThemeMode.light, label: Text('Light')),
                  ButtonSegment(value: ThemeMode.dark, label: Text('Dark')),
                  ButtonSegment(
                      value: ThemeMode.system, label: Text('ফোনের মতো')),
                ],
                selected: {m},
                onSelectionChanged: (s) => AppSettings.setMode(s.first),
              ),
            ),
            _title('রঙের এনিমেশন'),
            ValueListenableBuilder<bool>(
              valueListenable: AppSettings.animate,
              builder: (c, on, _) => SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('ব্যাকগ্রাউন্ডের রং ধীরে বদলাবে'),
                value: on,
                onChanged: (v) => AppSettings.setAnimate(v),
              ),
            ),
            ValueListenableBuilder<int>(
              valueListenable: AppSettings.animSecs,
              builder: (c, s, _) => SegmentedButton<int>(
                segments: const [
                  ButtonSegment(value: 24, label: Text('ধীর')),
                  ButtonSegment(value: 14, label: Text('মাঝারি')),
                  ButtonSegment(value: 7, label: Text('দ্রুত')),
                ],
                selected: {AppSettings.speeds.contains(s) ? s : 14},
                onSelectionChanged: (v) => AppSettings.setAnimSecs(v.first),
              ),
            ),
            _title('লেখার আকার'),
            ValueListenableBuilder<double>(
              valueListenable: AppSettings.textScale,
              builder: (c, s, _) => SegmentedButton<double>(
                segments: const [
                  ButtonSegment(value: 0.9, label: Text('ছোট')),
                  ButtonSegment(value: 1.0, label: Text('মাঝারি')),
                  ButtonSegment(value: 1.2, label: Text('বড়')),
                ],
                selected: {s},
                onSelectionChanged: (v) => AppSettings.setScale(v.first),
              ),
            ),
            _title('অ্যাপের রঙ'),
            ValueListenableBuilder<int>(
              valueListenable: AppSettings.seed,
              builder: (c, cur, _) => Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  for (final col in AppSettings.colors)
                    GestureDetector(
                      onTap: () => AppSettings.setSeed(col),
                      child: CircleAvatar(
                        radius: 22,
                        backgroundColor: Color(col),
                        child: cur == col
                            ? const Icon(Icons.check, color: Colors.white)
                            : null,
                      ),
                    ),
                ],
              ),
            ),
            _title('কোরিয়ান উচ্চারণের গতি'),
            ValueListenableBuilder<double>(
              valueListenable: AppSettings.speech,
              builder: (c, v, _) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Slider(
                    value: v,
                    min: 0.2,
                    max: 0.8,
                    divisions: 6,
                    label: v.toStringAsFixed(1),
                    onChanged: (x) => AppSettings.speech.value = x,
                    onChangeEnd: (x) => AppSettings.setSpeech(x),
                  ),
                  Row(
                    children: [
                      const Text('ধীর'),
                      const Spacer(),
                      OutlinedButton.icon(
                        icon: const Icon(Icons.volume_up),
                        label: const Text('শুনুন'),
                        onPressed: () => speakKorean('안녕하세요'),
                      ),
                      const Spacer(),
                      const Text('দ্রুত'),
                    ],
                  ),
                ],
              ),
            ),
            _title('অ্যাপ'),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.info_outline),
              title: const Text('অ্যাপ ও ডেভেলপার সম্পর্কে'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AboutPage()),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
