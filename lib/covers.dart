import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

// PDF বইয়ের কভার: ডেভেলপারের দেওয়া ছবি (ফোনে জমা থাকে), না থাকলে সুন্দর নিজস্ব নকশা
class BookCoverImage extends StatefulWidget {
  final String thumb;
  final List<Color> colors;
  const BookCoverImage({super.key, required this.thumb, required this.colors});
  @override
  State<BookCoverImage> createState() => _BookCoverImageState();
}

class _BookCoverImageState extends State<BookCoverImage> {
  File? file;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(BookCoverImage old) {
    super.didUpdateWidget(old);
    if (old.thumb != widget.thumb) {
      file = null;
      _load();
    }
  }

  Future<void> _load() async {
    final t = widget.thumb.trim();
    if (!t.startsWith('http')) return;
    try {
      final base = await getApplicationDocumentsDirectory();
      final d = Directory('${base.path}/covers');
      if (!await d.exists()) await d.create(recursive: true);
      final f = File('${d.path}/${t.hashCode.toUnsigned(32)}.img');
      if (await f.exists()) {
        if (mounted && widget.thumb == t) setState(() => file = f);
        return;
      }
      final r = await http.get(Uri.parse(t)).timeout(const Duration(seconds: 20));
      if (r.statusCode != 200 || r.bodyBytes.length < 1500) return;
      await f.writeAsBytes(r.bodyBytes);
      if (mounted && widget.thumb == t) setState(() => file = f);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final f = file;
    if (f != null) {
      return SizedBox.expand(
        child: Image.file(
          f,
          fit: BoxFit.cover,
          alignment: Alignment.topCenter,
          cacheWidth: 600,
          filterQuality: FilterQuality.medium,
          errorBuilder: (c, e, s) => _generated(),
        ),
      );
    }
    return _generated();
  }

  Widget _generated() {
    final c = widget.colors;
    return SizedBox.expand(
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: c,
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              right: -30,
              top: -30,
              child: Container(
                width: 130,
                height: 130,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.10),
                ),
              ),
            ),
            Positioned(
              left: -20,
              bottom: 30,
              child: Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.08),
                ),
              ),
            ),
            Align(
              alignment: const Alignment(0, -0.25),
              child: Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: Colors.white.withOpacity(0.18),
                  border: Border.all(color: Colors.white.withOpacity(0.45)),
                ),
                child: const Icon(Icons.menu_book_rounded,
                    color: Colors.white, size: 36),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
