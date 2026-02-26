use starknet::ContractAddress;

#[derive(Drop, Serde, Clone)]
pub struct BitcoinTransaction {
    pub txid: felt252,
    pub version: u32,
    pub vin_count: u32,
    pub vout_count: u32,
    pub locktime: u32,
    pub block_height: u64,
    pub block_time: u64,
    pub confirmations: u64,
}

#[derive(Drop, Serde, Clone, starknet::Store)]
pub struct BitcoinProof {
    pub proof_id: felt252,
    pub txid: felt252,
    pub proof_type: u8,
    pub merkle_root: felt252,
    pub merkle_proof: felt252,
    pub block_header: felt252,
    pub block_height: u64,
    pub verified_at: u64,
    pub verifier: ContractAddress,
    pub valid_until: u64,
    pub used: bool,
}

#[derive(Drop, Serde, Clone, starknet::Store)]
pub struct BitcoinUTXO {
    pub utxo_hash: felt252,
    pub txid: felt252,
    pub vout: u32,
    pub amount: u64,
    pub script_pubkey: felt252,
    pub address: felt252,
    pub owner: ContractAddress,
    pub block_height: u64,
    pub processed_at: u64,
    pub spent: bool,
}

#[derive(Drop, Serde, Clone)]
pub struct BitcoinUTXOResponse {
    pub utxo_hash: felt252,
    pub txid: felt252,
    pub vout: u32,
    pub amount: u64,
    pub script_pubkey: felt252,
    pub address: felt252,
    pub owner: ContractAddress,
    pub block_height: u64,
    pub processed_at: u64,
    pub spent: bool,
}

#[derive(Drop, Serde, Clone, starknet::Store)]
pub struct BitcoinBridgeStats {
    pub total_deposits: u64,
    pub total_withdrawals: u64,
    pub total_volume_btc: u256,
    pub total_fees_collected: u256,
    pub last_deposit_at: u64,
    pub last_withdrawal_at: u64,
}

#[derive(Drop, Serde, Clone, starknet::Store)]
pub struct BitcoinBridgeConfig {
    pub required_confirmations: u64,
    pub min_deposit_amount: u64,
    pub max_deposit_amount: u64,
    pub protocol_fee_bps: u64,
    pub fee_collector: ContractAddress,
    pub paused: bool,
}