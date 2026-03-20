import 'package:integration_test/integration_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mytube/app.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('app boots into the real widget tree', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: MyTubeApp()));
    await tester.pump();

    expect(find.byType(MyTubeApp), findsOneWidget);
    expect(find.byType(ProviderScope), findsOneWidget);
  });
}
