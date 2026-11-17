import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';
import 'smart_reading.dart';

class OcrPage extends StatefulWidget {
  const OcrPage({super.key});
  @override
  State<OcrPage> createState() => _OcrPageState();
}

class _OcrPageState extends State<OcrPage> {
  String _text = '';
  String _msg = 'ছবি তুলুন বা গ্যালারি থেকে বাছুন';
  bool _busy = false;

  Future<void> _scan(ImageSource s) async {
    try {
      final x = await ImagePicker()
          .pickImage(source: s, maxWidth: 2200, imageQuality: 92);
      if (x == null) return;
      setState(() {
        _busy = true;
        _text = '';
        _msg = 'পড়া হচ্ছে...';
      });
      final rec = TextRecognizer(script: TextRecognitionScript.korean);
      try {
        final r = await rec.processImage(InputImage.fromFilePath(x.path));
        if (!mounted) return;
        setState(() {
          _text = r.text.trim();
          _msg = _text.isEmpty
              ? 'কোনো কোরিয়ান লেখা পাওয়া যায়নি। স্পষ্ট ছাপা লেখার ছবি নিন।'
              : 'পাওয়া লেখা (ভুল থাকলে স্মার্ট রিডিংয়ে ঠিক করুন):';
        });
      } finally {
        await rec.close();
      }
    } catch (_) {
      if (mounted) setState(() => _msg = 'পড়তে সমস্যা হয়েছে');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ক্যামেরা OCR')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Row(children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _busy ? null : () => _scan(ImageSource.camera),
                  icon: const Icon(Icons.camera_alt),
                  label: const Text('ক্যামেরা'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _busy ? null : () => _scan(ImageSource.gallery),
                  icon: const Icon(Icons.photo_library),
                  label: const Text('গ্যালারি'),
                ),
              ),
            ]),
            const SizedBox(height: 16),
            if (_busy) const LinearProgressIndicator(),
            Text(_msg),
            const SizedBox(height: 8),
            if (_text.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(8)),
                child: SelectableText(_text,
                    style: const TextStyle(fontSize: 20)),
              ),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) =>
                                SmartReadingPage(initialText: _text))),
                    child: const Text('স্মার্ট রিডিংয়ে খুলুন'),
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton(
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: _text));
                    ScaffoldMessenger.of(context)
                        .showSnackBar(const SnackBar(content: Text('কপি হয়েছে')));
                  },
                  child: const Text('কপি'),
                ),
              ]),
            ],
          ],
        ),
      ),
    );
  }
}
