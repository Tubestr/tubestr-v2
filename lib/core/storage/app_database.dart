import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../domain/models/remote_share_identity.dart';
import '../../domain/models/remote_share_projection.dart';

part 'app_database.g.dart';

class JsonStringListConverter extends TypeConverter<List<String>, String> {
  const JsonStringListConverter();

  @override
  List<String> fromSql(String fromDb) {
    final decoded = jsonDecode(fromDb);
    if (decoded is! List) {
      return const [];
    }
    return decoded.map((item) => item.toString()).toList(growable: false);
  }

  @override
  String toSql(List<String> value) => jsonEncode(value);
}

class Profiles extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get theme => text()();
  TextColumn get avatarAsset => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class ProfileGroups extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get profileId => text().references(Profiles, #id)();
  TextColumn get mlsGroupId => text()();
  BoolColumn get isPrimary => boolean().withDefault(const Constant(true))();
  DateTimeColumn get joinedAt => dateTime()();
}

class LocalVideos extends Table {
  TextColumn get id => text()();
  TextColumn get profileId => text().references(Profiles, #id)();
  TextColumn get filePath => text()();
  TextColumn get thumbPath => text()();
  TextColumn get title => text().withDefault(const Constant('Untitled'))();
  RealColumn get durationSeconds => real().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get lastPlayedAt => dateTime().nullable()();
  IntColumn get playCount => integer().withDefault(const Constant(0))();
  RealColumn get completionRate => real().withDefault(const Constant(0))();
  RealColumn get replayRate => real().withDefault(const Constant(0))();
  BoolColumn get liked => boolean().withDefault(const Constant(false))();
  BoolColumn get hidden => boolean().withDefault(const Constant(false))();
  TextColumn get tags => text()
      .map(const JsonStringListConverter())
      .withDefault(const Constant('[]'))();
  TextColumn get cvLabels => text()
      .map(const JsonStringListConverter())
      .withDefault(const Constant('[]'))();
  IntColumn get faceCount => integer().withDefault(const Constant(0))();
  RealColumn get loudness => real().withDefault(const Constant(0))();
  DateTimeColumn get reportedAt => dateTime().nullable()();
  TextColumn get reportReason => text().nullable()();
  TextColumn get approvalStatus =>
      text().withDefault(const Constant('approved'))();
  DateTimeColumn get approvedAt => dateTime().nullable()();
  TextColumn get approvedByParentKey => text().nullable()();
  TextColumn get scanResults => text().nullable()();
  DateTimeColumn get scanCompletedAt => dateTime().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class RemoteAssets extends Table {
  TextColumn get remoteShareId => text()();
  TextColumn get videoId => text()();
  TextColumn get blobHash => text().nullable()();
  TextColumn get thumbHash => text().nullable()();
  TextColumn get epoch => text().nullable()();
  TextColumn get mime => text().nullable()();
  TextColumn get metadataJson => text().nullable()();
  TextColumn get localMediaPath => text().nullable()();
  TextColumn get localThumbPath => text().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {remoteShareId};
}

class ShareRecords extends Table {
  TextColumn get remoteShareId =>
      text().references(RemoteAssets, #remoteShareId)();
  TextColumn get videoId => text()();
  TextColumn get mlsGroupId => text()();
  TextColumn get senderParentKey => text()();
  TextColumn get childProfileId => text()();
  TextColumn get childDisplayName => text().nullable()();
  TextColumn get status => text().withDefault(const Constant('available'))();
  DateTimeColumn get receivedAt => dateTime()();
  TextColumn get downloadError => text().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {remoteShareId};
}

class Likes extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get videoId => text()();
  TextColumn get childProfileId => text()();
  TextColumn get parentPubkey => text()();
  DateTimeColumn get createdAt => dateTime()();
}

class Reactions extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get videoId => text()();
  TextColumn get childProfileId => text()();
  TextColumn get parentPubkey => text()();
  TextColumn get emoji => text()();
  DateTimeColumn get createdAt => dateTime()();
}

class RemotePlaybackMetrics extends Table {
  TextColumn get remoteShareId =>
      text().references(ShareRecords, #remoteShareId)();
  TextColumn get videoId => text()();
  DateTimeColumn get lastPlayedAt => dateTime().nullable()();
  IntColumn get playCount => integer().withDefault(const Constant(0))();
  RealColumn get completionRate => real().withDefault(const Constant(0))();
  RealColumn get replayRate => real().withDefault(const Constant(0))();

  @override
  Set<Column<Object>> get primaryKey => {remoteShareId};
}

class Reports extends Table {
  TextColumn get id => text()();
  TextColumn get videoId => text()();
  TextColumn get subjectChildId => text()();
  TextColumn get blobHash => text().nullable()();
  TextColumn get reason => text()();
  TextColumn get note => text().nullable()();
  IntColumn get level => integer().withDefault(const Constant(1))();
  TextColumn get recipientType => text().withDefault(const Constant('group'))();
  TextColumn get reporterChildId => text().nullable()();
  TextColumn get reporterParentKey => text()();
  TextColumn get status => text().withDefault(const Constant('pending'))();
  TextColumn get actionTaken => text().nullable()();
  BoolColumn get isOutbound => boolean().withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get deliveredAt => dateTime().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class ModerationAuditLogs extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get videoId => text().nullable()();
  TextColumn get mlsGroupId => text().nullable()();
  TextColumn get actionType => text()();
  TextColumn get actorParentKey => text().nullable()();
  TextColumn get subjectParentKey => text().nullable()();
  TextColumn get detailsJson => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
}

class AppSettings extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {key};
}

@DriftDatabase(
  tables: [
    Profiles,
    ProfileGroups,
    LocalVideos,
    RemoteAssets,
    ShareRecords,
    Likes,
    Reactions,
    RemotePlaybackMetrics,
    Reports,
    ModerationAuditLogs,
    AppSettings,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onUpgrade: (m, from, to) async {
      if (from < 3) {
        await m.createTable(reactions);
        await m.createTable(remotePlaybackMetrics);
      }
    },
  );

  Stream<List<Profile>> watchProfiles() {
    return (select(
      profiles,
    )..orderBy([(t) => OrderingTerm.asc(t.createdAt)])).watch();
  }

  Stream<List<LocalVideo>> watchVideosForProfile(String? profileId) {
    final query = select(localVideos)
      ..where((tbl) => tbl.hidden.equals(false))
      ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]);

