import 'package:flutter/material.dart';

// ---------- থিম প্রিসেট (প্রতিটিতে ২টি রঙের গ্রেডিয়েন্ট) ----------
class Preset {
  final String name;
  final bool dark;
  final Color bg1, bg2, card, primary, head1, head2, text, soft, sheet;
  const Preset(this.name, this.dark, this.bg1, this.bg2, this.card,
      this.primary, this.head1, this.head2, this.text, this.soft, this.sheet);
}

const Color _gDark = Color(0x1FFFFFFF);
const Color _gLight = Color(0xA8FFFFFF);

const List<Preset> kPresets = [
  // রেফারেন্স স্ক্রিনশটের থিম: গাঢ় নেভি + বেগুনি/গোলাপি আভা + কাচের কার্ড
  Preset('Studio Night', true, Color(0xFF0F152B), Color(0xFF1B2047), Color(0x1AFFFFFF),
      Color(0xFF8B7BFF), Color(0xFF5B4BDB), Color(0xFFB65CFF),
      Color(0xFFEAEFFF), Color(0xFF9AA4C7), Color(0xFF171C3A)),
  Preset('Midnight Blue', true, Color(0xFF0B1226), Color(0xFF17387A), _gDark,
      Color(0xFF4DA3FF), Color(0xFF1D4ED8), Color(0xFF38BDF8),
      Color(0xFFEAF2FF), Color(0xFF9FB4D6), Color(0xFF13224A)),
  Preset('Violet Dusk', true, Color(0xFF171033), Color(0xFF45349A), _gDark,
      Color(0xFFB79CFF), Color(0xFF6D3BFF), Color(0xFFC25CFF),
      Color(0xFFF1ECFF), Color(0xFFB4A9DC), Color(0xFF241A55)),
  Preset('Ocean Teal', true, Color(0xFF061E26), Color(0xFF0E5A66), _gDark,
      Color(0xFF34E0C4), Color(0xFF0EA5A5), Color(0xFF2563EB),
      Color(0xFFE6FBF8), Color(0xFF9CC9C6), Color(0xFF0B3640)),
  Preset('Rose Aurora', true, Color(0xFF230C2E), Color(0xFF702370), _gDark,
      Color(0xFFFF7EB8), Color(0xFFE0338A), Color(0xFF8B3DFF),
      Color(0xFFFFEAF5), Color(0xFFD2A6C4), Color(0xFF3A1245)),
  Preset('Sunset Ember', true, Color(0xFF24100C), Color(0xFF80321C), _gDark,
      Color(0xFFFFB066), Color(0xFFF0592A), Color(0xFFFFA32B),
      Color(0xFFFFF0E6), Color(0xFFD9B3A0), Color(0xFF3C1A12)),
  Preset('Emerald Night', true, Color(0xFF061A14), Color(0xFF14604A), _gDark,
      Color(0xFF52E8A0), Color(0xFF0F9D6B), Color(0xFF2EC4B6),
      Color(0xFFE7FFF4), Color(0xFF9FCDB9), Color(0xFF0C3326)),
  Preset('Classic Navy-Orange', true, Color(0xFF14213D), Color(0xFF5A2F2A),
      _gDark, Color(0xFFFFA94D), Color(0xFF1F3A68), Color(0xFFE07A2F),
      Color(0xFFF5EEE4), Color(0xFFC4B8A8), Color(0xFF23304D)),
  Preset('Crystal Sky (Light)', false, Color(0xFFD6E8FF), Color(0xFFF1E4FF),
      _gLight, Color(0xFF2F6BFF), Color(0xFF3B82F6), Color(0xFF8B5CF6),
      Color(0xFF14213D), Color(0xFF5C6B8A), Color(0xFFF4F7FF)),
  Preset('Peach Blossom (Light)', false, Color(0xFFFFE6D6), Color(0xFFFFD6EA),
      _gLight, Color(0xFFE2573B), Color(0xFFFF7A59), Color(0xFFE0508F),
      Color(0xFF3B1E1A), Color(0xFF8A6359), Color(0xFFFFF6F0)),
  Preset('Mint Breeze (Light)', false, Color(0xFFD3F4E8), Color(0xFFD6E6FF),
      _gLight, Color(0xFF14967F), Color(0xFF10B981), Color(0xFF3B82F6),
      Color(0xFF10302A), Color(0xFF56756D), Color(0xFFF2FCF8)),
  Preset('Warm Cream (Reading)', false, Color(0xFFF6ECDC), Color(0xFFE9D6B6),
      _gLight, Color(0xFFB4532A), Color(0xFF6B3A22), Color(0xFFB4532A),
      Color(0xFF2B2118), Color(0xFF7A6A5C), Color(0xFFFFF8EC)),
  Preset('High Contrast Dark', true, Color(0xFF000000), Color(0xFF000000),
      Color(0x24FFFFFF), Color(0xFFFFD60A), Color(0xFF1A1A1A),
      Color(0xFF3A3A3A), Color(0xFFFFFFFF), Color(0xFFD0D0D0),
      Color(0xFF111111)),
  Preset('High Contrast Light', false, Color(0xFFFFFFFF), Color(0xFFFFFFFF),
      Color(0xFFF2F2F2), Color(0xFF0B3D91), Color(0xFF0B3D91),
      Color(0xFF0B3D91), Color(0xFF000000), Color(0xFF333333),
      Color(0xFFFFFFFF)),
];

