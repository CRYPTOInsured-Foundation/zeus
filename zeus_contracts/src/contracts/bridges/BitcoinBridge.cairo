#[starknet::contract]
pub mod BitcoinBridge {
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
    use core::poseidon::PoseidonTrait;
    use core::hash::HashStateTrait;
    
    // OpenZeppelin imports
    use openzeppelin::access::ownable::OwnableComponent;
    use openzeppelin::security::pausable::PausableComponent;
    use openzeppelin_access::accesscontrol::AccessControlComponent;
    use openzeppelin::introspection::src5::SRC5Component;
    use openzeppelin::upgrades::UpgradeableComponent;
    use openzeppelin::upgrades::interface::IUpgradeable;
    
    // Import local modules
    use crate::constants::bitcoin_bridge_constants::*;
    use crate::errors::bitcoin_bridge_errors::*;
    use crate::structs::bitcoin_bridge_structs::*;
    use crate::structs::bitcoin_structs::WithdrawalRequest;
    use crate::event_structs::bitcoin_bridge_events::*;
    use crate::interfaces::i_bitcoin_bridge::IBitcoinBridge;
    use crate::interfaces::i_zkbtc::IZKBTCDispatcher;
    use crate::interfaces::i_zkbtc::IZKBTCDispatcherTrait;
    use crate::interfaces::i_btc_vault::IBTCVaultDispatcher;
    use crate::interfaces::i_btc_vault::IBTCVaultDispatcherTrait;
    use crate::interfaces::i_zk_atomic_swap_verifier::IZKAtomicSwapVerifierDispatcher;
    use crate::utils::bitcoin_bridge_utils::*;
    
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
    const RELAYER_ROLE: felt252 = selector!("RELAYER_ROLE");
    const GUARDIAN_ROLE: felt252 = selector!("GUARDIAN_ROLE");
    const VERIFIER_ROLE: felt252 = selector!("VERIFIER_ROLE");
    
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
        
        // Contract dependencies
        btc_vault: ContractAddress,
        zk_verifier: ContractAddress,
        zkbtc_token: ContractAddress,
        
        // UTXO tracking
        utxos: Map<felt252, BitcoinUTXO>,
        user_utxos: Map<ContractAddress, Vec<felt252>>,
        processed_txs: Map<felt252, bool>,
        
        // Proofs
        proofs: Map<felt252, BitcoinProof>,
        tx_proofs: Map<felt252, Vec<felt252>>,
        
        // Withdrawal tracking
        withdrawals: Map<felt252, WithdrawalRequest>,
        user_withdrawals: Map<ContractAddress, Vec<felt252>>,
        withdrawal_signatures: Map<felt252, Vec<ContractAddress>>,
        
        // Relayers
        whitelisted_relayers: Map<ContractAddress, bool>,
        
        // Bridge configuration
        config: BitcoinBridgeConfig,
        
        // Statistics
        stats: BitcoinBridgeStats,
        
        // Counters
        deposit_counter: u64,
        proof_counter: u64,
        withdrawal_counter: u64,
        
