# Nook (MyTube) — UI Reference for Flutter Rewrite

Complete inventory of every screen, flow, component, and navigation path in the iOS SwiftUI app.

---

## Table of Contents

1. [App Shell & Navigation](#app-shell--navigation)
2. [Onboarding Flow](#onboarding-flow)
3. [Home Feed](#home-feed)
4. [Player](#player)
5. [Capture](#capture)
6. [Editor Hub](#editor-hub)
7. [Editor Detail](#editor-detail)
8. [Selfie Sticker Capture](#selfie-sticker-capture)
9. [Parent Zone](#parent-zone)
10. [Shared UI Components](#shared-ui-components)
11. [Theming System](#theming-system)
12. [Navigation Map](#navigation-map)
13. [State Management Patterns](#state-management-patterns)

---

## App Shell & Navigation

**Source:** `MyTube/MyTubeApp.swift`, `MyTube/Features/AppShell/AppRootView.swift`

### Entry Point

- Creates `AppEnvironment.live()`, injected as `@EnvironmentObject` throughout the tree.
- Handles deep link URL schemes: `nook://`, `tubestr://`, `mytube://` — stores URL in `environment.pendingDeepLink`, triggers navigation to Parent Zone tab.

### Root View (`AppRootView`)

- **When `onboardingState == .needsParentIdentity`:** Full-screen `OnboardingFlowView`.
- **When `onboardingState == .ready`:** Main tab shell.

### Main Tab Shell

- `TabView` with 4 tabs. Native tab bar hidden (`.toolbar(.hidden, for: .tabBar)`).
- Custom `CustomTabBar` overlaid via `ZStack` (bottom-anchored).
- Global tint set to `palette.accent`.
- Background: `NookAppBackground()`.

### Custom Tab Bar

- `HStack` of 4 tab buttons separated by vertical `Divider`s.
- Background: `.ultraThickMaterial` with top border stroke.
- Each button: icon (`Image(systemName:)`) + label (`Text`) stacked vertically.
- Active tab: accent color fill. Inactive: secondary label color.

| Tab | Icon | Label |
|-----|------|-------|
| Home | `house.fill` | "Home" |
| Capture | `video.badge.plus` | "Capture" |
| Editor | `wand.and.stars` | "Editor" |
| Parent Zone | `lock.shield` | "Parent Zone" |

**Auto-behavior:** If PIN not configured → auto-select Parent Zone tab on appear. On `pendingDeepLink` change → navigate to Parent Zone tab.

---

## Onboarding Flow

**Source:** `MyTube/Features/Onboarding/OnboardingFlowView.swift` (~1495 lines)

State machine driven by a `Step` enum. Each step renders a distinct full-screen view.

### Step 1: Introduction (Paged Slides)

Full-screen `TabView` with `.page` tab style (no default indicators).

**4 slides**, each an `IntroSlideView`:
- Full-screen `LinearGradient` background.
- Large SF symbol icon in circle (76pt).
- Title (34pt bold white).
- Subtitle (18pt white, 0.9 opacity).

| Slide | Icon | Title | Subtitle |
|-------|------|-------|----------|
| 1 | `sparkles` | "Curated For Kids" | — |
| 2 | `video.badge.plus` | "Create Magical Moments" | — |
| 3 | `lock.shield.fill` | "Stay In Control" | — |
| 4 | `person.2.fill` | "Private By Design" | — |

**Bottom HUD:**
- Capsule page-indicator dots (active dot stretches to 24pt wide, spring animation).
- "Next" / "Start Setup" capsule button (white fill, accent text).
- Top-left: "Skip" capsule button (white 0.2 opacity background, white text).

### Step 2: Role Selection

- "Welcome to Nook" title (34pt bold), subtitle (17pt secondary).
- Two full-width buttons:
  - **"I'm a new parent"** — `.borderedProminent`, `sparkles` icon.
  - **"Restore my account"** — `.bordered`, `arrow.clockwise` icon.

### Step 3a: Parent Key — New Account

- **`IdentityCard`:** Shows truncated public key + "Copy" button.
- **`SecureValueCard`:** Private key field with reveal/hide eye toggle, copy button, red warning text about saving.
- **"Publish Parent Profile"** button → presents `ParentProfileOnboardingSheet`.
- **"Continue to Child Profiles"** button (disabled until profile published).
- While generating key: `ProgressView` + "Preparing your secure parent key…".

### Step 3b: Parent Key — Restore Account

- `TextField` for nsec1.../hex input.
- "Scan QR Code" button → `QRScannerSheet`.
- "Restore" primary button.

### Step 4: Recovery (restore path only)

- Circle containing `ProgressView` (in progress), `checkmark.seal.fill` (success), or `exclamationmark.triangle` (error).
- Status text below.
- On success: green badge showing recovered child count.
- "Continue" button.

### Step 5: Child Profile Setup

- "Child Profiles" section header.
- **"Add Child Profile"** primary button → `ChildProfileSheet` (medium detent).
- List of `ChildIdentityCard` per child:
  - Name + theme color dot.
  - Theme display name.
  - Truncated group ID.
- **"Finish Setup"** button (disabled until ≥1 child added).

### Step 6: Ready / Complete

- `checkmark.seal.fill` icon (72pt, green).
- "All Set!" title.
- Description text.
- Auto-dismisses or shows Continue button.

### Onboarding Sheets

| Sheet | Presentation | Contents |
|-------|-------------|----------|
| `QRScannerSheet` | Full screen | Black background, `QRCodeScannerView` fills screen, X dismiss (top-left circle), centered title capsule |
| `ParentProfileOnboardingSheet` | NavigationStack sheet | Form: "Display Name" TextField, Cancel/Continue toolbar, ProgressView overlay when submitting |
| `ChildProfileSheet` | Medium detent | Form: "Name" TextField + "Theme" Picker (segmented), Cancel/Save toolbar |

---

## Home Feed

**Source:** `MyTube/Features/HomeFeed/HomeFeedView.swift`

### Structure

- `NavigationStack` → `ScrollView` (`.refreshable`).
- Toolbar: `StandardToolbar(showLogo: true)` — "Nook" title (leading) + `ProfileSwitcherButton` (trailing).
- Background: `NookAppBackground(showDecorations: true, decorationIntensity: .gentle)`.

### Layout (top to bottom)

#### 1. Welcome Header
- Time-of-day greeting (e.g. "Good Morning, [name]").
- Profile avatar circle with glow effect (`.nookGlow(.soft)`).

#### 2. My Videos Section (when videos exist)
- Section header: "My Videos" + count badge capsule.
- `LazyVGrid` — 3 columns, 16pt spacing.
- Each **`VideoTile`:**
  - 140pt height thumbnail (`AsyncImage`, rounded 20pt corners).
  - Heart badge (top-right) if liked.
  - "Pending" badge (top-left) if not published.
  - Title text (caption, 2-line limit, bottom).

#### 3. Empty State (when no videos)
- Concentric circles + `video.badge.plus` icon (48pt).
- "Your Nook awaits!" title.
- `.cozyCard` styled container.

#### 4. From Friends & Family Section
- `ForEach` of `SharedRemoteSection` (grouped by sender).
- Each section: sender name header + horizontal `ScrollView`.
- Each **`SharedVideoTile`:**
  - 160×120pt thumbnail.
  - Status icon badge overlay (checkmark/clock/exclamation).
  - "From [name]" subtitle caption.

#### 5. Add Friends CTA Card
- `person.badge.plus` icon.
- "Connect with Friends" label.
- Tapping shows `Alert`: "Go to Parent Zone → Connections".

### Modals

- `.fullScreenCover` → `PlayerView` (local video, when tile tapped).
- `.fullScreenCover` → `PlayerView` (remote video, when shared tile tapped).
- `Alert` for trusted creators info.

---

## Player

**Source:** `MyTube/Features/Player/PlayerView.swift`

### Presentation
- `.fullScreenCover`, `.statusBar(hidden: true)`.
- Background: dark `Color(red:0.08, green:0.06, blue:0.10)` + radial gradient glow (accent color, 600pt radius) + `FloatingDecorations(.subtle)`.

### Top Bar (auto-hides after 4s, opacity animated)

| Position | Element | Notes |
|----------|---------|-------|
| Leading | X close button | 44pt circle, `.ultraThinMaterial` |
| Trailing | Edit/Remix button | Capsule, `.ultraThinMaterial`, `wand.and.stars` + "Edit" — own videos only |
| Trailing | Publish button | Accent gradient capsule, `arrow.up.circle` + "Publish" — when `shouldShowPublishAction` |
| Trailing | Report button | 44pt circle, `flag` icon |

### Video Area (center)
- `VideoPlayer(player:)` with accent gradient border stroke + drop shadow.
- Loading: centered `ProgressView`.
- Error: `exclamationmark.triangle` icon + message text.
- Paused overlay: 80pt circle with accent gradient + `play.fill` icon (tap to resume).

### Bottom Panel

`.ultraThinMaterial` rounded rect, horizontal padding 16pt.

- **Title** (headline, 2-line) + **subtitle** (caption, secondary).
- **Like button:** `heart.circle.fill` (56pt), pink when liked, like count below.
- **Progress scrubber:** `Slider` with gradient track (accent → accentSecondary), white thumb.
- **Time labels:** current / total (caption mono).
- **Playback controls** (`HStack`):
  - Rewind-to-start (`backward.end.fill`).
  - Play/pause (72pt circle, `play.fill` / `pause.fill`).
  - Skip-forward (placeholder).

**Tap-anywhere gesture:** Toggles controls visibility; 4s auto-hide timer resets on each tap.

### Sheets from Player

| Sheet | Presentation | Contents |
|-------|-------------|----------|
| `FeelingReportSheet` | `.sheet`, large detent | Child-facing 3-step report flow (see Shared UI) |
| `PINPromptView` | `.sheet`, medium detent | PIN entry for publish action |
| `EditorDetailView` | `.fullScreenCover` | Video editor (when Edit/Remix tapped) |

---

## Capture

**Source:** `MyTube/Features/Capture/CaptureView.swift`

### Presentation
- Tab content, full screen (`ignoresSafeArea`).
- Full-screen black background with camera preview filling entire screen.

### Layout Layers (bottom to top)

#### 1. Camera Preview
- `CameraPreview` (`UIViewRepresentable` wrapping `AVCaptureVideoPreviewLayer`).
- Pinch gesture → zoom (`videoZoomFactor`).
- Tap gesture → focus point.

#### 2. Header Overlay (top, floating)
- Leading: **`ZoomBadge`** — "1.0x" capsule (`.ultraThinMaterial`, monospaced caption).
- Trailing `HStack`:
  - Torch toggle (`bolt.fill` / `bolt.slash.fill`, 44pt circle).
  - Camera flip (`camera.rotate.fill`, 44pt circle).
  - Both: `.ultraThinMaterial` circle backgrounds.

#### 3. Record Controls (bottom, floating)
- When recording: **`RecordingIndicator`** — `.ultraThinMaterial` capsule with red dot pulse + elapsed time (`MM:SS`).
- **`RecordButton`** (80pt):
  - Outer ring: white stroke, 6pt.
  - Inner shape: morphs circle → rounded-rect on recording state, red fill, spring animation.

#### 4. Overlays
- **`SavedBanner`:** Slides from top, white capsule "Video Saved!", auto-dismisses at 2.5s.
- **`ErrorBanner`:** Red rounded rect, error message, tap to dismiss.
- **`PublishProgressOverlay`:** Full-screen when scanning/processing.
- **`PreparingOverlay`:** Spinner + "Preparing camera…" while session starts.

### Lifecycle
- `onAppear` starts `AVCaptureSession`.
- `onDisappear` stops it.

---

## Editor Hub

**Source:** `MyTube/Features/Editor/EditorHubView.swift`

### Structure
- `NavigationStack` → `ScrollView`.
- Toolbar: `StandardToolbar(showLogo: false)` — `ProfileSwitcherButton` (trailing) + refresh button (trailing).
- Background: `NookAppBackground(.subtle)`.

### Layout

#### Header Card
- `wand.and.stars` icon in accent circle (56pt).
- "Edit Studio" title (28pt, accent color, rounded heavy).
- Subtitle text.

#### Empty State (no videos)
- Concentric circles + `video.badge.waveform` icon.
- "No videos to edit yet" message.
- `.cozyCard` container.

#### Video Grid (when videos exist)
- `LazyVGrid` — 2 columns, 20pt spacing.
- Each **`EditorVideoCard`:**
  - 160pt thumbnail with `wand.and.stars` circle hint (bottom-right, 28pt, accent 0.8 opacity).
  - Title (subheadline, 2-line).
  - Duration + date `HStack` (caption, secondary).
  - `.cozyCard` styled.

### Navigation
- Tap card → `.fullScreenCover` → `EditorDetailView`.

---

## Editor Detail

**Source:** `MyTube/Features/Editor/EditorDetailView.swift` (~1245 lines)

### Presentation
- `.fullScreenCover`, `.statusBar(hidden: true)`.
- Background: theme `backgroundGradient` + `OrganicBlobBackground` + `FloatingDecorations(.subtle, opacity: 0.4)`.

### Top Header Bar
- Leading: X close button (circle).
- Center: `VStack` — "Editing" caption + video title (headline).
- Trailing: Save button (accent gradient capsule) or `ProgressView`.

### Main Layout: `HStack`
- **Left:** Video preview area (fills remaining width).
- **Right:** Tool sidebar (fixed width ~80pt).

### Tool Sidebar (`playfulToolSidebar`)

Vertical `VStack` of `PlayfulToolButton` (56pt circles):
- Active tool: accent gradient fill + accentSecondary stroke ring.
- Inactive: cardFill background.

| Icon | Label |
|------|-------|
| `scissors` | "Trim" |
| `wand.and.stars` | "Effects" |
| `face.smiling.inverse` | "Overlays" |
| `music.note.list` | "Audio" |
| `textformat.abc` | "Text" |

Below tools: trash delete button (56pt, error color).

**Behavior:** Tap active tool → collapse panel. Tap new tool → switch + expand panel.

### Bottom Tool Panel

Slides up from bottom, fixed 340pt height, draggable down to dismiss. Top: drag handle capsule (40×5pt, tertiary fill).

#### Trim Tool
- Header row + thumbnail filmstrip (HStack of video frame thumbnails, playhead line overlay).
- Playhead position slider.
- Start trim slider + end trim slider (side by side).

#### Effects Tool
- Horizontal `ScrollView` of filter chips: `None` + named filters (Vivid, Matte, Fade, Warm, Cool, Noir).
- Vertical `ScrollView` of effect sliders:
  - Each row: icon + label (leading) + `Slider` (0–1) + "Reset" button (trailing).
  - Parameters: Brightness, Contrast, Saturation, Sharpness, Vignette.

#### Overlays Tool
- Header: "Fun Stickers" + "Remove" button (if sticker active).
- "Drag stickers on your video!" subtitle.
- `LazyVGrid` (4 columns) of sticker chips:
  - First cell: `SelfieStickerCaptureButton` (camera icon, accent tint).
  - User stickers (image thumbnails, long-press to delete).
  - Built-in stickers (asset name thumbnails).
- Tapping sticker → places on video.

#### Audio Tool
- Volume `Slider` (when track is selected).
- `List` of `MusicTrackRow`:
  - Leading: preview play/stop circle button (30pt, accent).
  - Title text (subheadline).
  - Trailing: checkmark if selected track.
- "Remove" button in header (when track selected).

#### Text Tool
- `TextField` ("Type something…").
- Font style horizontal scroll: circle buttons showing "Aa" in different fonts.
- Color picker horizontal scroll: 36pt solid color circles (tap to select, white ring on selected).
- Position `Picker` segmented: Top / Center / Bottom.
- Size `Slider` range 24–96.

### Sticker Overlay on Video (`StickerOverlayView`)
- Draggable (normalized position, `DragGesture`).
- Pinch-scalable (0.5–2.0, `MagnificationGesture`).
- Rotatable (`RotationGesture`).
- White border stroke + 4 corner circle handles (selection affordance).

### Overlays
- Error toast: capsule with `exclamationmark.triangle` + message (auto-dismiss).
- `PublishProgressOverlay`: full-screen during export.
- `ConfettiView`: on export complete.
- Confirmation `confirmationDialog` for delete video action.

### Sheets
- `.fullScreenCover` → `SelfieStickerCaptureView`.

---

## Selfie Sticker Capture

**Source:** `MyTube/Features/Editor/SelfieStickerCaptureView.swift`

### Presentation
- `.fullScreenCover`, black background.

### State Machine

#### `.camera`
- Front-facing selfie camera preview (`CameraPreview`).
- Top: X dismiss button (leading), camera flip button (trailing).
- Instruction text: "Take a photo to create a sticker".
- Bottom: large white capture button with accent ring (80pt circle).

#### `.subjectLifting(UIImage)`
- Analyzing state: `ProgressView` + "Lifting subject…".
- Done state: extracted subject PNG on checkerboard background.
- "Use Sticker" accent button (bottom).
- Uses `VisionKit.ImageAnalyzer` + `ImageAnalysisInteraction` for subject isolation.

#### `.saving`
- Centered `ProgressView`.

#### `.error`
- `exclamationmark.triangle` (60pt, warning color).
- Error message text.
- "Try Again" button.

---

## Parent Zone

**Source:** `MyTube/Features/ParentZone/ParentZoneView.swift` (~2446 lines)

### Presentation
- Tab content with `NavigationStack`.
- `ZStack`: main content area + slide-in sidebar + dim overlay.

### Lock Screen (when `!isUnlocked`)

#### PIN Not Configured (`needsSetup`)
- `PinCard` container (`.cozyCard`).
- "Create Parent PIN" title.
- Two `PinSecureField` inputs: "New PIN (4 digits)" + "Confirm PIN".
- "Save PIN" primary button.
- "Face ID will also be enabled" footnote.

#### PIN Entry
- `PinCard` "Unlock Parent Tools" title.
- `PinDots` (4 dots, fills as digits entered).
- `PinKeypad` (3×4 grid: 1–9, ⌫, 0, OK).
- "Unlock with Face ID" button (below keypad).
- Error text (red, caption) on wrong PIN.

### Unlocked — Sidebar Navigation

- Slides in from leading edge, 280pt wide.
- Trigger: hamburger/menu button in toolbar.
- Animation: `.spring(response: 0.35)` translate; dimming overlay (black 0.4 opacity).

**Sidebar layout:**
- **Header:** gradient background (accent → accentSecondary), shield icon + "Parent Zone" title, parent public key (truncated, monospaced caption).
- **Navigation list:** Each `ParentZoneSection` — icon + label in `HStack`. Active: accent-filled rounded rect background. `.connections` case: badge with pending welcomes count.
- **Footer:** app version string (caption, secondary).

### Section: Overview

`insetGroupedList` style.

**Family Summary:**
- Parent key status (checkmark or exclamationmark).
- Child profiles count.
- Total videos count.
- Active connections count.
- MLS groups count.
- Remote shares count.
- Pending welcomes count.

**Quick Actions:**
- "Generate Key" (only if no parent key).
- "Add Child Profile" → `ChildProfileFormSheet`.
- "Import Child Profile" → `ChildImportFormSheet`.
- "New Connection Invite" → follow request sheet.

**Storage Snapshot:**
- `StorageMeterView`: linear progress bar + breakdown legend.
- Cloud mode label.
- Entitlement summary text.
- "Refresh" button.

### Section: Family

Segmented `Picker`: "Children" / "Parent".

**Children tab:**
- "Add Child" + "Import Child" action buttons.
- List of child sections (expandable disclosure per `ProfileEntity`):
  - Child name + theme dot.
  - Expanded: group summary card (members, status), connection invite (share/copy), device invite (share/copy), `KeyExportCard` (reveal/hide/copy/share private key), "Set Active" button.

**Parent tab:**
- Parent public key display row + share + copy buttons.
- `KeyExportCard` for parent private key.
- "Display Name" `TextField` + "Publish Profile" button.

### Section: Connections

- "New Connection Invite" primary button (full width).
- **Active Connections** list:
  - Refresh button in header.
  - Grouped by child profile.
  - Each group: `groupSummaryCard` (member count, group ID truncated, last activity).
- **Pending Welcomes** list:
  - Each row: sender info + "Accept" (accent) + "Decline" (destructive) buttons.

### Section: Library

- `List` of `VideoEntity` rows:
  - Thumbnail (40×40pt, rounded).
  - Title + date.
  - Trailing menu: Hide/Unhide, Export (→ `ShareSheet`), Send Secure Share, Delete (destructive).
- "Refresh Videos" button at bottom.

### Section: Storage

- `StorageMeterView`: full-width progress bar.
- Cloud mode + entitlement status rows.
- "Start Trial" / "Refresh" button.
- **Managed Backend:** URL `TextField` + "Apply" button.
- **BYO Storage** (`DisclosureGroup`):
  - Endpoint, Bucket, Region, Access Key `TextField`s.
  - Secret Key `SecureField`.
  - Path-style toggle.
  - "Apply" button.

### Section: Safety

Renders `ConversationCardsView` (see Shared UI below).

### Section: Settings

- **Relay list:** `List` of relays with enable/disable `Toggle` + remove. "Add Relay" `TextField` + "Add" button. "Reconnect All" button.
- **Content Controls:** "Require Approval" toggle, "Content Scanning" toggle, "Pending Approval" `NavigationLink` → list with Approve & Publish buttons.
- **Connection Diagnostics:** Group count, pending welcomes count, "Refresh" button.
- **Maintenance:** "Reset App" destructive button → confirmation `Alert`.
- Version info row.

### Parent Zone Sheets

| Sheet | Presentation | Contents |
|-------|-------------|----------|
| `ChildProfileFormSheet` | Medium detent | Form: Name TextField + Theme Picker (segmented) + Cancel/Save toolbar |
| `ChildImportFormSheet` | Medium detent | Form: Name TextField + Theme Picker + private key TextField + Cancel/Import toolbar |
| Follow request sheet | Sheet | Child picker + invite paste field + Paste button + approved families picker + key package fetch status + Connect button |
| Secure share prompt | Sheet | Recipient field + approved parents picker + video info card + Send/Cancel |
| `ShareSheet` | System | `UIActivityViewController` |
| Reset confirmation | Alert | Destructive confirmation |

---

## Shared UI Components

### StandardToolbar
**Source:** `MyTube/SharedUI/Components/StandardToolbar.swift`

View modifier: `.standardToolbar(showLogo:)`.
- Leading: "Nook" in `.title2.rounded.heavy`, accent color — only when `showLogo: true`.
- Trailing: `ProfileSwitcherButton` always.

### ProfileSwitcherButton
**Source:** `MyTube/Features/AppShell/ProfileSwitcherButton.swift`

Capsule pill button: profile name + `person.circle` icon. Expands as `Menu`:
- Section 1 "Switch Profile": child profiles list, active has `checkmark`.
- Section 2 "Theme": `Picker` with `ThemeDescriptor.allCases`.

### NookAppBackground / FloatingDecorations / OrganicBlobBackground
**Source:** `MyTube/SharedUI/Components/NookDecorations.swift`

- **`NookAppBackground`:** theme `backgroundGradient` + `OrganicBlobBackground` + `FloatingDecorations`.
- **`OrganicBlobBackground`:** 3 ellipses with radial gradient fills, slow breathing `scaleEffect` animation (12s easeInOut, repeat, autoreverses).
- **`FloatingDecorations`:** N decorations with deterministic positions, slow drift (8–15s easeInOut), rotation, scale pulse. Theme-specific SF symbols:
  - Campfire: `circle`, `sparkles`
  - Treehouse: `leaf.fill`, `circle`, `leaf`
  - Blanket Fort: `heart`, `star`, rounded rect
  - Starlight: `star`, `moon.stars.fill`, `sparkles`, `circle`
- **`GlowEffect`:** `.nookGlow(.soft/.medium/.warm)` — double shadow with accent color at 0.3 + 0.15 opacity.
- **`CozyCardStyle`:** `.cozyCard(cornerRadius:elevation:)` — cardFill + `.ultraThinMaterial` + cardStroke border + drop shadow.
- **`BouncyButtonStyle`:** 0.92 spring scale on press + `UIImpactFeedbackGenerator(.light)` haptic. Variants: `.primary`, `.secondary`, `.icon`.
- **`PlayfulIconButton`:** 64pt circle icon button, label text below.

### PublishProgressOverlay
**Source:** `MyTube/SharedUI/Components/PublishProgressOverlay.swift`

Full-screen black 0.6 opacity overlay. Center `.ultraThinMaterial` card:
- 4 step dots (filled/checkmark when reached, gray when pending).
- Current step icon (SF symbol, 32pt, accent).
- Current step label text.
- Spinning `ProgressView` or green `checkmark.circle.fill` on complete.
- `ConfettiView` on complete.

**Steps:** preparing (`gearshape`) → processing (`wand.and.stars`) → scanning (`viewfinder`) → saving (`square.and.arrow.down`) → complete.

### ConfettiView
**Source:** `MyTube/SharedUI/Components/ConfettiView.swift`

`Canvas`-based. 60 particles, theme-colored (accent, accentSecondary, success, warning), 3 shapes (square, circle, rounded rect). Physics: gravity + horizontal wobble. `Timer` at 16ms tick. Auto-stops when all particles off screen.

### PINPromptView
**Source:** `MyTube/SharedUI/Components/PINPromptView.swift`

`.sheet` with `.medium` detent, `NavigationStack`.
- Title.
- `PinDots`.
- `PinKeypad`.
- Error label (red caption).
- "Confirm PIN" button.

### PinDots
**Source:** `MyTube/SharedUI/Components/PinDots.swift`

`HStack` of 4 circles (18pt diameter, 8pt spacing). Unfilled = stroke only; filled = `.primary` fill. Animates with `.spring`.

### PinKeypad
**Source:** `MyTube/SharedUI/Components/PinKeypad.swift`

`LazyVGrid` 3 columns, 12 cells: 1–9, ⌫, 0, OK.
- Each cell: full-width, 54pt min height, `RoundedRectangle(cornerRadius: 18)`.
- Digit cells: `.secondarySystemBackground`.
- OK cell: accent tinted.
- ⌫ cell: `delete.left` SF symbol.

### QRCodeCard
**Source:** `MyTube/SharedUI/Components/QRCodeCard.swift`

Card containing: title, `LabelRow` or `SecureRow` (with reveal/hide toggle + copy), optional QR code `Image` (140×140pt, `CIQRCodeGenerator`), optional "Share" button.

### QRCodeScannerView
**Source:** `MyTube/SharedUI/Components/QRCodeScannerView.swift`

`UIViewControllerRepresentable` wrapping `AVCaptureMetadataOutput` for `.qr` codes. Black background, centered status label on permission denied.

### FeelingReportSheet (Child-Facing)
**Source:** `MyTube/SharedUI/Reporting/FeelingReportSheet.swift`

`.sheet` with `.large` detent. Dark gradient background. **3-step flow:**

**Step 1 — Feeling Selection:**
- 🎬 emoji (48pt).
- "How does this video make you feel?"
- `LazyVGrid` 2 columns of `FeelingButton`:

| Emoji | Label |
|-------|-------|
| 😕 | Feels Weird |
| 😢 | Makes Me Sad |
| 🤔 | Confusing |
| 😨 | Scary |
| 😠 | Really Bad |

- Each: emoji (36pt) + label, white 0.15 opacity rounded rect, scales to accent fill on select.
- Auto-advances to step 2 (0.3s delay).

**Step 2 — Action Selection:**
- Selected feeling emoji + label (top).
- "What should we do?" title.
- `ActionOptionButton` list:
  - "Just Tell Them" — `hand.raised` icon (always shown).
  - "Hide Their Videos" — `eye.slash` icon, warning color (level ≥ 2).
  - "Block Them" — `xmark.shield` icon, error color (level 3).
- "Next" button.

**Step 3 — Confirm:**
- Large feeling emoji (64pt).
- "Ready to send?" title.
- `RecipientIndicator`: 3-node diagram — "Them" → "Parents" → "Tubestr" — highlights active nodes per escalation level with connecting lines.
- "Send" primary button (with `ProgressView` while submitting).

**Header throughout:** back button (leading, hidden on step 1) + X dismiss (trailing) + 3 progress dots (center).

### ConversationCardsView (Parent-Facing Safety)
**Source:** `MyTube/SharedUI/Reporting/ConversationCardsView.swift`

Full-height `ScrollView`.

**"Let's Talk" section** (unread or level ≥ 2 inbound reports):
- Each `ConversationCard`:
  - Feeling badge capsule: emoji + label + "from another family".
  - Conversation prompt text.
  - Level indicator icon + label.
  - "Try asking:" + 2–3 conversation starter questions.
  - Bottom: "We Talked" button (accent) + "Mark as Read" button (secondary).

**"Recent Feedback" section** (resolved peer reports): simplified cards, no actions.

**"Feedback You Shared" section** (outbound):
- `OutboundReportCard`: status dot + status text + date + level badge.

**Empty state:** `sparkles` icon (48pt) + "All good here!" + "No reports to review".

### ReportAbuseSheet (Parent-Facing)
**Source:** `MyTube/SharedUI/Reporting/ReportAbuseSheet.swift`

`NavigationStack` Form:
- Inline `Picker` for `ReportReason.allCases`.
- "Actions" section (when `allowsRelationshipActions`): "Unfollow this family" + "Block this family" toggles.
- `TextEditor` notes (120pt min height).
- Error text row.
- Toolbar: Cancel / Submit.

Also exports `ReportButtonChip`: red capsule button (`hand.raised.fill` + label).

### PlaybackControlButton
**Source:** `MyTube/SharedUI/PlaybackControlButton.swift`

SF `Image` button, 56×56pt, `KidCircleIconButtonStyle`.

### PlaybackLikeSummaryView
**Source:** `MyTube/SharedUI/PlaybackLikeSummaryView.swift`

- "N Likes" / "No likes yet" header.
- List of up to 8 display names.
- "+N more" if overflow.

### PlaybackMetricRow
**Source:** `MyTube/SharedUI/PlaybackMetricRow.swift`

`HStack` of `MetricChip` capsules (accent gradient fill, white text): "N Plays", "N% Completion", "N% Replays".

---

## Theming System

**Source:** `MyTube/SharedUI/Theme/KidTheme.swift`

### KidPalette Properties

| Token | Description |
|-------|-------------|
| `accent` | Primary accent color |
| `accentSecondary` | Secondary accent (gradients, highlights) |
| `bgTop` | Background gradient top |
| `bgBottom` | Background gradient bottom |
| `cardFill` | Card background fill |
| `cardStroke` | Card border stroke |
| `chipFill` | Chip/badge background |
| `success` | Success state color |
| `warning` | Warning state color |
| `error` | Error/destructive color |
| `backgroundGradient` | Computed gradient from bgTop → bgBottom |

All colors use `Color(light:dark:)` dynamic provider (`UIColor` adaptive).

### Four Themes

| Theme | Vibe | Accent Light | Accent Dark |
|-------|------|-------------|-------------|
| **Campfire** | Warm amber/orange | `rgb(0.91, 0.49, 0.27)` | `rgb(1.0, 0.62, 0.40)` |
| **Treehouse** | Warm brown/green | — | — |
| **Blanket Fort** | Soft lavender/pink | — | — |
| **Starlight** | Deep purple/gold | — | — |

### Button Styles

| Style | Appearance |
|-------|-----------|
| `KidPrimaryButtonStyle` | Gradient capsule (accent → accentSecondary), white text, headline rounded font, 0.97 scale press, shadow |
| `KidSecondaryButtonStyle` | cardFill background, accent text, bordered capsule |
| `KidCircleIconButtonStyle` | Fixed-size gradient circle (default 56pt) |
| `KidCardBackground` modifier | `.ultraThinMaterial` + cardStroke border + shadow |

---

## Navigation Map

```
App Launch
├── OnboardingFlowView (if needs setup)
│   ├── Introduction slides (pager)
│   ├── Role selection
│   ├── Parent key (new or restore)
│   │   ├── Sheet: ParentProfileOnboardingSheet
│   │   └── Sheet: QRScannerSheet
│   ├── Recovery (restore path only)
│   ├── Child setup
│   │   └── Sheet: ChildProfileSheet
│   └── Ready / Complete
│
└── Main Tab Shell (AppRootView)
    ├── Tab 1: Home (HomeFeedView)
    │   ├── fullScreenCover → PlayerView (local video)
    │   │   ├── Sheet: FeelingReportSheet
    │   │   ├── Sheet: PINPromptView
    │   │   └── fullScreenCover → EditorDetailView
    │   │       └── fullScreenCover → SelfieStickerCaptureView
    │   └── fullScreenCover → PlayerView (remote video)
    │
    ├── Tab 2: Capture (CaptureView)
    │
    ├── Tab 3: Editor (EditorHubView)
    │   └── fullScreenCover → EditorDetailView
    │       └── fullScreenCover → SelfieStickerCaptureView
    │
    └── Tab 4: Parent Zone (ParentZoneView)
        ├── Lock Screen (PIN setup or PIN entry)
        └── Unlocked (sidebar nav + content area)
            ├── Overview
            ├── Family
            │   ├── Sheet: ChildProfileFormSheet
            │   └── Sheet: ChildImportFormSheet
            ├── Connections
            │   └── Sheet: follow request sheet
            ├── Library
            │   └── Sheet: secure share sheet
            ├── Storage
            ├── Safety (ConversationCardsView)
            └── Settings
                └── NavigationLink → Pending Approval list
```

---

## State Management Patterns

These patterns from the SwiftUI app should inform the Flutter architecture:

| Pattern | SwiftUI Implementation | Flutter Equivalent Suggestion |
|---------|----------------------|-------------------------------|
| Global dependency injection | `AppEnvironment` as `@EnvironmentObject` | `Provider` / `Riverpod` at app root |
| Per-screen state | `@StateObject` ViewModel | `ChangeNotifier` / `StateNotifier` per screen |
| Reactive Core Data | `NSFetchedResultsController` in ViewModels | Stream-based repository pattern |
| Theme access | `@EnvironmentObject` → `KidPalette` | `InheritedWidget` / `Theme.of(context)` extension |
| Sheet/modal state | `@State var showingX: Bool` or `@State var activeItem: Item?` | `showModalBottomSheet` / `Navigator.push` |
| Parent Zone navigation | `@State var selectedSection` (sidebar selection) | Custom sidebar + `IndexedStack` or router |
| Deep links | URL → `pendingDeepLink` → `.onChange` observer | `go_router` / `auto_route` deep link handling |
| Profile switching | Menu picker → updates `activeProfile` on environment | Global state notifier, rebuilds dependent widgets |
