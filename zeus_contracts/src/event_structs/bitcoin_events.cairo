use starknet::ContractAddress;

#[derive(Drop, starknet::Event)]
pub struct UTXODeposited {
    pub utxo_hash: felt252,
    pub txid: felt252,
    pub vout: u32,
    pub amount: u64,
    pub owner: ContractAddress,
    pub timestamp: u64,
    pub zkbtc_minted: u256,
}

#[derive(Drop, starknet::Event)]
pub struct UTXOSpent {
    pub utxo_hash: felt252,
    pub txid: felt252,
    pub spent_at: u64,
    pub spent_by: ContractAddress,
}

#[derive(Drop, starknet::Event)]
pub struct UTXOLocked {
    pub utxo_hash: felt252,
    pub swap_id: felt252,
    pub locked_until: u64,
    pub locked_by: ContractAddress,
    pub timestamp: u64,
}

#[derive(Drop, starknet::Event)]
pub struct UTXOUnlocked {
    pub utxo_hash: felt252,
    pub swap_id: felt252,
    pub timestamp: u64,
}

#[derive(Drop, starknet::Event)]
pub struct WithdrawalRequested {
    pub request_id: u64,
    pub user: ContractAddress,
    pub amount: u256,
    pub bitcoin_address: felt252,
    pub expiry: u64,
    pub timestamp: u64,
}

#[derive(Drop, starknet::Event)]
pub struct WithdrawalSigned {
    pub request_id: u64,
    pub guardian: ContractAddress,
    pub signatures_count: u8,
    pub required_signatures: u8,
    pub timestamp: u64,
}

#[derive(Drop, starknet::Event)]
pub struct WithdrawalProcessed {
    pub request_id: u64,
    pub btc_txid: felt252,
    pub processed_by: ContractAddress,
    pub timestamp: u64,
}

#[derive(Drop, starknet::Event)]
pub struct WithdrawalFailed {
    pub request_id: u64,
    pub reason: felt252,
    pub timestamp: u64,
}

#[derive(Drop, starknet::Event)]
pub struct GuardianAdded {
    pub guardian: ContractAddress,
    pub added_by: ContractAddress,
    pub timestamp: u64,
}

#[derive(Drop, starknet::Event)]
pub struct GuardianRemoved {
    pub guardian: ContractAddress,
    pub removed_by: ContractAddress,
    pub timestamp: u64,
}

#[derive(Drop, starknet::Event)]
pub struct ThresholdUpdated {
    pub old_threshold: u8,
    pub new_threshold: u8,
    pub updated_by: ContractAddress,
    pub timestamp: u64,
}

#[derive(Drop, starknet::Event)]
pub struct SwapEscrowWhitelisted {
    pub swap_escrow: ContractAddress,
    pub added_by: ContractAddress,
    pub timestamp: u64,
}

#[derive(Drop, starknet::Event)]
pub struct SwapEscrowRemoved {
    pub swap_escrow: ContractAddress,
    pub removed_by: ContractAddress,
    pub timestamp: u64,
}

#[derive(Drop, starknet::Event)]
pub struct VaultPaused {
    pub paused_by: ContractAddress,
    pub timestamp: u64,
}

#[derive(Drop, starknet::Event)]
pub struct VaultUnpaused {
    pub unpaused_by: ContractAddress,
    pub timestamp: u64,
}