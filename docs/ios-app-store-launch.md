# iOS App Store and TestFlight Launch Checklist

Last updated: March 19, 2026

This document is the current launch packet for Tubestr's iOS/TestFlight submission. It covers the public URLs we now host, the App Store Connect answers we should use, and the items that still need a board/legal/product decision before we submit.

## Public URLs

- Marketing site: `https://www.tubestr.app`
- Support URL: `https://www.tubestr.app/support`
- Privacy Policy URL: `https://www.tubestr.app/privacy`
- Terms URL: `https://www.tubestr.app/terms`

## Launch-blocker additions from follow-up review

These are now explicitly tracked as pre-launch blockers for the iOS path:

1. Privacy policy must state the COPPA posture directly, including collection scope, what is not collected, parent rights, and the beta contact path for review/delete/opt-out requests.
2. New-parent onboarding must require an explicit adult attestation tied to the privacy policy before account creation.
3. Parent account creation must age-gate the legal account holder so under-18 users cannot create the parent account.
4. Child-profile deletion needs a verified answer for managed-storage cleanup. Today we can confirm local profile deletion; we cannot yet claim managed Blossom cleanup on child delete.

## What the current app actually does

Based on the current Flutter and iOS code:

- App name / bundle: `Tubestr` / `app.tubestr.mobile`
- Current version in `pubspec.yaml`: `1.0.3+20`
- iOS permission strings in `ios/Runner/Info.plist` currently request:
  - camera access for recording videos and scanning family invite QR codes
  - microphone access for recording audio with videos
- The product supports:
  - parent-managed account setup
  - child profiles
  - family-space invites and approvals
  - recording, editing, private sharing, and playback
  - reporting / blocking flows in the player and parent-zone UI
- The current app does not appear to expose:
  - public social discovery
  - ad SDKs in the mobile client
- New-parent onboarding should now require adult birth-year entry, an explicit 18+ attestation, and privacy-policy acknowledgement before parent-key generation.
- The current app now exposes support, privacy policy, and terms links from the Parent Zone account section.
- The current app now exposes an in-app parent account deletion flow from Parent Zone -> Account, separate from the local device reset path.

## Apple policy anchors

These are the Apple rules this launch packet is built around:

- App Review Guidelines 1.3 and 5.1.4: Kids-category and child-privacy restrictions
  - https://developer.apple.com/app-store/review/guidelines/
- App Review Guidelines 2.3.6 and 2.3.8: honest age rating and metadata rules
  - https://developer.apple.com/app-store/review/guidelines/
- App Review Guidelines 5.1.1: privacy policy and in-app account deletion
  - https://developer.apple.com/app-store/review/guidelines/
- App Review Guidelines 1.2 / 4.7.1 style requirements for user-generated content controls
  - https://developer.apple.com/app-store/review/guidelines/

Inference from those guidelines: Tubestr should launch with a conservative review posture. We should describe it as a parent-managed private family video app, not as an open child social network, and we should avoid any App Store metadata that implies broad child-directed distribution unless we intentionally opt into Kids Category and can sustain those constraints.

## Recommended App Store Connect answers

### App positioning

- Category recommendation:
  - Primary: `Social Networking` or `Photo & Video`
  - Secondary: whichever best fits the final screenshots and purchase model
- Metadata posture:
  - describe Tubestr as a `private family video app with parent approval`
  - avoid the phrases `for kids` and `for children` in App Store metadata unless leadership intentionally chooses the Kids Category

Reason: Apple's metadata rules reserve those phrases for Kids Category apps, and Kids Category materially tightens analytics, external links, and child-directed handling requirements.

### Age rating

Recommended initial answer set:

- User-generated content: `Yes`
- Unrestricted web access: `No`
- Messaging / chat with strangers: `No`
- Public sharing / public audience: `No`
- Parental controls: `Yes`, because the product is parent-managed and connection approval is required

Recommended rating posture:

- Start from the lowest rating produced by the honest questionnaire.
- If the questionnaire forces a higher rating because of user-generated media or reporting flows, accept that rating rather than under-rating the app.

Reason: Apple guideline 2.3.6 explicitly requires honest age-rating answers.

### Kids / family disclosures

Recommended narrative:

- The app is parent-managed.
- A parent creates the account, adds child profiles, and approves family connections.
- New parent setup requires an adult attestation before the legal parent account is created.
- There is no public feed or public discovery surface.
- Sharing is intended for approved family circles only.
- Reporting and blocking controls are available for safety follow-up.

