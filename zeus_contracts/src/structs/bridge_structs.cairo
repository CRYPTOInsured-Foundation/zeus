use starknet::ContractAddress;

#[derive(Drop, Serde, Clone, starknet::Store)]
pub struct AtomicBridgeSwap {
    pub swap_id: felt252,
    pub initiator: ContractAddress,
    pub counterparty: ContractAddress,
    pub bridge_type: u8,
    pub amount_btc: u256,
    pub amount_strk: u256,
    pub hashlock: felt252,
    pub timelock: u64,
    pub status: u8,
    pub secret: felt252,
    pub secret_revealed: bool,
    pub btc_txid: felt252,
    pub strk_tx_hash: felt252,
    pub created_at: u64,
    pub funded_at: u64,
    pub completed_at: u64,
    pub expires_at: u64,
    pub retry_count: u8,
}

#[derive(Drop, Serde, Clone)]
pub struct AtomicBridgeSwapResponse {
    pub swap_id: felt252,
    pub initiator: ContractAddress,
    pub counterparty: ContractAddress,
    pub bridge_type: u8,
    pub amount_btc: u256,
    pub amount_strk: u256,
    pub hashlock: felt252,
    pub timelock: u64,
    pub status: u8,
    pub secret: felt252,
    pub secret_revealed: bool,
    pub btc_txid: felt252,
    pub strk_tx_hash: felt252,
    pub created_at: u64,
    pub funded_at: u64,
    pub completed_at: u64,
    pub expires_at: u64,
    pub retry_count: u8,
}

#[derive(Drop, Serde, Clone, starknet::Store)]
pub struct BridgeProof {
    pub proof_id: felt252,
    pub swap_id: felt252,
    pub proof_type: u8,
    pub proof_data: felt252,
    pub verified_at: u64,
    pub verifier: ContractAddress,
    pub valid_until: u64,
}

#[derive(Drop, Serde, Clone, starknet::Store)]
pub struct BridgeRelayer {
    pub relayer: ContractAddress,
    pub fee_bps: u64,
    pub is_active: bool,
    pub total_swaps: u64,
    pub total_volume: u256,
    pub whitelisted: bool,
}

#[derive(Drop, Serde, Clone, starknet::Store)]
pub struct BridgeStats {
    pub total_swaps: u64,
    pub total_volume_btc: u256,
    pub total_volume_strk: u256,
    pub total_fees_collected: u256,
    pub active_swaps: u64,
    pub completed_swaps: u64,
    pub failed_swaps: u64,
    pub avg_completion_time: u64,
    pub last_swap_at: u64,
}

#[derive(Drop, Serde, Clone, starknet::Store)]
pub struct UserBridgeInfo {
    pub total_swaps: u64,
    pub active_swaps: u64,
    pub total_volume_btc: u256,
    pub total_volume_strk: u256,
    pub last_swap_at: u64,
    pub blacklisted: bool,
}

#[derive(Drop, Serde, Clone, starknet::Store)]
pub struct BridgeFee {
    pub protocol_fee_bps: u64,
    pub relayer_fee_bps: u64,
    pub min_fee: u256,
    pub max_fee: u256,
    pub fee_collector: ContractAddress,
}

#[derive(Drop, Serde, Clone, starknet::Store)]
pub struct RetryInfo {
    pub swap_id: felt252,
    pub attempts: u8,
    pub last_attempt: u64,
    pub next_attempt: u64,
    pub reason: felt252,
}