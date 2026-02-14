#[starknet::contract]
pub mod BTCVault {
    use crate::structs::bitcoin_structs::SwapLock;
use starknet::{
        ContractAddress,
        ClassHash,
        get_caller_address,
        get_block_timestamp,
        get_contract_address
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
    use core::array::{
        Array,
        ArrayTrait
    };
    // use core::dict::Felt252DictTrait;
    use core::traits::Into;
    // use core::poseidon::PoseidonTrait;
    // use core::hash::HashStateTrait;
    
    // OpenZeppelin imports
    use openzeppelin::access::ownable::OwnableComponent;
    use openzeppelin::security::pausable::PausableComponent;
    use openzeppelin_access::accesscontrol::AccessControlComponent;
    use openzeppelin::introspection::src5::SRC5Component;
    use openzeppelin::upgrades::UpgradeableComponent;
    use openzeppelin::upgrades::interface::IUpgradeable;
    // use openzeppelin::token::erc20::interface::{IERC20Dispatcher, IERC20DispatcherTrait};
    
    // Import local modules
    use crate::constants::bitcoin_constants::*;
    use crate::errors::bitcoin_errors::*;
    use crate::structs::bitcoin_structs::*;
    use crate::event_structs::bitcoin_events::*;
    use crate::interfaces::i_btc_vault::IBTCVault;
    use crate::interfaces::i_zkbtc::IZKBTCDispatcher;
    use crate::interfaces::i_zkbtc::IZKBTCDispatcherTrait;
    use crate::utils::bitcoin_utils::*;
    
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
    const GUARDIAN_ROLE: felt252 = selector!("GUARDIAN_ROLE");
    const SWAP_ESCROW_ROLE: felt252 = selector!("SWAP_ESCROW_ROLE");
    const RELAYER_ROLE: felt252 = selector!("RELAYER_ROLE");
    
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
        
        // Core storage
        zkbtc_token: ContractAddress,
        
        // UTXO tracking
        utxos: Map<felt252, UTXO>,
        user_utxos: Map<ContractAddress, Vec<felt252>>,
        utxo_count: u64,
        
        // Withdrawal management
        withdrawal_requests: Map<u64, WithdrawalRequest>,
        user_withdrawals: Map<ContractAddress, Vec<u64>>,
        withdrawal_counter: u64,
        
        // Guardian management
        guardians: Map<ContractAddress, GuardianInfo>,
        guardian_list: Vec<ContractAddress>,
        guardian_count: u8,
        threshold: u8,
        
        // Whitelisted swap escrows
        whitelisted_swap_escrows: Map<ContractAddress, bool>,
        
        // Active locks for swaps
        swap_locks: Map<felt252, SwapLock>,
        
        // Vault statistics
        stats: VaultStats,
        
        // Paused state
        paused: bool,
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
        UTXODeposited: UTXODeposited,
        UTXOSpent: UTXOSpent,
        UTXOLocked: UTXOLocked,
        UTXOUnlocked: UTXOUnlocked,
        WithdrawalRequested: WithdrawalRequested,
        WithdrawalSigned: WithdrawalSigned,
        WithdrawalProcessed: WithdrawalProcessed,
        WithdrawalFailed: WithdrawalFailed,
        GuardianAdded: GuardianAdded,
        GuardianRemoved: GuardianRemoved,
        ThresholdUpdated: ThresholdUpdated,
        SwapEscrowWhitelisted: SwapEscrowWhitelisted,
        SwapEscrowRemoved: SwapEscrowRemoved,
        VaultPaused: VaultPaused,
        VaultUnpaused: VaultUnpaused,
    }
    
