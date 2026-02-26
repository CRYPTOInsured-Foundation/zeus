use starknet::ContractAddress;
// use crate::enums::swap_enums::SwapStatus;
// use crate::enums::swap_enums::SwapStatus;


#[derive(Drop, starknet::Event)]
pub struct SwapInitiated {
    pub swap_id: felt252,
    pub initiator: ContractAddress,
    pub counterparty: ContractAddress,
    pub token_a: ContractAddress,
    pub token_b: ContractAddress,
    pub amount_a: u256,
    pub amount_b: u256,
    pub hashlock: felt252,
    pub timelock: u64,
    pub timestamp: u64,
}

#[derive(Drop, starknet::Event)]
pub struct SwapFunded {
    pub swap_id: felt252,
    pub funder: ContractAddress,
    pub amount: u256,
    pub token: ContractAddress,
    pub timestamp: u64,
}

#[derive(Drop, starknet::Event)]
pub struct SwapCompleted {
    pub swap_id: felt252,
    pub completer: ContractAddress,
    pub secret: felt252,
    pub timestamp: u64,
}

#[derive(Drop, starknet::Event)]
pub struct SwapRefunded {
    pub swap_id: felt252,
    pub refundee: ContractAddress,
    pub amount: u256,
    pub token: ContractAddress,
    pub timestamp: u64,
}

#[derive(Drop, starknet::Event)]
pub struct SwapExpired {
    pub swap_id: felt252,
    pub timestamp: u64,
}

#[derive(Drop, starknet::Event)]
pub struct SecretRevealed {
    pub swap_id: felt252,
    pub secret: felt252,
    pub revealer: ContractAddress,
    pub timestamp: u64,
}

#[derive(Drop, starknet::Event)]
pub struct RelayerWhitelisted {
    pub relayer: ContractAddress,
    pub fee_bps: u64,
    pub added_by: ContractAddress,
    pub timestamp: u64,
}

#[derive(Drop, starknet::Event)]
pub struct RelayerRemoved {
    pub relayer: ContractAddress,
    pub removed_by: ContractAddress,
    pub timestamp: u64,
}

#[derive(Drop, starknet::Event)]
pub struct FeeConfigUpdated {
    pub protocol_fee_bps: u64,
    pub relayer_fee_bps: u64,
    pub fee_collector: ContractAddress,
    pub updated_by: ContractAddress,
    pub timestamp: u64,
}

#[derive(Drop, starknet::Event)]
pub struct TokenWhitelisted {
    pub token: ContractAddress,
    pub added_by: ContractAddress,
    pub timestamp: u64,
}

#[derive(Drop, starknet::Event)]
pub struct TokenRemoved {
    pub token: ContractAddress,
    pub removed_by: ContractAddress,
    pub timestamp: u64,
}