use std::fs;
use std::path::PathBuf;
use std::sync::Mutex;

use mdk_core::encrypted_media::types::MediaReference;
use mdk_core::groups::{NostrGroupConfigData, NostrGroupDataUpdate};
use mdk_core::key_packages::KeyPackageEventData as MdkKeyPackageEventData;
use mdk_core::messages::MessageProcessingResult;
use mdk_core::MDK;
use mdk_sqlite_storage::MdkSqliteStorage;
use mdk_storage_traits::groups::types::GroupState;
use mdk_storage_traits::GroupId;
use nostr::JsonUtil;
use nostr::{Event, EventId, PublicKey, RelayUrl, Tag, UnsignedEvent};
use once_cell::sync::Lazy;

type MdkInstance = MDK<MdkSqliteStorage>;

static MDK_INSTANCE: Lazy<Mutex<Option<MdkRuntime>>> = Lazy::new(|| Mutex::new(None));

struct MdkRuntime {
    db_path: PathBuf,
    mdk: MdkInstance,
}

pub struct KeyPackageEventData {
    pub content: String,
    pub tags_json: String,
    pub hash_ref_hex: String,
}

pub struct GroupSummaryData {
    pub mls_group_id_hex: String,
    pub nostr_group_id_hex: String,
    pub name: String,
    pub description: String,
    pub member_count: u32,
    pub admin_pubkeys_hex: Vec<String>,
}

pub struct PendingWelcomeData {
    pub welcome_event_id_hex: String,
    pub wrapper_event_id_hex: String,
    pub mls_group_id_hex: String,
    pub nostr_group_id_hex: String,
    pub group_name: String,
    pub group_description: String,
    pub member_count: u32,
    pub welcomer_pubkey_hex: String,
    pub relays: Vec<String>,
    pub state: String,
}

pub struct CreateGroupWithWelcomesData {
    pub group: GroupSummaryData,
    pub welcome_rumor_jsons: Vec<String>,
}

pub struct MessageEventData {
    pub wrapper_event_json: String,
    pub wrapper_event_id_hex: String,
    pub rumor_event_id_hex: String,
    pub mls_group_id_hex: String,
}

pub struct GroupUpdateData {
    pub wrapper_event_json: String,
    pub wrapper_event_id_hex: String,
    pub mls_group_id_hex: String,
}

pub struct ProcessedMessageData {
    pub outcome: String,
    pub mls_group_id_hex: String,
    pub message_event_id_hex: String,
    pub wrapper_event_id_hex: String,
    pub pubkey_hex: String,
    pub kind: u32,
    pub content: String,
    pub created_at: u64,
    pub state: String,
}

pub struct EncryptedMediaData {
    pub encrypted_data: Vec<u8>,
    pub encrypted_hash_hex: String,
    pub original_hash_hex: String,
    pub mime_type: String,
    pub filename: String,
    pub original_size: u64,
    pub encrypted_size: u64,
    pub nonce_hex: String,
    pub scheme_version: String,
    pub epoch: u64,
}

pub fn bridge_version() -> String {
    format!(
        "mdk_bridge={} mdk-core={} mode=smoke-test",
        env!("CARGO_PKG_VERSION"),
        "0.7.1+8a8d06c"
    )
}

pub fn init_mdk_unencrypted(data_dir: String) -> Result<String, String> {
    let root = PathBuf::from(data_dir);
    fs::create_dir_all(&root).map_err(|err| err.to_string())?;

    let db_path = root.join("mdk.sqlite");
    let storage = MdkSqliteStorage::new_unencrypted(&db_path).map_err(|err| err.to_string())?;
    let mdk = MDK::new(storage);

    let mut guard = MDK_INSTANCE.lock().map_err(|err| err.to_string())?;
    *guard = Some(MdkRuntime {
        db_path: db_path.clone(),
        mdk,
    });

    Ok(db_path.display().to_string())
}

pub fn mdk_db_path() -> Result<String, String> {
    let guard = MDK_INSTANCE.lock().map_err(|err| err.to_string())?;
    let runtime = guard
        .as_ref()
        .ok_or_else(|| "MDK runtime has not been initialized".to_string())?;
    Ok(runtime.db_path.display().to_string())
}

pub fn group_count() -> Result<u32, String> {
    let guard = MDK_INSTANCE.lock().map_err(|err| err.to_string())?;
    let runtime = guard
        .as_ref()
        .ok_or_else(|| "MDK runtime has not been initialized".to_string())?;
    let groups = runtime.mdk.get_groups().map_err(|err| err.to_string())?;
    u32::try_from(groups.len()).map_err(|err| err.to_string())
}

