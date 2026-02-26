use starknet::ContractAddress;

#[derive(Drop, starknet::Event)]
pub struct BridgeSwapInitiated {
    pub swap_id: felt252,
    pub initiator: ContractAddress,
    pub counterparty: ContractAddress,
    pub bridge_type: u8,
    pub amount_btc: u256,
    pub amount_strk: u256,
    pub hashlock: felt252,
    pub timelock: u64,
    pub expires_at: u64,
    pub timestamp: u64,
}

#[derive(Drop, starknet::Event)]
pub struct BridgeSwapFunded {
    pub swap_id: felt252,
    pub funder: ContractAddress,
    pub amount: u256,
    pub asset: felt252,
    pub timestamp: u64,
}

#[derive(Drop, starknet::Event)]
pub struct BridgeSwapCompleted {
    pub swap_id: felt252,
    pub completer: ContractAddress,
    pub secret: felt252,
    pub btc_txid: felt252,
    pub strk_tx_hash: felt252,
    pub timestamp: u64,
}

#[derive(Drop, starknet::Event)]
pub struct BridgeSwapRefunded {
    pub swap_id: felt252,
    pub refundee: ContractAddress,
    pub amount: u256,
    pub asset: felt252,
    pub timestamp: u64,
    pub reason: felt252,
}

#[derive(Drop, starknet::Event)]
pub struct BridgeSwapExpired {
    pub swap_id: felt252,
    pub timestamp: u64,
}

#[derive(Drop, starknet::Event)]
pub struct BridgeProofSubmitted {
    pub proof_id: felt252,
    pub swap_id: felt252,
    pub proof_type: u8,
    pub submitter: ContractAddress,
    pub timestamp: u64,
    pub valid_until: u64,
}

#[derive(Drop, starknet::Event)]
pub struct BridgeProofVerified {
    pub proof_id: felt252,
    pub swap_id: felt252,
    pub verifier: ContractAddress,
    pub result: bool,
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
pub struct BridgeRelayerWhitelisted {
    pub relayer: ContractAddress,
    pub fee_bps: u64,
    pub added_by: ContractAddress,
    pub timestamp: u64,
}

#[derive(Drop, starknet::Event)]
pub struct BridgeRelayerRemoved {
    pub relayer: ContractAddress,
    pub removed_by: ContractAddress,
    pub timestamp: u64,
}

#[derive(Drop, starknet::Event)]
pub struct BridgeFeeUpdated {
    pub protocol_fee_bps: u64,
    pub relayer_fee_bps: u64,
    pub min_fee: u256,
    pub max_fee: u256,
    pub fee_collector: ContractAddress,
    pub updated_by: ContractAddress,
    pub timestamp: u64,
}

#[derive(Drop, starknet::Event)]
pub struct BridgePaused {
    pub paused_by: ContractAddress,
    pub timestamp: u64,
    pub reason: felt252,
}

#[derive(Drop, starknet::Event)]
pub struct BridgeUnpaused {
    pub unpaused_by: ContractAddress,
    pub timestamp: u64,
}

#[derive(Drop, starknet::Event)]
pub struct BridgeRetryInitiated {
    pub swap_id: felt252,
    pub attempt: u8,
    pub max_attempts: u8,
    pub next_attempt: u64,
    pub reason: felt252,
    pub timestamp: u64,
}

#[derive(Drop, starknet::Event)]
pub struct BridgeStatsUpdated {
    pub total_swaps: u64,
    pub total_volume_btc: u256,
    pub total_volume_strk: u256,
    pub timestamp: u64,
}

#[derive(Drop, starknet::Event)]
pub struct ContractWhitelisted {
    pub contract_address: ContractAddress,
    pub contract_type: felt252,
    pub added_by: ContractAddress,
    pub timestamp: u64,
}

#[derive(Drop, starknet::Event)]
pub struct ContractRemoved {
    pub contract_address: ContractAddress,
    pub contract_type: felt252,
    pub removed_by: ContractAddress,
    pub timestamp: u64,
}