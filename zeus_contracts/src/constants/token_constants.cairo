// Token Metadata
pub const ZKBTC_NAME: felt252 = 'ZKBTC';
pub const ZKBTC_SYMBOL: felt252 = 'ZKBTC';
pub const ZKBTC_DECIMALS: u8 = 8;

// Supply Constants
pub const MAX_SUPPLY: u256 = 21_000_000_00000000; // 21 million * 10^8
pub const INITIAL_SUPPLY: u256 = 0;

// Role Constants - Using selector! for all roles (best practice)
pub const MINTER_ROLE: felt252 = selector!("MINTER_ROLE");
pub const BURNER_ROLE: felt252 = selector!("BURNER_ROLE");
pub const VAULT_ROLE: felt252 = selector!("VAULT_ROLE");
pub const GUARDIAN_ROLE: felt252 = selector!("GUARDIAN_ROLE");
pub const RELAYER_ROLE: felt252 = selector!("RELAYER_ROLE");
pub const PAUSER_ROLE: felt252 = selector!("PAUSER_ROLE");
pub const UPGRADER_ROLE: felt252 = selector!("UPGRADER_ROLE");
pub const DEFAULT_ADMIN_ROLE: felt252 = selector!("DEFAULT_ADMIN_ROLE");

// Fee Constants
pub const MINT_FEE_BPS: u64 = 10; // 0.1%
pub const BURN_FEE_BPS: u64 = 10;  // 0.1%
pub const MAX_FEE_BPS: u64 = 100;  // 1%

// Cap Constraints
pub const MINT_CAP_PER_TX: u256 = 1_000_000_0000; // 1000 BTC
pub const BURN_CAP_PER_TX: u256 = 1_000_000_0000; // 1000 BTC
pub const DAILY_MINT_CAP: u256 = 10_000_000_0000; // 10000 BTC