import 'package:flutter/material.dart';

import '../../../../services/mdk/mdk_service.dart';

enum ParentZoneSection {
  dashboard(Icons.dashboard_rounded),
  children(Icons.people_rounded),
  familySpaces(Icons.link_rounded),
  activity(Icons.history_rounded),
  account(Icons.person_rounded),
  network(Icons.cell_tower_rounded),
  diagnostics(Icons.radar_rounded);

  const ParentZoneSection(this.icon);

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
