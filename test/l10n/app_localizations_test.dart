import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mytube/l10n/app_localizations.dart';
import 'package:mytube/l10n/app_localizations_en.dart';
import 'package:mytube/l10n/app_localizations_es.dart';

void main() {
  test('supports English and Spanish locales', () {
    expect(AppLocalizations.supportedLocales, const [
      Locale('en'),
      Locale('es'),
    ]);
  });

  test('Spanish strings are generated for representative app surfaces', () {
    final en = AppLocalizationsEn();
    final es = AppLocalizationsEs();

    expect(en.tabHome, 'Home');
    expect(en.languageSystemDescription, 'Follow device language');
    expect(es.tabHome, 'Inicio');
    expect(es.language, 'Idioma');
    expect(es.languageSpanishDescription, 'Usar español');
    expect(es.parentZoneTitle, 'Zona de Padres');
    expect(es.captureSharing('Mi video', 2), contains('espacios familiares'));
    expect(es.playerPlayCount(1), contains('reproducción'));
  });
}