    if (profileId != null) {
      query.where((tbl) => tbl.profileId.equals(profileId));
    }

    return query.watch();
  }

  Stream<List<LocalVideo>> watchPendingApprovalVideos() {
    return (select(localVideos)
          ..where((tbl) => tbl.approvalStatus.isNotValue('approved'))
          ..orderBy([(tbl) => OrderingTerm.desc(tbl.createdAt)]))
        .watch();
  }

  Stream<List<ShareRecord>> watchShareRecords() {
    return (select(
      shareRecords,
    )..orderBy([(t) => OrderingTerm.desc(t.receivedAt)])).watch();
  }

  Stream<List<RemoteShareProjection>> watchRemoteShareProjections() {
    final query = select(shareRecords).join([
      innerJoin(
        remoteAssets,
        remoteAssets.remoteShareId.equalsExp(shareRecords.remoteShareId),
      ),
    ])..orderBy([OrderingTerm.desc(shareRecords.receivedAt)]);

    return query.watch().map(
      (rows) => rows
          .map((row) => _mapRemoteShareProjection(row))
          .toList(growable: false),
    );
  }

  Stream<RemoteShareProjection?> watchRemoteShareProjectionByRemoteShareId(
    String remoteShareId,
  ) {
    final query =
        select(shareRecords).join([
            innerJoin(
              remoteAssets,
              remoteAssets.remoteShareId.equalsExp(shareRecords.remoteShareId),
            ),
          ])
          ..where(shareRecords.remoteShareId.equals(remoteShareId))
          ..limit(1);

    return query.watchSingleOrNull().map(
      (row) => row == null ? null : _mapRemoteShareProjection(row),
    );
  }

  Future<List<RemoteShareProjection>> getRemoteShareProjectionsForGroup(
    String mlsGroupId,
  ) async {
    final query =
        select(shareRecords).join([
            innerJoin(
              remoteAssets,
              remoteAssets.remoteShareId.equalsExp(shareRecords.remoteShareId),
            ),
          ])
          ..where(shareRecords.mlsGroupId.equals(mlsGroupId))
          ..orderBy([OrderingTerm.desc(shareRecords.receivedAt)]);

    final rows = await query.get();
    return rows.map(_mapRemoteShareProjection).toList(growable: false);
  }

  Stream<List<Report>> watchReports() {
    return (select(
      reports,
    )..orderBy([(t) => OrderingTerm.desc(t.createdAt)])).watch();
  }

  Stream<List<ModerationAuditLog>> watchModerationAuditLogs() {
    return (select(
      moderationAuditLogs,
    )..orderBy([(t) => OrderingTerm.desc(t.createdAt)])).watch();
  }

  Stream<int> watchLikeCountForVideo(String videoId) {
    final query = selectOnly(likes)
      ..addColumns([likes.id.count()])
      ..where(likes.videoId.equals(videoId));
    return query.watchSingle().map((row) => row.read(likes.id.count()) ?? 0);
  }

  Stream<List<Like>> watchLikesForVideo(String videoId) {
    return (select(likes)
          ..where((tbl) => tbl.videoId.equals(videoId))
          ..orderBy([(tbl) => OrderingTerm.desc(tbl.createdAt)]))
        .watch();
  }

  Stream<bool> watchLikeForVideoByParentAndChild({
    required String videoId,
    required String childProfileId,
    required String parentPubkey,
  }) {
    return (select(likes)
          ..where(
            (tbl) =>
                tbl.videoId.equals(videoId) &
                tbl.childProfileId.equals(childProfileId) &
                tbl.parentPubkey.equals(parentPubkey),
          )
          ..limit(1))
        .watchSingleOrNull()
        .map((row) => row != null);
  }

  Stream<List<Reaction>> watchReactionsForVideo(String videoId) {
    return (select(reactions)
          ..where((tbl) => tbl.videoId.equals(videoId))
          ..orderBy([(tbl) => OrderingTerm.desc(tbl.createdAt)]))
        .watch();
  }

  Stream<List<String>> watchReactionsForVideoByParentAndChild({
    required String videoId,
    required String childProfileId,
    required String parentPubkey,
  }) {
    return (select(reactions)..where(
          (tbl) =>
              tbl.videoId.equals(videoId) &
              tbl.childProfileId.equals(childProfileId) &
              tbl.parentPubkey.equals(parentPubkey),
        ))
        .watch()
        .map(
          (rows) =>
              rows.map((row) => row.emoji).toSet().toList(growable: false),
        );
  }

  Stream<RemotePlaybackMetric?> watchRemotePlaybackMetrics(
    String remoteShareId,
  ) {
    return (select(remotePlaybackMetrics)
          ..where((tbl) => tbl.remoteShareId.equals(remoteShareId))
          ..limit(1))
        .watchSingleOrNull();
  }

  Future<void> upsertProfile({
    required String id,
    required String name,
    required String theme,
    required String avatarAsset,
  }) {
    final now = DateTime.now();

    return into(profiles).insertOnConflictUpdate(
      ProfilesCompanion(
        id: Value(id),
        name: Value(name),
        theme: Value(theme),
        avatarAsset: Value(avatarAsset),
        createdAt: Value(now),
        updatedAt: Value(now),
      ),
    );
  }

  Future<void> updateProfileTheme({
    required String profileId,
    required String theme,
  }) {
    return (update(profiles)..where((tbl) => tbl.id.equals(profileId))).write(
      ProfilesCompanion(theme: Value(theme), updatedAt: Value(DateTime.now())),
    );
  }

  Future<void> deleteProfileById(String profileId) async {
    await (delete(
      profileGroups,
    )..where((tbl) => tbl.profileId.equals(profileId))).go();
    await (delete(
      localVideos,
    )..where((tbl) => tbl.profileId.equals(profileId))).go();
    await (delete(profiles)..where((tbl) => tbl.id.equals(profileId))).go();
  }

  Future<String?> getPrimaryGroupIdForProfile(String profileId) async {
    final row =
        await (select(profileGroups)
              ..where(
                (tbl) =>
                    tbl.profileId.equals(profileId) &
                    tbl.isPrimary.equals(true),
              )
              ..orderBy([(tbl) => OrderingTerm.desc(tbl.joinedAt)])
              ..limit(1))
            .getSingleOrNull();
    return row?.mlsGroupId;
  }

  Future<String?> getPrimaryGroupIdForAnyProfile() async {
    final row =
        await (select(profileGroups)
              ..where((tbl) => tbl.isPrimary.equals(true))
              ..orderBy([(tbl) => OrderingTerm.desc(tbl.joinedAt)])
              ..limit(1))
            .getSingleOrNull();
    return row?.mlsGroupId;
  }

  Future<void> setPrimaryGroupForProfile({
    required String profileId,
    required String mlsGroupId,
  }) async {
    await transaction(() async {
      await (update(profileGroups)
            ..where((tbl) => tbl.profileId.equals(profileId)))
          .write(const ProfileGroupsCompanion(isPrimary: Value(false)));

      final existing =
          await (select(profileGroups)
                ..where(
                  (tbl) =>
                      tbl.profileId.equals(profileId) &
                      tbl.mlsGroupId.equals(mlsGroupId),
                )
                ..limit(1))
              .getSingleOrNull();

      if (existing == null) {
        await into(profileGroups).insert(
          ProfileGroupsCompanion.insert(
            profileId: profileId,
            mlsGroupId: mlsGroupId,
            isPrimary: const Value(true),
            joinedAt: DateTime.now(),
          ),
        );
        return;
      }

      await (update(
        profileGroups,
      )..where((tbl) => tbl.id.equals(existing.id))).write(
        ProfileGroupsCompanion(
          isPrimary: const Value(true),
          joinedAt: Value(DateTime.now()),
        ),
      );
    });
  }

  Future<void> assignPrimaryGroupToProfilesIfMissing(String mlsGroupId) async {
    final allProfiles = await select(profiles).get();
    for (final profile in allProfiles) {
      final existingPrimary = await getPrimaryGroupIdForProfile(profile.id);
      if (existingPrimary != null && existingPrimary.isNotEmpty) {
        continue;
      }
      await setPrimaryGroupForProfile(
        profileId: profile.id,
        mlsGroupId: mlsGroupId,
      );
    }
  }

  Future<String?> getSetting(String key) async {
    final row = await (select(
      appSettings,
    )..where((tbl) => tbl.key.equals(key))).getSingleOrNull();
    return row?.value;
  }

  Stream<String?> watchSetting(String key) {
    return (select(appSettings)..where((tbl) => tbl.key.equals(key)))
        .watchSingleOrNull()
        .map((row) => row?.value);
  }

  Future<void> putSetting(String key, String value) {
    return into(appSettings).insertOnConflictUpdate(
      AppSettingsCompanion(
        key: Value(key),
        value: Value(value),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<void> clearAllData() {
    return transaction(() async {
      await delete(remotePlaybackMetrics).go();
      await delete(shareRecords).go();
      await delete(remoteAssets).go();
      await delete(likes).go();
      await delete(reactions).go();
      await delete(reports).go();
      await delete(moderationAuditLogs).go();
      await delete(profileGroups).go();
      await delete(localVideos).go();
      await delete(profiles).go();
      await delete(appSettings).go();
    });
  }

  Future<void> addModerationAuditLog({
    String? videoId,
    String? mlsGroupId,
    required String actionType,
    String? actorParentKey,
    String? subjectParentKey,
    String? detailsJson,
    DateTime? createdAt,
  }) {
    return into(moderationAuditLogs).insert(
      ModerationAuditLogsCompanion.insert(
        videoId: Value(videoId),
        mlsGroupId: Value(mlsGroupId),
        actionType: actionType,
        actorParentKey: Value(actorParentKey),
        subjectParentKey: Value(subjectParentKey),
        detailsJson: Value(detailsJson),
        createdAt: createdAt ?? DateTime.now(),
      ),
    );
  }

  Future<void> saveLocalVideo({
    required String videoId,
    required String profileId,
    required String filePath,
    String thumbPath = '',
    required String title,
    double durationSeconds = 0,
    List<String> tags = const <String>[],
    String approvalStatus = 'approved',
    DateTime? approvedAt,
    String? approvedByParentKey,
    String? scanResults,
    DateTime? scanCompletedAt,
  }) {
    return into(localVideos).insert(
      LocalVideosCompanion.insert(
        id: videoId,
        profileId: profileId,
        filePath: filePath,
        thumbPath: thumbPath,
        title: Value(title),
        durationSeconds: Value(durationSeconds),
        createdAt: DateTime.now(),
        tags: Value(tags),
        cvLabels: const Value(<String>[]),
        approvalStatus: Value(approvalStatus),
        approvedAt: Value(approvedAt),
        approvedByParentKey: Value(approvedByParentKey),
        scanResults: Value(scanResults),
        scanCompletedAt: Value(scanCompletedAt),
      ),
    );
  }

  Future<LocalVideo?> getLocalVideoById(String videoId) {
    return (select(
      localVideos,
    )..where((tbl) => tbl.id.equals(videoId))).getSingleOrNull();
  }

  Future<void> updateLocalVideoModeration({
    required String videoId,
    String? approvalStatus,
    DateTime? approvedAt,
    String? approvedByParentKey,
    String? scanResults,
    DateTime? scanCompletedAt,
    bool clearApproval = false,
  }) {
    return (update(localVideos)..where((tbl) => tbl.id.equals(videoId))).write(
      LocalVideosCompanion(
        approvalStatus: approvalStatus == null
            ? const Value.absent()
            : Value(approvalStatus),
        approvedAt: clearApproval
            ? const Value(null)
            : approvedAt == null
            ? const Value.absent()
            : Value(approvedAt),
        approvedByParentKey: clearApproval
            ? const Value(null)
            : approvedByParentKey == null
            ? const Value.absent()
            : Value(approvedByParentKey),
        scanResults: scanResults == null
            ? const Value.absent()
            : Value(scanResults),
        scanCompletedAt: scanCompletedAt == null
            ? const Value.absent()
            : Value(scanCompletedAt),
      ),
    );
  }

  Future<void> setLocalVideoLiked({
    required String videoId,
    required bool liked,
  }) {
    return (update(localVideos)..where((tbl) => tbl.id.equals(videoId))).write(
      LocalVideosCompanion(liked: Value(liked)),
    );
  }

  Future<void> recordLocalPlaybackSession({
    required String videoId,
    required double completionRatio,
    required bool replayed,
    DateTime? playedAt,
  }) async {
    final existing = await (select(
      localVideos,
    )..where((tbl) => tbl.id.equals(videoId))).getSingleOrNull();
    if (existing == null) {
      return;
    }

    await (update(localVideos)..where((tbl) => tbl.id.equals(videoId))).write(
      LocalVideosCompanion(
        lastPlayedAt: Value(playedAt ?? DateTime.now()),
        playCount: Value(existing.playCount + 1),
        completionRate: Value(
          _rollingAverage(
            previousAverage: existing.completionRate,
            previousCount: existing.playCount,
            nextValue: completionRatio.clamp(0.0, 1.0),
          ),
        ),
        replayRate: Value(
          _rollingAverage(
            previousAverage: existing.replayRate,
            previousCount: existing.playCount,
            nextValue: replayed ? 1.0 : 0.0,
          ),
        ),
      ),
    );
  }

  Future<LocalVideo?> getLatestLocalVideo({String? profileId}) async {
    final query = select(localVideos)
      ..where((tbl) => tbl.hidden.equals(false))
      ..orderBy([(t) => OrderingTerm.desc(t.createdAt)])
      ..limit(1);

    if (profileId != null) {
      query.where((tbl) => tbl.profileId.equals(profileId));
    }

    return query.getSingleOrNull();
  }

  Future<String> upsertRemoteShareProjection({
    required String videoId,
    required String mlsGroupId,
    required String senderParentKey,
    required String childProfileId,
    required String childDisplayName,
    required String blobHash,
    required String thumbHash,
    required String epoch,
    required String mime,
    required String metadataJson,
    DateTime? receivedAt,
    String status = 'available',
    String? localMediaPath,
    String? localThumbPath,
    String? downloadError,
  }) async {
    final received = receivedAt ?? DateTime.now();
    final remoteShareId = buildRemoteShareId(
      senderParentKey: senderParentKey,
      mlsGroupId: mlsGroupId,
      videoId: videoId,
    );

    await into(remoteAssets).insertOnConflictUpdate(
      RemoteAssetsCompanion(
        remoteShareId: Value(remoteShareId),
        videoId: Value(videoId),
        blobHash: Value(blobHash),
        thumbHash: Value(thumbHash),
        epoch: Value(epoch),
        mime: Value(mime),
        metadataJson: Value(metadataJson),
        localMediaPath: Value(localMediaPath),
        localThumbPath: Value(localThumbPath),
      ),
    );

    final existing =
        await (select(shareRecords)
              ..where((tbl) => tbl.remoteShareId.equals(remoteShareId)))
            .getSingleOrNull();

    if (existing == null) {
      await into(shareRecords).insert(
        ShareRecordsCompanion.insert(
          remoteShareId: remoteShareId,
          videoId: videoId,
          mlsGroupId: mlsGroupId,
          senderParentKey: senderParentKey,
          childProfileId: childProfileId,
          childDisplayName: Value(childDisplayName),
          status: Value(status),
          receivedAt: received,
          downloadError: Value(downloadError),
        ),
      );
      return remoteShareId;
    }

    await (update(
      shareRecords,
    )..where((tbl) => tbl.remoteShareId.equals(remoteShareId))).write(
      ShareRecordsCompanion(
        childDisplayName: Value(childDisplayName),
        status: Value(status),
        receivedAt: Value(received),
        downloadError: Value(downloadError),
      ),
    );
    return remoteShareId;
  }

  Future<RemoteAsset?> getRemoteAssetByRemoteShareId(String remoteShareId) {
    return (select(remoteAssets)
          ..where((tbl) => tbl.remoteShareId.equals(remoteShareId)))
        .getSingleOrNull();
  }

  Future<RemoteShareProjection?> getRemoteShareProjectionByRemoteShareId(
    String remoteShareId,
  ) {
    return watchRemoteShareProjectionByRemoteShareId(remoteShareId).first;
  }

  Future<void> updateRemoteAssetCache({
    required String remoteShareId,
    String? localMediaPath,
    String? localThumbPath,
  }) {
    return (update(
      remoteAssets,
    )..where((tbl) => tbl.remoteShareId.equals(remoteShareId))).write(
      RemoteAssetsCompanion(
        localMediaPath: localMediaPath == null
            ? const Value.absent()
            : Value(localMediaPath),
        localThumbPath: localThumbPath == null
            ? const Value.absent()
            : Value(localThumbPath),
      ),
    );
  }

  Future<void> clearRemoteMediaCachePath({required String remoteShareId}) {
    return (update(remoteAssets)
          ..where((tbl) => tbl.remoteShareId.equals(remoteShareId)))
        .write(const RemoteAssetsCompanion(localMediaPath: Value(null)));
  }

  Future<void> clearRemoteThumbCachePath({required String remoteShareId}) {
    return (update(remoteAssets)
          ..where((tbl) => tbl.remoteShareId.equals(remoteShareId)))
        .write(const RemoteAssetsCompanion(localThumbPath: Value(null)));
  }

  Future<void> updateRemoteShareStatus({
    required String remoteShareId,
    required String status,
    String? downloadError,
  }) {
    return (update(
      shareRecords,
    )..where((tbl) => tbl.remoteShareId.equals(remoteShareId))).write(
      ShareRecordsCompanion(
        status: Value(status),
        downloadError: Value(downloadError),
      ),
    );
  }

  Future<void> purgeRemoteAssetCache({required String remoteShareId}) {
    return (update(
      remoteAssets,
    )..where((tbl) => tbl.remoteShareId.equals(remoteShareId))).write(
      const RemoteAssetsCompanion(
        localMediaPath: Value(null),
        localThumbPath: Value(null),
      ),
    );
  }

  Future<void> markRemoteShareDeleted({
    required String remoteShareId,
    String? reason,
  }) {
    return (update(
      shareRecords,
    )..where((tbl) => tbl.remoteShareId.equals(remoteShareId))).write(
      ShareRecordsCompanion(
        status: const Value('deleted'),
        downloadError: Value(reason),
      ),
    );
  }

  Future<void> upsertLike({
    required String videoId,
    required String childProfileId,
    required String parentPubkey,
    DateTime? createdAt,
  }) async {
    final existing =
        await (select(likes)
              ..where(
                (tbl) =>
                    tbl.videoId.equals(videoId) &
                    tbl.childProfileId.equals(childProfileId) &
                    tbl.parentPubkey.equals(parentPubkey),
              )
              ..limit(1))
            .getSingleOrNull();

    if (existing == null) {
      await into(likes).insert(
        LikesCompanion.insert(
          videoId: videoId,
          childProfileId: childProfileId,
          parentPubkey: parentPubkey,
          createdAt: createdAt ?? DateTime.now(),
        ),
      );
      return;
    }

    await (update(likes)..where((tbl) => tbl.id.equals(existing.id))).write(
      LikesCompanion(createdAt: Value(createdAt ?? DateTime.now())),
    );
  }

  Future<void> upsertReaction({
    required String videoId,
    required String childProfileId,
    required String parentPubkey,
    required String emoji,
    DateTime? createdAt,
  }) async {
    final existing =
        await (select(reactions)
              ..where(
                (tbl) =>
                    tbl.videoId.equals(videoId) &
                    tbl.childProfileId.equals(childProfileId) &
                    tbl.parentPubkey.equals(parentPubkey) &
                    tbl.emoji.equals(emoji),
              )
              ..limit(1))
            .getSingleOrNull();

    if (existing == null) {
      await into(reactions).insert(
        ReactionsCompanion.insert(
          videoId: videoId,
          childProfileId: childProfileId,
          parentPubkey: parentPubkey,
          emoji: emoji,
          createdAt: createdAt ?? DateTime.now(),
        ),
      );
      return;
    }

    await (update(reactions)..where((tbl) => tbl.id.equals(existing.id))).write(
      ReactionsCompanion(createdAt: Value(createdAt ?? DateTime.now())),
    );
  }

  Future<void> recordRemotePlaybackSession({
    required String remoteShareId,
    required String videoId,
    required double completionRatio,
    required bool replayed,
    DateTime? playedAt,
  }) async {
    final existing =
        await (select(remotePlaybackMetrics)
              ..where((tbl) => tbl.remoteShareId.equals(remoteShareId)))
            .getSingleOrNull();
    final previousCount = existing?.playCount ?? 0;

    await into(remotePlaybackMetrics).insertOnConflictUpdate(
      RemotePlaybackMetricsCompanion(
        remoteShareId: Value(remoteShareId),
        videoId: Value(videoId),
        lastPlayedAt: Value(playedAt ?? DateTime.now()),
        playCount: Value(previousCount + 1),
        completionRate: Value(
          _rollingAverage(
            previousAverage: existing?.completionRate ?? 0,
            previousCount: previousCount,
            nextValue: completionRatio.clamp(0.0, 1.0),
          ),
        ),
        replayRate: Value(
          _rollingAverage(
            previousAverage: existing?.replayRate ?? 0,
            previousCount: previousCount,
            nextValue: replayed ? 1.0 : 0.0,
          ),
        ),
      ),
    );
  }

  Future<void> upsertReportRecord({
    required String reportId,
    required String videoId,
    required String subjectChildId,
    String? blobHash,
    required String reason,
    String? note,
    required int level,
    required String recipientType,
    String? reporterChildId,
    required String reporterParentKey,
    required bool isOutbound,
    required DateTime createdAt,
    String status = 'received',
    DateTime? deliveredAt,
  }) async {
    final existing =
        await (select(reports)
              ..where((tbl) => tbl.id.equals(reportId))
              ..limit(1))
            .getSingleOrNull();

    if (existing == null) {
      await into(reports).insert(
        ReportsCompanion.insert(
          id: reportId,
          videoId: videoId,
          subjectChildId: subjectChildId,
          blobHash: Value(blobHash),
          reason: reason,
          note: Value(note),
          level: Value(level),
          recipientType: Value(recipientType),
          reporterChildId: Value(reporterChildId),
          reporterParentKey: reporterParentKey,
          status: Value(status),
          isOutbound: Value(isOutbound),
          createdAt: createdAt,
          deliveredAt: deliveredAt == null
              ? const Value.absent()
              : Value(deliveredAt),
        ),
      );
      return;
    }

    await (update(reports)..where((tbl) => tbl.id.equals(reportId))).write(
      ReportsCompanion(
        videoId: Value(videoId),
        subjectChildId: Value(subjectChildId),
        blobHash: Value(blobHash),
        reason: Value(reason),
        note: Value(note),
        level: Value(level),
        recipientType: Value(recipientType),
        reporterChildId: Value(reporterChildId),
        reporterParentKey: Value(reporterParentKey),
        status: Value(status),
        isOutbound: Value(existing.isOutbound || isOutbound),
        createdAt: Value(createdAt),
        deliveredAt: deliveredAt == null
            ? const Value.absent()
            : Value(deliveredAt),
      ),
    );
  }

  RemoteShareProjection _mapRemoteShareProjection(TypedResult row) {
    final share = row.readTable(shareRecords);
    final asset = row.readTable(remoteAssets);

    return RemoteShareProjection(
      remoteShareId: share.remoteShareId,
      videoId: share.videoId,
      mlsGroupId: share.mlsGroupId,
      senderParentKey: share.senderParentKey,
      childProfileId: share.childProfileId,
      childDisplayName: share.childDisplayName,
      status: share.status,
      receivedAt: share.receivedAt,
      downloadError: share.downloadError,
      blobHash: asset.blobHash,
      thumbHash: asset.thumbHash,
      epoch: asset.epoch,
      mime: asset.mime,
      metadataJson: asset.metadataJson,
      localMediaPath: asset.localMediaPath,
      localThumbPath: asset.localThumbPath,
    );
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final root = await getApplicationDocumentsDirectory();
    final file = File(p.join(root.path, 'mytube.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}

double _rollingAverage({
  required double previousAverage,
  required int previousCount,
  required double nextValue,
}) {
  if (previousCount <= 0) {
    return nextValue;
  }
  return ((previousAverage * previousCount) + nextValue) / (previousCount + 1);
}