    #[constructor]
    fn constructor(
        ref self: ContractState,
        owner: ContractAddress,
        zkbtc_token: ContractAddress,
        // initial_guardians: ByteArray,
        initial_threshold: u8
    ) {
        // Initialize Ownable
        self.ownable.initializer(owner);
        
        // Initialize AccessControl
        self.accesscontrol.initializer();
        self.accesscontrol._grant_role(ADMIN_ROLE, owner);
        self.accesscontrol._grant_role(AccessControlComponent::DEFAULT_ADMIN_ROLE, owner);
        
        // Set ZKBTC token address
        self.zkbtc_token.write(zkbtc_token);
        

           // Initialize guardians
    // let mut guardian_count = 0;
    // // let mut guardian_list: Vec<ContractAddress> = VecTrait::new();
    // let mut guardian_list: Array<ContractAddress> = array![]; 

    
    // // Parse comma-separated guardian addresses
    // if initial_guardians.len() > 0 {
    //     let mut remaining = initial_guardians;
    //     loop {
    //         match remaining.split_once(',') {
    //             Option::Some((guardian_str, rest)) => {
    //                 // Convert ByteArray to felt252 then to ContractAddress
    //                 let guardian_felt: felt252 = guardian_str.into();
    //                 // let guardian = contract_address_const::<guardian_felt>();
    //                 let guardian: ContractAddress = guardian_felt.into();
                    
    //                 self.guardians.write(guardian, GuardianInfo {
    //                     guardian: guardian,
    //                     is_active: true,
    //                     added_at: get_block_timestamp(),
    //                     added_by: owner,
    //                     total_votes: 0,
    //                 });
                    
    //                 guardian_list.append(guardian);
    //                 guardian_count += 1;
    //                 self.accesscontrol._grant_role(GUARDIAN_ROLE, guardian);
                    
    //                 remaining = rest;
    //             },
    //             Option::None => {
    //                 // Last guardian
    //                 let guardian_felt: felt252 = remaining.into();
    //                 let guardian: ContractAddress = guardian_felt.into();
                    
    //                 self.guardians.write(guardian, GuardianInfo {
    //                     guardian: guardian,
    //                     is_active: true,
    //                     added_at: get_block_timestamp(),
    //                     added_by: owner,
    //                     total_votes: 0,
    //                 });
                    
    //                 guardian_list.append(guardian);
    //                 guardian_count += 1;
    //                 self.accesscontrol._grant_role(GUARDIAN_ROLE, guardian);
                    
    //                 break;
    //             }
    //         }
    //     };
    // }
        
        // self.guardian_list.write(guardian_list);
        // self.guardian_count.write(guardian_count);
        
        // Set threshold
        // assert(initial_threshold <= guardian_count, THRESHOLD_TOO_HIGH);
        assert(initial_threshold >= MIN_THRESHOLD, THRESHOLD_TOO_LOW);
        self.threshold.write(initial_threshold);
        
        // Initialize stats
        self.stats.write(VaultStats {
            total_btc_locked: 0,
            total_utxos: 0,
            total_withdrawals: 0,
            total_withdrawal_amount: 0,
            total_deposits: 0,
            total_deposit_amount: 0,
            active_swaps: 0,
            last_updated: get_block_timestamp(),
        });
        
        // Initialize counters
        self.utxo_count.write(0);
        self.withdrawal_counter.write(0);
        // self.paused.write(false);
    }
    
