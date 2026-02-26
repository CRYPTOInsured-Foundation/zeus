#[starknet::contract]
pub mod StarknetAtomicBridge {
    use starknet::{
        ContractAddress,
        ClassHash,
        get_caller_address,
        get_block_timestamp,
        get_contract_address,
        // get_tx_info
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
    use openzeppelin::token::erc20::interface::{IERC20Dispatcher, IERC20DispatcherTrait};
    
    // Import local modules
    use crate::constants::bridge_constants::*;
    use crate::errors::bridge_errors::*;
    use crate::structs::bridge_structs::*;
    use crate::event_structs::bridge_events::*;
    use crate::interfaces::i_starknet_atomic_bridge::IStarknetAtomicBridge;
    use crate::interfaces::i_zkbtc::IZKBTCDispatcher;
    use crate::interfaces::i_zkbtc::IZKBTCDispatcherTrait;
   // use crate::interfaces::i_swap_escrow::ISwapEscrowDispatcher;
    //use crate::interfaces::i_swap_escrow::ISwapEscrowDispatcherTrait;
    use crate::interfaces::i_btc_vault::IBTCVaultDispatcher;
    use crate::interfaces::i_btc_vault::IBTCVaultDispatcherTrait;
    use crate::interfaces::i_zk_atomic_swap_verifier::IZKAtomicSwapVerifierDispatcher;
   // use crate::interfaces::i_zk_atomic_swap_verifier::IZKAtomicSwapVerifierDispatcherTrait;
    use crate::utils::bridge_utils::*;
    
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
        swap_escrow: ContractAddress,
        zk_verifier: ContractAddress,
        zkbtc_token: ContractAddress,
        strk_address: ContractAddress,
        
        // Bridge swaps
        swaps: Map<felt252, AtomicBridgeSwap>,
        user_swaps: Map<ContractAddress, Vec<felt252>>,
        pending_swaps: Vec<felt252>,
        hashlock_to_swap: Map<felt252, felt252>,
        
        // Proofs
        proofs: Map<felt252, BridgeProof>,
        swap_proofs: Map<felt252, Vec<felt252>>,
        
        // Relayers
        relayers: Map<ContractAddress, BridgeRelayer>,
        whitelisted_relayers: Map<ContractAddress, bool>,
        
        // Retry tracking
        retry_info: Map<felt252, RetryInfo>,
        
        // User info
        user_info: Map<ContractAddress, UserBridgeInfo>,
        blacklisted_users: Map<ContractAddress, bool>,
        
        // Bridge configuration
        fee_config: BridgeFee,
        required_confirmations: Map<u8, u64>,
        
        // Statistics
        stats: BridgeStats,
        
        // Counters
        swap_counter: u64,
        proof_counter: u64,
        
        // Paused state
        // paused: bool,
        // pause_reason: felt252,
        // paused_at: u64,
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
        BridgeSwapInitiated: BridgeSwapInitiated,
        BridgeSwapFunded: BridgeSwapFunded,
        BridgeSwapCompleted: BridgeSwapCompleted,
        BridgeSwapRefunded: BridgeSwapRefunded,
        BridgeSwapExpired: BridgeSwapExpired,
        BridgeProofSubmitted: BridgeProofSubmitted,
        BridgeProofVerified: BridgeProofVerified,
        SecretRevealed: SecretRevealed,
        BridgeRelayerWhitelisted: BridgeRelayerWhitelisted,
        BridgeRelayerRemoved: BridgeRelayerRemoved,
        BridgeFeeUpdated: BridgeFeeUpdated,
        BridgePaused: BridgePaused,
        BridgeUnpaused: BridgeUnpaused,
        BridgeRetryInitiated: BridgeRetryInitiated,
        BridgeStatsUpdated: BridgeStatsUpdated,
        ContractWhitelisted: ContractWhitelisted,
        ContractRemoved: ContractRemoved,
    }
    
