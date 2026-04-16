import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mytube/core/theme/theme_descriptor.dart';
import 'package:mytube/features/onboarding/presentation/widgets/onboarding_step_widgets.dart';

void main() {
  testWidgets('age confirmation label toggles checkbox', (tester) async {
    final displayNameController = TextEditingController(text: 'Lee');
    final birthYearController = TextEditingController(text: '1988');
    var consentAccepted = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) {
              return OnboardingParentKeyStep(
                identity: null,
                displayNameController: displayNameController,
                birthYearController: birthYearController,
                palette: ThemeDescriptor.campfire.palette,
                busy: false,
                consentAccepted: consentAccepted,
                eligibilityMessage: null,
                onGenerate: () {},
                onBirthYearChanged: (_) {},
                onConsentChanged: (value) {
                  setState(() => consentAccepted = value);
                },
                onOpenPrivacyPolicy: () async {},
                onContinue: () {},
              );
            },
          ),
        ),
      ),
    );

    const label =
        'I am 18 or older and I agree to the Tubestr privacy policy on behalf of any children whose profiles I create.';

    await tester.tap(find.text(label));
    await tester.pump();

    expect(consentAccepted, isTrue);
    expect(tester.widget<Checkbox>(find.byType(Checkbox)).value, isTrue);

    displayNameController.dispose();
    birthYearController.dispose();
  });
}
