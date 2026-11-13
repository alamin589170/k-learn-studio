import 'package:flutter/material.dart';
import 'pages.dart';

void main() => runApp(const KLearnApp());

class Feature {
  final String title;
  final String sub;
  final IconData icon;
  final Color color;
  const Feature(this.title, this.sub, this.icon, this.color);
}

const features = [
  Feature('3D ফ্ল্যাশকার্ড', 'শব্দ, ছবি ও অডিও', Icons.style, Color(0xFF6C5CE7)),
  Feature('ছবি ম্যানেজার', 'ক্যামেরা ও গ্যালারি', Icons.image, Color(0xFFE17055)),
  Feature('PDF লাইব্রেরি', 'বই পড়া ও নোট', Icons.picture_as_pdf, Color(0xFFD63031)),
  Feature('স্মার্ট রিডিং', 'PDF থেকে অনুবাদ', Icons.auto_stories, Color(0xFF00B894)),
  Feature('ক্যামেরা OCR', 'স্ক্যান করে অর্থ', Icons.document_scanner, Color(0xFF0984E3)),
  Feature('অভিধান', 'কোরিয়ান-বাংলা', Icons.menu_book, Color(0xFF6C5CE7)),
  Feature('পড়া ও শোনা', 'গল্প ও কথোপকথন', Icons.headphones, Color(0xFFE84393)),
  Feature('গ্রামার সেন্টার', 'হাঙ্গুল থেকে TOPIK', Icons.school, Color(0xFF00CEC9)),
  Feature('কুইজ ও টেস্ট', 'নিজেকে যাচাই', Icons.quiz, Color(0xFFFDAA5E)),
  Feature('আমার শব্দ', 'সংরক্ষিত শব্দ', Icons.bookmark, Color(0xFFE17055)),
  Feature('AI টিউটর', 'বাংলায় প্রশ্ন করুন', Icons.smart_toy, Color(0xFF6C5CE7)),
  Feature('স্মার্ট রিভিশন', 'ভুলে যাওয়া শব্দ', Icons.replay, Color(0xFF00B894)),
  Feature('বাক্য নির্মাতা', 'বাংলা থেকে কোরিয়ান', Icons.edit_note, Color(0xFF0984E3)),
  Feature('উচ্চারণ অনুশীলন', 'নিজের কণ্ঠ রেকর্ড', Icons.mic, Color(0xFFD63031)),
  Feature('TOPIK / EPS', 'মডেল টেস্ট', Icons.assignment, Color(0xFFE84393)),
  Feature('আমার অগ্রগতি', 'রিপোর্ট ও হিসাব', Icons.bar_chart, Color(0xFF00CEC9)),
  Feature('স্টাডি প্ল্যানার', 'দৈনিক লক্ষ্য', Icons.event_note, Color(0xFFFDAA5E)),
  Feature('ওয়েবসাইট হাব', 'দরকারি লিংক', Icons.language, Color(0xFF6C5CE7)),
  Feature('কানেক্টেড অ্যাপস', 'সমর্থিত সার্ভিস', Icons.apps, Color(0xFFE17055)),
  Feature('ক্লাউড ব্যাকআপ', 'ব্যাকআপ ও সিঙ্ক', Icons.cloud_upload, Color(0xFF00B894)),
  Feature('সার্চ', 'সবকিছু একসঙ্গে খুঁজুন', Icons.search, Color(0xFF0984E3)),
  Feature('সেটিংস', 'থিম ও ফন্ট', Icons.settings, Color(0xFF636E72)),
];

class KLearnApp extends StatefulWidget {
  const KLearnApp({super.key});
  @override
  State<KLearnApp> createState() => _KLearnAppState();
}

class _KLearnAppState extends State<KLearnApp> {
  ThemeMode mode = ThemeMode.light;

  void toggle() => setState(() {
        mode = mode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
      });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'K-Learn Studio',
      debugShowCheckedModeBanner: false,
      themeMode: mode,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFF6C5CE7),
        brightness: Brightness.light,
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFF6C5CE7),
        brightness: Brightness.dark,
      ),
      home: HomePage(onToggle: toggle, isDark: mode == ThemeMode.dark),
    );
  }
}

class HomePage extends StatelessWidget {
  final VoidCallback onToggle;
  final bool isDark;
  const HomePage({super.key, required this.onToggle, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('K-Learn Studio',
            style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode),
            onPressed: onToggle,
          ),
        ],
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(12),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.1,
        ),
        itemCount: features.length,
        itemBuilder: (context, i) {
          final f = features[i];
          return InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) =>
                      vocabPageFor(i) ?? ComingSoonPage(feature: f)),
            ),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [f.color, f.color.withOpacity(0.7)],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Icon(f.icon, color: Colors.white, size: 34),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(f.title,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold)),
                      const SizedBox(height: 2),
                      Text(f.sub,
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 12)),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class ComingSoonPage extends StatelessWidget {
  final Feature feature;
  const ComingSoonPage({super.key, required this.feature});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(feature.title)),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(feature.icon, size: 80, color: feature.color),
            const SizedBox(height: 16),
            const Text('শীঘ্রই আসছে',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