    #[constructor]
    fn constructor(
        ref self: ContractState,
        owner: ContractAddress,
        btc_vault: ContractAddress,
        swap_escrow: ContractAddress,
        zk_verifier: ContractAddress,
        zkbtc_token: ContractAddress,
        strk_address: ContractAddress
        // initial_relayers: Array<ContractAddress>
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
        self.swap_escrow.write(swap_escrow);
        self.zk_verifier.write(zk_verifier);
        self.zkbtc_token.write(zkbtc_token);
        self.strk_address.write(strk_address);
        
        // Initialize relayers
        // let mut i = 0;
        // loop {
        //     match initial_relayers.get(i) {
        //         Option::Some(relayer) => {
        //             self.relayers.write(relayer, BridgeRelayer {
        //                 relayer: relayer,
        //                 fee_bps: BRIDGE_RELAYER_FEE_BPS,
        //                 is_active: true,
        //                 total_swaps: 0,
        //                 total_volume: 0,
        //                 whitelisted: true,
        //             });
                    
        //             self.whitelisted_relayers.write(relayer, true);
        //             self.accesscontrol._grant_role(RELAYER_ROLE, relayer);
        //             i += 1;
        //         },
        //         Option::None => { break; }
        //     }
        // };
        
        // Initialize fee config
        self.fee_config.write(BridgeFee {
            protocol_fee_bps: BRIDGE_PROTOCOL_FEE_BPS,
            relayer_fee_bps: BRIDGE_RELAYER_FEE_BPS,
            min_fee: BRIDGE_MIN_FEE,
            max_fee: MAX_BRIDGE_FEE_BPS.into(),
            fee_collector: owner,
        });
        
        // Set required confirmations
        self.required_confirmations.write(BRIDGE_TYPE_BTC_TO_STRK, BTC_CONFIRMATION_BLOCKS);
        self.required_confirmations.write(BRIDGE_TYPE_STRK_TO_BTC, STRK_CONFIRMATION_BLOCKS);
        
        // Initialize stats
        self.stats.write(BridgeStats {
            total_swaps: 0,
            total_volume_btc: 0,
            total_volume_strk: 0,
            total_fees_collected: 0,
            active_swaps: 0,
            completed_swaps: 0,
            failed_swaps: 0,
            avg_completion_time: 0,
            last_swap_at: 0,
        });
        
        // Initialize counters
        self.swap_counter.write(0);
        self.proof_counter.write(0);
        // self.paused.write(false);
        // self.pause_reason.write(0);
        // self.paused_at.write(0);
    }
    
    #[abi(embed_v0)]
    impl StarknetAtomicBridgeImpl of IStarknetAtomicBridge<ContractState> {
        fn initiate_swap(
            ref self: ContractState,
            counterparty: ContractAddress,
            bridge_type: u8,
            amount_btc: u256,
            amount_strk: u256,
            hashlock: felt252,
            timelock: u64
        ) -> felt252 {
            // Check if bridge is paused
            // assert(!self.paused.read(), BRIDGE_PAUSED);
            self.pausable.assert_not_paused();
            
            // Validate inputs
            assert(bridge_type == BRIDGE_TYPE_BTC_TO_STRK || bridge_type == BRIDGE_TYPE_STRK_TO_BTC, 
                   BRIDGE_TYPE_INVALID);
            assert(validate_amount(amount_btc, MIN_SWAP_SIZE, MAX_SWAP_SIZE), AMOUNT_TOO_LOW);
            assert(validate_amount(amount_strk, MIN_SWAP_SIZE, MAX_SWAP_SIZE), AMOUNT_TOO_LOW);
            assert(validate_hashlock(hashlock), INVALID_HASHLOCK);
            assert(timelock >= MIN_SWAP_DURATION && timelock <= MAX_SWAP_DURATION, 
                   TIMELOCK_TOO_SHORT);
            
            let caller = get_caller_address();
            let current_time = get_block_timestamp();
            let expires_at = current_time + timelock;
            
            // Check user not blacklisted
            assert(!self.blacklisted_users.read(caller), USER_BLACKLISTED);
            
            // Check user limits
            let mut user_info = self.user_info.read(caller);
            assert(user_info.active_swaps < MAX_PENDING_SWAPS_PER_USER, 
                   MAX_PENDING_SWAPS_EXCEEDED);
            
            // Generate swap ID
            let swap_id = generate_swap_id(
                caller,
                counterparty,
                bridge_type,
                hashlock,
                current_time
            );
            
            // Ensure swap doesn't already exist
            let existing: AtomicBridgeSwap = self.swaps.read(swap_id);
            assert(existing.swap_id.is_zero(), SWAP_ALREADY_EXISTS);
            
            // Create swap
            let swap = AtomicBridgeSwap {
                swap_id: swap_id,
                initiator: caller,
                counterparty: counterparty,
                bridge_type: bridge_type,
                amount_btc: amount_btc,
                amount_strk: amount_strk,
                hashlock: hashlock,
                timelock: timelock,
                status: BRIDGE_STATUS_PENDING,
                secret: 0,
                secret_revealed: false,
                btc_txid: 0,
                strk_tx_hash: 0,
                created_at: current_time,
                funded_at: 0,
                completed_at: 0,
                expires_at: expires_at,
                retry_count: 0,
            };
            
            // Store swap
            self.swaps.write(swap_id, swap);
            self.hashlock_to_swap.write(hashlock, swap_id);
            
            // Add to user's swaps
            // let mut user_swaps = self.user_swaps.read(caller);
            // user_swaps.append(swap_id);
            // self.user_swaps.write(caller, user_swaps);

            self.user_swaps.entry(caller).push(swap_id);
            
            // Add to pending swaps
            // let mut pending = self.pending_swaps.read();
            // pending.append(swap_id);
            // self.pending_swaps.write(pending);

            self.pending_swaps.push(swap_id);
            
            // Update user info
            user_info.total_swaps += 1;
            user_info.active_swaps += 1;
            user_info.last_swap_at = current_time;
            self.user_info.write(caller, user_info);
            
            // Update stats
            let mut stats = self.stats.read();
            stats.total_swaps += 1;
            stats.active_swaps += 1;
            stats.last_swap_at = current_time;
            self.stats.write(stats);
            
            // Update counter
            let counter = self.swap_counter.read() + 1;
            self.swap_counter.write(counter);
            
            // Emit event
            self.emit(BridgeSwapInitiated {
                swap_id: swap_id,
                initiator: caller,
                counterparty: counterparty,
                bridge_type: bridge_type,
                amount_btc: amount_btc,
                amount_strk: amount_strk,
                hashlock: hashlock,
                timelock: timelock,
                expires_at: expires_at,
                timestamp: current_time,
            });
            
            swap_id
        }
        
