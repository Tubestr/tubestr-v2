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

  KidPalette get palette => switch (this) {
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
