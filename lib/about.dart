import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dev_photo.dart';
import 'style.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  static const String devName = 'MD Alamin Shagor';
  static const String devAddress = 'Khulna, Bangladesh';
  static const String devEmail = 'Alamin589170@gmail.com';
  static const String devWhatsapp = '+8801923589170';
  static const String devFacebook =
      'https://www.facebook.com/share/1EGtVdRzKz/';

  static final Uint8List _photo = base64Decode(kDevPhotoB64);

  Future<void> _open(BuildContext context, Uri uri, String copyText) async {
    var ok = false;
    try {
      ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {}
    if (!ok) {
      await Clipboard.setData(ClipboardData(text: copyText));
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('কপি হয়েছে')));
      }
    }
  }

  Widget _row(BuildContext context, IconData icon, Color color, String label,
      String value,
      {VoidCallback? onTap}) {
    return ListTile(
      leading: IconCircle(icon: icon, color: color, size: 42),
      title:
          Text(label, style: TextStyle(fontSize: 13, color: softText(context))),
      subtitle: Text(value,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
      trailing: onTap == null ? null : const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }

  Widget _card(BuildContext context, List<Widget> children) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: cardDeco(context, 24),
      child: Column(children: children),
    );
  }

  Widget _head(String t) => Padding(
        padding: const EdgeInsets.fromLTRB(4, 4, 4, 8),
        child: Text(t,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('অ্যাপ সম্পর্কে')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(20, 28, 20, 24),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              gradient: headGradient(context),
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                      shape: BoxShape.circle, color: Colors.white),
                  child: ClipOval(
                    child: Image.memory(
                      _photo,
                      width: 130,
                      height: 130,
                      fit: BoxFit.cover,
                      alignment: Alignment.topCenter,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                const Text(devName,
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 2),
                const Text('অ্যাপের ডিজাইনার ও নির্মাতা',
                    style: TextStyle(color: Colors.white70, fontSize: 14)),
                const SizedBox(height: 14),
                const Text('K-Learn Studio',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w600)),
                const Text('সংস্করণ 1.0.0',
                    style: TextStyle(color: Colors.white70, fontSize: 13)),
              ],
            ),
          ),
          const SizedBox(height: 18),
          _head('যোগাযোগ'),
          _card(context, [
            _row(context, Icons.chat, const Color(0xFF25A244), 'WhatsApp',
                devWhatsapp,
                onTap: () => _open(
                    context,
                    Uri.parse('https://wa.me/8801923589170'),
                    devWhatsapp)),
            _row(context, Icons.facebook, const Color(0xFF1877F2), 'Facebook',
                'MD Alamin Shagor',
                onTap: () =>
                    _open(context, Uri.parse(devFacebook), devFacebook)),
            _row(context, Icons.email, const Color(0xFFD14836), 'ইমেইল',
                devEmail,
                onTap: () => _open(context,
                    Uri(scheme: 'mailto', path: devEmail), devEmail)),
            _row(context, Icons.location_on, const Color(0xFF6A55C8), 'ঠিকানা',
                devAddress),
          ]),
          _head('অ্যাপ সম্পর্কে'),
          _card(context, const [
            Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'অ্যাপের ধারণা, ডিজাইন ও বিষয়বস্তু নির্ধারণ করেছেন MD Alamin Shagor। শব্দভাণ্ডার, ফ্ল্যাশকার্ড, গ্রামার ও PDF বই এক জায়গায় রেখে কোরিয়ান ভাষা শেখা সহজ করাই এর লক্ষ্য।\n\nএই অ্যাপের বই, শব্দ ও সংশোধন সবার জন্য। কেউ ভুল খুঁজে পেলে বা নতুন PDF দিতে চাইলে ডেভেলপারকে জানাতে পারেন। যাচাই হলে নতুন বই ও সংশোধন সবার অ্যাপে নিজে থেকে চলে আসবে।',
                style: TextStyle(fontSize: 15, height: 1.6),
              ),
            ),
          ]),
          _head('কৃতজ্ঞতা'),
          _card(context, const [
            Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'শব্দের ছবি: Pixabay\nবই সংরক্ষণ: Google Drive\nPDF রিডার: pdfrx\nঅ্যাপ ফ্রেমওয়ার্ক: Flutter',
                style: TextStyle(fontSize: 15, height: 1.6),
              ),
            ),
          ]),
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text('© 2026 MD Alamin Shagor. সর্বস্বত্ব সংরক্ষিত।',
                  style: TextStyle(fontSize: 13, color: softText(context))),
            ),
          ),
        ],
      ),
    );
  }
}
