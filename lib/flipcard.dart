import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'images.dart';
import 'style.dart';
import 'vocab.dart';
import 'wordimg.dart';
import 'package:url_launcher/url_launcher.dart';
class FlipCard extends StatefulWidget {
  final Word word;
  const FlipCard({super.key, required this.word});
  @override
  State<FlipCard> createState() => _FlipCardState();
}

class _FlipCardState extends State<FlipCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController c = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 320));
  String? path;
  bool busy = true;

  @override
  void initState() {
    super.initState();
    loadImage();
  }

  @override
  void dispose() {
    c.dispose();
    super.dispose();
  }

  Future<void> loadImage() async {
    final w = widget.word;
    File? f;
    try {
      f = await WordImg.fetch(w, alive: () => mounted);
    } catch (_) {}
    String? p = f?.path;
    if (p == null) {
      try {
        p = await Images.get(w.id!);
      } catch (_) {}
    }
    if (!mounted) return;
    setState(() {
      path = p;
      busy = false;
    });
  }

  Future<void> changeImage() async {
    final id = widget.word.id!;
    final act = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.travel_explore),
              title: const Text('ইন্টারনেট থেকে অন্য ছবি'),
              onTap: () => Navigator.pop(ctx, 'net'),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('গ্যালারি থেকে'),
              onTap: () => Navigator.pop(ctx, 'gal'),
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera),
              title: const Text('ক্যামেরা দিয়ে তুলুন'),
              onTap: () => Navigator.pop(ctx, 'cam'),
            ),
            ListTile(
                  leading: const Icon(Icons.search),
                  title: const Text('Google-এ ছবি খুঁজুন'),
                  onTap: () => Navigator.pop(ctx, 'google'),
                ),
                ListTile(
                  leading: const Icon(Icons.push_pin),
                  title: const Text('Pinterest-এ ছবি খুঁজুন'),
                  onTap: () => Navigator.pop(ctx, 'pinterest'),
                ),
            ListTile(
              leading: const Icon(Icons.delete_outline),
              title: const Text('ছবি সরান'),
              onTap: () => Navigator.pop(ctx, 'del'),
            ),
          ],
        ),
      ),
    );
    if (act == null) return;    
    if (act == 'google' || act == 'pinterest') {
      final q = Uri.encodeQueryComponent(
          widget.word.en.isNotEmpty ? widget.word.en : widget.word.ko);
      final url = act == 'google'
          ? 'https://www.google.com/search?tbm=isch&q=$q'
          : 'https://www.pinterest.com/search/pins/?q=$q';
      try {
        await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
      } catch (_) {}
      return;
    }
    setState(() => busy = true);
    String? p;
    if (act == 'net') {
      p = await Images.nextOnline(id, Images.query(widget.word.en));
    } else if (act == 'gal') {
      p = await Images.pick(id, ImageSource.gallery);
    } else if (act == 'cam') {
      p = await Images.pick(id, ImageSource.camera);
    } else if (act == 'del') {
      await Images.remove(id);
    }
    if (act == 'del') {
      await WordImg.clear(id);
    } else if (p != null) {
      await WordImg.setFromFile(id, p);
      p = (await WordImg.fileOf(id)).path;
    }
    if (!mounted) return;
    setState(() {
      busy = false;
      if (act == 'del') {
        path = null;
      } else if (p != null) {
        path = p;
      }
    });
    if (act == 'net' && p == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('ইন্টারনেট থেকে ছবি পাওয়া যায়নি')));
    }
  }

  void flip() {
    if (c.status == AnimationStatus.completed ||
        c.status == AnimationStatus.forward) {
      c.reverse();
    } else {
      c.forward();
    }
  }

  BoxDecoration deco(Color a, Color b) {
    return BoxDecoration(
      borderRadius: BorderRadius.circular(32),
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [a, b],
      ),
      border: Border.all(color: Colors.white.withOpacity(0.35), width: 1.2),
      boxShadow: [
        BoxShadow(
            color: a.withOpacity(0.45),
            blurRadius: 22,
            offset: const Offset(0, 10)),
      ],
    );
  }

  Widget frontFace() {
    final w = widget.word;
    final photoButton = Positioned(
      top: 8,
      right: 8,
      child: IconButton.filled(
        icon: const Icon(Icons.add_photo_alternate),
        onPressed: changeImage,
      ),
    );
    final hasImg = path != null;
    return Container(
      width: double.infinity,
      height: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: deco(head1(context), head2(context)),
      child: Stack(
        children: [
          if (hasImg)
            Positioned.fill(
              child: Container(
                color: Colors.white,
                child: Image.file(
                  File(path!),
                  fit: BoxFit.cover,
                  filterQuality: FilterQuality.high,
                  errorBuilder: (ctx, e, s) => const SizedBox(),
                ),
              ),
            )
          else if (busy)
            const Center(
                child: CircularProgressIndicator(color: Colors.white)),
          if (!hasImg && !busy)
            Center(
              child: Text(w.ko.isEmpty ? '?' : w.ko.characters.first,
                  style: TextStyle(
                      fontSize: 200,
                      fontWeight: FontWeight.bold,
                      color: Colors.white.withOpacity(0.14))),
            ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 30, 16, 16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.78),
                  ],
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    w.ko,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 44,
                        fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 2),
                  const Text('উল্টাতে চাপুন',
                      style: TextStyle(color: Colors.white70, fontSize: 14)),
                ],
              ),
            ),
          ),
          photoButton,
        ],
      ),
    );
  }

  Widget backFace() {
    final w = widget.word;
    final items = <Widget>[];
    if (w.pron.isNotEmpty) {
      items.add(Text(
        w.pron,
        textAlign: TextAlign.center,
        style: const TextStyle(
            color: Colors.white70, fontSize: 20, fontStyle: FontStyle.italic),
      ));
    }
    items.add(const SizedBox(height: 12));
    items.add(Text(
      w.bn,
      textAlign: TextAlign.center,
      style: const TextStyle(
          color: Colors.white, fontSize: 34, fontWeight: FontWeight.bold),
    ));
    if (w.en.isNotEmpty) {
      items.add(const SizedBox(height: 12));
      items.add(Text(
        w.en,
        textAlign: TextAlign.center,
        style: const TextStyle(color: Colors.white, fontSize: 20),
      ));
    }
    if (w.ex.isNotEmpty) {
      items.add(const SizedBox(height: 24));
      items.add(Text(
        w.ex,
        textAlign: TextAlign.center,
        style: const TextStyle(color: Colors.white70, fontSize: 18),
      ));
    }
    return Container(
      width: double.infinity,
      height: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: deco(head2(context),
          Color.lerp(head2(context), Theme.of(context).colorScheme.primary, 0.6)!),
      child: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: items,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: flip,
      child: RepaintBoundary(child: AnimatedBuilder(
        animation: c,
        builder: (context, _) {
          final t = Curves.easeInOut.transform(c.value);
          final angle = t * math.pi;
          final Widget face;
          if (angle > math.pi / 2) {
            face = Transform(
              alignment: Alignment.center,
              transform: Matrix4.rotationY(math.pi),
              child: backFace(),
            );
          } else {
            face = frontFace();
          }
          return Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.001)
              ..rotateY(angle),
            child: face,
          );
        },
      )),
    );
  }
}
