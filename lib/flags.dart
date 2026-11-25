import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'style.dart';

enum FlagKind { korea, bangladesh }

class FlagPainter extends CustomPainter {
  final FlagKind kind;
  final double t;
  final double offset;
  FlagPainter(this.kind, this.t, this.offset);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final amp = h * 0.035;
    final phase = (t + offset) * 2 * math.pi;
    const n = 28;
    double wave(double x) => math.sin(x / w * 2 * math.pi * 1.1 - phase);

    final path = Path()..moveTo(0, amp + amp * wave(0));
    for (var i = 1; i <= n; i++) {
      final x = w * i / n;
      path.lineTo(x, amp + amp * wave(x));
    }
    for (var i = n; i >= 0; i--) {
      final x = w * i / n;
      path.lineTo(x, h - amp + amp * wave(x));
    }
    path.close();

    canvas.save();
    canvas.clipPath(path);
    if (kind == FlagKind.korea) {
      _korea(canvas, w, h);
    } else {
      _bangladesh(canvas, w, h);
    }
    // কাপড়ের ভাঁজের আলো-ছায়া
    const seg = n;
    for (var i = 0; i < seg; i++) {
      final x0 = w * i / seg;
      final cx = x0 + w / seg / 2;
      final d = math.cos(cx / w * 2 * math.pi * 1.1 - phase);
      final col = d > 0 ? Colors.white : Colors.black;
      canvas.drawRect(
        Rect.fromLTWH(x0, 0, w / seg + 0.6, h),
        Paint()..color = col.withOpacity(0.13 * d.abs()),
      );
    }
    canvas.restore();
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = Colors.white.withOpacity(0.5),
    );
  }

  void _korea(Canvas canvas, double w, double h) {
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), Paint()..color = Colors.white);
    final c = Offset(w / 2, h / 2);
    final r = h * 0.25;
    const red = Color(0xFFCD2E3A);
    const blue = Color(0xFF0047A0);

    // তাইগুক
    canvas.save();
    canvas.translate(c.dx, c.dy);
    canvas.rotate(-0.9828);
    final circle = Path()..addOval(Rect.fromCircle(center: Offset.zero, radius: r));
    canvas.clipPath(circle);
    canvas.drawRect(Rect.fromLTRB(-r, -r, r, 0), Paint()..color = red);
    canvas.drawRect(Rect.fromLTRB(-r, 0, r, r), Paint()..color = blue);
    canvas.drawCircle(Offset(-r / 2, 0), r / 2, Paint()..color = red);
    canvas.drawCircle(Offset(r / 2, 0), r / 2, Paint()..color = blue);
    canvas.restore();

    // চার কোণের ট্রাইগ্রাম
    final len = h * 0.34, th = h * 0.05, gap = h * 0.028;
    final d = h * 0.62;
    final black = Paint()..color = Colors.black;
    void tri(Offset dir, List<bool> solid) {
      final u = dir / dir.distance;
      canvas.save();
      canvas.translate(c.dx + u.dx * d, c.dy + u.dy * d);
      canvas.rotate(math.atan2(u.dy, u.dx));
      for (var i = 0; i < 3; i++) {
        final x = (i - 1) * (th + gap);
        if (solid[i]) {
          canvas.drawRect(
              Rect.fromLTRB(x - th / 2, -len / 2, x + th / 2, len / 2), black);
        } else {
          final g = len * 0.12;
          canvas.drawRect(
              Rect.fromLTRB(x - th / 2, -len / 2, x + th / 2, -g), black);
          canvas.drawRect(
              Rect.fromLTRB(x - th / 2, g, x + th / 2, len / 2), black);
        }
      }
      canvas.restore();
    }

    tri(Offset(-w, -h), [true, true, true]);
    tri(Offset(w, -h), [false, true, false]);
    tri(Offset(-w, h), [true, false, true]);
    tri(Offset(w, h), [false, false, false]);
  }

  void _bangladesh(Canvas canvas, double w, double h) {
    canvas.drawRect(
        Rect.fromLTWH(0, 0, w, h), Paint()..color = const Color(0xFF006A4E));
    canvas.drawCircle(Offset(w * 0.45, h / 2), h * 0.33,
        Paint()..color = const Color(0xFFF42A41));
  }

  @override
  bool shouldRepaint(FlagPainter old) => old.t != t || old.kind != kind;
}

// কোরিয়া + বাংলাদেশ: দুই পতাকা ও বন্ধুত্বের হৃদয়
class FlagsBanner extends StatefulWidget {
  const FlagsBanner({super.key});
  @override
  State<FlagsBanner> createState() => _FlagsBannerState();
}

class _FlagsBannerState extends State<FlagsBanner>
    with SingleTickerProviderStateMixin {
  late final AnimationController c =
      AnimationController(vsync: this, duration: const Duration(seconds: 5))
        ..repeat();

  @override
  void dispose() {
    c.dispose();
    super.dispose();
  }

  Widget flag(FlagKind k, double w, double tilt, double off) {
    final h = k == FlagKind.korea ? w * 2 / 3 : w * 0.6;
    return Transform.rotate(
      angle: tilt,
      child: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.35),
                blurRadius: 14,
                offset: const Offset(0, 8)),
          ],
        ),
        child: CustomPaint(size: Size(w, h), painter: FlagPainter(k, c.value, off)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pr = Theme.of(context).colorScheme.primary;
    final h2 = head2(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Glass(
        radius: 30,
        blur: 18,
        padding: const EdgeInsets.fromLTRB(14, 16, 14, 14),
        child: LayoutBuilder(
          builder: (ctx, box) {
            final fw = ((box.maxWidth - 84) / 2).clamp(80.0, 130.0).toDouble();
            return AnimatedBuilder(
              animation: c,
              builder: (ctx, _) {
                final beat = 1 + 0.12 * math.sin(c.value * 2 * math.pi * 2);
                return Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        flag(FlagKind.korea, fw, -0.07, 0),
                        Transform.scale(
                          scale: beat,
                          child: Container(
                            width: 54,
                            height: 54,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [pr, h2],
                              ),
                              border: Border.all(
                                  color: Colors.white.withOpacity(0.6)),
                              boxShadow: [
                                BoxShadow(
                                    color: pr.withOpacity(0.55),
                                    blurRadius: 18,
                                    spreadRadius: 1),
                              ],
                            ),
                            child: const Icon(Icons.favorite,
                                color: Colors.white, size: 28),
                          ),
                        ),
                        flag(FlagKind.bangladesh, fw, 0.07, 0.35),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('한국',
                            style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: pr)),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 10),
                          child: Text('×', style: TextStyle(fontSize: 18)),
                        ),
                        Text('বাংলাদেশ',
                            style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: h2)),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text('দুই দেশের বন্ধুত্ব, ভাষার সেতুবন্ধন',
                        style: TextStyle(fontSize: 13, color: softText(context))),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }
}