    #[abi(embed_v0)]
    impl BTCVaultImpl of IBTCVault<ContractState> {
        fn deposit_utxo(
            ref self: ContractState,
            txid: felt252,
            vout: u32,
            amount: u64,
            script_pubkey: felt252,
            merkle_proof: felt252,
            block_height: u64,
            block_time: u64
        ) -> felt252 {
            // Check if vault is paused
            // assert(!self.paused.read(), VAULT_PAUSED);

            self.pausable.assert_not_paused();
            
            // Validate amount
            assert(amount > 0, UTXO_INVALID_AMOUNT);
            assert(is_above_dust_limit(amount), UTXO_BELOW_DUST);
            
            // Generate UTXO hash
            let utxo_hash = generate_utxo_hash(txid, vout);
            
            // Ensure UTXO doesn't already exist
            let existing: UTXO = self.utxos.read(utxo_hash);
            assert(existing.txid.is_zero(), UTXO_DUPLICATE);
            
            // Verify merkle proof (simplified for hackathon)
            // In production, would verify against Bitcoin block headers
            assert(verify_merkle_proof(txid, block_height.into(), merkle_proof), MERKLE_PROOF_INVALID);
            
            // Check user UTXO limit
            let caller: ContractAddress = get_caller_address();
            // let mut user_utxos: Array<felt252> = array![]; 

            let len: u64 = self.user_utxos.entry(caller).len();

            assert(len < MAX_UTXOS_PER_USER, UTXO_MAX_EXCEEDED);
            
            // Create UTXO
            let utxo = UTXO {
                txid: txid,
                vout: vout,
                amount: amount,
                script_pubkey: script_pubkey,
                owner: caller,
                status: UTXO_STATUS_UNSPENT,
                locked_until: 0,
                created_at: get_block_timestamp(),
                spent_at: 0,
                confirmations: REQUIRED_CONFIRMATIONS, // Assume enough confirmations
            };
            
            // Store UTXO
            self.utxos.write(utxo_hash, utxo);
            
            self.user_utxos.entry(caller).push(utxo_hash);

            
            // Update stats
            let mut stats = self.stats.read();
            stats.total_utxos += 1;
            stats.total_deposits += 1;
            stats.total_deposit_amount += amount.into();
            stats.total_btc_locked += amount.into();
            stats.last_updated = get_block_timestamp();
            self.stats.write(stats);
            
            // Mint ZKBTC tokens
            let zkbtc_amount: u256 = amount.into();
            let zkbtc_dispatcher = IZKBTCDispatcher { contract_address: self.zkbtc_token.read() };
            
            // Call bridge_mint on ZKBTC contract
            zkbtc_dispatcher.bridge_mint(caller, zkbtc_amount, txid);
            
            // Emit event
            self.emit(UTXODeposited {
                utxo_hash: utxo_hash,
                txid: txid,
                vout: vout,
                amount: amount,
                owner: caller,
                timestamp: get_block_timestamp(),
                zkbtc_minted: zkbtc_amount,
            });
            
            utxo_hash
        }
        
        fn request_withdrawal(
            ref self: ContractState,
            amount: u256,
            bitcoin_address: felt252
        ) -> u64 {
            // Check if vault is paused
            // assert(!self.paused.read(), VAULT_PAUSED);
            self.pausable.assert_not_paused();

            
            // Validate amount
            assert(amount >= MIN_WITHDRAWAL_AMOUNT, WITHDRAWAL_AMOUNT_TOO_LOW);
            assert(amount <= MAX_WITHDRAWAL_AMOUNT, WITHDRAWAL_AMOUNT_TOO_HIGH);
            
            // Validate Bitcoin address
            assert(validate_bitcoin_address(bitcoin_address), INVALID_BITCOIN_ADDRESS);
            
            // Check total BTC locked is sufficient
            let stats = self.stats.read();
            assert(stats.total_btc_locked >= amount, INSUFFICIENT_TOTAL_BTC);
            
            let caller: ContractAddress = get_caller_address();
            
            // Generate request ID
            let request_id = generate_withdrawal_id(
                caller,
                amount,
                bitcoin_address,
                get_block_timestamp()
            );
            
            // Ensure request doesn't exist
            let existing: WithdrawalRequest = self.withdrawal_requests.read(request_id);
            assert!(existing.request_id == 0, "Request already exists");
            
            // Create withdrawal request
            let request = WithdrawalRequest {
                request_id: request_id,
                user: caller,
                amount: amount,
                bitcoin_address: bitcoin_address,
                status: WITHDRAWAL_STATUS_PENDING,
                created_at: get_block_timestamp(),
                processed_at: 0,
                expiry: get_block_timestamp() + WITHDRAWAL_EXPIRY,
                guardian_signatures: 0,
                required_signatures: self.threshold.read(),
                btc_txid: 0,
            };
            
            // Store request
            self.withdrawal_requests.write(request_id, request.clone());
            
            // Add to user's withdrawal list
            // let mut user_withdrawals = self.user_withdrawals.read(caller);
            // user_withdrawals.append(request_id);
            // self.user_withdrawals.write(caller, user_withdrawals);
            self.user_withdrawals.entry(caller).push(request_id);
            
            // Update withdrawal counter
            let counter: u64 = self.withdrawal_counter.read() + 1;
            self.withdrawal_counter.write(counter);
            
            // Burn ZKBTC tokens
            let zkbtc_dispatcher = IZKBTCDispatcher { contract_address: self.zkbtc_token.read() };
            zkbtc_dispatcher.native_burn(caller, amount, bitcoin_address);
            
            // Update stats
            let mut stats: VaultStats = self.stats.read();
            stats.total_withdrawals += 1;
            stats.total_withdrawal_amount += amount;
            stats.total_btc_locked -= amount;
            stats.last_updated = get_block_timestamp();
            self.stats.write(stats);
            
            // Emit event
            self.emit(WithdrawalRequested {
                request_id: request_id,
                user: caller,
                amount: amount,
                bitcoin_address: bitcoin_address,
                expiry: request.expiry,
                timestamp: get_block_timestamp(),
            });
            
            request_id
        }
        