### Privacy nutrition label working draft

This still needs final App Store Connect entry review, but the current engineering read is:

- Data linked to user:
  - contact or account identifiers only if managed subscriptions/support flows are enabled
  - user content such as uploaded videos, thumbnails, profile names, and reports
- Sensitive data:
  - content involving children, videos, photos, and moderation reports
- Diagnostics:
  - operational and delivery metadata if logged by our backend or relay/storage infrastructure
- Tracking:
  - `No` current evidence of ATT-style cross-app tracking in the mobile app

Board/legal review required before submission because the exact nutrition-label answers depend on the final production backend, storage model, and support tooling enabled for iOS launch.

### COPPA posture

Current recommended statement:

- Tubestr is operated by a parent or guardian on behalf of a child.
- The adult account holder is the legal actor for consent.
- The privacy policy tells parents how to review, delete, or stop future collection of child-profile information Tubestr controls.
- We should not claim remote managed-storage deletion for child profiles until the delete path is implemented and verified end to end.

### Review notes draft

Use this in App Review Notes, edited for the exact build:

```text
Tubestr is a parent-managed private family video app. A parent creates the account, sets up child profiles, and approves family connections before any sharing occurs.

The app has no public feed or public discovery. Video sharing is limited to approved family spaces. The current build requests camera access to record clips and scan invite QR codes, and microphone access to record audio with clips.

Safety controls include parent approval flows, family-space controls, and reporting/blocking actions for shared content.
```

If App Review asks for a demo account or family-space setup path, provide:

- one parent-managed demo account
- one secondary approved family contact
- one seeded sample clip
- exact steps to reach camera, parent zone, invite, playback, and report flows

## TestFlight checklist

- Confirm bundle identifier remains `app.tubestr.mobile`.
- Confirm version/build numbers match the release candidate.
- Verify the support URL points to `https://www.tubestr.app/support`.
- Verify the privacy policy URL points to `https://www.tubestr.app/privacy`.
- Verify TestFlight beta notes explain:
  - this is a private beta
  - parent-managed family testing is the target
  - where to send install or safety feedback
- Smoke test on real iPhone and iPad hardware:
  - onboarding
  - parent identity creation/recovery
  - child profile creation
  - invite QR scanning
  - recording with camera + microphone permissions
  - approval flow
  - encrypted upload
  - playback
  - reporting / blocking path

## App Store submission checklist

- Prepare final app name, subtitle, keywords, and screenshots.
- Ensure screenshots use fictional or authorized family data only.
- Avoid metadata phrasing that implies Kids Category unless we intentionally enroll in that category.
- Verify the app itself exposes the privacy policy in an easy-to-find location.
  Current build: exposed from Parent Zone -> Account.
- Confirm the support URL, privacy URL, and terms URL all resolve publicly.
- Confirm the App Privacy answers match the actual production backend and SDK set.
- Confirm whether subscriptions are enabled for iOS launch.
- Confirm the in-app parent account deletion flow works end-to-end against the production account API before submission.
- If subscriptions are enabled, confirm the account-deletion copy clearly states that subscription cancellation is still managed through Apple.
- Prepare review notes, demo credentials, and exact reviewer walkthrough steps.
- Run real-device regression on the launch build before upload.

## Open decisions and blockers

### Board / legal / product decisions

- Decide whether Tubestr is launching in the Kids Category or as a general-audience family app with strong parent controls.
- Approve the final privacy-policy language once the production storage and subscription posture is locked.
- Approve the final support contact path if GitHub-only support is not acceptable for production App Store launch.
- Decide whether iOS launch includes managed subscriptions, BYO storage only, or both.

### Engineering blockers

- Confirm the production build has no third-party analytics or ad SDK behavior that would conflict with a child-focused launch posture.
- Prepare a deterministic demo environment for App Review.
- Verify backend deletion behavior and retention exceptions match the final public privacy-policy language.
- Implement and verify managed Blossom cleanup for child-profile deletion before claiming full child-content deletion in launch materials.

## Recommended launch posture

Unless leadership explicitly chooses otherwise, the lowest-risk path is:

1. Launch first via TestFlight with the new support/privacy/terms URLs.
2. Position Tubestr in App Store metadata as a `private family video app with parent approval`.
3. Avoid Kids Category claims in metadata until legal and product sign off on the stricter category obligations.
4. Keep the reviewer walkthrough explicit about where Parent Zone -> Account -> Delete Parent Account lives and what it removes.
