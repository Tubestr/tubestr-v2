# Tubestr Social Content

## Twitter/X Thread

**Tweet 1 (Hook)**

Your family videos live on corporate servers. They train AI models. They feed recommendation algorithms. They sit behind terms of service that change without notice.

We built Tubestr to fix this. A private family video app where parents own the keys, literally.

Here's how. (thread)

---

**Tweet 2 (What)**

Tubestr is a family video sharing app. Kids capture, edit, and share clips. Parents manage everything: profiles, approvals, moderation, and who gets to see what.

No algorithmic feeds. No ads. No strangers in the comments. Just your family, sharing moments in a space you actually control.

---

**Tweet 3 (The Problem)**

Every "family-friendly" video platform today is a corporate product first and a family tool second.

YouTube Kids still runs on Google's infrastructure. iCloud Photos is locked to Apple's ecosystem. None of them give you real ownership of your identity or your data.

Parents deserve better.

---

**Tweet 4 (Why Nostr - Identity)**

Tubestr is built on Nostr, and here's why that matters.

On Nostr, your identity is a cryptographic keypair. You generate it. You hold it. No company issues it, no company can revoke it.

Parents create a Nostr key during onboarding. That key signs every action in the app: shares, approvals, moderation decisions. It's portable, it's yours, and it works across any Nostr-compatible app.

---

**Tweet 5 (Why Nostr - Relays & Decentralization)**

Nostr uses relays instead of centralized servers. Your data isn't stored in one company's database. It's distributed across relays you choose.

Tubestr families pick their own relay set. If a relay goes down or starts misbehaving, you switch. No vendor lock-in. No single point of failure. No terms of service that can pull the rug.

---

**Tweet 6 (Why Nostr - The Right Fit)**

Why not just use Signal protocol or Matrix or a custom backend?

Nostr gives us three things at once:
- Decentralized identity (keypairs, not accounts)
- A relay network for message delivery
- An open ecosystem of NIPs (protocol extensions) to build on

It's the only protocol that combines self-sovereign identity with a flexible messaging layer and an active open-source ecosystem. We didn't have to reinvent any of these pieces.

---

**Tweet 7 (MLS - The Encryption Layer)**

Family groups in Tubestr are encrypted with MLS (Messaging Layer Security) via the Marmot protocol.

MLS is a standard from the IETF (RFC 9420). It's not homegrown crypto. It provides:
- Group encryption that scales (not just 1-to-1)
- Forward secrecy (compromise a key today, old messages stay private)
- Efficient member add/remove without re-encrypting everything

---

**Tweet 8 (MLS + Nostr Together)**

Here's how it fits together:

1. Parent creates a family group (an MLS group)
2. Invites another parent via QR code / deep link
3. MLS key packages are published as Nostr events (kind:443)
4. Welcome messages delivered via Nostr relays (kind:444)
5. Every shared video, like, and moderation action is an MLS-encrypted message on Nostr

The relay sees encrypted blobs. Only family members hold the group secret.

---

**Tweet 9 (Blossom - Media Storage)**

Videos don't live on relays. They go to Blossom servers: immutable blob storage, addressed by SHA-256 hash.

Videos are encrypted on-device before upload. Uploaded to multiple Blossom servers for redundancy. Only family members have the decryption key (delivered via MLS).

Even the blob server operator can't watch your kids' videos.

---

**Tweet 10 (Kids Experience)**

For kids, none of this is visible. They see a warm, playful app.

- Capture videos with the camera
- Edit with trim, filters, stickers, text, and audio
- Watch a home feed of family clips
- React with likes and emoji

The crypto, relays, and key management are invisible. That's the point.

---

**Tweet 11 (Parent Experience)**

Parents get a calm control panel:

- Create and manage child profiles
- Review and approve content before it's shared
- Invite trusted family members
- Moderate or remove content
- Back up and restore their Nostr key
- On-device content scanning gives you a safety summary before approving

Full control. No black boxes.

---

**Tweet 12 (Local-First)**

Tubestr is local-first. Everything works offline.

Captures, edits, likes, shares, and reports queue up locally and sync when connectivity returns. No spinner of death when the WiFi drops.

Your data lives on your device first. The network is for sharing, not for storage.

---

**Tweet 13 (CTA)**

Tubestr is live on Android (v1.0.3). iOS is next.

Private family video sharing. Nostr identity. MLS encryption. Blossom media storage. No ads, no algorithms, no corporate custody of your family moments.

Your keys. Your family. Your videos.

---

## Reddit Post (r/nostr, r/privacy, r/selfhosted)

**Title:** We built a family video sharing app on Nostr + MLS encryption. Here's the technical deep dive on why.

**Body:**

Hey everyone,

I want to share what we've been building with **Tubestr** and, more importantly, *why* we made the technical choices we did. This is a family video sharing app for parents and kids, and under the hood it runs on Nostr for identity/transport and MLS for group encryption.

### The Problem

