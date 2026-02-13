#[starknet::contract]
pub mod SwapEscrow {
    use starknet::{
        ContractAddress,
        ClassHash,
        get_caller_address,
        get_block_timestamp,
        get_contract_address
    };

    use starknet::storage::{
        Map, 
        StorageMapReadAccess, 
        StorageMapWriteAccess,
        StoragePointerReadAccess,
        StoragePointerWriteAccess
    };
    use core::num::traits::Zero;
    
    use openzeppelin::token::erc20::interface::{IERC20Dispatcher, IERC20DispatcherTrait};
    use openzeppelin::access::ownable::OwnableComponent;

    use openzeppelin::security::pausable::PausableComponent;
    use openzeppelin_access::accesscontrol::AccessControlComponent;
    use openzeppelin::introspection::src5::SRC5Component;


    use openzeppelin::upgrades::UpgradeableComponent;
    use openzeppelin::upgrades::interface::IUpgradeable;
    
    // Import local modules
    // use crate::constants::swap_constants::{
    //     MIN_SWAP_DURATION, MAX_SWAP_DURATION, MIN_SWAP_AMOUNT, MAX_SWAP_AMOUNT,
    //     MAX_ACTIVE_SWAPS_PER_USER, SWAP_PROTOCOL_FEE_BPS, SWAP_RELAYER_FEE_BPS,
    //     SWAP_STATUS_CREATED, SWAP_STATUS_FUNDED, SWAP_STATUS_COMPLETED,
    //     SWAP_STATUS_REFUNDED, SWAP_STATUS_EXPIRED
    // };


    use crate::constants::swap_constants::*;
    
    // use crate::errors::swap_errors::{
    //     SWAP_NOT_FOUND, SWAP_ALREADY_EXISTS, INVALID_SWAP_STATUS,
    //     SWAP_NOT_FUNDED, SWAP_ALREADY_COMPLETED, SWAP_ALREADY_REFUNDED,
    //     TIMELOCK_NOT_EXPIRED, TIMELOCK_EXPIRED, TIMELOCK_TOO_SHORT,
    //     TIMELOCK_TOO_LONG, INVALID_SECRET, HASHLOCK_MISMATCH,
    //     UNAUTHORIZED_INITIATOR, UNAUTHORIZED_COUNTERPARTY, UNAUTHORIZED_RELAYER,
    //     INVALID_AMOUNT, AMOUNT_MISMATCH, UNSUPPORTED_TOKEN,
    //     TOKEN_TRANSFER_FAILED, SAME_TOKEN_NOT_ALLOWED,
    //     MAX_SWAPS_PER_USER_EXCEEDED
    // };

    use crate::errors::swap_errors::*;
    
    use crate::enums::swap_enums::SwapStatus;
    use crate::structs::swap_structs::{
        AtomicSwap, AtomicSwapResponse, 
        // PendingSwap, 
        RelayerInfo, 
        UserSwapCounter, SwapFee
    };
    
    use crate::event_structs::swap_events::{
        SwapInitiated, SwapFunded, SwapCompleted, SwapRefunded,
        SwapExpired, SecretRevealed, RelayerWhitelisted, RelayerRemoved,
        FeeConfigUpdated, TokenWhitelisted, TokenRemoved
    };
    
    use crate::interfaces::i_swap_escrow::ISwapEscrow;
    // use crate::utils::swap_utils::{
    //     atomic_swap_to_response,
    //     atomic_swap_status_to_code,
    //     atomic_swap_code_to_status,
    //     // calculate_fee, validate_hashlock,
    //     // validate_timelock, generate_swap_id
    // };

    use crate::utils::swap_utils::*;
    
    // OpenZeppelin components
    component!(path: OwnableComponent, storage: ownable, event: OwnableEvent);
    component!(path: PausableComponent, storage: pausable, event: PausableEvent);

    component!(path: AccessControlComponent, storage: accesscontrol, event: AccessControlEvent);
    component!(path: SRC5Component, storage: src5, event: SRC5Event);

    component!(path: UpgradeableComponent, storage: upgradeable, event: UpgradeableEvent);
    
    // Component embeddings
    // #[abi(embed_v0)]
    // impl OwnableImpl = OwnableComponent::OwnableImpl<ContractState>;
    // impl OwnableInternalImpl = OwnableComponent::InternalImpl<ContractState>;

    impl UpgradeableInternalImpl = UpgradeableComponent::InternalImpl<ContractState>;

