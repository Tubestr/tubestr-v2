# Safety HQ Backend Plan

## Goal

Build a real backend Safety HQ receiver for Tubestr that can be enrolled as a
member of each family's Safety HQ MLS group, receive level-3 report events from
relays, decrypt them, persist them as moderation cases, and expose a minimal
ops API to review intake.

## Current Client Contract

- Reports are sent as app messages with kind `4547` (`MarmotKinds.report`).
- Report payload type is `mytube/report`.
- Payload fields:
  - `report_id: string`
  - `video_id: string`
  - `subject_child_id: string`
  - `blob_hash: string`
  - `reason: string`
  - `note: string | null`
  - `level: int`
  - `recipient_type: string`
  - `reporter_child_id: string | null`
  - `by: string`
  - `ts: unix seconds`
- Related MLS/Nostr kinds:
  - key package: `443`
  - welcome: `444`
  - gift wrap: `1059`

## Deliverables

### 1. Service Identity

- Generate and securely store a dedicated backend Nostr keypair.
- Persist the service pubkey across restarts and deploys.
- Treat this as a service identity, not a parent account.

### 2. Bootstrap / Enrollment API

Expose an endpoint like `GET /v1/safety-hq/bootstrap`.

Response should include:

- `service_public_key_hex`
- `signed_key_package_event_json`
- `key_package_event_id`
- relay list the backend expects to use
- `version`
- `generated_at`

The signed key package event must be valid for the service pubkey and usable by
the client when creating an MLS group that includes the backend.

### 3. Relay Listener

- Connect to configured relays.
- Subscribe for:
  - gift-wrapped welcome messages addressed to the backend service pubkey
  - group traffic for any MLS groups the service has joined
- Persist checkpoints so restart/reconnect does not lose continuity.

### 4. Welcome Processing / Enrollment

When the client creates a Safety HQ group and publishes a welcome for the
backend service, the backend must:

- receive the welcome
- process it into local MLS state
- accept the pending welcome / join the group
- persist enrolled group membership locally

Track enrolled groups by `mls_group_id_hex` and related metadata.

### 5. Report Intake Worker

For joined groups:

- process incoming application messages
- only treat kind `4547` as report intake
- decrypt MLS messages
- parse `mytube/report`
- validate required fields
- dedupe on `report_id`

Persist a moderation case with:

- `report_id`
- `mls_group_id_hex`
- sender parent pubkey (`by`)
- `video_id`
- `subject_child_id`
- `reporter_child_id`
- `blob_hash`
- `reason`
- `note`
- `level`
- `recipient_type`
- `ts`
- raw wrapper/event ids if available
- `received_at`
- `status` such as `new`, `triaged`, `closed`

### 6. Minimal Ops API

Expose endpoints like:

- `GET /v1/safety-hq/cases`
- `GET /v1/safety-hq/cases/:report_id`
- `POST /v1/safety-hq/cases/:report_id/status`

Support basic filtering by status, date, and group.

### 7. Observability and Safety

- Log enrollment success/failure, relay connection state, decrypt failures,
  parse failures, and duplicate reports.
- Do not log full decrypted report payloads at info level.
- Add metrics/counters for:
  - welcomes received
  - groups joined
  - reports received
  - decrypt failures
  - parse failures
  - duplicate `report_id`s

### 8. Persistence

Use a real database table set for:

- service config
- enrolled groups
- raw intake events if useful
- moderation cases
- case status history / audit log

## Preferred Implementation Approach

- Reuse the same MLS/MDK stack as the client if possible so welcome handling
  and message decryption match client behavior exactly.
- The client will be updated to fetch the backend bootstrap payload, create the
  Safety HQ MLS group with the backend key package included, and publish the
  welcome to the backend over relays.

## Acceptance Criteria

- Backend boots with a stable service pubkey.
- Client can fetch bootstrap info and create a Safety HQ group that includes
  the backend.
- Backend receives and accepts the welcome, then marks the group enrolled.
- When the client files a level-3 report, the backend receives and decrypts the
  kind-4547 message and stores exactly one moderation case.
- Duplicate relay delivery does not create duplicate cases.
- Restarting the backend does not lose enrolled-group state or intake
  continuity.

## Non-Goals For This Pass

- automated moderation decisions
- parent notifications back from backend
- full Trust & Safety dashboard
- migration support for old pre-live device state

