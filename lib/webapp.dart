import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

// অ্যাপের ভেতরেই ওয়েব-অ্যাপ চালানোর পাতা (ইনস্টল লাগে না)
class WebAppPage extends StatefulWidget {
  final String title;
  final String url;
  const WebAppPage({super.key, required this.title, required this.url});
  @override
  State<WebAppPage> createState() => _WebAppPageState();
}

class _WebAppPageState extends State<WebAppPage> {
  late final WebViewController c;
  int progress = 0;

  @override
  void initState() {
    super.initState();
    c = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(NavigationDelegate(onProgress: (p) {
        if (mounted) setState(() => progress = p);
      }))
      ..loadRequest(Uri.parse(widget.url));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title, maxLines: 1, overflow: TextOverflow.ellipsis),
        actions: [
          IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () async {
              if (await c.canGoBack()) c.goBack();
            },
          ),
          IconButton(icon: const Icon(Icons.refresh), onPressed: () => c.reload()),
          IconButton(
            icon: const Icon(Icons.open_in_browser),
            onPressed: () async {
              try {
                await launchUrl(Uri.parse(widget.url),
                    mode: LaunchMode.externalApplication);
              } catch (_) {}
            },
          ),
        ],
      ),
      body: Column(
        children: [
          if (progress < 100) LinearProgressIndicator(value: progress / 100),
          Expanded(child: WebViewWidget(controller: c)),
        ],
      ),
    );
  }
}