        fn fund_swap(ref self: ContractState, swap_id: felt252) -> bool {
            // Check if bridge is paused
            // assert(!self.paused.read(), BRIDGE_PAUSED);
            self.pausable.assert_not_paused();
            
            let mut swap = self.get_swap_by_id(swap_id);
            let caller = get_caller_address();
            let current_time = get_block_timestamp();
            
            // Validate swap status
            assert(swap.status == BRIDGE_STATUS_PENDING, SWAP_INVALID_STATUS);
            assert(caller == swap.initiator, NOT_SWAP_INITIATOR);
            assert(current_time < swap.expires_at, SWAP_EXPIRED);
            
            // Calculate fees
            let (protocol_fee, _relayer_fee) = calculate_bridge_fee(
                swap.amount_btc,
                self.fee_config.read().protocol_fee_bps,
                self.fee_config.read().relayer_fee_bps,
                self.fee_config.read().min_fee,
                self.fee_config.read().max_fee
            );
            
            // Handle based on bridge type
            if swap.bridge_type == BRIDGE_TYPE_BTC_TO_STRK {
                // User needs to deposit ZKBTC (representing BTC)
                let zkbtc_dispatcher: IZKBTCDispatcher = IZKBTCDispatcher { 
                    contract_address: self.zkbtc_token.read() 
                };
                
                // Transfer ZKBTC from user to bridge
                zkbtc_dispatcher._transfer_from(caller, get_contract_address(), swap.amount_btc);
                
                // Update BTC vault
                let vault_dispatcher: IBTCVaultDispatcher = IBTCVaultDispatcher { 
                    contract_address: self.btc_vault.read() 
                };
                
                // Lock UTXO equivalent in vault
                // This would need actual UTXO hash in production
                vault_dispatcher.lock_utxo(swap_id.into(), swap_id, swap.expires_at);
                
            } else {
                // User needs to deposit STRK
                let strk_dispatcher: IERC20Dispatcher = IERC20Dispatcher { 
                    contract_address: self.strk_address.read() 
                };
                
                // Transfer STRK from user to swap escrow
                strk_dispatcher.transfer_from(caller, self.swap_escrow.read(), swap.amount_strk);
            }
            
            // Collect fees
            if protocol_fee > 0 {
                let _fee_collector = self.fee_config.read().fee_collector;
                // Transfer fee to collector (simplified)
            }
            
            // Update swap status
            swap.status = BRIDGE_STATUS_ACTIVE;
            swap.funded_at = current_time;
            self.swaps.write(swap_id, swap.clone());
            
            // Emit event
            self.emit(BridgeSwapFunded {
                swap_id: swap_id,
                funder: caller,
                amount: if swap.bridge_type == BRIDGE_TYPE_BTC_TO_STRK {
                    swap.amount_btc
                } else {
                    swap.amount_strk
                },
                asset: if swap.bridge_type == BRIDGE_TYPE_BTC_TO_STRK {
                    'ZKBTC'
                } else {
                    'STRK'
                },
                timestamp: current_time,
            });
            
            true
        }
        
