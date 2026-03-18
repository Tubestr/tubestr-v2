// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $ProfilesTable extends Profiles with TableInfo<$ProfilesTable, Profile> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ProfilesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _themeMeta = const VerificationMeta('theme');
  @override
  late final GeneratedColumn<String> theme = GeneratedColumn<String>(
    'theme',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _avatarAssetMeta = const VerificationMeta(
    'avatarAsset',
  );
  @override
  late final GeneratedColumn<String> avatarAsset = GeneratedColumn<String>(
    'avatar_asset',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    theme,
    avatarAsset,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'profiles';
  @override
  VerificationContext validateIntegrity(
    Insertable<Profile> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('theme')) {
      context.handle(
        _themeMeta,
        theme.isAcceptableOrUnknown(data['theme']!, _themeMeta),
      );
    } else if (isInserting) {
      context.missing(_themeMeta);
    }
    if (data.containsKey('avatar_asset')) {
      context.handle(
        _avatarAssetMeta,
        avatarAsset.isAcceptableOrUnknown(
          data['avatar_asset']!,
          _avatarAssetMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Profile map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Profile(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      theme: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}theme'],
      )!,
      avatarAsset: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}avatar_asset'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $ProfilesTable createAlias(String alias) {
    return $ProfilesTable(attachedDatabase, alias);
  }
}

class Profile extends DataClass implements Insertable<Profile> {
  final String id;
  final String name;
  final String theme;
  final String? avatarAsset;
  final DateTime createdAt;
  final DateTime updatedAt;
  const Profile({
    required this.id,
    required this.name,
    required this.theme,
    this.avatarAsset,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['theme'] = Variable<String>(theme);
    if (!nullToAbsent || avatarAsset != null) {
      map['avatar_asset'] = Variable<String>(avatarAsset);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  ProfilesCompanion toCompanion(bool nullToAbsent) {
    return ProfilesCompanion(
      id: Value(id),
      name: Value(name),
      theme: Value(theme),
      avatarAsset: avatarAsset == null && nullToAbsent
          ? const Value.absent()
          : Value(avatarAsset),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory Profile.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Profile(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      theme: serializer.fromJson<String>(json['theme']),
      avatarAsset: serializer.fromJson<String?>(json['avatarAsset']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'theme': serializer.toJson<String>(theme),
      'avatarAsset': serializer.toJson<String?>(avatarAsset),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  Profile copyWith({
    String? id,
    String? name,
    String? theme,
    Value<String?> avatarAsset = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => Profile(
    id: id ?? this.id,
    name: name ?? this.name,
    theme: theme ?? this.theme,
    avatarAsset: avatarAsset.present ? avatarAsset.value : this.avatarAsset,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  Profile copyWithCompanion(ProfilesCompanion data) {
    return Profile(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      theme: data.theme.present ? data.theme.value : this.theme,
      avatarAsset: data.avatarAsset.present
          ? data.avatarAsset.value
          : this.avatarAsset,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Profile(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('theme: $theme, ')
          ..write('avatarAsset: $avatarAsset, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, name, theme, avatarAsset, createdAt, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Profile &&
          other.id == this.id &&
          other.name == this.name &&
          other.theme == this.theme &&
          other.avatarAsset == this.avatarAsset &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class ProfilesCompanion extends UpdateCompanion<Profile> {
  final Value<String> id;
  final Value<String> name;
  final Value<String> theme;
  final Value<String?> avatarAsset;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const ProfilesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.theme = const Value.absent(),
    this.avatarAsset = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ProfilesCompanion.insert({
    required String id,
    required String name,
    required String theme,
    this.avatarAsset = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       theme = Value(theme),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<Profile> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? theme,
    Expression<String>? avatarAsset,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (theme != null) 'theme': theme,
      if (avatarAsset != null) 'avatar_asset': avatarAsset,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ProfilesCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<String>? theme,
    Value<String?>? avatarAsset,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return ProfilesCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      theme: theme ?? this.theme,
      avatarAsset: avatarAsset ?? this.avatarAsset,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (theme.present) {
      map['theme'] = Variable<String>(theme.value);
    }
    if (avatarAsset.present) {
      map['avatar_asset'] = Variable<String>(avatarAsset.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ProfilesCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('theme: $theme, ')
          ..write('avatarAsset: $avatarAsset, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ProfileGroupsTable extends ProfileGroups
    with TableInfo<$ProfileGroupsTable, ProfileGroup> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ProfileGroupsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _profileIdMeta = const VerificationMeta(
    'profileId',
  );
  @override
  late final GeneratedColumn<String> profileId = GeneratedColumn<String>(
    'profile_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES profiles (id)',
    ),
  );
  static const VerificationMeta _mlsGroupIdMeta = const VerificationMeta(
    'mlsGroupId',
  );
  @override
  late final GeneratedColumn<String> mlsGroupId = GeneratedColumn<String>(
    'mls_group_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isPrimaryMeta = const VerificationMeta(
    'isPrimary',
  );
  @override
  late final GeneratedColumn<bool> isPrimary = GeneratedColumn<bool>(
    'is_primary',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_primary" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _joinedAtMeta = const VerificationMeta(
    'joinedAt',
  );
  @override
  late final GeneratedColumn<DateTime> joinedAt = GeneratedColumn<DateTime>(
    'joined_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    profileId,
    mlsGroupId,
    isPrimary,
    joinedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'profile_groups';
  @override
  VerificationContext validateIntegrity(
    Insertable<ProfileGroup> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('profile_id')) {
      context.handle(
        _profileIdMeta,
        profileId.isAcceptableOrUnknown(data['profile_id']!, _profileIdMeta),
      );
    } else if (isInserting) {
      context.missing(_profileIdMeta);
    }
    if (data.containsKey('mls_group_id')) {
      context.handle(
        _mlsGroupIdMeta,
        mlsGroupId.isAcceptableOrUnknown(
          data['mls_group_id']!,
          _mlsGroupIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_mlsGroupIdMeta);
    }
    if (data.containsKey('is_primary')) {
      context.handle(
        _isPrimaryMeta,
        isPrimary.isAcceptableOrUnknown(data['is_primary']!, _isPrimaryMeta),
      );
    }
    if (data.containsKey('joined_at')) {
      context.handle(
        _joinedAtMeta,
        joinedAt.isAcceptableOrUnknown(data['joined_at']!, _joinedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_joinedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ProfileGroup map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ProfileGroup(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      profileId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}profile_id'],
      )!,
      mlsGroupId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}mls_group_id'],
      )!,
      isPrimary: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_primary'],
      )!,
      joinedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}joined_at'],
      )!,
    );
  }

  @override
  $ProfileGroupsTable createAlias(String alias) {
    return $ProfileGroupsTable(attachedDatabase, alias);
  }
}

class ProfileGroup extends DataClass implements Insertable<ProfileGroup> {
  final int id;
  final String profileId;
  final String mlsGroupId;
  final bool isPrimary;
  final DateTime joinedAt;
  const ProfileGroup({
    required this.id,
    required this.profileId,
    required this.mlsGroupId,
    required this.isPrimary,
    required this.joinedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['profile_id'] = Variable<String>(profileId);
    map['mls_group_id'] = Variable<String>(mlsGroupId);
    map['is_primary'] = Variable<bool>(isPrimary);
    map['joined_at'] = Variable<DateTime>(joinedAt);
    return map;
  }

  ProfileGroupsCompanion toCompanion(bool nullToAbsent) {
    return ProfileGroupsCompanion(
      id: Value(id),
      profileId: Value(profileId),
      mlsGroupId: Value(mlsGroupId),
      isPrimary: Value(isPrimary),
      joinedAt: Value(joinedAt),
    );
  }

  factory ProfileGroup.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ProfileGroup(
      id: serializer.fromJson<int>(json['id']),
      profileId: serializer.fromJson<String>(json['profileId']),
      mlsGroupId: serializer.fromJson<String>(json['mlsGroupId']),
      isPrimary: serializer.fromJson<bool>(json['isPrimary']),
      joinedAt: serializer.fromJson<DateTime>(json['joinedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'profileId': serializer.toJson<String>(profileId),
      'mlsGroupId': serializer.toJson<String>(mlsGroupId),
      'isPrimary': serializer.toJson<bool>(isPrimary),
      'joinedAt': serializer.toJson<DateTime>(joinedAt),
    };
  }

  ProfileGroup copyWith({
    int? id,
    String? profileId,
    String? mlsGroupId,
    bool? isPrimary,
    DateTime? joinedAt,
  }) => ProfileGroup(
    id: id ?? this.id,
    profileId: profileId ?? this.profileId,
    mlsGroupId: mlsGroupId ?? this.mlsGroupId,
    isPrimary: isPrimary ?? this.isPrimary,
    joinedAt: joinedAt ?? this.joinedAt,
  );
  ProfileGroup copyWithCompanion(ProfileGroupsCompanion data) {
    return ProfileGroup(
      id: data.id.present ? data.id.value : this.id,
      profileId: data.profileId.present ? data.profileId.value : this.profileId,
      mlsGroupId: data.mlsGroupId.present
          ? data.mlsGroupId.value
          : this.mlsGroupId,
      isPrimary: data.isPrimary.present ? data.isPrimary.value : this.isPrimary,
      joinedAt: data.joinedAt.present ? data.joinedAt.value : this.joinedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ProfileGroup(')
          ..write('id: $id, ')
          ..write('profileId: $profileId, ')
          ..write('mlsGroupId: $mlsGroupId, ')
          ..write('isPrimary: $isPrimary, ')
          ..write('joinedAt: $joinedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, profileId, mlsGroupId, isPrimary, joinedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ProfileGroup &&
          other.id == this.id &&
          other.profileId == this.profileId &&
          other.mlsGroupId == this.mlsGroupId &&
          other.isPrimary == this.isPrimary &&
          other.joinedAt == this.joinedAt);
}

class ProfileGroupsCompanion extends UpdateCompanion<ProfileGroup> {
  final Value<int> id;
  final Value<String> profileId;
  final Value<String> mlsGroupId;
  final Value<bool> isPrimary;
  final Value<DateTime> joinedAt;
  const ProfileGroupsCompanion({
    this.id = const Value.absent(),
    this.profileId = const Value.absent(),
    this.mlsGroupId = const Value.absent(),
    this.isPrimary = const Value.absent(),
    this.joinedAt = const Value.absent(),
  });
  ProfileGroupsCompanion.insert({
    this.id = const Value.absent(),
    required String profileId,
    required String mlsGroupId,
    this.isPrimary = const Value.absent(),
    required DateTime joinedAt,
  }) : profileId = Value(profileId),
       mlsGroupId = Value(mlsGroupId),
       joinedAt = Value(joinedAt);
  static Insertable<ProfileGroup> custom({
    Expression<int>? id,
    Expression<String>? profileId,
    Expression<String>? mlsGroupId,
    Expression<bool>? isPrimary,
    Expression<DateTime>? joinedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (profileId != null) 'profile_id': profileId,
      if (mlsGroupId != null) 'mls_group_id': mlsGroupId,
      if (isPrimary != null) 'is_primary': isPrimary,
      if (joinedAt != null) 'joined_at': joinedAt,
    });
  }

  ProfileGroupsCompanion copyWith({
    Value<int>? id,
    Value<String>? profileId,
    Value<String>? mlsGroupId,
    Value<bool>? isPrimary,
    Value<DateTime>? joinedAt,
  }) {
    return ProfileGroupsCompanion(
      id: id ?? this.id,
      profileId: profileId ?? this.profileId,
      mlsGroupId: mlsGroupId ?? this.mlsGroupId,
      isPrimary: isPrimary ?? this.isPrimary,
      joinedAt: joinedAt ?? this.joinedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (profileId.present) {
      map['profile_id'] = Variable<String>(profileId.value);
    }
    if (mlsGroupId.present) {
      map['mls_group_id'] = Variable<String>(mlsGroupId.value);
    }
    if (isPrimary.present) {
      map['is_primary'] = Variable<bool>(isPrimary.value);
    }
    if (joinedAt.present) {
      map['joined_at'] = Variable<DateTime>(joinedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ProfileGroupsCompanion(')
          ..write('id: $id, ')
          ..write('profileId: $profileId, ')
          ..write('mlsGroupId: $mlsGroupId, ')
          ..write('isPrimary: $isPrimary, ')
          ..write('joinedAt: $joinedAt')
          ..write(')'))
        .toString();
  }
}

class $LocalVideosTable extends LocalVideos
    with TableInfo<$LocalVideosTable, LocalVideo> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalVideosTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _profileIdMeta = const VerificationMeta(
    'profileId',
  );
  @override
  late final GeneratedColumn<String> profileId = GeneratedColumn<String>(
    'profile_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES profiles (id)',
    ),
  );
  static const VerificationMeta _filePathMeta = const VerificationMeta(
    'filePath',
  );
  @override
  late final GeneratedColumn<String> filePath = GeneratedColumn<String>(
    'file_path',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _thumbPathMeta = const VerificationMeta(
    'thumbPath',
  );
  @override
  late final GeneratedColumn<String> thumbPath = GeneratedColumn<String>(
    'thumb_path',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('Untitled'),
  );
  static const VerificationMeta _durationSecondsMeta = const VerificationMeta(
    'durationSeconds',
  );
  @override
  late final GeneratedColumn<double> durationSeconds = GeneratedColumn<double>(
    'duration_seconds',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lastPlayedAtMeta = const VerificationMeta(
    'lastPlayedAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastPlayedAt = GeneratedColumn<DateTime>(
    'last_played_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _playCountMeta = const VerificationMeta(
    'playCount',
  );
  @override
  late final GeneratedColumn<int> playCount = GeneratedColumn<int>(
    'play_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _completionRateMeta = const VerificationMeta(
    'completionRate',
  );
  @override
  late final GeneratedColumn<double> completionRate = GeneratedColumn<double>(
    'completion_rate',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _replayRateMeta = const VerificationMeta(
    'replayRate',
  );
  @override
  late final GeneratedColumn<double> replayRate = GeneratedColumn<double>(
    'replay_rate',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _likedMeta = const VerificationMeta('liked');
  @override
  late final GeneratedColumn<bool> liked = GeneratedColumn<bool>(
    'liked',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("liked" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _hiddenMeta = const VerificationMeta('hidden');
  @override
  late final GeneratedColumn<bool> hidden = GeneratedColumn<bool>(
    'hidden',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("hidden" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  late final GeneratedColumnWithTypeConverter<List<String>, String> tags =
      GeneratedColumn<String>(
        'tags',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: const Constant('[]'),
      ).withConverter<List<String>>($LocalVideosTable.$convertertags);
  @override
  late final GeneratedColumnWithTypeConverter<List<String>, String> cvLabels =
      GeneratedColumn<String>(
        'cv_labels',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: const Constant('[]'),
      ).withConverter<List<String>>($LocalVideosTable.$convertercvLabels);
  static const VerificationMeta _faceCountMeta = const VerificationMeta(
    'faceCount',
  );
  @override
  late final GeneratedColumn<int> faceCount = GeneratedColumn<int>(
    'face_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _loudnessMeta = const VerificationMeta(
    'loudness',
  );
  @override
  late final GeneratedColumn<double> loudness = GeneratedColumn<double>(
    'loudness',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _reportedAtMeta = const VerificationMeta(
    'reportedAt',
  );
  @override
  late final GeneratedColumn<DateTime> reportedAt = GeneratedColumn<DateTime>(
    'reported_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _reportReasonMeta = const VerificationMeta(
    'reportReason',
  );
  @override
  late final GeneratedColumn<String> reportReason = GeneratedColumn<String>(
    'report_reason',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _approvalStatusMeta = const VerificationMeta(
    'approvalStatus',
  );
  @override
  late final GeneratedColumn<String> approvalStatus = GeneratedColumn<String>(
    'approval_status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('approved'),
  );
  static const VerificationMeta _approvedAtMeta = const VerificationMeta(
    'approvedAt',
  );
  @override
  late final GeneratedColumn<DateTime> approvedAt = GeneratedColumn<DateTime>(
    'approved_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _approvedByParentKeyMeta =
      const VerificationMeta('approvedByParentKey');
  @override
  late final GeneratedColumn<String> approvedByParentKey =
      GeneratedColumn<String>(
        'approved_by_parent_key',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _scanResultsMeta = const VerificationMeta(
    'scanResults',
  );
  @override
  late final GeneratedColumn<String> scanResults = GeneratedColumn<String>(
    'scan_results',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _scanCompletedAtMeta = const VerificationMeta(
    'scanCompletedAt',
  );
  @override
  late final GeneratedColumn<DateTime> scanCompletedAt =
      GeneratedColumn<DateTime>(
        'scan_completed_at',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _aspectRatioMeta = const VerificationMeta(
    'aspectRatio',
  );
  @override
  late final GeneratedColumn<double> aspectRatio = GeneratedColumn<double>(
    'aspect_ratio',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    profileId,
    filePath,
    thumbPath,
    title,
    durationSeconds,
    createdAt,
    lastPlayedAt,
    playCount,
    completionRate,
    replayRate,
    liked,
    hidden,
    tags,
    cvLabels,
    faceCount,
    loudness,
    reportedAt,
    reportReason,
    approvalStatus,
    approvedAt,
    approvedByParentKey,
    scanResults,
    scanCompletedAt,
    aspectRatio,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_videos';
  @override
  VerificationContext validateIntegrity(
    Insertable<LocalVideo> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('profile_id')) {
      context.handle(
        _profileIdMeta,
        profileId.isAcceptableOrUnknown(data['profile_id']!, _profileIdMeta),
      );
    } else if (isInserting) {
      context.missing(_profileIdMeta);
    }
    if (data.containsKey('file_path')) {
      context.handle(
        _filePathMeta,
        filePath.isAcceptableOrUnknown(data['file_path']!, _filePathMeta),
      );
    } else if (isInserting) {
      context.missing(_filePathMeta);
    }
    if (data.containsKey('thumb_path')) {
      context.handle(
        _thumbPathMeta,
        thumbPath.isAcceptableOrUnknown(data['thumb_path']!, _thumbPathMeta),
      );
    } else if (isInserting) {
      context.missing(_thumbPathMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    }
    if (data.containsKey('duration_seconds')) {
      context.handle(
        _durationSecondsMeta,
        durationSeconds.isAcceptableOrUnknown(
          data['duration_seconds']!,
          _durationSecondsMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('last_played_at')) {
      context.handle(
        _lastPlayedAtMeta,
        lastPlayedAt.isAcceptableOrUnknown(
          data['last_played_at']!,
          _lastPlayedAtMeta,
        ),
      );
    }
    if (data.containsKey('play_count')) {
      context.handle(
        _playCountMeta,
        playCount.isAcceptableOrUnknown(data['play_count']!, _playCountMeta),
      );
    }
    if (data.containsKey('completion_rate')) {
      context.handle(
        _completionRateMeta,
        completionRate.isAcceptableOrUnknown(
          data['completion_rate']!,
          _completionRateMeta,
        ),
      );
    }
    if (data.containsKey('replay_rate')) {
      context.handle(
        _replayRateMeta,
        replayRate.isAcceptableOrUnknown(data['replay_rate']!, _replayRateMeta),
      );
    }
    if (data.containsKey('liked')) {
      context.handle(
        _likedMeta,
        liked.isAcceptableOrUnknown(data['liked']!, _likedMeta),
      );
    }
    if (data.containsKey('hidden')) {
      context.handle(
        _hiddenMeta,
        hidden.isAcceptableOrUnknown(data['hidden']!, _hiddenMeta),
      );
    }
    if (data.containsKey('face_count')) {
      context.handle(
        _faceCountMeta,
        faceCount.isAcceptableOrUnknown(data['face_count']!, _faceCountMeta),
      );
    }
    if (data.containsKey('loudness')) {
      context.handle(
        _loudnessMeta,
        loudness.isAcceptableOrUnknown(data['loudness']!, _loudnessMeta),
      );
    }
    if (data.containsKey('reported_at')) {
      context.handle(
        _reportedAtMeta,
        reportedAt.isAcceptableOrUnknown(data['reported_at']!, _reportedAtMeta),
      );
    }
    if (data.containsKey('report_reason')) {
      context.handle(
        _reportReasonMeta,
        reportReason.isAcceptableOrUnknown(
          data['report_reason']!,
          _reportReasonMeta,
        ),
      );
    }
    if (data.containsKey('approval_status')) {
      context.handle(
        _approvalStatusMeta,
        approvalStatus.isAcceptableOrUnknown(
          data['approval_status']!,
          _approvalStatusMeta,
        ),
      );
    }
    if (data.containsKey('approved_at')) {
      context.handle(
        _approvedAtMeta,
        approvedAt.isAcceptableOrUnknown(data['approved_at']!, _approvedAtMeta),
      );
    }
    if (data.containsKey('approved_by_parent_key')) {
      context.handle(
        _approvedByParentKeyMeta,
        approvedByParentKey.isAcceptableOrUnknown(
          data['approved_by_parent_key']!,
          _approvedByParentKeyMeta,
        ),
      );
    }
    if (data.containsKey('scan_results')) {
      context.handle(
        _scanResultsMeta,
        scanResults.isAcceptableOrUnknown(
          data['scan_results']!,
          _scanResultsMeta,
        ),
      );
    }
    if (data.containsKey('scan_completed_at')) {
      context.handle(
        _scanCompletedAtMeta,
        scanCompletedAt.isAcceptableOrUnknown(
          data['scan_completed_at']!,
          _scanCompletedAtMeta,
        ),
      );
    }
    if (data.containsKey('aspect_ratio')) {
      context.handle(
        _aspectRatioMeta,
        aspectRatio.isAcceptableOrUnknown(
          data['aspect_ratio']!,
          _aspectRatioMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LocalVideo map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalVideo(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      profileId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}profile_id'],
      )!,
      filePath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}file_path'],
      )!,
      thumbPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}thumb_path'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      durationSeconds: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}duration_seconds'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      lastPlayedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_played_at'],
      ),
      playCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}play_count'],
      )!,
      completionRate: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}completion_rate'],
      )!,
      replayRate: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}replay_rate'],
      )!,
      liked: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}liked'],
      )!,
      hidden: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}hidden'],
      )!,
      tags: $LocalVideosTable.$convertertags.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}tags'],
        )!,
      ),
      cvLabels: $LocalVideosTable.$convertercvLabels.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}cv_labels'],
        )!,
      ),
      faceCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}face_count'],
      )!,
      loudness: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}loudness'],
      )!,
      reportedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}reported_at'],
      ),
      reportReason: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}report_reason'],
      ),
      approvalStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}approval_status'],
      )!,
      approvedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}approved_at'],
      ),
      approvedByParentKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}approved_by_parent_key'],
      ),
      scanResults: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}scan_results'],
      ),
      scanCompletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}scan_completed_at'],
      ),
      aspectRatio: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}aspect_ratio'],
      ),
    );
  }

  @override
  $LocalVideosTable createAlias(String alias) {
    return $LocalVideosTable(attachedDatabase, alias);
  }

  static TypeConverter<List<String>, String> $convertertags =
      const JsonStringListConverter();
  static TypeConverter<List<String>, String> $convertercvLabels =
      const JsonStringListConverter();
}

class LocalVideo extends DataClass implements Insertable<LocalVideo> {
  final String id;
  final String profileId;
  final String filePath;
  final String thumbPath;
  final String title;
  final double durationSeconds;
  final DateTime createdAt;
  final DateTime? lastPlayedAt;
  final int playCount;
  final double completionRate;
  final double replayRate;
  final bool liked;
  final bool hidden;
  final List<String> tags;
  final List<String> cvLabels;
  final int faceCount;
  final double loudness;
  final DateTime? reportedAt;
  final String? reportReason;
  final String approvalStatus;
  final DateTime? approvedAt;
  final String? approvedByParentKey;
  final String? scanResults;
  final DateTime? scanCompletedAt;
  final double? aspectRatio;
  const LocalVideo({
    required this.id,
    required this.profileId,
    required this.filePath,
    required this.thumbPath,
    required this.title,
    required this.durationSeconds,
    required this.createdAt,
    this.lastPlayedAt,
    required this.playCount,
    required this.completionRate,
    required this.replayRate,
    required this.liked,
    required this.hidden,
    required this.tags,
    required this.cvLabels,
    required this.faceCount,
    required this.loudness,
    this.reportedAt,
    this.reportReason,
    required this.approvalStatus,
    this.approvedAt,
    this.approvedByParentKey,
    this.scanResults,
    this.scanCompletedAt,
    this.aspectRatio,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['profile_id'] = Variable<String>(profileId);
    map['file_path'] = Variable<String>(filePath);
    map['thumb_path'] = Variable<String>(thumbPath);
    map['title'] = Variable<String>(title);
    map['duration_seconds'] = Variable<double>(durationSeconds);
    map['created_at'] = Variable<DateTime>(createdAt);
    if (!nullToAbsent || lastPlayedAt != null) {
      map['last_played_at'] = Variable<DateTime>(lastPlayedAt);
    }
    map['play_count'] = Variable<int>(playCount);
    map['completion_rate'] = Variable<double>(completionRate);
    map['replay_rate'] = Variable<double>(replayRate);
    map['liked'] = Variable<bool>(liked);
    map['hidden'] = Variable<bool>(hidden);
    {
      map['tags'] = Variable<String>(
        $LocalVideosTable.$convertertags.toSql(tags),
      );
    }
    {
      map['cv_labels'] = Variable<String>(
        $LocalVideosTable.$convertercvLabels.toSql(cvLabels),
      );
    }
    map['face_count'] = Variable<int>(faceCount);
    map['loudness'] = Variable<double>(loudness);
    if (!nullToAbsent || reportedAt != null) {
      map['reported_at'] = Variable<DateTime>(reportedAt);
    }
    if (!nullToAbsent || reportReason != null) {
      map['report_reason'] = Variable<String>(reportReason);
    }
    map['approval_status'] = Variable<String>(approvalStatus);
    if (!nullToAbsent || approvedAt != null) {
      map['approved_at'] = Variable<DateTime>(approvedAt);
    }
    if (!nullToAbsent || approvedByParentKey != null) {
      map['approved_by_parent_key'] = Variable<String>(approvedByParentKey);
    }
    if (!nullToAbsent || scanResults != null) {
      map['scan_results'] = Variable<String>(scanResults);
    }
    if (!nullToAbsent || scanCompletedAt != null) {
      map['scan_completed_at'] = Variable<DateTime>(scanCompletedAt);
    }
    if (!nullToAbsent || aspectRatio != null) {
      map['aspect_ratio'] = Variable<double>(aspectRatio);
    }
    return map;
  }

  LocalVideosCompanion toCompanion(bool nullToAbsent) {
    return LocalVideosCompanion(
      id: Value(id),
      profileId: Value(profileId),
      filePath: Value(filePath),
      thumbPath: Value(thumbPath),
      title: Value(title),
      durationSeconds: Value(durationSeconds),
      createdAt: Value(createdAt),
      lastPlayedAt: lastPlayedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastPlayedAt),
      playCount: Value(playCount),
      completionRate: Value(completionRate),
      replayRate: Value(replayRate),
      liked: Value(liked),
      hidden: Value(hidden),
      tags: Value(tags),
      cvLabels: Value(cvLabels),
      faceCount: Value(faceCount),
      loudness: Value(loudness),
      reportedAt: reportedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(reportedAt),
      reportReason: reportReason == null && nullToAbsent
          ? const Value.absent()
          : Value(reportReason),
      approvalStatus: Value(approvalStatus),
      approvedAt: approvedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(approvedAt),
      approvedByParentKey: approvedByParentKey == null && nullToAbsent
          ? const Value.absent()
          : Value(approvedByParentKey),
      scanResults: scanResults == null && nullToAbsent
          ? const Value.absent()
          : Value(scanResults),
      scanCompletedAt: scanCompletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(scanCompletedAt),
      aspectRatio: aspectRatio == null && nullToAbsent
          ? const Value.absent()
          : Value(aspectRatio),
    );
  }

