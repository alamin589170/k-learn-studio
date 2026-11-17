import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:pdfrx/pdfrx.dart' as pdf;
import 'smart_reading.dart';
import 'vocab.dart' show Db;

class PdfLibraryPage extends StatefulWidget {
  const PdfLibraryPage({super.key});
  @override
  State<PdfLibraryPage> createState() => _PdfLibraryPageState();
}

class _PdfLibraryPageState extends State<PdfLibraryPage> {
  static const _sql =
      'CREATE TABLE IF NOT EXISTS pdf_library(id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL, path TEXT NOT NULL, ts INTEGER NOT NULL)';
  static bool _inited = false;
  List<Map<String, Object?>> _items = [];
  bool _loading = true;
  bool _busy = false;

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
      final rows = await db.query('pdf_library', orderBy: 'id DESC');
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

  Future<void> _add() async {
    if (_busy) return;
    try {
      final files = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );
      if (files.isEmpty) return;
      setState(() => _busy = true);
      final dir = await getApplicationDocumentsDirectory();
      final folder = Directory(p.join(dir.path, 'pdfs'));
      await folder.create(recursive: true);
      final db = await Db.get();
      await db.execute(_sql);
      for (final f in files) {
        final dest = p.join(
            folder.path, '${DateTime.now().microsecondsSinceEpoch}.pdf');
        final sink = File(dest).openWrite();
        await sink.addStream(f.readAsByteStream());
        await sink.close();
        await db.insert('pdf_library', {
          'name': f.name,
          'path': dest,
          'ts': DateTime.now().millisecondsSinceEpoch,
        });
      }
      await _load();
    } catch (_) {
      _toast('PDF যোগ করা যায়নি');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _delete(Map<String, Object?> r) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('মুছবেন?'),
        content: Text('${r['name']}'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('না')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('মুছুন', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (ok != true) return;
    try {
      final f = File(r['path'] as String);
      if (await f.exists()) await f.delete();
      final db = await Db.get();
      await db.delete('pdf_library', where: 'id = ?', whereArgs: [r['id']]);
      await _load();
    } catch (_) {
      _toast('মোছা যায়নি');
    }
  }

  Future<void> _readText(Map<String, Object?> r) async {
    if (_busy) return;
    setState(() => _busy = true);
    _toast('লেখা পড়া হচ্ছে...');
    var text = '';
    try {
      if (!_inited) {
        pdf.pdfrxFlutterInitialize();
        _inited = true;
      }
      final doc = await pdf.PdfDocument.openFile(r['path'] as String);
      try {
        final buf = StringBuffer();
        final n = doc.pages.length < 30 ? doc.pages.length : 30;
        for (var i = 0; i < n; i++) {
          final t = await doc.pages[i].loadText();
          final s = t?.fullText ?? '';
          if (s.trim().isNotEmpty) buf.writeln(s.trim());
          if (buf.length > 20000) break;
        }
        text = buf.toString();
      } finally {
        await doc.dispose();
      }
    } catch (_) {
      text = '';
    }
    if (!mounted) return;
    setState(() => _busy = false);
    if (text.trim().isEmpty) {
      _toast('এই PDF থেকে লেখা পাওয়া যায়নি (স্ক্যান করা ছবি হতে পারে)');
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => SmartReadingPage(initialText: text)),
    );
  }

  String _date(Object? ts) {
    final d = DateTime.fromMillisecondsSinceEpoch((ts as int?) ?? 0);
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('PDF লাইব্রেরি')),
      body: SafeArea(
        child: Column(
          children: [
            if (_busy) const LinearProgressIndicator(),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _items.isEmpty
                      ? const Center(
                          child: Padding(
                            padding: EdgeInsets.all(24),
                            child: Text(
                                'এখনো কোনো PDF নেই। নিচের + চেপে আপনার PDF যোগ করুন।',
                                textAlign: TextAlign.center),
                          ),
                        )
                      : ListView.builder(
                          itemCount: _items.length,
                          itemBuilder: (c, i) {
                            final r = _items[i];
                            return ListTile(
                              leading: const Icon(Icons.picture_as_pdf,
                                  color: Colors.red, size: 32),
                              title: Text('${r['name']}',
                                  maxLines: 2, overflow: TextOverflow.ellipsis),
                              subtitle: Text(_date(r['ts'])),
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => PdfViewPage(
                                      name: '${r['name']}',
                                      path: r['path'] as String),
                                ),
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    tooltip: 'লেখা বের করে স্মার্ট রিডিং',
                                    icon: const Icon(Icons.auto_stories),
                                    onPressed: () => _readText(r),
                                  ),
                                  IconButton(
                                    tooltip: 'মুছুন',
                                    icon: const Icon(Icons.delete_outline),
                                    onPressed: () => _delete(r),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _busy ? null : _add,
        child: const Icon(Icons.add),
      ),
    );
  }
}

class PdfViewPage extends StatelessWidget {
  final String name;
  final String path;
  const PdfViewPage({super.key, required this.name, required this.path});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(name, maxLines: 1, overflow: TextOverflow.ellipsis)),
      body: SafeArea(child: pdf.PdfViewer.file(path)),
    );
  }
}
