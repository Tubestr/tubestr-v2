class AppConstants {
  static const appName = 'Tubestr';
  static const supportUrl = 'https://www.tubestr.app/support';
  static const privacyUrl = 'https://www.tubestr.app/privacy';
  static const termsUrl = 'https://www.tubestr.app/terms';
  static const parentIdentityStorageKey = 'parent_identity_v1';
  static const parentPinStorageKey = 'parent_pin_hash_v1';
  static const parentDisplayNameSettingKey = 'parent_display_name';
  static const parentProfileCachePrefix = 'parent_profile_cache:';
  static const approvalRequiredSettingKey = 'approval_required';
  static const offlineActionQueueSettingKey = 'offline_action_queue';
  static const shareHistorySettingKey = 'share_history';
  static const managedVideoUploadsSettingKey = 'managed_video_uploads';
  static const relayListSettingKey = 'relay_list';
  static const blossomServerListSettingKey = 'blossom_server_list';
  static const safetyJoinQueuedKey = 'safety_join_queued';
  static const safetyJoinedKey = 'safety_joined';
  static const safetyGroupIdSettingKey = 'safety_group_id';
  static const safetyServicePubkeySettingKey = 'safety_service_pubkey';
  static const safetyRelayListSettingKey = 'safety_relay_list';
  static const safetyLastSyncAtSettingKey = 'safety_last_sync_at';
  static const safetyHqGroupName = 'Safety HQ';
  static const defaultRelays = <String>[
    'wss://no.str.cr',
    'wss://relay.primal.net',
    'wss://nos.lol',
  ];
  static const defaultBlossomServers = <String>['https://blossom.tubestr.app'];
}

class MarmotKinds {
  static const chatMessage = 9;
  static const keyPackage = 30443;
  static const legacyKeyPackage = 443;
  static const keyPackageKinds = <int>[keyPackage, legacyKeyPackage];
  static const welcome = 444;
  static const groupCommit = 445;
  static const giftWrap = 1059;
  static const videoShare = 4543;
  static const videoRevoke = 4544;
  static const videoDelete = 4545;
  static const like = 4546;
  static const report = 4547;
  static const reaction = 4548;
  static const tombstone = 30302;
  static const blossomServers = 10063;
  static const relayList = 10002;
  static const keyPackageRelays = 10051;
}
