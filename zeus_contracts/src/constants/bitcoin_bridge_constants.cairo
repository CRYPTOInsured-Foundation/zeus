pub const BTC_BRIDGE_PROTOCOL_FEE_BPS: u64 = 10; // 0.1%
pub const BTC_BRIDGE_RELAYER_FEE_BPS: u64 = 5; // 0.05%
pub const BTC_MAX_BRIDGE_FEE_BPS: u64 = 100; // 1% max

pub const BTC_MIN_SWAP_SIZE: u256 = 100_000; // 0.001 BTC in satoshis
pub const BTC_MAX_SWAP_SIZE: u256 = 1_000_000_0000; // 1000 BTC
pub const BTC_MIN_FEE: u256 = 1000; // Minimum fee in satoshis

pub const BTC_REQUIRED_CONFIRMATIONS: u64 = 6; // Bitcoin blocks
pub const BTC_PROOF_VALIDITY_WINDOW: u64 = 3 * 3600; // 3 hours

pub const BTC_TX_P2PKH: u8 = 0;
pub const BTC_TX_P2SH: u8 = 1;
pub const BTC_TX_P2WPKH: u8 = 2;
pub const BTC_TX_P2WSH: u8 = 3;
pub const BTC_TX_P2TR: u8 = 4;

pub const BTC_PROOF_TYPE_MERKLE: u8 = 0;
pub const BTC_PROOF_TYPE_BLOCK_HEADER: u8 = 1;
pub const BTC_PROOF_TYPE_TX: u8 = 2;

pub const BTC_HEADER_SIZE: u64 = 80; // Bitcoin block header size in bytes
pub const BTC_MAX_PROOF_SIZE: u32 = 1024;