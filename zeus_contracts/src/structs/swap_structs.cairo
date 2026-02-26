use starknet::ContractAddress;
// use crate::enums::swap_enums::SwapStatus;
use crate::enums::swap_enums::SwapStatus;

#[derive(Drop, Serde, Clone, starknet::Store)]
pub struct AtomicSwap {
    pub swap_id: felt252,
    pub initiator: ContractAddress,
    pub counterparty: ContractAddress,
    pub token_a: ContractAddress,
    pub token_b: ContractAddress,
    pub amount_a: u256,
    pub amount_b: u256,
    pub hashlock: felt252,
    pub timelock: u64,
    pub status_code: u8,
    pub secret: felt252,
    pub secret_revealed: bool,
    pub created_at: u64,
    pub funded_at: u64,
    pub completed_at: u64,
}

#[derive(Drop, Serde, Clone)]
pub struct AtomicSwapResponse {
    pub swap_id: felt252,
    pub initiator: ContractAddress,
    pub counterparty: ContractAddress,
    pub token_a: ContractAddress,
    pub token_b: ContractAddress,
    pub amount_a: u256,
    pub amount_b: u256,
    pub hashlock: felt252,
    pub timelock: u64,
    pub status: SwapStatus,
    pub secret: felt252,
    pub secret_revealed: bool,
    pub created_at: u64,
    pub funded_at: u64,
    pub completed_at: u64,
}

#[derive(Drop, Serde, Clone, starknet::Store)]
pub struct PendingSwap {
    pub swap_id: felt252,
    pub hashlock: felt252,
    pub timelock: u64,
    pub amount: u256,
    pub sender: ContractAddress,
    pub recipient: ContractAddress,
    pub token_address: ContractAddress,
}

#[derive(Drop, Serde, Clone, starknet::Store)]
pub struct RelayerInfo {
    pub relayer_address: ContractAddress,
    pub fee_bps: u64,
    pub is_active: bool,
    pub total_swaps_facilitated: u64,
}

#[derive(Drop, Serde, Clone, starknet::Store)]
pub struct UserSwapCounter {
    pub initiated_count: u64,
    pub participated_count: u64,
    pub active_count: u64,
}

#[derive(Drop, Serde, Clone, starknet::Store)]
pub struct SwapFee {
    pub protocol_fee_bps: u64,
    pub relayer_fee_bps: u64,
    pub fee_collector: ContractAddress,
}