use starknet::ContractAddress;

#[derive(Drop, Serde, Clone, starknet::Store)]
pub struct Order {
    pub order_id: felt252,
    pub owner: ContractAddress,
    pub asset_type: u8,
    pub side: u8,
    pub amount_commitment: felt252,
    pub price_commitment: felt252,
    pub expiry: u64,
    pub created_at: u64,
    pub status: u8,
    pub matched_amount: u256,
    pub remaining_amount: u256,
    pub nullifier: felt252,
}

#[derive(Drop, Serde, Clone)]
pub struct OrderResponse {
    pub order_id: felt252,
    pub owner: ContractAddress,
    pub asset_type: u8,
    pub side: u8,
    pub amount_commitment: felt252,
    pub price_commitment: felt252,
    pub expiry: u64,
    pub created_at: u64,
    pub status: u8,
    pub matched_amount: u256,
    pub remaining_amount: u256,
    pub nullifier: felt252,
}

#[derive(Drop, Serde, Clone, starknet::Store)]
pub struct OrderCommitment {
    pub commitment_hash: felt252,
    pub owner: ContractAddress,
    pub timestamp: u64,
    pub expiry: u64,
    pub nullifier: felt252,
    pub used: bool,
}

#[derive(Drop, Serde, Clone, starknet::Store)]
pub struct Match {
    pub match_id: felt252,
    pub buy_order_id: felt252,
    pub sell_order_id: felt252,
    pub matched_amount: u256,
    pub match_price: u256,
    pub timestamp: u64,
    pub relayer: ContractAddress,
    pub proof_hash: felt252,
}

#[derive(Drop, Serde, Clone)]
pub struct MatchResponse {
    pub match_id: felt252,
    pub buy_order_id: felt252,
    pub sell_order_id: felt252,
    pub matched_amount: u256,
    pub match_price: u256,
    pub timestamp: u64,
    pub relayer: ContractAddress,
    pub proof_hash: felt252,
}

#[derive(Drop, Serde, Clone, starknet::Store)]
pub struct MerkleNode {
    pub hash: felt252,
    pub left: u32,
    pub right: u32,
    pub parent: u32,
}

#[derive(Drop, Serde, Clone, starknet::Store)]
pub struct MerkleTree {
    pub root: felt252,
    pub leaves: u32,
    pub nodes: u32,
    pub height: u32,
}

#[derive(Drop, Serde, Clone, starknet::Store)]
pub struct RangeProof {
    pub proof_data: felt252,
    pub min_value: u256,
    pub max_value: u256,
    pub expires_at: u64,
    pub verifier: ContractAddress,
}

#[derive(Drop, Serde, Clone, starknet::Store)]
pub struct RelayerInfo {
    pub relayer: ContractAddress,
    pub fee_bps: u64,
    pub is_active: bool,
    pub total_matches: u64,
    pub total_volume: u256,
    pub whitelisted: bool,
}

#[derive(Drop, Serde, Clone, starknet::Store)]
pub struct UserOrderInfo {
    pub total_orders: u64,
    pub active_orders: u64,
    pub total_volume: u256,
    pub last_order_at: u64,
    pub blacklisted: bool,
}

#[derive(Drop, Serde, Clone, starknet::Store)]
pub struct OrderbookStats {
    pub total_orders: u64,
    pub active_orders: u64,
    pub total_matches: u64,
    pub total_volume: u256,
    pub total_fees_collected: u256,
    pub last_match_at: u64,
    pub last_cleanup_at: u64,
}