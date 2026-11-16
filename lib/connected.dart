import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

const List<List<String>> connectedApps = [
  ['Papago অনুবাদ', 'Naver-এর অনুবাদ, কোরিয়ান ভালো বোঝে', 'https://papago.naver.com'],
  ['Naver অভিধান', 'কোরিয়ান শব্দের অর্থ ও উদাহরণ', 'https://dict.naver.com'],
  ['Google Translate', 'বাংলা-কোরিয়ান অনুবাদ', 'https://translate.google.com'],
  ['TOPIK অফিসিয়াল', 'TOPIK পরীক্ষার তথ্য', 'https://www.topik.go.kr'],
  ['YouTube', 'কোরিয়ান শেখার ভিডিও খুঁজুন', 'https://www.youtube.com/results?search_query=learn+korean'],
];

class ConnectedPage extends StatelessWidget {
  const ConnectedPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('কানেক্টেড অ্যাপস')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(12),
          children: [
            const Padding(
              padding: EdgeInsets.all(8),
              child: Text('চাপলে ব্রাউজারে খুলবে। এগুলো বাইরের সাইট, ঠিকানা বদলাতে পারে।'),
            ),
            for (final a in connectedApps)
              Card(
                child: ListTile(
                  leading: const Icon(Icons.open_in_new),
                  title: Text(a[0]),
                  subtitle: Text(a[1]),
                  onTap: () async {
                    try {
                      await launchUrl(Uri.parse(a[2]),
                          mode: LaunchMode.externalApplication);
                    } catch (_) {}
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
