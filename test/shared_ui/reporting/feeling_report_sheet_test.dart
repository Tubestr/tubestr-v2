import 'package:flutter_test/flutter_test.dart';
import 'package:mytube/shared_ui/reporting/feeling_report_sheet.dart';

void main() {
  test('level 1 reports stay on this device', () {
    const submission = FeelingReportSubmission(
      feeling: ReportFeeling.uncomfortable,
      action: ReportActionOption.tellThem,
    );

    expect(submission.level, 1);
    expect(submission.recipientType, 'local');
    expect(submission.destinationLabel, 'Stays on this device');
    expect(submission.levelLabel, 'Level 1 · Noted');
  });

  test('level 2 reports alert a parent privately', () {
    const submission = FeelingReportSubmission(
      feeling: ReportFeeling.confused,
      action: ReportActionOption.hideVideos,
    );

    expect(submission.level, 2);
    expect(submission.recipientType, 'local_parent');
    expect(submission.destinationLabel, 'Your parent');
    expect(submission.levelLabel, 'Level 2 · Parent help');
  });

  test('level 3 reports alert both families', () {
    const submission = FeelingReportSubmission(
      feeling: ReportFeeling.angry,
      action: ReportActionOption.blockThem,
    );

    expect(submission.level, 3);
    expect(submission.recipientType, 'family');
    expect(submission.destinationLabel, 'Both families');
    expect(submission.levelLabel, 'Level 3 · Family alert');
  });
}
