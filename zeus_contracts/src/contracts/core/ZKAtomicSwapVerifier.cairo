#[starknet::contract]
pub mod ZKAtomicSwapVerifier {
    use starknet::{
        ContractAddress,
        ClassHash,
        get_caller_address,
        get_block_timestamp,
        // get_contract_address
    };

    use starknet::storage::{
        Map,
        Vec,
        VecTrait,
        MutableVecTrait,
        StorageMapReadAccess,
        StorageMapWriteAccess,
        StoragePointerReadAccess,
        StoragePointerWriteAccess,
        StoragePathEntry
    };
    use core::num::traits::Zero;
    use core::traits::Into;
    use core::poseidon::PoseidonTrait;
    use core::hash::HashStateTrait;
    use core::array::{
        Array,
        ArrayTrait
    };
    
    // OpenZeppelin imports
    use openzeppelin::access::ownable::OwnableComponent;
    use openzeppelin::security::pausable::PausableComponent;
    use openzeppelin_access::accesscontrol::AccessControlComponent;
    use openzeppelin::introspection::src5::SRC5Component;
    use openzeppelin::upgrades::UpgradeableComponent;
    use openzeppelin::upgrades::interface::IUpgradeable;
    
    // Import local modules
    use crate::constants::verifier_constants::*;
    use crate::errors::verifier_errors::*;
    use crate::structs::verifier_structs::*;
    use crate::event_structs::verifier_events::*;
    use crate::interfaces::i_zk_atomic_swap_verifier::IZKAtomicSwapVerifier;
    use crate::utils::verifier_utils::*;
    
    // OpenZeppelin components
    component!(path: OwnableComponent, storage: ownable, event: OwnableEvent);
    component!(path: PausableComponent, storage: pausable, event: PausableEvent);
    component!(path: AccessControlComponent, storage: accesscontrol, event: AccessControlEvent);
    component!(path: SRC5Component, storage: src5, event: SRC5Event);
    component!(path: UpgradeableComponent, storage: upgradeable, event: UpgradeableEvent);
    
    // Component embeddings
    #[abi(embed_v0)]
    impl OwnableImpl = OwnableComponent::OwnableImpl<ContractState>;
    impl OwnableInternalImpl = OwnableComponent::InternalImpl<ContractState>;
    
    #[abi(embed_v0)]
    impl PausableImpl = PausableComponent::PausableImpl<ContractState>;
    impl PausableInternalImpl = PausableComponent::InternalImpl<ContractState>;
    
    #[abi(embed_v0)]
    impl AccessControlImpl = AccessControlComponent::AccessControlImpl<ContractState>;
    impl AccessControlInternalImpl = AccessControlComponent::InternalImpl<ContractState>;
    
    impl UpgradeableInternalImpl = UpgradeableComponent::InternalImpl<ContractState>;
    
    // Role constants
    const ADMIN_ROLE: felt252 = selector!("ADMIN_ROLE");
    const VERIFIER_ROLE: felt252 = selector!("VERIFIER_ROLE");
    const RELAYER_ROLE: felt252 = selector!("RELAYER_ROLE");
    const CIRCUIT_MANAGER_ROLE: felt252 = selector!("CIRCUIT_MANAGER_ROLE");
    
    #[storage]
    struct Storage {
        // OpenZeppelin components
        #[substorage(v0)]
        ownable: OwnableComponent::Storage,
        #[substorage(v0)]
        pausable: PausableComponent::Storage,
        #[substorage(v0)]
        accesscontrol: AccessControlComponent::Storage,
        #[substorage(v0)]
        src5: SRC5Component::Storage,
        #[substorage(v0)]
        upgradeable: UpgradeableComponent::Storage,
        
        // Proof storage
        proofs: Map<felt252, ZKProof>,
        proof_nullifiers: Map<felt252, ProofNullifier>,
        user_proofs: Map<ContractAddress, Vec<felt252>>,
        
        // Circuit verifiers
        circuit_verifiers: Map<felt252, CircuitVerifier>,
        supported_circuits: Vec<felt252>,
        
        // Batch verification
        batch_proofs: Map<felt252, BatchProof>,

        proof_ids_by_batch: Map<felt252, Vec<felt252>>,
        
