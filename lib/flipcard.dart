import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'images.dart';
import 'style.dart';
import 'ui.dart';
import 'vocab.dart';
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
      vsync: this, duration: const Duration(milliseconds: 500));
  String? path;
  bool busy = true;
  bool useThumb = false;

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

  Future<Directory> _thumbDir() async {
    final base = await getApplicationDocumentsDirectory();
    final t = Directory('${base.path}/thumbs');
    if (!await t.exists()) await t.create(recursive: true);
    return t;
  }

  String _q() {
    var q = widget.word.en.split(RegExp(r'[,/;(]')).first.trim().toLowerCase();
    if (q.startsWith('to ')) q = q.substring(3);
    return q;
  }

  // বড় (৬৪০px) 2D/ভেক্টর ছবি; শুধু শব্দের অর্থের সঙ্গে ট্যাগ মিললে নেয়
  Future<File?> _fetchHq(Directory dir, int id) async {
    const key = String.fromEnvironment('PIXABAY_KEY');
    final q = _q();
    if (key.isEmpty || q.isEmpty) return null;
    final last = q.split(' ').last;
    for (final type in const ['vector', 'illustration']) {
      try {
        final r = await http
            .get(Uri.parse(
                'https://pixabay.com/api/?key=$key&q=${Uri.encodeQueryComponent(q)}&image_type=$type&per_page=20&safe_search=true&order=popular&min_width=500'))
            .timeout(const Duration(seconds: 12));
        if (r.statusCode != 200) continue;
        final hits = (jsonDecode(r.body) as Map)['hits'] as List;
        Map? pick;
        for (final h in hits) {
          final tags = ('${(h as Map)['tags']}').toLowerCase();
          final list = tags.split(',').map((e) => e.trim()).toList();
          if (list.contains(q) || list.contains(last)) {
            pick = h;
            break;
          }
        }
        if (pick == null) continue;
        final img = await http
            .get(Uri.parse('${pick['webformatURL']}'))
            .timeout(const Duration(seconds: 15));
        if (img.statusCode != 200) continue;
        final f = File('${dir.path}/${id}_hq.jpg');
        await f.writeAsBytes(img.bodyBytes);
        return f;
      } catch (_) {}
    }
    return null;
  }

  Future<void> loadImage() async {
    final id = widget.word.id!;
    try {
      final dir = await _thumbDir();
      final f = File('${dir.path}/${id}_hq.jpg');
      if (await f.exists()) {
        if (!mounted) return;
        setState(() {
          path = f.path;
          busy = false;
        });
        return;
      }
      final none = File('${dir.path}/${id}_hq.none');
      if (!await none.exists()) {
        final got = await _fetchHq(dir, id);
        if (got != null) {
          if (!mounted) return;
          setState(() {
            path = got.path;
            busy = false;
          });
          return;
        }
        await none.writeAsString('1');
      }
    } catch (_) {}
    // না পেলে: নিজের তোলা/বাছা ছবি, নইলে ছবি ছাড়া সুন্দর কার্ড
    String? p;
    try {
      p = await Images.get(id);
    } catch (_) {}
    if (!mounted) return;
    setState(() {
      path = p;
      busy = false;
    });
  }

  // নতুন ছবি বসালে শব্দভাণ্ডারের ছবিও একই হয়ে যায়
  Future<void> _syncThumb(int id, String? p) async {
    try {
      final dir = await _thumbDir();
      final f = File('${dir.path}/$id.jpg');
      final none = File('${dir.path}/$id.none');
      final hq = File('${dir.path}/${id}_hq.jpg');
      final hqNone = File('${dir.path}/${id}_hq.none');
      if (p == null) {
        if (await f.exists()) await f.delete();
        if (await hq.exists()) await hq.delete();
        await none.writeAsString('1');
        await hqNone.writeAsString('1');
      } else {
        await File(p).copy(f.path);
        await File(p).copy(hq.path);
        if (await none.exists()) await none.delete();
        if (await hqNone.exists()) await hqNone.delete();
      }
      imageCache.clear();
    } catch (_) {}
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
      await _syncThumb(id, null);
    } else if (p != null) {
      await _syncThumb(id, p);
      p = '${(await _thumbDir()).path}/${id}_hq.jpg';
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

  Widget imageArea() {
    Widget inner;
    if (path != null) {
      inner = Image.file(
        File(path!),
        width: 210,
        height: 210,
        fit: BoxFit.cover,
        errorBuilder: (ctx, e, s) => const Icon(Icons.broken_image,
            size: 60, color: Colors.white54),
      );
    } else if (useThumb) {
      inner = WordThumb(word: widget.word, size: 210);
    } else if (busy) {
      inner = const CircularProgressIndicator(color: Colors.white);
    } else {
      inner = const Icon(Icons.image_outlined, size: 90, color: Colors.white54);
    }
    return Center(
      child: Container(
        width: 214,
        height: 214,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          color: Colors.white.withOpacity(0.14),
          border: Border.all(color: Colors.white.withOpacity(0.5), width: 1.5),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.25),
                blurRadius: 16,
                offset: const Offset(0, 8)),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: inner,
        ),
      ),
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
      child: AnimatedBuilder(
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
      ),
    );
  }
}