        fn complete_swap(
            ref self: ContractState,
            swap_id: felt252,
            secret: felt252,
            btc_txid: felt252
        ) -> bool {
            // Check if bridge is paused
            // assert(!self.paused.read(), BRIDGE_PAUSED);
            self.pausable.assert_not_paused();
            
            let mut swap = self.get_swap_by_id(swap_id);
            let caller = get_caller_address();
            let current_time = get_block_timestamp();
            
            // Validate swap status
            assert(swap.status == BRIDGE_STATUS_ACTIVE, SWAP_INVALID_STATUS);
            assert(caller == swap.counterparty, NOT_SWAP_COUNTERPARTY);
            assert(current_time < swap.expires_at, SWAP_EXPIRED);
            
            // Validate secret against hashlock
            assert(validate_secret(secret, swap.hashlock), INVALID_SECRET);
            
            // Verify with ZK verifier
            let _verifier_dispatcher: IZKAtomicSwapVerifierDispatcher = IZKAtomicSwapVerifierDispatcher { 
                contract_address: self.zk_verifier.read() 
            };
            
            // Prepare proof data (simplified)
            let mut proof_data = ArrayTrait::<felt252>::new();
            proof_data.append(swap_id);
            proof_data.append(secret);
            proof_data.append(btc_txid);
            
            // Submit and verify proof
            let proof_id = self.submit_proof(swap_id, 2, proof_data); // 2 = ZKProof type
            let verified = self.verify_proof(proof_id, true);
            assert(verified, PROOF_VERIFICATION_FAILED);
            
            // Handle based on bridge type
            if swap.bridge_type == BRIDGE_TYPE_BTC_TO_STRK {
                // Release STRK to counterparty (initiator gets BTC, counterparty gets STRK)
                let strk_dispatcher: IERC20Dispatcher = IERC20Dispatcher { 
                    contract_address: self.strk_address.read() 
                };
                
                // Transfer STRK from escrow to counterparty
                strk_dispatcher.transfer(swap.counterparty, swap.amount_strk);
                
                // Update BTC vault - mark UTXO as spent
                let vault_dispatcher: IBTCVaultDispatcher = IBTCVaultDispatcher { 
                    contract_address: self.btc_vault.read() 
                };
                
                vault_dispatcher.spend_utxo(swap_id.into(), btc_txid);
                
            } else {
                // Release BTC (ZKBTC) to counterparty (initiator gets STRK, counterparty gets BTC)
                let zkbtc_dispatcher: IZKBTCDispatcher = IZKBTCDispatcher { 
                    contract_address: self.zkbtc_token.read() 
                };
                
                // Transfer ZKBTC from bridge to counterparty
                zkbtc_dispatcher._transfer(swap.counterparty, swap.amount_btc);
            }
            
            // Update swap
            swap.status = BRIDGE_STATUS_COMPLETED;
            swap.secret = secret;
            swap.secret_revealed = true;
            swap.completed_at = current_time;
            swap.btc_txid = btc_txid;
            self.swaps.write(swap_id, swap.clone());
            
            // Update user info
            let mut initiator_info = self.user_info.read(swap.initiator);
            if initiator_info.active_swaps > 0 {
                initiator_info.active_swaps -= 1;
            }
            self.user_info.write(swap.initiator, initiator_info);
            
            let mut counterparty_info = self.user_info.read(swap.counterparty);
            counterparty_info.total_swaps += 1;
            self.user_info.write(swap.counterparty, counterparty_info);
            
            // Update stats
            let mut stats = self.stats.read();
            stats.active_swaps -= 1;
            stats.completed_swaps += 1;
            stats.total_volume_btc += swap.amount_btc;
            stats.total_volume_strk += swap.amount_strk;
            
            // Update average completion time
            let completion_time = current_time - swap.created_at;
            stats.avg_completion_time = (stats.avg_completion_time * (stats.completed_swaps - 1) + 
                                        completion_time) / stats.completed_swaps;
            
            self.stats.write(stats);
            
            // Emit events
            self.emit(SecretRevealed {
                swap_id: swap_id,
                secret: secret,
                revealer: caller,
                timestamp: current_time,
            });
            
            self.emit(BridgeSwapCompleted {
                swap_id: swap_id,
                completer: caller,
                secret: secret,
                btc_txid: btc_txid,
                strk_tx_hash: 0, // Would be actual Starknet tx hash
                timestamp: current_time,
            });
            
            true
        }
        
        fn refund_swap(ref self: ContractState, swap_id: felt252) -> bool {
            // Check if bridge is paused
            // assert(!self.paused.read(), BRIDGE_PAUSED);
            self.pausable.assert_not_paused();
            
            let mut swap = self.get_swap_by_id(swap_id);
            let caller = get_caller_address();
            let current_time = get_block_timestamp();
            
            // Validate swap status
            assert(swap.status == BRIDGE_STATUS_ACTIVE, SWAP_INVALID_STATUS);
            assert(caller == swap.initiator, NOT_SWAP_INITIATOR);
            assert(current_time >= swap.expires_at, TIMELOCK_NOT_EXPIRED);
            
            // Handle refund based on bridge type
            if swap.bridge_type == BRIDGE_TYPE_BTC_TO_STRK {
                // Refund ZKBTC to initiator
                let zkbtc_dispatcher: IZKBTCDispatcher = IZKBTCDispatcher { 
                    contract_address: self.zkbtc_token.read() 
                };
                
                zkbtc_dispatcher._transfer(swap.initiator, swap.amount_btc);
                
                // Unlock UTXO in vault
                let vault_dispatcher: IBTCVaultDispatcher = IBTCVaultDispatcher { 
                    contract_address: self.btc_vault.read() 
                };
                
                vault_dispatcher.unlock_utxo(swap_id.into(), swap_id);
                
            } else {
                // Refund STRK to initiator
                let strk_dispatcher: IERC20Dispatcher = IERC20Dispatcher { 
                    contract_address: self.strk_address.read() 
                };
                
                strk_dispatcher.transfer(swap.initiator, swap.amount_strk);
            }
            
            // Update swap
            swap.status = BRIDGE_STATUS_REFUNDED;
            self.swaps.write(swap_id, swap.clone());
            
            // Update user info
            let mut user_info = self.user_info.read(swap.initiator);
            if user_info.active_swaps > 0 {
                user_info.active_swaps -= 1;
            }
            self.user_info.write(swap.initiator, user_info);
            
            // Update stats
            let mut stats = self.stats.read();
            stats.active_swaps -= 1;
            self.stats.write(stats);
            
            // Emit event
            self.emit(BridgeSwapRefunded {
                swap_id: swap_id,
                refundee: swap.initiator,
                amount: if swap.bridge_type == BRIDGE_TYPE_BTC_TO_STRK {
                    swap.amount_btc
                } else {
                    swap.amount_strk
                },
                asset: if swap.bridge_type == BRIDGE_TYPE_BTC_TO_STRK {
                    'ZKBTC'
                } else {
                    'STRK'
                },
                timestamp: current_time,
                reason: 'TIMELOCK_EXPIRED',
            });
            
            true
        }
        
