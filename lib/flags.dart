import 'dart:math' as math;
import 'package:flutter/material.dart';

// কোরিয়া | বাংলাদেশ: দুই পতাকা একসঙ্গে (স্থির ছবি, এনিমেশন নেই)
class FlagSplitPainter extends CustomPainter {
  const FlagSplitPainter();

  static double _edge(double y, double w) =>
      w * 0.60 + 9 * math.sin(y * 0.055) + 6 * math.sin(y * 0.17 + 1.3);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    const red = Color(0xFFCD2E3A);
    const blue = Color(0xFF0047A0);

    // কোরিয়া (সাদা জমি)
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h),
        Paint()..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFFFFF), Color(0xFFE9EDF2)],
        ).createShader(Rect.fromLTWH(0, 0, w, h)));

    // বাংলাদেশ (সবুজ জমি, ভাঙা ধারসহ)
    final g = Path()..moveTo(_edge(0, w), 0);
    for (double y = 0; y <= h; y += 6) {
      g.lineTo(_edge(y, w), y);
    }
    g.lineTo(w, h);
    g.lineTo(w, 0);
    g.close();
    canvas.drawPath(
        g,
        Paint()
          ..shader = const LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: [Color(0xFF00855F), Color(0xFF00573F)],
          ).createShader(Rect.fromLTWH(0, 0, w, h)));
    // ধারের ছায়া
    final edge = Path()..moveTo(_edge(0, w), 0);
    for (double y = 0; y <= h; y += 6) {
      edge.lineTo(_edge(y, w), y);
    }
    canvas.drawPath(
        edge,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = Colors.black.withOpacity(0.22));

    // কোরিয়ার তাইগুক
    final cx = w * 0.29, cy = 118.0;
    final r = w * 0.135;
    canvas.save();
    canvas.translate(cx, cy);
    canvas.rotate(-0.588);
    canvas.save();
    canvas.clipPath(Path()..addOval(Rect.fromCircle(center: Offset.zero, radius: r)));
    canvas.drawRect(Rect.fromLTRB(-r, -r, r, 0), Paint()..color = red);
    canvas.drawRect(Rect.fromLTRB(-r, 0, r, r), Paint()..color = blue);
    canvas.drawCircle(Offset(-r / 2, 0), r / 2, Paint()..color = blue);
    canvas.drawCircle(Offset(r / 2, 0), r / 2, Paint()..color = red);
    canvas.restore();
    canvas.restore();

    // চার কোণের ট্রাইগ্রাম
    final black = Paint()..color = const Color(0xFF111111);
    final len = r * 1.35, th = r * 0.2, gap = r * 0.12, d = r * 2.05;
    void tri(double sx, double sy, List<bool> solid) {
      final u = Offset(sx, sy) / math.sqrt2;
      canvas.save();
      canvas.translate(cx + u.dx * d, cy + u.dy * d);
      canvas.rotate(math.atan2(u.dy, u.dx));
      for (var i = 0; i < 3; i++) {
        final x = (i - 1) * (th + gap);
        if (solid[i]) {
          canvas.drawRect(
              Rect.fromLTRB(x - th / 2, -len / 2, x + th / 2, len / 2), black);
        } else {
          final k = len * 0.1;
          canvas.drawRect(
              Rect.fromLTRB(x - th / 2, -len / 2, x + th / 2, -k), black);
          canvas.drawRect(
              Rect.fromLTRB(x - th / 2, k, x + th / 2, len / 2), black);
        }
      }
      canvas.restore();
    }

    tri(-1, -1, [true, true, true]);
    tri(1, -1, [false, true, false]);
    tri(-1, 1, [true, false, true]);
    tri(1, 1, [false, false, false]);

    // বাংলাদেশের লাল বৃত্ত
    canvas.drawCircle(Offset(w * 0.80, cy), w * 0.15,
        Paint()..color = const Color(0xFFF42A41));

    // কাচের হালকা আলো
    canvas.drawRect(
        Rect.fromLTWH(0, 0, w, h * 0.5),
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.white.withOpacity(0.28), Colors.white.withOpacity(0)],
          ).createShader(Rect.fromLTWH(0, 0, w, h * 0.5)));
  }

  @override
  bool shouldRepaint(FlagSplitPainter old) => false;
}

// হোমের ক্রিস্টাল প্লেট: উপরে দুই পতাকা, নিচে K-Learn Studio লেখা
class FlagHeader extends StatelessWidget {
  final Widget menu;
  final Widget body;
  const FlagHeader({super.key, required this.menu, required this.body});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(34),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(34),
          border: Border.all(color: Colors.white.withOpacity(0.7), width: 1.2),
        ),
        child: Stack(
          children: [
            const Positioned.fill(
              child: RepaintBoundary(
                child: CustomPaint(painter: FlagSplitPainter()),
              ),
            ),
            Column(
              children: [
                SizedBox(
                  height: 236,
                  child: Align(alignment: Alignment.topLeft, child: menu),
                ),
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.fromLTRB(10, 0, 10, 10),
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(26),
                    border: Border.all(color: Colors.white.withOpacity(0.35)),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.black.withOpacity(0.62),
                        Colors.black.withOpacity(0.48),
                      ],
                    ),
                  ),
                  child: body,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