        fn sign_withdrawal(
            ref self: ContractState,
            request_id: u64
        ) -> bool {
            // Check if caller is guardian
            let caller: ContractAddress = get_caller_address();
            assert(self.accesscontrol.has_role(GUARDIAN_ROLE, caller), NOT_GUARDIAN);
            
            // Get request
            let mut request: WithdrawalRequest = self.withdrawal_requests.read(request_id);
            assert(request.request_id != 0, WITHDRAWAL_NOT_FOUND);
            
            // Check request status
            assert(request.status == WITHDRAWAL_STATUS_PENDING || 
                   request.status == WITHDRAWAL_STATUS_PROCESSING, 
                   WITHDRAWAL_INVALID_STATUS);
            
            // Check if not expired
            assert(get_block_timestamp() < request.expiry, WITHDRAWAL_EXPIRED);
            
            // Increment signatures
            request.guardian_signatures += 1;
            
            // Update status if threshold reached
            if request.guardian_signatures >= request.required_signatures {
                request.status = WITHDRAWAL_STATUS_PROCESSING;
            }
            
            // Store updated request
            self.withdrawal_requests.write(request_id, request.clone());
            
            // Update guardian stats
            let mut guardian_info = self.guardians.read(caller);
            guardian_info.total_votes += 1;
            self.guardians.write(caller, guardian_info);
            
            // Emit event
            self.emit(WithdrawalSigned {
                request_id: request_id,
                guardian: caller,
                signatures_count: request.guardian_signatures,
                required_signatures: request.required_signatures,
                timestamp: get_block_timestamp(),
            });
            
            true
        }
        
        fn execute_withdrawal(
            ref self: ContractState,
            request_id: u64,
            btc_txid: felt252,
            guardian_signatures: Array<felt252>
        ) -> bool {
            // Check if caller is guardian
            let caller = get_caller_address();
            assert(self.accesscontrol.has_role(GUARDIAN_ROLE, caller), NOT_GUARDIAN);
            
            // Get request
            let mut request = self.withdrawal_requests.read(request_id);
            assert(request.request_id != 0, WITHDRAWAL_NOT_FOUND);
            
            // Check request status
            assert(request.status == WITHDRAWAL_STATUS_PROCESSING, WITHDRAWAL_INVALID_STATUS);
            
            // Check if not expired
            assert(get_block_timestamp() < request.expiry, WITHDRAWAL_EXPIRED);
            
            // Verify signatures (simplified - in production would verify each signature)
            // For hackathon, assume they're valid
            assert(guardian_signatures.len() >= request.required_signatures.into(), 
                   INSUFFICIENT_SIGNATURES);
            
            // Update request
            request.status = WITHDRAWAL_STATUS_COMPLETED;
            request.processed_at = get_block_timestamp();
            request.btc_txid = btc_txid;
            self.withdrawal_requests.write(request_id, request);
            
            // Emit event
            self.emit(WithdrawalProcessed {
                request_id: request_id,
                btc_txid: btc_txid,
                processed_by: caller,
                timestamp: get_block_timestamp(),
            });
            
            true
        }
        
