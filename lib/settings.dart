import 'package:flutter/material.dart';
import 'about.dart';
import 'style.dart';
import 'vocab.dart';

class AppSettings {
  static final ValueNotifier<int> preset = ValueNotifier(0);
  static int lastDark = kDefaultDark;
  static int lastLight = kDefaultLight;
  static final ValueNotifier<int> accent = ValueNotifier(0);
  static final ValueNotifier<double> warm = ValueNotifier(0.0);
  static final ValueNotifier<double> dim = ValueNotifier(0.0);
  static final ValueNotifier<double> textScale = ValueNotifier(1.0);
  static final ValueNotifier<double> speech = ValueNotifier(0.4);
  static final ValueNotifier<bool> animate = ValueNotifier(true);
  static final ValueNotifier<int> animSecs = ValueNotifier(14);

  // 0 মানে থিমের নিজস্ব রঙ
  static const List<int> accents = [
    0xFF4DA3FF,
    0xFFB79CFF,
    0xFF34E0C4,
    0xFFFF7EB8,
    0xFFFFB066,
    0xFF52E8A0,
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
    final p = int.tryParse(m['preset3'] ?? '') ?? 0;
    preset.value = (p >= 0 && p < kPresets.length) ? p : 0;
    if (kPresets[preset.value].dark) {
      lastDark = preset.value;
    } else {
      lastLight = preset.value;
    }
    accent.value = int.tryParse(m['accent'] ?? '') ?? 0;
    warm.value = double.tryParse(m['warm'] ?? '') ?? 0.0;
    dim.value = double.tryParse(m['dim'] ?? '') ?? 0.0;
    textScale.value = double.tryParse(m['scale'] ?? '') ?? 1.0;
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

  static Future<void> setPreset(int i) async {
    preset.value = i;
    if (kPresets[i].dark) {
      lastDark = i;
    } else {
      lastLight = i;
    }
    await save('preset3', '$i');
  }

  // সূর্য/চাঁদ বাটন: রাত হলে দিনের থিমে, দিন হলে রাতের থিমে
  static Future<void> toggleDayNight(bool nowDark) =>
      setPreset(nowDark ? lastLight : lastDark);

  static Future<void> setAccent(int c) async {
    accent.value = c;
    await save('accent', '$c');
  }

  static Future<void> setWarm(double v) async {
    warm.value = v;
    await save('warm', '$v');
  }

  static Future<void> setDim(double v) async {
    dim.value = v;
    await save('dim', '$v');
  }

  static Future<void> setScale(double s) async {
    textScale.value = s;
    await save('scale', '$s');
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

  Widget _title(String t, [String? sub]) => Padding(
        padding: const EdgeInsets.fromLTRB(4, 22, 4, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(t,
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            if (sub != null)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(sub, style: const TextStyle(fontSize: 13)),
              ),
          ],
        ),
      );

  Widget _presetCard(BuildContext context, int i, bool sel, double w) {
    final p = kPresets[i];
    return GestureDetector(
      onTap: () => AppSettings.setPreset(i),
      child: Container(
        width: w,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [p.bg1, p.bg2]),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
              color: sel ? p.primary : Colors.white24, width: sel ? 3 : 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 34,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: p.card,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  CircleAvatar(radius: 8, backgroundColor: p.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Container(
                        height: 6,
                        decoration: BoxDecoration(
                            color: p.soft.withOpacity(0.5),
                            borderRadius: BorderRadius.circular(3))),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Text(p.name,
                      maxLines: 2,
                      style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: p.text)),
                ),
                if (sel) Icon(Icons.check_circle, color: p.primary, size: 18),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cardW = (MediaQuery.of(context).size.width - 32 - 10) / 2;
    return Scaffold(
      appBar: AppBar(title: const Text('সেটিংস')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _title('থিম', 'ক্রিস্টাল থিম বেছে নিন (সূর্য/চাঁদ বাটনেও দিন-রাত বদলায়)'),
            ValueListenableBuilder<int>(
              valueListenable: AppSettings.preset,
              builder: (c, cur, _) => Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  for (var i = 0; i < kPresets.length; i++)
                    _presetCard(context, i, cur == i, cardW),
                ],
              ),
            ),
            _title('আলাদা রঙ (অ্যাকসেন্ট)', 'থিমের মূল রঙ বদলাতে চাইলে'),
            ValueListenableBuilder<int>(
              valueListenable: AppSettings.accent,
              builder: (c, cur, _) => Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  GestureDetector(
                    onTap: () => AppSettings.setAccent(0),
                    child: CircleAvatar(
                      radius: 22,
                      backgroundColor: Colors.grey.shade600,
                      child: cur == 0
                          ? const Icon(Icons.check, color: Colors.white)
                          : const Text('Auto',
                              style: TextStyle(
                                  fontSize: 11, color: Colors.white)),
                    ),
                  ),
                  for (final col in AppSettings.accents)
                    GestureDetector(
                      onTap: () => AppSettings.setAccent(col),
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
            _title('চোখের আরাম', 'রাতে বা কম আলোতে পড়ার জন্য'),
            ValueListenableBuilder<double>(
              valueListenable: AppSettings.warm,
              builder: (c, v, _) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('উষ্ণ ফিল্টার (নীল আলো কমায়): ${(v * 100).round()}%'),
                  Slider(
                    value: v,
                    min: 0,
                    max: 1,
                    onChanged: (x) => AppSettings.warm.value = x,
                    onChangeEnd: (x) => AppSettings.setWarm(x),
                  ),
                ],
              ),
            ),
            ValueListenableBuilder<double>(
              valueListenable: AppSettings.dim,
              builder: (c, v, _) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('স্ক্রিন কম উজ্জ্বল: ${(v * 200).round()}%'),
                  Slider(
                    value: v,
                    min: 0,
                    max: 0.5,
                    onChanged: (x) => AppSettings.dim.value = x,
                    onChangeEnd: (x) => AppSettings.setDim(x),
                  ),
                ],
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