pub fn group_summaries() -> Result<Vec<String>, String> {
    let guard = MDK_INSTANCE.lock().map_err(|err| err.to_string())?;
    let runtime = guard
        .as_ref()
        .ok_or_else(|| "MDK runtime has not been initialized".to_string())?;
    let groups = runtime.mdk.get_groups().map_err(|err| err.to_string())?;

    Ok(groups
        .into_iter()
        .map(|group| {
            format!(
                "{}|{}",
                hex::encode(group.mls_group_id.as_slice()),
                group.name
            )
        })
        .collect())
}

pub fn get_group_summaries() -> Result<Vec<GroupSummaryData>, String> {
    let guard = MDK_INSTANCE.lock().map_err(|err| err.to_string())?;
    let runtime = guard
        .as_ref()
        .ok_or_else(|| "MDK runtime has not been initialized".to_string())?;
    let groups = runtime.mdk.get_groups().map_err(|err| err.to_string())?;

    groups
        .into_iter()
        .filter(|group| group.state == GroupState::Active)
        .map(|group| summarize_group(runtime, group))
        .collect()
}

pub fn create_key_package_event(
    public_key_hex: String,
    relays: Vec<String>,
) -> Result<KeyPackageEventData, String> {
    let guard = MDK_INSTANCE.lock().map_err(|err| err.to_string())?;
    let runtime = guard
        .as_ref()
        .ok_or_else(|| "MDK runtime has not been initialized".to_string())?;

    let public_key =
        PublicKey::parse(&public_key_hex).map_err(|err| format!("Invalid pubkey: {err}"))?;
    let relay_urls = relays
        .into_iter()
        .map(|relay| {
            RelayUrl::parse(&relay).map_err(|err| format!("Invalid relay '{relay}': {err}"))
        })
        .collect::<Result<Vec<_>, _>>()?;

    let MdkKeyPackageEventData {
        content,
        tags_30443,
        hash_ref,
        ..
    } = runtime
        .mdk
        .create_key_package_for_event(&public_key, relay_urls)
        .map_err(|err| err.to_string())?;

    Ok(KeyPackageEventData {
        content,
        tags_json: serialize_tags(&tags_30443)?,
        hash_ref_hex: hex::encode(hash_ref),
    })
}

pub fn create_local_group(
    creator_public_key_hex: String,
    name: String,
    description: String,
    relays: Vec<String>,
    member_key_package_event_jsons: Vec<String>,
) -> Result<GroupSummaryData, String> {
    Ok(create_local_group_with_welcomes(
        creator_public_key_hex,
        name,
        description,
        relays,
        member_key_package_event_jsons,
    )?
    .group)
}

pub fn create_local_group_with_welcomes(
    creator_public_key_hex: String,
    name: String,
    description: String,
    relays: Vec<String>,
    member_key_package_event_jsons: Vec<String>,
) -> Result<CreateGroupWithWelcomesData, String> {
    let guard = MDK_INSTANCE.lock().map_err(|err| err.to_string())?;
    let runtime = guard
        .as_ref()
        .ok_or_else(|| "MDK runtime has not been initialized".to_string())?;

    let creator_public_key = PublicKey::parse(&creator_public_key_hex)
        .map_err(|err| format!("Invalid creator pubkey: {err}"))?;
    let relay_urls = relays
        .into_iter()
        .map(|relay| {
            RelayUrl::parse(&relay).map_err(|err| format!("Invalid relay '{relay}': {err}"))
        })
        .collect::<Result<Vec<_>, _>>()?;
    let member_key_package_events = member_key_package_event_jsons
        .into_iter()
        .map(|json| {
            Event::from_json(json).map_err(|err| format!("Invalid member event json: {err}"))
        })
        .collect::<Result<Vec<_>, _>>()?;

    let config = NostrGroupConfigData {
        name,
        description,
        image_hash: None,
        image_key: None,
        image_nonce: None,
        relays: relay_urls,
        admins: vec![creator_public_key],
    };

    let result = runtime
        .mdk
        .create_group(&creator_public_key, member_key_package_events, config)
        .map_err(|err| err.to_string())?;

    Ok(CreateGroupWithWelcomesData {
        group: summarize_group(runtime, result.group)?,
        welcome_rumor_jsons: result
            .welcome_rumors
            .into_iter()
            .map(|event| event.as_json())
            .collect(),
    })
}