        fn lock_utxo(
            ref self: ContractState,
            utxo_hash: felt252,
            swap_id: felt252,
            duration: u64
        ) -> bool {
            // Check if caller is whitelisted swap escrow
            let caller = get_caller_address();
            assert(self.whitelisted_swap_escrows.read(caller), UNAUTHORIZED_SWAP_ESCROW);
            
            // Validate duration
            assert!(duration >= MIN_LOCK_TIME && duration <= MAX_LOCK_TIME, "Invalid lock duration");
            
            // Get UTXO
            let mut utxo = self.utxos.read(utxo_hash);
            assert(!utxo.txid.is_zero(), UTXO_NOT_FOUND);
            
            // Check if UTXO is available
            assert(utxo.status == UTXO_STATUS_UNSPENT, UTXO_NOT_AVAILABLE);
            
            // Update UTXO status
            utxo.status = UTXO_STATUS_LOCKED;
            utxo.locked_until = get_block_timestamp() + duration;
            self.utxos.write(utxo_hash, utxo.clone());
            
            // Create swap lock
            let swap_lock: SwapLock = SwapLock {
                swap_id: swap_id,
                utxo_hash: utxo_hash,
                locked_at: get_block_timestamp(),
                expires_at: get_block_timestamp() + duration,
                locked_by: caller,
            };
            self.swap_locks.write(swap_id, swap_lock);
            
            // Update stats
            let mut stats = self.stats.read();
            stats.active_swaps += 1;
            stats.last_updated = get_block_timestamp();
            self.stats.write(stats);
            
            // Emit event
            self.emit(UTXOLocked {
                utxo_hash: utxo_hash,
                swap_id: swap_id,
                locked_until: utxo.locked_until,
                locked_by: caller,
                timestamp: get_block_timestamp(),
            });
            
            true
        }
        
        fn unlock_utxo(
            ref self: ContractState,
            utxo_hash: felt252,
            swap_id: felt252
        ) -> bool {
            // Check if caller is whitelisted swap escrow
            let caller = get_caller_address();
            assert(self.whitelisted_swap_escrows.read(caller), UNAUTHORIZED_SWAP_ESCROW);
            
            // Get UTXO
            let mut utxo: UTXO = self.utxos.read(utxo_hash);
            assert(!utxo.txid.is_zero(), UTXO_NOT_FOUND);
            
            // Check if UTXO is locked
            assert!(utxo.status == UTXO_STATUS_LOCKED, "UTXO not locked");
            
            // Update UTXO status
            utxo.status = UTXO_STATUS_UNSPENT;
            utxo.locked_until = 0;
            self.utxos.write(utxo_hash, utxo);
            
            // Remove swap lock
            self.swap_locks.write(swap_id, SwapLock {
                swap_id: 0,
                utxo_hash: 0,
                locked_at: 0,
                expires_at: 0,
                locked_by: get_contract_address(),
            });
            
            // Update stats
            let mut stats = self.stats.read();
            if stats.active_swaps > 0 {
                stats.active_swaps -= 1;
            }
            stats.last_updated = get_block_timestamp();
            self.stats.write(stats);
            
            // Emit event
            self.emit(UTXOUnlocked {
                utxo_hash: utxo_hash,
                swap_id: swap_id,
                timestamp: get_block_timestamp(),
            });
            
            true
        }
        
