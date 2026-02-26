use starknet::ContractAddress;

#[derive(Drop, starknet::Event)]
pub struct OrderPlaced {
    pub order_id: felt252,
    pub owner: ContractAddress,
    pub asset_type: u8,
    pub side: u8,
    pub amount_commitment: felt252,
    pub price_commitment: felt252,
    pub expiry: u64,
    pub timestamp: u64,
    pub nullifier: felt252,
}

#[derive(Drop, starknet::Event)]
pub struct OrderMatched {
    pub match_id: felt252,
    pub buy_order_id: felt252,
    pub sell_order_id: felt252,
    pub matched_amount: u256,
    pub match_price: u256,
    pub timestamp: u64,
    pub relayer: ContractAddress,
}

#[derive(Drop, starknet::Event)]
pub struct OrderCancelled {
    pub order_id: felt252,
    pub owner: ContractAddress,
    pub timestamp: u64,
    pub reason: felt252,
}

#[derive(Drop, starknet::Event)]
pub struct OrderExpired {
    pub order_id: felt252,
    pub owner: ContractAddress,
    pub timestamp: u64,
}

#[derive(Drop, starknet::Event)]
pub struct BatchMatchExecuted {
    pub batch_id: felt252,
    pub match_count: u32,
    pub total_volume: u256,
    pub proof_hash: felt252,
    pub relayer: ContractAddress,
    pub timestamp: u64,
}

#[derive(Drop, starknet::Event)]
pub struct CommitmentRevealed {
    pub commitment_hash: felt252,
    pub order_id: felt252,
    pub revealer: ContractAddress,
    pub timestamp: u64,
}

#[derive(Drop, starknet::Event)]
pub struct RangeProofVerified {
    pub proof_hash: felt252,
    pub min_value: u256,
    pub max_value: u256,
    pub verifier: ContractAddress,
    pub timestamp: u64,
}

#[derive(Drop, starknet::Event)]
pub struct MerkleRootUpdated {
    pub old_root: felt252,
    pub new_root: felt252,
    pub timestamp: u64,
    pub updated_by: ContractAddress,
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
pub struct OrderbookPaused {
    pub paused_by: ContractAddress,
    pub timestamp: u64,
}

#[derive(Drop, starknet::Event)]
pub struct OrderbookUnpaused {
    pub unpaused_by: ContractAddress,
    pub timestamp: u64,
}

#[derive(Drop, starknet::Event)]
pub struct UserBlacklisted {
    pub user: ContractAddress,
    pub blacklisted_by: ContractAddress,
    pub timestamp: u64,
}

#[derive(Drop, starknet::Event)]
pub struct UserWhitelisted {
    pub user: ContractAddress,
    pub whitelisted_by: ContractAddress,
    pub timestamp: u64,
}

#[derive(Drop, starknet::Event)]
pub struct CleanupExecuted {
    pub expired_orders_removed: u64,
    pub timestamp: u64,
}