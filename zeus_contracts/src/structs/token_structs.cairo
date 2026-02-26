use starknet::ContractAddress;

#[derive(Drop, Serde, Clone, starknet::Store)]
pub struct MintLimit {
    pub daily_minted: u256,
    pub last_reset_day: u64,
    pub daily_cap: u256
}

#[derive(Drop, Serde, Clone)]
pub struct MintLimitResponse {
    pub daily_minted: u256,
    pub last_reset_day: u64,
    pub daily_cap: u256
}

#[derive(Drop, Serde, Clone, starknet::Store)]
pub struct FeeConfig {
    pub mint_fee_bps: u64,
    pub burn_fee_bps: u64,
    pub fee_collector: ContractAddress
}

#[derive(Drop, Serde, Clone)]
pub struct FeeConfigResponse {
    pub mint_fee_bps: u64,
    pub burn_fee_bps: u64,
    pub fee_collector: ContractAddress
}

#[derive(Drop, Serde, Clone, starknet::Store)]
pub struct BridgeMintRequest {
    pub bridge_address: ContractAddress,
    pub amount: u256,
    pub btc_txid: felt252,
    pub timestamp: u64,
    pub processed: bool
}

#[derive(Drop, Serde, Clone)]
pub struct BridgeMintRequestResponse {
    pub bridge_address: ContractAddress,
    pub amount: u256,
    pub btc_txid: felt252,
    pub timestamp: u64,
    pub processed: bool
}