        fn spend_utxo(
            ref self: ContractState,
            utxo_hash: felt252,
            btc_txid: felt252
        ) -> bool {
            // Check if caller is guardian
            let caller = get_caller_address();
            assert(self.accesscontrol.has_role(GUARDIAN_ROLE, caller), NOT_GUARDIAN);
            
            // Get UTXO
            let mut utxo = self.utxos.read(utxo_hash);
            assert(!utxo.txid.is_zero(), UTXO_NOT_FOUND);
            
            // Check if UTXO is spent or locked
            assert(utxo.status != UTXO_STATUS_SPENT, UTXO_ALREADY_SPENT);
            
            // Update UTXO status
            utxo.status = UTXO_STATUS_SPENT;
            utxo.spent_at = get_block_timestamp();
            self.utxos.write(utxo_hash, utxo);
            
            // Emit event
            self.emit(UTXOSpent {
                utxo_hash: utxo_hash,
                txid: btc_txid,
                spent_at: get_block_timestamp(),
                spent_by: caller,
            });
            
            true
        }
        
        // View functions
        fn get_utxo(self: @ContractState, utxo_hash: felt252) -> UTXOResponse {
            let utxo = self.utxos.read(utxo_hash);
            assert(!utxo.txid.is_zero(), UTXO_NOT_FOUND);
            utxo_to_response(utxo)
        }
        
        fn get_withdrawal_request(self: @ContractState, request_id: u64) -> WithdrawalRequestResponse {
            let request = self.withdrawal_requests.read(request_id);
            assert(request.request_id != 0, WITHDRAWAL_NOT_FOUND);
            withdrawal_request_to_response(request)
        }
        
        fn get_vault_stats(self: @ContractState) -> VaultStats {
            self.stats.read()
        }
        
        fn get_user_utxos(self: @ContractState, user: ContractAddress, offset: u64, limit: u64) -> Array<UTXOResponse> {
            // let user_utxos = self.user_utxos.read(user);

            // let mut pseudoResult: Array<UTXO> = array![]; 

            let mut result: Array<UTXOResponse> = array![]; 


            let len: u64 = self.user_utxos.entry(user).len();

            // let mut result = ArrayTrait::new();
            
            let start: u64 = offset;
            let end: u64 = if offset + limit > len {
                // user_utxos.len()
                len
            } else {
                offset + limit
            };
            
            let mut i: u64 = start;
            while i < end {
                let utxo_hash: felt252 = self.user_utxos.entry(user).at(i).read();
                let utxo: UTXO = self.utxos.entry(utxo_hash).read().into();
                result.append(utxo_to_response(utxo));
                i += 1;
            };
            
            result
        }
        
        fn get_total_btc_locked(self: @ContractState) -> u256 {
            self.stats.read().total_btc_locked
        }
        
        fn is_guardian(self: @ContractState, guardian: ContractAddress) -> bool {
            self.accesscontrol.has_role(GUARDIAN_ROLE, guardian)
        }
        
        fn get_threshold(self: @ContractState) -> u8 {
            self.threshold.read()
        }
        
        fn get_guardian_count(self: @ContractState) -> u8 {
            self.guardian_count.read()
        }

        fn add_guardian(ref self: ContractState, guardian: ContractAddress) {
            // Only admin can add guardians
            assert(self.accesscontrol.has_role(ADMIN_ROLE, get_caller_address()), UNAUTHORIZED_GUARDIAN);
            
            // Check if guardian already exists
            assert(!self.guardians.read(guardian).is_active, GUARDIAN_ALREADY_EXISTS);
            
            // Check max guardians
            let current_count = self.guardian_count.read();
            assert(current_count < MAX_GUARDIANS, MAX_GUARDIANS_EXCEEDED);
            
            // Add guardian
            self.guardians.write(guardian, GuardianInfo {
                guardian: guardian,
                is_active: true,
                added_at: get_block_timestamp(),
                added_by: get_caller_address(),
                total_votes: 0,
            });
            
            // Add to list
            // let mut guardian_list = self.guardian_list.read();
            // guardian_list.append(guardian);
            // self.guardian_list.write(guardian_list);

            self.guardian_list.push(guardian);
            
            // Update count
            self.guardian_count.write(current_count + 1);
            
            // Grant role
            self.accesscontrol._grant_role(GUARDIAN_ROLE, guardian);
            
            // Emit event
            self.emit(GuardianAdded {
                guardian: guardian,
                added_by: get_caller_address(),
                timestamp: get_block_timestamp(),
            });
        }
        
