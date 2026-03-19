import 'package:flutter/material.dart';

import '../../../../services/mdk/mdk_service.dart';

enum ParentZoneSection {
  dashboard('Dashboard', Icons.dashboard_rounded),
  children('Children', Icons.people_rounded),
  familySpaces('Family Spaces', Icons.link_rounded),
  activity('Activity', Icons.history_rounded),
  account('Account', Icons.person_rounded),
  network('Network', Icons.cell_tower_rounded),
  diagnostics('Diagnostics', Icons.radar_rounded);

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
