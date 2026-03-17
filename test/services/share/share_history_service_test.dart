import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mytube/core/storage/app_database.dart';
import 'package:mytube/services/share/share_history_service.dart';
import 'package:uuid/uuid.dart';

void main() {
  late AppDatabase database;
  late ShareHistoryService service;

  setUp(() {
    database = AppDatabase.forTesting(NativeDatabase.memory());
    service = ShareHistoryService(database: database, uuid: const Uuid());
  });

  tearDown(() async {
    await database.close();
  });

  test('records sent shares newest first', () async {
    await service.recordSent(
      videoId: 'video-1',
      title: 'First',
      childProfileId: 'child-1',
      childDisplayName: 'Emma',
      mlsGroupId: 'group-1',
      eventId: 'event-1',
    );
    await service.recordSent(
      videoId: 'video-2',
      title: 'Second',
      childProfileId: 'child-2',
      childDisplayName: 'Noah',
      mlsGroupId: 'group-1',
      eventId: 'event-2',
    );

    final history = await service.load();

    expect(history, hasLength(2));
    expect(history.first.videoId, 'video-2');
    expect(history.first.status, 'sent');
    expect(history.first.eventId, 'event-2');
    expect(history.last.videoId, 'video-1');
  });

  test('records queued shares with error details', () async {
    await service.recordQueued(
      videoId: 'video-3',
      title: 'Queued',
      childProfileId: 'child-1',
      childDisplayName: 'Emma',
      mlsGroupId: 'group-9',
      error: 'relay offline',
    );

    final history = await service.load();

    expect(history, hasLength(1));
    expect(history.single.status, 'queued');
    expect(history.single.error, 'relay offline');
    expect(history.single.eventId, isNull);
  });
}
