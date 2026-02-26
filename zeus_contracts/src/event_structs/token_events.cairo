use starknet::ContractAddress;
// use starknet::Secp256k1Point;

#[derive(Drop, starknet::Event)]
pub struct TokensMinted {
    pub minter: ContractAddress,
    pub to: ContractAddress,
    pub amount: u256,
    pub fee: u256,
    pub btc_txid: felt252
}

#[derive(Drop, starknet::Event)]
pub struct TokensBurned {
    pub burner: ContractAddress,
    pub from: ContractAddress,
    pub amount: u256,
    pub fee: u256,
    pub btc_address: felt252
}

#[derive(Drop, starknet::Event)]
pub struct MinterAdded {
    pub account: ContractAddress,
    pub added_by: ContractAddress
}

#[derive(Drop, starknet::Event)]
pub struct MinterRemoved {
    pub account: ContractAddress,
    pub removed_by: ContractAddress
}

#[derive(Drop, starknet::Event)]
pub struct FeeUpdated {
    pub mint_fee_bps: u64,
    pub burn_fee_bps: u64,
    pub updated_by: ContractAddress
}

#[derive(Drop, starknet::Event)]
pub struct FeeCollectorUpdated {
    pub old_collector: ContractAddress,
    pub new_collector: ContractAddress,
    pub updated_by: ContractAddress
}

#[derive(Drop, starknet::Event)]
pub struct DailyMintCapUpdated {
    pub old_cap: u256,
    pub new_cap: u256,
    pub updated_by: ContractAddress
}

#[derive(Drop, starknet::Event)]
pub struct BridgeWhitelisted {
    pub bridge: ContractAddress,
    pub added_by: ContractAddress
}

#[derive(Drop, starknet::Event)]
pub struct BridgeRemoved {
    pub bridge: ContractAddress,
    pub removed_by: ContractAddress
}

#[derive(Drop, starknet::Event)]
pub struct ContractPaused {
    pub paused_by: ContractAddress
}

#[derive(Drop, starknet::Event)]
pub struct ContractUnpaused {
    pub unpaused_by: ContractAddress
}