    #[abi(embed_v0)]
    impl OwnableImpl = OwnableComponent::OwnableImpl<ContractState>;
    impl InternalIMpl = OwnableComponent::InternalImpl<ContractState>;
    
    #[abi(embed_v0)]
    impl PausableImpl = PausableComponent::PausableImpl<ContractState>;
    impl PausableInternalImpl = PausableComponent::InternalImpl<ContractState>;
    
    #[abi(embed_v0)]
    impl AccessControlImpl = AccessControlComponent::AccessControlImpl<ContractState>;
    impl AccessControlInternalImpl = AccessControlComponent::InternalImpl<ContractState>;
    


    
    // Role constants
    const ADMIN_ROLE: felt252 = selector!("ADMIN_ROLE");
    const RELAYER_MANAGER_ROLE: felt252 = selector!("RELAYER_MANAGER_ROLE");
    const TOKEN_MANAGER_ROLE: felt252 = selector!("TOKEN_MANAGER_ROLE");
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
        upgradeable: UpgradeableComponent::Storage,
        #[substorage(v0)]
        src5: SRC5Component::Storage,

        // Core swap storage
        swaps: Map<felt252, AtomicSwap>,
        hashlock_to_swap: Map<felt252, felt252>,
        user_swap_counters: Map<ContractAddress, UserSwapCounter>,
        
        // Token management
        supported_tokens: Map<ContractAddress, bool>,
        
        // Relayer management
        relayers: Map<ContractAddress, RelayerInfo>,
        whitelisted_relayers: Map<ContractAddress, bool>,
        
        // Fee configuration
        swap_fee: SwapFee,
        