pub fn process_welcome_rumor(welcome_rumor_json: String) -> Result<PendingWelcomeData, String> {
    let guard = MDK_INSTANCE.lock().map_err(|err| err.to_string())?;
    let runtime = guard
        .as_ref()
        .ok_or_else(|| "MDK runtime has not been initialized".to_string())?;

    let mut welcome_rumor = UnsignedEvent::from_json(welcome_rumor_json)
        .map_err(|err| format!("Invalid welcome rumor json: {err}"))?;
    let wrapper_event_id = welcome_rumor.id();

    runtime
        .mdk
        .process_welcome(&wrapper_event_id, &welcome_rumor)
        .map_err(|err| err.to_string())?;

    let welcome = runtime
        .mdk
        .get_welcome(&wrapper_event_id)
        .map_err(|err| err.to_string())?
        .ok_or_else(|| "Processed welcome was not stored".to_string())?;

    summarize_pending_welcome(welcome)
}

pub fn get_pending_welcome_summaries() -> Result<Vec<PendingWelcomeData>, String> {
    let guard = MDK_INSTANCE.lock().map_err(|err| err.to_string())?;
    let runtime = guard
        .as_ref()
        .ok_or_else(|| "MDK runtime has not been initialized".to_string())?;
    let welcomes = runtime
        .mdk
        .get_pending_welcomes(None)
        .map_err(|err| err.to_string())?;

    welcomes
        .into_iter()
        .map(summarize_pending_welcome)
        .collect()
}

pub fn accept_pending_welcome(welcome_event_id_hex: String) -> Result<GroupSummaryData, String> {
    let guard = MDK_INSTANCE.lock().map_err(|err| err.to_string())?;
    let runtime = guard
        .as_ref()
        .ok_or_else(|| "MDK runtime has not been initialized".to_string())?;

    let event_id = EventId::parse(&welcome_event_id_hex)
        .map_err(|err| format!("Invalid welcome event id: {err}"))?;
    let welcome = runtime
        .mdk
        .get_welcome(&event_id)
        .map_err(|err| err.to_string())?
        .ok_or_else(|| "Pending welcome not found".to_string())?;

    runtime
        .mdk
        .accept_welcome(&welcome)
        .map_err(|err| err.to_string())?;

    let group = if let Some(group) = runtime
        .mdk
        .get_group(&welcome.mls_group_id)
        .map_err(|err| err.to_string())?
    {
        Some(group)
    } else {
        runtime
            .mdk
            .get_groups()
            .map_err(|err| err.to_string())?
            .into_iter()
            .find(|group| group.nostr_group_id == welcome.nostr_group_id)
            .or_else(|| {
                runtime.mdk.get_groups().ok().and_then(|groups| {
                    if groups.len() == 1 {
                        groups.into_iter().next()
                    } else {
                        None
                    }
                })
            })
    };

    match group {
        Some(group) => summarize_group(runtime, group),
        None => Ok(GroupSummaryData {
            mls_group_id_hex: hex::encode(welcome.mls_group_id.as_slice()),
            nostr_group_id_hex: hex::encode(welcome.nostr_group_id),
            name: welcome.group_name,
            description: welcome.group_description,
            member_count: welcome.member_count,
            admin_pubkeys_hex: welcome
                .group_admin_pubkeys
                .into_iter()
                .map(|pubkey| pubkey.to_string())
                .collect(),
        }),
    }
}

pub fn get_group_members(mls_group_id_hex: String) -> Result<Vec<String>, String> {
    let guard = MDK_INSTANCE.lock().map_err(|err| err.to_string())?;
    let runtime = guard
        .as_ref()
        .ok_or_else(|| "MDK runtime has not been initialized".to_string())?;

    let mls_group_id = group_id_from_hex(&mls_group_id_hex)?;
    let members = runtime
        .mdk
        .get_members(&mls_group_id)
        .map_err(|err| err.to_string())?;

    Ok(members
        .into_iter()
        .map(|pubkey| pubkey.to_string())
        .collect())
}

pub fn remove_group_members(
    mls_group_id_hex: String,
    member_pubkeys_hex: Vec<String>,
) -> Result<GroupUpdateData, String> {
    let guard = MDK_INSTANCE.lock().map_err(|err| err.to_string())?;
    let runtime = guard
        .as_ref()
        .ok_or_else(|| "MDK runtime has not been initialized".to_string())?;

    let mls_group_id = group_id_from_hex(&mls_group_id_hex)?;
    let member_pubkeys = member_pubkeys_hex
        .into_iter()
        .map(|pubkey| {
            PublicKey::parse(&pubkey).map_err(|err| format!("Invalid member pubkey: {err}"))
        })
        .collect::<Result<Vec<_>, _>>()?;

    let result = runtime
        .mdk
        .remove_members(&mls_group_id, &member_pubkeys)
        .map_err(|err| err.to_string())?;

    Ok(GroupUpdateData {
        wrapper_event_json: result.evolution_event.as_json(),
        wrapper_event_id_hex: result.evolution_event.id.to_hex(),
        mls_group_id_hex: hex::encode(result.mls_group_id.as_slice()),
    })
}

