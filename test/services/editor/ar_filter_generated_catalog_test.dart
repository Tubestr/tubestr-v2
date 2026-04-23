import 'package:flutter_test/flutter_test.dart';
import 'package:mytube/services/editor/generated_ar_filter_catalog.dart';

void main() {
  test('generated AR catalog is populated after publishing', () {
    expect(GeneratedArFilterCatalog.communityFilters, isNotEmpty);
  });

  test('generated AR catalog has a reviewed studio pack', () {
    final ids = GeneratedArFilterCatalog.communityFilters
        .map((filter) => filter.id)
        .toSet();

    expect(
      GeneratedArFilterCatalog.communityFilters.length,
      greaterThanOrEqualTo(30),
    );
    expect(ids, contains('studio-pup-pop'));
    expect(ids, contains('studio-cat-noir'));
    expect(ids, contains('studio-flower-crown'));
  });
}
