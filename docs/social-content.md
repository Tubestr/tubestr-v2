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

Tubestr is live on Android (v1.0.3) and iOS (TestFlight).

Private family video sharing. Nostr identity. MLS encryption. Blossom media storage. No ads, no algorithms, no corporate custody of your family moments.

Your keys. Your family. Your videos.

---

## Reddit Post (r/nostr)

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

Tubestr v1.0.3 is live on Android (GitHub releases + Zapstore) and iOS (TestFlight). The stack is Flutter + Riverpod + Drift (local SQLite) + NDK + mdk-core (Rust via FFI) + Blossom.

We'd love feedback from the Nostr community, especially on:
- The custom kind allocations (4543-4548)
- Marmot/MLS integration patterns
- Blossom multi-server mirroring strategies
- Ideas for cross-app interoperability

Happy to answer technical questions in the comments.

**TL;DR:** Tubestr is a private family video app. Nostr provides decentralized identity and relay transport. MLS provides group encryption with forward secrecy. Blossom stores encrypted media blobs. Parents own their keys. Kids see a fun video app. No corporate servers in the loop.

---

## Reddit Post (r/privacy, r/selfhosted)

**Title:** We built a family video app you can fully self-host. Your relay, your blob server, your keys. No cloud dependency.

**Body:**

Hey r/privacy and r/selfhosted,

I want to show you something we built that I think hits the intersection of both communities. **Tubestr** is a private family video sharing app for parents and kids. The entire server-side infrastructure is self-hostable, and the app is designed so your family's videos never touch a server in plaintext.

### The Setup (for the impatient)

To run Tubestr on entirely self-hosted infrastructure, you need two things:

1. **A Nostr relay** -- a lightweight WebSocket server that stores and forwards signed JSON events
2. **A Blossom server** -- a simple HTTP blob server for media files (videos, thumbnails)

That's it. No application server. No database you manage. No auth service. The relay and Blossom server are the entire backend, and both are trivial to self-host.

### Self-Hosting a Nostr Relay

A Nostr relay is a WebSocket server that accepts signed JSON events, stores them, and serves them back based on filters. Several mature implementations exist:

- **strfry** -- C++, single binary, extremely fast, handles millions of events. Config is one file.
- **nostr-rs-relay** -- Rust, SQLite-backed, low resource usage. Good for a home server or Raspberry Pi.
- **nostream** -- TypeScript/Node, PostgreSQL-backed, more ops-friendly if you already run Postgres.

A minimal relay runs on practically anything. A Raspberry Pi with an SD card can handle a family's traffic without breaking a sweat. You're talking single-digit megabytes of JSON events for metadata (the actual videos go elsewhere).

**Setup is genuinely simple:**

```bash
# Example with strfry (single binary)
git clone https://github.com/hoytech/strfry.git
cd strfry && make setup-golpe && make -j4
./strfry relay  # running on ws://localhost:7777
```

Or with Docker:

```bash
docker run -p 7777:7777 -v strfry-data:/app/strfry-db dockurr/strfry
```