        // Whitelisted relayers
        whitelisted_relayers: Map<ContractAddress, bool>,
        
        // Statistics
        stats: VerifierStats,
        
        // Paused state
        paused: bool,
        
        // Counters
        proof_counter: u64,
        batch_counter: u64,
    }
    
    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        #[flat]
        OwnableEvent: OwnableComponent::Event,
        #[flat]
        PausableEvent: PausableComponent::Event,
        #[flat]
        AccessControlEvent: AccessControlComponent::Event,
        #[flat]
        SRC5Event: SRC5Component::Event,
        #[flat]
        UpgradeableEvent: UpgradeableComponent::Event,
        
        // Custom events
        ProofSubmitted: ProofSubmitted,
        ProofVerified: ProofVerified,
        BatchProofVerified: BatchProofVerified,
        CircuitVerifierAdded: CircuitVerifierAdded,
        CircuitVerifierUpdated: CircuitVerifierUpdated,
        NullifierUsed: NullifierUsed,
        OrderMatchValidated: OrderMatchValidated,
        RelayerWhitelisted: RelayerWhitelisted,
        RelayerRemoved: RelayerRemoved,
        VerifierPaused: VerifierPaused,
        VerifierUnpaused: VerifierUnpaused,
    }
    
    #[constructor]
    fn constructor(
        ref self: ContractState,
        owner: ContractAddress,
        // initial_circuits: Array<(felt252, felt252)> // (circuit_type, verifier_key) pairs
    ) {
        // Initialize Ownable
        self.ownable.initializer(owner);
        
        // Initialize AccessControl
        self.accesscontrol.initializer();
        self.accesscontrol._grant_role(ADMIN_ROLE, owner);
        self.accesscontrol._grant_role(CIRCUIT_MANAGER_ROLE, owner);
        self.accesscontrol._grant_role(AccessControlComponent::DEFAULT_ADMIN_ROLE, owner);
        
        // Initialize supported circuits
        // let mut circuits_list: Vec<felt252> = VecTrait::new();
        // let mut i = 0;
        // loop {
        //     match initial_circuits.get(i) {
        //         Option::Some((circuit_type, verifier_key)) => {
        //             self.circuit_verifiers.write(circuit_type, CircuitVerifier {
        //                 circuit_type: circuit_type,
        //                 verifier_key: verifier_key,
        //                 is_active: true,
        //                 added_at: get_block_timestamp(),
        //                 added_by: owner,
        //             });
                    
        //             circuits_list.append(circuit_type);
        //             i += 1;
        //         },
        //         Option::None => { break; }
        //     }
        // };
        
        // self.supported_circuits.write(circuits_list);
        
        // Initialize stats
        self.stats.write(VerifierStats {
            total_proofs_verified: 0,
            total_batches_verified: 0,
            total_failed_verifications: 0,
            active_circuits: 0,
            last_verification: get_block_timestamp(),
        });
        
        // Initialize counters
        self.proof_counter.write(0);
        self.batch_counter.write(0);
        self.paused.write(false);
    }
    
    #[abi(embed_v0)]
    impl ZKAtomicSwapVerifierImpl of IZKAtomicSwapVerifier<ContractState> {

        fn verify_proof(
            ref self: ContractState,
            circuit_type: felt252,
            proof: Array<felt252>,
            public_inputs: Array<felt252>
        ) -> bool {
            // Check if verifier is paused
            // assert(!self.paused.read(), "Verifier is paused");
            self.pausable.assert_not_paused();
            
            // Validate inputs
            assert(validate_proof_format(proof.span()), PROOF_TOO_LARGE);
            assert(validate_public_inputs(public_inputs.span()), INVALID_PUBLIC_INPUTS);
            
            // Check if circuit is supported
            let circuit_verifier: CircuitVerifier = self.circuit_verifiers.read(circuit_type);
            assert(circuit_verifier.is_active, CIRCUIT_NOT_SUPPORTED);
            
            // Generate nullifier to prevent replay
            let nullifier = generate_nullifier(proof.span());
            assert(!self.is_nullifier_used(nullifier), PROOF_ALREADY_USED);
            
            // Generate proof ID
            let proof_id = generate_proof_id(
                circuit_type,
                get_caller_address(),
                get_block_timestamp(),
                nullifier
            );
            
            // Store proof
            let zk_proof: ZKProof = ZKProof {
                proof_id: proof_id,
                circuit_type: circuit_type,
                proof_data: hash_public_inputs(proof.span()), // Store hash, not full proof
                public_inputs_hash: hash_public_inputs(public_inputs.span()),
                verifier: get_caller_address(),
                created_at: get_block_timestamp(),
                expires_at: get_block_timestamp() + PROOF_EXPIRY,
                status: VERIFICATION_STATUS_PENDING,
                verification_result: false,
            };
            
            self.proofs.write(proof_id, zk_proof.clone());
            
            // Store in user's proofs list
            // let mut user_proofs = self.user_proofs.read(get_caller_address());
            // user_proofs.append(proof_id);
            // self.user_proofs.write(get_caller_address(), user_proofs);
            self.user_proofs.entry(get_caller_address()).push(proof_id);
            
            // Emit submission event
            self.emit(ProofSubmitted {
                proof_id: proof_id,
                circuit_type: circuit_type,
                prover: get_caller_address(),
                timestamp: get_block_timestamp(),
                expires_at: zk_proof.expires_at,
            });
            
            // Perform actual verification (simulated)
            let verification_result = self.perform_verification(
                circuit_verifier.verifier_key,
                proof,
                public_inputs
            );
            
            // Update proof status
            let mut stored_proof = self.proofs.read(proof_id);
            stored_proof.status = if verification_result {
                VERIFICATION_STATUS_SUCCESS
            } else {
                VERIFICATION_STATUS_FAILED
            };
            stored_proof.verification_result = verification_result;
            self.proofs.write(proof_id, stored_proof);
            
            // Mark nullifier as used
            self._use_nullifier(nullifier, proof_id);
            
            // Update stats
            let mut stats: VerifierStats = self.stats.read();
            if verification_result {
                stats.total_proofs_verified += 1;
            } else {
                stats.total_failed_verifications += 1;
            }
            stats.last_verification = get_block_timestamp();
            self.stats.write(stats);
            
            // Emit verification event
            self.emit(ProofVerified {
                proof_id: proof_id,
                verifier: get_caller_address(),
                result: verification_result,
                timestamp: get_block_timestamp(),
            });
            
            verification_result
        }
        
        fn verify_batch_proofs(
            ref self: ContractState,
            circuit_type: felt252,
            proofs: Array<Array<felt252>>,
            public_inputs_batch: Array<Array<felt252>>
        ) -> bool {
            // Check if verifier is paused
            // assert(!self.paused.read(), "Verifier is paused");
            self.pausable.assert_not_paused();
            
            // Validate batch size
            assert(proofs.len() <= MAX_SWAPS_PER_BATCH, BATCH_SIZE_EXCEEDED);
            assert(proofs.len() == public_inputs_batch.len(), PUBLIC_INPUTS_MISMATCH);
            
            // Check if circuit is supported
            let circuit_verifier: CircuitVerifier = self.circuit_verifiers.read(circuit_type);
            assert(circuit_verifier.is_active, CIRCUIT_NOT_SUPPORTED);
            
            // Generate batch ID
            let batch_id = PoseidonTrait::new()
                .update(circuit_type)
                .update(get_caller_address().into())
                .update(get_block_timestamp().into())
                .finalize();
            
            // Verify each proof individually (simplified batch verification)
            let mut all_valid = true;
            let mut proof_ids: Array<felt252> = array![];
            let len: u32 = proofs.len();
            
            // let mut i = 0;
            // while i < proofs.len() {
            for i in 0..len {

                let mut proof  = proofs.get(i).unwrap().unbox();
                let mut public_inputs = public_inputs_batch.get(i).unwrap().unbox();

                let proof_len = proof.len();
                let public_inputs_len = public_inputs.len();

                let mut final_proof: Array<felt252> = array![];
                let mut final_public_inputs: Array<felt252> = array![];

                for j in 0..proof_len {
                    final_proof.append(*proof.at(j));
                }

                for k in 0..public_inputs_len {
                    final_public_inputs.append(*public_inputs.at(k));
                }

                let is_valid = self.verify_proof(
                    circuit_type,
                    final_proof,
                    final_public_inputs
                );
                
                if !is_valid {
                    all_valid = false;
                }
              
        }
            
            // Store batch proof
            let batch_proof: BatchProof = BatchProof {
                batch_id: batch_id,
                // proof_ids: proof_ids.clone(),
                aggregate_proof: 0, // Would store aggregate proof hash
                verified_at: get_block_timestamp(),
                verifier: get_caller_address(),
            };
            
            self.batch_proofs.write(batch_id, batch_proof);
            // self.proof_ids_by_batch.entry(batch_id).write(proof_ids);

            let proof_ids_len: u32 = proof_ids.len();

            for j in 0..proof_ids_len {
                self.proof_ids_by_batch.entry(batch_id).push(*proof_ids.get(j).unwrap().unbox());
            }
            
            // Update batch counter
            let counter = self.batch_counter.read() + 1;
            self.batch_counter.write(counter);
            
            // Update stats
            let mut stats: VerifierStats = self.stats.read();
            stats.total_batches_verified += 1;
            stats.last_verification = get_block_timestamp();
            self.stats.write(stats);
            
            // Emit batch verification event
            self.emit(BatchProofVerified {
                batch_id: batch_id,
                proof_count: proofs.len(),
                verifier: get_caller_address(),
                result: all_valid,
                timestamp: get_block_timestamp(),
            });
            
            all_valid
        }

        // In the contract implementation, replace the verify_order_match method:

        fn verify_order_match(
            ref self: ContractState,
            proof: Array<felt252>,
            total_volume_commitment: felt252,
            fee_commitment: felt252,
            min_timestamp: u64,
            max_timestamp: u64,
            order_root: felt252,
            match_count: u32
        ) -> bool {
            // Check if verifier is paused
            // assert(!self.paused.read(), "Verifier is paused");
            self.pausable.assert_not_paused();
            
            // Validate inputs
            assert!(match_count > 0, "No matches");
            assert(match_count <= MAX_MATCHES_PER_BATCH, BATCH_SIZE_EXCEEDED);
            
            // Prepare public inputs array for verification
            let mut inputs_array: Array<felt252> = array![];
            inputs_array.append(total_volume_commitment);
            inputs_array.append(fee_commitment);
            inputs_array.append(min_timestamp.into());
            inputs_array.append(max_timestamp.into());
            inputs_array.append(order_root);
            inputs_array.append(match_count.into());
            
            // Verify using order matching circuit
            let result = self.verify_proof(
                CIRCUIT_ORDER_MATCHING,
                proof,
                inputs_array
            );
            
            if result {
                // Emit order match validated event
                self.emit(OrderMatchValidated {
                    match_id: PoseidonTrait::new()
                        .update(total_volume_commitment)
                        .update(order_root)
                        .finalize(),
                    buy_order_commitment: 0,
                    sell_order_commitment: 0,
                    matched_amount: 0,
                    timestamp: get_block_timestamp(),
                });
            }
            
            result
        }
                
        fn verify_swap_validity(
            ref self: ContractState,
            proof: Array<felt252>,
            swap_id: felt252,
            commitments: Array<felt252>
        ) -> bool {
            // Check if verifier is paused
            assert!(!self.paused.read(), "Verifier is paused");
            
            // Validate commitments
            assert!(commitments.len() == 4, "Invalid commitments count");
            
            // Prepare public inputs
            let mut inputs_array = ArrayTrait::<felt252>::new();
            inputs_array.append(swap_id);
            
            let mut i = 0;
            while i < commitments.len() {
                inputs_array.append(*commitments[i]);
                i += 1;
            };
            
            // Verify using swap validity circuit
            self.verify_proof(
                CIRCUIT_SWAP_VALIDITY,
                proof,
                inputs_array
            )
        }
        
        fn use_nullifier(ref self: ContractState, nullifier: felt252) -> bool {
            // Check permissions (only internal calls or relayers)
            if !self.accesscontrol.has_role(RELAYER_ROLE, get_caller_address()) {
                assert(self.accesscontrol.has_role(VERIFIER_ROLE, get_caller_address()), 
                       UNAUTHORIZED_VERIFIER);
            }
            
            assert(!self.is_nullifier_used(nullifier), NULLIFIER_ALREADY_USED);
            
            let nullifier_data: ProofNullifier = ProofNullifier {
                nullifier: nullifier,
                used_at: get_block_timestamp(),
                used_in_tx: 0, // Would store tx hash
            };
            
            self.proof_nullifiers.write(nullifier, nullifier_data);
            
            self.emit(NullifierUsed {
                nullifier: nullifier,
                proof_id: 0,
                timestamp: get_block_timestamp(),
            });
            
            true
        }
        
        fn is_nullifier_used(self: @ContractState, nullifier: felt252) -> bool {
            let data = self.proof_nullifiers.read(nullifier);
            !data.nullifier.is_zero()
        }
        
        fn get_proof(self: @ContractState, proof_id: felt252) -> ZKProofResponse {
            let proof = self.proofs.read(proof_id);
            assert!(!proof.proof_id.is_zero(), "Proof not found");
            proof_to_response(proof)
        }
        
        fn get_verification_result(self: @ContractState, proof_id: felt252) -> bool {
            let proof: ZKProof = self.proofs.read(proof_id);
            assert!(!proof.proof_id.is_zero(), "Proof not found");
            proof.verification_result
        }
        
        fn is_circuit_supported(self: @ContractState, circuit_type: felt252) -> bool {
            let circuit = self.circuit_verifiers.read(circuit_type);
            circuit.is_active
        }
        
        fn get_verifier_key(self: @ContractState, circuit_type: felt252) -> felt252 {
            let circuit = self.circuit_verifiers.read(circuit_type);
            assert(circuit.is_active, CIRCUIT_NOT_SUPPORTED);
            circuit.verifier_key
        }


        fn add_circuit_verifier(
            ref self: ContractState,
            circuit_type: felt252,
            verifier_key: felt252
        ) {
            // Only circuit manager can add circuits
            assert(self.accesscontrol.has_role(CIRCUIT_MANAGER_ROLE, get_caller_address()), 
                   UNAUTHORIZED_VERIFIER);
            
            // Check if circuit already exists
            let existing: CircuitVerifier = self.circuit_verifiers.read(circuit_type);
            assert!(existing.verifier_key.is_zero(), "Circuit already exists");
            
            // Add circuit
            self.circuit_verifiers.write(circuit_type, CircuitVerifier {
                circuit_type: circuit_type,
                verifier_key: verifier_key,
                is_active: true,
                added_at: get_block_timestamp(),
                added_by: get_caller_address(),
            });
            
            // Add to supported circuits list
            // let mut circuits = self.supported_circuits.read();
            // circuits.append(circuit_type);
            // self.supported_circuits.write(circuits);

            self.supported_circuits.push(circuit_type);
            
            // Update stats
            let mut stats: VerifierStats = self.stats.read();
            stats.active_circuits += 1;
            self.stats.write(stats);
            
            // Emit event
            self.emit(CircuitVerifierAdded {
                circuit_type: circuit_type,
                verifier_key: verifier_key,
                added_by: get_caller_address(),
                timestamp: get_block_timestamp(),
            });
        }
        
        fn update_circuit_verifier(
            ref self: ContractState,
            circuit_type: felt252,
            new_verifier_key: felt252
        ) {
            // Only circuit manager can update circuits
            assert(self.accesscontrol.has_role(CIRCUIT_MANAGER_ROLE, get_caller_address()), 
                   UNAUTHORIZED_VERIFIER);
            
            // Get existing circuit
            let mut circuit: CircuitVerifier = self.circuit_verifiers.read(circuit_type);
            assert(!circuit.verifier_key.is_zero(), CIRCUIT_NOT_SUPPORTED);
            
            let old_key: felt252 = circuit.verifier_key;
            circuit.verifier_key = new_verifier_key;
            self.circuit_verifiers.write(circuit_type, circuit);
            
            // Emit event
            self.emit(CircuitVerifierUpdated {
                circuit_type: circuit_type,
                old_verifier_key: old_key,
                new_verifier_key: new_verifier_key,
                updated_by: get_caller_address(),
                timestamp: get_block_timestamp(),
            });
        }
        
        fn deactivate_circuit(ref self: ContractState, circuit_type: felt252) {
            // Only circuit manager can deactivate circuits
            assert(self.accesscontrol.has_role(CIRCUIT_MANAGER_ROLE, get_caller_address()), 
                   UNAUTHORIZED_VERIFIER);
            
            // Get existing circuit
            let mut circuit = self.circuit_verifiers.read(circuit_type);
            assert(!circuit.verifier_key.is_zero(), CIRCUIT_NOT_SUPPORTED);
            
            circuit.is_active = false;
            self.circuit_verifiers.write(circuit_type, circuit);
            
            // Update stats
            let mut stats: VerifierStats = self.stats.read();
            if stats.active_circuits > 0 {
                stats.active_circuits -= 1;
            }
            self.stats.write(stats);
        }
        
        fn whitelist_relayer(ref self: ContractState, relayer: ContractAddress) {
            // Only admin can whitelist relayers
            assert(self.accesscontrol.has_role(ADMIN_ROLE, get_caller_address()), 
                   UNAUTHORIZED_VERIFIER);
            
            self.whitelisted_relayers.write(relayer, true);
            self.accesscontrol._grant_role(RELAYER_ROLE, relayer);
            
            self.emit(RelayerWhitelisted {
                relayer: relayer,
                added_by: get_caller_address(),
                timestamp: get_block_timestamp(),
            });
        }
        
        fn remove_relayer(ref self: ContractState, relayer: ContractAddress) {
            // Only admin can remove relayers
            assert(self.accesscontrol.has_role(ADMIN_ROLE, get_caller_address()), 
                   UNAUTHORIZED_VERIFIER);
            
            self.whitelisted_relayers.write(relayer, false);
            self.accesscontrol._revoke_role(RELAYER_ROLE, relayer);
            
            self.emit(RelayerRemoved {
                relayer: relayer,
                removed_by: get_caller_address(),
                timestamp: get_block_timestamp(),
            });
        }
        
        fn pause_verifier(ref self: ContractState) {
            self.ownable.assert_only_owner();
            self.paused.write(true);
            
            self.emit(VerifierPaused {
                paused_by: get_caller_address(),
                timestamp: get_block_timestamp(),
            });
        }
        
        fn unpause_verifier(ref self: ContractState) {
            self.ownable.assert_only_owner();
            self.paused.write(false);
            
            self.emit(VerifierUnpaused {
                unpaused_by: get_caller_address(),
                timestamp: get_block_timestamp(),
            });
        }
        
        fn get_stats(self: @ContractState) -> VerifierStats {
            self.stats.read()
        }
        
        fn get_supported_circuits(self: @ContractState) -> Array<felt252> {

            let mut circuits: Array<felt252> = array![];
            // let circuits = self.supported_circuits.read();
            // let mut result = ArrayTrait::new();

            let len: u64 = self.supported_circuits.len();

            for i in 0..len {
                circuits.append(self.supported_circuits.at(i).read());
            };
            
            circuits
        }
    }
    
    #[abi(embed_v0)]
    impl UpgradeableImpl of IUpgradeable<ContractState> {
        fn upgrade(ref self: ContractState, new_class_hash: ClassHash) {
            self.ownable.assert_only_owner();
            self.upgradeable.upgrade(new_class_hash);
        }
    }
    
    #[generate_trait]
    impl InternalImpl of InternalTrait {
        fn _use_nullifier(ref self: ContractState, nullifier: felt252, proof_id: felt252) {
            let nullifier_data: ProofNullifier = ProofNullifier {
                nullifier: nullifier,
                used_at: get_block_timestamp(),
                used_in_tx: proof_id,
            };
            
            self.proof_nullifiers.write(nullifier, nullifier_data);
        }
        
        fn perform_verification(
            ref self: ContractState,
            verifier_key: felt252,
            proof: Array<felt252>,
            public_inputs: Array<felt252>
        ) -> bool {
            // This is where actual STARK verification would happen
            // For hackathon, simulate verification
            // In production, would call verifier contract or native STARK verifier
            
            // Simple simulation: verify proof format and non-zero inputs
            if proof.len() == 0 || public_inputs.len() == 0 {
                return false;
            }
            
            // Simulate verification success (for demo purposes)
            // In production, this would be actual cryptographic verification
            true
        }
    }
}
