import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'images.dart';
import 'vocab.dart';

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
    final id = widget.word.id!;
    var p = await Images.get(id);
    p ??= await Images.auto(id, Images.query(widget.word.en));
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
              leading: const Icon(Icons.delete_outline),
              title: const Text('ছবি সরান'),
              onTap: () => Navigator.pop(ctx, 'del'),
            ),
          ],
        ),
      ),
    );
    if (act == null) return;
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
      borderRadius: BorderRadius.circular(28),
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [a, b],
      ),
      boxShadow: const [
        BoxShadow(color: Colors.black26, blurRadius: 16, offset: Offset(0, 8)),
      ],
    );
  }

  Widget imageArea() {
    if (path != null) {
      return SizedBox.expand(
        child: Image.file(
          File(path!),
          fit: BoxFit.cover,
          errorBuilder: (ctx, e, s) => const Center(
            child: Icon(Icons.broken_image, size: 60, color: Colors.white54),
          ),
        ),
      );
    }
    if (busy) {
      return const Center(child: CircularProgressIndicator(color: Colors.white));
    }
    return const Center(
      child: Icon(Icons.image_outlined, size: 90, color: Colors.white54),
    );
  }

  Widget frontFace() {
    final w = widget.word;
    final title = Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            w.ko,
            textAlign: TextAlign.center,
            style: const TextStyle(
                color: Colors.white, fontSize: 44, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          const Text(
            'উল্টাতে চাপুন',
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
        ],
      ),
    );
    final photoButton = Positioned(
      top: 8,
      right: 8,
      child: IconButton.filled(
        icon: const Icon(Icons.add_photo_alternate),
        onPressed: changeImage,
      ),
    );
    return Container(
      width: double.infinity,
      height: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: deco(const Color(0xFF6C5CE7), const Color(0xFFA29BFE)),
      child: Stack(
        children: [
          Column(
            children: [
              Expanded(child: imageArea()),
              title,
            ],
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
      decoration: deco(const Color(0xFF00B894), const Color(0xFF55EFC4)),
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
