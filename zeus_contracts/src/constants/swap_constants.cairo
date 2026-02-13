// Time constants (in seconds)
pub const ONE_MINUTE: u64 = 60;
pub const ONE_HOUR: u64 = 3600;
pub const ONE_DAY: u64 = 86400;
pub const ONE_WEEK: u64 = 604800;

// Swap parameters
pub const MAX_SWAP_DURATION: u64 = 7 * ONE_DAY;      // 7 days max
pub const MIN_SWAP_DURATION: u64 = 10 * ONE_MINUTE;   // 10 minutes min
pub const DEFAULT_TIMELOCK: u64 = 24 * ONE_HOUR;      // 24 hours default

// Swap limits
pub const MIN_SWAP_AMOUNT: u256 = 1000;                // Minimum swap amount (in smallest unit)
pub const MAX_SWAP_AMOUNT: u256 = 1_000_000_0000;      // Max 1000 BTC equivalent

// Fee constants
pub const SWAP_PROTOCOL_FEE_BPS: u64 = 5;              // 0.05%
pub const SWAP_RELAYER_FEE_BPS: u64 = 5;                // 0.05%
pub const SWAP_MAX_FEE_BPS: u64 = 100;                  // 1% cap

// Security
pub const MAX_ACTIVE_SWAPS_PER_USER: u64 = 10;          // Prevent spam
pub const REFUND_BUFFER_SECONDS: u64 = 3600;            // 1 hour buffer for refunds

// Status codes (as felt252 for events)
pub const SWAP_STATUS_CREATED: felt252 = 'CREATED';
pub const SWAP_STATUS_FUNDED: felt252 = 'FUNDED';
pub const SWAP_STATUS_COMPLETED: felt252 = 'COMPLETED';
pub const SWAP_STATUS_REFUNDED: felt252 = 'REFUNDED';
pub const SWAP_STATUS_EXPIRED: felt252 = 'EXPIRED';