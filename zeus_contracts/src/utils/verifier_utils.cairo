use starknet::ContractAddress;
use core::poseidon::PoseidonTrait;
use core::hash::HashStateTrait;
use crate::structs::verifier_structs::{ZKProof, ZKProofResponse};
use crate::constants::verifier_constants::{
    VERIFICATION_STATUS_PENDING, VERIFICATION_STATUS_SUCCESS, 
    VERIFICATION_STATUS_FAILED, VERIFICATION_STATUS_EXPIRED
};

// Convert ZKProof storage struct to response struct
pub fn proof_to_response(proof: ZKProof) -> ZKProofResponse {
    ZKProofResponse {
        proof_id: proof.proof_id,
        circuit_type: proof.circuit_type,
        proof_data: proof.proof_data,
        public_inputs_hash: proof.public_inputs_hash,
        verifier: proof.verifier,
        created_at: proof.created_at,
        expires_at: proof.expires_at,
        status: proof.status,
        verification_result: proof.verification_result,
    }
}

// Generate proof ID
pub fn generate_proof_id(
    circuit_type: felt252,
    prover: ContractAddress,
    timestamp: u64,
    nonce: felt252
) -> felt252 {
    PoseidonTrait::new()
        .update(circuit_type)
        .update(prover.into())
        .update(timestamp.into())
        .update(nonce)
        .finalize()
}

// Generate nullifier from proof data
pub fn generate_nullifier(proof_data: Span<felt252>) -> felt252 {
    let mut hasher = PoseidonTrait::new();
    let mut i = 0;
    while i < proof_data.len() {
        hasher = hasher.update(*proof_data[i]);
        i += 1;
    };
    hasher.finalize()
}

// Hash public inputs
pub fn hash_public_inputs(inputs: Span<felt252>) -> felt252 {
    let mut hasher = PoseidonTrait::new();
    let mut i = 0;
    while i < inputs.len() {
        hasher = hasher.update(*inputs[i]);
        i += 1;
    };
    hasher.finalize()
}

// Verify proof format
pub fn validate_proof_format(proof: Span<felt252>) -> bool {
    proof.len() > 0 && proof.len() <= 1024
}

// Verify public inputs format
pub fn validate_public_inputs(inputs: Span<felt252>) -> bool {
    inputs.len() > 0 && inputs.len() <= 64
}

// Check if proof is expired
pub fn is_proof_expired(expires_at: u64, current_time: u64) -> bool {
    current_time >= expires_at
}

// Convert status code to string for events
pub fn proof_status_to_string(status: u8) -> felt252 {
    if status == VERIFICATION_STATUS_PENDING {
        'PENDING'
    } else if status == VERIFICATION_STATUS_SUCCESS {
        'SUCCESS'
    } else if status == VERIFICATION_STATUS_FAILED {
        'FAILED'
    } else if status == VERIFICATION_STATUS_EXPIRED {
        'EXPIRED'
    } else {
        'UNKNOWN'
    }
}

// Verify order matching constraints (simplified)
pub fn verify_matching_constraints(
    buy_commitments: Span<felt252>,
    sell_commitments: Span<felt252>,
    match_count: u32,
    max_slippage: u64
) -> bool {
    // In production, this would verify actual constraints
    // For hackathon, simplified check
    match_count > 0 && match_count <= 50
}

// Simulate STARK verification (placeholder for actual ZK logic)
pub fn simulate_stark_verification(
    verifier_key: felt252,
    proof: Span<felt252>,
    public_inputs: Span<felt252>
) -> bool {
    // This is a placeholder - in production, this would call actual STARK verifier
    // For hackathon, return true for valid format
    proof.len() > 0 && public_inputs.len() > 0
}