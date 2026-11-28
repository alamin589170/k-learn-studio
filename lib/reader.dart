import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:pdfrx/pdfrx.dart' as pdf;
import 'resume.dart';
import 'style.dart';

class PickedPdf {
  final String name;
  final String path;
  PickedPdf(this.name, this.path);
}

// ফোন থেকে PDF বেছে অ্যাপের ভেতরে কপি করে রাখে
Future<PickedPdf?> pickAndCopyPdf() async {
  final files = await FilePicker.pickFiles(
    type: FileType.custom,
    allowedExtensions: ['pdf'],
  );
  if (files.isEmpty) return null;
  final dir = await getApplicationDocumentsDirectory();
  final folder = Directory(p.join(dir.path, 'pdfs'));
  await folder.create(recursive: true);
  for (final f in files) {
    final dest = p.join(
        folder.path, '${DateTime.now().microsecondsSinceEpoch}.pdf');
    final sink = File(dest).openWrite();
    await sink.addStream(f.readAsByteStream());
    await sink.close();
    return PickedPdf(f.name, dest);
  }
  return null;
}

class PdfReaderPage extends StatefulWidget {
  final String title;
  final String? path;
  final String? url;
  final int startPage;
  const PdfReaderPage(
      {super.key,
      required this.title,
      this.path,
      this.url,
      this.startPage = 1});
  @override
  State<PdfReaderPage> createState() => _PdfReaderPageState();
}

class _PdfReaderPageState extends State<PdfReaderPage> {
  final pdf.PdfViewerController ctrl = pdf.PdfViewerController();
  int lastSaved = 0;
  String get _key => 'pdf_${(widget.path ?? widget.url ?? widget.title).hashCode}';

  void _track() {
    try {
      final n = ctrl.pageNumber;
      if (n != null && n != lastSaved && n > 0) {
        lastSaved = n;
        Resume.setInt(_key, n);
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    ctrl.removeListener(_track);
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    ctrl.addListener(_track);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        duration: Duration(seconds: 5),
        content: Text(
            'লেখার ওপর চেপে ধরে সিলেক্ট করুন, তারপর Copy চাপুন। (ছবি-স্ক্যান করা PDF-এর লেখা সিলেক্ট হয় না)'),
      ));
    });
  }

  Future<void> jump() async {
    final c = TextEditingController();
    final n = await showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('কত নম্বর পৃষ্ঠায় যাবেন?'),
        content: TextField(
          controller: c,
          autofocus: true,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('বাতিল')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, parseNum(c.text)),
              child: const Text('যান')),
        ],
      ),
    );
    if (n == null || n < 1) return;
    try {
      await ctrl.goToPage(pageNumber: n);
    } catch (_) {}
  }

  Widget viewer() {
    final params = pdf.PdfViewerParams(
      onViewerReady: (doc, c) async {
        if (widget.startPage > 1) {
          c.goToPage(pageNumber: widget.startPage);
          return;
        }
        final last = await Resume.getInt(_key);
        if (last != null && last > 1) {
          lastSaved = last;
          c.goToPage(pageNumber: last);
        }
      },
    );
    final path = widget.path;
    if (path != null && path.isNotEmpty) {
      return pdf.PdfViewer.file(path, controller: ctrl, params: params);
    }
    return pdf.PdfViewer.uri(Uri.parse(widget.url ?? ''),
        controller: ctrl, params: params);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:
            Text(widget.title, maxLines: 1, overflow: TextOverflow.ellipsis),
        actions: [
          IconButton(
            icon: const Icon(Icons.tag),
            tooltip: 'পৃষ্ঠায় যান',
            onPressed: jump,
          ),
        ],
      ),
      body: SafeArea(child: viewer()),
    );
  }
}
