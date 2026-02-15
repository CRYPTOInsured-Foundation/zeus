// Proof verification constants
pub const MAX_PROOF_SIZE: u32 = 1024;
pub const MAX_PUBLIC_INPUTS: u32 = 64;
pub const MAX_SWAPS_PER_BATCH: u32 = 50;

// Circuit types
pub const CIRCUIT_ORDER_MATCHING: felt252 = 'ORDER_MATCHING';
pub const CIRCUIT_SWAP_VALIDITY: felt252 = 'SWAP_VALIDITY';
pub const CIRCUIT_RANGE_PROOF: felt252 = 'RANGE_PROOF';
pub const CIRCUIT_OWNERSHIP: felt252 = 'OWNERSHIP';

// Verification status codes
pub const VERIFICATION_STATUS_PENDING: u8 = 0;
pub const VERIFICATION_STATUS_SUCCESS: u8 = 1;
pub const VERIFICATION_STATUS_FAILED: u8 = 2;
pub const VERIFICATION_STATUS_EXPIRED: u8 = 3;

// Proof expiry (in seconds)
pub const PROOF_EXPIRY: u64 = 3600; // 1 hour
pub const BATCH_PROOF_EXPIRY: u64 = 7200; // 2 hours

// STARK verification parameters
pub const STARK_FRI_STEPS: u32 = 4;
pub const STARK_FRI_LAYERS: u32 = 3;
pub const STARK_SECURITY_BITS: u32 = 128;

// Circuit constraints
pub const MAX_ORDERS_PER_BATCH: u32 = 100;
pub const MAX_MATCHES_PER_BATCH: u32 = 50;
pub const MAX_SLIPPAGE_BPS: u64 = 100; // 1% max slippage

// Verifier types
pub const VERIFIER_TYPE_STARK: u8 = 0;
pub const VERIFIER_TYPE_SNARK: u8 = 1;

// Nullifier status
pub const NULLIFIER_UNUSED: u8 = 0;
pub const NULLIFIER_USED: u8 = 1;
pub const NULLIFIER_ALREADY_USED: felt252 = 'NULLIFIER_ALREADY_USED';