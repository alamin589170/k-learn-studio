import 'package:flutter/material.dart';

const Color kNavy = Color(0xFF1B2F4A);
const Color kCream = Color(0xFFF7EFE2);
const Color kOrange = Color(0xFFC05A2B);
const Color kGold = Color(0xFFD4A24C);

bool isDark(BuildContext c) => Theme.of(c).brightness == Brightness.dark;

Color cardBg(BuildContext c) =>
    isDark(c) ? const Color(0xFF223A57) : Colors.white;

Color softText(BuildContext c) => isDark(c) ? Colors.white70 : Colors.black54;

List<BoxShadow> softShadow(BuildContext c) => [
      BoxShadow(
        color: Colors.black.withOpacity(isDark(c) ? 0.35 : 0.08),
        blurRadius: 14,
        offset: const Offset(0, 6),
      ),
    ];

// বাংলা বা ইংরেজি সংখ্যা থেকে পূর্ণসংখ্যা
int? parseNum(String s) {
  const bn = '০১২৩৪৫৬৭৮৯';
  final b = StringBuffer();
  for (final ch in s.trim().split('')) {
    final i = bn.indexOf(ch);
    b.write(i >= 0 ? '$i' : ch);
  }
  return int.tryParse(b.toString());
}

class IconCircle extends StatelessWidget {
  final IconData icon;
  final Color color;
  final double size;
  const IconCircle(
      {super.key, required this.icon, required this.color, this.size = 56});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color, color.withOpacity(0.7)],
        ),
      ),
      child: Icon(icon, color: Colors.white, size: size * 0.5),
    );
  }
}