/// Replace the admin set of a group.
///
/// [`admin_pubkeys_hex`] is the full desired admin set (not a delta). mdk-core
/// prunes any pubkeys that aren't group members and rejects an update that
/// would leave the group with zero admins. Returns the wrapper event the
/// caller must publish to relays so other members advance the epoch. Only an
/// existing admin can publish this update.
pub fn update_group_admins(
    mls_group_id_hex: String,
    admin_pubkeys_hex: Vec<String>,
) -> Result<GroupUpdateData, String> {
    let guard = MDK_INSTANCE.lock().map_err(|err| err.to_string())?;
    let runtime = guard
        .as_ref()
        .ok_or_else(|| "MDK runtime has not been initialized".to_string())?;

    let mls_group_id = group_id_from_hex(&mls_group_id_hex)?;
    let admins = admin_pubkeys_hex
        .into_iter()
        .map(|pubkey| {
            PublicKey::parse(&pubkey).map_err(|err| format!("Invalid admin pubkey: {err}"))
        })
        .collect::<Result<Vec<_>, _>>()?;

    let update = NostrGroupDataUpdate::new().admins(admins);
    let result = runtime
        .mdk
        .update_group_data(&mls_group_id, update)
        .map_err(|err| err.to_string())?;

    Ok(GroupUpdateData {
        wrapper_event_json: result.evolution_event.as_json(),
        wrapper_event_id_hex: result.evolution_event.id.to_hex(),
        mls_group_id_hex: hex::encode(result.mls_group_id.as_slice()),
    })
}

/// Demote the current account from the admin set of a group.
///
/// MIP-03 requires admins to self-demote before leaving. Returns the wrapper
/// event the caller must publish to relays so remaining members advance the
/// epoch. Fails if the account is the only active admin.
pub fn self_demote(mls_group_id_hex: String) -> Result<GroupUpdateData, String> {
    let guard = MDK_INSTANCE.lock().map_err(|err| err.to_string())?;
    let runtime = guard
        .as_ref()
        .ok_or_else(|| "MDK runtime has not been initialized".to_string())?;

    let mls_group_id = group_id_from_hex(&mls_group_id_hex)?;
    let result = runtime
        .mdk
        .self_demote(&mls_group_id)
        .map_err(|err| err.to_string())?;

    Ok(GroupUpdateData {
        wrapper_event_json: result.evolution_event.as_json(),
        wrapper_event_id_hex: result.evolution_event.id.to_hex(),
        mls_group_id_hex: hex::encode(result.mls_group_id.as_slice()),
    })
}

/// Build a SelfRemove proposal event for the current account.
///
/// The caller must publish the returned wrapper event to relays — another
/// member will commit it on the next epoch. mdk-core refuses this if the
/// account is still an admin, so callers must `self_demote` first in that
/// case. After publishing, the caller should treat local state for the
/// group as departed (no local commit will be processed).
pub fn leave_group(mls_group_id_hex: String) -> Result<GroupUpdateData, String> {
    let guard = MDK_INSTANCE.lock().map_err(|err| err.to_string())?;
    let runtime = guard
        .as_ref()
        .ok_or_else(|| "MDK runtime has not been initialized".to_string())?;

    let mls_group_id = group_id_from_hex(&mls_group_id_hex)?;
    let result = runtime
        .mdk
        .leave_group(&mls_group_id)
        .map_err(|err| err.to_string())?;

    Ok(GroupUpdateData {
        wrapper_event_json: result.evolution_event.as_json(),
        wrapper_event_id_hex: result.evolution_event.id.to_hex(),
        mls_group_id_hex: hex::encode(result.mls_group_id.as_slice()),
    })
}

pub fn create_application_message(
    mls_group_id_hex: String,
    sender_public_key_hex: String,
    kind: u32,
    content: String,
    tags_json: Option<String>,
    created_at: Option<u64>,
) -> Result<MessageEventData, String> {
    let guard = MDK_INSTANCE.lock().map_err(|err| err.to_string())?;
    let runtime = guard
        .as_ref()
        .ok_or_else(|| "MDK runtime has not been initialized".to_string())?;

    let mls_group_id = group_id_from_hex(&mls_group_id_hex)?;
    let sender_public_key = PublicKey::parse(&sender_public_key_hex)
        .map_err(|err| format!("Invalid sender pubkey: {err}"))?;
    let kind_u16 = u16::try_from(kind).map_err(|err| err.to_string())?;
    let tags = tags_json
        .as_deref()
        .map(parse_tags_json)
        .transpose()?
        .unwrap_or_default();

    let rumor = UnsignedEvent::new(
        sender_public_key,
        created_at
            .map(nostr::Timestamp::from)
            .unwrap_or_else(nostr::Timestamp::now),
        kind_u16.into(),
        tags,
        content,
    );

    let event = runtime
        .mdk
        .create_message(&mls_group_id, rumor, None)
        .map_err(|err| err.to_string())?;

    let rumor_event_id_hex = runtime
        .mdk
        .get_message(&mls_group_id, &event.id)
        .map_err(|err| err.to_string())?
        .map(|message| message.id.to_hex())
        .unwrap_or_default();

    Ok(MessageEventData {
        wrapper_event_json: event.as_json(),
        wrapper_event_id_hex: event.id.to_hex(),
        rumor_event_id_hex,
        mls_group_id_hex,
    })
}