  factory LocalVideo.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalVideo(
      id: serializer.fromJson<String>(json['id']),
      profileId: serializer.fromJson<String>(json['profileId']),
      filePath: serializer.fromJson<String>(json['filePath']),
      thumbPath: serializer.fromJson<String>(json['thumbPath']),
      title: serializer.fromJson<String>(json['title']),
      durationSeconds: serializer.fromJson<double>(json['durationSeconds']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      lastPlayedAt: serializer.fromJson<DateTime?>(json['lastPlayedAt']),
      playCount: serializer.fromJson<int>(json['playCount']),
      completionRate: serializer.fromJson<double>(json['completionRate']),
      replayRate: serializer.fromJson<double>(json['replayRate']),
      liked: serializer.fromJson<bool>(json['liked']),
      hidden: serializer.fromJson<bool>(json['hidden']),
      tags: serializer.fromJson<List<String>>(json['tags']),
      cvLabels: serializer.fromJson<List<String>>(json['cvLabels']),
      faceCount: serializer.fromJson<int>(json['faceCount']),
      loudness: serializer.fromJson<double>(json['loudness']),
      reportedAt: serializer.fromJson<DateTime?>(json['reportedAt']),
      reportReason: serializer.fromJson<String?>(json['reportReason']),
      approvalStatus: serializer.fromJson<String>(json['approvalStatus']),
      approvedAt: serializer.fromJson<DateTime?>(json['approvedAt']),
      approvedByParentKey: serializer.fromJson<String?>(
        json['approvedByParentKey'],
      ),
      scanResults: serializer.fromJson<String?>(json['scanResults']),
      scanCompletedAt: serializer.fromJson<DateTime?>(json['scanCompletedAt']),
      aspectRatio: serializer.fromJson<double?>(json['aspectRatio']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'profileId': serializer.toJson<String>(profileId),
      'filePath': serializer.toJson<String>(filePath),
      'thumbPath': serializer.toJson<String>(thumbPath),
      'title': serializer.toJson<String>(title),
      'durationSeconds': serializer.toJson<double>(durationSeconds),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'lastPlayedAt': serializer.toJson<DateTime?>(lastPlayedAt),
      'playCount': serializer.toJson<int>(playCount),
      'completionRate': serializer.toJson<double>(completionRate),
      'replayRate': serializer.toJson<double>(replayRate),
      'liked': serializer.toJson<bool>(liked),
      'hidden': serializer.toJson<bool>(hidden),
      'tags': serializer.toJson<List<String>>(tags),
      'cvLabels': serializer.toJson<List<String>>(cvLabels),
      'faceCount': serializer.toJson<int>(faceCount),
      'loudness': serializer.toJson<double>(loudness),
      'reportedAt': serializer.toJson<DateTime?>(reportedAt),
      'reportReason': serializer.toJson<String?>(reportReason),
      'approvalStatus': serializer.toJson<String>(approvalStatus),
      'approvedAt': serializer.toJson<DateTime?>(approvedAt),
      'approvedByParentKey': serializer.toJson<String?>(approvedByParentKey),
      'scanResults': serializer.toJson<String?>(scanResults),
      'scanCompletedAt': serializer.toJson<DateTime?>(scanCompletedAt),
      'aspectRatio': serializer.toJson<double?>(aspectRatio),
    };
  }

  LocalVideo copyWith({
    String? id,
    String? profileId,
    String? filePath,
    String? thumbPath,
    String? title,
    double? durationSeconds,
    DateTime? createdAt,
    Value<DateTime?> lastPlayedAt = const Value.absent(),
    int? playCount,
    double? completionRate,
    double? replayRate,
    bool? liked,
    bool? hidden,
    List<String>? tags,
    List<String>? cvLabels,
    int? faceCount,
    double? loudness,
    Value<DateTime?> reportedAt = const Value.absent(),
    Value<String?> reportReason = const Value.absent(),
    String? approvalStatus,
    Value<DateTime?> approvedAt = const Value.absent(),
    Value<String?> approvedByParentKey = const Value.absent(),
    Value<String?> scanResults = const Value.absent(),
    Value<DateTime?> scanCompletedAt = const Value.absent(),
    Value<double?> aspectRatio = const Value.absent(),
  }) => LocalVideo(
    id: id ?? this.id,
    profileId: profileId ?? this.profileId,
    filePath: filePath ?? this.filePath,
    thumbPath: thumbPath ?? this.thumbPath,
    title: title ?? this.title,
    durationSeconds: durationSeconds ?? this.durationSeconds,
    createdAt: createdAt ?? this.createdAt,
    lastPlayedAt: lastPlayedAt.present ? lastPlayedAt.value : this.lastPlayedAt,
    playCount: playCount ?? this.playCount,
    completionRate: completionRate ?? this.completionRate,
    replayRate: replayRate ?? this.replayRate,
    liked: liked ?? this.liked,
    hidden: hidden ?? this.hidden,
    tags: tags ?? this.tags,
    cvLabels: cvLabels ?? this.cvLabels,
    faceCount: faceCount ?? this.faceCount,
    loudness: loudness ?? this.loudness,
    reportedAt: reportedAt.present ? reportedAt.value : this.reportedAt,
    reportReason: reportReason.present ? reportReason.value : this.reportReason,
    approvalStatus: approvalStatus ?? this.approvalStatus,
    approvedAt: approvedAt.present ? approvedAt.value : this.approvedAt,
    approvedByParentKey: approvedByParentKey.present
        ? approvedByParentKey.value
        : this.approvedByParentKey,
    scanResults: scanResults.present ? scanResults.value : this.scanResults,
    scanCompletedAt: scanCompletedAt.present
        ? scanCompletedAt.value
        : this.scanCompletedAt,
    aspectRatio: aspectRatio.present ? aspectRatio.value : this.aspectRatio,
  );
  LocalVideo copyWithCompanion(LocalVideosCompanion data) {
    return LocalVideo(
      id: data.id.present ? data.id.value : this.id,
      profileId: data.profileId.present ? data.profileId.value : this.profileId,
      filePath: data.filePath.present ? data.filePath.value : this.filePath,
      thumbPath: data.thumbPath.present ? data.thumbPath.value : this.thumbPath,
      title: data.title.present ? data.title.value : this.title,
      durationSeconds: data.durationSeconds.present
          ? data.durationSeconds.value
          : this.durationSeconds,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      lastPlayedAt: data.lastPlayedAt.present
          ? data.lastPlayedAt.value
          : this.lastPlayedAt,
      playCount: data.playCount.present ? data.playCount.value : this.playCount,
      completionRate: data.completionRate.present
          ? data.completionRate.value
          : this.completionRate,
      replayRate: data.replayRate.present
          ? data.replayRate.value
          : this.replayRate,
      liked: data.liked.present ? data.liked.value : this.liked,
      hidden: data.hidden.present ? data.hidden.value : this.hidden,
      tags: data.tags.present ? data.tags.value : this.tags,
      cvLabels: data.cvLabels.present ? data.cvLabels.value : this.cvLabels,
      faceCount: data.faceCount.present ? data.faceCount.value : this.faceCount,
      loudness: data.loudness.present ? data.loudness.value : this.loudness,
      reportedAt: data.reportedAt.present
          ? data.reportedAt.value
          : this.reportedAt,
      reportReason: data.reportReason.present
          ? data.reportReason.value
          : this.reportReason,
      approvalStatus: data.approvalStatus.present
          ? data.approvalStatus.value
          : this.approvalStatus,
      approvedAt: data.approvedAt.present
          ? data.approvedAt.value
          : this.approvedAt,
      approvedByParentKey: data.approvedByParentKey.present
          ? data.approvedByParentKey.value
          : this.approvedByParentKey,
      scanResults: data.scanResults.present
          ? data.scanResults.value
          : this.scanResults,
      scanCompletedAt: data.scanCompletedAt.present
          ? data.scanCompletedAt.value
          : this.scanCompletedAt,
      aspectRatio: data.aspectRatio.present
          ? data.aspectRatio.value
          : this.aspectRatio,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalVideo(')
          ..write('id: $id, ')
          ..write('profileId: $profileId, ')
          ..write('filePath: $filePath, ')
          ..write('thumbPath: $thumbPath, ')
          ..write('title: $title, ')
          ..write('durationSeconds: $durationSeconds, ')
          ..write('createdAt: $createdAt, ')
          ..write('lastPlayedAt: $lastPlayedAt, ')
          ..write('playCount: $playCount, ')
          ..write('completionRate: $completionRate, ')
          ..write('replayRate: $replayRate, ')
          ..write('liked: $liked, ')
          ..write('hidden: $hidden, ')
          ..write('tags: $tags, ')
          ..write('cvLabels: $cvLabels, ')
          ..write('faceCount: $faceCount, ')
          ..write('loudness: $loudness, ')
          ..write('reportedAt: $reportedAt, ')
          ..write('reportReason: $reportReason, ')
          ..write('approvalStatus: $approvalStatus, ')
          ..write('approvedAt: $approvedAt, ')
          ..write('approvedByParentKey: $approvedByParentKey, ')
          ..write('scanResults: $scanResults, ')
          ..write('scanCompletedAt: $scanCompletedAt, ')
          ..write('aspectRatio: $aspectRatio')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
    id,
    profileId,
    filePath,
    thumbPath,
    title,
    durationSeconds,
    createdAt,
    lastPlayedAt,
    playCount,
    completionRate,
    replayRate,
    liked,
    hidden,
    tags,
    cvLabels,
    faceCount,
    loudness,
    reportedAt,
    reportReason,
    approvalStatus,
    approvedAt,
    approvedByParentKey,
    scanResults,
    scanCompletedAt,
    aspectRatio,
  ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalVideo &&
          other.id == this.id &&
          other.profileId == this.profileId &&
          other.filePath == this.filePath &&
          other.thumbPath == this.thumbPath &&
          other.title == this.title &&
          other.durationSeconds == this.durationSeconds &&
          other.createdAt == this.createdAt &&
          other.lastPlayedAt == this.lastPlayedAt &&
          other.playCount == this.playCount &&
          other.completionRate == this.completionRate &&
          other.replayRate == this.replayRate &&
          other.liked == this.liked &&
          other.hidden == this.hidden &&
          other.tags == this.tags &&
          other.cvLabels == this.cvLabels &&
          other.faceCount == this.faceCount &&
          other.loudness == this.loudness &&
          other.reportedAt == this.reportedAt &&
          other.reportReason == this.reportReason &&
          other.approvalStatus == this.approvalStatus &&
          other.approvedAt == this.approvedAt &&
          other.approvedByParentKey == this.approvedByParentKey &&
          other.scanResults == this.scanResults &&
          other.scanCompletedAt == this.scanCompletedAt &&
          other.aspectRatio == this.aspectRatio);
}

class LocalVideosCompanion extends UpdateCompanion<LocalVideo> {
  final Value<String> id;
  final Value<String> profileId;
  final Value<String> filePath;
  final Value<String> thumbPath;
  final Value<String> title;
  final Value<double> durationSeconds;
  final Value<DateTime> createdAt;
  final Value<DateTime?> lastPlayedAt;
  final Value<int> playCount;
  final Value<double> completionRate;
  final Value<double> replayRate;
  final Value<bool> liked;
  final Value<bool> hidden;
  final Value<List<String>> tags;
  final Value<List<String>> cvLabels;
  final Value<int> faceCount;
  final Value<double> loudness;
  final Value<DateTime?> reportedAt;
  final Value<String?> reportReason;
  final Value<String> approvalStatus;
  final Value<DateTime?> approvedAt;
  final Value<String?> approvedByParentKey;
  final Value<String?> scanResults;
  final Value<DateTime?> scanCompletedAt;
  final Value<double?> aspectRatio;
  final Value<int> rowid;
  const LocalVideosCompanion({
    this.id = const Value.absent(),
    this.profileId = const Value.absent(),
    this.filePath = const Value.absent(),
    this.thumbPath = const Value.absent(),
    this.title = const Value.absent(),
    this.durationSeconds = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.lastPlayedAt = const Value.absent(),
    this.playCount = const Value.absent(),
    this.completionRate = const Value.absent(),
    this.replayRate = const Value.absent(),
    this.liked = const Value.absent(),
    this.hidden = const Value.absent(),
    this.tags = const Value.absent(),
    this.cvLabels = const Value.absent(),
    this.faceCount = const Value.absent(),
    this.loudness = const Value.absent(),
    this.reportedAt = const Value.absent(),
    this.reportReason = const Value.absent(),
    this.approvalStatus = const Value.absent(),
    this.approvedAt = const Value.absent(),
    this.approvedByParentKey = const Value.absent(),
    this.scanResults = const Value.absent(),
    this.scanCompletedAt = const Value.absent(),
    this.aspectRatio = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalVideosCompanion.insert({
    required String id,
    required String profileId,
    required String filePath,
    required String thumbPath,
    this.title = const Value.absent(),
    this.durationSeconds = const Value.absent(),
    required DateTime createdAt,
    this.lastPlayedAt = const Value.absent(),
    this.playCount = const Value.absent(),
    this.completionRate = const Value.absent(),
    this.replayRate = const Value.absent(),
    this.liked = const Value.absent(),
    this.hidden = const Value.absent(),
    this.tags = const Value.absent(),
    this.cvLabels = const Value.absent(),
    this.faceCount = const Value.absent(),
    this.loudness = const Value.absent(),
    this.reportedAt = const Value.absent(),
    this.reportReason = const Value.absent(),
    this.approvalStatus = const Value.absent(),
    this.approvedAt = const Value.absent(),
    this.approvedByParentKey = const Value.absent(),
    this.scanResults = const Value.absent(),
    this.scanCompletedAt = const Value.absent(),
    this.aspectRatio = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       profileId = Value(profileId),
       filePath = Value(filePath),
       thumbPath = Value(thumbPath),
       createdAt = Value(createdAt);
  static Insertable<LocalVideo> custom({
    Expression<String>? id,
    Expression<String>? profileId,
    Expression<String>? filePath,
    Expression<String>? thumbPath,
    Expression<String>? title,
    Expression<double>? durationSeconds,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? lastPlayedAt,
    Expression<int>? playCount,
    Expression<double>? completionRate,
    Expression<double>? replayRate,
    Expression<bool>? liked,
    Expression<bool>? hidden,
    Expression<String>? tags,
    Expression<String>? cvLabels,
    Expression<int>? faceCount,
    Expression<double>? loudness,
    Expression<DateTime>? reportedAt,
    Expression<String>? reportReason,
    Expression<String>? approvalStatus,
    Expression<DateTime>? approvedAt,
    Expression<String>? approvedByParentKey,
    Expression<String>? scanResults,
    Expression<DateTime>? scanCompletedAt,
    Expression<double>? aspectRatio,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (profileId != null) 'profile_id': profileId,
      if (filePath != null) 'file_path': filePath,
      if (thumbPath != null) 'thumb_path': thumbPath,
      if (title != null) 'title': title,
      if (durationSeconds != null) 'duration_seconds': durationSeconds,
      if (createdAt != null) 'created_at': createdAt,
      if (lastPlayedAt != null) 'last_played_at': lastPlayedAt,
      if (playCount != null) 'play_count': playCount,
      if (completionRate != null) 'completion_rate': completionRate,
      if (replayRate != null) 'replay_rate': replayRate,
      if (liked != null) 'liked': liked,
      if (hidden != null) 'hidden': hidden,
      if (tags != null) 'tags': tags,
      if (cvLabels != null) 'cv_labels': cvLabels,
      if (faceCount != null) 'face_count': faceCount,
      if (loudness != null) 'loudness': loudness,
      if (reportedAt != null) 'reported_at': reportedAt,
      if (reportReason != null) 'report_reason': reportReason,
      if (approvalStatus != null) 'approval_status': approvalStatus,
      if (approvedAt != null) 'approved_at': approvedAt,
      if (approvedByParentKey != null)
        'approved_by_parent_key': approvedByParentKey,
      if (scanResults != null) 'scan_results': scanResults,
      if (scanCompletedAt != null) 'scan_completed_at': scanCompletedAt,
      if (aspectRatio != null) 'aspect_ratio': aspectRatio,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocalVideosCompanion copyWith({
    Value<String>? id,
    Value<String>? profileId,
    Value<String>? filePath,
    Value<String>? thumbPath,
    Value<String>? title,
    Value<double>? durationSeconds,
    Value<DateTime>? createdAt,
    Value<DateTime?>? lastPlayedAt,
    Value<int>? playCount,
    Value<double>? completionRate,
    Value<double>? replayRate,
    Value<bool>? liked,
    Value<bool>? hidden,
    Value<List<String>>? tags,
    Value<List<String>>? cvLabels,
    Value<int>? faceCount,
    Value<double>? loudness,
    Value<DateTime?>? reportedAt,
    Value<String?>? reportReason,
    Value<String>? approvalStatus,
    Value<DateTime?>? approvedAt,
    Value<String?>? approvedByParentKey,
    Value<String?>? scanResults,
    Value<DateTime?>? scanCompletedAt,
    Value<double?>? aspectRatio,
    Value<int>? rowid,
  }) {
    return LocalVideosCompanion(
      id: id ?? this.id,
      profileId: profileId ?? this.profileId,
      filePath: filePath ?? this.filePath,
      thumbPath: thumbPath ?? this.thumbPath,
      title: title ?? this.title,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      createdAt: createdAt ?? this.createdAt,
      lastPlayedAt: lastPlayedAt ?? this.lastPlayedAt,
      playCount: playCount ?? this.playCount,
      completionRate: completionRate ?? this.completionRate,
      replayRate: replayRate ?? this.replayRate,
      liked: liked ?? this.liked,
      hidden: hidden ?? this.hidden,
      tags: tags ?? this.tags,
      cvLabels: cvLabels ?? this.cvLabels,
      faceCount: faceCount ?? this.faceCount,
      loudness: loudness ?? this.loudness,
      reportedAt: reportedAt ?? this.reportedAt,
      reportReason: reportReason ?? this.reportReason,
      approvalStatus: approvalStatus ?? this.approvalStatus,
      approvedAt: approvedAt ?? this.approvedAt,
      approvedByParentKey: approvedByParentKey ?? this.approvedByParentKey,
      scanResults: scanResults ?? this.scanResults,
      scanCompletedAt: scanCompletedAt ?? this.scanCompletedAt,
      aspectRatio: aspectRatio ?? this.aspectRatio,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (profileId.present) {
      map['profile_id'] = Variable<String>(profileId.value);
    }
    if (filePath.present) {
      map['file_path'] = Variable<String>(filePath.value);
    }
    if (thumbPath.present) {
      map['thumb_path'] = Variable<String>(thumbPath.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (durationSeconds.present) {
      map['duration_seconds'] = Variable<double>(durationSeconds.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (lastPlayedAt.present) {
      map['last_played_at'] = Variable<DateTime>(lastPlayedAt.value);
    }
    if (playCount.present) {
      map['play_count'] = Variable<int>(playCount.value);
    }
    if (completionRate.present) {
      map['completion_rate'] = Variable<double>(completionRate.value);
    }
    if (replayRate.present) {
      map['replay_rate'] = Variable<double>(replayRate.value);
    }
    if (liked.present) {
      map['liked'] = Variable<bool>(liked.value);
    }
    if (hidden.present) {
      map['hidden'] = Variable<bool>(hidden.value);
    }
    if (tags.present) {
      map['tags'] = Variable<String>(
        $LocalVideosTable.$convertertags.toSql(tags.value),
      );
    }
    if (cvLabels.present) {
      map['cv_labels'] = Variable<String>(
        $LocalVideosTable.$convertercvLabels.toSql(cvLabels.value),
      );
    }
    if (faceCount.present) {
      map['face_count'] = Variable<int>(faceCount.value);
    }
    if (loudness.present) {
      map['loudness'] = Variable<double>(loudness.value);
    }
    if (reportedAt.present) {
      map['reported_at'] = Variable<DateTime>(reportedAt.value);
    }
    if (reportReason.present) {
      map['report_reason'] = Variable<String>(reportReason.value);
    }
    if (approvalStatus.present) {
      map['approval_status'] = Variable<String>(approvalStatus.value);
    }
    if (approvedAt.present) {
      map['approved_at'] = Variable<DateTime>(approvedAt.value);
    }
    if (approvedByParentKey.present) {
      map['approved_by_parent_key'] = Variable<String>(
        approvedByParentKey.value,
      );
    }
    if (scanResults.present) {
      map['scan_results'] = Variable<String>(scanResults.value);
    }
    if (scanCompletedAt.present) {
      map['scan_completed_at'] = Variable<DateTime>(scanCompletedAt.value);
    }
    if (aspectRatio.present) {
      map['aspect_ratio'] = Variable<double>(aspectRatio.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalVideosCompanion(')
          ..write('id: $id, ')
          ..write('profileId: $profileId, ')
          ..write('filePath: $filePath, ')
          ..write('thumbPath: $thumbPath, ')
          ..write('title: $title, ')
          ..write('durationSeconds: $durationSeconds, ')
          ..write('createdAt: $createdAt, ')
          ..write('lastPlayedAt: $lastPlayedAt, ')
          ..write('playCount: $playCount, ')
          ..write('completionRate: $completionRate, ')
          ..write('replayRate: $replayRate, ')
          ..write('liked: $liked, ')
          ..write('hidden: $hidden, ')
          ..write('tags: $tags, ')
          ..write('cvLabels: $cvLabels, ')
          ..write('faceCount: $faceCount, ')
          ..write('loudness: $loudness, ')
          ..write('reportedAt: $reportedAt, ')
          ..write('reportReason: $reportReason, ')
          ..write('approvalStatus: $approvalStatus, ')
          ..write('approvedAt: $approvedAt, ')
          ..write('approvedByParentKey: $approvedByParentKey, ')
          ..write('scanResults: $scanResults, ')
          ..write('scanCompletedAt: $scanCompletedAt, ')
          ..write('aspectRatio: $aspectRatio, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $RemoteAssetsTable extends RemoteAssets
    with TableInfo<$RemoteAssetsTable, RemoteAsset> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RemoteAssetsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _remoteShareIdMeta = const VerificationMeta(
    'remoteShareId',
  );
  @override
  late final GeneratedColumn<String> remoteShareId = GeneratedColumn<String>(
    'remote_share_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _videoIdMeta = const VerificationMeta(
    'videoId',
  );
  @override
  late final GeneratedColumn<String> videoId = GeneratedColumn<String>(
    'video_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _blobHashMeta = const VerificationMeta(
    'blobHash',
  );
  @override
  late final GeneratedColumn<String> blobHash = GeneratedColumn<String>(
    'blob_hash',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _thumbHashMeta = const VerificationMeta(
    'thumbHash',
  );
  @override
  late final GeneratedColumn<String> thumbHash = GeneratedColumn<String>(
    'thumb_hash',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _epochMeta = const VerificationMeta('epoch');
  @override
  late final GeneratedColumn<String> epoch = GeneratedColumn<String>(
    'epoch',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _mimeMeta = const VerificationMeta('mime');
  @override
  late final GeneratedColumn<String> mime = GeneratedColumn<String>(
    'mime',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _metadataJsonMeta = const VerificationMeta(
    'metadataJson',
  );
  @override
  late final GeneratedColumn<String> metadataJson = GeneratedColumn<String>(
    'metadata_json',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _localMediaPathMeta = const VerificationMeta(
    'localMediaPath',
  );
  @override
  late final GeneratedColumn<String> localMediaPath = GeneratedColumn<String>(
    'local_media_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _localThumbPathMeta = const VerificationMeta(
    'localThumbPath',
  );
  @override
  late final GeneratedColumn<String> localThumbPath = GeneratedColumn<String>(
    'local_thumb_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _aspectRatioMeta = const VerificationMeta(
    'aspectRatio',
  );
  @override
  late final GeneratedColumn<double> aspectRatio = GeneratedColumn<double>(
    'aspect_ratio',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    remoteShareId,
    videoId,
    blobHash,
    thumbHash,
    epoch,
    mime,
    metadataJson,
    localMediaPath,
    localThumbPath,
    aspectRatio,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'remote_assets';
  @override
  VerificationContext validateIntegrity(
    Insertable<RemoteAsset> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('remote_share_id')) {
      context.handle(
        _remoteShareIdMeta,
        remoteShareId.isAcceptableOrUnknown(
          data['remote_share_id']!,
          _remoteShareIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_remoteShareIdMeta);
    }
    if (data.containsKey('video_id')) {
      context.handle(
        _videoIdMeta,
        videoId.isAcceptableOrUnknown(data['video_id']!, _videoIdMeta),
      );
    } else if (isInserting) {
      context.missing(_videoIdMeta);
    }
    if (data.containsKey('blob_hash')) {
      context.handle(
        _blobHashMeta,
        blobHash.isAcceptableOrUnknown(data['blob_hash']!, _blobHashMeta),
      );
    }
    if (data.containsKey('thumb_hash')) {
      context.handle(
        _thumbHashMeta,
        thumbHash.isAcceptableOrUnknown(data['thumb_hash']!, _thumbHashMeta),
      );
    }
    if (data.containsKey('epoch')) {
      context.handle(
        _epochMeta,
        epoch.isAcceptableOrUnknown(data['epoch']!, _epochMeta),
      );
    }
    if (data.containsKey('mime')) {
      context.handle(
        _mimeMeta,
        mime.isAcceptableOrUnknown(data['mime']!, _mimeMeta),
      );
    }
    if (data.containsKey('metadata_json')) {
      context.handle(
        _metadataJsonMeta,
        metadataJson.isAcceptableOrUnknown(
          data['metadata_json']!,
          _metadataJsonMeta,
        ),
      );
    }
    if (data.containsKey('local_media_path')) {
      context.handle(
        _localMediaPathMeta,
        localMediaPath.isAcceptableOrUnknown(
          data['local_media_path']!,
          _localMediaPathMeta,
        ),
      );
    }
    if (data.containsKey('local_thumb_path')) {
      context.handle(
        _localThumbPathMeta,
        localThumbPath.isAcceptableOrUnknown(
          data['local_thumb_path']!,
          _localThumbPathMeta,
        ),
      );
    }
    if (data.containsKey('aspect_ratio')) {
      context.handle(
        _aspectRatioMeta,
        aspectRatio.isAcceptableOrUnknown(
          data['aspect_ratio']!,
          _aspectRatioMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {remoteShareId};
  @override
  RemoteAsset map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return RemoteAsset(
      remoteShareId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}remote_share_id'],
      )!,
      videoId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}video_id'],
      )!,
      blobHash: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}blob_hash'],
      ),
      thumbHash: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}thumb_hash'],
      ),
      epoch: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}epoch'],
      ),
      mime: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}mime'],
      ),
      metadataJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}metadata_json'],
      ),
      localMediaPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}local_media_path'],
      ),
      localThumbPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}local_thumb_path'],
      ),
      aspectRatio: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}aspect_ratio'],
      ),
    );
  }

  @override
  $RemoteAssetsTable createAlias(String alias) {
    return $RemoteAssetsTable(attachedDatabase, alias);
  }
}

class RemoteAsset extends DataClass implements Insertable<RemoteAsset> {
  final String remoteShareId;
  final String videoId;
  final String? blobHash;
  final String? thumbHash;
  final String? epoch;
  final String? mime;
  final String? metadataJson;
  final String? localMediaPath;
  final String? localThumbPath;
  final double? aspectRatio;
  const RemoteAsset({
    required this.remoteShareId,
    required this.videoId,
    this.blobHash,
    this.thumbHash,
    this.epoch,
    this.mime,
    this.metadataJson,
    this.localMediaPath,
    this.localThumbPath,
    this.aspectRatio,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['remote_share_id'] = Variable<String>(remoteShareId);
    map['video_id'] = Variable<String>(videoId);
    if (!nullToAbsent || blobHash != null) {
      map['blob_hash'] = Variable<String>(blobHash);
    }
    if (!nullToAbsent || thumbHash != null) {
      map['thumb_hash'] = Variable<String>(thumbHash);
    }
    if (!nullToAbsent || epoch != null) {
      map['epoch'] = Variable<String>(epoch);
    }
    if (!nullToAbsent || mime != null) {
      map['mime'] = Variable<String>(mime);
    }
    if (!nullToAbsent || metadataJson != null) {
      map['metadata_json'] = Variable<String>(metadataJson);
    }
    if (!nullToAbsent || localMediaPath != null) {
      map['local_media_path'] = Variable<String>(localMediaPath);
    }
    if (!nullToAbsent || localThumbPath != null) {
      map['local_thumb_path'] = Variable<String>(localThumbPath);
    }
    if (!nullToAbsent || aspectRatio != null) {
      map['aspect_ratio'] = Variable<double>(aspectRatio);
    }
    return map;
  }

  RemoteAssetsCompanion toCompanion(bool nullToAbsent) {
    return RemoteAssetsCompanion(
      remoteShareId: Value(remoteShareId),
      videoId: Value(videoId),
      blobHash: blobHash == null && nullToAbsent
          ? const Value.absent()
          : Value(blobHash),
      thumbHash: thumbHash == null && nullToAbsent
          ? const Value.absent()
          : Value(thumbHash),
      epoch: epoch == null && nullToAbsent
          ? const Value.absent()
          : Value(epoch),
      mime: mime == null && nullToAbsent ? const Value.absent() : Value(mime),
      metadataJson: metadataJson == null && nullToAbsent
          ? const Value.absent()
          : Value(metadataJson),
      localMediaPath: localMediaPath == null && nullToAbsent
          ? const Value.absent()
          : Value(localMediaPath),
      localThumbPath: localThumbPath == null && nullToAbsent
          ? const Value.absent()
          : Value(localThumbPath),
      aspectRatio: aspectRatio == null && nullToAbsent
          ? const Value.absent()
          : Value(aspectRatio),
    );
  }

  factory RemoteAsset.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return RemoteAsset(
      remoteShareId: serializer.fromJson<String>(json['remoteShareId']),
      videoId: serializer.fromJson<String>(json['videoId']),
      blobHash: serializer.fromJson<String?>(json['blobHash']),
      thumbHash: serializer.fromJson<String?>(json['thumbHash']),
      epoch: serializer.fromJson<String?>(json['epoch']),
      mime: serializer.fromJson<String?>(json['mime']),
      metadataJson: serializer.fromJson<String?>(json['metadataJson']),
      localMediaPath: serializer.fromJson<String?>(json['localMediaPath']),
      localThumbPath: serializer.fromJson<String?>(json['localThumbPath']),
      aspectRatio: serializer.fromJson<double?>(json['aspectRatio']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'remoteShareId': serializer.toJson<String>(remoteShareId),
      'videoId': serializer.toJson<String>(videoId),
      'blobHash': serializer.toJson<String?>(blobHash),
      'thumbHash': serializer.toJson<String?>(thumbHash),
      'epoch': serializer.toJson<String?>(epoch),
      'mime': serializer.toJson<String?>(mime),
      'metadataJson': serializer.toJson<String?>(metadataJson),
      'localMediaPath': serializer.toJson<String?>(localMediaPath),
      'localThumbPath': serializer.toJson<String?>(localThumbPath),
      'aspectRatio': serializer.toJson<double?>(aspectRatio),
    };
  }

  RemoteAsset copyWith({
    String? remoteShareId,
    String? videoId,
    Value<String?> blobHash = const Value.absent(),
    Value<String?> thumbHash = const Value.absent(),
    Value<String?> epoch = const Value.absent(),
    Value<String?> mime = const Value.absent(),
    Value<String?> metadataJson = const Value.absent(),
    Value<String?> localMediaPath = const Value.absent(),
    Value<String?> localThumbPath = const Value.absent(),
    Value<double?> aspectRatio = const Value.absent(),
  }) => RemoteAsset(
    remoteShareId: remoteShareId ?? this.remoteShareId,
    videoId: videoId ?? this.videoId,
    blobHash: blobHash.present ? blobHash.value : this.blobHash,
    thumbHash: thumbHash.present ? thumbHash.value : this.thumbHash,
    epoch: epoch.present ? epoch.value : this.epoch,
    mime: mime.present ? mime.value : this.mime,
    metadataJson: metadataJson.present ? metadataJson.value : this.metadataJson,
    localMediaPath: localMediaPath.present
        ? localMediaPath.value
        : this.localMediaPath,
    localThumbPath: localThumbPath.present
        ? localThumbPath.value
        : this.localThumbPath,
    aspectRatio: aspectRatio.present ? aspectRatio.value : this.aspectRatio,
  );
  RemoteAsset copyWithCompanion(RemoteAssetsCompanion data) {
    return RemoteAsset(
      remoteShareId: data.remoteShareId.present
          ? data.remoteShareId.value
          : this.remoteShareId,
      videoId: data.videoId.present ? data.videoId.value : this.videoId,
      blobHash: data.blobHash.present ? data.blobHash.value : this.blobHash,
      thumbHash: data.thumbHash.present ? data.thumbHash.value : this.thumbHash,
      epoch: data.epoch.present ? data.epoch.value : this.epoch,
      mime: data.mime.present ? data.mime.value : this.mime,
      metadataJson: data.metadataJson.present
          ? data.metadataJson.value
          : this.metadataJson,
      localMediaPath: data.localMediaPath.present
          ? data.localMediaPath.value
          : this.localMediaPath,
      localThumbPath: data.localThumbPath.present
          ? data.localThumbPath.value
          : this.localThumbPath,
      aspectRatio: data.aspectRatio.present
          ? data.aspectRatio.value
          : this.aspectRatio,
    );
  }

  @override
  String toString() {
    return (StringBuffer('RemoteAsset(')
          ..write('remoteShareId: $remoteShareId, ')
          ..write('videoId: $videoId, ')
          ..write('blobHash: $blobHash, ')
          ..write('thumbHash: $thumbHash, ')
          ..write('epoch: $epoch, ')
          ..write('mime: $mime, ')
          ..write('metadataJson: $metadataJson, ')
          ..write('localMediaPath: $localMediaPath, ')
          ..write('localThumbPath: $localThumbPath, ')
          ..write('aspectRatio: $aspectRatio')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    remoteShareId,
    videoId,
    blobHash,
    thumbHash,
    epoch,
    mime,
    metadataJson,
    localMediaPath,
    localThumbPath,
    aspectRatio,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RemoteAsset &&
          other.remoteShareId == this.remoteShareId &&
          other.videoId == this.videoId &&
          other.blobHash == this.blobHash &&
          other.thumbHash == this.thumbHash &&
          other.epoch == this.epoch &&
          other.mime == this.mime &&
          other.metadataJson == this.metadataJson &&
          other.localMediaPath == this.localMediaPath &&
          other.localThumbPath == this.localThumbPath &&
          other.aspectRatio == this.aspectRatio);
}

class RemoteAssetsCompanion extends UpdateCompanion<RemoteAsset> {
  final Value<String> remoteShareId;
  final Value<String> videoId;
  final Value<String?> blobHash;
  final Value<String?> thumbHash;
  final Value<String?> epoch;
  final Value<String?> mime;
  final Value<String?> metadataJson;
  final Value<String?> localMediaPath;
  final Value<String?> localThumbPath;
  final Value<double?> aspectRatio;
  final Value<int> rowid;
  const RemoteAssetsCompanion({
    this.remoteShareId = const Value.absent(),
    this.videoId = const Value.absent(),
    this.blobHash = const Value.absent(),
    this.thumbHash = const Value.absent(),
    this.epoch = const Value.absent(),
    this.mime = const Value.absent(),
    this.metadataJson = const Value.absent(),
    this.localMediaPath = const Value.absent(),
    this.localThumbPath = const Value.absent(),
    this.aspectRatio = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  RemoteAssetsCompanion.insert({
    required String remoteShareId,
    required String videoId,
    this.blobHash = const Value.absent(),
    this.thumbHash = const Value.absent(),
    this.epoch = const Value.absent(),
    this.mime = const Value.absent(),
    this.metadataJson = const Value.absent(),
    this.localMediaPath = const Value.absent(),
    this.localThumbPath = const Value.absent(),
    this.aspectRatio = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : remoteShareId = Value(remoteShareId),
       videoId = Value(videoId);
  static Insertable<RemoteAsset> custom({
    Expression<String>? remoteShareId,
    Expression<String>? videoId,
    Expression<String>? blobHash,
    Expression<String>? thumbHash,
    Expression<String>? epoch,
    Expression<String>? mime,
    Expression<String>? metadataJson,
    Expression<String>? localMediaPath,
    Expression<String>? localThumbPath,
    Expression<double>? aspectRatio,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (remoteShareId != null) 'remote_share_id': remoteShareId,
      if (videoId != null) 'video_id': videoId,
      if (blobHash != null) 'blob_hash': blobHash,
      if (thumbHash != null) 'thumb_hash': thumbHash,
      if (epoch != null) 'epoch': epoch,
      if (mime != null) 'mime': mime,
      if (metadataJson != null) 'metadata_json': metadataJson,
      if (localMediaPath != null) 'local_media_path': localMediaPath,
      if (localThumbPath != null) 'local_thumb_path': localThumbPath,
      if (aspectRatio != null) 'aspect_ratio': aspectRatio,
      if (rowid != null) 'rowid': rowid,
    });
  }

  RemoteAssetsCompanion copyWith({
    Value<String>? remoteShareId,
    Value<String>? videoId,
    Value<String?>? blobHash,
    Value<String?>? thumbHash,
    Value<String?>? epoch,
    Value<String?>? mime,
    Value<String?>? metadataJson,
    Value<String?>? localMediaPath,
    Value<String?>? localThumbPath,
    Value<double?>? aspectRatio,
    Value<int>? rowid,
  }) {
    return RemoteAssetsCompanion(
      remoteShareId: remoteShareId ?? this.remoteShareId,
      videoId: videoId ?? this.videoId,
      blobHash: blobHash ?? this.blobHash,
      thumbHash: thumbHash ?? this.thumbHash,
      epoch: epoch ?? this.epoch,
      mime: mime ?? this.mime,
      metadataJson: metadataJson ?? this.metadataJson,
      localMediaPath: localMediaPath ?? this.localMediaPath,
      localThumbPath: localThumbPath ?? this.localThumbPath,
      aspectRatio: aspectRatio ?? this.aspectRatio,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (remoteShareId.present) {
      map['remote_share_id'] = Variable<String>(remoteShareId.value);
    }
    if (videoId.present) {
      map['video_id'] = Variable<String>(videoId.value);
    }
    if (blobHash.present) {
      map['blob_hash'] = Variable<String>(blobHash.value);
    }
    if (thumbHash.present) {
      map['thumb_hash'] = Variable<String>(thumbHash.value);
    }
    if (epoch.present) {
      map['epoch'] = Variable<String>(epoch.value);
    }
    if (mime.present) {
      map['mime'] = Variable<String>(mime.value);
    }
    if (metadataJson.present) {
      map['metadata_json'] = Variable<String>(metadataJson.value);
    }
    if (localMediaPath.present) {
      map['local_media_path'] = Variable<String>(localMediaPath.value);
    }
    if (localThumbPath.present) {
      map['local_thumb_path'] = Variable<String>(localThumbPath.value);
    }
    if (aspectRatio.present) {
      map['aspect_ratio'] = Variable<double>(aspectRatio.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RemoteAssetsCompanion(')
          ..write('remoteShareId: $remoteShareId, ')
          ..write('videoId: $videoId, ')
          ..write('blobHash: $blobHash, ')
          ..write('thumbHash: $thumbHash, ')
          ..write('epoch: $epoch, ')
          ..write('mime: $mime, ')
          ..write('metadataJson: $metadataJson, ')
          ..write('localMediaPath: $localMediaPath, ')
          ..write('localThumbPath: $localThumbPath, ')
          ..write('aspectRatio: $aspectRatio, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ShareRecordsTable extends ShareRecords
    with TableInfo<$ShareRecordsTable, ShareRecord> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ShareRecordsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _remoteShareIdMeta = const VerificationMeta(
    'remoteShareId',
  );
  @override
  late final GeneratedColumn<String> remoteShareId = GeneratedColumn<String>(
    'remote_share_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES remote_assets (remote_share_id)',
    ),
  );
  static const VerificationMeta _videoIdMeta = const VerificationMeta(
    'videoId',
  );
  @override
  late final GeneratedColumn<String> videoId = GeneratedColumn<String>(
    'video_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _mlsGroupIdMeta = const VerificationMeta(
    'mlsGroupId',
  );
  @override
  late final GeneratedColumn<String> mlsGroupId = GeneratedColumn<String>(
    'mls_group_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _senderParentKeyMeta = const VerificationMeta(
    'senderParentKey',
  );
  @override
  late final GeneratedColumn<String> senderParentKey = GeneratedColumn<String>(
    'sender_parent_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _childProfileIdMeta = const VerificationMeta(
    'childProfileId',
  );
  @override
  late final GeneratedColumn<String> childProfileId = GeneratedColumn<String>(
    'child_profile_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _childDisplayNameMeta = const VerificationMeta(
    'childDisplayName',
  );
  @override
  late final GeneratedColumn<String> childDisplayName = GeneratedColumn<String>(
    'child_display_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('available'),
  );
  static const VerificationMeta _receivedAtMeta = const VerificationMeta(
    'receivedAt',
  );
  @override
  late final GeneratedColumn<DateTime> receivedAt = GeneratedColumn<DateTime>(
    'received_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _downloadErrorMeta = const VerificationMeta(
    'downloadError',
  );
  @override
  late final GeneratedColumn<String> downloadError = GeneratedColumn<String>(
    'download_error',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    remoteShareId,
    videoId,
    mlsGroupId,
    senderParentKey,
    childProfileId,
    childDisplayName,
    status,
    receivedAt,
    downloadError,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'share_records';
  @override
  VerificationContext validateIntegrity(
    Insertable<ShareRecord> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('remote_share_id')) {
      context.handle(
        _remoteShareIdMeta,
        remoteShareId.isAcceptableOrUnknown(
          data['remote_share_id']!,
          _remoteShareIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_remoteShareIdMeta);
    }
    if (data.containsKey('video_id')) {
      context.handle(
        _videoIdMeta,
        videoId.isAcceptableOrUnknown(data['video_id']!, _videoIdMeta),
      );
    } else if (isInserting) {
      context.missing(_videoIdMeta);
    }
    if (data.containsKey('mls_group_id')) {
      context.handle(
        _mlsGroupIdMeta,
        mlsGroupId.isAcceptableOrUnknown(
          data['mls_group_id']!,
          _mlsGroupIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_mlsGroupIdMeta);
    }
    if (data.containsKey('sender_parent_key')) {
      context.handle(
        _senderParentKeyMeta,
        senderParentKey.isAcceptableOrUnknown(
          data['sender_parent_key']!,
          _senderParentKeyMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_senderParentKeyMeta);
    }
    if (data.containsKey('child_profile_id')) {
      context.handle(
        _childProfileIdMeta,
        childProfileId.isAcceptableOrUnknown(
          data['child_profile_id']!,
          _childProfileIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_childProfileIdMeta);
    }
    if (data.containsKey('child_display_name')) {
      context.handle(
        _childDisplayNameMeta,
        childDisplayName.isAcceptableOrUnknown(
          data['child_display_name']!,
          _childDisplayNameMeta,
        ),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('received_at')) {
      context.handle(
        _receivedAtMeta,
        receivedAt.isAcceptableOrUnknown(data['received_at']!, _receivedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_receivedAtMeta);
    }
    if (data.containsKey('download_error')) {
      context.handle(
        _downloadErrorMeta,
        downloadError.isAcceptableOrUnknown(
          data['download_error']!,
          _downloadErrorMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {remoteShareId};
  @override
  ShareRecord map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ShareRecord(
      remoteShareId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}remote_share_id'],
      )!,
      videoId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}video_id'],
      )!,
      mlsGroupId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}mls_group_id'],
      )!,
      senderParentKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sender_parent_key'],
      )!,
      childProfileId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}child_profile_id'],
      )!,
      childDisplayName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}child_display_name'],
      ),
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      receivedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}received_at'],
      )!,
      downloadError: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}download_error'],
      ),
    );
  }

  @override
  $ShareRecordsTable createAlias(String alias) {
    return $ShareRecordsTable(attachedDatabase, alias);
  }
}

class ShareRecord extends DataClass implements Insertable<ShareRecord> {
  final String remoteShareId;
  final String videoId;
  final String mlsGroupId;
  final String senderParentKey;
  final String childProfileId;
  final String? childDisplayName;
  final String status;
  final DateTime receivedAt;
  final String? downloadError;
  const ShareRecord({
    required this.remoteShareId,
    required this.videoId,
    required this.mlsGroupId,
    required this.senderParentKey,
    required this.childProfileId,
    this.childDisplayName,
    required this.status,
    required this.receivedAt,
    this.downloadError,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['remote_share_id'] = Variable<String>(remoteShareId);
    map['video_id'] = Variable<String>(videoId);
    map['mls_group_id'] = Variable<String>(mlsGroupId);
    map['sender_parent_key'] = Variable<String>(senderParentKey);
    map['child_profile_id'] = Variable<String>(childProfileId);
    if (!nullToAbsent || childDisplayName != null) {
      map['child_display_name'] = Variable<String>(childDisplayName);
    }
    map['status'] = Variable<String>(status);
    map['received_at'] = Variable<DateTime>(receivedAt);
    if (!nullToAbsent || downloadError != null) {
      map['download_error'] = Variable<String>(downloadError);
    }
    return map;
  }

  ShareRecordsCompanion toCompanion(bool nullToAbsent) {
    return ShareRecordsCompanion(
      remoteShareId: Value(remoteShareId),
      videoId: Value(videoId),
      mlsGroupId: Value(mlsGroupId),
      senderParentKey: Value(senderParentKey),
      childProfileId: Value(childProfileId),
      childDisplayName: childDisplayName == null && nullToAbsent
          ? const Value.absent()
          : Value(childDisplayName),
      status: Value(status),
      receivedAt: Value(receivedAt),
      downloadError: downloadError == null && nullToAbsent
          ? const Value.absent()
          : Value(downloadError),
    );
  }

  factory ShareRecord.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ShareRecord(
      remoteShareId: serializer.fromJson<String>(json['remoteShareId']),
      videoId: serializer.fromJson<String>(json['videoId']),
      mlsGroupId: serializer.fromJson<String>(json['mlsGroupId']),
      senderParentKey: serializer.fromJson<String>(json['senderParentKey']),
      childProfileId: serializer.fromJson<String>(json['childProfileId']),
      childDisplayName: serializer.fromJson<String?>(json['childDisplayName']),
      status: serializer.fromJson<String>(json['status']),
      receivedAt: serializer.fromJson<DateTime>(json['receivedAt']),
      downloadError: serializer.fromJson<String?>(json['downloadError']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'remoteShareId': serializer.toJson<String>(remoteShareId),
      'videoId': serializer.toJson<String>(videoId),
      'mlsGroupId': serializer.toJson<String>(mlsGroupId),
      'senderParentKey': serializer.toJson<String>(senderParentKey),
      'childProfileId': serializer.toJson<String>(childProfileId),
      'childDisplayName': serializer.toJson<String?>(childDisplayName),
      'status': serializer.toJson<String>(status),
      'receivedAt': serializer.toJson<DateTime>(receivedAt),
      'downloadError': serializer.toJson<String?>(downloadError),
    };
  }

  ShareRecord copyWith({
    String? remoteShareId,
    String? videoId,
    String? mlsGroupId,
    String? senderParentKey,
    String? childProfileId,
    Value<String?> childDisplayName = const Value.absent(),
    String? status,
    DateTime? receivedAt,
    Value<String?> downloadError = const Value.absent(),
  }) => ShareRecord(
    remoteShareId: remoteShareId ?? this.remoteShareId,
    videoId: videoId ?? this.videoId,
    mlsGroupId: mlsGroupId ?? this.mlsGroupId,
    senderParentKey: senderParentKey ?? this.senderParentKey,
    childProfileId: childProfileId ?? this.childProfileId,
    childDisplayName: childDisplayName.present
        ? childDisplayName.value
        : this.childDisplayName,
    status: status ?? this.status,
    receivedAt: receivedAt ?? this.receivedAt,
    downloadError: downloadError.present
        ? downloadError.value
        : this.downloadError,
  );
  ShareRecord copyWithCompanion(ShareRecordsCompanion data) {
    return ShareRecord(
      remoteShareId: data.remoteShareId.present
          ? data.remoteShareId.value
          : this.remoteShareId,
      videoId: data.videoId.present ? data.videoId.value : this.videoId,
      mlsGroupId: data.mlsGroupId.present
          ? data.mlsGroupId.value
          : this.mlsGroupId,
      senderParentKey: data.senderParentKey.present
          ? data.senderParentKey.value
          : this.senderParentKey,
      childProfileId: data.childProfileId.present
          ? data.childProfileId.value
          : this.childProfileId,
      childDisplayName: data.childDisplayName.present
          ? data.childDisplayName.value
          : this.childDisplayName,
      status: data.status.present ? data.status.value : this.status,
      receivedAt: data.receivedAt.present
          ? data.receivedAt.value
          : this.receivedAt,
      downloadError: data.downloadError.present
          ? data.downloadError.value
          : this.downloadError,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ShareRecord(')
          ..write('remoteShareId: $remoteShareId, ')
          ..write('videoId: $videoId, ')
          ..write('mlsGroupId: $mlsGroupId, ')
          ..write('senderParentKey: $senderParentKey, ')
          ..write('childProfileId: $childProfileId, ')
          ..write('childDisplayName: $childDisplayName, ')
          ..write('status: $status, ')
          ..write('receivedAt: $receivedAt, ')
          ..write('downloadError: $downloadError')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    remoteShareId,
    videoId,
    mlsGroupId,
    senderParentKey,
    childProfileId,
    childDisplayName,
    status,
    receivedAt,
    downloadError,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ShareRecord &&
          other.remoteShareId == this.remoteShareId &&
          other.videoId == this.videoId &&
          other.mlsGroupId == this.mlsGroupId &&
          other.senderParentKey == this.senderParentKey &&
          other.childProfileId == this.childProfileId &&
          other.childDisplayName == this.childDisplayName &&
          other.status == this.status &&
          other.receivedAt == this.receivedAt &&
          other.downloadError == this.downloadError);
}

class ShareRecordsCompanion extends UpdateCompanion<ShareRecord> {
  final Value<String> remoteShareId;
  final Value<String> videoId;
  final Value<String> mlsGroupId;
  final Value<String> senderParentKey;
  final Value<String> childProfileId;
  final Value<String?> childDisplayName;
  final Value<String> status;
  final Value<DateTime> receivedAt;
  final Value<String?> downloadError;
  final Value<int> rowid;
  const ShareRecordsCompanion({
    this.remoteShareId = const Value.absent(),
    this.videoId = const Value.absent(),
    this.mlsGroupId = const Value.absent(),
    this.senderParentKey = const Value.absent(),
    this.childProfileId = const Value.absent(),
    this.childDisplayName = const Value.absent(),
    this.status = const Value.absent(),
    this.receivedAt = const Value.absent(),
    this.downloadError = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ShareRecordsCompanion.insert({
    required String remoteShareId,
    required String videoId,
    required String mlsGroupId,
    required String senderParentKey,
    required String childProfileId,
    this.childDisplayName = const Value.absent(),
    this.status = const Value.absent(),
    required DateTime receivedAt,
    this.downloadError = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : remoteShareId = Value(remoteShareId),
       videoId = Value(videoId),
       mlsGroupId = Value(mlsGroupId),
       senderParentKey = Value(senderParentKey),
       childProfileId = Value(childProfileId),
       receivedAt = Value(receivedAt);
  static Insertable<ShareRecord> custom({
    Expression<String>? remoteShareId,
    Expression<String>? videoId,
    Expression<String>? mlsGroupId,
    Expression<String>? senderParentKey,
    Expression<String>? childProfileId,
    Expression<String>? childDisplayName,
    Expression<String>? status,
    Expression<DateTime>? receivedAt,
    Expression<String>? downloadError,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (remoteShareId != null) 'remote_share_id': remoteShareId,
      if (videoId != null) 'video_id': videoId,
      if (mlsGroupId != null) 'mls_group_id': mlsGroupId,
      if (senderParentKey != null) 'sender_parent_key': senderParentKey,
      if (childProfileId != null) 'child_profile_id': childProfileId,
      if (childDisplayName != null) 'child_display_name': childDisplayName,
      if (status != null) 'status': status,
      if (receivedAt != null) 'received_at': receivedAt,
      if (downloadError != null) 'download_error': downloadError,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ShareRecordsCompanion copyWith({
    Value<String>? remoteShareId,
    Value<String>? videoId,
    Value<String>? mlsGroupId,
    Value<String>? senderParentKey,
    Value<String>? childProfileId,
    Value<String?>? childDisplayName,
    Value<String>? status,
    Value<DateTime>? receivedAt,
    Value<String?>? downloadError,
    Value<int>? rowid,
  }) {
    return ShareRecordsCompanion(
      remoteShareId: remoteShareId ?? this.remoteShareId,
      videoId: videoId ?? this.videoId,
      mlsGroupId: mlsGroupId ?? this.mlsGroupId,
      senderParentKey: senderParentKey ?? this.senderParentKey,
      childProfileId: childProfileId ?? this.childProfileId,
      childDisplayName: childDisplayName ?? this.childDisplayName,
      status: status ?? this.status,
      receivedAt: receivedAt ?? this.receivedAt,
      downloadError: downloadError ?? this.downloadError,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (remoteShareId.present) {
      map['remote_share_id'] = Variable<String>(remoteShareId.value);
    }
    if (videoId.present) {
      map['video_id'] = Variable<String>(videoId.value);
    }
    if (mlsGroupId.present) {
      map['mls_group_id'] = Variable<String>(mlsGroupId.value);
    }
    if (senderParentKey.present) {
      map['sender_parent_key'] = Variable<String>(senderParentKey.value);
    }
    if (childProfileId.present) {
      map['child_profile_id'] = Variable<String>(childProfileId.value);
    }
    if (childDisplayName.present) {
      map['child_display_name'] = Variable<String>(childDisplayName.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (receivedAt.present) {
      map['received_at'] = Variable<DateTime>(receivedAt.value);
    }
    if (downloadError.present) {
      map['download_error'] = Variable<String>(downloadError.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ShareRecordsCompanion(')
          ..write('remoteShareId: $remoteShareId, ')
          ..write('videoId: $videoId, ')
          ..write('mlsGroupId: $mlsGroupId, ')
          ..write('senderParentKey: $senderParentKey, ')
          ..write('childProfileId: $childProfileId, ')
          ..write('childDisplayName: $childDisplayName, ')
          ..write('status: $status, ')
          ..write('receivedAt: $receivedAt, ')
          ..write('downloadError: $downloadError, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LikesTable extends Likes with TableInfo<$LikesTable, Like> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LikesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _videoIdMeta = const VerificationMeta(
    'videoId',
  );
  @override
  late final GeneratedColumn<String> videoId = GeneratedColumn<String>(
    'video_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _childProfileIdMeta = const VerificationMeta(
    'childProfileId',
  );
  @override
  late final GeneratedColumn<String> childProfileId = GeneratedColumn<String>(
    'child_profile_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _parentPubkeyMeta = const VerificationMeta(
    'parentPubkey',
  );
  @override
  late final GeneratedColumn<String> parentPubkey = GeneratedColumn<String>(
    'parent_pubkey',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    videoId,
    childProfileId,
    parentPubkey,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'likes';
  @override
  VerificationContext validateIntegrity(
    Insertable<Like> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('video_id')) {
      context.handle(
        _videoIdMeta,
        videoId.isAcceptableOrUnknown(data['video_id']!, _videoIdMeta),
      );
    } else if (isInserting) {
      context.missing(_videoIdMeta);
    }
    if (data.containsKey('child_profile_id')) {
      context.handle(
        _childProfileIdMeta,
        childProfileId.isAcceptableOrUnknown(
          data['child_profile_id']!,
          _childProfileIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_childProfileIdMeta);
    }
    if (data.containsKey('parent_pubkey')) {
      context.handle(
        _parentPubkeyMeta,
        parentPubkey.isAcceptableOrUnknown(
          data['parent_pubkey']!,
          _parentPubkeyMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_parentPubkeyMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Like map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Like(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      videoId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}video_id'],
      )!,
      childProfileId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}child_profile_id'],
      )!,
      parentPubkey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}parent_pubkey'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $LikesTable createAlias(String alias) {
    return $LikesTable(attachedDatabase, alias);
  }
}

class Like extends DataClass implements Insertable<Like> {
  final int id;
  final String videoId;
  final String childProfileId;
  final String parentPubkey;
  final DateTime createdAt;
  const Like({
    required this.id,
    required this.videoId,
    required this.childProfileId,
    required this.parentPubkey,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['video_id'] = Variable<String>(videoId);
    map['child_profile_id'] = Variable<String>(childProfileId);
    map['parent_pubkey'] = Variable<String>(parentPubkey);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  LikesCompanion toCompanion(bool nullToAbsent) {
    return LikesCompanion(
      id: Value(id),
      videoId: Value(videoId),
      childProfileId: Value(childProfileId),
      parentPubkey: Value(parentPubkey),
      createdAt: Value(createdAt),
    );
  }

  factory Like.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Like(
      id: serializer.fromJson<int>(json['id']),
      videoId: serializer.fromJson<String>(json['videoId']),
      childProfileId: serializer.fromJson<String>(json['childProfileId']),
      parentPubkey: serializer.fromJson<String>(json['parentPubkey']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'videoId': serializer.toJson<String>(videoId),
      'childProfileId': serializer.toJson<String>(childProfileId),
      'parentPubkey': serializer.toJson<String>(parentPubkey),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  Like copyWith({
    int? id,
    String? videoId,
    String? childProfileId,
    String? parentPubkey,
    DateTime? createdAt,
  }) => Like(
    id: id ?? this.id,
    videoId: videoId ?? this.videoId,
    childProfileId: childProfileId ?? this.childProfileId,
    parentPubkey: parentPubkey ?? this.parentPubkey,
    createdAt: createdAt ?? this.createdAt,
  );
  Like copyWithCompanion(LikesCompanion data) {
    return Like(
      id: data.id.present ? data.id.value : this.id,
      videoId: data.videoId.present ? data.videoId.value : this.videoId,
      childProfileId: data.childProfileId.present
          ? data.childProfileId.value
          : this.childProfileId,
      parentPubkey: data.parentPubkey.present
          ? data.parentPubkey.value
          : this.parentPubkey,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Like(')
          ..write('id: $id, ')
          ..write('videoId: $videoId, ')
          ..write('childProfileId: $childProfileId, ')
          ..write('parentPubkey: $parentPubkey, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, videoId, childProfileId, parentPubkey, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Like &&
          other.id == this.id &&
          other.videoId == this.videoId &&
          other.childProfileId == this.childProfileId &&
          other.parentPubkey == this.parentPubkey &&
          other.createdAt == this.createdAt);
}

class LikesCompanion extends UpdateCompanion<Like> {
  final Value<int> id;
  final Value<String> videoId;
  final Value<String> childProfileId;
  final Value<String> parentPubkey;
  final Value<DateTime> createdAt;
  const LikesCompanion({
    this.id = const Value.absent(),
    this.videoId = const Value.absent(),
    this.childProfileId = const Value.absent(),
    this.parentPubkey = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  LikesCompanion.insert({
    this.id = const Value.absent(),
    required String videoId,
    required String childProfileId,
    required String parentPubkey,
    required DateTime createdAt,
  }) : videoId = Value(videoId),
       childProfileId = Value(childProfileId),
       parentPubkey = Value(parentPubkey),
       createdAt = Value(createdAt);
  static Insertable<Like> custom({
    Expression<int>? id,
    Expression<String>? videoId,
    Expression<String>? childProfileId,
    Expression<String>? parentPubkey,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (videoId != null) 'video_id': videoId,
      if (childProfileId != null) 'child_profile_id': childProfileId,
      if (parentPubkey != null) 'parent_pubkey': parentPubkey,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  LikesCompanion copyWith({
    Value<int>? id,
    Value<String>? videoId,
    Value<String>? childProfileId,
    Value<String>? parentPubkey,
    Value<DateTime>? createdAt,
  }) {
    return LikesCompanion(
      id: id ?? this.id,
      videoId: videoId ?? this.videoId,
      childProfileId: childProfileId ?? this.childProfileId,
      parentPubkey: parentPubkey ?? this.parentPubkey,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (videoId.present) {
      map['video_id'] = Variable<String>(videoId.value);
    }
    if (childProfileId.present) {
      map['child_profile_id'] = Variable<String>(childProfileId.value);
    }
    if (parentPubkey.present) {
      map['parent_pubkey'] = Variable<String>(parentPubkey.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LikesCompanion(')
          ..write('id: $id, ')
          ..write('videoId: $videoId, ')
          ..write('childProfileId: $childProfileId, ')
          ..write('parentPubkey: $parentPubkey, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $ReactionsTable extends Reactions
    with TableInfo<$ReactionsTable, Reaction> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ReactionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _videoIdMeta = const VerificationMeta(
    'videoId',
  );
  @override
  late final GeneratedColumn<String> videoId = GeneratedColumn<String>(
    'video_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _childProfileIdMeta = const VerificationMeta(
    'childProfileId',
  );
  @override
  late final GeneratedColumn<String> childProfileId = GeneratedColumn<String>(
    'child_profile_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _parentPubkeyMeta = const VerificationMeta(
    'parentPubkey',
  );
  @override
  late final GeneratedColumn<String> parentPubkey = GeneratedColumn<String>(
    'parent_pubkey',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _emojiMeta = const VerificationMeta('emoji');
  @override
  late final GeneratedColumn<String> emoji = GeneratedColumn<String>(
    'emoji',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    videoId,
    childProfileId,
    parentPubkey,
    emoji,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'reactions';
  @override
  VerificationContext validateIntegrity(
    Insertable<Reaction> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('video_id')) {
      context.handle(
        _videoIdMeta,
        videoId.isAcceptableOrUnknown(data['video_id']!, _videoIdMeta),
      );
    } else if (isInserting) {
      context.missing(_videoIdMeta);
    }
    if (data.containsKey('child_profile_id')) {
      context.handle(
        _childProfileIdMeta,
        childProfileId.isAcceptableOrUnknown(
          data['child_profile_id']!,
          _childProfileIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_childProfileIdMeta);
    }
    if (data.containsKey('parent_pubkey')) {
      context.handle(
        _parentPubkeyMeta,
        parentPubkey.isAcceptableOrUnknown(
          data['parent_pubkey']!,
          _parentPubkeyMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_parentPubkeyMeta);
    }
    if (data.containsKey('emoji')) {
      context.handle(
        _emojiMeta,
        emoji.isAcceptableOrUnknown(data['emoji']!, _emojiMeta),
      );
    } else if (isInserting) {
      context.missing(_emojiMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Reaction map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Reaction(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      videoId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}video_id'],
      )!,
      childProfileId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}child_profile_id'],
      )!,
      parentPubkey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}parent_pubkey'],
      )!,
      emoji: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}emoji'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $ReactionsTable createAlias(String alias) {
    return $ReactionsTable(attachedDatabase, alias);
  }
}

class Reaction extends DataClass implements Insertable<Reaction> {
  final int id;
  final String videoId;
  final String childProfileId;
  final String parentPubkey;
  final String emoji;
  final DateTime createdAt;
  const Reaction({
    required this.id,
    required this.videoId,
    required this.childProfileId,
    required this.parentPubkey,
    required this.emoji,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['video_id'] = Variable<String>(videoId);
    map['child_profile_id'] = Variable<String>(childProfileId);
    map['parent_pubkey'] = Variable<String>(parentPubkey);
    map['emoji'] = Variable<String>(emoji);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  ReactionsCompanion toCompanion(bool nullToAbsent) {
    return ReactionsCompanion(
      id: Value(id),
      videoId: Value(videoId),
      childProfileId: Value(childProfileId),
      parentPubkey: Value(parentPubkey),
      emoji: Value(emoji),
      createdAt: Value(createdAt),
    );
  }

  factory Reaction.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Reaction(
      id: serializer.fromJson<int>(json['id']),
      videoId: serializer.fromJson<String>(json['videoId']),
      childProfileId: serializer.fromJson<String>(json['childProfileId']),
      parentPubkey: serializer.fromJson<String>(json['parentPubkey']),
      emoji: serializer.fromJson<String>(json['emoji']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'videoId': serializer.toJson<String>(videoId),
      'childProfileId': serializer.toJson<String>(childProfileId),
      'parentPubkey': serializer.toJson<String>(parentPubkey),
      'emoji': serializer.toJson<String>(emoji),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  Reaction copyWith({
    int? id,
    String? videoId,
    String? childProfileId,
    String? parentPubkey,
    String? emoji,
    DateTime? createdAt,
  }) => Reaction(
    id: id ?? this.id,
    videoId: videoId ?? this.videoId,
    childProfileId: childProfileId ?? this.childProfileId,
    parentPubkey: parentPubkey ?? this.parentPubkey,
    emoji: emoji ?? this.emoji,
    createdAt: createdAt ?? this.createdAt,
  );
  Reaction copyWithCompanion(ReactionsCompanion data) {
    return Reaction(
      id: data.id.present ? data.id.value : this.id,
      videoId: data.videoId.present ? data.videoId.value : this.videoId,
      childProfileId: data.childProfileId.present
          ? data.childProfileId.value
          : this.childProfileId,
      parentPubkey: data.parentPubkey.present
          ? data.parentPubkey.value
          : this.parentPubkey,
      emoji: data.emoji.present ? data.emoji.value : this.emoji,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Reaction(')
          ..write('id: $id, ')
          ..write('videoId: $videoId, ')
          ..write('childProfileId: $childProfileId, ')
          ..write('parentPubkey: $parentPubkey, ')
          ..write('emoji: $emoji, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, videoId, childProfileId, parentPubkey, emoji, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Reaction &&
          other.id == this.id &&
          other.videoId == this.videoId &&
          other.childProfileId == this.childProfileId &&
          other.parentPubkey == this.parentPubkey &&
          other.emoji == this.emoji &&
          other.createdAt == this.createdAt);
}

class ReactionsCompanion extends UpdateCompanion<Reaction> {
  final Value<int> id;
  final Value<String> videoId;
  final Value<String> childProfileId;
  final Value<String> parentPubkey;
  final Value<String> emoji;
  final Value<DateTime> createdAt;
  const ReactionsCompanion({
    this.id = const Value.absent(),
    this.videoId = const Value.absent(),
    this.childProfileId = const Value.absent(),
    this.parentPubkey = const Value.absent(),
    this.emoji = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  ReactionsCompanion.insert({
    this.id = const Value.absent(),
    required String videoId,
    required String childProfileId,
    required String parentPubkey,
    required String emoji,
    required DateTime createdAt,
  }) : videoId = Value(videoId),
       childProfileId = Value(childProfileId),
       parentPubkey = Value(parentPubkey),
       emoji = Value(emoji),
       createdAt = Value(createdAt);
  static Insertable<Reaction> custom({
    Expression<int>? id,
    Expression<String>? videoId,
    Expression<String>? childProfileId,
    Expression<String>? parentPubkey,
    Expression<String>? emoji,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (videoId != null) 'video_id': videoId,
      if (childProfileId != null) 'child_profile_id': childProfileId,
      if (parentPubkey != null) 'parent_pubkey': parentPubkey,
      if (emoji != null) 'emoji': emoji,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  ReactionsCompanion copyWith({
    Value<int>? id,
    Value<String>? videoId,
    Value<String>? childProfileId,
    Value<String>? parentPubkey,
    Value<String>? emoji,
    Value<DateTime>? createdAt,
  }) {
    return ReactionsCompanion(
      id: id ?? this.id,
      videoId: videoId ?? this.videoId,
      childProfileId: childProfileId ?? this.childProfileId,
      parentPubkey: parentPubkey ?? this.parentPubkey,
      emoji: emoji ?? this.emoji,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (videoId.present) {
      map['video_id'] = Variable<String>(videoId.value);
    }
    if (childProfileId.present) {
      map['child_profile_id'] = Variable<String>(childProfileId.value);
    }
    if (parentPubkey.present) {
      map['parent_pubkey'] = Variable<String>(parentPubkey.value);
    }
    if (emoji.present) {
      map['emoji'] = Variable<String>(emoji.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ReactionsCompanion(')
          ..write('id: $id, ')
          ..write('videoId: $videoId, ')
          ..write('childProfileId: $childProfileId, ')
          ..write('parentPubkey: $parentPubkey, ')
          ..write('emoji: $emoji, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $RemotePlaybackMetricsTable extends RemotePlaybackMetrics
    with TableInfo<$RemotePlaybackMetricsTable, RemotePlaybackMetric> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RemotePlaybackMetricsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _remoteShareIdMeta = const VerificationMeta(
    'remoteShareId',
  );
  @override
  late final GeneratedColumn<String> remoteShareId = GeneratedColumn<String>(
    'remote_share_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES share_records (remote_share_id)',
    ),
  );
  static const VerificationMeta _videoIdMeta = const VerificationMeta(
    'videoId',
  );
  @override
  late final GeneratedColumn<String> videoId = GeneratedColumn<String>(
    'video_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lastPlayedAtMeta = const VerificationMeta(
    'lastPlayedAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastPlayedAt = GeneratedColumn<DateTime>(
    'last_played_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _playCountMeta = const VerificationMeta(
    'playCount',
  );
  @override
  late final GeneratedColumn<int> playCount = GeneratedColumn<int>(
    'play_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _completionRateMeta = const VerificationMeta(
    'completionRate',
  );
  @override
  late final GeneratedColumn<double> completionRate = GeneratedColumn<double>(
    'completion_rate',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _replayRateMeta = const VerificationMeta(
    'replayRate',
  );
  @override
  late final GeneratedColumn<double> replayRate = GeneratedColumn<double>(
    'replay_rate',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    remoteShareId,
    videoId,
    lastPlayedAt,
    playCount,
    completionRate,
    replayRate,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'remote_playback_metrics';
  @override
  VerificationContext validateIntegrity(
    Insertable<RemotePlaybackMetric> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('remote_share_id')) {
      context.handle(
        _remoteShareIdMeta,
        remoteShareId.isAcceptableOrUnknown(
          data['remote_share_id']!,
          _remoteShareIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_remoteShareIdMeta);
    }
    if (data.containsKey('video_id')) {
      context.handle(
        _videoIdMeta,
        videoId.isAcceptableOrUnknown(data['video_id']!, _videoIdMeta),
      );
    } else if (isInserting) {
      context.missing(_videoIdMeta);
    }
    if (data.containsKey('last_played_at')) {
      context.handle(
        _lastPlayedAtMeta,
        lastPlayedAt.isAcceptableOrUnknown(
          data['last_played_at']!,
          _lastPlayedAtMeta,
        ),
      );
    }
    if (data.containsKey('play_count')) {
      context.handle(
        _playCountMeta,
        playCount.isAcceptableOrUnknown(data['play_count']!, _playCountMeta),
      );
    }
    if (data.containsKey('completion_rate')) {
      context.handle(
        _completionRateMeta,
        completionRate.isAcceptableOrUnknown(
          data['completion_rate']!,
          _completionRateMeta,
        ),
      );
    }
    if (data.containsKey('replay_rate')) {
      context.handle(
        _replayRateMeta,
        replayRate.isAcceptableOrUnknown(data['replay_rate']!, _replayRateMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {remoteShareId};
  @override
  RemotePlaybackMetric map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return RemotePlaybackMetric(
      remoteShareId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}remote_share_id'],
      )!,
      videoId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}video_id'],
      )!,
      lastPlayedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_played_at'],
      ),
      playCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}play_count'],
      )!,
      completionRate: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}completion_rate'],
      )!,
      replayRate: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}replay_rate'],
      )!,
    );
  }

  @override
  $RemotePlaybackMetricsTable createAlias(String alias) {
    return $RemotePlaybackMetricsTable(attachedDatabase, alias);
  }
}

class RemotePlaybackMetric extends DataClass
    implements Insertable<RemotePlaybackMetric> {
  final String remoteShareId;
  final String videoId;
  final DateTime? lastPlayedAt;
  final int playCount;
  final double completionRate;
  final double replayRate;
  const RemotePlaybackMetric({
    required this.remoteShareId,
    required this.videoId,
    this.lastPlayedAt,
    required this.playCount,
    required this.completionRate,
    required this.replayRate,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['remote_share_id'] = Variable<String>(remoteShareId);
    map['video_id'] = Variable<String>(videoId);
    if (!nullToAbsent || lastPlayedAt != null) {
      map['last_played_at'] = Variable<DateTime>(lastPlayedAt);
    }
    map['play_count'] = Variable<int>(playCount);
    map['completion_rate'] = Variable<double>(completionRate);
    map['replay_rate'] = Variable<double>(replayRate);
    return map;
  }

  RemotePlaybackMetricsCompanion toCompanion(bool nullToAbsent) {
    return RemotePlaybackMetricsCompanion(
      remoteShareId: Value(remoteShareId),
      videoId: Value(videoId),
      lastPlayedAt: lastPlayedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastPlayedAt),
      playCount: Value(playCount),
      completionRate: Value(completionRate),
      replayRate: Value(replayRate),
    );
  }

  factory RemotePlaybackMetric.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return RemotePlaybackMetric(
      remoteShareId: serializer.fromJson<String>(json['remoteShareId']),
      videoId: serializer.fromJson<String>(json['videoId']),
      lastPlayedAt: serializer.fromJson<DateTime?>(json['lastPlayedAt']),
      playCount: serializer.fromJson<int>(json['playCount']),
      completionRate: serializer.fromJson<double>(json['completionRate']),
      replayRate: serializer.fromJson<double>(json['replayRate']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'remoteShareId': serializer.toJson<String>(remoteShareId),
      'videoId': serializer.toJson<String>(videoId),
      'lastPlayedAt': serializer.toJson<DateTime?>(lastPlayedAt),
      'playCount': serializer.toJson<int>(playCount),
      'completionRate': serializer.toJson<double>(completionRate),
      'replayRate': serializer.toJson<double>(replayRate),
    };
  }

  RemotePlaybackMetric copyWith({
    String? remoteShareId,
    String? videoId,
    Value<DateTime?> lastPlayedAt = const Value.absent(),
    int? playCount,
    double? completionRate,
    double? replayRate,
  }) => RemotePlaybackMetric(
    remoteShareId: remoteShareId ?? this.remoteShareId,
    videoId: videoId ?? this.videoId,
    lastPlayedAt: lastPlayedAt.present ? lastPlayedAt.value : this.lastPlayedAt,
    playCount: playCount ?? this.playCount,
    completionRate: completionRate ?? this.completionRate,
    replayRate: replayRate ?? this.replayRate,
  );
  RemotePlaybackMetric copyWithCompanion(RemotePlaybackMetricsCompanion data) {
    return RemotePlaybackMetric(
      remoteShareId: data.remoteShareId.present
          ? data.remoteShareId.value
          : this.remoteShareId,
      videoId: data.videoId.present ? data.videoId.value : this.videoId,
      lastPlayedAt: data.lastPlayedAt.present
          ? data.lastPlayedAt.value
          : this.lastPlayedAt,
      playCount: data.playCount.present ? data.playCount.value : this.playCount,
      completionRate: data.completionRate.present
          ? data.completionRate.value
          : this.completionRate,
      replayRate: data.replayRate.present
          ? data.replayRate.value
          : this.replayRate,
    );
  }

  @override
  String toString() {
    return (StringBuffer('RemotePlaybackMetric(')
          ..write('remoteShareId: $remoteShareId, ')
          ..write('videoId: $videoId, ')
          ..write('lastPlayedAt: $lastPlayedAt, ')
          ..write('playCount: $playCount, ')
          ..write('completionRate: $completionRate, ')
          ..write('replayRate: $replayRate')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    remoteShareId,
    videoId,
    lastPlayedAt,
    playCount,
    completionRate,
    replayRate,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RemotePlaybackMetric &&
          other.remoteShareId == this.remoteShareId &&
          other.videoId == this.videoId &&
          other.lastPlayedAt == this.lastPlayedAt &&
          other.playCount == this.playCount &&
          other.completionRate == this.completionRate &&
          other.replayRate == this.replayRate);
}

class RemotePlaybackMetricsCompanion
    extends UpdateCompanion<RemotePlaybackMetric> {
  final Value<String> remoteShareId;
  final Value<String> videoId;
  final Value<DateTime?> lastPlayedAt;
  final Value<int> playCount;
  final Value<double> completionRate;
  final Value<double> replayRate;
  final Value<int> rowid;
  const RemotePlaybackMetricsCompanion({
    this.remoteShareId = const Value.absent(),
    this.videoId = const Value.absent(),
    this.lastPlayedAt = const Value.absent(),
    this.playCount = const Value.absent(),
    this.completionRate = const Value.absent(),
    this.replayRate = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  RemotePlaybackMetricsCompanion.insert({
    required String remoteShareId,
    required String videoId,
    this.lastPlayedAt = const Value.absent(),
    this.playCount = const Value.absent(),
    this.completionRate = const Value.absent(),
    this.replayRate = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : remoteShareId = Value(remoteShareId),
       videoId = Value(videoId);
  static Insertable<RemotePlaybackMetric> custom({
    Expression<String>? remoteShareId,
    Expression<String>? videoId,
    Expression<DateTime>? lastPlayedAt,
    Expression<int>? playCount,
    Expression<double>? completionRate,
    Expression<double>? replayRate,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (remoteShareId != null) 'remote_share_id': remoteShareId,
      if (videoId != null) 'video_id': videoId,
      if (lastPlayedAt != null) 'last_played_at': lastPlayedAt,
      if (playCount != null) 'play_count': playCount,
      if (completionRate != null) 'completion_rate': completionRate,
      if (replayRate != null) 'replay_rate': replayRate,
      if (rowid != null) 'rowid': rowid,
    });
  }

  RemotePlaybackMetricsCompanion copyWith({
    Value<String>? remoteShareId,
    Value<String>? videoId,
    Value<DateTime?>? lastPlayedAt,
    Value<int>? playCount,
    Value<double>? completionRate,
    Value<double>? replayRate,
    Value<int>? rowid,
  }) {
    return RemotePlaybackMetricsCompanion(
      remoteShareId: remoteShareId ?? this.remoteShareId,
      videoId: videoId ?? this.videoId,
      lastPlayedAt: lastPlayedAt ?? this.lastPlayedAt,
      playCount: playCount ?? this.playCount,
      completionRate: completionRate ?? this.completionRate,
      replayRate: replayRate ?? this.replayRate,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (remoteShareId.present) {
      map['remote_share_id'] = Variable<String>(remoteShareId.value);
    }
    if (videoId.present) {
      map['video_id'] = Variable<String>(videoId.value);
    }
    if (lastPlayedAt.present) {
      map['last_played_at'] = Variable<DateTime>(lastPlayedAt.value);
    }
    if (playCount.present) {
      map['play_count'] = Variable<int>(playCount.value);
    }
    if (completionRate.present) {
      map['completion_rate'] = Variable<double>(completionRate.value);
    }
    if (replayRate.present) {
      map['replay_rate'] = Variable<double>(replayRate.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RemotePlaybackMetricsCompanion(')
          ..write('remoteShareId: $remoteShareId, ')
          ..write('videoId: $videoId, ')
          ..write('lastPlayedAt: $lastPlayedAt, ')
          ..write('playCount: $playCount, ')
          ..write('completionRate: $completionRate, ')
          ..write('replayRate: $replayRate, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ReportsTable extends Reports with TableInfo<$ReportsTable, Report> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ReportsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _videoIdMeta = const VerificationMeta(
    'videoId',
  );
  @override
  late final GeneratedColumn<String> videoId = GeneratedColumn<String>(
    'video_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _subjectChildIdMeta = const VerificationMeta(
    'subjectChildId',
  );
  @override
  late final GeneratedColumn<String> subjectChildId = GeneratedColumn<String>(
    'subject_child_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _blobHashMeta = const VerificationMeta(
    'blobHash',
  );
  @override
  late final GeneratedColumn<String> blobHash = GeneratedColumn<String>(
    'blob_hash',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _reasonMeta = const VerificationMeta('reason');
  @override
  late final GeneratedColumn<String> reason = GeneratedColumn<String>(
    'reason',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _levelMeta = const VerificationMeta('level');
  @override
  late final GeneratedColumn<int> level = GeneratedColumn<int>(
    'level',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _recipientTypeMeta = const VerificationMeta(
    'recipientType',
  );
  @override
  late final GeneratedColumn<String> recipientType = GeneratedColumn<String>(
    'recipient_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('group'),
  );
  static const VerificationMeta _reporterChildIdMeta = const VerificationMeta(
    'reporterChildId',
  );
  @override
  late final GeneratedColumn<String> reporterChildId = GeneratedColumn<String>(
    'reporter_child_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _reporterParentKeyMeta = const VerificationMeta(
    'reporterParentKey',
  );
  @override
  late final GeneratedColumn<String> reporterParentKey =
      GeneratedColumn<String>(
        'reporter_parent_key',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('pending'),
  );
  static const VerificationMeta _actionTakenMeta = const VerificationMeta(
    'actionTaken',
  );
  @override
  late final GeneratedColumn<String> actionTaken = GeneratedColumn<String>(
    'action_taken',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isOutboundMeta = const VerificationMeta(
    'isOutbound',
  );
  @override
  late final GeneratedColumn<bool> isOutbound = GeneratedColumn<bool>(
    'is_outbound',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_outbound" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deliveredAtMeta = const VerificationMeta(
    'deliveredAt',
  );
  @override
  late final GeneratedColumn<DateTime> deliveredAt = GeneratedColumn<DateTime>(
    'delivered_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    videoId,
    subjectChildId,
    blobHash,
    reason,
    note,
    level,
    recipientType,
    reporterChildId,
    reporterParentKey,
    status,
    actionTaken,
    isOutbound,
    createdAt,
    deliveredAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'reports';
  @override
  VerificationContext validateIntegrity(
    Insertable<Report> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('video_id')) {
      context.handle(
        _videoIdMeta,
        videoId.isAcceptableOrUnknown(data['video_id']!, _videoIdMeta),
      );
    } else if (isInserting) {
      context.missing(_videoIdMeta);
    }
    if (data.containsKey('subject_child_id')) {
      context.handle(
        _subjectChildIdMeta,
        subjectChildId.isAcceptableOrUnknown(
          data['subject_child_id']!,
          _subjectChildIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_subjectChildIdMeta);
    }
    if (data.containsKey('blob_hash')) {
      context.handle(
        _blobHashMeta,
        blobHash.isAcceptableOrUnknown(data['blob_hash']!, _blobHashMeta),
      );
    }
    if (data.containsKey('reason')) {
      context.handle(
        _reasonMeta,
        reason.isAcceptableOrUnknown(data['reason']!, _reasonMeta),
      );
    } else if (isInserting) {
      context.missing(_reasonMeta);
    }
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
      );
    }
    if (data.containsKey('level')) {
      context.handle(
        _levelMeta,
        level.isAcceptableOrUnknown(data['level']!, _levelMeta),
      );
    }
    if (data.containsKey('recipient_type')) {
      context.handle(
        _recipientTypeMeta,
        recipientType.isAcceptableOrUnknown(
          data['recipient_type']!,
          _recipientTypeMeta,
        ),
      );
    }
    if (data.containsKey('reporter_child_id')) {
      context.handle(
        _reporterChildIdMeta,
        reporterChildId.isAcceptableOrUnknown(
          data['reporter_child_id']!,
          _reporterChildIdMeta,
        ),
      );
    }
    if (data.containsKey('reporter_parent_key')) {
      context.handle(
        _reporterParentKeyMeta,
        reporterParentKey.isAcceptableOrUnknown(
          data['reporter_parent_key']!,
          _reporterParentKeyMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_reporterParentKeyMeta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('action_taken')) {
      context.handle(
        _actionTakenMeta,
        actionTaken.isAcceptableOrUnknown(
          data['action_taken']!,
          _actionTakenMeta,
        ),
      );
    }
    if (data.containsKey('is_outbound')) {
      context.handle(
        _isOutboundMeta,
        isOutbound.isAcceptableOrUnknown(data['is_outbound']!, _isOutboundMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('delivered_at')) {
      context.handle(
        _deliveredAtMeta,
        deliveredAt.isAcceptableOrUnknown(
          data['delivered_at']!,
          _deliveredAtMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Report map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Report(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      videoId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}video_id'],
      )!,
      subjectChildId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}subject_child_id'],
      )!,
      blobHash: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}blob_hash'],
      ),
      reason: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}reason'],
      )!,
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      ),
      level: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}level'],
      )!,
      recipientType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}recipient_type'],
      )!,
      reporterChildId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}reporter_child_id'],
      ),
      reporterParentKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}reporter_parent_key'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      actionTaken: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}action_taken'],
      ),
      isOutbound: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_outbound'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      deliveredAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}delivered_at'],
      ),
    );
  }

  @override
  $ReportsTable createAlias(String alias) {
    return $ReportsTable(attachedDatabase, alias);
  }
}

class Report extends DataClass implements Insertable<Report> {
  final String id;
  final String videoId;
  final String subjectChildId;
  final String? blobHash;
  final String reason;
  final String? note;
  final int level;
  final String recipientType;
  final String? reporterChildId;
  final String reporterParentKey;
  final String status;
  final String? actionTaken;
  final bool isOutbound;
  final DateTime createdAt;
  final DateTime? deliveredAt;
  const Report({
    required this.id,
    required this.videoId,
    required this.subjectChildId,
    this.blobHash,
    required this.reason,
    this.note,
    required this.level,
    required this.recipientType,
    this.reporterChildId,
    required this.reporterParentKey,
    required this.status,
    this.actionTaken,
    required this.isOutbound,
    required this.createdAt,
    this.deliveredAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['video_id'] = Variable<String>(videoId);
    map['subject_child_id'] = Variable<String>(subjectChildId);
    if (!nullToAbsent || blobHash != null) {
      map['blob_hash'] = Variable<String>(blobHash);
    }
    map['reason'] = Variable<String>(reason);
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    map['level'] = Variable<int>(level);
    map['recipient_type'] = Variable<String>(recipientType);
    if (!nullToAbsent || reporterChildId != null) {
      map['reporter_child_id'] = Variable<String>(reporterChildId);
    }
    map['reporter_parent_key'] = Variable<String>(reporterParentKey);
    map['status'] = Variable<String>(status);
    if (!nullToAbsent || actionTaken != null) {
      map['action_taken'] = Variable<String>(actionTaken);
    }
    map['is_outbound'] = Variable<bool>(isOutbound);
    map['created_at'] = Variable<DateTime>(createdAt);
    if (!nullToAbsent || deliveredAt != null) {
      map['delivered_at'] = Variable<DateTime>(deliveredAt);
    }
    return map;
  }

  ReportsCompanion toCompanion(bool nullToAbsent) {
    return ReportsCompanion(
      id: Value(id),
      videoId: Value(videoId),
      subjectChildId: Value(subjectChildId),
      blobHash: blobHash == null && nullToAbsent
          ? const Value.absent()
          : Value(blobHash),
      reason: Value(reason),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
      level: Value(level),
      recipientType: Value(recipientType),
      reporterChildId: reporterChildId == null && nullToAbsent
          ? const Value.absent()
          : Value(reporterChildId),
      reporterParentKey: Value(reporterParentKey),
      status: Value(status),
      actionTaken: actionTaken == null && nullToAbsent
          ? const Value.absent()
          : Value(actionTaken),
      isOutbound: Value(isOutbound),
      createdAt: Value(createdAt),
      deliveredAt: deliveredAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deliveredAt),
    );
  }

  factory Report.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Report(
      id: serializer.fromJson<String>(json['id']),
      videoId: serializer.fromJson<String>(json['videoId']),
      subjectChildId: serializer.fromJson<String>(json['subjectChildId']),
      blobHash: serializer.fromJson<String?>(json['blobHash']),
      reason: serializer.fromJson<String>(json['reason']),
      note: serializer.fromJson<String?>(json['note']),
      level: serializer.fromJson<int>(json['level']),
      recipientType: serializer.fromJson<String>(json['recipientType']),
      reporterChildId: serializer.fromJson<String?>(json['reporterChildId']),
      reporterParentKey: serializer.fromJson<String>(json['reporterParentKey']),
      status: serializer.fromJson<String>(json['status']),
      actionTaken: serializer.fromJson<String?>(json['actionTaken']),
      isOutbound: serializer.fromJson<bool>(json['isOutbound']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      deliveredAt: serializer.fromJson<DateTime?>(json['deliveredAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'videoId': serializer.toJson<String>(videoId),
      'subjectChildId': serializer.toJson<String>(subjectChildId),
      'blobHash': serializer.toJson<String?>(blobHash),
      'reason': serializer.toJson<String>(reason),
      'note': serializer.toJson<String?>(note),
      'level': serializer.toJson<int>(level),
      'recipientType': serializer.toJson<String>(recipientType),
      'reporterChildId': serializer.toJson<String?>(reporterChildId),
      'reporterParentKey': serializer.toJson<String>(reporterParentKey),
      'status': serializer.toJson<String>(status),
      'actionTaken': serializer.toJson<String?>(actionTaken),
      'isOutbound': serializer.toJson<bool>(isOutbound),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'deliveredAt': serializer.toJson<DateTime?>(deliveredAt),
    };
  }

  Report copyWith({
    String? id,
    String? videoId,
    String? subjectChildId,
    Value<String?> blobHash = const Value.absent(),
    String? reason,
    Value<String?> note = const Value.absent(),
    int? level,
    String? recipientType,
    Value<String?> reporterChildId = const Value.absent(),
    String? reporterParentKey,
    String? status,
    Value<String?> actionTaken = const Value.absent(),
    bool? isOutbound,
    DateTime? createdAt,
    Value<DateTime?> deliveredAt = const Value.absent(),
  }) => Report(
    id: id ?? this.id,
    videoId: videoId ?? this.videoId,
    subjectChildId: subjectChildId ?? this.subjectChildId,
    blobHash: blobHash.present ? blobHash.value : this.blobHash,
    reason: reason ?? this.reason,
    note: note.present ? note.value : this.note,
    level: level ?? this.level,
    recipientType: recipientType ?? this.recipientType,
    reporterChildId: reporterChildId.present
        ? reporterChildId.value
        : this.reporterChildId,
    reporterParentKey: reporterParentKey ?? this.reporterParentKey,
    status: status ?? this.status,
    actionTaken: actionTaken.present ? actionTaken.value : this.actionTaken,
    isOutbound: isOutbound ?? this.isOutbound,
    createdAt: createdAt ?? this.createdAt,
    deliveredAt: deliveredAt.present ? deliveredAt.value : this.deliveredAt,
  );
  Report copyWithCompanion(ReportsCompanion data) {
    return Report(
      id: data.id.present ? data.id.value : this.id,
      videoId: data.videoId.present ? data.videoId.value : this.videoId,
      subjectChildId: data.subjectChildId.present
          ? data.subjectChildId.value
          : this.subjectChildId,
      blobHash: data.blobHash.present ? data.blobHash.value : this.blobHash,
      reason: data.reason.present ? data.reason.value : this.reason,
      note: data.note.present ? data.note.value : this.note,
      level: data.level.present ? data.level.value : this.level,
      recipientType: data.recipientType.present
          ? data.recipientType.value
          : this.recipientType,
      reporterChildId: data.reporterChildId.present
          ? data.reporterChildId.value
          : this.reporterChildId,
      reporterParentKey: data.reporterParentKey.present
          ? data.reporterParentKey.value
          : this.reporterParentKey,
      status: data.status.present ? data.status.value : this.status,
      actionTaken: data.actionTaken.present
          ? data.actionTaken.value
          : this.actionTaken,
      isOutbound: data.isOutbound.present
          ? data.isOutbound.value
          : this.isOutbound,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      deliveredAt: data.deliveredAt.present
          ? data.deliveredAt.value
          : this.deliveredAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Report(')
          ..write('id: $id, ')
          ..write('videoId: $videoId, ')
          ..write('subjectChildId: $subjectChildId, ')
          ..write('blobHash: $blobHash, ')
          ..write('reason: $reason, ')
          ..write('note: $note, ')
          ..write('level: $level, ')
          ..write('recipientType: $recipientType, ')
          ..write('reporterChildId: $reporterChildId, ')
          ..write('reporterParentKey: $reporterParentKey, ')
          ..write('status: $status, ')
          ..write('actionTaken: $actionTaken, ')
          ..write('isOutbound: $isOutbound, ')
          ..write('createdAt: $createdAt, ')
          ..write('deliveredAt: $deliveredAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    videoId,
    subjectChildId,
    blobHash,
    reason,
    note,
    level,
    recipientType,
    reporterChildId,
    reporterParentKey,
    status,
    actionTaken,
    isOutbound,
    createdAt,
    deliveredAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Report &&
          other.id == this.id &&
          other.videoId == this.videoId &&
          other.subjectChildId == this.subjectChildId &&
          other.blobHash == this.blobHash &&
          other.reason == this.reason &&
          other.note == this.note &&
          other.level == this.level &&
          other.recipientType == this.recipientType &&
          other.reporterChildId == this.reporterChildId &&
          other.reporterParentKey == this.reporterParentKey &&
          other.status == this.status &&
          other.actionTaken == this.actionTaken &&
          other.isOutbound == this.isOutbound &&
          other.createdAt == this.createdAt &&
          other.deliveredAt == this.deliveredAt);
}

class ReportsCompanion extends UpdateCompanion<Report> {
  final Value<String> id;
  final Value<String> videoId;
  final Value<String> subjectChildId;
  final Value<String?> blobHash;
  final Value<String> reason;
  final Value<String?> note;
  final Value<int> level;
  final Value<String> recipientType;
  final Value<String?> reporterChildId;
  final Value<String> reporterParentKey;
  final Value<String> status;
  final Value<String?> actionTaken;
  final Value<bool> isOutbound;
  final Value<DateTime> createdAt;
  final Value<DateTime?> deliveredAt;
  final Value<int> rowid;
  const ReportsCompanion({
    this.id = const Value.absent(),
    this.videoId = const Value.absent(),
    this.subjectChildId = const Value.absent(),
    this.blobHash = const Value.absent(),
    this.reason = const Value.absent(),
    this.note = const Value.absent(),
    this.level = const Value.absent(),
    this.recipientType = const Value.absent(),
    this.reporterChildId = const Value.absent(),
    this.reporterParentKey = const Value.absent(),
    this.status = const Value.absent(),
    this.actionTaken = const Value.absent(),
    this.isOutbound = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.deliveredAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ReportsCompanion.insert({
    required String id,
    required String videoId,
    required String subjectChildId,
    this.blobHash = const Value.absent(),
    required String reason,
    this.note = const Value.absent(),
    this.level = const Value.absent(),
    this.recipientType = const Value.absent(),
    this.reporterChildId = const Value.absent(),
    required String reporterParentKey,
    this.status = const Value.absent(),
    this.actionTaken = const Value.absent(),
    this.isOutbound = const Value.absent(),
    required DateTime createdAt,
    this.deliveredAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       videoId = Value(videoId),
       subjectChildId = Value(subjectChildId),
       reason = Value(reason),
       reporterParentKey = Value(reporterParentKey),
       createdAt = Value(createdAt);
  static Insertable<Report> custom({
    Expression<String>? id,
    Expression<String>? videoId,
    Expression<String>? subjectChildId,
    Expression<String>? blobHash,
    Expression<String>? reason,
    Expression<String>? note,
    Expression<int>? level,
    Expression<String>? recipientType,
    Expression<String>? reporterChildId,
    Expression<String>? reporterParentKey,
    Expression<String>? status,
    Expression<String>? actionTaken,
    Expression<bool>? isOutbound,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? deliveredAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (videoId != null) 'video_id': videoId,
      if (subjectChildId != null) 'subject_child_id': subjectChildId,
      if (blobHash != null) 'blob_hash': blobHash,
      if (reason != null) 'reason': reason,
      if (note != null) 'note': note,
      if (level != null) 'level': level,
      if (recipientType != null) 'recipient_type': recipientType,
      if (reporterChildId != null) 'reporter_child_id': reporterChildId,
      if (reporterParentKey != null) 'reporter_parent_key': reporterParentKey,
      if (status != null) 'status': status,
      if (actionTaken != null) 'action_taken': actionTaken,
      if (isOutbound != null) 'is_outbound': isOutbound,
      if (createdAt != null) 'created_at': createdAt,
      if (deliveredAt != null) 'delivered_at': deliveredAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ReportsCompanion copyWith({
    Value<String>? id,
    Value<String>? videoId,
    Value<String>? subjectChildId,
    Value<String?>? blobHash,
    Value<String>? reason,
    Value<String?>? note,
    Value<int>? level,
    Value<String>? recipientType,
    Value<String?>? reporterChildId,
    Value<String>? reporterParentKey,
    Value<String>? status,
    Value<String?>? actionTaken,
    Value<bool>? isOutbound,
    Value<DateTime>? createdAt,
    Value<DateTime?>? deliveredAt,
    Value<int>? rowid,
  }) {
    return ReportsCompanion(
      id: id ?? this.id,
      videoId: videoId ?? this.videoId,
      subjectChildId: subjectChildId ?? this.subjectChildId,
      blobHash: blobHash ?? this.blobHash,
      reason: reason ?? this.reason,
      note: note ?? this.note,
      level: level ?? this.level,
      recipientType: recipientType ?? this.recipientType,
      reporterChildId: reporterChildId ?? this.reporterChildId,
      reporterParentKey: reporterParentKey ?? this.reporterParentKey,
      status: status ?? this.status,
      actionTaken: actionTaken ?? this.actionTaken,
      isOutbound: isOutbound ?? this.isOutbound,
      createdAt: createdAt ?? this.createdAt,
      deliveredAt: deliveredAt ?? this.deliveredAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (videoId.present) {
      map['video_id'] = Variable<String>(videoId.value);
    }
    if (subjectChildId.present) {
      map['subject_child_id'] = Variable<String>(subjectChildId.value);
    }
    if (blobHash.present) {
      map['blob_hash'] = Variable<String>(blobHash.value);
    }
    if (reason.present) {
      map['reason'] = Variable<String>(reason.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (level.present) {
      map['level'] = Variable<int>(level.value);
    }
    if (recipientType.present) {
      map['recipient_type'] = Variable<String>(recipientType.value);
    }
    if (reporterChildId.present) {
      map['reporter_child_id'] = Variable<String>(reporterChildId.value);
    }
    if (reporterParentKey.present) {
      map['reporter_parent_key'] = Variable<String>(reporterParentKey.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (actionTaken.present) {
      map['action_taken'] = Variable<String>(actionTaken.value);
    }
    if (isOutbound.present) {
      map['is_outbound'] = Variable<bool>(isOutbound.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (deliveredAt.present) {
      map['delivered_at'] = Variable<DateTime>(deliveredAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ReportsCompanion(')
          ..write('id: $id, ')
          ..write('videoId: $videoId, ')
          ..write('subjectChildId: $subjectChildId, ')
          ..write('blobHash: $blobHash, ')
          ..write('reason: $reason, ')
          ..write('note: $note, ')
          ..write('level: $level, ')
          ..write('recipientType: $recipientType, ')
          ..write('reporterChildId: $reporterChildId, ')
          ..write('reporterParentKey: $reporterParentKey, ')
          ..write('status: $status, ')
          ..write('actionTaken: $actionTaken, ')
          ..write('isOutbound: $isOutbound, ')
          ..write('createdAt: $createdAt, ')
          ..write('deliveredAt: $deliveredAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ModerationAuditLogsTable extends ModerationAuditLogs
    with TableInfo<$ModerationAuditLogsTable, ModerationAuditLog> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ModerationAuditLogsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _videoIdMeta = const VerificationMeta(
    'videoId',
  );
  @override
  late final GeneratedColumn<String> videoId = GeneratedColumn<String>(
    'video_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _mlsGroupIdMeta = const VerificationMeta(
    'mlsGroupId',
  );
  @override
  late final GeneratedColumn<String> mlsGroupId = GeneratedColumn<String>(
    'mls_group_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _actionTypeMeta = const VerificationMeta(
    'actionType',
  );
  @override
  late final GeneratedColumn<String> actionType = GeneratedColumn<String>(
    'action_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _actorParentKeyMeta = const VerificationMeta(
    'actorParentKey',
  );
  @override
  late final GeneratedColumn<String> actorParentKey = GeneratedColumn<String>(
    'actor_parent_key',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _subjectParentKeyMeta = const VerificationMeta(
    'subjectParentKey',
  );
  @override
  late final GeneratedColumn<String> subjectParentKey = GeneratedColumn<String>(
    'subject_parent_key',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _detailsJsonMeta = const VerificationMeta(
    'detailsJson',
  );
  @override
  late final GeneratedColumn<String> detailsJson = GeneratedColumn<String>(
    'details_json',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    videoId,
    mlsGroupId,
    actionType,
    actorParentKey,
    subjectParentKey,
    detailsJson,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'moderation_audit_logs';
  @override
  VerificationContext validateIntegrity(
    Insertable<ModerationAuditLog> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('video_id')) {
      context.handle(
        _videoIdMeta,
        videoId.isAcceptableOrUnknown(data['video_id']!, _videoIdMeta),
      );
    }
    if (data.containsKey('mls_group_id')) {
      context.handle(
        _mlsGroupIdMeta,
        mlsGroupId.isAcceptableOrUnknown(
          data['mls_group_id']!,
          _mlsGroupIdMeta,
        ),
      );
    }
    if (data.containsKey('action_type')) {
      context.handle(
        _actionTypeMeta,
        actionType.isAcceptableOrUnknown(data['action_type']!, _actionTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_actionTypeMeta);
    }
    if (data.containsKey('actor_parent_key')) {
      context.handle(
        _actorParentKeyMeta,
        actorParentKey.isAcceptableOrUnknown(
          data['actor_parent_key']!,
          _actorParentKeyMeta,
        ),
      );
    }
    if (data.containsKey('subject_parent_key')) {
      context.handle(
        _subjectParentKeyMeta,
        subjectParentKey.isAcceptableOrUnknown(
          data['subject_parent_key']!,
          _subjectParentKeyMeta,
        ),
      );
    }
    if (data.containsKey('details_json')) {
      context.handle(
        _detailsJsonMeta,
        detailsJson.isAcceptableOrUnknown(
          data['details_json']!,
          _detailsJsonMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ModerationAuditLog map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ModerationAuditLog(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      videoId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}video_id'],
      ),
      mlsGroupId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}mls_group_id'],
      ),
      actionType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}action_type'],
      )!,
      actorParentKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}actor_parent_key'],
      ),
      subjectParentKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}subject_parent_key'],
      ),
      detailsJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}details_json'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $ModerationAuditLogsTable createAlias(String alias) {
    return $ModerationAuditLogsTable(attachedDatabase, alias);
  }
}

class ModerationAuditLog extends DataClass
    implements Insertable<ModerationAuditLog> {
  final int id;
  final String? videoId;
  final String? mlsGroupId;
  final String actionType;
  final String? actorParentKey;
  final String? subjectParentKey;
  final String? detailsJson;
  final DateTime createdAt;
  const ModerationAuditLog({
    required this.id,
    this.videoId,
    this.mlsGroupId,
    required this.actionType,
    this.actorParentKey,
    this.subjectParentKey,
    this.detailsJson,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    if (!nullToAbsent || videoId != null) {
      map['video_id'] = Variable<String>(videoId);
    }
    if (!nullToAbsent || mlsGroupId != null) {
      map['mls_group_id'] = Variable<String>(mlsGroupId);
    }
    map['action_type'] = Variable<String>(actionType);
    if (!nullToAbsent || actorParentKey != null) {
      map['actor_parent_key'] = Variable<String>(actorParentKey);
    }
    if (!nullToAbsent || subjectParentKey != null) {
      map['subject_parent_key'] = Variable<String>(subjectParentKey);
    }
    if (!nullToAbsent || detailsJson != null) {
      map['details_json'] = Variable<String>(detailsJson);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  ModerationAuditLogsCompanion toCompanion(bool nullToAbsent) {
    return ModerationAuditLogsCompanion(
      id: Value(id),
      videoId: videoId == null && nullToAbsent
          ? const Value.absent()
          : Value(videoId),
      mlsGroupId: mlsGroupId == null && nullToAbsent
          ? const Value.absent()
          : Value(mlsGroupId),
      actionType: Value(actionType),
      actorParentKey: actorParentKey == null && nullToAbsent
          ? const Value.absent()
          : Value(actorParentKey),
      subjectParentKey: subjectParentKey == null && nullToAbsent
          ? const Value.absent()
          : Value(subjectParentKey),
      detailsJson: detailsJson == null && nullToAbsent
          ? const Value.absent()
          : Value(detailsJson),
      createdAt: Value(createdAt),
    );
  }

  factory ModerationAuditLog.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ModerationAuditLog(
      id: serializer.fromJson<int>(json['id']),
      videoId: serializer.fromJson<String?>(json['videoId']),
      mlsGroupId: serializer.fromJson<String?>(json['mlsGroupId']),
      actionType: serializer.fromJson<String>(json['actionType']),
      actorParentKey: serializer.fromJson<String?>(json['actorParentKey']),
      subjectParentKey: serializer.fromJson<String?>(json['subjectParentKey']),
      detailsJson: serializer.fromJson<String?>(json['detailsJson']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'videoId': serializer.toJson<String?>(videoId),
      'mlsGroupId': serializer.toJson<String?>(mlsGroupId),
      'actionType': serializer.toJson<String>(actionType),
      'actorParentKey': serializer.toJson<String?>(actorParentKey),
      'subjectParentKey': serializer.toJson<String?>(subjectParentKey),
      'detailsJson': serializer.toJson<String?>(detailsJson),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  ModerationAuditLog copyWith({
    int? id,
    Value<String?> videoId = const Value.absent(),
    Value<String?> mlsGroupId = const Value.absent(),
    String? actionType,
    Value<String?> actorParentKey = const Value.absent(),
    Value<String?> subjectParentKey = const Value.absent(),
    Value<String?> detailsJson = const Value.absent(),
    DateTime? createdAt,
  }) => ModerationAuditLog(
    id: id ?? this.id,
    videoId: videoId.present ? videoId.value : this.videoId,
    mlsGroupId: mlsGroupId.present ? mlsGroupId.value : this.mlsGroupId,
    actionType: actionType ?? this.actionType,
    actorParentKey: actorParentKey.present
        ? actorParentKey.value
        : this.actorParentKey,
    subjectParentKey: subjectParentKey.present
        ? subjectParentKey.value
        : this.subjectParentKey,
    detailsJson: detailsJson.present ? detailsJson.value : this.detailsJson,
    createdAt: createdAt ?? this.createdAt,
  );
  ModerationAuditLog copyWithCompanion(ModerationAuditLogsCompanion data) {
    return ModerationAuditLog(
      id: data.id.present ? data.id.value : this.id,
      videoId: data.videoId.present ? data.videoId.value : this.videoId,
      mlsGroupId: data.mlsGroupId.present
          ? data.mlsGroupId.value
          : this.mlsGroupId,
      actionType: data.actionType.present
          ? data.actionType.value
          : this.actionType,
      actorParentKey: data.actorParentKey.present
          ? data.actorParentKey.value
          : this.actorParentKey,
      subjectParentKey: data.subjectParentKey.present
          ? data.subjectParentKey.value
          : this.subjectParentKey,
      detailsJson: data.detailsJson.present
          ? data.detailsJson.value
          : this.detailsJson,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ModerationAuditLog(')
          ..write('id: $id, ')
          ..write('videoId: $videoId, ')
          ..write('mlsGroupId: $mlsGroupId, ')
          ..write('actionType: $actionType, ')
          ..write('actorParentKey: $actorParentKey, ')
          ..write('subjectParentKey: $subjectParentKey, ')
          ..write('detailsJson: $detailsJson, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    videoId,
    mlsGroupId,
    actionType,
    actorParentKey,
    subjectParentKey,
    detailsJson,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ModerationAuditLog &&
          other.id == this.id &&
          other.videoId == this.videoId &&
          other.mlsGroupId == this.mlsGroupId &&
          other.actionType == this.actionType &&
          other.actorParentKey == this.actorParentKey &&
          other.subjectParentKey == this.subjectParentKey &&
          other.detailsJson == this.detailsJson &&
          other.createdAt == this.createdAt);
}

class ModerationAuditLogsCompanion extends UpdateCompanion<ModerationAuditLog> {
  final Value<int> id;
  final Value<String?> videoId;
  final Value<String?> mlsGroupId;
  final Value<String> actionType;
  final Value<String?> actorParentKey;
  final Value<String?> subjectParentKey;
  final Value<String?> detailsJson;
  final Value<DateTime> createdAt;
  const ModerationAuditLogsCompanion({
    this.id = const Value.absent(),
    this.videoId = const Value.absent(),
    this.mlsGroupId = const Value.absent(),
    this.actionType = const Value.absent(),
    this.actorParentKey = const Value.absent(),
    this.subjectParentKey = const Value.absent(),
    this.detailsJson = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  ModerationAuditLogsCompanion.insert({
    this.id = const Value.absent(),
    this.videoId = const Value.absent(),
    this.mlsGroupId = const Value.absent(),
    required String actionType,
    this.actorParentKey = const Value.absent(),
    this.subjectParentKey = const Value.absent(),
    this.detailsJson = const Value.absent(),
    required DateTime createdAt,
  }) : actionType = Value(actionType),
       createdAt = Value(createdAt);
  static Insertable<ModerationAuditLog> custom({
    Expression<int>? id,
    Expression<String>? videoId,
    Expression<String>? mlsGroupId,
    Expression<String>? actionType,
    Expression<String>? actorParentKey,
    Expression<String>? subjectParentKey,
    Expression<String>? detailsJson,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (videoId != null) 'video_id': videoId,
      if (mlsGroupId != null) 'mls_group_id': mlsGroupId,
      if (actionType != null) 'action_type': actionType,
      if (actorParentKey != null) 'actor_parent_key': actorParentKey,
      if (subjectParentKey != null) 'subject_parent_key': subjectParentKey,
      if (detailsJson != null) 'details_json': detailsJson,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  ModerationAuditLogsCompanion copyWith({
    Value<int>? id,
    Value<String?>? videoId,
    Value<String?>? mlsGroupId,
    Value<String>? actionType,
    Value<String?>? actorParentKey,
    Value<String?>? subjectParentKey,
    Value<String?>? detailsJson,
    Value<DateTime>? createdAt,
  }) {
    return ModerationAuditLogsCompanion(
      id: id ?? this.id,
      videoId: videoId ?? this.videoId,
      mlsGroupId: mlsGroupId ?? this.mlsGroupId,
      actionType: actionType ?? this.actionType,
      actorParentKey: actorParentKey ?? this.actorParentKey,
      subjectParentKey: subjectParentKey ?? this.subjectParentKey,
      detailsJson: detailsJson ?? this.detailsJson,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (videoId.present) {
      map['video_id'] = Variable<String>(videoId.value);
    }
    if (mlsGroupId.present) {
      map['mls_group_id'] = Variable<String>(mlsGroupId.value);
    }
    if (actionType.present) {
      map['action_type'] = Variable<String>(actionType.value);
    }
    if (actorParentKey.present) {
      map['actor_parent_key'] = Variable<String>(actorParentKey.value);
    }
    if (subjectParentKey.present) {
      map['subject_parent_key'] = Variable<String>(subjectParentKey.value);
    }
    if (detailsJson.present) {
      map['details_json'] = Variable<String>(detailsJson.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ModerationAuditLogsCompanion(')
          ..write('id: $id, ')
          ..write('videoId: $videoId, ')
          ..write('mlsGroupId: $mlsGroupId, ')
          ..write('actionType: $actionType, ')
          ..write('actorParentKey: $actorParentKey, ')
          ..write('subjectParentKey: $subjectParentKey, ')
          ..write('detailsJson: $detailsJson, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $AppSettingsTable extends AppSettings
    with TableInfo<$AppSettingsTable, AppSetting> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AppSettingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
    'key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
    'value',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [key, value, updatedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'app_settings';
  @override
  VerificationContext validateIntegrity(
    Insertable<AppSetting> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(
        _keyMeta,
        key.isAcceptableOrUnknown(data['key']!, _keyMeta),
      );
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
        _valueMeta,
        value.isAcceptableOrUnknown(data['value']!, _valueMeta),
      );
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  AppSetting map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AppSetting(
      key: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key'],
      )!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}value'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $AppSettingsTable createAlias(String alias) {
    return $AppSettingsTable(attachedDatabase, alias);
  }
}

class AppSetting extends DataClass implements Insertable<AppSetting> {
  final String key;
  final String value;
  final DateTime updatedAt;
  const AppSetting({
    required this.key,
    required this.value,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['value'] = Variable<String>(value);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  AppSettingsCompanion toCompanion(bool nullToAbsent) {
    return AppSettingsCompanion(
      key: Value(key),
      value: Value(value),
      updatedAt: Value(updatedAt),
    );
  }

  factory AppSetting.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AppSetting(
      key: serializer.fromJson<String>(json['key']),
      value: serializer.fromJson<String>(json['value']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'value': serializer.toJson<String>(value),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  AppSetting copyWith({String? key, String? value, DateTime? updatedAt}) =>
      AppSetting(
        key: key ?? this.key,
        value: value ?? this.value,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  AppSetting copyWithCompanion(AppSettingsCompanion data) {
    return AppSetting(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AppSetting(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, value, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AppSetting &&
          other.key == this.key &&
          other.value == this.value &&
          other.updatedAt == this.updatedAt);
}

class AppSettingsCompanion extends UpdateCompanion<AppSetting> {
  final Value<String> key;
  final Value<String> value;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const AppSettingsCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AppSettingsCompanion.insert({
    required String key,
    required String value,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : key = Value(key),
       value = Value(value),
       updatedAt = Value(updatedAt);
  static Insertable<AppSetting> custom({
    Expression<String>? key,
    Expression<String>? value,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (value != null) 'value': value,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AppSettingsCompanion copyWith({
    Value<String>? key,
    Value<String>? value,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return AppSettingsCompanion(
      key: key ?? this.key,
      value: value ?? this.value,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AppSettingsCompanion(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $ProfilesTable profiles = $ProfilesTable(this);
  late final $ProfileGroupsTable profileGroups = $ProfileGroupsTable(this);
  late final $LocalVideosTable localVideos = $LocalVideosTable(this);
  late final $RemoteAssetsTable remoteAssets = $RemoteAssetsTable(this);
  late final $ShareRecordsTable shareRecords = $ShareRecordsTable(this);
  late final $LikesTable likes = $LikesTable(this);
  late final $ReactionsTable reactions = $ReactionsTable(this);
  late final $RemotePlaybackMetricsTable remotePlaybackMetrics =
      $RemotePlaybackMetricsTable(this);
  late final $ReportsTable reports = $ReportsTable(this);
  late final $ModerationAuditLogsTable moderationAuditLogs =
      $ModerationAuditLogsTable(this);
  late final $AppSettingsTable appSettings = $AppSettingsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    profiles,
    profileGroups,
    localVideos,
    remoteAssets,
    shareRecords,
    likes,
    reactions,
    remotePlaybackMetrics,
    reports,
    moderationAuditLogs,
    appSettings,
  ];
}

typedef $$ProfilesTableCreateCompanionBuilder =
    ProfilesCompanion Function({
      required String id,
      required String name,
      required String theme,
      Value<String?> avatarAsset,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$ProfilesTableUpdateCompanionBuilder =
    ProfilesCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<String> theme,
      Value<String?> avatarAsset,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

final class $$ProfilesTableReferences
    extends BaseReferences<_$AppDatabase, $ProfilesTable, Profile> {
  $$ProfilesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$ProfileGroupsTable, List<ProfileGroup>>
  _profileGroupsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.profileGroups,
    aliasName: $_aliasNameGenerator(db.profiles.id, db.profileGroups.profileId),
  );

  $$ProfileGroupsTableProcessedTableManager get profileGroupsRefs {
    final manager = $$ProfileGroupsTableTableManager(
      $_db,
      $_db.profileGroups,
    ).filter((f) => f.profileId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_profileGroupsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$LocalVideosTable, List<LocalVideo>>
  _localVideosRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.localVideos,
    aliasName: $_aliasNameGenerator(db.profiles.id, db.localVideos.profileId),
  );

  $$LocalVideosTableProcessedTableManager get localVideosRefs {
    final manager = $$LocalVideosTableTableManager(
      $_db,
      $_db.localVideos,
    ).filter((f) => f.profileId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_localVideosRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$ProfilesTableFilterComposer
    extends Composer<_$AppDatabase, $ProfilesTable> {
  $$ProfilesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get theme => $composableBuilder(
    column: $table.theme,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get avatarAsset => $composableBuilder(
    column: $table.avatarAsset,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> profileGroupsRefs(
    Expression<bool> Function($$ProfileGroupsTableFilterComposer f) f,
  ) {
    final $$ProfileGroupsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.profileGroups,
      getReferencedColumn: (t) => t.profileId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProfileGroupsTableFilterComposer(
            $db: $db,
            $table: $db.profileGroups,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> localVideosRefs(
    Expression<bool> Function($$LocalVideosTableFilterComposer f) f,
  ) {
    final $$LocalVideosTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.localVideos,
      getReferencedColumn: (t) => t.profileId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LocalVideosTableFilterComposer(
            $db: $db,
            $table: $db.localVideos,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ProfilesTableOrderingComposer
    extends Composer<_$AppDatabase, $ProfilesTable> {
  $$ProfilesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get theme => $composableBuilder(
    column: $table.theme,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get avatarAsset => $composableBuilder(
    column: $table.avatarAsset,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ProfilesTableAnnotationComposer
    extends Composer<_$AppDatabase, $ProfilesTable> {
  $$ProfilesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get theme =>
      $composableBuilder(column: $table.theme, builder: (column) => column);

  GeneratedColumn<String> get avatarAsset => $composableBuilder(
    column: $table.avatarAsset,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  Expression<T> profileGroupsRefs<T extends Object>(
    Expression<T> Function($$ProfileGroupsTableAnnotationComposer a) f,
  ) {
    final $$ProfileGroupsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.profileGroups,
      getReferencedColumn: (t) => t.profileId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProfileGroupsTableAnnotationComposer(
            $db: $db,
            $table: $db.profileGroups,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> localVideosRefs<T extends Object>(
    Expression<T> Function($$LocalVideosTableAnnotationComposer a) f,
  ) {
    final $$LocalVideosTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.localVideos,
      getReferencedColumn: (t) => t.profileId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LocalVideosTableAnnotationComposer(
            $db: $db,
            $table: $db.localVideos,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ProfilesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ProfilesTable,
          Profile,
          $$ProfilesTableFilterComposer,
          $$ProfilesTableOrderingComposer,
          $$ProfilesTableAnnotationComposer,
          $$ProfilesTableCreateCompanionBuilder,
          $$ProfilesTableUpdateCompanionBuilder,
          (Profile, $$ProfilesTableReferences),
          Profile,
          PrefetchHooks Function({bool profileGroupsRefs, bool localVideosRefs})
        > {
  $$ProfilesTableTableManager(_$AppDatabase db, $ProfilesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ProfilesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ProfilesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ProfilesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> theme = const Value.absent(),
                Value<String?> avatarAsset = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ProfilesCompanion(
                id: id,
                name: name,
                theme: theme,
                avatarAsset: avatarAsset,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                required String theme,
                Value<String?> avatarAsset = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => ProfilesCompanion.insert(
                id: id,
                name: name,
                theme: theme,
                avatarAsset: avatarAsset,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$ProfilesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({profileGroupsRefs = false, localVideosRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (profileGroupsRefs) db.profileGroups,
                    if (localVideosRefs) db.localVideos,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (profileGroupsRefs)
                        await $_getPrefetchedData<
                          Profile,
                          $ProfilesTable,
                          ProfileGroup
                        >(
                          currentTable: table,
                          referencedTable: $$ProfilesTableReferences
                              ._profileGroupsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ProfilesTableReferences(
                                db,
                                table,
                                p0,
                              ).profileGroupsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.profileId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (localVideosRefs)
                        await $_getPrefetchedData<
                          Profile,
                          $ProfilesTable,
                          LocalVideo
                        >(
                          currentTable: table,
                          referencedTable: $$ProfilesTableReferences
                              ._localVideosRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ProfilesTableReferences(
                                db,
                                table,
                                p0,
                              ).localVideosRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.profileId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$ProfilesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ProfilesTable,
      Profile,
      $$ProfilesTableFilterComposer,
      $$ProfilesTableOrderingComposer,
      $$ProfilesTableAnnotationComposer,
      $$ProfilesTableCreateCompanionBuilder,
      $$ProfilesTableUpdateCompanionBuilder,
      (Profile, $$ProfilesTableReferences),
      Profile,
      PrefetchHooks Function({bool profileGroupsRefs, bool localVideosRefs})
    >;
typedef $$ProfileGroupsTableCreateCompanionBuilder =
    ProfileGroupsCompanion Function({
      Value<int> id,
      required String profileId,
      required String mlsGroupId,
      Value<bool> isPrimary,
      required DateTime joinedAt,
    });
typedef $$ProfileGroupsTableUpdateCompanionBuilder =
    ProfileGroupsCompanion Function({
      Value<int> id,
      Value<String> profileId,
      Value<String> mlsGroupId,
      Value<bool> isPrimary,
      Value<DateTime> joinedAt,
    });

final class $$ProfileGroupsTableReferences
    extends BaseReferences<_$AppDatabase, $ProfileGroupsTable, ProfileGroup> {
  $$ProfileGroupsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $ProfilesTable _profileIdTable(_$AppDatabase db) =>
      db.profiles.createAlias(
        $_aliasNameGenerator(db.profileGroups.profileId, db.profiles.id),
      );

  $$ProfilesTableProcessedTableManager get profileId {
    final $_column = $_itemColumn<String>('profile_id')!;

    final manager = $$ProfilesTableTableManager(
      $_db,
      $_db.profiles,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_profileIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$ProfileGroupsTableFilterComposer
    extends Composer<_$AppDatabase, $ProfileGroupsTable> {
  $$ProfileGroupsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get mlsGroupId => $composableBuilder(
    column: $table.mlsGroupId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isPrimary => $composableBuilder(
    column: $table.isPrimary,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get joinedAt => $composableBuilder(
    column: $table.joinedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$ProfilesTableFilterComposer get profileId {
    final $$ProfilesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.profileId,
      referencedTable: $db.profiles,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProfilesTableFilterComposer(
            $db: $db,
            $table: $db.profiles,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ProfileGroupsTableOrderingComposer
    extends Composer<_$AppDatabase, $ProfileGroupsTable> {
  $$ProfileGroupsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get mlsGroupId => $composableBuilder(
    column: $table.mlsGroupId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isPrimary => $composableBuilder(
    column: $table.isPrimary,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get joinedAt => $composableBuilder(
    column: $table.joinedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$ProfilesTableOrderingComposer get profileId {
    final $$ProfilesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.profileId,
      referencedTable: $db.profiles,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProfilesTableOrderingComposer(
            $db: $db,
            $table: $db.profiles,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ProfileGroupsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ProfileGroupsTable> {
  $$ProfileGroupsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get mlsGroupId => $composableBuilder(
    column: $table.mlsGroupId,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isPrimary =>
      $composableBuilder(column: $table.isPrimary, builder: (column) => column);

  GeneratedColumn<DateTime> get joinedAt =>
      $composableBuilder(column: $table.joinedAt, builder: (column) => column);

  $$ProfilesTableAnnotationComposer get profileId {
    final $$ProfilesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.profileId,
      referencedTable: $db.profiles,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProfilesTableAnnotationComposer(
            $db: $db,
            $table: $db.profiles,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ProfileGroupsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ProfileGroupsTable,
          ProfileGroup,
          $$ProfileGroupsTableFilterComposer,
          $$ProfileGroupsTableOrderingComposer,
          $$ProfileGroupsTableAnnotationComposer,
          $$ProfileGroupsTableCreateCompanionBuilder,
          $$ProfileGroupsTableUpdateCompanionBuilder,
          (ProfileGroup, $$ProfileGroupsTableReferences),
          ProfileGroup,
          PrefetchHooks Function({bool profileId})
        > {
  $$ProfileGroupsTableTableManager(_$AppDatabase db, $ProfileGroupsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ProfileGroupsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ProfileGroupsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ProfileGroupsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> profileId = const Value.absent(),
                Value<String> mlsGroupId = const Value.absent(),
                Value<bool> isPrimary = const Value.absent(),
                Value<DateTime> joinedAt = const Value.absent(),
              }) => ProfileGroupsCompanion(
                id: id,
                profileId: profileId,
                mlsGroupId: mlsGroupId,
                isPrimary: isPrimary,
                joinedAt: joinedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String profileId,
                required String mlsGroupId,
                Value<bool> isPrimary = const Value.absent(),
                required DateTime joinedAt,
              }) => ProfileGroupsCompanion.insert(
                id: id,
                profileId: profileId,
                mlsGroupId: mlsGroupId,
                isPrimary: isPrimary,
                joinedAt: joinedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$ProfileGroupsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({profileId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (profileId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.profileId,
                                referencedTable: $$ProfileGroupsTableReferences
                                    ._profileIdTable(db),
                                referencedColumn: $$ProfileGroupsTableReferences
                                    ._profileIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$ProfileGroupsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ProfileGroupsTable,
      ProfileGroup,
      $$ProfileGroupsTableFilterComposer,
      $$ProfileGroupsTableOrderingComposer,
      $$ProfileGroupsTableAnnotationComposer,
      $$ProfileGroupsTableCreateCompanionBuilder,
      $$ProfileGroupsTableUpdateCompanionBuilder,
      (ProfileGroup, $$ProfileGroupsTableReferences),
      ProfileGroup,
      PrefetchHooks Function({bool profileId})
    >;
typedef $$LocalVideosTableCreateCompanionBuilder =
    LocalVideosCompanion Function({
      required String id,
      required String profileId,
      required String filePath,
      required String thumbPath,
      Value<String> title,
      Value<double> durationSeconds,
      required DateTime createdAt,
      Value<DateTime?> lastPlayedAt,
      Value<int> playCount,
      Value<double> completionRate,
      Value<double> replayRate,
      Value<bool> liked,
      Value<bool> hidden,
      Value<List<String>> tags,
      Value<List<String>> cvLabels,
      Value<int> faceCount,
      Value<double> loudness,
      Value<DateTime?> reportedAt,
      Value<String?> reportReason,
      Value<String> approvalStatus,
      Value<DateTime?> approvedAt,
      Value<String?> approvedByParentKey,
      Value<String?> scanResults,
      Value<DateTime?> scanCompletedAt,
      Value<double?> aspectRatio,
      Value<int> rowid,
    });
typedef $$LocalVideosTableUpdateCompanionBuilder =
    LocalVideosCompanion Function({
      Value<String> id,
      Value<String> profileId,
      Value<String> filePath,
      Value<String> thumbPath,
      Value<String> title,
      Value<double> durationSeconds,
      Value<DateTime> createdAt,
      Value<DateTime?> lastPlayedAt,
      Value<int> playCount,
      Value<double> completionRate,
      Value<double> replayRate,
      Value<bool> liked,
      Value<bool> hidden,
      Value<List<String>> tags,
      Value<List<String>> cvLabels,
      Value<int> faceCount,
      Value<double> loudness,
      Value<DateTime?> reportedAt,
      Value<String?> reportReason,
      Value<String> approvalStatus,
      Value<DateTime?> approvedAt,
      Value<String?> approvedByParentKey,
      Value<String?> scanResults,
      Value<DateTime?> scanCompletedAt,
      Value<double?> aspectRatio,
      Value<int> rowid,
    });

final class $$LocalVideosTableReferences
    extends BaseReferences<_$AppDatabase, $LocalVideosTable, LocalVideo> {
  $$LocalVideosTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $ProfilesTable _profileIdTable(_$AppDatabase db) =>
      db.profiles.createAlias(
        $_aliasNameGenerator(db.localVideos.profileId, db.profiles.id),
      );

  $$ProfilesTableProcessedTableManager get profileId {
    final $_column = $_itemColumn<String>('profile_id')!;

    final manager = $$ProfilesTableTableManager(
      $_db,
      $_db.profiles,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_profileIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$LocalVideosTableFilterComposer
    extends Composer<_$AppDatabase, $LocalVideosTable> {
  $$LocalVideosTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get filePath => $composableBuilder(
    column: $table.filePath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get thumbPath => $composableBuilder(
    column: $table.thumbPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get durationSeconds => $composableBuilder(
    column: $table.durationSeconds,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastPlayedAt => $composableBuilder(
    column: $table.lastPlayedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get playCount => $composableBuilder(
    column: $table.playCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get completionRate => $composableBuilder(
    column: $table.completionRate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get replayRate => $composableBuilder(
    column: $table.replayRate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get liked => $composableBuilder(
    column: $table.liked,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get hidden => $composableBuilder(
    column: $table.hidden,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<List<String>, List<String>, String> get tags =>
      $composableBuilder(
        column: $table.tags,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnWithTypeConverterFilters<List<String>, List<String>, String>
  get cvLabels => $composableBuilder(
    column: $table.cvLabels,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<int> get faceCount => $composableBuilder(
    column: $table.faceCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get loudness => $composableBuilder(
    column: $table.loudness,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get reportedAt => $composableBuilder(
    column: $table.reportedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get reportReason => $composableBuilder(
    column: $table.reportReason,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get approvalStatus => $composableBuilder(
    column: $table.approvalStatus,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get approvedAt => $composableBuilder(
    column: $table.approvedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get approvedByParentKey => $composableBuilder(
    column: $table.approvedByParentKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get scanResults => $composableBuilder(
    column: $table.scanResults,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get scanCompletedAt => $composableBuilder(
    column: $table.scanCompletedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get aspectRatio => $composableBuilder(
    column: $table.aspectRatio,
    builder: (column) => ColumnFilters(column),
  );

  $$ProfilesTableFilterComposer get profileId {
    final $$ProfilesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.profileId,
      referencedTable: $db.profiles,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProfilesTableFilterComposer(
            $db: $db,
            $table: $db.profiles,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$LocalVideosTableOrderingComposer
    extends Composer<_$AppDatabase, $LocalVideosTable> {
  $$LocalVideosTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get filePath => $composableBuilder(
    column: $table.filePath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get thumbPath => $composableBuilder(
    column: $table.thumbPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get durationSeconds => $composableBuilder(
    column: $table.durationSeconds,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastPlayedAt => $composableBuilder(
    column: $table.lastPlayedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get playCount => $composableBuilder(
    column: $table.playCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get completionRate => $composableBuilder(
    column: $table.completionRate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get replayRate => $composableBuilder(
    column: $table.replayRate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get liked => $composableBuilder(
    column: $table.liked,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get hidden => $composableBuilder(
    column: $table.hidden,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tags => $composableBuilder(
    column: $table.tags,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get cvLabels => $composableBuilder(
    column: $table.cvLabels,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get faceCount => $composableBuilder(
    column: $table.faceCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get loudness => $composableBuilder(
    column: $table.loudness,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get reportedAt => $composableBuilder(
    column: $table.reportedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get reportReason => $composableBuilder(
    column: $table.reportReason,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get approvalStatus => $composableBuilder(
    column: $table.approvalStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get approvedAt => $composableBuilder(
    column: $table.approvedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get approvedByParentKey => $composableBuilder(
    column: $table.approvedByParentKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get scanResults => $composableBuilder(
    column: $table.scanResults,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get scanCompletedAt => $composableBuilder(
    column: $table.scanCompletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get aspectRatio => $composableBuilder(
    column: $table.aspectRatio,
    builder: (column) => ColumnOrderings(column),
  );

  $$ProfilesTableOrderingComposer get profileId {
    final $$ProfilesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.profileId,
      referencedTable: $db.profiles,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProfilesTableOrderingComposer(
            $db: $db,
            $table: $db.profiles,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$LocalVideosTableAnnotationComposer
    extends Composer<_$AppDatabase, $LocalVideosTable> {
  $$LocalVideosTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get filePath =>
      $composableBuilder(column: $table.filePath, builder: (column) => column);

  GeneratedColumn<String> get thumbPath =>
      $composableBuilder(column: $table.thumbPath, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<double> get durationSeconds => $composableBuilder(
    column: $table.durationSeconds,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get lastPlayedAt => $composableBuilder(
    column: $table.lastPlayedAt,
    builder: (column) => column,
  );

  GeneratedColumn<int> get playCount =>
      $composableBuilder(column: $table.playCount, builder: (column) => column);

  GeneratedColumn<double> get completionRate => $composableBuilder(
    column: $table.completionRate,
    builder: (column) => column,
  );

  GeneratedColumn<double> get replayRate => $composableBuilder(
    column: $table.replayRate,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get liked =>
      $composableBuilder(column: $table.liked, builder: (column) => column);

  GeneratedColumn<bool> get hidden =>
      $composableBuilder(column: $table.hidden, builder: (column) => column);

  GeneratedColumnWithTypeConverter<List<String>, String> get tags =>
      $composableBuilder(column: $table.tags, builder: (column) => column);

  GeneratedColumnWithTypeConverter<List<String>, String> get cvLabels =>
      $composableBuilder(column: $table.cvLabels, builder: (column) => column);

  GeneratedColumn<int> get faceCount =>
      $composableBuilder(column: $table.faceCount, builder: (column) => column);

  GeneratedColumn<double> get loudness =>
      $composableBuilder(column: $table.loudness, builder: (column) => column);

  GeneratedColumn<DateTime> get reportedAt => $composableBuilder(
    column: $table.reportedAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get reportReason => $composableBuilder(
    column: $table.reportReason,
    builder: (column) => column,
  );

  GeneratedColumn<String> get approvalStatus => $composableBuilder(
    column: $table.approvalStatus,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get approvedAt => $composableBuilder(
    column: $table.approvedAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get approvedByParentKey => $composableBuilder(
    column: $table.approvedByParentKey,
    builder: (column) => column,
  );

  GeneratedColumn<String> get scanResults => $composableBuilder(
    column: $table.scanResults,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get scanCompletedAt => $composableBuilder(
    column: $table.scanCompletedAt,
    builder: (column) => column,
  );

  GeneratedColumn<double> get aspectRatio => $composableBuilder(
    column: $table.aspectRatio,
    builder: (column) => column,
  );

  $$ProfilesTableAnnotationComposer get profileId {
    final $$ProfilesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.profileId,
      referencedTable: $db.profiles,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProfilesTableAnnotationComposer(
            $db: $db,
            $table: $db.profiles,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$LocalVideosTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LocalVideosTable,
          LocalVideo,
          $$LocalVideosTableFilterComposer,
          $$LocalVideosTableOrderingComposer,
          $$LocalVideosTableAnnotationComposer,
          $$LocalVideosTableCreateCompanionBuilder,
          $$LocalVideosTableUpdateCompanionBuilder,
          (LocalVideo, $$LocalVideosTableReferences),
          LocalVideo,
          PrefetchHooks Function({bool profileId})
        > {
  $$LocalVideosTableTableManager(_$AppDatabase db, $LocalVideosTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalVideosTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LocalVideosTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LocalVideosTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> profileId = const Value.absent(),
                Value<String> filePath = const Value.absent(),
                Value<String> thumbPath = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<double> durationSeconds = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime?> lastPlayedAt = const Value.absent(),
                Value<int> playCount = const Value.absent(),
                Value<double> completionRate = const Value.absent(),
                Value<double> replayRate = const Value.absent(),
                Value<bool> liked = const Value.absent(),
                Value<bool> hidden = const Value.absent(),
                Value<List<String>> tags = const Value.absent(),
                Value<List<String>> cvLabels = const Value.absent(),
                Value<int> faceCount = const Value.absent(),
                Value<double> loudness = const Value.absent(),
                Value<DateTime?> reportedAt = const Value.absent(),
                Value<String?> reportReason = const Value.absent(),
                Value<String> approvalStatus = const Value.absent(),
                Value<DateTime?> approvedAt = const Value.absent(),
                Value<String?> approvedByParentKey = const Value.absent(),
                Value<String?> scanResults = const Value.absent(),
                Value<DateTime?> scanCompletedAt = const Value.absent(),
                Value<double?> aspectRatio = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalVideosCompanion(
                id: id,
                profileId: profileId,
                filePath: filePath,
                thumbPath: thumbPath,
                title: title,
                durationSeconds: durationSeconds,
                createdAt: createdAt,
                lastPlayedAt: lastPlayedAt,
                playCount: playCount,
                completionRate: completionRate,
                replayRate: replayRate,
                liked: liked,
                hidden: hidden,
                tags: tags,
                cvLabels: cvLabels,
                faceCount: faceCount,
                loudness: loudness,
                reportedAt: reportedAt,
                reportReason: reportReason,
                approvalStatus: approvalStatus,
                approvedAt: approvedAt,
                approvedByParentKey: approvedByParentKey,
                scanResults: scanResults,
                scanCompletedAt: scanCompletedAt,
                aspectRatio: aspectRatio,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String profileId,
                required String filePath,
                required String thumbPath,
                Value<String> title = const Value.absent(),
                Value<double> durationSeconds = const Value.absent(),
                required DateTime createdAt,
                Value<DateTime?> lastPlayedAt = const Value.absent(),
                Value<int> playCount = const Value.absent(),
                Value<double> completionRate = const Value.absent(),
                Value<double> replayRate = const Value.absent(),
                Value<bool> liked = const Value.absent(),
                Value<bool> hidden = const Value.absent(),
                Value<List<String>> tags = const Value.absent(),
                Value<List<String>> cvLabels = const Value.absent(),
                Value<int> faceCount = const Value.absent(),
                Value<double> loudness = const Value.absent(),
                Value<DateTime?> reportedAt = const Value.absent(),
                Value<String?> reportReason = const Value.absent(),
                Value<String> approvalStatus = const Value.absent(),
                Value<DateTime?> approvedAt = const Value.absent(),
                Value<String?> approvedByParentKey = const Value.absent(),
                Value<String?> scanResults = const Value.absent(),
                Value<DateTime?> scanCompletedAt = const Value.absent(),
                Value<double?> aspectRatio = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalVideosCompanion.insert(
                id: id,
                profileId: profileId,
                filePath: filePath,
                thumbPath: thumbPath,
                title: title,
                durationSeconds: durationSeconds,
                createdAt: createdAt,
                lastPlayedAt: lastPlayedAt,
                playCount: playCount,
                completionRate: completionRate,
                replayRate: replayRate,
                liked: liked,
                hidden: hidden,
                tags: tags,
                cvLabels: cvLabels,
                faceCount: faceCount,
                loudness: loudness,
                reportedAt: reportedAt,
                reportReason: reportReason,
                approvalStatus: approvalStatus,
                approvedAt: approvedAt,
                approvedByParentKey: approvedByParentKey,
                scanResults: scanResults,
                scanCompletedAt: scanCompletedAt,
                aspectRatio: aspectRatio,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$LocalVideosTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({profileId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (profileId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.profileId,
                                referencedTable: $$LocalVideosTableReferences
                                    ._profileIdTable(db),
                                referencedColumn: $$LocalVideosTableReferences
                                    ._profileIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$LocalVideosTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LocalVideosTable,
      LocalVideo,
      $$LocalVideosTableFilterComposer,
      $$LocalVideosTableOrderingComposer,
      $$LocalVideosTableAnnotationComposer,
      $$LocalVideosTableCreateCompanionBuilder,
      $$LocalVideosTableUpdateCompanionBuilder,
      (LocalVideo, $$LocalVideosTableReferences),
      LocalVideo,
      PrefetchHooks Function({bool profileId})
    >;
typedef $$RemoteAssetsTableCreateCompanionBuilder =
    RemoteAssetsCompanion Function({
      required String remoteShareId,
      required String videoId,
      Value<String?> blobHash,
      Value<String?> thumbHash,
      Value<String?> epoch,
      Value<String?> mime,
      Value<String?> metadataJson,
      Value<String?> localMediaPath,
      Value<String?> localThumbPath,
      Value<double?> aspectRatio,
      Value<int> rowid,
    });
typedef $$RemoteAssetsTableUpdateCompanionBuilder =
    RemoteAssetsCompanion Function({
      Value<String> remoteShareId,
      Value<String> videoId,
      Value<String?> blobHash,
      Value<String?> thumbHash,
      Value<String?> epoch,
      Value<String?> mime,
      Value<String?> metadataJson,
      Value<String?> localMediaPath,
      Value<String?> localThumbPath,
      Value<double?> aspectRatio,
      Value<int> rowid,
    });

final class $$RemoteAssetsTableReferences
    extends BaseReferences<_$AppDatabase, $RemoteAssetsTable, RemoteAsset> {
  $$RemoteAssetsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$ShareRecordsTable, List<ShareRecord>>
  _shareRecordsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.shareRecords,
    aliasName: $_aliasNameGenerator(
      db.remoteAssets.remoteShareId,
      db.shareRecords.remoteShareId,
    ),
  );

  $$ShareRecordsTableProcessedTableManager get shareRecordsRefs {
    final manager = $$ShareRecordsTableTableManager($_db, $_db.shareRecords)
        .filter(
          (f) => f.remoteShareId.remoteShareId.sqlEquals(
            $_itemColumn<String>('remote_share_id')!,
          ),
        );

    final cache = $_typedResult.readTableOrNull(_shareRecordsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$RemoteAssetsTableFilterComposer
    extends Composer<_$AppDatabase, $RemoteAssetsTable> {
  $$RemoteAssetsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get remoteShareId => $composableBuilder(
    column: $table.remoteShareId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get videoId => $composableBuilder(
    column: $table.videoId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get blobHash => $composableBuilder(
    column: $table.blobHash,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get thumbHash => $composableBuilder(
    column: $table.thumbHash,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get epoch => $composableBuilder(
    column: $table.epoch,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get mime => $composableBuilder(
    column: $table.mime,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get metadataJson => $composableBuilder(
    column: $table.metadataJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get localMediaPath => $composableBuilder(
    column: $table.localMediaPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get localThumbPath => $composableBuilder(
    column: $table.localThumbPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get aspectRatio => $composableBuilder(
    column: $table.aspectRatio,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> shareRecordsRefs(
    Expression<bool> Function($$ShareRecordsTableFilterComposer f) f,
  ) {
    final $$ShareRecordsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.remoteShareId,
      referencedTable: $db.shareRecords,
      getReferencedColumn: (t) => t.remoteShareId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ShareRecordsTableFilterComposer(
            $db: $db,
            $table: $db.shareRecords,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$RemoteAssetsTableOrderingComposer
    extends Composer<_$AppDatabase, $RemoteAssetsTable> {
  $$RemoteAssetsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get remoteShareId => $composableBuilder(
    column: $table.remoteShareId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get videoId => $composableBuilder(
    column: $table.videoId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get blobHash => $composableBuilder(
    column: $table.blobHash,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get thumbHash => $composableBuilder(
    column: $table.thumbHash,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get epoch => $composableBuilder(
    column: $table.epoch,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get mime => $composableBuilder(
    column: $table.mime,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get metadataJson => $composableBuilder(
    column: $table.metadataJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get localMediaPath => $composableBuilder(
    column: $table.localMediaPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get localThumbPath => $composableBuilder(
    column: $table.localThumbPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get aspectRatio => $composableBuilder(
    column: $table.aspectRatio,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$RemoteAssetsTableAnnotationComposer
    extends Composer<_$AppDatabase, $RemoteAssetsTable> {
  $$RemoteAssetsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get remoteShareId => $composableBuilder(
    column: $table.remoteShareId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get videoId =>
      $composableBuilder(column: $table.videoId, builder: (column) => column);

  GeneratedColumn<String> get blobHash =>
      $composableBuilder(column: $table.blobHash, builder: (column) => column);

  GeneratedColumn<String> get thumbHash =>
      $composableBuilder(column: $table.thumbHash, builder: (column) => column);

  GeneratedColumn<String> get epoch =>
      $composableBuilder(column: $table.epoch, builder: (column) => column);

  GeneratedColumn<String> get mime =>
      $composableBuilder(column: $table.mime, builder: (column) => column);

  GeneratedColumn<String> get metadataJson => $composableBuilder(
    column: $table.metadataJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get localMediaPath => $composableBuilder(
    column: $table.localMediaPath,
    builder: (column) => column,
  );

  GeneratedColumn<String> get localThumbPath => $composableBuilder(
    column: $table.localThumbPath,
    builder: (column) => column,
  );

  GeneratedColumn<double> get aspectRatio => $composableBuilder(
    column: $table.aspectRatio,
    builder: (column) => column,
  );

  Expression<T> shareRecordsRefs<T extends Object>(
    Expression<T> Function($$ShareRecordsTableAnnotationComposer a) f,
  ) {
    final $$ShareRecordsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.remoteShareId,
      referencedTable: $db.shareRecords,
      getReferencedColumn: (t) => t.remoteShareId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ShareRecordsTableAnnotationComposer(
            $db: $db,
            $table: $db.shareRecords,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$RemoteAssetsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $RemoteAssetsTable,
          RemoteAsset,
          $$RemoteAssetsTableFilterComposer,
          $$RemoteAssetsTableOrderingComposer,
          $$RemoteAssetsTableAnnotationComposer,
          $$RemoteAssetsTableCreateCompanionBuilder,
          $$RemoteAssetsTableUpdateCompanionBuilder,
          (RemoteAsset, $$RemoteAssetsTableReferences),
          RemoteAsset,
          PrefetchHooks Function({bool shareRecordsRefs})
        > {
  $$RemoteAssetsTableTableManager(_$AppDatabase db, $RemoteAssetsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RemoteAssetsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$RemoteAssetsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$RemoteAssetsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> remoteShareId = const Value.absent(),
                Value<String> videoId = const Value.absent(),
                Value<String?> blobHash = const Value.absent(),
                Value<String?> thumbHash = const Value.absent(),
                Value<String?> epoch = const Value.absent(),
                Value<String?> mime = const Value.absent(),
                Value<String?> metadataJson = const Value.absent(),
                Value<String?> localMediaPath = const Value.absent(),
                Value<String?> localThumbPath = const Value.absent(),
                Value<double?> aspectRatio = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => RemoteAssetsCompanion(
                remoteShareId: remoteShareId,
                videoId: videoId,
                blobHash: blobHash,
                thumbHash: thumbHash,
                epoch: epoch,
                mime: mime,
                metadataJson: metadataJson,
                localMediaPath: localMediaPath,
                localThumbPath: localThumbPath,
                aspectRatio: aspectRatio,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String remoteShareId,
                required String videoId,
                Value<String?> blobHash = const Value.absent(),
                Value<String?> thumbHash = const Value.absent(),
                Value<String?> epoch = const Value.absent(),
                Value<String?> mime = const Value.absent(),
                Value<String?> metadataJson = const Value.absent(),
                Value<String?> localMediaPath = const Value.absent(),
                Value<String?> localThumbPath = const Value.absent(),
                Value<double?> aspectRatio = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => RemoteAssetsCompanion.insert(
                remoteShareId: remoteShareId,
                videoId: videoId,
                blobHash: blobHash,
                thumbHash: thumbHash,
                epoch: epoch,
                mime: mime,
                metadataJson: metadataJson,
                localMediaPath: localMediaPath,
                localThumbPath: localThumbPath,
                aspectRatio: aspectRatio,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$RemoteAssetsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({shareRecordsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (shareRecordsRefs) db.shareRecords],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (shareRecordsRefs)
                    await $_getPrefetchedData<
                      RemoteAsset,
                      $RemoteAssetsTable,
                      ShareRecord
                    >(
                      currentTable: table,
                      referencedTable: $$RemoteAssetsTableReferences
                          ._shareRecordsRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$RemoteAssetsTableReferences(
                            db,
                            table,
                            p0,
                          ).shareRecordsRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where(
                            (e) => e.remoteShareId == item.remoteShareId,
                          ),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$RemoteAssetsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $RemoteAssetsTable,
      RemoteAsset,
      $$RemoteAssetsTableFilterComposer,
      $$RemoteAssetsTableOrderingComposer,
      $$RemoteAssetsTableAnnotationComposer,
      $$RemoteAssetsTableCreateCompanionBuilder,
      $$RemoteAssetsTableUpdateCompanionBuilder,
      (RemoteAsset, $$RemoteAssetsTableReferences),
      RemoteAsset,
      PrefetchHooks Function({bool shareRecordsRefs})
    >;
typedef $$ShareRecordsTableCreateCompanionBuilder =
    ShareRecordsCompanion Function({
      required String remoteShareId,
      required String videoId,
      required String mlsGroupId,
      required String senderParentKey,
      required String childProfileId,
      Value<String?> childDisplayName,
      Value<String> status,
      required DateTime receivedAt,
      Value<String?> downloadError,
      Value<int> rowid,
    });
typedef $$ShareRecordsTableUpdateCompanionBuilder =
    ShareRecordsCompanion Function({
      Value<String> remoteShareId,
      Value<String> videoId,
      Value<String> mlsGroupId,
      Value<String> senderParentKey,
      Value<String> childProfileId,
      Value<String?> childDisplayName,
      Value<String> status,
      Value<DateTime> receivedAt,
      Value<String?> downloadError,
      Value<int> rowid,
    });

final class $$ShareRecordsTableReferences
    extends BaseReferences<_$AppDatabase, $ShareRecordsTable, ShareRecord> {
  $$ShareRecordsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $RemoteAssetsTable _remoteShareIdTable(_$AppDatabase db) =>
      db.remoteAssets.createAlias(
        $_aliasNameGenerator(
          db.shareRecords.remoteShareId,
          db.remoteAssets.remoteShareId,
        ),
      );

  $$RemoteAssetsTableProcessedTableManager get remoteShareId {
    final $_column = $_itemColumn<String>('remote_share_id')!;

    final manager = $$RemoteAssetsTableTableManager(
      $_db,
      $_db.remoteAssets,
    ).filter((f) => f.remoteShareId.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_remoteShareIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$ShareRecordsTableFilterComposer
    extends Composer<_$AppDatabase, $ShareRecordsTable> {
  $$ShareRecordsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get videoId => $composableBuilder(
    column: $table.videoId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get mlsGroupId => $composableBuilder(
    column: $table.mlsGroupId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get senderParentKey => $composableBuilder(
    column: $table.senderParentKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get childProfileId => $composableBuilder(
    column: $table.childProfileId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get childDisplayName => $composableBuilder(
    column: $table.childDisplayName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get receivedAt => $composableBuilder(
    column: $table.receivedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get downloadError => $composableBuilder(
    column: $table.downloadError,
    builder: (column) => ColumnFilters(column),
  );

  $$RemoteAssetsTableFilterComposer get remoteShareId {
    final $$RemoteAssetsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.remoteShareId,
      referencedTable: $db.remoteAssets,
      getReferencedColumn: (t) => t.remoteShareId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RemoteAssetsTableFilterComposer(
            $db: $db,
            $table: $db.remoteAssets,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ShareRecordsTableOrderingComposer
    extends Composer<_$AppDatabase, $ShareRecordsTable> {
  $$ShareRecordsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get videoId => $composableBuilder(
    column: $table.videoId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get mlsGroupId => $composableBuilder(
    column: $table.mlsGroupId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get senderParentKey => $composableBuilder(
    column: $table.senderParentKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get childProfileId => $composableBuilder(
    column: $table.childProfileId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get childDisplayName => $composableBuilder(
    column: $table.childDisplayName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get receivedAt => $composableBuilder(
    column: $table.receivedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get downloadError => $composableBuilder(
    column: $table.downloadError,
    builder: (column) => ColumnOrderings(column),
  );

  $$RemoteAssetsTableOrderingComposer get remoteShareId {
    final $$RemoteAssetsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.remoteShareId,
      referencedTable: $db.remoteAssets,
      getReferencedColumn: (t) => t.remoteShareId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RemoteAssetsTableOrderingComposer(
            $db: $db,
            $table: $db.remoteAssets,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ShareRecordsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ShareRecordsTable> {
  $$ShareRecordsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get videoId =>
      $composableBuilder(column: $table.videoId, builder: (column) => column);

  GeneratedColumn<String> get mlsGroupId => $composableBuilder(
    column: $table.mlsGroupId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get senderParentKey => $composableBuilder(
    column: $table.senderParentKey,
    builder: (column) => column,
  );

  GeneratedColumn<String> get childProfileId => $composableBuilder(
    column: $table.childProfileId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get childDisplayName => $composableBuilder(
    column: $table.childDisplayName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<DateTime> get receivedAt => $composableBuilder(
    column: $table.receivedAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get downloadError => $composableBuilder(
    column: $table.downloadError,
    builder: (column) => column,
  );

  $$RemoteAssetsTableAnnotationComposer get remoteShareId {
    final $$RemoteAssetsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.remoteShareId,
      referencedTable: $db.remoteAssets,
      getReferencedColumn: (t) => t.remoteShareId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RemoteAssetsTableAnnotationComposer(
            $db: $db,
            $table: $db.remoteAssets,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ShareRecordsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ShareRecordsTable,
          ShareRecord,
          $$ShareRecordsTableFilterComposer,
          $$ShareRecordsTableOrderingComposer,
          $$ShareRecordsTableAnnotationComposer,
          $$ShareRecordsTableCreateCompanionBuilder,
          $$ShareRecordsTableUpdateCompanionBuilder,
          (ShareRecord, $$ShareRecordsTableReferences),
          ShareRecord,
          PrefetchHooks Function({bool remoteShareId})
        > {
  $$ShareRecordsTableTableManager(_$AppDatabase db, $ShareRecordsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ShareRecordsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ShareRecordsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ShareRecordsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> remoteShareId = const Value.absent(),
                Value<String> videoId = const Value.absent(),
                Value<String> mlsGroupId = const Value.absent(),
                Value<String> senderParentKey = const Value.absent(),
                Value<String> childProfileId = const Value.absent(),
                Value<String?> childDisplayName = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<DateTime> receivedAt = const Value.absent(),
                Value<String?> downloadError = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ShareRecordsCompanion(
                remoteShareId: remoteShareId,
                videoId: videoId,
                mlsGroupId: mlsGroupId,
                senderParentKey: senderParentKey,
                childProfileId: childProfileId,
                childDisplayName: childDisplayName,
                status: status,
                receivedAt: receivedAt,
                downloadError: downloadError,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String remoteShareId,
                required String videoId,
                required String mlsGroupId,
                required String senderParentKey,
                required String childProfileId,
                Value<String?> childDisplayName = const Value.absent(),
                Value<String> status = const Value.absent(),
                required DateTime receivedAt,
                Value<String?> downloadError = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ShareRecordsCompanion.insert(
                remoteShareId: remoteShareId,
                videoId: videoId,
                mlsGroupId: mlsGroupId,
                senderParentKey: senderParentKey,
                childProfileId: childProfileId,
                childDisplayName: childDisplayName,
                status: status,
                receivedAt: receivedAt,
                downloadError: downloadError,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$ShareRecordsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({remoteShareId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (remoteShareId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.remoteShareId,
                                referencedTable: $$ShareRecordsTableReferences
                                    ._remoteShareIdTable(db),
                                referencedColumn: $$ShareRecordsTableReferences
                                    ._remoteShareIdTable(db)
                                    .remoteShareId,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$ShareRecordsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ShareRecordsTable,
      ShareRecord,
      $$ShareRecordsTableFilterComposer,
      $$ShareRecordsTableOrderingComposer,
      $$ShareRecordsTableAnnotationComposer,
      $$ShareRecordsTableCreateCompanionBuilder,
      $$ShareRecordsTableUpdateCompanionBuilder,
      (ShareRecord, $$ShareRecordsTableReferences),
      ShareRecord,
      PrefetchHooks Function({bool remoteShareId})
    >;
typedef $$LikesTableCreateCompanionBuilder =
    LikesCompanion Function({
      Value<int> id,
      required String videoId,
      required String childProfileId,
      required String parentPubkey,
      required DateTime createdAt,
    });
typedef $$LikesTableUpdateCompanionBuilder =
    LikesCompanion Function({
      Value<int> id,
      Value<String> videoId,
      Value<String> childProfileId,
      Value<String> parentPubkey,
      Value<DateTime> createdAt,
    });

class $$LikesTableFilterComposer extends Composer<_$AppDatabase, $LikesTable> {
  $$LikesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get videoId => $composableBuilder(
    column: $table.videoId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get childProfileId => $composableBuilder(
    column: $table.childProfileId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get parentPubkey => $composableBuilder(
    column: $table.parentPubkey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LikesTableOrderingComposer
    extends Composer<_$AppDatabase, $LikesTable> {
  $$LikesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get videoId => $composableBuilder(
    column: $table.videoId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get childProfileId => $composableBuilder(
    column: $table.childProfileId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get parentPubkey => $composableBuilder(
    column: $table.parentPubkey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LikesTableAnnotationComposer
    extends Composer<_$AppDatabase, $LikesTable> {
  $$LikesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get videoId =>
      $composableBuilder(column: $table.videoId, builder: (column) => column);

  GeneratedColumn<String> get childProfileId => $composableBuilder(
    column: $table.childProfileId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get parentPubkey => $composableBuilder(
    column: $table.parentPubkey,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$LikesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LikesTable,
          Like,
          $$LikesTableFilterComposer,
          $$LikesTableOrderingComposer,
          $$LikesTableAnnotationComposer,
          $$LikesTableCreateCompanionBuilder,
          $$LikesTableUpdateCompanionBuilder,
          (Like, BaseReferences<_$AppDatabase, $LikesTable, Like>),
          Like,
          PrefetchHooks Function()
        > {
  $$LikesTableTableManager(_$AppDatabase db, $LikesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LikesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LikesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LikesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> videoId = const Value.absent(),
                Value<String> childProfileId = const Value.absent(),
                Value<String> parentPubkey = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => LikesCompanion(
                id: id,
                videoId: videoId,
                childProfileId: childProfileId,
                parentPubkey: parentPubkey,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String videoId,
                required String childProfileId,
                required String parentPubkey,
                required DateTime createdAt,
              }) => LikesCompanion.insert(
                id: id,
                videoId: videoId,
                childProfileId: childProfileId,
                parentPubkey: parentPubkey,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LikesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LikesTable,
      Like,
      $$LikesTableFilterComposer,
      $$LikesTableOrderingComposer,
      $$LikesTableAnnotationComposer,
      $$LikesTableCreateCompanionBuilder,
      $$LikesTableUpdateCompanionBuilder,
      (Like, BaseReferences<_$AppDatabase, $LikesTable, Like>),
      Like,
      PrefetchHooks Function()
    >;
typedef $$ReactionsTableCreateCompanionBuilder =
    ReactionsCompanion Function({
      Value<int> id,
      required String videoId,
      required String childProfileId,
      required String parentPubkey,
      required String emoji,
      required DateTime createdAt,
    });
typedef $$ReactionsTableUpdateCompanionBuilder =
    ReactionsCompanion Function({
      Value<int> id,
      Value<String> videoId,
      Value<String> childProfileId,
      Value<String> parentPubkey,
      Value<String> emoji,
      Value<DateTime> createdAt,
    });

class $$ReactionsTableFilterComposer
    extends Composer<_$AppDatabase, $ReactionsTable> {
  $$ReactionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get videoId => $composableBuilder(
    column: $table.videoId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get childProfileId => $composableBuilder(
    column: $table.childProfileId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get parentPubkey => $composableBuilder(
    column: $table.parentPubkey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get emoji => $composableBuilder(
    column: $table.emoji,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ReactionsTableOrderingComposer
    extends Composer<_$AppDatabase, $ReactionsTable> {
  $$ReactionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get videoId => $composableBuilder(
    column: $table.videoId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get childProfileId => $composableBuilder(
    column: $table.childProfileId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get parentPubkey => $composableBuilder(
    column: $table.parentPubkey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get emoji => $composableBuilder(
    column: $table.emoji,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ReactionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ReactionsTable> {
  $$ReactionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get videoId =>
      $composableBuilder(column: $table.videoId, builder: (column) => column);

  GeneratedColumn<String> get childProfileId => $composableBuilder(
    column: $table.childProfileId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get parentPubkey => $composableBuilder(
    column: $table.parentPubkey,
    builder: (column) => column,
  );

  GeneratedColumn<String> get emoji =>
      $composableBuilder(column: $table.emoji, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$ReactionsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ReactionsTable,
          Reaction,
          $$ReactionsTableFilterComposer,
          $$ReactionsTableOrderingComposer,
          $$ReactionsTableAnnotationComposer,
          $$ReactionsTableCreateCompanionBuilder,
          $$ReactionsTableUpdateCompanionBuilder,
          (Reaction, BaseReferences<_$AppDatabase, $ReactionsTable, Reaction>),
          Reaction,
          PrefetchHooks Function()
        > {
  $$ReactionsTableTableManager(_$AppDatabase db, $ReactionsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ReactionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ReactionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ReactionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> videoId = const Value.absent(),
                Value<String> childProfileId = const Value.absent(),
                Value<String> parentPubkey = const Value.absent(),
                Value<String> emoji = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => ReactionsCompanion(
                id: id,
                videoId: videoId,
                childProfileId: childProfileId,
                parentPubkey: parentPubkey,
                emoji: emoji,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String videoId,
                required String childProfileId,
                required String parentPubkey,
                required String emoji,
                required DateTime createdAt,
              }) => ReactionsCompanion.insert(
                id: id,
                videoId: videoId,
                childProfileId: childProfileId,
                parentPubkey: parentPubkey,
                emoji: emoji,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ReactionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ReactionsTable,
      Reaction,
      $$ReactionsTableFilterComposer,
      $$ReactionsTableOrderingComposer,
      $$ReactionsTableAnnotationComposer,
      $$ReactionsTableCreateCompanionBuilder,
      $$ReactionsTableUpdateCompanionBuilder,
      (Reaction, BaseReferences<_$AppDatabase, $ReactionsTable, Reaction>),
      Reaction,
      PrefetchHooks Function()
    >;
typedef $$RemotePlaybackMetricsTableCreateCompanionBuilder =
    RemotePlaybackMetricsCompanion Function({
      required String remoteShareId,
      required String videoId,
      Value<DateTime?> lastPlayedAt,
      Value<int> playCount,
      Value<double> completionRate,
      Value<double> replayRate,
      Value<int> rowid,
    });
typedef $$RemotePlaybackMetricsTableUpdateCompanionBuilder =
    RemotePlaybackMetricsCompanion Function({
      Value<String> remoteShareId,
      Value<String> videoId,
      Value<DateTime?> lastPlayedAt,
      Value<int> playCount,
      Value<double> completionRate,
      Value<double> replayRate,
      Value<int> rowid,
    });

class $$RemotePlaybackMetricsTableFilterComposer
    extends Composer<_$AppDatabase, $RemotePlaybackMetricsTable> {
  $$RemotePlaybackMetricsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get videoId => $composableBuilder(
    column: $table.videoId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastPlayedAt => $composableBuilder(
    column: $table.lastPlayedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get playCount => $composableBuilder(
    column: $table.playCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get completionRate => $composableBuilder(
    column: $table.completionRate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get replayRate => $composableBuilder(
    column: $table.replayRate,
    builder: (column) => ColumnFilters(column),
  );
}

class $$RemotePlaybackMetricsTableOrderingComposer
    extends Composer<_$AppDatabase, $RemotePlaybackMetricsTable> {
  $$RemotePlaybackMetricsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get videoId => $composableBuilder(
    column: $table.videoId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastPlayedAt => $composableBuilder(
    column: $table.lastPlayedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get playCount => $composableBuilder(
    column: $table.playCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get completionRate => $composableBuilder(
    column: $table.completionRate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get replayRate => $composableBuilder(
    column: $table.replayRate,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$RemotePlaybackMetricsTableAnnotationComposer
    extends Composer<_$AppDatabase, $RemotePlaybackMetricsTable> {
  $$RemotePlaybackMetricsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get videoId =>
      $composableBuilder(column: $table.videoId, builder: (column) => column);

  GeneratedColumn<DateTime> get lastPlayedAt => $composableBuilder(
    column: $table.lastPlayedAt,
    builder: (column) => column,
  );

  GeneratedColumn<int> get playCount =>
      $composableBuilder(column: $table.playCount, builder: (column) => column);

  GeneratedColumn<double> get completionRate => $composableBuilder(
    column: $table.completionRate,
    builder: (column) => column,
  );

  GeneratedColumn<double> get replayRate => $composableBuilder(
    column: $table.replayRate,
    builder: (column) => column,
  );
}

class $$RemotePlaybackMetricsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $RemotePlaybackMetricsTable,
          RemotePlaybackMetric,
          $$RemotePlaybackMetricsTableFilterComposer,
          $$RemotePlaybackMetricsTableOrderingComposer,
          $$RemotePlaybackMetricsTableAnnotationComposer,
          $$RemotePlaybackMetricsTableCreateCompanionBuilder,
          $$RemotePlaybackMetricsTableUpdateCompanionBuilder,
          (
            RemotePlaybackMetric,
            BaseReferences<
              _$AppDatabase,
              $RemotePlaybackMetricsTable,
              RemotePlaybackMetric
            >,
          ),
          RemotePlaybackMetric,
          PrefetchHooks Function()
        > {
  $$RemotePlaybackMetricsTableTableManager(
    _$AppDatabase db,
    $RemotePlaybackMetricsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RemotePlaybackMetricsTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$RemotePlaybackMetricsTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$RemotePlaybackMetricsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> remoteShareId = const Value.absent(),
                Value<String> videoId = const Value.absent(),
                Value<DateTime?> lastPlayedAt = const Value.absent(),
                Value<int> playCount = const Value.absent(),
                Value<double> completionRate = const Value.absent(),
                Value<double> replayRate = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => RemotePlaybackMetricsCompanion(
                remoteShareId: remoteShareId,
                videoId: videoId,
                lastPlayedAt: lastPlayedAt,
                playCount: playCount,
                completionRate: completionRate,
                replayRate: replayRate,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String remoteShareId,
                required String videoId,
                Value<DateTime?> lastPlayedAt = const Value.absent(),
                Value<int> playCount = const Value.absent(),
                Value<double> completionRate = const Value.absent(),
                Value<double> replayRate = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => RemotePlaybackMetricsCompanion.insert(
                remoteShareId: remoteShareId,
                videoId: videoId,
                lastPlayedAt: lastPlayedAt,
                playCount: playCount,
                completionRate: completionRate,
                replayRate: replayRate,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$RemotePlaybackMetricsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $RemotePlaybackMetricsTable,
      RemotePlaybackMetric,
      $$RemotePlaybackMetricsTableFilterComposer,
      $$RemotePlaybackMetricsTableOrderingComposer,
      $$RemotePlaybackMetricsTableAnnotationComposer,
      $$RemotePlaybackMetricsTableCreateCompanionBuilder,
      $$RemotePlaybackMetricsTableUpdateCompanionBuilder,
      (
        RemotePlaybackMetric,
        BaseReferences<
          _$AppDatabase,
          $RemotePlaybackMetricsTable,
          RemotePlaybackMetric
        >,
      ),
      RemotePlaybackMetric,
      PrefetchHooks Function()
    >;
typedef $$ReportsTableCreateCompanionBuilder =
    ReportsCompanion Function({
      required String id,
      required String videoId,
      required String subjectChildId,
      Value<String?> blobHash,
      required String reason,
      Value<String?> note,
      Value<int> level,
      Value<String> recipientType,
      Value<String?> reporterChildId,
      required String reporterParentKey,
      Value<String> status,
      Value<String?> actionTaken,
      Value<bool> isOutbound,
      required DateTime createdAt,
      Value<DateTime?> deliveredAt,
      Value<int> rowid,
    });
typedef $$ReportsTableUpdateCompanionBuilder =
    ReportsCompanion Function({
      Value<String> id,
      Value<String> videoId,
      Value<String> subjectChildId,
      Value<String?> blobHash,
      Value<String> reason,
      Value<String?> note,
      Value<int> level,
      Value<String> recipientType,
      Value<String?> reporterChildId,
      Value<String> reporterParentKey,
      Value<String> status,
      Value<String?> actionTaken,
      Value<bool> isOutbound,
      Value<DateTime> createdAt,
      Value<DateTime?> deliveredAt,
      Value<int> rowid,
    });

class $$ReportsTableFilterComposer
    extends Composer<_$AppDatabase, $ReportsTable> {
  $$ReportsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get videoId => $composableBuilder(
    column: $table.videoId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get subjectChildId => $composableBuilder(
    column: $table.subjectChildId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get blobHash => $composableBuilder(
    column: $table.blobHash,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get reason => $composableBuilder(
    column: $table.reason,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get level => $composableBuilder(
    column: $table.level,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get recipientType => $composableBuilder(
    column: $table.recipientType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get reporterChildId => $composableBuilder(
    column: $table.reporterChildId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get reporterParentKey => $composableBuilder(
    column: $table.reporterParentKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get actionTaken => $composableBuilder(
    column: $table.actionTaken,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isOutbound => $composableBuilder(
    column: $table.isOutbound,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get deliveredAt => $composableBuilder(
    column: $table.deliveredAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ReportsTableOrderingComposer
    extends Composer<_$AppDatabase, $ReportsTable> {
  $$ReportsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get videoId => $composableBuilder(
    column: $table.videoId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get subjectChildId => $composableBuilder(
    column: $table.subjectChildId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get blobHash => $composableBuilder(
    column: $table.blobHash,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get reason => $composableBuilder(
    column: $table.reason,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get level => $composableBuilder(
    column: $table.level,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get recipientType => $composableBuilder(
    column: $table.recipientType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get reporterChildId => $composableBuilder(
    column: $table.reporterChildId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get reporterParentKey => $composableBuilder(
    column: $table.reporterParentKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get actionTaken => $composableBuilder(
    column: $table.actionTaken,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isOutbound => $composableBuilder(
    column: $table.isOutbound,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get deliveredAt => $composableBuilder(
    column: $table.deliveredAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ReportsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ReportsTable> {
  $$ReportsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get videoId =>
      $composableBuilder(column: $table.videoId, builder: (column) => column);

  GeneratedColumn<String> get subjectChildId => $composableBuilder(
    column: $table.subjectChildId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get blobHash =>
      $composableBuilder(column: $table.blobHash, builder: (column) => column);

  GeneratedColumn<String> get reason =>
      $composableBuilder(column: $table.reason, builder: (column) => column);

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<int> get level =>
      $composableBuilder(column: $table.level, builder: (column) => column);

  GeneratedColumn<String> get recipientType => $composableBuilder(
    column: $table.recipientType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get reporterChildId => $composableBuilder(
    column: $table.reporterChildId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get reporterParentKey => $composableBuilder(
    column: $table.reporterParentKey,
    builder: (column) => column,
  );

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get actionTaken => $composableBuilder(
    column: $table.actionTaken,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isOutbound => $composableBuilder(
    column: $table.isOutbound,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get deliveredAt => $composableBuilder(
    column: $table.deliveredAt,
    builder: (column) => column,
  );
}

class $$ReportsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ReportsTable,
          Report,
          $$ReportsTableFilterComposer,
          $$ReportsTableOrderingComposer,
          $$ReportsTableAnnotationComposer,
          $$ReportsTableCreateCompanionBuilder,
          $$ReportsTableUpdateCompanionBuilder,
          (Report, BaseReferences<_$AppDatabase, $ReportsTable, Report>),
          Report,
          PrefetchHooks Function()
        > {
  $$ReportsTableTableManager(_$AppDatabase db, $ReportsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ReportsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ReportsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ReportsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> videoId = const Value.absent(),
                Value<String> subjectChildId = const Value.absent(),
                Value<String?> blobHash = const Value.absent(),
                Value<String> reason = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<int> level = const Value.absent(),
                Value<String> recipientType = const Value.absent(),
                Value<String?> reporterChildId = const Value.absent(),
                Value<String> reporterParentKey = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String?> actionTaken = const Value.absent(),
                Value<bool> isOutbound = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime?> deliveredAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ReportsCompanion(
                id: id,
                videoId: videoId,
                subjectChildId: subjectChildId,
                blobHash: blobHash,
                reason: reason,
                note: note,
                level: level,
                recipientType: recipientType,
                reporterChildId: reporterChildId,
                reporterParentKey: reporterParentKey,
                status: status,
                actionTaken: actionTaken,
                isOutbound: isOutbound,
                createdAt: createdAt,
                deliveredAt: deliveredAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String videoId,
                required String subjectChildId,
                Value<String?> blobHash = const Value.absent(),
                required String reason,
                Value<String?> note = const Value.absent(),
                Value<int> level = const Value.absent(),
                Value<String> recipientType = const Value.absent(),
                Value<String?> reporterChildId = const Value.absent(),
                required String reporterParentKey,
                Value<String> status = const Value.absent(),
                Value<String?> actionTaken = const Value.absent(),
                Value<bool> isOutbound = const Value.absent(),
                required DateTime createdAt,
                Value<DateTime?> deliveredAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ReportsCompanion.insert(
                id: id,
                videoId: videoId,
                subjectChildId: subjectChildId,
                blobHash: blobHash,
                reason: reason,
                note: note,
                level: level,
                recipientType: recipientType,
                reporterChildId: reporterChildId,
                reporterParentKey: reporterParentKey,
                status: status,
                actionTaken: actionTaken,
                isOutbound: isOutbound,
                createdAt: createdAt,
                deliveredAt: deliveredAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ReportsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ReportsTable,
      Report,
      $$ReportsTableFilterComposer,
      $$ReportsTableOrderingComposer,
      $$ReportsTableAnnotationComposer,
      $$ReportsTableCreateCompanionBuilder,
      $$ReportsTableUpdateCompanionBuilder,
      (Report, BaseReferences<_$AppDatabase, $ReportsTable, Report>),
      Report,
      PrefetchHooks Function()
    >;
typedef $$ModerationAuditLogsTableCreateCompanionBuilder =
    ModerationAuditLogsCompanion Function({
      Value<int> id,
      Value<String?> videoId,
      Value<String?> mlsGroupId,
      required String actionType,
      Value<String?> actorParentKey,
      Value<String?> subjectParentKey,
      Value<String?> detailsJson,
      required DateTime createdAt,
    });
typedef $$ModerationAuditLogsTableUpdateCompanionBuilder =
    ModerationAuditLogsCompanion Function({
      Value<int> id,
      Value<String?> videoId,
      Value<String?> mlsGroupId,
      Value<String> actionType,
      Value<String?> actorParentKey,
      Value<String?> subjectParentKey,
      Value<String?> detailsJson,
      Value<DateTime> createdAt,
    });

class $$ModerationAuditLogsTableFilterComposer
    extends Composer<_$AppDatabase, $ModerationAuditLogsTable> {
  $$ModerationAuditLogsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get videoId => $composableBuilder(
    column: $table.videoId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get mlsGroupId => $composableBuilder(
    column: $table.mlsGroupId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get actionType => $composableBuilder(
    column: $table.actionType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get actorParentKey => $composableBuilder(
    column: $table.actorParentKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get subjectParentKey => $composableBuilder(
    column: $table.subjectParentKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get detailsJson => $composableBuilder(
    column: $table.detailsJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ModerationAuditLogsTableOrderingComposer
    extends Composer<_$AppDatabase, $ModerationAuditLogsTable> {
  $$ModerationAuditLogsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get videoId => $composableBuilder(
    column: $table.videoId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get mlsGroupId => $composableBuilder(
    column: $table.mlsGroupId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get actionType => $composableBuilder(
    column: $table.actionType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get actorParentKey => $composableBuilder(
    column: $table.actorParentKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get subjectParentKey => $composableBuilder(
    column: $table.subjectParentKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get detailsJson => $composableBuilder(
    column: $table.detailsJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ModerationAuditLogsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ModerationAuditLogsTable> {
  $$ModerationAuditLogsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get videoId =>
      $composableBuilder(column: $table.videoId, builder: (column) => column);

  GeneratedColumn<String> get mlsGroupId => $composableBuilder(
    column: $table.mlsGroupId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get actionType => $composableBuilder(
    column: $table.actionType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get actorParentKey => $composableBuilder(
    column: $table.actorParentKey,
    builder: (column) => column,
  );

  GeneratedColumn<String> get subjectParentKey => $composableBuilder(
    column: $table.subjectParentKey,
    builder: (column) => column,
  );

  GeneratedColumn<String> get detailsJson => $composableBuilder(
    column: $table.detailsJson,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$ModerationAuditLogsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ModerationAuditLogsTable,
          ModerationAuditLog,
          $$ModerationAuditLogsTableFilterComposer,
          $$ModerationAuditLogsTableOrderingComposer,
          $$ModerationAuditLogsTableAnnotationComposer,
          $$ModerationAuditLogsTableCreateCompanionBuilder,
          $$ModerationAuditLogsTableUpdateCompanionBuilder,
          (
            ModerationAuditLog,
            BaseReferences<
              _$AppDatabase,
              $ModerationAuditLogsTable,
              ModerationAuditLog
            >,
          ),
          ModerationAuditLog,
          PrefetchHooks Function()
        > {
  $$ModerationAuditLogsTableTableManager(
    _$AppDatabase db,
    $ModerationAuditLogsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ModerationAuditLogsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ModerationAuditLogsTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$ModerationAuditLogsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String?> videoId = const Value.absent(),
                Value<String?> mlsGroupId = const Value.absent(),
                Value<String> actionType = const Value.absent(),
                Value<String?> actorParentKey = const Value.absent(),
                Value<String?> subjectParentKey = const Value.absent(),
                Value<String?> detailsJson = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => ModerationAuditLogsCompanion(
                id: id,
                videoId: videoId,
                mlsGroupId: mlsGroupId,
                actionType: actionType,
                actorParentKey: actorParentKey,
                subjectParentKey: subjectParentKey,
                detailsJson: detailsJson,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String?> videoId = const Value.absent(),
                Value<String?> mlsGroupId = const Value.absent(),
                required String actionType,
                Value<String?> actorParentKey = const Value.absent(),
                Value<String?> subjectParentKey = const Value.absent(),
                Value<String?> detailsJson = const Value.absent(),
                required DateTime createdAt,
              }) => ModerationAuditLogsCompanion.insert(
                id: id,
                videoId: videoId,
                mlsGroupId: mlsGroupId,
                actionType: actionType,
                actorParentKey: actorParentKey,
                subjectParentKey: subjectParentKey,
                detailsJson: detailsJson,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ModerationAuditLogsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ModerationAuditLogsTable,
      ModerationAuditLog,
      $$ModerationAuditLogsTableFilterComposer,
      $$ModerationAuditLogsTableOrderingComposer,
      $$ModerationAuditLogsTableAnnotationComposer,
      $$ModerationAuditLogsTableCreateCompanionBuilder,
      $$ModerationAuditLogsTableUpdateCompanionBuilder,
      (
        ModerationAuditLog,
        BaseReferences<
          _$AppDatabase,
          $ModerationAuditLogsTable,
          ModerationAuditLog
        >,
      ),
      ModerationAuditLog,
      PrefetchHooks Function()
    >;
typedef $$AppSettingsTableCreateCompanionBuilder =
    AppSettingsCompanion Function({
      required String key,
      required String value,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$AppSettingsTableUpdateCompanionBuilder =
    AppSettingsCompanion Function({
      Value<String> key,
      Value<String> value,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$AppSettingsTableFilterComposer
    extends Composer<_$AppDatabase, $AppSettingsTable> {
  $$AppSettingsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$AppSettingsTableOrderingComposer
    extends Composer<_$AppDatabase, $AppSettingsTable> {
  $$AppSettingsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AppSettingsTableAnnotationComposer
    extends Composer<_$AppDatabase, $AppSettingsTable> {
  $$AppSettingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$AppSettingsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AppSettingsTable,
          AppSetting,
          $$AppSettingsTableFilterComposer,
          $$AppSettingsTableOrderingComposer,
          $$AppSettingsTableAnnotationComposer,
          $$AppSettingsTableCreateCompanionBuilder,
          $$AppSettingsTableUpdateCompanionBuilder,
          (
            AppSetting,
            BaseReferences<_$AppDatabase, $AppSettingsTable, AppSetting>,
          ),
          AppSetting,
          PrefetchHooks Function()
        > {
  $$AppSettingsTableTableManager(_$AppDatabase db, $AppSettingsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AppSettingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AppSettingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AppSettingsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> key = const Value.absent(),
                Value<String> value = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AppSettingsCompanion(
                key: key,
                value: value,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String key,
                required String value,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => AppSettingsCompanion.insert(
                key: key,
                value: value,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$AppSettingsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AppSettingsTable,
      AppSetting,
      $$AppSettingsTableFilterComposer,
      $$AppSettingsTableOrderingComposer,
      $$AppSettingsTableAnnotationComposer,
      $$AppSettingsTableCreateCompanionBuilder,
      $$AppSettingsTableUpdateCompanionBuilder,
      (
        AppSetting,
        BaseReferences<_$AppDatabase, $AppSettingsTable, AppSetting>,
      ),
      AppSetting,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$ProfilesTableTableManager get profiles =>
      $$ProfilesTableTableManager(_db, _db.profiles);
  $$ProfileGroupsTableTableManager get profileGroups =>
      $$ProfileGroupsTableTableManager(_db, _db.profileGroups);
  $$LocalVideosTableTableManager get localVideos =>
      $$LocalVideosTableTableManager(_db, _db.localVideos);
  $$RemoteAssetsTableTableManager get remoteAssets =>
      $$RemoteAssetsTableTableManager(_db, _db.remoteAssets);
  $$ShareRecordsTableTableManager get shareRecords =>
      $$ShareRecordsTableTableManager(_db, _db.shareRecords);
  $$LikesTableTableManager get likes =>
      $$LikesTableTableManager(_db, _db.likes);
  $$ReactionsTableTableManager get reactions =>
      $$ReactionsTableTableManager(_db, _db.reactions);
  $$RemotePlaybackMetricsTableTableManager get remotePlaybackMetrics =>
      $$RemotePlaybackMetricsTableTableManager(_db, _db.remotePlaybackMetrics);
  $$ReportsTableTableManager get reports =>
      $$ReportsTableTableManager(_db, _db.reports);
  $$ModerationAuditLogsTableTableManager get moderationAuditLogs =>
      $$ModerationAuditLogsTableTableManager(_db, _db.moderationAuditLogs);
  $$AppSettingsTableTableManager get appSettings =>
      $$AppSettingsTableTableManager(_db, _db.appSettings);
}