        fn remove_guardian(ref self: ContractState, guardian: ContractAddress) {
            // Only admin can remove guardians
            assert(self.accesscontrol.has_role(ADMIN_ROLE, get_caller_address()), UNAUTHORIZED_GUARDIAN);
            
            // Check if guardian exists
            let mut info: GuardianInfo = self.guardians.read(guardian);
            assert(info.is_active, GUARDIAN_NOT_FOUND);
            
            // Cannot remove if threshold would become invalid
            let current_count = self.guardian_count.read();
            let current_threshold = self.threshold.read();
            assert!(current_count - 1 >= current_threshold, "Threshold too high for removal");
            
            // Deactivate guardian
            info.is_active = false;
            self.guardians.write(guardian, info);
            
            // Remove from list (simplified - in production would need proper removal)
            // For hackathon, we just deactivate
            
            // Update count
            self.guardian_count.write(current_count - 1);
            
            // Revoke role
            self.accesscontrol._revoke_role(GUARDIAN_ROLE, guardian);
            
            // Emit event
            self.emit(GuardianRemoved {
                guardian: guardian,
                removed_by: get_caller_address(),
                timestamp: get_block_timestamp(),
            });
        }
        
        fn set_threshold(ref self: ContractState, new_threshold: u8) {
            // Only admin can set threshold
            self.ownable.assert_only_owner();
            
            let guardian_count = self.guardian_count.read();
            assert(new_threshold <= guardian_count, THRESHOLD_TOO_HIGH);
            assert(new_threshold >= MIN_THRESHOLD, THRESHOLD_TOO_LOW);
            
            let old_threshold = self.threshold.read();
            self.threshold.write(new_threshold);
            
            // Emit event
            self.emit(ThresholdUpdated {
                old_threshold: old_threshold,
                new_threshold: new_threshold,
                updated_by: get_caller_address(),
                timestamp: get_block_timestamp(),
            });
        }
        
        fn whitelist_swap_escrow(ref self: ContractState, swap_escrow: ContractAddress) {
            // Only admin can whitelist
            self.ownable.assert_only_owner();
            
            self.whitelisted_swap_escrows.write(swap_escrow, true);
            
            // Grant role
            self.accesscontrol._grant_role(SWAP_ESCROW_ROLE, swap_escrow);
            
            self.emit(SwapEscrowWhitelisted {
                swap_escrow: swap_escrow,
                added_by: get_caller_address(),
                timestamp: get_block_timestamp(),
            });
        }
        
        fn remove_swap_escrow(ref self: ContractState, swap_escrow: ContractAddress) {
            // Only admin can remove
            self.ownable.assert_only_owner();
            
            self.whitelisted_swap_escrows.write(swap_escrow, false);
            
            // Revoke role
            self.accesscontrol._revoke_role(SWAP_ESCROW_ROLE, swap_escrow);
            
            self.emit(SwapEscrowRemoved {
                swap_escrow: swap_escrow,
                removed_by: get_caller_address(),
                timestamp: get_block_timestamp(),
            });
        }
        
        fn pause_vault(ref self: ContractState) {
            self.ownable.assert_only_owner();
            // self.paused.write(true);
            self.pausable.pause();
            
            self.emit(VaultPaused {
                paused_by: get_caller_address(),
                timestamp: get_block_timestamp(),
            });
        }
        
        fn unpause_vault(ref self: ContractState) {
            self.ownable.assert_only_owner();
            // self.paused.write(false);
            self.pausable.unpause();
            
            self.emit(VaultUnpaused {
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
}