pub fn encrypt_media(
    mls_group_id_hex: String,
    bytes: Vec<u8>,
    mime_type: String,
    filename: String,
) -> Result<EncryptedMediaData, String> {
    let guard = MDK_INSTANCE.lock().map_err(|err| err.to_string())?;
    let runtime = guard
        .as_ref()
        .ok_or_else(|| "MDK runtime has not been initialized".to_string())?;

    let mls_group_id = group_id_from_hex(&mls_group_id_hex)?;
    let group = runtime
        .mdk
        .get_group(&mls_group_id)
        .map_err(|err| err.to_string())?
        .ok_or_else(|| "MLS group not found".to_string())?;
    let manager = runtime.mdk.media_manager(mls_group_id);
    let upload = manager
        .encrypt_for_upload(&bytes, &mime_type, &filename)
        .map_err(|err| err.to_string())?;

    Ok(EncryptedMediaData {
        encrypted_data: upload.encrypted_data,
        encrypted_hash_hex: hex::encode(upload.encrypted_hash),
        original_hash_hex: hex::encode(upload.original_hash),
        mime_type: upload.mime_type,
        filename: upload.filename,
        original_size: upload.original_size,
        encrypted_size: upload.encrypted_size,
        nonce_hex: hex::encode(upload.nonce),
        scheme_version: "mip04-v2".to_string(),
        epoch: group.epoch,
    })
}

pub fn decrypt_media(
    mls_group_id_hex: String,
    encrypted_bytes: Vec<u8>,
    original_hash_hex: String,
    mime_type: String,
    filename: String,
    nonce_hex: String,
    scheme_version: String,
    url: String,
) -> Result<Vec<u8>, String> {
    let guard = MDK_INSTANCE.lock().map_err(|err| err.to_string())?;
    let runtime = guard
        .as_ref()
        .ok_or_else(|| "MDK runtime has not been initialized".to_string())?;

    let mls_group_id = group_id_from_hex(&mls_group_id_hex)?;
    let original_hash = decode_fixed_hex::<32>(&original_hash_hex, "original hash")?;
    let nonce = decode_fixed_hex::<12>(&nonce_hex, "nonce")?;
    let manager = runtime.mdk.media_manager(mls_group_id);
    let reference = MediaReference {
        url,
        original_hash,
        mime_type,
        filename,
        dimensions: None,
        scheme_version,
        nonce,
    };

    manager
        .decrypt_from_download(&encrypted_bytes, &reference)
        .map_err(|err| err.to_string())
}

