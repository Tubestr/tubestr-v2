import 'package:flutter_test/flutter_test.dart';
import 'package:mytube/core/router/deep_link_service.dart';

void main() {
  test('parseAppDeepLink maps nook links into the parent zone destination', () {
    final result = parseAppDeepLink(Uri.parse('nook://family-invite?v=1'));

    expect(result, isNotNull);
    expect(result!.destination, AppDeepLinkDestination.parentZone);
  });

  test('parseAppDeepLink ignores unsupported schemes', () {
    final result = parseAppDeepLink(Uri.parse('mytube://family-invite?v=1'));

    expect(result, isNull);
  });
}