        // Guardian threshold
        guardian_threshold: u8,
        guardians: Map<ContractAddress, bool>,
        guardian_count: u8,
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
        BitcoinDepositInitiated: BitcoinDepositInitiated,
        BitcoinDepositCompleted: BitcoinDepositCompleted,
        BitcoinWithdrawalInitiated: BitcoinWithdrawalInitiated,
        BitcoinWithdrawalSigned: BitcoinWithdrawalSigned,
        BitcoinWithdrawalCompleted: BitcoinWithdrawalCompleted,
        BitcoinProofSubmitted: BitcoinProofSubmitted,
        BitcoinProofVerified: BitcoinProofVerified,
        BitcoinRelayerWhitelisted: BitcoinRelayerWhitelisted,
        BitcoinRelayerRemoved: BitcoinRelayerRemoved,
        BitcoinBridgePaused: BitcoinBridgePaused,
        BitcoinBridgeUnpaused: BitcoinBridgeUnpaused,
    }
    
    #[constructor]
    fn constructor(
        ref self: ContractState,
        owner: ContractAddress,
        btc_vault: ContractAddress,
        zk_verifier: ContractAddress,
        zkbtc_token: ContractAddress,
        // initial_guardians: Array<ContractAddress>,
        // guardian_threshold: u8
    ) {
        // Initialize Ownable
        self.ownable.initializer(owner);
        
        // Initialize AccessControl
        self.accesscontrol.initializer();
        self.accesscontrol._grant_role(ADMIN_ROLE, owner);
        self.accesscontrol._grant_role(GUARDIAN_ROLE, owner);
        self.accesscontrol._grant_role(AccessControlComponent::DEFAULT_ADMIN_ROLE, owner);
        
        // Set contract dependencies
        self.btc_vault.write(btc_vault);
        self.zk_verifier.write(zk_verifier);
        self.zkbtc_token.write(zkbtc_token);
        
        // Initialize guardians
        // let mut guardian_count = 0;
        // let mut i = 0;
        // loop {
        //     match initial_guardians.get(i) {
        //         Option::Some(guardian) => {
        //             self.guardians.write(guardian, true);
        //             self.accesscontrol._grant_role(GUARDIAN_ROLE, guardian);
        //             guardian_count += 1;
        //             i += 1;
        //         },
        //         Option::None => { break; }
        //     }
        // };
        // self.guardian_count.write(guardian_count);
        // self.guardian_threshold.write(guardian_threshold);
        
        // Initialize config
        self.config.write(BitcoinBridgeConfig {
            required_confirmations: BTC_REQUIRED_CONFIRMATIONS,
            min_deposit_amount: BTC_MIN_SWAP_SIZE.try_into().unwrap(),
            max_deposit_amount: BTC_MAX_SWAP_SIZE.try_into().unwrap(),
            protocol_fee_bps: BTC_BRIDGE_PROTOCOL_FEE_BPS,
            fee_collector: owner,
            paused: false,
        });
        
        // Initialize stats
        self.stats.write(BitcoinBridgeStats {
            total_deposits: 0,
            total_withdrawals: 0,
            total_volume_btc: 0,
            total_fees_collected: 0,
            last_deposit_at: 0,
            last_withdrawal_at: 0,
        });
        
        // Initialize counters
        self.deposit_counter.write(0);
        self.proof_counter.write(0);
        self.withdrawal_counter.write(0);
    }
    
    #[abi(embed_v0)]
    impl BitcoinBridgeImpl of IBitcoinBridge<ContractState> {
        fn deposit_btc(
            ref self: ContractState,
            txid: felt252,
            vout: u32,
            amount: u64,
            script_pubkey: felt252,
            address: felt252,
            proof: Array<felt252>,
            block_height: u64
        ) -> felt252 {
            // Check if bridge is paused
            self.pausable.assert_not_paused();
            
            let config = self.config.read();
            
            // Validate amount
            assert(amount >= config.min_deposit_amount, BTC_UTXO_AMOUNT_TOO_LOW);
            assert(amount <= config.max_deposit_amount, BTC_UTXO_AMOUNT_TOO_HIGH);
            
            // Validate inputs
            assert(validate_btc_address(address), BTC_INVALID_ADDRESS);
            assert(validate_script(script_pubkey), BTC_INVALID_SCRIPT);
            
            // Check if transaction already processed
            let tx_key = PoseidonTrait::new()
                .update(txid)
                .update(vout.into())
                .finalize();
            assert(!self.processed_txs.read(tx_key), BTC_TX_ALREADY_PROCESSED);
            
            let caller = get_caller_address();
            let current_time = get_block_timestamp();
            
            // Generate UTXO hash
            let utxo_hash = generate_utxo_hash(txid, vout);
            
            // Verify proof
            let proof_id = self.submit_proof(
                txid,
                BTC_PROOF_TYPE_MERKLE,
                0, // merkle_root placeholder
                0, // merkle_proof placeholder
                0, // block_header placeholder
                block_height
            );
            
            let verified = self.verify_proof(proof_id);
            assert(verified, BTC_PROOF_INVALID);
            
            // Create UTXO record
            let utxo = BitcoinUTXO {
                utxo_hash: utxo_hash,
                txid: txid,
                vout: vout,
                amount: amount,
                script_pubkey: script_pubkey,
                address: address,
                owner: caller,
                block_height: block_height,
                processed_at: current_time,
                spent: false,
            };
            
            // Store UTXO
            self.utxos.write(utxo_hash, utxo.clone());
            self.user_utxos.entry(caller).push(utxo_hash);
            self.processed_txs.write(tx_key, true);
            
            // Calculate fee and mint amount
            let amount_u256: u256 = amount.into();
            let fee = calculate_btc_fee(amount_u256, config.protocol_fee_bps);
            let mint_amount = amount_u256 - fee;
            
            // Mint ZKBTC to user
            let zkbtc_dispatcher = IZKBTCDispatcher { 
                contract_address: self.zkbtc_token.read() 
            };
            zkbtc_dispatcher.bridge_mint(caller, mint_amount, txid);
            
            // Collect fee
            if fee > 0 {
                let fee_collector = config.fee_collector;
                zkbtc_dispatcher.bridge_mint(fee_collector, fee, txid);
            }
            
            // Update BTC vault
            let vault_dispatcher = IBTCVaultDispatcher { 
                contract_address: self.btc_vault.read() 
            };
            vault_dispatcher.deposit_utxo(
                txid,
                vout,
                amount,
                script_pubkey,
                0, // merkle_proof
                block_height,
                current_time
            );
            
            // Update stats
            let mut stats = self.stats.read();
            stats.total_deposits += 1;
            stats.total_volume_btc += amount_u256;
            stats.total_fees_collected += fee;
            stats.last_deposit_at = current_time;
            self.stats.write(stats);
            
            // Update counter
            let deposit_id = self.deposit_counter.read() + 1;
            self.deposit_counter.write(deposit_id);
            
            // Emit events
            self.emit(BitcoinDepositInitiated {
                deposit_id: deposit_id.into(),
                user: caller,
                txid: txid,
                vout: vout,
                amount: amount,
                block_height: block_height,
                timestamp: current_time,
            });
            
            self.emit(BitcoinDepositCompleted {
                deposit_id: deposit_id.into(),
                user: caller,
                utxo_hash: utxo_hash,
                amount: amount,
                zkbtc_minted: mint_amount,
                timestamp: current_time,
            });
            
            utxo_hash
        }
        
        fn initiate_withdrawal(
            ref self: ContractState,
            amount: u256,
            btc_address: felt252
        ) -> felt252 {
            // Check if bridge is paused
            self.pausable.assert_not_paused();
            
            // Validate amount
            let config = self.config.read();
            assert(amount >= config.min_deposit_amount.into(), BTC_UTXO_AMOUNT_TOO_LOW);
            assert(amount <= config.max_deposit_amount.into(), BTC_UTXO_AMOUNT_TOO_HIGH);
            assert(validate_btc_address(btc_address), BTC_INVALID_ADDRESS);
            
            let caller = get_caller_address();
            let current_time = get_block_timestamp();
            
            // Generate withdrawal ID
            let withdrawal_id = generate_withdrawal_id(
                caller,
                amount,
                btc_address,
                current_time
            );
            
            // Burn ZKBTC from user
            let zkbtc_dispatcher = IZKBTCDispatcher { 
                contract_address: self.zkbtc_token.read() 
            };
            zkbtc_dispatcher.native_burn(caller, amount, btc_address);
            
            // Create withdrawal request
            let request: WithdrawalRequest = WithdrawalRequest {
                request_id: withdrawal_id.try_into().unwrap(),
                user: caller,
                amount: amount,
                bitcoin_address: btc_address,
                status: 0, // PENDING
                created_at: current_time,
                processed_at: 0,
                expiry: current_time + 7 * 86400, // 7 days
                guardian_signatures: 0,
                required_signatures: self.guardian_threshold.read(),
                btc_txid: 0,
            };
            
            self.withdrawals.write(withdrawal_id, request.clone());
            self.user_withdrawals.entry(caller).push(withdrawal_id);
            
            // Update stats
            let mut stats = self.stats.read();
            stats.total_withdrawals += 1;
            self.stats.write(stats);
            
            // Update counter
            let counter = self.withdrawal_counter.read() + 1;
            self.withdrawal_counter.write(counter);
            
            // Emit event
            self.emit(BitcoinWithdrawalInitiated {
                withdrawal_id: withdrawal_id,
                user: caller,
                amount: amount,
                btc_address: btc_address,
                timestamp: current_time,
            });
            
            withdrawal_id
        }
        
        fn sign_withdrawal(
            ref self: ContractState,
            withdrawal_id: felt252
        ) -> bool {
            // Check caller is guardian
            let caller: ContractAddress = get_caller_address();
            assert(self.guardians.read(caller), BTC_UNAUTHORIZED_GUARDIAN);
            
            let mut request = self.withdrawals.read(withdrawal_id);
            assert!(request.request_id != 0, "Withdrawal not found");
            assert!(request.status == 0, "Invalid status"); // PENDING
            assert!(get_block_timestamp() < request.expiry, "Withdrawal expired");
            
            // Check if already signed
            // let mut signatures = self.withdrawal_signatures.read(withdrawal_id);
            let mut signatures: Array<ContractAddress> = array![];

            let len: u64 = self.withdrawal_signatures.entry(withdrawal_id).len();

            for i in 0..len {
                let each: ContractAddress = self.withdrawal_signatures.entry(withdrawal_id).at(i).read();

                signatures.append(each);
            };

            let mut already_signed: bool = false;
            let mut j: u32 = 0;
            while j < len.try_into().unwrap() {

                let mut desired_signature: ContractAddress = *signatures.at(j);
                if desired_signature == caller {
                    already_signed = true;
                    break;
                }
                j += 1;
            };
            assert!(!already_signed, "Already signed");
            
            // Add signature
            // signatures.push(caller);
            // self.withdrawal_signatures.write(withdrawal_id, signatures);
            self.withdrawal_signatures.entry(withdrawal_id).push(caller);
            
            // Update signature count
            request.guardian_signatures += 1;
            
            // Check if threshold reached
            if request.guardian_signatures >= request.required_signatures {
                request.status = 1; // PROCESSING
            }
            
            self.withdrawals.write(withdrawal_id, request.clone());
            
            // Emit event
            self.emit(BitcoinWithdrawalSigned {
                withdrawal_id: withdrawal_id,
                guardian: caller,
                signatures_count: request.guardian_signatures,
                required_signatures: request.required_signatures,
                timestamp: get_block_timestamp(),
            });
            
            true
        }
        
        fn execute_withdrawal(
            ref self: ContractState,
            withdrawal_id: felt252,
            btc_txid: felt252
        ) -> bool {
            // Check caller is guardian
            let caller = get_caller_address();
            assert(self.guardians.read(caller), BTC_UNAUTHORIZED_GUARDIAN);
            
            let mut request = self.withdrawals.read(withdrawal_id);
            assert!(request.request_id != 0, "Withdrawal not found");
            assert!(request.status == 1, "Invalid status"); // PROCESSING
            assert(request.guardian_signatures >= request.required_signatures, 
                   BTC_INSUFFICIENT_SIGNATURES);
            
            // Update request
            request.status = 2; // COMPLETED
            request.processed_at = get_block_timestamp();
            request.btc_txid = btc_txid;
            self.withdrawals.write(withdrawal_id, request.clone());
            
            // Update BTC vault (mark UTXO as spent)
            // This would need actual UTXO hash in production
            let _vault_dispatcher: IBTCVaultDispatcher = IBTCVaultDispatcher { 
                contract_address: self.btc_vault.read() 
            };
            
            // Emit event
            self.emit(BitcoinWithdrawalCompleted {
                withdrawal_id: withdrawal_id,
                btc_txid: btc_txid,
                amount: request.amount,
                timestamp: get_block_timestamp(),
            });
            
            true
        }
        
        fn submit_proof(
            ref self: ContractState,
            txid: felt252,
            proof_type: u8,
            merkle_root: felt252,
            merkle_proof: felt252,
            block_header: felt252,
            block_height: u64
        ) -> felt252 {
            let caller = get_caller_address();
            let current_time = get_block_timestamp();
            
            let proof_id = generate_proof_id(
                txid,
                proof_type,
                caller,
                current_time
            );
            
            let proof = BitcoinProof {
                proof_id: proof_id,
                txid: txid,
                proof_type: proof_type,
                merkle_root: merkle_root,
                merkle_proof: merkle_proof,
                block_header: block_header,
                block_height: block_height,
                verified_at: 0,
                verifier: caller,
                valid_until: current_time + BTC_PROOF_VALIDITY_WINDOW,
                used: false,
            };
            
            self.proofs.write(proof_id, proof.clone());
            self.tx_proofs.entry(txid).push(proof_id);
            
            // Update counter
            let counter = self.proof_counter.read() + 1;
            self.proof_counter.write(counter);
            
            self.emit(BitcoinProofSubmitted {
                proof_id: proof_id,
                txid: txid,
                proof_type: proof_type,
                block_height: block_height,
                submitter: caller,
                timestamp: current_time,
            });
            
            proof_id
        }
        
        fn verify_proof(
            ref self: ContractState,
            proof_id: felt252
        ) -> bool {
            // Check caller has verifier role
            assert!(self.accesscontrol.has_role(VERIFIER_ROLE, get_caller_address()), 
                   "Not authorized");
            
            let mut proof = self.proofs.read(proof_id);
            assert!(!proof.proof_id.is_zero(), "Proof not found");
            assert(!proof.used, BTC_PROOF_ALREADY_USED);
            assert(get_block_timestamp() < proof.valid_until, BTC_PROOF_TOO_OLD);
            
            let _config: BitcoinBridgeConfig = self.config.read();
            let verified = if proof.proof_type == BTC_PROOF_TYPE_MERKLE {
                verify_merkle_proof(
                    proof.txid,
                    proof.merkle_root,
                    proof.merkle_proof,
                    0
                )
            } else if proof.proof_type == BTC_PROOF_TYPE_BLOCK_HEADER {
                verify_block_header(proof.block_header, proof.block_height)
            } else {
                false
            };
            
            if verified {
                proof.verified_at = get_block_timestamp();
                proof.used = true;
                self.proofs.write(proof_id, proof.clone());
            }
            
            // Verify with ZK verifier contract
            let _verifier_dispatcher: IZKAtomicSwapVerifierDispatcher = IZKAtomicSwapVerifierDispatcher { 
                contract_address: self.zk_verifier.read() 
            };
            
            self.emit(BitcoinProofVerified {
                proof_id: proof_id,
                txid: proof.txid,
                verifier: get_caller_address(),
                valid: verified,
                timestamp: get_block_timestamp(),
            });
            
            verified
        }
        
        // View functions
        fn get_utxo(self: @ContractState, utxo_hash: felt252) -> BitcoinUTXOResponse {
            let utxo = self.utxos.read(utxo_hash);
            assert(!utxo.utxo_hash.is_zero(), BTC_UTXO_NOT_FOUND);
            utxo_to_response(utxo)
        }
        
        fn get_user_utxos(self: @ContractState, user: ContractAddress, offset: u64, limit: u64) -> Array<BitcoinUTXOResponse> {
            let mut user_utxos: Array<felt252> = array![];
            let len: u64 = self.user_utxos.entry(user).len();
            
            for i in 0..len {
                let each = self.user_utxos.entry(user).at(i).read();
                user_utxos.append(each);
            }
            
            let mut result: Array<BitcoinUTXOResponse> = array![];
            let start = offset;
            let end = if offset + limit > len { len } else { offset + limit };
            
            let mut j: u32 = start.try_into().unwrap();
            while j < end.try_into().unwrap() {
                let utxo_hash = *user_utxos.at(j);
                let utxo = self.utxos.read(utxo_hash);
                result.append(utxo_to_response(utxo));
                j += 1;
            };
            
            result
        }
        
        fn get_proof(self: @ContractState, proof_id: felt252) -> BitcoinProof {
            let proof = self.proofs.read(proof_id);
            assert!(!proof.proof_id.is_zero(), "Proof not found");
            proof
        }
        
        fn get_bridge_stats(self: @ContractState) -> BitcoinBridgeStats {
            self.stats.read()
        }
        
        fn is_tx_processed(self: @ContractState, txid: felt252, vout: u32) -> bool {
            let tx_key = PoseidonTrait::new()
                .update(txid)
                .update(vout.into())
                .finalize();
            self.processed_txs.read(tx_key)
        }
        
        // Admin functions
        fn whitelist_relayer(ref self: ContractState, relayer: ContractAddress) {
            assert!(self.accesscontrol.has_role(ADMIN_ROLE, get_caller_address()), 
                   "Caller is not Admin");
            
            self.whitelisted_relayers.write(relayer, true);
            self.accesscontrol._grant_role(RELAYER_ROLE, relayer);
            
            self.emit(BitcoinRelayerWhitelisted {
                relayer: relayer,
                added_by: get_caller_address(),
                timestamp: get_block_timestamp(),
            });
        }
        
        fn remove_relayer(ref self: ContractState, relayer: ContractAddress) {
            assert!(self.accesscontrol.has_role(ADMIN_ROLE, get_caller_address()), 
                   "Caller is not Admin");
            
            self.whitelisted_relayers.write(relayer, false);
            self.accesscontrol._revoke_role(RELAYER_ROLE, relayer);
            
            self.emit(BitcoinRelayerRemoved {
                relayer: relayer,
                removed_by: get_caller_address(),
                timestamp: get_block_timestamp(),
            });
        }
        
        fn set_config(
            ref self: ContractState,
            required_confirmations: u64,
            min_deposit_amount: u64,
            max_deposit_amount: u64,
            protocol_fee_bps: u64,
            fee_collector: ContractAddress
        ) {
            self.ownable.assert_only_owner();
            
            assert!(protocol_fee_bps <= BTC_MAX_BRIDGE_FEE_BPS, "Fee too high");
            assert!(min_deposit_amount <= max_deposit_amount, "Invalid range");
            assert!(!fee_collector.is_zero(), "Invalid fee collector");
            
            self.config.write(BitcoinBridgeConfig {
                required_confirmations: required_confirmations,
                min_deposit_amount: min_deposit_amount,
                max_deposit_amount: max_deposit_amount,
                protocol_fee_bps: protocol_fee_bps,
                fee_collector: fee_collector,
                paused: self.config.read().paused,
            });
        }
        
        fn pause_bridge(ref self: ContractState, reason: felt252) {
            self.ownable.assert_only_owner();
            self.pausable.pause();
            
            self.emit(BitcoinBridgePaused {
                paused_by: get_caller_address(),
                reason: reason,
                timestamp: get_block_timestamp(),
            });
        }
        
        fn unpause_bridge(ref self: ContractState) {
            self.ownable.assert_only_owner();
            self.pausable.unpause();
            
            self.emit(BitcoinBridgeUnpaused {
                unpaused_by: get_caller_address(),
                timestamp: get_block_timestamp(),
            });
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
        fn get_withdrawal_by_id(self: @ContractState, withdrawal_id: felt252) -> WithdrawalRequest {
            let withdrawal = self.withdrawals.read(withdrawal_id);
            assert!(withdrawal.request_id != 0, "Withdrawal not found");
            withdrawal
        }
    }
}