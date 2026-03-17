# Tubestr Client Redesign Brief

## Goal

Redesign the client so it feels like one coherent family product with two clearly different modes:

- Kid-facing spaces should feel creative, warm, and action-oriented.
- Parent Zone should feel like a calmer control room.

This brief translates the current critique into concrete direction for Home, Capture/Edit flow entry, Parent Zone, and the shared design system.

## Product Intent

### Child-side job
Help a child quickly understand:

- what they can watch
- how to make something new
- how to keep going after capture into editing

If Home is empty, the interface should strongly prompt capture and edit rather than just acknowledge that nothing exists yet.

### Parent-side job
Help a parent quickly understand:

- what needs attention now
- what is safe and working
- where to manage family, approvals, and moderation

Parent Zone should feel calmer, more structured, and more trustworthy than the kid-facing side.

## Core Design Direction

### Shared foundation

- Keep the warm family-friendly palettes.
- Keep the product voice private, gentle, and human.
- Reduce decorative repetition across the app.

### Kid mode

- Use bolder color moments, larger action cues, and friendlier illustration or media-led composition.
- Prioritize "Capture" and "Edit" over ornamental welcome chrome.
- Make empty states feel like invitations, not placeholders.

### Parent mode

- Use quieter surfaces, less glow, less blur, and fewer playful shapes.
- Shift hierarchy toward typography, spacing, and clear status emphasis.
- Treat urgent items as a dashboard, not a long scrapbook of cards.

## Anti-Patterns To Remove

- Reusing frosted cards as the default container for nearly everything.
- Repeating concentric-circle empty states.
- Using animated blob backgrounds across all contexts.
- Using the same playful typographic tone in kid and parent spaces.
- Giving equal visual weight to urgent actions and passive history.

## Screen Briefs

## Home

### Current problem

Home feels friendly but passive. The greeting and decorative avatar consume early attention, while the real product action is lower in the hierarchy.

### Redesign target

Home should answer these questions immediately:

- Do I have videos to watch?
- If not, how do I make one?
- What should I do next?

### New hierarchy

1. Primary action band at the top:
   Capture a video
   Edit a recent clip
2. Then the main content:
   My videos or in-progress clips
3. Then shared videos from family
4. Then connection growth actions

### Empty-state direction

Replace the current passive empty state with an action-led starter state:

- Headline: "Make your first video"
- Support copy: "Start in Capture, then add stickers, music, or text in Edit Studio."
- Primary CTA: "Open Capture"
- Secondary CTA: "See Edit Studio"

### Layout notes

- Compress or remove the decorative welcome header.
- Let the first scroll viewport contain both the action prompt and the reason to use it.
- Use one strong horizontal action row or one hero action block instead of another generic card.

### Copy notes

- Prefer "Make a video" over "Your Nook awaits!"
- Prefer "Open Capture" and "Edit a clip" over generic nudges.

### Skills

- `/arrange` for hierarchy and first-viewport composition
- `/onboard` for the empty-state teaching pattern
- `/clarify` for CTA and empty-state copy
- `/bolder` if the action area still feels timid

## Capture And Edit Entry

### Current problem

The product already has a strong capture-to-process-to-next-step flow, but the rest of the app does not reinforce it strongly enough.

### Redesign target

Capture should feel like the center of gravity for child creation.

### Direction

- Make Capture the most visually obvious tab.
- Give it a distinct active state shape, not just a color change.
- Echo capture/edit continuity in Home, post-save states, and Editor Hub.
- Treat "Edit" as the natural second step after capture rather than a separate tool island.

### Skills

- `/arrange` for navigation emphasis
- `/animate` for transitions from save to edit
- `/normalize` for consistent action patterns across Home, Capture, and Editor

## Editor Hub

### Current problem

Editor Hub feels like another polite card-based gallery rather than a creative destination.

### Redesign target

Make it feel like a studio entrance, not a generic content list.

### Direction

- Replace the header card with a more intentional title zone or recent-project rail.
- Highlight recent editable clips and drafts.
- Add stronger "continue editing" affordances when work exists.
- When empty, teach the full loop: capture first, then edit.

