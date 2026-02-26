// Bridge operation limits
pub const MAX_SWAP_SIZE: u256 = 1_000_000_0000; // 1000 BTC equivalent
pub const MIN_SWAP_SIZE: u256 = 100_000; // 0.001 BTC equivalent
pub const MAX_PENDING_SWAPS_PER_USER: u64 = 5;
pub const MAX_SWAP_DURATION: u64 = 7 * 86400; // 7 days
pub const MIN_SWAP_DURATION: u64 = 3600; // 1 hour
pub const DEFAULT_SWAP_DURATION: u64 = 24 * 3600; // 1 day

// Bridge status codes
pub const BRIDGE_STATUS_PENDING: u8 = 0;
pub const BRIDGE_STATUS_ACTIVE: u8 = 1;
pub const BRIDGE_STATUS_COMPLETED: u8 = 2;
pub const BRIDGE_STATUS_REFUNDED: u8 = 3;
pub const BRIDGE_STATUS_EXPIRED: u8 = 4;
pub const BRIDGE_STATUS_FAILED: u8 = 5;

// Bridge types
pub const BRIDGE_TYPE_BTC_TO_STRK: u8 = 0;
pub const BRIDGE_TYPE_STRK_TO_BTC: u8 = 1;

// Fee constants
pub const BRIDGE_PROTOCOL_FEE_BPS: u64 = 10; // 0.1%
pub const BRIDGE_RELAYER_FEE_BPS: u64 = 5; // 0.05%
pub const MAX_BRIDGE_FEE_BPS: u64 = 100; // 1% max
pub const BRIDGE_MIN_FEE: u256 = 1000; // Minimum fee in smallest unit

// Time constants
pub const PROOF_VALIDITY_WINDOW: u64 = 3 * 3600; // 3 hours
pub const BTC_CONFIRMATION_BLOCKS: u64 = 6;
pub const STRK_CONFIRMATION_BLOCKS: u64 = 12;

// Retry constants
pub const MAX_RETRY_ATTEMPTS: u8 = 3;
pub const RETRY_DELAY: u64 = 3600; // 1 hour

// Security constants
pub const REQUIRED_GUARDIAN_SIGNATURES: u8 = 3;
pub const EMERGENCY_PAUSE_DURATION: u64 = 7 * 86400; // 7 days

// Operation limits
pub const MAX_BATCH_SIZE: u32 = 50;
pub const MAX_PROOFS_PER_BATCH: u32 = 10;
pub const MAX_RETRIES_PER_SWAP: u8 = 3;

// Asset identifiers
pub const ASSET_BTC_ON_STRK: felt252 = 'ZKBTC';
pub const ASSET_STRK: felt252 = 'STRK';