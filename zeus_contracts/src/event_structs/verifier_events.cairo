use starknet::ContractAddress;

#[derive(Drop, starknet::Event)]
pub struct ProofSubmitted {
    pub proof_id: felt252,
    pub circuit_type: felt252,
    pub prover: ContractAddress,
    pub timestamp: u64,
    pub expires_at: u64,
}

#[derive(Drop, starknet::Event)]
pub struct ProofVerified {
    pub proof_id: felt252,
    pub verifier: ContractAddress,
    pub result: bool,
    pub timestamp: u64,
}

#[derive(Drop, starknet::Event)]
pub struct BatchProofVerified {
    pub batch_id: felt252,
    pub proof_count: u32,
    pub verifier: ContractAddress,
    pub result: bool,
    pub timestamp: u64,
}

#[derive(Drop, starknet::Event)]
pub struct CircuitVerifierAdded {
    pub circuit_type: felt252,
    pub verifier_key: felt252,
    pub added_by: ContractAddress,
    pub timestamp: u64,
}

#[derive(Drop, starknet::Event)]
pub struct CircuitVerifierUpdated {
    pub circuit_type: felt252,
    pub old_verifier_key: felt252,
    pub new_verifier_key: felt252,
    pub updated_by: ContractAddress,
    pub timestamp: u64,
}

#[derive(Drop, starknet::Event)]
pub struct NullifierUsed {
    pub nullifier: felt252,
    pub proof_id: felt252,
    pub timestamp: u64,
}

#[derive(Drop, starknet::Event)]
pub struct OrderMatchValidated {
    pub match_id: felt252,
    pub buy_order_commitment: felt252,
    pub sell_order_commitment: felt252,
    pub matched_amount: u256,
    pub timestamp: u64,
}

#[derive(Drop, starknet::Event)]
pub struct RelayerWhitelisted {
    pub relayer: ContractAddress,
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
pub struct VerifierPaused {
    pub paused_by: ContractAddress,
    pub timestamp: u64,
}

#[derive(Drop, starknet::Event)]
pub struct VerifierUnpaused {
    pub unpaused_by: ContractAddress,
    pub timestamp: u64,
}