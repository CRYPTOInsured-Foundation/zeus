use starknet::ContractAddress;

#[derive(Drop, starknet::Event)]
pub struct BitcoinDepositInitiated {
    pub deposit_id: felt252,
    pub user: ContractAddress,
    pub txid: felt252,
    pub vout: u32,
    pub amount: u64,
    pub block_height: u64,
    pub timestamp: u64,
}

#[derive(Drop, starknet::Event)]
pub struct BitcoinDepositCompleted {
    pub deposit_id: felt252,
    pub user: ContractAddress,
    pub utxo_hash: felt252,
    pub amount: u64,
    pub zkbtc_minted: u256,
    pub timestamp: u64,
}

#[derive(Drop, starknet::Event)]
pub struct BitcoinWithdrawalInitiated {
    pub withdrawal_id: felt252,
    pub user: ContractAddress,
    pub amount: u256,
    pub btc_address: felt252,
    pub timestamp: u64,
}

#[derive(Drop, starknet::Event)]
pub struct BitcoinWithdrawalSigned {
    pub withdrawal_id: felt252,
    pub guardian: ContractAddress,
    pub signatures_count: u8,
    pub required_signatures: u8,
    pub timestamp: u64,
}

#[derive(Drop, starknet::Event)]
pub struct BitcoinWithdrawalCompleted {
    pub withdrawal_id: felt252,
    pub btc_txid: felt252,
    pub amount: u256,
    pub timestamp: u64,
}

#[derive(Drop, starknet::Event)]
pub struct BitcoinProofSubmitted {
    pub proof_id: felt252,
    pub txid: felt252,
    pub proof_type: u8,
    pub block_height: u64,
    pub submitter: ContractAddress,
    pub timestamp: u64,
}

#[derive(Drop, starknet::Event)]
pub struct BitcoinProofVerified {
    pub proof_id: felt252,
    pub txid: felt252,
    pub verifier: ContractAddress,
    pub valid: bool,
    pub timestamp: u64,
}

#[derive(Drop, starknet::Event)]
pub struct BitcoinRelayerWhitelisted {
    pub relayer: ContractAddress,
    pub added_by: ContractAddress,
    pub timestamp: u64,
}

#[derive(Drop, starknet::Event)]
pub struct BitcoinRelayerRemoved {
    pub relayer: ContractAddress,
    pub removed_by: ContractAddress,
    pub timestamp: u64,
}

#[derive(Drop, starknet::Event)]
pub struct BitcoinBridgePaused {
    pub paused_by: ContractAddress,
    pub reason: felt252,
    pub timestamp: u64,
}

#[derive(Drop, starknet::Event)]
pub struct BitcoinBridgeUnpaused {
    pub unpaused_by: ContractAddress,
    pub timestamp: u64,
}