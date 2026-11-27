import 'package:flutter/material.dart';

// ছোট গোল পতাকা (কোরিয়া ও বাংলাদেশ) ও "বাংলা → 한국어" ব্যাজ
class MiniFlags extends StatelessWidget {
  final double size;
  const MiniFlags({super.key, this.size = 24});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size * 1.7,
      height: size,
      child: Stack(
        children: [
          Positioned(
            left: 0,
            child: Container(
              width: size,
              height: size,
              decoration: const BoxDecoration(
                  shape: BoxShape.circle, color: Colors.white),
              child: CustomPaint(painter: _KoreaDot()),
            ),
          ),
          Positioned(
            left: size * 0.7,
            child: Container(
              width: size,
              height: size,
              decoration: const BoxDecoration(
                  shape: BoxShape.circle, color: Color(0xFF006A4E)),
              child: Center(
                child: Container(
                  width: size * 0.5,
                  height: size * 0.5,
                  decoration: const BoxDecoration(
                      shape: BoxShape.circle, color: Color(0xFFF42A41)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _KoreaDot extends CustomPainter {
  @override
  void paint(Canvas canvas, Size s) {
    final c = Offset(s.width / 2, s.height / 2);
    final r = s.width * 0.26;
    canvas.save();
    canvas.translate(c.dx, c.dy);
    canvas.rotate(-0.588);
    canvas.clipPath(Path()..addOval(Rect.fromCircle(center: Offset.zero, radius: r)));
    canvas.drawRect(Rect.fromLTRB(-r, -r, r, 0), Paint()..color = const Color(0xFFCD2E3A));
    canvas.drawRect(Rect.fromLTRB(-r, 0, r, r), Paint()..color = const Color(0xFF0047A0));
    canvas.restore();
  }

  @override
  bool shouldRepaint(_KoreaDot old) => false;
}

class LangBadge extends StatelessWidget {
  const LangBadge({super.key});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 5, 12, 5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Colors.white.withOpacity(0.08),
        border: Border.all(color: Colors.white.withOpacity(0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const MiniFlags(size: 22),
          const SizedBox(width: 6),
          Text('বাংলা → 한국어',
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface)),
        ],
      ),
    );
  }
}
