// Order limits
pub const MAX_ORDERS_PER_USER: u64 = 50;
pub const MAX_ACTIVE_ORDERS_PER_USER: u64 = 10;
pub const MAX_ORDER_EXPIRY: u64 = 7 * 86400; // 7 days
pub const MIN_ORDER_EXPIRY: u64 = 300; // 5 minutes
pub const DEFAULT_ORDER_EXPIRY: u64 = 86400; // 1 day

// Order amounts
pub const MIN_ORDER_AMOUNT: u256 = 1000; // Minimum order amount
pub const MAX_ORDER_AMOUNT: u256 = 1_000_000_0000; // 1000 BTC equivalent

// Order status codes
pub const ORDER_STATUS_ACTIVE: u8 = 0;
pub const ORDER_STATUS_MATCHED: u8 = 1;
pub const ORDER_STATUS_CANCELLED: u8 = 2;
pub const ORDER_STATUS_EXPIRED: u8 = 3;
pub const ORDER_STATUS_PARTIAL: u8 = 4;

// Order sides
pub const ORDER_SIDE_BUY: u8 = 0;
pub const ORDER_SIDE_SELL: u8 = 1;

// Asset types (matching token constants)
pub const ASSET_TYPE_BTC: u8 = 0;
pub const ASSET_TYPE_STRK: u8 = 1;
pub const ASSET_TYPE_ETH: u8 = 2;
pub const ASSET_TYPE_USDC: u8 = 3;
pub const ASSET_TYPE_ZKBTC: u8 = 4;

// Matching constants
pub const MAX_MATCHES_PER_BATCH: u32 = 50;
pub const MAX_SLIPPAGE_BPS: u64 = 100; // 1% max slippage
pub const MIN_MATCH_AMOUNT: u256 = 1000;

// Merkle tree constants
pub const MERKLE_TREE_HEIGHT: u32 = 32;
pub const EMPTY_HASH: felt252 = 0x0;

// Fee constants
pub const ORDERBOOK_FEE_BPS: u64 = 5; // 0.05%
pub const MAKER_REBATE_BPS: u64 = 2; // 0.02%
pub const TAKER_FEE_BPS: u64 = 7; // 0.07%

// Commitment constants
pub const COMMITMENT_NULLIFIER: felt252 = selector!("COMMITMENT_NULLIFIER");
pub const RANGE_PROOF_SIZE: u32 = 128;

// Time constants
pub const ORDER_CLEANUP_INTERVAL: u64 = 3600; // 1 hour
pub const MAX_ORDER_AGE: u64 = 30 * 86400; // 30 days