There's no good option for families who want to share home videos privately without handing everything to a big tech platform. YouTube Kids, Google Photos, iCloud -- they all require you to trust a corporation with your family's most personal content. Your identity is an account they control. Your data sits on their servers under their terms.

We wanted to build something where **parents actually own the infrastructure**: their identity, their encryption keys, their choice of servers.

### Why Nostr?

We evaluated several approaches and kept coming back to Nostr for a few reasons:

**1. Self-sovereign identity.** Nostr identity is a keypair. Parents generate theirs during onboarding and hold the private key (nsec). No registration server, no email/password, no OAuth dependency. The key is portable -- back it up, restore it on another device, use it in other Nostr apps. Children don't get independent keys (deliberate design choice -- they're local profiles managed entirely by parents).

**2. Relay-based transport.** Instead of building and operating centralized infrastructure, we use Nostr relays for message delivery. Families configure their own relay sets (kind:10002 events). If a relay disappears or becomes untrustworthy, switch to another. The protocol doesn't care. This gives us decentralization without having to build our own federation protocol.

**3. Extensible event model.** Nostr's kind system lets us define custom event types for our use case without conflicting with the broader ecosystem:
- `kind:4543` -- encrypted video share metadata
- `kind:4544` -- video revocation
- `kind:4545` -- video deletion
- `kind:4546` -- likes
- `kind:4547` -- reports (3-level escalation)
- `kind:4548` -- emoji reactions

This slots cleanly into existing Nostr infrastructure. Relays don't need to know what these events mean -- they just store and forward them.

**4. Ecosystem momentum.** NDK (Nostr Developer Kit) gave us a solid client library. The NIP process gives us a standards track to build on. The community is active and aligned with the kind of user-sovereignty we care about.

### Why MLS?

All group communication in Tubestr is encrypted with MLS (Messaging Layer Security, RFC 9420). We use the Marmot protocol, which maps MLS operations onto Nostr events:

- `kind:443` -- MLS key packages (member credentials)
- `kind:444` -- MLS welcome messages (group invitations)
- `kind:445` -- MLS group commits (state transitions)

**Why MLS over simpler alternatives?**

- **Group scalability.** Signal protocol is excellent for 1-to-1 but group handling gets complex. MLS was designed from the ground up for group encryption with efficient add/remove operations.
- **Forward secrecy.** Key ratcheting means past messages remain private even if a current key is compromised.
- **Standard cryptography.** MLS is an IETF RFC, not custom crypto. It's been formally analyzed. We integrate it via `mdk-core` (a Rust implementation) bridged to Flutter via `flutter_rust_bridge`.
- **Clean membership model.** MLS group state evolves deterministically. All members derive the same group secret. Adding or removing a member is a commit operation that all members process. This maps naturally to "parent invites another parent to the family group."

The MLS state lives in an isolated local SQLite database on each device. Key packages are published to Nostr relays. Welcome messages are delivered as gift-wrapped Nostr events (encrypted to the recipient's Nostr key). From the relay's perspective, it's all opaque blobs.

### Media Storage: Blossom

Videos don't go through relays (too large). Instead, we use **Blossom** -- immutable blob storage addressed by SHA-256 hash.

The flow:
1. Video is encrypted on-device (AES-GCM, key generated per-video)
2. Encrypted blob is uploaded to one or more Blossom servers
3. The decryption key, hash, and server list are sent to the family group as an MLS-encrypted Nostr event
4. Recipients fetch the blob from Blossom, decrypt locally

Blossom servers are authenticated via BUD-02/BUD-11 (Nostr-signed auth). Families configure their Blossom server list via `kind:10063` events. Multi-server mirroring provides redundancy.

The key insight: **the blob server never sees plaintext video**. It stores encrypted data addressed by hash. Only family group members have the MLS-derived key to decrypt.

### What Users Actually See

All of this complexity is invisible to users:

**Kids** get a playful, warm UI: camera capture, a video editor with trim/filters/stickers/text/audio, a home feed of family videos, and like/reaction buttons.

**Parents** get a calm control panel: child profile management, content approval queues (with on-device safety scanning summaries), family group invitations via QR code, relay and Blossom server configuration, moderation tools, and key backup/restore.

The app is local-first. Everything works offline. Captures, edits, shares, likes, and reports queue locally and sync when connectivity returns.

### Current Status

Tubestr v1.0.3 is live on Android (GitHub releases + Zapstore). iOS is next. The stack is Flutter + Riverpod + Drift (local SQLite) + NDK + mdk-core (Rust via FFI) + Blossom.

We'd love feedback from the Nostr community, especially on:
- The custom kind allocations (4543-4548)
- Marmot/MLS integration patterns
- Blossom multi-server mirroring strategies
- Ideas for cross-app interoperability

Happy to answer technical questions in the comments.

**TL;DR:** Tubestr is a private family video app. Nostr provides decentralized identity and relay transport. MLS provides group encryption with forward secrecy. Blossom stores encrypted media blobs. Parents own their keys. Kids see a fun video app. No corporate servers in the loop.