pub fn process_message_event(event_json: String) -> Result<ProcessedMessageData, String> {
    let guard = MDK_INSTANCE.lock().map_err(|err| err.to_string())?;
    let runtime = guard
        .as_ref()
        .ok_or_else(|| "MDK runtime has not been initialized".to_string())?;

    let event = Event::from_json(event_json).map_err(|err| format!("Invalid event json: {err}"))?;
    let result = runtime
        .mdk
        .process_message(&event)
        .map_err(|err| err.to_string())?;

    Ok(match result {
        MessageProcessingResult::ApplicationMessage(message) => ProcessedMessageData {
            outcome: "application_message".to_string(),
            mls_group_id_hex: hex::encode(message.mls_group_id.as_slice()),
            message_event_id_hex: message.id.to_hex(),
            wrapper_event_id_hex: message.wrapper_event_id.to_hex(),
            pubkey_hex: message.pubkey.to_hex(),
            kind: u16::from(message.kind) as u32,
            content: message.content,
            created_at: message.created_at.as_secs(),
            state: message.state.to_string(),
        },
        MessageProcessingResult::Proposal(result) => ProcessedMessageData {
            outcome: "proposal".to_string(),
            mls_group_id_hex: hex::encode(result.mls_group_id.as_slice()),
            message_event_id_hex: String::new(),
            wrapper_event_id_hex: result.evolution_event.id.to_hex(),
            pubkey_hex: String::new(),
            kind: 0,
            content: String::new(),
            created_at: result.evolution_event.created_at.as_secs(),
            state: "proposal".to_string(),
        },
        MessageProcessingResult::PendingProposal { mls_group_id } => ProcessedMessageData {
            outcome: "pending_proposal".to_string(),
            mls_group_id_hex: hex::encode(mls_group_id.as_slice()),
            message_event_id_hex: String::new(),
            wrapper_event_id_hex: String::new(),
            pubkey_hex: String::new(),
            kind: 0,
            content: String::new(),
            created_at: 0,
            state: "pending".to_string(),
        },
        MessageProcessingResult::IgnoredProposal {
            mls_group_id,
            reason,
        } => ProcessedMessageData {
            outcome: "ignored_proposal".to_string(),
            mls_group_id_hex: hex::encode(mls_group_id.as_slice()),
            message_event_id_hex: String::new(),
            wrapper_event_id_hex: String::new(),
            pubkey_hex: String::new(),
            kind: 0,
            content: reason,
            created_at: 0,
            state: "ignored".to_string(),
        },
        MessageProcessingResult::ExternalJoinProposal { mls_group_id } => ProcessedMessageData {
            outcome: "external_join_proposal".to_string(),
            mls_group_id_hex: hex::encode(mls_group_id.as_slice()),
            message_event_id_hex: String::new(),
            wrapper_event_id_hex: String::new(),
            pubkey_hex: String::new(),
            kind: 0,
            content: String::new(),
            created_at: 0,
            state: "external_join".to_string(),
        },
        MessageProcessingResult::Commit { mls_group_id } => ProcessedMessageData {
            outcome: "commit".to_string(),
            mls_group_id_hex: hex::encode(mls_group_id.as_slice()),
            message_event_id_hex: String::new(),
            wrapper_event_id_hex: event.id.to_hex(),
            pubkey_hex: String::new(),
            kind: 0,
            content: String::new(),
            created_at: event.created_at.as_secs(),
            state: "commit".to_string(),
        },
        MessageProcessingResult::Unprocessable { mls_group_id } => ProcessedMessageData {
            outcome: "unprocessable".to_string(),
            mls_group_id_hex: hex::encode(mls_group_id.as_slice()),
            message_event_id_hex: String::new(),
            wrapper_event_id_hex: event.id.to_hex(),
            pubkey_hex: String::new(),
            kind: 0,
            content: String::new(),
            created_at: event.created_at.as_secs(),
            state: "unprocessable".to_string(),
        },
        MessageProcessingResult::PreviouslyFailed => ProcessedMessageData {
            outcome: "previously_failed".to_string(),
            mls_group_id_hex: String::new(),
            message_event_id_hex: String::new(),
            wrapper_event_id_hex: event.id.to_hex(),
            pubkey_hex: String::new(),
            kind: 0,
            content: String::new(),
            created_at: event.created_at.as_secs(),
            state: "failed".to_string(),
        },
    })
}

fn summarize_group(
    runtime: &MdkRuntime,
    group: mdk_storage_traits::groups::types::Group,
) -> Result<GroupSummaryData, String> {
    let member_count = runtime
        .mdk
        .get_members(&group.mls_group_id)
        .map_err(|err| err.to_string())?
        .len();

    Ok(GroupSummaryData {
        mls_group_id_hex: hex::encode(group.mls_group_id.as_slice()),
        nostr_group_id_hex: hex::encode(group.nostr_group_id),
        name: group.name,
        description: group.description,
        member_count: u32::try_from(member_count).map_err(|err| err.to_string())?,
        admin_pubkeys_hex: group
            .admin_pubkeys
            .into_iter()
            .map(|pubkey| pubkey.to_string())
            .collect(),
    })
}

fn summarize_pending_welcome(
    welcome: mdk_storage_traits::welcomes::types::Welcome,
) -> Result<PendingWelcomeData, String> {
    Ok(PendingWelcomeData {
        welcome_event_id_hex: welcome.id.to_string(),
        wrapper_event_id_hex: welcome.wrapper_event_id.to_string(),
        mls_group_id_hex: hex::encode(welcome.mls_group_id.as_slice()),
        nostr_group_id_hex: hex::encode(welcome.nostr_group_id),
        group_name: welcome.group_name,
        group_description: welcome.group_description,
        member_count: welcome.member_count,
        welcomer_pubkey_hex: welcome.welcomer.to_string(),
        relays: welcome
            .group_relays
            .into_iter()
            .map(|relay| relay.to_string())
            .collect(),
        state: welcome.state.to_string(),
    })
}

fn serialize_tags(tags: &[Tag]) -> Result<String, String> {
    let raw = tags
        .iter()
        .cloned()
        .map(|tag| tag.to_vec())
        .collect::<Vec<Vec<String>>>();
    serde_json::to_string(&raw).map_err(|err| err.to_string())
}

