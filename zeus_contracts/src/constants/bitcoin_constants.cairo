// Bitcoin network constants
pub const BTC_DECIMALS: u8 = 8;
pub const SATOSHI_PER_BTC: u256 = 100_000_000;
pub const DUST_LIMIT: u64 = 546; // Minimum UTXO amount in satoshis

// Security parameters
pub const MAX_GUARDIANS: u8 = 15;
pub const MIN_THRESHOLD: u8 = 3;
pub const DEFAULT_THRESHOLD: u8 = 5;

// Time constants (in seconds)
pub const LOCK_TIME_ONE_DAY: u64 = 86400;
pub const LOCK_TIME_ONE_WEEK: u64 = 604800;
pub const MAX_LOCK_TIME: u64 = 4 * LOCK_TIME_ONE_WEEK; // 4 weeks max
pub const MIN_LOCK_TIME: u64 = 3600; // 1 hour min

// UTXO status codes
pub const UTXO_STATUS_UNSPENT: u8 = 0;
pub const UTXO_STATUS_SPENT: u8 = 1;
pub const UTXO_STATUS_LOCKED: u8 = 2;
pub const UTXO_STATUS_PENDING: u8 = 3;

// Withdrawal request status codes
pub const WITHDRAWAL_STATUS_PENDING: u8 = 0;
pub const WITHDRAWAL_STATUS_PROCESSING: u8 = 1;
pub const WITHDRAWAL_STATUS_COMPLETED: u8 = 2;
pub const WITHDRAWAL_STATUS_FAILED: u8 = 3;
pub const WITHDRAWAL_STATUS_EXPIRED: u8 = 4;

// Operation limits
pub const MAX_UTXOS_PER_USER: u64 = 100;
pub const MAX_WITHDRAWAL_AMOUNT: u256 = 1_000_000_0000; // 1000 BTC
pub const MIN_WITHDRAWAL_AMOUNT: u256 = 100_000; // 0.001 BTC in satoshis
pub const WITHDRAWAL_EXPIRY: u64 = 7 * LOCK_TIME_ONE_DAY; // 7 days

// Proof verification
pub const REQUIRED_CONFIRMATIONS: u64 = 6; // Bitcoin blocks
pub const MAX_PROOF_AGE: u64 = 3 * 3600; // 3 hours