        fn relay_complete_swap(
            ref self: ContractState,
            swap_id: felt252,
            secret: felt252,
            btc_txid: felt252,
            relayer_fee_recipient: ContractAddress
        ) -> bool {
            // Check if bridge is paused
            // assert(!self.paused.read(), BRIDGE_PAUSED);
            self.pausable.assert_not_paused();
            
            // Check caller is whitelisted relayer
            let caller = get_caller_address();
            assert(self.whitelisted_relayers.read(caller), UNAUTHORIZED_RELAYER);
            
            let mut swap = self.get_swap_by_id(swap_id);
            let current_time = get_block_timestamp();
            
            // Validate swap status
            assert(swap.status == BRIDGE_STATUS_ACTIVE, SWAP_INVALID_STATUS);
            assert(current_time < swap.expires_at, SWAP_EXPIRED);
            
            // Validate secret
            assert(validate_secret(secret, swap.hashlock), INVALID_SECRET);
            
            // Calculate fees including relayer fee
            let (protocol_fee, relayer_fee) = calculate_bridge_fee(
                swap.amount_btc,
                self.fee_config.read().protocol_fee_bps,
                self.fee_config.read().relayer_fee_bps,
                self.fee_config.read().min_fee,
                self.fee_config.read().max_fee
            );
            
            // Complete the swap (similar to complete_swap but with relayer fee)
            if swap.bridge_type == BRIDGE_TYPE_BTC_TO_STRK {
                // Release STRK to counterparty minus fees
                let strk_dispatcher: IERC20Dispatcher = IERC20Dispatcher { 
                    contract_address: self.strk_address.read() 
                };
                
                let amount_after_fees = swap.amount_strk - protocol_fee - relayer_fee;
                strk_dispatcher.transfer(swap.counterparty, amount_after_fees);
                
                // Pay relayer fee
                if relayer_fee > 0 {
                    strk_dispatcher.transfer(relayer_fee_recipient, relayer_fee);
                }
                
                // Update BTC vault
                let vault_dispatcher: IBTCVaultDispatcher = IBTCVaultDispatcher { 
                    contract_address: self.btc_vault.read() 
                };
                vault_dispatcher.spend_utxo(swap_id.into(), btc_txid);
                
            } else {
                // Release ZKBTC to counterparty minus fees
                let zkbtc_dispatcher: IZKBTCDispatcher = IZKBTCDispatcher { 
                    contract_address: self.zkbtc_token.read() 
                };
                
                let amount_after_fees = swap.amount_btc - protocol_fee - relayer_fee;
                zkbtc_dispatcher._transfer(swap.counterparty, amount_after_fees);
                
                // Pay relayer fee
                if relayer_fee > 0 {
                    zkbtc_dispatcher._transfer(relayer_fee_recipient, relayer_fee);
                }
            }
            
            // Collect protocol fee
            if protocol_fee > 0 {
                let _fee_collector = self.fee_config.read().fee_collector;
                // Fee already collected via amount reduction
                let mut stats = self.stats.read();
                stats.total_fees_collected += protocol_fee;
                self.stats.write(stats);
            }
            
            // Update swap
            swap.status = BRIDGE_STATUS_COMPLETED;
            swap.secret = secret;
            swap.secret_revealed = true;
            swap.completed_at = current_time;
            swap.btc_txid = btc_txid;
            self.swaps.write(swap_id, swap.clone());
            
            // Update relayer stats
            let mut relayer_info = self.relayers.read(caller);
            relayer_info.total_swaps += 1;
            relayer_info.total_volume += swap.amount_btc;
            self.relayers.write(caller, relayer_info);
            
            // Emit events
            self.emit(SecretRevealed {
                swap_id: swap_id,
                secret: secret,
                revealer: caller,
                timestamp: current_time,
            });
            
            self.emit(BridgeSwapCompleted {
                swap_id: swap_id,
                completer: swap.counterparty,
                secret: secret,
                btc_txid: btc_txid,
                strk_tx_hash: 0,
                timestamp: current_time,
            });
            
            true
        }
        
