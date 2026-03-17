import 'package:flutter_test/flutter_test.dart';
import 'package:mytube/shared_ui/reporting/feeling_report_sheet.dart';

void main() {
  test('level 1 reports stay inside the family group', () {
    const submission = FeelingReportSubmission(
      feeling: ReportFeeling.uncomfortable,
      action: ReportActionOption.tellThem,
    );

    expect(submission.level, 1);
    expect(submission.recipientType, 'group');
    expect(submission.destinationLabel, 'Your family');
    expect(submission.levelLabel, 'Level 1 · Family feedback');
  });

  test('level 2 reports escalate to parent helpers', () {
    const submission = FeelingReportSubmission(
      feeling: ReportFeeling.confused,
      action: ReportActionOption.hideVideos,
    );

    expect(submission.level, 2);
    expect(submission.recipientType, 'parents');
    expect(submission.destinationLabel, 'Parent helpers');
    expect(submission.levelLabel, 'Level 2 · Parent help');
  });

  test('level 3 reports escalate to Safety HQ', () {
    const submission = FeelingReportSubmission(
      feeling: ReportFeeling.angry,
      action: ReportActionOption.blockThem,
    );

    expect(submission.level, 3);
    expect(submission.recipientType, 'safety_hq');
    expect(submission.destinationLabel, 'Safety HQ');
    expect(submission.levelLabel, 'Level 3 · Safety alert');
  });
}
