class AppConstants {
  static const appName = 'MyTube';
  static const parentIdentityStorageKey = 'parent_identity_v1';
  static const parentPinStorageKey = 'parent_pin_hash_v1';
  static const parentDisplayNameSettingKey = 'parent_display_name';
  static const parentProfileCachePrefix = 'parent_profile_cache:';
  static const approvalRequiredSettingKey = 'approval_required';
  static const offlineActionQueueSettingKey = 'offline_action_queue';
  static const shareHistorySettingKey = 'share_history';
  static const relayListSettingKey = 'relay_list';
  static const blossomServerListSettingKey = 'blossom_server_list';
  static const safetyJoinQueuedKey = 'safety_join_queued';
  static const safetyJoinedKey = 'safety_joined';
  static const safetyGroupIdSettingKey = 'safety_group_id';
  static const safetyLastSyncAtSettingKey = 'safety_last_sync_at';
  static const safetyHqGroupName = 'Safety HQ';
  static const defaultRelays = <String>[
    'wss://no.str.cr',
    'wss://relay.damus.io',
    'wss://relay.primal.net',
  ];
  static const defaultBlossomServers = <String>['https://blossom.tubestr.app'];
}

class MarmotKinds {
  static const keyPackage = 443;
  static const welcome = 444;
  static const groupCommit = 445;
  static const giftWrap = 1059;
  static const videoShare = 4543;
  static const videoRevoke = 4544;
  static const videoDelete = 4545;
  static const like = 4546;
  static const report = 4547;
  static const tombstone = 30302;
  static const blossomServers = 10063;
  static const relayList = 10002;
}