        fn submit_proof(
            ref self: ContractState,
            swap_id: felt252,
            proof_type: u8,
            proof_data: Array<felt252>
        ) -> felt252 {
            // Check if bridge is paused
            // assert(!self.paused.read(), BRIDGE_PAUSED);
            self.pausable.assert_not_paused();
            
            let caller = get_caller_address();
            let current_time = get_block_timestamp();
            
            // Generate proof ID
            let proof_id = generate_proof_id(
                swap_id,
                proof_type,
                caller,
                current_time
            );
            
            // Create proof
            let proof = BridgeProof {
                proof_id: proof_id,
                swap_id: swap_id,
                proof_type: proof_type,
                proof_data: PoseidonTrait::new()
                    .update(proof_data.len().into())
                    .finalize(), // Hash of proof data
                verified_at: 0,
                verifier: caller,
                valid_until: current_time + PROOF_VALIDITY_WINDOW,
            };
            
            self.proofs.write(proof_id, proof.clone());
            
            // Add to swap's proofs
            // let mut swap_proofs = self.swap_proofs.read(swap_id);
            // swap_proofs.append(proof_id);
            // self.swap_proofs.write(swap_id, swap_proofs);
            self.swap_proofs.entry(swap_id).push(proof_id);
            
            // Update proof counter
            let counter = self.proof_counter.read() + 1;
            self.proof_counter.write(counter);
            
            // Emit event
            self.emit(BridgeProofSubmitted {
                proof_id: proof_id,
                swap_id: swap_id,
                proof_type: proof_type,
                submitter: caller,
                timestamp: current_time,
                valid_until: proof.valid_until,
            });
            
            proof_id
        }
        
        fn verify_proof(
            ref self: ContractState,
            proof_id: felt252,
            expected_result: bool
        ) -> bool {
            // Check if bridge is paused
            // assert(!self.paused.read(), BRIDGE_PAUSED);
            self.pausable.assert_not_paused();
            
            // Check caller has verifier role
            assert(self.accesscontrol.has_role(VERIFIER_ROLE, get_caller_address()), 
                   UNAUTHORIZED_RELAYER);
            
            let mut proof = self.proofs.read(proof_id);
            assert!(!proof.proof_id.is_zero(), "Proof not found");
            assert(get_block_timestamp() < proof.valid_until, PROOF_TOO_OLD);
            
            // Update proof
            proof.verified_at = get_block_timestamp();
            self.proofs.write(proof_id, proof.clone());
            
            // Emit event
            self.emit(BridgeProofVerified {
                proof_id: proof_id,
                swap_id: proof.swap_id,
                verifier: get_caller_address(),
                result: expected_result,
                timestamp: get_block_timestamp(),
            });
            
            expected_result
        }
        
        fn retry_swap(ref self: ContractState, swap_id: felt252) -> bool {
            // Check if bridge is paused
            // assert(!self.paused.read(), BRIDGE_PAUSED);
            self.pausable.assert_not_paused();
            
            let mut swap = self.get_swap_by_id(swap_id);
            let caller = get_caller_address();
            let current_time = get_block_timestamp();
            
            // Check if swap can be retried
            assert(swap.status == BRIDGE_STATUS_FAILED || swap.status == BRIDGE_STATUS_EXPIRED,
                   SWAP_INVALID_STATUS);
            assert(caller == swap.initiator, NOT_SWAP_INITIATOR);
            assert(swap.retry_count < MAX_RETRY_ATTEMPTS, MAX_RETRIES_EXCEEDED);
            
            // Check retry timing
            let retry = self.retry_info.read(swap_id);
            if retry.last_attempt != 0 {
                assert(current_time - retry.last_attempt >= RETRY_DELAY, RETRY_TOO_SOON);
            }
            
            // Reset swap status to pending
            swap.status = BRIDGE_STATUS_PENDING;
            swap.retry_count += 1;
            swap.expires_at = current_time + MIN_SWAP_DURATION;
            self.swaps.write(swap_id, swap.clone());
            
            // Update retry info
            let retry_info = RetryInfo {
                swap_id: swap_id,
                attempts: swap.retry_count,
                last_attempt: current_time,
                next_attempt: current_time + RETRY_DELAY,
                reason: 'RETRY_INITIATED',
            };
            self.retry_info.write(swap_id, retry_info);
            
            // Emit event
            self.emit(BridgeRetryInitiated {
                swap_id: swap_id,
                attempt: swap.retry_count,
                max_attempts: MAX_RETRY_ATTEMPTS,
                next_attempt: current_time + RETRY_DELAY,
                reason: 'RETRY_INITIATED',
                timestamp: current_time,
            });
            
            true
        }
        
        // View functions
        fn get_swap(self: @ContractState, swap_id: felt252) -> AtomicBridgeSwapResponse {
            let swap = self.get_swap_by_id(swap_id);
            bridge_swap_to_response(swap)
        }
        
