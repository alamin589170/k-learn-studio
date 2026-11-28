import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'about.dart';

// ব্যবহারকারী ভুল জানাবে: হোয়াটসঅ্যাপ বা ইমেইলে ডেভেলপারের কাছে যাবে
// ctx = কোথায় ভুল (যেমন "ফ্ল্যাশকার্ড #281: 안녕 — হ্যালো")
Future<void> showReportDialog(BuildContext context, String ctx) async {
  final ctl = TextEditingController();
  await showDialog(
    context: context,
    builder: (c) => AlertDialog(
      title: const Text('ভুল জানান'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(ctx, style: const TextStyle(fontSize: 13)),
            const SizedBox(height: 10),
            TextField(
              controller: ctl,
              minLines: 3,
              maxLines: 6,
              decoration: const InputDecoration(
                labelText: 'কী ভুল? সঠিক কী হবে?',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () async {
            final m = Uri.encodeComponent(
                'K-Learn Studio — ভুল রিপোর্ট\n$ctx\n\n${ctl.text}');
            Navigator.pop(c);
            try {
              await launchUrl(Uri.parse('https://wa.me/8801923589170?text=$m'),
                  mode: LaunchMode.externalApplication);
            } catch (_) {}
          },
          child: const Text('হোয়াটসঅ্যাপ'),
        ),
        TextButton(
          onPressed: () async {
            final m = Uri.encodeComponent(
                '$ctx\n\n${ctl.text}');
            Navigator.pop(c);
            try {
              await launchUrl(
                  Uri.parse(
                      'mailto:${AboutPage.devEmail}?subject=${Uri.encodeComponent('K-Learn Studio ভুল রিপোর্ট')}&body=$m'),
                  mode: LaunchMode.externalApplication);
            } catch (_) {}
          },
          child: const Text('ইমেইল'),
        ),
        TextButton(
            onPressed: () => Navigator.pop(c), child: const Text('বাতিল')),
      ],
    ),
  );
}