// দিন/রাত বদলের ডিফল্ট থিম
const int kDefaultDark = 0;
const int kDefaultLight = 8;

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
  card: Color(0x1FFFFFFF),
  head1: Color(0xFF1D4ED8),
  head2: Color(0xFF38BDF8),
  soft: Color(0xFF9FB4D6),
  border: Color(0x2EFFFFFF),
);

Pal palOf(BuildContext c) => Theme.of(c).extension<Pal>() ?? _defaultPal;

bool isDark(BuildContext c) => Theme.of(c).brightness == Brightness.dark;
Color cardBg(BuildContext c) => palOf(c).card;
Color softText(BuildContext c) => palOf(c).soft;
Color head1(BuildContext c) => palOf(c).head1;
Color head2(BuildContext c) => palOf(c).head2;

List<BoxShadow> softShadow(BuildContext c) => [
      BoxShadow(
        color: Colors.black.withOpacity(isDark(c) ? 0.22 : 0.06),
        blurRadius: 8,
        offset: const Offset(0, 3),
      ),
    ];

// তালিকার সারির জন্য হালকা কার্ড (ছায়া ছাড়া, স্ক্রল দ্রুত)
BoxDecoration flatDeco(BuildContext c, [double radius = 24]) {
  final p = palOf(c);
  return BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [p.card, p.card.withOpacity(p.card.opacity * 0.55)],
    ),
    borderRadius: BorderRadius.circular(radius),
    border: Border.all(color: p.border, width: 1),
  );
}

// ক্রিস্টাল কার্ড (স্বচ্ছ গ্রেডিয়েন্ট + আলোর বর্ডার)
BoxDecoration cardDeco(BuildContext c, [double radius = 24, Color? color]) {
  final p = palOf(c);
  return BoxDecoration(
    color: color,
    gradient: color == null
        ? LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [p.card, p.card.withOpacity(p.card.opacity * 0.55)],
          )
        : null,
    borderRadius: BorderRadius.circular(radius),
    border: Border.all(color: p.border, width: 1),
    boxShadow: softShadow(c),
  );
}

// ক্রিস্টাল কাচের বাক্স (ব্লার ছাড়া, তাই ল্যাগ হয় না)
class Glass extends StatelessWidget {
  final Widget child;
  final double radius;
  final double blur;
  final EdgeInsetsGeometry? padding;
  final Gradient? gradient;
  const Glass(
      {super.key,
      required this.child,
      this.radius = 24,
      this.blur = 0,
      this.padding,
      this.gradient});

  @override
  Widget build(BuildContext context) {
    final p = palOf(context);
    final r = BorderRadius.circular(radius);
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        borderRadius: r,
        border: Border.all(color: p.border, width: 1),
        gradient: gradient ??
            LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [p.card, p.card.withOpacity(p.card.opacity * 0.55)],
            ),
        boxShadow: softShadow(context),
      ),
      child: child,
    );
  }
}

// পেজ বদলের নরম ফেড-স্লাইড
class GlassTransitions extends PageTransitionsBuilder {
  const GlassTransitions();
  @override
  Widget buildTransitions<T>(
      PageRoute<T> route,
      BuildContext context,
      Animation<double> animation,
      Animation<double> secondaryAnimation,
      Widget child) {
    final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
    return FadeTransition(
      opacity: curved,
      child: SlideTransition(
        position: Tween<Offset>(begin: const Offset(0, 0.04), end: Offset.zero)
            .animate(curved),
        child: child,
      ),
    );
  }
}

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
    surface: p.sheet,
    onSurface: p.text,
    onSurfaceVariant: p.soft,
    surfaceContainerLowest: p.sheet,
    surfaceContainerLow: p.sheet,
    surfaceContainer: p.sheet,
    surfaceContainerHigh: p.sheet,
    surfaceContainerHighest: p.sheet,
  );
  const tr = FadeUpwardsPageTransitionsBuilder();
  final t = ThemeData(
    useMaterial3: true,
    colorScheme: cs,
    scaffoldBackgroundColor: Colors.transparent,
    canvasColor: p.sheet,
    iconTheme: IconThemeData(color: p.text),
    pageTransitionsTheme: const PageTransitionsTheme(builders: {
      TargetPlatform.android: tr,
      TargetPlatform.iOS: tr,
      TargetPlatform.linux: tr,
      TargetPlatform.macOS: tr,
      TargetPlatform.windows: tr,
    }),
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      foregroundColor: p.text,
      scrolledUnderElevation: 0,
      elevation: 0,
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
        border: p.dark
            ? Colors.white.withOpacity(0.18)
            : Colors.white.withOpacity(0.85),
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
