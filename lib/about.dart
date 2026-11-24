import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'style.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  static const String devName = 'MD Alamin';
  static const String devAddress = 'Khulna, Bangladesh';
  static const String devEmail = 'Alamin589170@gmail.com';

  Future<void> _mail(BuildContext context) async {
    var ok = false;
    try {
      ok = await launchUrl(
        Uri(scheme: 'mailto', path: devEmail),
        mode: LaunchMode.externalApplication,
      );
    } catch (_) {}
    if (!ok) {
      await Clipboard.setData(const ClipboardData(text: devEmail));
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('ইমেইল ঠিকানা কপি হয়েছে')));
      }
    }
  }

  Widget _row(BuildContext context, IconData icon, String label, String value,
      {VoidCallback? onTap}) {
    return ListTile(
      leading: IconCircle(icon: icon, color: kNavy, size: 42),
      title: Text(label, style: TextStyle(fontSize: 13, color: softText(context))),
      subtitle: Text(value,
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
      onTap: onTap,
    );
  }

  Widget _card(BuildContext context, List<Widget> children) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: cardBg(context),
        borderRadius: BorderRadius.circular(24),
        boxShadow: softShadow(context),
      ),
      child: Column(children: children),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('অ্যাপ সম্পর্কে')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [kNavy, cs.primary],
              ),
            ),
            child: const Column(
              children: [
                Icon(Icons.translate, color: Colors.white, size: 56),
                SizedBox(height: 10),
                Text('K-Learn Studio',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold)),
                SizedBox(height: 4),
                Text('বাংলা ভাষীদের জন্য কোরিয়ান শেখার অ্যাপ',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white70, fontSize: 14)),
                SizedBox(height: 10),
                Text('সংস্করণ 1.0.0',
                    style: TextStyle(color: Colors.white, fontSize: 13)),
              ],
            ),
          ),
          const SizedBox(height: 18),
          const Padding(
            padding: EdgeInsets.fromLTRB(4, 0, 4, 8),
            child: Text('ডেভেলপার',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
          _card(context, [
            _row(context, Icons.person, 'ডিজাইন ও ডেভেলপমেন্ট', devName),
            _row(context, Icons.location_on, 'ঠিকানা', devAddress),
            _row(context, Icons.email, 'ইমেইল', devEmail,
                onTap: () => _mail(context)),
          ]),
          const Padding(
            padding: EdgeInsets.fromLTRB(4, 0, 4, 8),
            child: Text('অ্যাপ সম্পর্কে',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
          _card(context, const [
            Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'অ্যাপের ধারণা, ডিজাইন ও বিষয়বস্তু নির্ধারণ করেছেন MD Alamin। শব্দভাণ্ডার, ফ্ল্যাশকার্ড, গ্রামার ও PDF বই এক জায়গায় রেখে কোরিয়ান ভাষা শেখা সহজ করাই এর লক্ষ্য।\n\nআপনার শব্দ, সংরক্ষিত তালিকা ও PDF বই শুধু আপনার ফোনেই থাকে।',
                style: TextStyle(fontSize: 15, height: 1.6),
              ),
            ),
          ]),
          const Padding(
            padding: EdgeInsets.fromLTRB(4, 0, 4, 8),
            child: Text('কৃতজ্ঞতা',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
          _card(context, const [
            Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'শব্দের ছবি: Pixabay\nPDF রিডার: pdfrx\nঅ্যাপ ফ্রেমওয়ার্ক: Flutter',
                style: TextStyle(fontSize: 15, height: 1.6),
              ),
            ),
          ]),
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text('© 2026 MD Alamin. সর্বস্বত্ব সংরক্ষিত।',
                  style: TextStyle(fontSize: 13, color: softText(context))),
            ),
          ),
        ],
      ),
    );
  }
}
