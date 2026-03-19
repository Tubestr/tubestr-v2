# Safety HQ Frontend Plan

## Goal

Replace the current app-managed placeholder Safety HQ provisioning flow with a
real backend-backed enrollment flow, while keeping the new tiered report
routing already shipped on the client:

- level 1: local-only
- level 2: local parent-only
- level 3: publish to family group and Safety HQ when provisioned

## What Already Works

- Level 1-2 reports complete locally without relay publish.
- Level 3 reports publish to the family group.
- Level 3 reports publish to the configured Safety HQ group when provisioned.
- Parent UI now reflects local versus shared destinations.

## What Must Change In The Client

### 1. Replace Local Safety HQ Provisioning

Current behavior:

- the app creates or reuses a local group named `Safety HQ`
- the app stores that group id as if Safety HQ were fully provisioned

Required behavior:

- provisioning must mean the backend service is actually enrolled as an MLS
  member and can receive reports
- stop treating "local group exists" as success

Primary file:

- `lib/services/safety/safety_hq_service.dart`

### 2. Fetch Backend Bootstrap Data

Add a client call that fetches backend bootstrap info, expected to include:

- backend service public key
- signed key package event JSON
- key package event id
- relay list or backend relay expectations

This will become the input for Safety HQ group creation.

Likely work:

- add API client surface
- add models for bootstrap payload
- handle failures and retries cleanly

### 3. Create Safety HQ Group With Backend Included

Use MLS creation with the backend key package included from day one.

Preferred path:

- call MDK `createGroupWithWelcomes(...)`
- include the backend key package event JSON in
  `memberKeyPackageEventJsons`
- publish the resulting welcome rumor(s) to the backend service pubkey

Relevant file:

- `lib/services/mdk/mdk_service.dart`

### 4. Redefine Safety HQ Status

Current client status is too optimistic. It mostly means:

- queued
- joined
- not configured

Update the state model so "joined" means:

- backend service is enrolled in the group's MLS state
- client has completed the real provisioning flow

Possible status set:

- `not_configured`
- `provisioning`
- `provisioned`
- `failed`
- `needs_retry`

Primary surfaces:

- `lib/services/safety/safety_hq_service.dart`
- `lib/core/di/providers/app_state_providers.dart`
- Parent Zone status UI

### 5. Remove Startup Auto-Creation

Current startup behavior auto-calls Safety HQ provisioning.

That should stop creating placeholder local groups on app launch.

Instead, startup should:

- refresh current Safety HQ status
- optionally retry pending real enrollment
- flush queued Safety HQ reports only if provisioned

Primary file:

- `lib/features/app_shell/presentation/app_shell.dart`

### 6. Update Parent Zone Provisioning UX

Provisioning UI should explain the real behavior:

- Safety HQ connects this family to the platform moderation service
- reports at level 3 can be sent there once enrollment completes

The button/status area should handle:

- initial provision
- loading state
- success
- failure / retry

Primary files:

- `lib/features/parent_zone/presentation/parent_zone_page.dart`
- `lib/features/parent_zone/presentation/widgets/parent_zone_network_section.dart`
- `lib/features/parent_zone/presentation/widgets/parent_zone_dashboard_section.dart`

### 7. Keep Report Routing Compatible With New Enrollment

The current routing logic should stay:

- level 1-2 local-only
- level 3 publish to family
- level 3 additionally publish to Safety HQ when provisioned
- if Safety HQ is not yet provisioned, queue the Safety HQ copy

Primary file:

- `lib/services/safety/report_coordinator.dart`

This logic is already updated and should be preserved while replacing the
provisioning path.

## Suggested Implementation Sequence

1. Add backend bootstrap client/API models.
2. Rework `SafetyHqService` to fetch bootstrap info and create a real group
   with backend membership.
3. Publish backend welcome rumors and persist real provisioned state.
4. Update Parent Zone UI/status strings and retry handling.
5. Remove startup placeholder auto-create behavior.
6. Add tests for real enrollment orchestration and queued Safety HQ flush after
   successful provisioning.

## Acceptance Criteria

- A fresh device can provision Safety HQ against the backend bootstrap API.
- Provisioning results in a group that includes the backend service.
- The client only marks Safety HQ as provisioned once enrollment succeeds.
- Level-3 reports publish to the family group and backend-backed Safety HQ
  group.
- Queued Safety HQ reports flush after real provisioning succeeds.
- Parent Zone status accurately reflects the true backend-backed state.

## Non-Goals For This Pass

- migration support for old local-only Safety HQ groups
- backend moderation UI
- acknowledge/escalate parent report actions