        fn get_user_swaps(self: @ContractState, user: ContractAddress, offset: u64, limit: u64) -> Array<AtomicBridgeSwapResponse> {
            // let user_swaps = self.user_swaps.read(user);
            // let mut result = ArrayTrait::new();

            let mut user_swaps: Array<felt252> = array![];
            let mut result: Array<AtomicBridgeSwapResponse> = array![];

            let len: u64 = self.user_swaps.entry(user).len();

            for i in 0..len {
                let each: felt252 = self.user_swaps.entry(user).at(i).read();

                user_swaps.append(each);
            }
            
            let start = offset;
            let end = if offset + limit > len {
                len
            } else {
                offset + limit
            };
            
            let mut j: u32 = start.try_into().unwrap();
            while j < end.try_into().unwrap() {
                let swap_id = *user_swaps.at(j);
                let swap = self.swaps.read(swap_id);
                result.append(bridge_swap_to_response(swap));
                j += 1;
            };
            
            result
        }
        
        fn get_pending_swaps(self: @ContractState, offset: u64, limit: u64) -> Array<AtomicBridgeSwapResponse> {
           
           
            // let pending = self.pending_swaps.read();
            let mut pending: Array<felt252> = array![];
            let mut result: Array<AtomicBridgeSwapResponse> = array![];
            let current_time = get_block_timestamp();

            let len: u64 = self.pending_swaps.len();

            for i in 0..len {
                let each: felt252 = self.pending_swaps.at(i).read();

                pending.append(each);
            }
            
            let start = offset;
            let end = if offset + limit > len {
                len
            } else {
                offset + limit
            };
            
            let mut j = start.try_into().unwrap();
            while j < end.try_into().unwrap() {
                let swap_id = *pending.at(j);
                let swap = self.swaps.read(swap_id);
                
                // Only return active pending swaps
                if swap.status == BRIDGE_STATUS_ACTIVE && current_time < swap.expires_at {
                    result.append(bridge_swap_to_response(swap));
                }
                
                j += 1;
            };
            
            result
        }
        
        fn get_bridge_stats(self: @ContractState) -> BridgeStats {
            self.stats.read()
        }
        
        fn get_user_info(self: @ContractState, user: ContractAddress) -> UserBridgeInfo {
            self.user_info.read(user)
        }
        
        fn can_refund(self: @ContractState, swap_id: felt252) -> bool {
            let swap = self.swaps.read(swap_id);
            !swap.swap_id.is_zero() && 
            swap.status == BRIDGE_STATUS_ACTIVE && 
            get_block_timestamp() >= swap.expires_at
        }
        
        fn get_required_confirmations(self: @ContractState, bridge_type: u8) -> u64 {
            self.required_confirmations.read(bridge_type)
        }
        
        // Admin functions
        fn whitelist_relayer(ref self: ContractState, relayer: ContractAddress, fee_bps: u64) {

            assert!(self.accesscontrol.has_role(ADMIN_ROLE, get_caller_address()), "Caller is not an Admin");
            
            assert!(!relayer.is_zero(), "Invalid relayer");
            assert(fee_bps <= MAX_BRIDGE_FEE_BPS, FEE_TOO_HIGH);
            
            self.relayers.write(relayer, BridgeRelayer {
                relayer: relayer,
                fee_bps: fee_bps,
                is_active: true,
                total_swaps: 0,
                total_volume: 0,
                whitelisted: true,
            });
            
            self.whitelisted_relayers.write(relayer, true);
            self.accesscontrol._grant_role(RELAYER_ROLE, relayer);
            
            self.emit(BridgeRelayerWhitelisted {
                relayer: relayer,
                fee_bps: fee_bps,
                added_by: get_caller_address(),
                timestamp: get_block_timestamp(),
            });
        }
        
        fn remove_relayer(ref self: ContractState, relayer: ContractAddress) {

            assert!(self.accesscontrol.has_role(ADMIN_ROLE, get_caller_address()), "Caller is not an Admin");
            
            self.whitelisted_relayers.write(relayer, false);
            
            let mut info = self.relayers.read(relayer);
            info.whitelisted = false;
            info.is_active = false;
            self.relayers.write(relayer, info);
            
            self.accesscontrol._revoke_role(RELAYER_ROLE, relayer);
            
            self.emit(BridgeRelayerRemoved {
                relayer: relayer,
                removed_by: get_caller_address(),
                timestamp: get_block_timestamp(),
            });
        }
        