fn parse_tags_json(raw: &str) -> Result<Vec<Tag>, String> {
    let rows = serde_json::from_str::<Vec<Vec<String>>>(raw).map_err(|err| err.to_string())?;
    rows.into_iter()
        .map(|row| Tag::parse(row).map_err(|err| err.to_string()))
        .collect()
}

fn group_id_from_hex(raw: &str) -> Result<GroupId, String> {
    let bytes = hex::decode(raw).map_err(|err| format!("Invalid group id hex: {err}"))?;
    Ok(GroupId::from_slice(&bytes))
}

fn decode_fixed_hex<const N: usize>(raw: &str, label: &str) -> Result<[u8; N], String> {
    let bytes = hex::decode(raw).map_err(|err| format!("Invalid {label} hex: {err}"))?;
    bytes
        .try_into()
        .map_err(|_| format!("Invalid {label} length: expected {N} bytes"))
}

#[cfg(test)]
mod tests {
    use super::*;
    use mdk_core_legacy::prelude::NostrGroupConfigData as LegacyNostrGroupConfigData;
    use mdk_core_legacy::MDK as LegacyMDK;
    use mdk_memory_storage_legacy::MdkMemoryStorage as LegacyMemoryStorage;
    use nostr::{EventBuilder, Keys, Kind};
    use openmls::prelude::ProposalType;
    use std::sync::atomic::{AtomicU64, Ordering};
    use tempfile::TempDir;
    use tokio::sync::Mutex as AsyncMutex;

    static NEXT_TEST_DB: AtomicU64 = AtomicU64::new(1);
    static TEST_RUNTIME_LOCK: AsyncMutex<()> = AsyncMutex::const_new(());

    fn init_test_runtime() -> TempDir {
        let dir = tempfile::Builder::new()
            .prefix(&format!(
                "tubestr-mdk-{}-",
                NEXT_TEST_DB.fetch_add(1, Ordering::Relaxed)
            ))
            .tempdir()
            .expect("create tempdir");
        init_mdk_unencrypted(dir.path().to_string_lossy().to_string())
            .expect("initialize mdk runtime");
        dir
    }

    fn tag_rows(tags_json: &str) -> Vec<Vec<String>> {
        serde_json::from_str(tags_json).expect("tags json")
    }

    fn has_tag(tags: &[Vec<String>], name: &str, value: &str) -> bool {
        tags.iter()
            .any(|tag| tag.len() == 2 && tag[0] == name && tag[1].eq_ignore_ascii_case(value))
    }

    fn legacy_443_tags(tags_30443: &[Vec<String>]) -> Vec<Vec<String>> {
        tags_30443
            .iter()
            .filter(|tag| tag.first().map(String::as_str) != Some("d"))
            .cloned()
            .collect()
    }

    #[tokio::test]
    async fn generated_key_package_tags_advertise_self_remove_for_current_kinds() {
        let _lock = TEST_RUNTIME_LOCK.lock().await;
        let _dir = init_test_runtime();
        let keys = Keys::generate();

        let key_package = create_key_package_event(
            keys.public_key().to_hex(),
            vec!["wss://relay.example".to_string()],
        )
        .expect("create key package");
        let tags_30443 = tag_rows(&key_package.tags_json);
        let tags_443 = legacy_443_tags(&tags_30443);
        let event = EventBuilder::new(Kind::Custom(30443), key_package.content.clone())
            .tags(parse_tags_json(&key_package.tags_json).expect("parse tags"))
            .build(keys.public_key())
            .sign(&keys)
            .await
            .expect("sign key package");
        let parsed = {
            let guard = MDK_INSTANCE.lock().expect("runtime lock");
            let runtime = guard.as_ref().expect("runtime");
            runtime
                .mdk
                .parse_key_package(&event)
                .expect("parse generated key package")
        };

        assert!(
            tags_30443.iter().any(|tag| {
                tag.len() == 2
                    && tag[0] == "d"
                    && tag[1].len() == 64
                    && hex::decode(&tag[1]).is_ok()
            }),
            "kind 30443 key packages must include a 32-byte hex d tag: {tags_30443:?}"
        );
        assert!(
            !tags_443
                .iter()
                .any(|tag| tag.first().map(String::as_str) == Some("d")),
            "kind 443 key packages must use legacy tags without a d tag: {tags_443:?}"
        );
        assert!(
            has_tag(&tags_30443, "mls_proposals", "0x000a"),
            "SelfRemove proposal support must be advertised in 30443 mls_proposals: {tags_30443:?}"
        );
        assert!(
            has_tag(&tags_443, "mls_proposals", "0x000a"),
            "SelfRemove proposal support must be advertised in 443 mls_proposals: {tags_443:?}"
        );
        assert!(
            parsed
                .leaf_node()
                .capabilities()
                .proposals()
                .contains(&ProposalType::SelfRemove),
            "SelfRemove must be present in the MLS leaf capabilities"
        );
        assert!(
            has_tag(&tags_30443, "encoding", "base64"),
            "30443 key packages should explicitly advertise base64 content encoding: {tags_30443:?}"
        );
        assert!(
            has_tag(&tags_443, "encoding", "base64"),
            "443 key packages should explicitly advertise base64 content encoding: {tags_443:?}"
        );
        assert!(
            !key_package.hash_ref_hex.is_empty(),
            "hash_ref should be available for local key package cleanup"
        );
    }

