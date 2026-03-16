import 'package:flutter/material.dart';

import '../../../../services/mdk/mdk_service.dart';

enum ParentZoneSection {
  overview('Overview', Icons.dashboard_rounded),
  family('Family', Icons.people_rounded),
  connections('Connections', Icons.link_rounded),
  settings('Settings', Icons.settings_rounded);

  const ParentZoneSection(this.label, this.icon);

  final String label;
  final IconData icon;
}

class ParentZoneMdkDebugState {
  const ParentZoneMdkDebugState({
    required this.version,
    required this.dbPath,
    required this.groupCount,
    required this.groups,
    required this.pendingWelcomes,
  });

  final String version;
  final String dbPath;
  final int groupCount;
  final List<MdkGroupSummary> groups;
  final List<MdkPendingWelcome> pendingWelcomes;
}
