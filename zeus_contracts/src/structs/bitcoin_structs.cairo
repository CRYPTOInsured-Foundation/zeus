use starknet::ContractAddress;
// use core::traits::Into;

#[derive(Drop, Serde, Clone, starknet::Store)]
pub struct UTXO {
    pub txid: felt252,
    pub vout: u32,
    pub amount: u64,
    pub script_pubkey: felt252,
    pub owner: ContractAddress,
    pub status: u8, // 0=unspent, 1=spent, 2=locked, 3=pending
    pub locked_until: u64,
    pub created_at: u64,
    pub spent_at: u64,
    pub confirmations: u64,
}

#[derive(Drop, Serde, Clone)]
pub struct UTXOResponse {
    pub txid: felt252,
    pub vout: u32,
    pub amount: u64,
    pub script_pubkey: felt252,
    pub owner: ContractAddress,
    pub status: u8,
    pub locked_until: u64,
    pub created_at: u64,
    pub spent_at: u64,
    pub confirmations: u64,
}

#[derive(Drop, Serde, Clone, starknet::Store)]
pub struct WithdrawalRequest {
    pub request_id: u64,
    pub user: ContractAddress,
    pub amount: u256,
    pub bitcoin_address: felt252,
    pub status: u8,
    pub created_at: u64,
    pub processed_at: u64,
    pub expiry: u64,
    pub guardian_signatures: u8,
    pub required_signatures: u8,
    pub btc_txid: felt252,
}

#[derive(Drop, Serde, Clone)]
pub struct WithdrawalRequestResponse {
    pub request_id: u64,
    pub user: ContractAddress,
    pub amount: u256,
    pub bitcoin_address: felt252,
    pub status: u8,
    pub created_at: u64,
    pub processed_at: u64,
    pub expiry: u64,
    pub guardian_signatures: u8,
    pub required_signatures: u8,
    pub btc_txid: felt252,
}

#[derive(Drop, Serde, Clone, starknet::Store)]
pub struct GuardianInfo {
    pub guardian: ContractAddress,
    pub is_active: bool,
    pub added_at: u64,
    pub added_by: ContractAddress,
    pub total_votes: u64,
}

#[derive(Drop, Serde, Clone, starknet::Store)]
pub struct VaultStats {
    pub total_btc_locked: u256,
    pub total_utxos: u64,
    pub total_withdrawals: u64,
    pub total_withdrawal_amount: u256,
    pub total_deposits: u64,
    pub total_deposit_amount: u256,
    pub active_swaps: u64,
    pub last_updated: u64,
}

#[derive(Drop, Serde, Clone, starknet::Store)]
pub struct BitcoinProof {
    pub txid: felt252,
    pub merkle_root: felt252,
    pub merkle_proof: felt252,
    pub block_height: u64,
    pub block_time: u64,
    pub verified_at: u64,
    pub verifier: ContractAddress,
}

#[derive(Drop, Serde, Clone, starknet::Store)]
pub struct SwapLock {
    pub swap_id: felt252,
    pub utxo_hash: felt252,
    pub locked_at: u64,
    pub expires_at: u64,
    pub locked_by: ContractAddress,
}