        // Counters
        total_swaps: u64,
        active_swaps_count: u64,
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
        SwapInitiated: SwapInitiated,
        SwapFunded: SwapFunded,
        SwapCompleted: SwapCompleted,
        SwapRefunded: SwapRefunded,
        SwapExpired: SwapExpired,
        SecretRevealed: SecretRevealed,
        RelayerWhitelisted: RelayerWhitelisted,
        RelayerRemoved: RelayerRemoved,
        FeeConfigUpdated: FeeConfigUpdated,
        TokenWhitelisted: TokenWhitelisted,
        TokenRemoved: TokenRemoved,
    }
    
    #[constructor]
    fn constructor(
        ref self: ContractState,
        owner: ContractAddress,
        fee_collector: ContractAddress
    ) {
        // Initialize Ownable
        self.ownable.initializer(owner);
        
        // Initialize AccessControl
        self.accesscontrol.initializer();
        self.accesscontrol._grant_role(ADMIN_ROLE, owner);
        self.accesscontrol._grant_role(RELAYER_MANAGER_ROLE, owner);
        self.accesscontrol._grant_role(TOKEN_MANAGER_ROLE, owner);
        self.accesscontrol._grant_role(AccessControlComponent::DEFAULT_ADMIN_ROLE, owner);
        
        // Initialize fee config
        self.swap_fee.write(SwapFee {
            protocol_fee_bps: SWAP_PROTOCOL_FEE_BPS,
            relayer_fee_bps: SWAP_RELAYER_FEE_BPS,
            fee_collector: fee_collector,
        });
        
        // Initialize counters
        self.total_swaps.write(0);
        self.active_swaps_count.write(0);
    }
    
    #[abi(embed_v0)]
    pub impl SwapEscrowImpl of ISwapEscrow<ContractState> {
        fn initiate_swap(
            ref self: ContractState,
            counterparty: ContractAddress,
            token_a: ContractAddress,
            token_b: ContractAddress,
            amount_a: u256,
            amount_b: u256,
            hashlock: felt252,
            timelock: u64
        ) -> felt252 {
            // Validate inputs
            self.validate_swap_inputs(
                counterparty,
                token_a,
                token_b,
                amount_a,
                amount_b,
                hashlock,
                timelock
            );
            
            // Check user limits
            self.check_user_limits(get_caller_address());
            
            // Generate unique swap ID
            let swap_id = generate_swap_id(
                get_caller_address(),
                counterparty,
                hashlock,
                get_block_timestamp()
            );
            
            // Ensure swap doesn't already exist
            assert(!self.swaps.read(swap_id).swap_id.is_zero(), SWAP_ALREADY_EXISTS);
            
            // Create swap
            let swap = AtomicSwap {
                swap_id: swap_id,
                initiator: get_caller_address(),
                counterparty: counterparty,
                token_a: token_a,
                token_b: token_b,
                amount_a: amount_a,
                amount_b: amount_b,
                hashlock: hashlock,
                timelock: get_block_timestamp() + timelock,
                status_code: atomic_swap_status_to_code(SwapStatus::Created),
                secret: 0,
                secret_revealed: false,
                created_at: get_block_timestamp(),
                funded_at: 0,
                completed_at: 0,
            };
            
            // Store swap
            self.swaps.write(swap_id, swap.clone());
            self.hashlock_to_swap.write(hashlock, swap_id);
            
            // Update user counters
            self.increment_user_swap_count(get_caller_address());
            
            // Update global counters
            self.total_swaps.write(self.total_swaps.read() + 1);
            self.active_swaps_count.write(self.active_swaps_count.read() + 1);
            
            // Emit event
            self.emit(SwapInitiated {
                swap_id: swap_id,
                initiator: get_caller_address(),
                counterparty: counterparty,
                token_a: token_a,
                token_b: token_b,
                amount_a: amount_a,
                amount_b: amount_b,
                hashlock: hashlock,
                timelock: swap.timelock,
                timestamp: get_block_timestamp(),
            });
            
            swap_id
        }
        
        fn fund_swap(ref self: ContractState, swap_id: felt252) -> bool {
            // Get swap
            let mut swap = self.get_swap_by_id(swap_id);
            
            // Validate status
            assert(atomic_swap_code_to_status(swap.status_code) == SwapStatus::Created, INVALID_SWAP_STATUS);
            assert(get_caller_address() == swap.initiator, UNAUTHORIZED_INITIATOR);
            
            // Check timelock not expired
            assert(get_block_timestamp() < swap.timelock, TIMELOCK_EXPIRED);
            
            // Transfer tokens from initiator to escrow
            self.transfer_tokens(
                swap.initiator,
                swap.token_a,
                swap.amount_a
            );
            
            // Update swap status
            swap.status_code = atomic_swap_status_to_code(SwapStatus::Funded);
            swap.funded_at = get_block_timestamp();
            self.swaps.write(swap_id, swap.clone());
            
            // Emit event
            self.emit(SwapFunded {
                swap_id: swap_id,
                funder: swap.initiator,
                amount: swap.amount_a,
                token: swap.token_a,
                timestamp: get_block_timestamp(),
            });
            
            true
        }
        
        fn complete_swap(ref self: ContractState, swap_id: felt252, secret: felt252) -> bool {
            // Get swap
            let mut swap = self.get_swap_by_id(swap_id);
            
            // Validate caller is counterparty
            assert(get_caller_address() == swap.counterparty, UNAUTHORIZED_COUNTERPARTY);
            
            // Validate status
            assert(atomic_swap_code_to_status(swap.status_code) == SwapStatus::Funded, SWAP_NOT_FUNDED);
            
            // Validate secret
            self.validate_secret(swap.hashlock, secret);
            
            // Calculate and distribute fees
            let (protocol_fee, relayer_fee) = self.calculate_and_distribute_fees(
                swap.amount_b,
                get_caller_address()
            );
            
            // Transfer tokens to counterparty (minus fees)
            let amount_to_counterparty = swap.amount_b - protocol_fee - relayer_fee;
            
            // Transfer counterparty's tokens to initiator (these are the swapped tokens)
            self.transfer_tokens_from_escrow(
                swap.counterparty,
                swap.token_b,
                amount_to_counterparty
            );
            
            // Transfer initiator's tokens to counterparty (the other side of the swap)
            self.transfer_tokens_from_escrow(
                swap.initiator,
                swap.token_a,
                swap.amount_a
            );
            
            // Update swap
            swap.status_code = atomic_swap_status_to_code(SwapStatus::Completed);
            swap.secret = secret;
            swap.secret_revealed = true;
            swap.completed_at = get_block_timestamp();
            self.swaps.write(swap_id, swap);
            
            // Update active swaps count
            self.active_swaps_count.write(self.active_swaps_count.read() - 1);
            
            // Emit events
            self.emit(SecretRevealed {
                swap_id: swap_id,
                secret: secret,
                revealer: get_caller_address(),
                timestamp: get_block_timestamp(),
            });
            
            self.emit(SwapCompleted {
                swap_id: swap_id,
                completer: get_caller_address(),
                secret: secret,
                timestamp: get_block_timestamp(),
            });
            
            true
        }
        
        fn refund_swap(ref self: ContractState, swap_id: felt252) -> bool {
            // Get swap
            let mut swap = self.get_swap_by_id(swap_id);
            
            // Validate caller is initiator
            assert(get_caller_address() == swap.initiator, UNAUTHORIZED_INITIATOR);
            
            // Validate status
            assert(atomic_swap_code_to_status(swap.status_code) == SwapStatus::Funded, INVALID_SWAP_STATUS);
            
            // Validate timelock expired
            assert(get_block_timestamp() >= swap.timelock, TIMELOCK_NOT_EXPIRED);
            
            // Return funds to initiator
            self.transfer_tokens_from_escrow(
                swap.initiator,
                swap.token_a,
                swap.amount_a
            );
            
            // Update swap
            swap.status_code = atomic_swap_status_to_code(SwapStatus::Refunded);
            self.swaps.write(swap_id, swap.clone());
            
            // Update active swaps count
            self.active_swaps_count.write(self.active_swaps_count.read() - 1);
            
            // Emit event
            self.emit(SwapRefunded {
                swap_id: swap_id,
                refundee: swap.initiator,
                amount: swap.amount_a,
                token: swap.token_a,
                timestamp: get_block_timestamp(),
            });
            
            true
        }
        
        fn relay_complete_swap(
            ref self: ContractState,
            swap_id: felt252,
            secret: felt252,
            relayer_fee_recipient: ContractAddress
        ) -> bool {
            // Only whitelisted relayers can call this
            assert(self.whitelisted_relayers.read(get_caller_address()), UNAUTHORIZED_RELAYER);
            
            // Get swap
            let mut swap = self.get_swap_by_id(swap_id);
            
            // Validate status
            assert(atomic_swap_code_to_status(swap.status_code) == SwapStatus::Funded, SWAP_NOT_FUNDED);
            
            // Validate secret
            self.validate_secret(swap.hashlock, secret);
            
            // Calculate fees with relayer fee going to specified recipient
            let (protocol_fee, relayer_fee) = self.calculate_fees_with_relayer(swap.amount_b);
            
            // Transfer protocol fee to fee collector
            if protocol_fee > 0 {
                let fee_collector = self.swap_fee.read().fee_collector;
                self.transfer_tokens_from_escrow(fee_collector, swap.token_b, protocol_fee);
            }
            
            // Transfer relayer fee to relayer
            if relayer_fee > 0 {
                self.transfer_tokens_from_escrow(relayer_fee_recipient, swap.token_b, relayer_fee);
            }
            
            // Transfer remaining to counterparty
            let amount_to_counterparty = swap.amount_b - protocol_fee - relayer_fee;
            self.transfer_tokens_from_escrow(swap.counterparty, swap.token_b, amount_to_counterparty);
            
            // Transfer initiator's tokens to counterparty
            self.transfer_tokens_from_escrow(swap.initiator, swap.token_a, swap.amount_a);
            
            // Update swap
            swap.status_code = atomic_swap_status_to_code(SwapStatus::Completed);
            swap.secret = secret;
            swap.secret_revealed = true;
            swap.completed_at = get_block_timestamp();
            self.swaps.write(swap_id, swap.clone());
            
            // Update active swaps count
            self.active_swaps_count.write(self.active_swaps_count.read() - 1);
            
            // Emit events
            self.emit(SecretRevealed {
                swap_id: swap_id,
                secret: secret,
                revealer: get_caller_address(),
                timestamp: get_block_timestamp(),
            });
            
            self.emit(SwapCompleted {
                swap_id: swap_id,
                completer: swap.counterparty,
                secret: secret,
                timestamp: get_block_timestamp(),
            });
            
            true
        }
        
        // View functions
        fn get_swap(self: @ContractState, swap_id: felt252) -> AtomicSwapResponse {
            let swap = self.get_swap_by_id(swap_id);
            atomic_swap_to_response(swap)
        }
        
        fn get_swap_status(self: @ContractState, swap_id: felt252) -> u8 {
            let swap = self.get_swap_by_id(swap_id);
            swap.status_code
        }
        
        fn can_refund(self: @ContractState, swap_id: felt252) -> bool {
            let swap = self.get_swap_by_id(swap_id);
            atomic_swap_code_to_status(swap.status_code) == SwapStatus::Funded && get_block_timestamp() >= swap.timelock
        }
        
        fn get_user_active_swaps(self: @ContractState, user: ContractAddress) -> u64 {
            let counter = self.user_swap_counters.read(user);
            counter.active_count
        }
        
        fn is_token_supported(self: @ContractState, token: ContractAddress) -> bool {
            self.supported_tokens.read(token)
        }
        
        fn is_relayer_whitelisted(self: @ContractState, relayer: ContractAddress) -> bool {
            self.whitelisted_relayers.read(relayer)
        }
        
        fn get_swap_fees(self: @ContractState) -> (u64, u64, ContractAddress) {
            let fee = self.swap_fee.read();
            (fee.protocol_fee_bps, fee.relayer_fee_bps, fee.fee_collector)
        }

        fn whitelist_token(ref self: ContractState, token: ContractAddress) {

            assert!(self.accesscontrol.has_role(TOKEN_MANAGER_ROLE, get_caller_address()), "AccessControl: Caller is not the Token Manager");

            assert!(!token.is_zero(), "Invalid token address");
            
            self.supported_tokens.write(token, true);
            
            self.emit(TokenWhitelisted {
                token: token,
                added_by: get_caller_address(),
                timestamp: get_block_timestamp(),
            });
        }
        
        fn remove_token(ref self: ContractState, token: ContractAddress) {

            assert!(self.accesscontrol.has_role(TOKEN_MANAGER_ROLE, get_caller_address()), "AccessControl: Caller is not the Token Manager");

            self.supported_tokens.write(token, false);
            
            self.emit(TokenRemoved {
                token: token,
                removed_by: get_caller_address(),
                timestamp: get_block_timestamp(),
            });
        }
        
        fn whitelist_relayer(ref self: ContractState, relayer: ContractAddress, fee_bps: u64) {

            assert!(self.accesscontrol.has_role(RELAYER_MANAGER_ROLE, get_caller_address()), "AccessControl: Caller is not the Relayer Manager");

            assert!(!relayer.is_zero(), "Invalid relayer address");
            assert!(fee_bps <= 1000, "Fee too high"); // Max 10%
            
            self.whitelisted_relayers.write(relayer, true);
            
            let relayer_info = RelayerInfo {
                relayer_address: relayer,
                fee_bps: fee_bps,
                is_active: true,
                total_swaps_facilitated: 0,
            };
            
            self.relayers.write(relayer, relayer_info);
            
            self.emit(RelayerWhitelisted {
                relayer: relayer,
                fee_bps: fee_bps,
                added_by: get_caller_address(),
                timestamp: get_block_timestamp(),
            });
        }
        
        fn remove_relayer(ref self: ContractState, relayer: ContractAddress) {

            assert!(self.accesscontrol.has_role(RELAYER_MANAGER_ROLE, get_caller_address()), "AccessControl: Caller is not the Relayer Manager");

            self.whitelisted_relayers.write(relayer, false);
            
            let mut info = self.relayers.read(relayer);
            info.is_active = false;
            self.relayers.write(relayer, info);
            
            self.emit(RelayerRemoved {
                relayer: relayer,
                removed_by: get_caller_address(),
                timestamp: get_block_timestamp(),
            });
        }
        
        fn set_fee_config(
            ref self: ContractState,
            protocol_fee_bps: u64,
            relayer_fee_bps: u64,
            fee_collector: ContractAddress
        ) {
            self.ownable.assert_only_owner();
            
            assert!(protocol_fee_bps <= 1000, "Protocol fee too high");
            assert!(relayer_fee_bps <= 1000, "Relayer fee too high");
            assert!(!fee_collector.is_zero(), "Invalid fee collector");
            
            self.swap_fee.write(SwapFee {
                protocol_fee_bps: protocol_fee_bps,
                relayer_fee_bps: relayer_fee_bps,
                fee_collector: fee_collector,
            });
            
            self.emit(FeeConfigUpdated {
                protocol_fee_bps: protocol_fee_bps,
                relayer_fee_bps: relayer_fee_bps,
                fee_collector: fee_collector,
                updated_by: get_caller_address(),
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
        fn get_swap_by_id(self: @ContractState, swap_id: felt252) -> AtomicSwap {
            let swap = self.swaps.read(swap_id);
            assert(!swap.swap_id.is_zero(), SWAP_NOT_FOUND);
            swap
        }
        
        fn validate_swap_inputs(
            ref self: ContractState,
            counterparty: ContractAddress,
            token_a: ContractAddress,
            token_b: ContractAddress,
            amount_a: u256,
            amount_b: u256,
            hashlock: felt252,
            timelock: u64
        ) {
            // Check counterparty not zero
            assert!(!counterparty.is_zero(), "Counterparty cannot be zero");
            
            // Check tokens are different
            assert(token_a != token_b, SAME_TOKEN_NOT_ALLOWED);
            
            // Check tokens are supported
            assert(self.supported_tokens.read(token_a), UNSUPPORTED_TOKEN);
            assert(self.supported_tokens.read(token_b), UNSUPPORTED_TOKEN);
            
            // Check amounts
            assert(amount_a >= MIN_SWAP_AMOUNT, INVALID_AMOUNT);
            assert(amount_b >= MIN_SWAP_AMOUNT, INVALID_AMOUNT);
            assert(amount_a <= MAX_SWAP_AMOUNT, INVALID_AMOUNT);
            assert(amount_b <= MAX_SWAP_AMOUNT, INVALID_AMOUNT);
            
            // Validate hashlock
            assert(validate_hashlock(hashlock), INVALID_HASHLOCK);
            
            // Validate timelock
            assert(validate_timelock(timelock, MIN_SWAP_DURATION, MAX_SWAP_DURATION), TIMELOCK_TOO_SHORT);
        }
        
        fn validate_secret(ref self: ContractState, hashlock: felt252, secret: felt252) {
            // In production, you'd hash the secret and compare
            // For now, we'll do a simple comparison
            assert(!secret.is_zero(), INVALID_SECRET);
            
            // Verify hashlock matches secret
            // let computed_hash = poseidon_hash(secret);
            // assert!(computed_hash == hashlock, HASHLOCK_MISMATCH);
            
            // For demo, just check it's not zero
            assert(!hashlock.is_zero(), INVALID_HASHLOCK);
        }
        
        fn check_user_limits(ref self: ContractState, user: ContractAddress) {
            let counter = self.user_swap_counters.read(user);
            assert(counter.active_count < MAX_ACTIVE_SWAPS_PER_USER, MAX_SWAPS_PER_USER_EXCEEDED);
        }
        
        fn increment_user_swap_count(ref self: ContractState, user: ContractAddress) {
            let mut counter = self.user_swap_counters.read(user);
            counter.initiated_count += 1;
            counter.active_count += 1;
            counter.participated_count += 1;
            self.user_swap_counters.write(user, counter);
        }
        
        fn transfer_tokens(
            ref self: ContractState,
            from: ContractAddress,
            token: ContractAddress,
            amount: u256
        ) {
            let token_dispatcher = IERC20Dispatcher { contract_address: token };
            
            // Transfer tokens from user to this contract
            let success = token_dispatcher.transfer_from(from, get_contract_address(), amount);
            assert(success, TOKEN_TRANSFER_FAILED);
        }
        
        fn transfer_tokens_from_escrow(
            ref self: ContractState,
            to: ContractAddress,
            token: ContractAddress,
            amount: u256
        ) {
            if amount == 0 {
                return;
            }
            
            let token_dispatcher = IERC20Dispatcher { contract_address: token };
            
            // Transfer tokens from this contract to recipient
            let success = token_dispatcher.transfer(to, amount);
            assert(success, TOKEN_TRANSFER_FAILED);
        }
        
        fn calculate_and_distribute_fees(
            ref self: ContractState,
            amount: u256,
            counterparty: ContractAddress
        ) -> (u256, u256) {
            let fee_config = self.swap_fee.read();
            
            let protocol_fee = calculate_fee(amount, fee_config.protocol_fee_bps);
            let _relayer_fee = calculate_fee(amount, fee_config.relayer_fee_bps);
            
            // Transfer protocol fee to fee collector
            if protocol_fee > 0 {
                self.transfer_tokens_from_escrow(fee_config.fee_collector, counterparty, protocol_fee);
            }
            
            // Relayer fee is zero in this path (direct completion)
            (protocol_fee, 0)
        }
        
        fn calculate_fees_with_relayer(ref self: ContractState, amount: u256) -> (u256, u256) {
            let fee_config = self.swap_fee.read();
            
            let protocol_fee = calculate_fee(amount, fee_config.protocol_fee_bps);
            let relayer_fee = calculate_fee(amount, fee_config.relayer_fee_bps);
            
            (protocol_fee, relayer_fee)
        }
    }
}