    #[tokio::test]
    async fn current_tubestr_key_package_is_accepted_by_group_creation() {
        let _lock = TEST_RUNTIME_LOCK.lock().await;
        let _dir = init_test_runtime();
        let alice = Keys::generate();
        let bob = Keys::generate();

        let key_package = create_key_package_event(
            bob.public_key().to_hex(),
            vec!["wss://relay.example".to_string()],
        )
        .expect("create bob key package");
        let event = EventBuilder::new(Kind::Custom(30443), key_package.content)
            .tags(parse_tags_json(&key_package.tags_json).expect("parse tags"))
            .build(bob.public_key())
            .sign(&bob)
            .await
            .expect("sign bob key package");

        let result = create_local_group_with_welcomes(
            alice.public_key().to_hex(),
            "Alice & Bob".to_string(),
            "Current MDK interop".to_string(),
            vec!["wss://relay.example".to_string()],
            vec![event.as_json()],
        )
        .expect("current key package should create group");

        assert_eq!(result.group.member_count, 2);
        assert_eq!(result.welcome_rumor_jsons.len(), 1);
    }

    #[tokio::test]
    async fn legacy_mdk_accepts_current_key_package_when_published_as_kind_443() {
        let _lock = TEST_RUNTIME_LOCK.lock().await;
        let _dir = init_test_runtime();
        let alice = Keys::generate();
        let bob = Keys::generate();
        let relay = RelayUrl::parse("wss://relay.example").expect("relay");

        let key_package =
            create_key_package_event(bob.public_key().to_hex(), vec![relay.to_string()])
                .expect("create bob key package");
        let tags = legacy_443_tags(&tag_rows(&key_package.tags_json));
        let event = EventBuilder::new(Kind::Custom(443), key_package.content)
            .tags(
                tags.into_iter()
                    .map(Tag::parse)
                    .collect::<Result<Vec<_>, _>>()
                    .expect("parse tags"),
            )
            .build(bob.public_key())
            .sign(&bob)
            .await
            .expect("sign bob compatibility key package");

        let legacy_mdk = LegacyMDK::new(LegacyMemoryStorage::default());
        let config = LegacyNostrGroupConfigData::new(
            "Alice & Bob".to_string(),
            "Legacy Tubestr compatibility".to_string(),
            None,
            None,
            None,
            vec![relay],
            vec![alice.public_key(), bob.public_key()],
        );

        let result = legacy_mdk
            .create_group(&alice.public_key(), vec![event], config)
            .expect("legacy MDK should accept current key package as kind 443");

        assert_eq!(result.welcome_rumors.len(), 1);
    }

    #[tokio::test]
    async fn legacy_key_package_without_self_remove_is_incompatible() {
        let _lock = TEST_RUNTIME_LOCK.lock().await;
        let _dir = init_test_runtime();
        let alice = Keys::generate();
        let bob = Keys::generate();
        let relay = RelayUrl::parse("wss://relay.example").expect("relay");
        let legacy_mdk = LegacyMDK::new(LegacyMemoryStorage::default());
        let (content, tags, _hash_ref) = legacy_mdk
            .create_key_package_for_event(&bob.public_key(), [relay])
            .expect("create legacy key package");
        assert!(
            !tags
                .iter()
                .any(|tag| tag.as_slice().first().map(String::as_str) == Some("mls_proposals")),
            "legacy key package fixture should not advertise mls_proposals"
        );

        let event = EventBuilder::new(Kind::Custom(443), content)
            .tags(tags)
            .build(bob.public_key())
            .sign(&bob)
            .await
            .expect("sign legacy key package");

        let result = create_local_group_with_welcomes(
            alice.public_key().to_hex(),
            "Alice & Bob".to_string(),
            "Legacy interop regression".to_string(),
            vec!["wss://relay.example".to_string()],
            vec![event.as_json()],
        );
        let err = match result {
            Ok(_) => panic!("legacy key package should be rejected by current group creation"),
            Err(err) => err,
        };

        assert!(
            err.contains("Proposals are not acceptable") || err.contains("KeyPackage"),
            "unexpected incompatibility error: {err}"
        );
    }
}
