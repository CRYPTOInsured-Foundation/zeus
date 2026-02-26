use starknet::ContractAddress;

#[derive(Drop, Serde, Clone, starknet::Store)]
pub struct ZKProof {
    pub proof_id: felt252,
    pub circuit_type: felt252,
    pub proof_data: felt252, // Hash of proof data
    pub public_inputs_hash: felt252,
    pub verifier: ContractAddress,
    pub created_at: u64,
    pub expires_at: u64,
    pub status: u8,
    pub verification_result: bool,
}

#[derive(Drop, Serde, Clone)]
pub struct ZKProofResponse {
    pub proof_id: felt252,
    pub circuit_type: felt252,
    pub proof_data: felt252,
    pub public_inputs_hash: felt252,
    pub verifier: ContractAddress,
    pub created_at: u64,
    pub expires_at: u64,
    pub status: u8,
    pub verification_result: bool,
}

#[derive(Drop, Serde, Clone, starknet::Store)]
pub struct ProofNullifier {
    pub nullifier: felt252,
    pub used_at: u64,
    pub used_in_tx: felt252,
}

#[derive(Drop, Serde, Clone, starknet::Store)]
pub struct BatchProof {
    pub batch_id: felt252,
    //captured by proof_ids_by_batch
    // pub proof_ids: Array<felt252>,
    pub aggregate_proof: felt252,
    pub verified_at: u64,
    pub verifier: ContractAddress,
}

#[derive(Drop, Serde, Clone, starknet::Store)]
pub struct CircuitVerifier {
    pub circuit_type: felt252,
    pub verifier_key: felt252,
    pub is_active: bool,
    pub added_at: u64,
    pub added_by: ContractAddress,
}

#[derive(Drop, Serde, Clone, starknet::Store)]
pub struct OrderMatchingPublicInputs {
    pub total_volume_commitment: felt252,
    pub fee_commitment: felt252,
    pub min_timestamp: u64,
    pub max_timestamp: u64,
    pub order_root: felt252,
    pub match_count: u32,
}

#[derive(Drop, Serde, Clone, starknet::Store)]
pub struct SwapValidityPublicInputs {
    pub swap_id: felt252,
    pub initiator_commitment: felt252,
    pub counterparty_commitment: felt252,
    pub amount_commitment: felt252,
    pub timelock: u64,
    pub hashlock: felt252,
}

#[derive(Drop, Serde, Clone, starknet::Store)]
pub struct VerifierStats {
    pub total_proofs_verified: u64,
    pub total_batches_verified: u64,
    pub total_failed_verifications: u64,
    pub active_circuits: u32,
    pub last_verification: u64,
}