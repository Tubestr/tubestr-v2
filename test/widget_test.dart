import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:mytube/app.dart';

void main() {
  testWidgets('app boots', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: MyTubeApp()),
    );
    await tester.pump();

    expect(find.byType(MyTubeApp), findsOneWidget);
    expect(find.byType(ProviderScope), findsOneWidget);
  });
}