### Skills

- `/arrange` for composition
- `/typeset` for clearer title hierarchy
- `/onboard` for the empty-state learning path
- `/polish` for card cleanup and spacing refinement

## Parent Zone

### Current problem

Parent Zone uses nearly the same visual language as the kid-facing app, so it does not feel sufficiently calm or authoritative.

### Redesign target

Parent Zone should feel like a control room:

- quieter
- clearer
- denser
- more trustworthy

### Visual direction

- Reduce glow, blur, and soft decorative gradients.
- Use flatter, more stable surfaces.
- Use tighter spacing and stronger type hierarchy.
- Introduce a more restrained heading system than the kid-facing side.

### Information architecture

Reorder the overview so the top of the screen is about urgency:

1. Needs attention now
2. Approval queue
3. Family and connection health
4. Safety and moderation status
5. History and audit trails

### Sidebar direction

- Keep the structural sidebar idea.
- Tone down the current bright gradient header.
- Make the nav feel more utilitarian and less mascot-like.
- Replace the exposed technical identity string with a more parent-readable account summary.

### Copy direction

- Replace technical terms where possible with parent-readable language.
- Keep safety language calm and specific.
- Turn statuses into action-oriented summaries, not just labels and counts.

### Skills

- `/normalize` for mode separation and system consistency
- `/quieter` for calmer visual tone
- `/arrange` for dashboard triage
- `/clarify` for status, settings, and moderation language
- `/typeset` for control-room typography

## Shared System Changes

## Typography

- Keep a friendlier display voice for kid mode.
- Introduce a more restrained text treatment for Parent Zone.
- Increase contrast between headlines, metadata, and passive status text.

### Skills

- `/typeset`

## Color

- Keep warm palettes for child themes.
- Build a quieter parent palette behavior from the same tokens by lowering saturation and contrast in chrome while preserving semantic colors for status.

### Skills

- `/colorize`
- `/normalize`

## Layout

- Stop solving every section with a card.
- Use spacing and grouping as hierarchy.
- Reserve heavy containers for genuinely distinct actions or states.

### Skills

- `/arrange`
- `/distill`

## Motion

- Use motion mainly for capture success, step progression, and reveal of secondary actions.
- Reduce ambient motion in Parent Zone.

### Skills

- `/animate`
- `/quieter`

## States And UX Writing

- Rewrite technical and generic errors into clear, non-blaming messages.
- Turn empty states into directional coaching.
- Make success states confirm what happened and what to do next.

### Skills

- `/clarify`
- `/onboard`
- `/harden`

## Execution Plan

## Phase 1: System Split

- Establish kid-mode and parent-mode rules in theme and shared UI.
- Reduce shared decorative treatments.
- Introduce parent-specific typography and quieter surfaces.

### Primary skills

- `/normalize`
- `/typeset`
- `/quieter`

## Phase 2: Home And Empty States

- Redesign Home first viewport around creation.
- Replace empty-state copy and composition.
- Strengthen capture and edit prompts.

### Primary skills

- `/arrange`
- `/onboard`
- `/clarify`
- `/bolder`

## Phase 3: Parent Zone Control Room

- Rebuild overview around urgency and action.
- Reduce decorative playfulness.
- Improve parent-readable summaries and statuses.

### Primary skills

- `/arrange`
- `/quieter`
- `/clarify`
- `/typeset`

## Phase 4: Continuity And Polish

- Align Capture, Editor, and Home as one creation loop.
- Improve transitions, responsiveness, and edge states.
- Run final polish and resilience pass.

### Primary skills

- `/animate`
- `/adapt`
- `/harden`
- `/polish`

## Success Criteria

- A child opening an empty Home immediately sees how to capture and edit a first video.
- Parent Zone feels recognizably different from the child-facing app without feeling like a different product.
- The UI no longer relies on repeated frosted-card decoration to create hierarchy.
- Parents can identify urgent actions in Parent Zone within two seconds.
- Empty, loading, success, and error states all sound calm, specific, and human.
