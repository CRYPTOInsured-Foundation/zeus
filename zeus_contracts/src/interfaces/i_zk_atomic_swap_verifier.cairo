use starknet::ContractAddress;
use crate::structs::verifier_structs::{ZKProofResponse, VerifierStats};

#[starknet::interface]
pub trait IZKAtomicSwapVerifier<TContractState> {
    // Core verification functions
    fn verify_proof(
        ref self: TContractState,
        circuit_type: felt252,
        proof: Array<felt252>,
        public_inputs: Array<felt252>
    ) -> bool;
    
    fn verify_batch_proofs(
        ref self: TContractState,
        circuit_type: felt252,
        proofs: Array<Array<felt252>>,
        public_inputs_batch: Array<Array<felt252>>
    ) -> bool;
    
    // Order matching verification - with expanded struct fields
    fn verify_order_match(
        ref self: TContractState,
        proof: Array<felt252>,
        total_volume_commitment: felt252,
        fee_commitment: felt252,
        min_timestamp: u64,
        max_timestamp: u64,
        order_root: felt252,
        match_count: u32
    ) -> bool;
    
    // Swap validity verification
    fn verify_swap_validity(
        ref self: TContractState,
        proof: Array<felt252>,
        swap_id: felt252,
        commitments: Array<felt252>
    ) -> bool;
    
    // Nullifier management
    fn use_nullifier(ref self: TContractState, nullifier: felt252) -> bool;
    fn is_nullifier_used(self: @TContractState, nullifier: felt252) -> bool;
    
    // View functions
    fn get_proof(self: @TContractState, proof_id: felt252) -> ZKProofResponse;
    fn get_verification_result(self: @TContractState, proof_id: felt252) -> bool;
    fn is_circuit_supported(self: @TContractState, circuit_type: felt252) -> bool;
    fn get_verifier_key(self: @TContractState, circuit_type: felt252) -> felt252;
    
    // Admin functions
    fn add_circuit_verifier(ref self: TContractState, circuit_type: felt252, verifier_key: felt252);
    fn update_circuit_verifier(ref self: TContractState, circuit_type: felt252, new_verifier_key: felt252);
    fn deactivate_circuit(ref self: TContractState, circuit_type: felt252);
    fn whitelist_relayer(ref self: TContractState, relayer: ContractAddress);
    fn remove_relayer(ref self: TContractState, relayer: ContractAddress);
    fn pause_verifier(ref self: TContractState);
    fn unpause_verifier(ref self: TContractState);
    fn get_stats(self: @TContractState) -> VerifierStats;
    fn get_supported_circuits(self: @TContractState) -> Array<felt252>;
}





















// use starknet::ContractAddress;
// use crate::structs::verifier_structs::{ZKProofResponse, OrderMatchingPublicInputs};

// #[starknet::interface]
// pub trait IZKAtomicSwapVerifier<TContractState> {
//     // Core verification functions
//     fn verify_proof(
//         ref self: TContractState,
//         circuit_type: felt252,
//         proof: Array<felt252>,
//         public_inputs: Array<felt252>
//     ) -> bool;
    
//     fn verify_batch_proofs(
//         ref self: TContractState,
//         circuit_type: felt252,
//         proofs: Array<Array<felt252>>,
//         public_inputs_batch: Array<Array<felt252>>
//     ) -> bool;
    
//     // Order matching verification
//     fn verify_order_match(
//         ref self: TContractState,
//         proof: Array<felt252>,
//         public_inputs: OrderMatchingPublicInputs
//     ) -> bool;
    
//     // Swap validity verification
//     fn verify_swap_validity(
//         ref self: TContractState,
//         proof: Array<felt252>,
//         swap_id: felt252,
//         commitments: Array<felt252>
//     ) -> bool;
    
//     // Nullifier management
//     fn use_nullifier(ref self: TContractState, nullifier: felt252) -> bool;
//     fn is_nullifier_used(self: @TContractState, nullifier: felt252) -> bool;
    
//     // View functions
//     fn get_proof(self: @TContractState, proof_id: felt252) -> ZKProofResponse;
//     fn get_verification_result(self: @TContractState, proof_id: felt252) -> bool;
//     fn is_circuit_supported(self: @TContractState, circuit_type: felt252) -> bool;
//     fn get_verifier_key(self: @TContractState, circuit_type: felt252) -> felt252;
// }