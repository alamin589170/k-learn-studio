import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'vocab.dart';

class ImageManagerPage extends StatefulWidget {
  const ImageManagerPage({super.key});
  @override
  State<ImageManagerPage> createState() => _ImageManagerPageState();
}

class _ImageManagerPageState extends State<ImageManagerPage> {
  static const _sql =
      'CREATE TABLE IF NOT EXISTS my_gallery(id INTEGER PRIMARY KEY AUTOINCREMENT, path TEXT NOT NULL, note TEXT, ts INTEGER NOT NULL)';
  List<Map<String, Object?>> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _toast(String m) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));
  }

  Future<void> _load() async {
    try {
      final db = await Db.get();
      await db.execute(_sql);
      final rows = await db.query('my_gallery', orderBy: 'id DESC');
      if (!mounted) return;
      setState(() {
        _items = rows;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  Future<void> _add(ImageSource s) async {
    try {
      final x = await ImagePicker()
          .pickImage(source: s, maxWidth: 1600, imageQuality: 85);
      if (x == null) return;
      final dir = await getApplicationDocumentsDirectory();
      final folder = Directory(p.join(dir.path, 'gallery'));
      await folder.create(recursive: true);
      final dest = p.join(folder.path,
          '${DateTime.now().millisecondsSinceEpoch}${p.extension(x.path)}');
      await File(x.path).copy(dest);
      final db = await Db.get();
      await db.execute(_sql);
      await db.insert('my_gallery', {
        'path': dest,
        'note': '',
        'ts': DateTime.now().millisecondsSinceEpoch,
      });
      await _load();
    } catch (_) {
      _toast('ছবি যোগ করা যায়নি');
    }
  }

  Future<void> _delete(Map<String, Object?> r) async {
    try {
      final f = File(r['path'] as String);
      if (await f.exists()) await f.delete();
      final db = await Db.get();
      await db.delete('my_gallery', where: 'id = ?', whereArgs: [r['id']]);
      await _load();
    } catch (_) {
      _toast('মোছা যায়নি');
    }
  }

  void _view(Map<String, Object?> r) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        content: Image.file(File(r['path'] as String),
            errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, size: 64)),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _delete(r);
            },
            child: const Text('মুছুন', style: TextStyle(color: Colors.red)),
          ),
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('বন্ধ')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ছবি ম্যানেজার')),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _items.isEmpty
                ? const Center(child: Text('এখনো কোনো ছবি নেই'))
                : GridView.builder(
                    padding: const EdgeInsets.all(8),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3, mainAxisSpacing: 6, crossAxisSpacing: 6),
                    itemCount: _items.length,
                    itemBuilder: (c, i) {
                      final r = _items[i];
                      return InkWell(
                        onTap: () => _view(r),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.file(File(r['path'] as String),
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) =>
                                  const Icon(Icons.broken_image)),
                        ),
                      );
                    },
                  ),
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton.small(
            heroTag: 'gal',
            onPressed: () => _add(ImageSource.gallery),
            child: const Icon(Icons.photo_library),
          ),
          const SizedBox(height: 10),
          FloatingActionButton(
            heroTag: 'cam',
            onPressed: () => _add(ImageSource.camera),
            child: const Icon(Icons.camera_alt),
          ),
        ],
      ),
    );
  }
}
