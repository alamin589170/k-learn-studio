import 'package:flutter/material.dart';

// ---------- থিম প্রিসেট ----------
class Preset {
  final String name;
  final bool dark;
  final Color bg, card, primary, head1, head2, text, soft;
  const Preset(this.name, this.dark, this.bg, this.card, this.primary,
      this.head1, this.head2, this.text, this.soft);
}

const List<Preset> kPresets = [
  Preset('Warm Cream', false, Color(0xFFF3EADB), Color(0xFFFFFAF1),
      Color(0xFFB4532A), Color(0xFF6B3A22), Color(0xFFB4532A),
      Color(0xFF2B2118), Color(0xFF7A6A5C)),
  Preset('Sepia (পড়ার জন্য)', false, Color(0xFFEADCBC), Color(0xFFF7EDD7),
      Color(0xFF8A5A2B), Color(0xFF5A3E22), Color(0xFF8A5A2B),
      Color(0xFF3B2A18), Color(0xFF7D6B52)),
  Preset('Mint Calm', false, Color(0xFFE4F0EA), Color(0xFFF7FCF9),
      Color(0xFF2A7F6B), Color(0xFF1F5C4E), Color(0xFF2A7F6B),
      Color(0xFF1B2E28), Color(0xFF5E7A70)),
  Preset('Sky Soft', false, Color(0xFFE6EEF8), Color(0xFFF8FBFE),
      Color(0xFF2F6DB5), Color(0xFF24508A), Color(0xFF2F6DB5),
      Color(0xFF17263A), Color(0xFF5D7086)),
  Preset('Lavender', false, Color(0xFFECE8F6), Color(0xFFFAF8FE),
      Color(0xFF6A55C8), Color(0xFF4B3B95), Color(0xFF6A55C8),
      Color(0xFF231D3D), Color(0xFF6E6890)),
  Preset('Soft Dark (Navy)', true, Color(0xFF16212F), Color(0xFF1F2E41),
      Color(0xFFE39A6B), Color(0xFF1B2B40), Color(0xFF35506F),
      Color(0xFFEDE6DA), Color(0xFFA8B3C2)),
  Preset('Night Warm (কম আলো)', true, Color(0xFF1B1714), Color(0xFF27211C),
      Color(0xFFD9A066), Color(0xFF33261C), Color(0xFF5A402B),
      Color(0xFFEADFD0), Color(0xFFB3A590)),
  Preset('High Contrast', false, Color(0xFFFFFFFF), Color(0xFFFFFFFF),
      Color(0xFF0B3D91), Color(0xFF0B3D91), Color(0xFF0B3D91),
      Color(0xFF000000), Color(0xFF333333)),
  Preset('High Contrast Dark', true, Color(0xFF000000), Color(0xFF121212),
      Color(0xFFFFD60A), Color(0xFF1A1A1A), Color(0xFF333333),
      Color(0xFFFFFFFF), Color(0xFFD0D0D0)),
];

// ---------- থিমের সঙ্গে বাঁধা রঙ ----------
class Pal extends ThemeExtension<Pal> {
  final Color card, head1, head2, soft, border;
  const Pal(
      {required this.card,
      required this.head1,
      required this.head2,
      required this.soft,
      required this.border});

  @override
  Pal copyWith(
          {Color? card,
          Color? head1,
          Color? head2,
          Color? soft,
          Color? border}) =>
      Pal(
        card: card ?? this.card,
        head1: head1 ?? this.head1,
        head2: head2 ?? this.head2,
        soft: soft ?? this.soft,
        border: border ?? this.border,
      );

  @override
  Pal lerp(ThemeExtension<Pal>? other, double t) {
    if (other is! Pal) return this;
    return Pal(
      card: Color.lerp(card, other.card, t)!,
      head1: Color.lerp(head1, other.head1, t)!,
      head2: Color.lerp(head2, other.head2, t)!,
      soft: Color.lerp(soft, other.soft, t)!,
      border: Color.lerp(border, other.border, t)!,
    );
  }
}

const Pal _defaultPal = Pal(
  card: Color(0xFFFFFAF1),
  head1: Color(0xFF6B3A22),
  head2: Color(0xFFB4532A),
  soft: Color(0xFF7A6A5C),
  border: Color(0x1FB4532A),
);

Pal palOf(BuildContext c) => Theme.of(c).extension<Pal>() ?? _defaultPal;

bool isDark(BuildContext c) => Theme.of(c).brightness == Brightness.dark;
Color cardBg(BuildContext c) => palOf(c).card;
Color softText(BuildContext c) => palOf(c).soft;
Color head1(BuildContext c) => palOf(c).head1;
Color head2(BuildContext c) => palOf(c).head2;

List<BoxShadow> softShadow(BuildContext c) => [
      BoxShadow(
        color: Colors.black.withOpacity(isDark(c) ? 0.30 : 0.06),
        blurRadius: 12,
        offset: const Offset(0, 5),
      ),
    ];

// কার্ডের সুন্দর ঘেরা (ছায়া + নরম বর্ডার)
BoxDecoration cardDeco(BuildContext c, [double radius = 24, Color? color]) =>
    BoxDecoration(
      color: color ?? cardBg(c),
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: palOf(c).border, width: 1),
      boxShadow: softShadow(c),
    );

LinearGradient headGradient(BuildContext c) => LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [palOf(c).head1, palOf(c).head2],
    );

// প্রিসেট থেকে ThemeData
ThemeData buildTheme(Preset p, int accent) {
  final primary = accent == 0 ? p.primary : Color(accent);
  final base = ColorScheme.fromSeed(
    seedColor: primary,
    brightness: p.dark ? Brightness.dark : Brightness.light,
  );
  final cs = base.copyWith(
    primary: primary,
    surface: p.bg,
    onSurface: p.text,
    onSurfaceVariant: p.soft,
  );
  final t = ThemeData(
    useMaterial3: true,
    colorScheme: cs,
    scaffoldBackgroundColor: p.bg,
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      foregroundColor: p.text,
      scrolledUnderElevation: 0,
      centerTitle: true,
    ),
  );
  return t.copyWith(
    textTheme: t.textTheme.apply(bodyColor: p.text, displayColor: p.text),
    extensions: [
      Pal(
        card: p.card,
        head1: p.head1,
        head2: accent == 0 ? p.head2 : Color(accent),
        soft: p.soft,
        border: (p.dark ? Colors.white : primary).withOpacity(p.dark ? 0.08 : 0.14),
      ),
    ],
  );
}

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
          colors: [color, color.withOpacity(0.72)],
        ),
      ),
      child: Icon(icon, color: Colors.white, size: size * 0.5),
    );
  }
}