Point your reverse proxy at it, add a TLS cert (Let's Encrypt), and you have a production relay at `wss://relay.yourfamily.net`.

In Tubestr, parents go to the **Relay Management** section in Parent Zone and add your relay URL. The app publishes all events (shares, likes, group state) to your relay and subscribes from it. You can add multiple relays for redundancy, or use just your own for maximum control.

### Self-Hosting a Blossom Server

Blossom is content-addressed blob storage over HTTP. Files go in, addressed by SHA-256 hash. Files come out by hash. That's the entire API.

- **blossom-server** -- the reference Go implementation. Single binary, filesystem-backed storage.
- **bouquet** -- Rust alternative, also filesystem-backed.

```bash
# Example with blossom-server
git clone https://github.com/hoytech/blossom-server.git
cd blossom-server && go build
./blossom-server  # running on http://localhost:3000
```

Throw it behind Nginx with TLS and you have `https://blossom.yourfamily.net`. Storage is just files on disk. Back them up however you back up any files -- rsync, ZFS snapshots, Borg, whatever you already use.

In Tubestr, parents configure their Blossom server list in Parent Zone. The app uploads encrypted video blobs to your server and downloads them from it.

**Storage math:** A typical family video is 30-90 seconds. At reasonable quality that's 20-80 MB per clip. A 1 TB drive holds tens of thousands of family videos. You won't outgrow a basic home server for years.

### What the Servers Actually See

Here's the privacy part that matters: **your self-hosted servers never see plaintext content.**

Videos are encrypted on-device with AES-GCM *before* upload to Blossom. The encryption key is generated per-video and delivered to family members through an MLS-encrypted group message on your Nostr relay. MLS (Messaging Layer Security, RFC 9420) provides group encryption with forward secrecy.

So even if someone compromises your Blossom server, they get encrypted blobs. Even if someone compromises your relay, they get encrypted event payloads. The decryption keys only exist on family members' devices, derived from the MLS group secret.

**Threat model summary:**
- Relay operator (you) sees: encrypted JSON event payloads, public keys, timestamps, event kinds
- Blossom operator (you) sees: encrypted binary blobs addressed by hash
- Neither sees: video content, thumbnail content, message text, who liked what
- Only family group members can decrypt: video files, share metadata, reactions, moderation actions

### The Full Self-Hosted Stack

Here's what a fully self-hosted Tubestr deployment looks like:

```
Family Phone A ──┐
                 ├──WSS──▶ [Your Nostr Relay]  (events, metadata, group state)
Family Phone B ──┘         e.g. strfry on a Pi
                 │
                 ├──HTTPS─▶ [Your Blossom Server]  (encrypted video blobs)
                 │          e.g. blossom-server on same Pi or NAS
```

Total infrastructure: one small server (or two if you want separation). Both services are lightweight, single-process, and designed to run unattended.

**What you control:**
- The relay where your family's events are stored (you can restrict it to only accept events from your family's public keys)
- The blob server where encrypted videos live (you can restrict uploads to authenticated users)
- Backup strategy (it's just a SQLite file and a directory of blobs)
- Network access (run it on your LAN only, or expose it through a VPN/Tailscale for remote family)

**What you don't have to manage:**
- No application server or custom backend code
- No database migrations (the relay handles its own storage)
- No user management (identity is cryptographic keypairs, managed on-device)
- No auth service (events are self-authenticating via cryptographic signatures; Blossom uses Nostr-signed auth tokens)

### How It Compares to Other Self-Hosted Options

| | Tubestr (self-hosted) | Immich / PhotoPrism | Jellyfin | Nextcloud |
|---|---|---|---|---|
| Server sees plaintext | No (E2E encrypted) | Yes | Yes | Yes (unless Veracrypt etc.) |
| Auth system to manage | No (keypairs) | Yes | Yes | Yes |
| Database to manage | No (relay handles it) | Yes (Postgres) | Yes (SQLite/Postgres) | Yes (MySQL/Postgres) |
| Kid-safe UX | Yes (designed for it) | No | No | No |
| Parent controls | Yes (approvals, moderation) | No | Limited | No |
| Works offline on mobile | Yes (local-first) | Limited | No (streaming) | Limited |
| Decentralized / portable | Yes (switch relays anytime) | No (server-bound) | No | No |

The trade-off: Tubestr is purpose-built for family video sharing, not a general-purpose photo/file tool. If you want a full photo library, use Immich. If you want a family video space where your kids can safely create, edit, and share clips under your control with E2E encryption and zero server-side plaintext -- that's what we built.

### For the Paranoid (in the best way)

If you want to go further:

- **LAN-only mode:** Run your relay and Blossom server on your local network. Family devices connect over WiFi. Nothing leaves your house.
- **VPN/Tailscale:** Expose your relay and Blossom server only through a VPN. Remote family members connect through the tunnel.
- **Restricted relay:** Configure your relay to only accept events signed by your family's known public keys. Strangers can't even publish to it.
- **Restricted Blossom:** Configure upload auth to only accept Nostr-signed tokens from your family's keys. No anonymous uploads.
- **Air-gapped backup:** Since Blossom is just files on disk and the relay is a SQLite file, you can rsync to an offline backup drive on a schedule.

### Current Status

Tubestr v1.0.3 is live on Android (GitHub releases + Zapstore) and iOS (TestFlight). The app works with public relays and Blossom servers out of the box (no self-hosting required to get started), but the entire infrastructure is replaceable with your own.

The stack: Flutter + Riverpod + Drift (local SQLite) + NDK (Nostr client) + mdk-core (MLS encryption, Rust via FFI) + Blossom.

Happy to answer questions about the self-hosting setup, the encryption model, or anything else.

**TL;DR:** Tubestr is a private family video app. Self-host a Nostr relay (strfry, one binary) and a Blossom server (another single binary) and you own the entire stack. All content is E2E encrypted with MLS before it leaves the device -- your servers never see plaintext. Kids get a fun video app, parents get full control, and no data leaves your infrastructure unencrypted.

---

## Reddit Post (r/vibecoding)

**Title:** I vibecoded a full video sharing app with zero backend code. The secret: a protocol called Nostr.

**Body:**

I just shipped a family video sharing app (Tubestr) and I want to talk about the thing that made it possible as a vibecoding project: I never had to build a backend.

No Express server. No database migrations. No auth system. No WebSocket server. No Docker containers. No AWS bill. I vibecoded the entire thing as a Flutter client and plugged it into an open protocol called Nostr. If you haven't heard of it, here's why it should be in your vibecoding toolkit.

### What is Nostr in 30 seconds

Nostr is a protocol, not a platform. It has two concepts:

1. **Keys.** Your identity is a cryptographic keypair. You generate it locally. That's it. No signup, no email, no OAuth. One line of code gives you a user identity.

2. **Relays.** These are dumb WebSocket servers that store and forward JSON events. Anyone can run one. Dozens of public ones already exist. You connect, publish events, subscribe to events. That's the entire API.

An "event" is just a JSON object: a kind number (like an event type), some content, some tags, and a cryptographic signature from the author's key. That's the whole data model.

### Why this is vibecoding gold

Here's what I *didn't* have to build, prompt, or debug:

**No auth system.** Identity is a keypair generated on-device. No registration endpoint, no password hashing, no session tokens, no "forgot password" flow, no OAuth integration. I prompt my AI to generate a keypair and store it in secure storage. Done. Users are real cryptographic identities from line one.

**No backend server.** Nostr relays are the backend. They're already running, publicly available, and free to use. I didn't write a single line of server code. My app connects to relays, publishes signed events, and subscribes to events from other users. The relay doesn't need to know what my app does. It just stores JSON blobs and serves them back on request.

**No database design.** Events *are* the database. Each event has a kind (integer), content (string), tags (key-value pairs), and a timestamp. Need to store a video share? Publish a kind:4543 event. Need to store a like? Kind:4546. Need to query all shares from a specific user? Subscribe with a filter: `{kinds: [4543], authors: ["<pubkey>"]}`. The relay handles the query. I didn't design a schema, write migrations, or set up an ORM.

**No API design.** There's no REST API, no GraphQL schema, no endpoint versioning. The entire interaction model is publish/subscribe over WebSockets. Publish an event, subscribe to events matching a filter. Two operations. That's the whole API surface for your AI to learn.

**No file storage infra.** For media (videos, thumbnails), there's a companion system called Blossom -- content-addressed blob storage over HTTP. Upload a file, get back a SHA-256 hash. Download by hash. That's it. Multiple public Blossom servers already exist. I didn't spin up S3 buckets or configure CDNs.

**No DevOps.** No containers. No CI/CD for a backend. No load balancer. No scaling conversations. The relays handle it. The Blossom servers handle it. My app is a pure client.

### What I actually spent my time on

Instead of fighting infrastructure, I got to vibecode the things that matter:

- A kid-friendly camera and video editor (trim, filters, stickers, text, audio)
- A parent control panel with content approval and moderation
- A home feed showing family videos
- Encrypted group sharing (MLS protocol -- standard group encryption)
- An offline queue that syncs when connectivity returns
- On-device content safety scanning

All the product stuff. All the UX stuff. Zero infrastructure stuff.

### The AI prompting angle

Nostr is absurdly easy to explain to an AI coding assistant. The entire publish flow is:

```
1. Create a JSON event with kind, content, tags, and timestamp
2. Sign it with the user's private key
3. Send it to connected relays via WebSocket
```

The entire read flow is:

```
1. Send a filter (kinds, authors, tags, time range) to a relay
2. Receive matching events
```

That's it. There's no complex API surface for the AI to hallucinate endpoints for. There's no auth middleware to get wrong. The data model is flat JSON events. Every event is self-authenticating (the signature proves who created it). Your AI assistant can grok the entire protocol in one prompt.

Compare that to prompting an AI to set up a full-stack app: Express routes, middleware chains, database schemas, connection pooling, JWT validation, CORS config, error handling... that's where vibecoded projects go to die. Every layer is another place for the AI to introduce a subtle bug you'll spend hours debugging.

### NDK: the client library

The Nostr ecosystem has a mature client library called **NDK** (Nostr Developer Kit). It handles relay connections, event publishing, subscriptions, caching, and key management. In Flutter, there's a dart NDK package. In JS/TS, there's `@nostr-dev-kit/ndk`.

You point your AI at NDK and say "use this to publish and subscribe to events." That's the entire integration. I didn't need to write WebSocket management code, reconnection logic, or relay failover. NDK does it.

### "But isn't this decentralized/crypto stuff complicated?"

Not for the builder. Here's the mental model:

- **Users** = keypairs (like SSH keys, but for your app)
- **Data** = signed JSON events published to relays
- **Storage** = relays (text/metadata) + Blossom (files/media)
- **Queries** = filters sent to relays over WebSocket

If you can prompt an AI to make a todo app with a REST API and Postgres, you can prompt it to make a todo app on Nostr. Except the Nostr version doesn't need a server, a database, or auth middleware. It's *less* complexity, not more.

The "decentralized" part just means your users aren't locked into your server. They hold their own keys. Their data lives on relays they choose. If your app disappears tomorrow, their identity and data still exist. That's a feature, not a complication.

### What I shipped

**Tubestr** -- a private family video sharing app for parents and kids.

- Parents hold a Nostr keypair (their identity)
- Family groups are encrypted with MLS (an IETF standard for group encryption)
- Videos are encrypted on-device, uploaded to Blossom servers, decryption keys shared via the encrypted group
- Kids capture, edit, and watch videos in a playful UI
- Parents manage profiles, approve content, moderate, and control everything
- Works offline, syncs when connected
- Live on Android (v1.0.3) and iOS (TestFlight)

The entire networking layer is Nostr relays. The entire storage layer is Blossom. I wrote zero backend code.

### Getting started

If you want to try Nostr for your next vibecoding project:

1. **Pick a client library.** `@nostr-dev-kit/ndk` for JS/TS, `ndk` for Dart/Flutter, `rust-nostr` for Rust.
2. **Generate a keypair.** One function call. That's your user.
3. **Connect to a relay.** `wss://relay.damus.io` or `wss://nos.lol` are good public ones.
4. **Publish an event.** JSON object, sign it, send it.
5. **Subscribe to events.** Send a filter, receive matching events.

You now have a multi-user, networked app with persistent storage and user authentication. No backend deployed. No database provisioned. No auth service configured.

Tell your AI assistant: "We're using Nostr. Users are keypairs. Data is signed JSON events published to WebSocket relays. Use NDK for the client library." Then vibecode your actual product.

**TL;DR:** Nostr eliminates the backend from vibecoding. Identity is a keypair (no auth to build). Data is signed JSON events on WebSocket relays (no database or API to build). Files go to Blossom (no S3 to configure). Your AI assistant can learn the entire protocol in one prompt. I shipped a full encrypted video sharing app without writing a single line of server code.
