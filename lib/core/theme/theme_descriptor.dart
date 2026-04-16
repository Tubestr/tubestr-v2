import 'package:flutter/material.dart';

enum ThemeDescriptor { campfire, treehouse, blanketFort, starlight }

extension ThemeDescriptorX on ThemeDescriptor {
  String get label => switch (this) {
    ThemeDescriptor.campfire => 'Campfire',
    ThemeDescriptor.treehouse => 'Treehouse',
    ThemeDescriptor.blanketFort => 'Blanket Fort',
    ThemeDescriptor.starlight => 'Starlight',
  };

  String get defaultAvatarAsset => switch (this) {
    ThemeDescriptor.campfire => 'sun',
    ThemeDescriptor.treehouse => 'leaf',
    ThemeDescriptor.blanketFort => 'kite',
    ThemeDescriptor.starlight => 'star',
  };

  KidPalette get palette => lightPalette;

  KidPalette paletteFor(Brightness brightness) {
    return brightness == Brightness.dark ? darkPalette : lightPalette;
  }

  KidPalette get lightPalette => switch (this) {
    ThemeDescriptor.campfire => const KidPalette(
      accent: Color(0xFFE8794E),
      accentSecondary: Color(0xFFF9B45E),
      backgroundTop: Color(0xFFFFF5ED),
      backgroundBottom: Color(0xFFFAD9BE),
      panel: Color(0xCCFFFDF8),
      panelBorder: Color(0x33C85D2E),
      ink: Color(0xFF3B2418),
      mutedInk: Color(0xFF845B48),
      success: Color(0xFF3FAE6F),
      warning: Color(0xFFF1A53A),
      danger: Color(0xFFD65D57),
    ),
    ThemeDescriptor.treehouse => const KidPalette(
      accent: Color(0xFF7A684A),
      accentSecondary: Color(0xFFA3B157),
      backgroundTop: Color(0xFFF7F2E6),
      backgroundBottom: Color(0xFFD8D0B5),
      panel: Color(0xCCFFFCF6),
      panelBorder: Color(0x334B422F),
      ink: Color(0xFF2F291E),
      mutedInk: Color(0xFF6B6452),
      success: Color(0xFF418B64),
      warning: Color(0xFFD99937),
      danger: Color(0xFFC0584B),
    ),
    ThemeDescriptor.blanketFort => const KidPalette(
      accent: Color(0xFF9C7AA8),
      accentSecondary: Color(0xFFF2A7B7),
      backgroundTop: Color(0xFFFCF7FD),
      backgroundBottom: Color(0xFFF1DDEB),
      panel: Color(0xCCFFFBFF),
      panelBorder: Color(0x33593C63),
      ink: Color(0xFF34263B),
      mutedInk: Color(0xFF75627D),
      success: Color(0xFF4CA378),
      warning: Color(0xFFEAAB42),
      danger: Color(0xFFCC6675),
    ),
    ThemeDescriptor.starlight => const KidPalette(
      accent: Color(0xFF6E63A8),
      accentSecondary: Color(0xFFE2C76C),
      backgroundTop: Color(0xFFF2F1FA),
      backgroundBottom: Color(0xFFD9D5EE),
      panel: Color(0xCCFBFBFF),
      panelBorder: Color(0x333B3568),
      ink: Color(0xFF241F38),
      mutedInk: Color(0xFF645C82),
      success: Color(0xFF4BA37A),
      warning: Color(0xFFF1AA45),
      danger: Color(0xFFD0605C),
    ),
  };

  KidPalette get darkPalette => switch (this) {
    ThemeDescriptor.campfire => const KidPalette(
      accent: Color(0xFFFF9A70),
      accentSecondary: Color(0xFFFFC56F),
      backgroundTop: Color(0xFF21130F),
      backgroundBottom: Color(0xFF3A1D16),
      panel: Color(0xDD2B1712),
      panelBorder: Color(0x55FF9A70),
      ink: Color(0xFFFFEDE4),
      mutedInk: Color(0xFFE2C1B2),
      success: Color(0xFF7AD99C),
      warning: Color(0xFFFFC768),
      danger: Color(0xFFFF8E86),
    ),
    ThemeDescriptor.treehouse => const KidPalette(
      accent: Color(0xFFD7C28E),
      accentSecondary: Color(0xFFC2D66F),
      backgroundTop: Color(0xFF141A12),
      backgroundBottom: Color(0xFF28321B),
      panel: Color(0xDD1C2418),
      panelBorder: Color(0x557D8D5C),
      ink: Color(0xFFF6F0DE),
      mutedInk: Color(0xFFD3C9AB),
      success: Color(0xFF7FD4A4),
      warning: Color(0xFFEAB65C),
      danger: Color(0xFFE18A7A),
    ),
    ThemeDescriptor.blanketFort => const KidPalette(
      accent: Color(0xFFD8A7EA),
      accentSecondary: Color(0xFFFFB4C8),
      backgroundTop: Color(0xFF1D1323),
      backgroundBottom: Color(0xFF332037),
      panel: Color(0xDD24172B),
      panelBorder: Color(0x55D8A7EA),
      ink: Color(0xFFFBE9FF),
      mutedInk: Color(0xFFDDBFDE),
      success: Color(0xFF82D8AD),
      warning: Color(0xFFFFC56D),
      danger: Color(0xFFF08A9A),
    ),
    ThemeDescriptor.starlight => const KidPalette(
      accent: Color(0xFFA99BFA),
      accentSecondary: Color(0xFFF0D777),
      backgroundTop: Color(0xFF111027),
      backgroundBottom: Color(0xFF211B42),
      panel: Color(0xDD161533),
      panelBorder: Color(0x55A99BFA),
      ink: Color(0xFFF3F0FF),
      mutedInk: Color(0xFFCBC3EA),
      success: Color(0xFF81D8B0),
      warning: Color(0xFFFFC96E),
      danger: Color(0xFFF08A86),
    ),
  };

  static ThemeDescriptor fromStorage(String raw) {
    return ThemeDescriptor.values.firstWhere(
      (value) => value.name == raw,
      orElse: () => ThemeDescriptor.campfire,
    );
  }
}

class KidPalette {
  const KidPalette({
    required this.accent,
    required this.accentSecondary,
    required this.backgroundTop,
    required this.backgroundBottom,
    required this.panel,
    required this.panelBorder,
    required this.ink,
    required this.mutedInk,
    required this.success,
    required this.warning,
    required this.danger,
  });

  final Color accent;
  final Color accentSecondary;
  final Color backgroundTop;
  final Color backgroundBottom;
  final Color panel;
  final Color panelBorder;
  final Color ink;
  final Color mutedInk;
  final Color success;
  final Color warning;
  final Color danger;
}