        fn set_fee_config(
            ref self: ContractState,
            protocol_fee_bps: u64,
            relayer_fee_bps: u64,
            min_fee: u256,
            max_fee: u256,
            fee_collector: ContractAddress
        ) {
            self.ownable.assert_only_owner();
            
            assert(protocol_fee_bps <= MAX_BRIDGE_FEE_BPS, FEE_TOO_HIGH);
            assert(relayer_fee_bps <= MAX_BRIDGE_FEE_BPS, FEE_TOO_HIGH);
            assert!(min_fee <= max_fee, "Invalid fee range");
            assert!(!fee_collector.is_zero(), "Invalid fee collector");
            
            self.fee_config.write(BridgeFee {
                protocol_fee_bps: protocol_fee_bps,
                relayer_fee_bps: relayer_fee_bps,
                min_fee: min_fee,
                max_fee: max_fee,
                fee_collector: fee_collector,
            });
            
            self.emit(BridgeFeeUpdated {
                protocol_fee_bps: protocol_fee_bps,
                relayer_fee_bps: relayer_fee_bps,
                min_fee: min_fee,
                max_fee: max_fee,
                fee_collector: fee_collector,
                updated_by: get_caller_address(),
                timestamp: get_block_timestamp(),
            });
        }
        
        fn pause_bridge(ref self: ContractState, reason: felt252) {
            self.ownable.assert_only_owner();
            
            // self.paused.write(true);
            // self.pause_reason.write(reason);
            // self.paused_at.write(get_block_timestamp());

            self.pausable.pause();
            
            self.emit(BridgePaused {
                paused_by: get_caller_address(),
                timestamp: get_block_timestamp(),
                reason: reason,
            });
        }
        
        fn unpause_bridge(ref self: ContractState) {
            self.ownable.assert_only_owner();
            
            // self.paused.write(false);
            // self.pause_reason.write(0);
            // self.paused_at.write(0);

            self.pausable.unpause();
            
            self.emit(BridgeUnpaused {
                unpaused_by: get_caller_address(),
                timestamp: get_block_timestamp(),
            });
        }
        
        fn set_contract_address(
            ref self: ContractState,
            contract_type: felt252,
            contract_address: ContractAddress
        ) {
            self.ownable.assert_only_owner();
            assert(!contract_address.is_zero(), INVALID_CONTRACT_ADDRESS);
            assert!(contract_type != 'BTC_VAULT' || contract_type != 'SWAP_ESCROW' || contract_type != 'ZK_VERIFIER' || contract_type != 'ZKBTC_TOKEN' || contract_type != 'STRK_TOKEN', "Invalid Contract Type");
            
            if contract_type == 'BTC_VAULT' {
                self.btc_vault.write(contract_address);
            } else if contract_type == 'SWAP_ESCROW' {
                self.swap_escrow.write(contract_address);
            } else if contract_type == 'ZK_VERIFIER' {
                self.zk_verifier.write(contract_address);
            } else if contract_type == 'ZKBTC_TOKEN' {
                self.zkbtc_token.write(contract_address);
            }  else if contract_type == 'STRK_TOKEN' {
                self.strk_address.write(contract_address);
            }
                     
            self.emit(ContractWhitelisted {
                contract_address: contract_address,
                contract_type: contract_type,
                added_by: get_caller_address(),
                timestamp: get_block_timestamp(),
            });
        }
        
        fn cleanup_expired_swaps(ref self: ContractState) -> u64 {
            // self.accesscontrol.assert_has_role(GUARDIAN_ROLE, get_caller_address());
            assert!(self.accesscontrol.has_role(GUARDIAN_ROLE, get_caller_address()), "Caller does not have the Guardian Role");

            
            // let pending = self.pending_swaps.read();
            let mut pending: Array<felt252> = array![];

            let len: u64 = self.pending_swaps.len();

            for i in 0..len {
                let each: felt252 = self.pending_swaps.at(i).read();

                pending.append(each);
            };
            let current_time = get_block_timestamp();
            let mut expired_count = 0;
            // let mut new_pending: Array<felt252> = array![];
            
            let mut j: u32 = 0;
            while j < len.try_into().unwrap() {
                let swap_id = *pending.at(j);
                let mut swap = self.swaps.read(swap_id);
                
                if swap.status == BRIDGE_STATUS_ACTIVE && current_time >= swap.expires_at {
                    // Mark as expired
                    swap.status = BRIDGE_STATUS_EXPIRED;
                    self.swaps.write(swap_id, swap.clone());
                    
                    // Update user info
                    let mut user_info = self.user_info.read(swap.initiator);
                    if user_info.active_swaps > 0 {
                        user_info.active_swaps -= 1;
                    }
                    self.user_info.write(swap.initiator, user_info);
                    
                    // Update stats
                    let mut stats = self.stats.read();
                    stats.active_swaps -= 1;
                    stats.failed_swaps += 1;
                    self.stats.write(stats);
                    
                    self.emit(BridgeSwapExpired {
                        swap_id: swap_id,
                        timestamp: current_time,
                    });
                    
                    expired_count += 1;
                } else {
                    // new_pending.append(swap_id);
                    self.pending_swaps.at(j.into()).write(swap_id);
                }
                
                j += 1;
            };
            
            // self.pending_swaps.write(new_pending);
            
            expired_count
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
        fn get_swap_by_id(self: @ContractState, swap_id: felt252) -> AtomicBridgeSwap {
            let swap = self.swaps.read(swap_id);
            assert(!swap.swap_id.is_zero(), SWAP_NOT_FOUND);
            swap
        }
    }
}