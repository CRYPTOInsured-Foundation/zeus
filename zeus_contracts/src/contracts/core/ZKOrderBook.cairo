#[starknet::contract]
pub mod ZKOrderBook {
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
    use core::poseidon::HashState;
    use core::hash::HashStateTrait;
    use core::array::SpanTrait;
    
    // OpenZeppelin imports
    use openzeppelin::access::ownable::OwnableComponent;
    use openzeppelin::security::pausable::PausableComponent;
    use openzeppelin_access::accesscontrol::AccessControlComponent;
    use openzeppelin::introspection::src5::SRC5Component;
    use openzeppelin::upgrades::UpgradeableComponent;
    use openzeppelin::upgrades::interface::IUpgradeable;
    
    // Import local modules
    use crate::constants::orderbook_constants::*;
    use crate::errors::orderbook_errors::*;
    use crate::structs::orderbook_structs::*;
    use crate::event_structs::orderbook_events::*;
    use crate::interfaces::i_zk_orderbook::IZKOrderBook;
    use crate::utils::orderbook_utils::*;
    
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
    const RELAYER_MANAGER_ROLE: felt252 = selector!("RELAYER_MANAGER_ROLE");
    const RELAYER_ROLE: felt252 = selector!("RELAYER_ROLE");
    const CLEANER_ROLE: felt252 = selector!("CLEANER_ROLE");
    
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
        
        // Order storage
        orders: Map<felt252, Order>,
        user_orders: Map<ContractAddress, Vec<felt252>>,
        active_orders_by_asset: Map<(u8, u8), Vec<felt252>>, // (asset_type, side) -> order_ids
        
        // Commitments and nullifiers
        commitments: Map<felt252, OrderCommitment>,
        nullifiers: Map<felt252, bool>,
        
        // Range proofs
        range_proofs: Map<felt252, RangeProof>,
        
        // Match storage
        matches: Map<felt252, Match>,
        order_matches: Map<felt252, Vec<felt252>>, // order_id -> match_ids
        
        // Merkle tree
        merkle_root: felt252,
        merkle_tree: Map<u32, MerkleNode>,
        
        // Relayer management
        relayers: Map<ContractAddress, RelayerInfo>,
        whitelisted_relayers: Map<ContractAddress, bool>,
        
        // User management
        user_info: Map<ContractAddress, UserOrderInfo>,
        blacklisted_users: Map<ContractAddress, bool>,
        
        // Statistics
        stats: OrderbookStats,
        
        // Counters
        order_counter: u64,
        match_counter: u64,
        
        // Paused state
        // paused: bool,
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
        OrderPlaced: OrderPlaced,
        OrderMatched: OrderMatched,
        OrderCancelled: OrderCancelled,
        OrderExpired: OrderExpired,
        BatchMatchExecuted: BatchMatchExecuted,
        CommitmentRevealed: CommitmentRevealed,
        RangeProofVerified: RangeProofVerified,
        MerkleRootUpdated: MerkleRootUpdated,
        RelayerWhitelisted: RelayerWhitelisted,
        RelayerRemoved: RelayerRemoved,
        OrderbookPaused: OrderbookPaused,
        OrderbookUnpaused: OrderbookUnpaused,
        UserBlacklisted: UserBlacklisted,
        UserWhitelisted: UserWhitelisted,
        CleanupExecuted: CleanupExecuted,
    }
    
    #[constructor]
    fn constructor(
        ref self: ContractState,
        owner: ContractAddress,
        // initial_relayers: Array<ContractAddress>
    ) {
        // Initialize Ownable
        self.ownable.initializer(owner);
        
        // Initialize AccessControl
        self.accesscontrol.initializer();
        self.accesscontrol._grant_role(ADMIN_ROLE, owner);
        self.accesscontrol._grant_role(RELAYER_MANAGER_ROLE, owner);
        self.accesscontrol._grant_role(CLEANER_ROLE, owner);
        self.accesscontrol._grant_role(AccessControlComponent::DEFAULT_ADMIN_ROLE, owner);
        
        // Initialize relayers
        // let mut i = 0;
        // loop {
        //     match initial_relayers.get(i) {
        //         Option::Some(relayer) => {
        //             self.relayers.write(relayer, RelayerInfo {
        //                 relayer: relayer,
        //                 fee_bps: RELAYER_FEE_BPS,
        //                 is_active: true,
        //                 total_matches: 0,
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
        
        // Initialize stats
        self.stats.write(OrderbookStats {
            total_orders: 0,
            active_orders: 0,
            total_matches: 0,
            total_volume: 0,
            total_fees_collected: 0,
            last_match_at: 0,
            last_cleanup_at: get_block_timestamp(),
        });
        
        // Initialize merkle root
        self.merkle_root.write(EMPTY_HASH);
        
        // Initialize counters
        self.order_counter.write(0);
        self.match_counter.write(0);
        // self.paused.write(false);
    }
    
    #[abi(embed_v0)]
    impl ZKOrderBookImpl of IZKOrderBook<ContractState> {
        fn place_order(
            ref self: ContractState,
            asset_type: u8,
            side: u8,
            amount_commitment: felt252,
            price_commitment: felt252,
            range_proof: Array<felt252>,
            expiry: u64
        ) -> felt252 {
            // Check if orderbook is paused
            // assert(!self.paused.read(), ORDERBOOK_PAUSED);
            self.pausable.assert_not_paused();
            
            // Validate inputs
            assert(asset_type <= ASSET_TYPE_ZKBTC, UNSUPPORTED_ASSET);
            assert(side == ORDER_SIDE_BUY || side == ORDER_SIDE_SELL, ORDER_INVALID_SIDE);
            assert(!amount_commitment.is_zero(), INVALID_COMMITMENT);
            assert(!price_commitment.is_zero(), INVALID_PRICE);
            
            // Validate expiry
            assert(expiry >= MIN_ORDER_EXPIRY && expiry <= MAX_ORDER_EXPIRY, INVALID_EXPIRY);
            
            let caller = get_caller_address();
            let current_time = get_block_timestamp();
            let expiry_time = current_time + expiry;
            
            // Check user not blacklisted
            assert(!self.blacklisted_users.read(caller), USER_BLACKLISTED);
            
            // Check user order limits
            let mut user_info = self.user_info.read(caller);
            assert(user_info.total_orders < MAX_ORDERS_PER_USER, MAX_ORDERS_PER_USER_EXCEEDED);
            assert(user_info.active_orders < MAX_ACTIVE_ORDERS_PER_USER, MAX_ACTIVE_ORDERS_EXCEEDED);
            
            // Verify range proof
            assert(self.verify_range_proof(range_proof, amount_commitment), INVALID_RANGE_PROOF);
            
            // Generate nullifier
            let nullifier = generate_nullifier(caller, amount_commitment, current_time);
            assert(!self.nullifiers.read(nullifier), NULLIFIER_ALREADY_USED);
            
            // Generate order ID
            let order_id = generate_order_id(
                caller,
                asset_type,
                side,
                amount_commitment,
                current_time
            );
            
            // Create order
            let order = Order {
                order_id: order_id,
                owner: caller,
                asset_type: asset_type,
                side: side,
                amount_commitment: amount_commitment,
                price_commitment: price_commitment,
                expiry: expiry_time,
                created_at: current_time,
                status: ORDER_STATUS_ACTIVE,
                matched_amount: 0,
                remaining_amount: 0,
                nullifier: nullifier,
            };
            
            // Store order
            self.orders.write(order_id, order);
            self.nullifiers.write(nullifier, true);
            
            // Add to user's orders
            // let mut user_orders = self.user_orders.read(caller);
            // user_orders.append(order_id);
            // self.user_orders.write(caller, user_orders);
            self.user_orders.entry(caller).push(order_id);
            
            // Add to active orders by asset
            let key = (asset_type, side);
            // let mut asset_orders = self.active_orders_by_asset.read(key);
            // asset_orders.append(order_id);
            // self.active_orders_by_asset.write(key, asset_orders);
            self.active_orders_by_asset.entry(key).push(order_id);
            
            // Update user info
            user_info.total_orders += 1;
            user_info.active_orders += 1;
            user_info.last_order_at = current_time;
            self.user_info.write(caller, user_info);
            
            // Update stats
            let mut stats = self.stats.read();
            stats.total_orders += 1;
            stats.active_orders += 1;
            self.stats.write(stats);
            
            // Update counter
            let counter = self.order_counter.read() + 1;
            self.order_counter.write(counter);
            
            // Emit event
            self.emit(OrderPlaced {
                order_id: order_id,
                owner: caller,
                asset_type: asset_type,
                side: side,
                amount_commitment: amount_commitment,
                price_commitment: price_commitment,
                expiry: expiry_time,
                timestamp: current_time,
                nullifier: nullifier,
            });
            
            order_id
        }
        
        fn cancel_order(ref self: ContractState, order_id: felt252) -> bool {
            // Check if orderbook is paused
            // assert(!self.paused.read(), ORDERBOOK_PAUSED);
            self.pausable.assert_not_paused();
            
            let caller = get_caller_address();
            let mut order = self.get_order_by_id(order_id);
            
            // Check ownership
            assert(order.owner == caller, NOT_ORDER_OWNER);
            
            // Check if order can be cancelled
            assert(order.status == ORDER_STATUS_ACTIVE, ORDER_INVALID_STATUS);
            
            // Update order status
            order.status = ORDER_STATUS_CANCELLED;
            self.orders.write(order_id, order);
            
            // Update user active orders
            let mut user_info = self.user_info.read(caller);
            if user_info.active_orders > 0 {
                user_info.active_orders -= 1;
            }
            self.user_info.write(caller, user_info);
            
            // Update stats
            let mut stats = self.stats.read();
            if stats.active_orders > 0 {
                stats.active_orders -= 1;
            }
            self.stats.write(stats);
            
            // Emit event
            self.emit(OrderCancelled {
                order_id: order_id,
                owner: caller,
                timestamp: get_block_timestamp(),
                reason: 'USER_CANCELLED',
            });
            
            true
        }
        
        fn cancel_batch_orders(ref self: ContractState, order_ids: Array<felt252>) -> bool {
            // Check if orderbook is paused
            // assert(!self.paused.read(), ORDERBOOK_PAUSED);
            self.pausable.assert_not_paused();
            
            let caller = get_caller_address();
            let mut i = 0;
            
            while i < order_ids.len() {
                let order_id: felt252 = *order_ids.at(i);
                let mut order: Order = self.get_order_by_id(order_id);
                
                // Check ownership
                assert(order.owner == caller, NOT_ORDER_OWNER);
                
                // Check if order can be cancelled
                if order.clone().status == ORDER_STATUS_ACTIVE {
                    order.status = ORDER_STATUS_CANCELLED;
                    self.orders.write(order_id, order);
                    
                    // Update user active orders
                    let mut user_info: UserOrderInfo = self.user_info.read(caller);
                    if user_info.active_orders > 0 {
                        user_info.active_orders -= 1;
                    }
                    self.user_info.write(caller, user_info);
                    
                    // Update stats
                    let mut stats = self.stats.read();
                    if stats.active_orders > 0 {
                        stats.active_orders -= 1;
                    }
                    self.stats.write(stats);
                    
                    self.emit(OrderCancelled {
                        order_id: order_id,
                        owner: caller,
                        timestamp: get_block_timestamp(),
                        reason: 'BATCH_CANCELLED',
                    });
                }
                
                i += 1;
            };
            
            true
        }
        
        fn match_orders(
            ref self: ContractState,
            buy_order_ids: Array<felt252>,
            sell_order_ids: Array<felt252>,
            match_amounts: Array<u256>,
            match_prices: Array<u256>,
            zk_proof: Array<felt252>
        ) -> Array<felt252> {
            // Check if orderbook is paused
            // assert(!self.paused.read(), ORDERBOOK_PAUSED);
            self.pausable.assert_not_paused();
            
            // Check caller is whitelisted relayer
            let caller = get_caller_address();
            assert(self.whitelisted_relayers.read(caller), UNAUTHORIZED_RELAYER);
            
            // Validate input lengths
            assert(buy_order_ids.len() == sell_order_ids.len(), ORDER_MISMATCH);
            assert!(buy_order_ids.len() == match_amounts.len(), "Amount mismatch");
            assert!(buy_order_ids.len() == match_prices.len(), "Price mismatch");
            assert(buy_order_ids.len() <= MAX_MATCHES_PER_BATCH, MATCH_COUNT_EXCEEDED);
            
            // Verify ZK proof (simplified)
            assert(zk_proof.len() > 0, INVALID_MATCHING_PROOF);
            
            let mut match_ids = ArrayTrait::<felt252>::new();
            let mut total_volume: u256 = 0;
            let current_time = get_block_timestamp();
            
            let mut i = 0;
            while i < buy_order_ids.len() {
                let buy_order_id = *buy_order_ids[i];
                let sell_order_id = *sell_order_ids[i];
                let amount = *match_amounts[i];
                let price = *match_prices[i];
                
                // Get orders
                let mut buy_order: Order = self.get_order_by_id(buy_order_id);
                let mut sell_order: Order = self.get_order_by_id(sell_order_id);
                
                // Validate orders are active
                assert!(is_order_active(buy_order.status, buy_order.expiry, current_time), 
                       "Buy order not active");
                assert!(is_order_active(sell_order.status, sell_order.expiry, current_time), 
                       "Sell order not active");
                
                // Validate amounts
                assert(amount >= MIN_MATCH_AMOUNT, MATCH_AMOUNT_TOO_LOW);
                
                // Generate match ID
                let match_id = generate_match_id(buy_order_id, sell_order_id, current_time);
                
                // Create match
                let match_item = Match {
                    match_id: match_id,
                    buy_order_id: buy_order_id,
                    sell_order_id: sell_order_id,
                    matched_amount: amount,
                    match_price: price,
                    timestamp: current_time,
                    relayer: caller,
                    proof_hash: self.hash_public_inputs(zk_proof.span()),
                };
                
                self.matches.write(match_id, match_item);
                match_ids.append(match_id);
                
                // Update orders (simplified - in production would handle partial fills)
                buy_order.status = ORDER_STATUS_MATCHED;
                buy_order.matched_amount = amount;
                sell_order.status = ORDER_STATUS_MATCHED;
                sell_order.matched_amount = amount;
                
                self.orders.write(buy_order_id, buy_order);
                self.orders.write(sell_order_id, sell_order);
                
                // Update match tracking
                // let mut buy_matches = self.order_matches.read(buy_order_id);
                // buy_matches.append(match_id);
                // self.order_matches.write(buy_order_id, buy_matches);
                self.order_matches.entry(buy_order_id).push(match_id);
                
                // let mut sell_matches = self.order_matches.read(sell_order_id);
                // sell_matches.append(match_id);
                // self.order_matches.write(sell_order_id, sell_matches);
                self.order_matches.entry(sell_order_id).push(match_id);
                
                // Update volume
                total_volume += amount;
                
                // Emit match event
                self.emit(OrderMatched {
                    match_id: match_id,
                    buy_order_id: buy_order_id,
                    sell_order_id: sell_order_id,
                    matched_amount: amount,
                    match_price: price,
                    timestamp: current_time,
                    relayer: caller,
                });
                
                i += 1;
            };
            
            // Update stats
            let mut stats = self.stats.read();
            stats.total_matches += buy_order_ids.len().into();
            stats.total_volume += total_volume;
            stats.active_orders -= (buy_order_ids.len().into() * 2); // Both orders consumed
            stats.last_match_at = current_time;
            self.stats.write(stats);
            
            // Update relayer stats
            let mut relayer_info = self.relayers.read(caller);
            relayer_info.total_matches += buy_order_ids.len().into();
            relayer_info.total_volume += total_volume;
            self.relayers.write(caller, relayer_info);
            
            // Update match counter
            let counter: u64 = self.match_counter.read() + buy_order_ids.len().into();
            self.match_counter.write(counter);
            
            // Emit batch event
            self.emit(BatchMatchExecuted {
                batch_id: PoseidonTrait::new()
                    .update(caller.into())
                    .update(current_time.into())
                    .finalize(),
                match_count: buy_order_ids.len(),
                total_volume: total_volume,
                proof_hash: self.hash_public_inputs(zk_proof.span()),
                relayer: caller,
                timestamp: current_time,
            });
            
            match_ids
        }
        
        fn match_orders_batch(
            ref self: ContractState,
            buy_order_commitments: Array<felt252>,
            sell_order_commitments: Array<felt252>,
            match_amounts: Array<u256>,
            match_prices: Array<u256>,
            batch_proof: Array<felt252>,
            total_volume_commitment: felt252,
            fee_commitment: felt252,
            match_count: u32
        ) -> bool {
            // Check if orderbook is paused
            // assert(!self.paused.read(), ORDERBOOK_PAUSED);
            self.pausable.assert_not_paused();
            
            // Check caller is whitelisted relayer
            let caller = get_caller_address();
            assert(self.whitelisted_relayers.read(caller), UNAUTHORIZED_RELAYER);
            
            // Validate match count
            assert(match_count <= MAX_MATCHES_PER_BATCH, MATCH_COUNT_EXCEEDED);
            assert!(buy_order_commitments.len() == match_count, "Commitment count mismatch");
            
            // In production, would verify batch ZK proof
            // For hackathon, simplified verification
            assert(batch_proof.len() > 0, INVALID_MATCHING_PROOF);
            
            // Compute total volume from match amounts
            let mut total_volume: u256 = 0;
            let mut i = 0;
            while i < match_amounts.len() {
                total_volume += *match_amounts[i];
                i += 1;
            };
            
            // Verify volume commitment (simplified)
            let computed_commitment = PoseidonTrait::new()
                .update(total_volume.low.into())
                .update(total_volume.high.into())
                .finalize();
            
            assert(computed_commitment == total_volume_commitment, VOLUME_MISMATCH);
            
            // Emit batch event
            self.emit(BatchMatchExecuted {
                batch_id: PoseidonTrait::new()
                    .update(caller.into())
                    .update(get_block_timestamp().into())
                    .finalize(),
                match_count: match_count,
                total_volume: total_volume,
                proof_hash: self.hash_public_inputs(batch_proof.span()),
                relayer: caller,
                timestamp: get_block_timestamp(),
            });
            
            true
        }
        
        // View functions
        fn get_order(self: @ContractState, order_id: felt252) -> OrderResponse {
            let order = self.get_order_by_id(order_id);
            order_to_response(order)
        }
        
        fn get_user_orders(self: @ContractState, user: ContractAddress, offset: u64, limit: u64) -> Array<OrderResponse> {
            // let user_orders: Array<felt252> = self.user_orders.read(user);
            let mut user_orders: Array<felt252> = array![];
            let len: u64 = self.user_orders.entry(user).len();

            for i in 0..len {
                let each: felt252 = self.user_orders.entry(user).at(i).read();
                user_orders.append(each);
            };
            let mut result: Array<OrderResponse> = array![];
            
            let start: u64 = offset;
            let end: u64 = if (offset + limit).into() > len {
                len
            } else {
                offset + limit
            };
            
            let mut j: u32 = start.try_into().unwrap();
            while j < end.try_into().unwrap() {
                let order_id: felt252 = *user_orders.at(j);
                let order: Order = self.orders.read(order_id);
                result.append(order_to_response(order));
                j += 1;
            };
            
            result
        }
        
        fn get_active_orders(self: @ContractState, asset_type: u8, side: u8, offset: u64, limit: u64) -> Array<OrderResponse> {
            let key = (asset_type, side);
            // let active_orders = self.active_orders_by_asset.read(key);
            let mut active_orders: Array<felt252> = array![];

            let len: u64 = self.active_orders_by_asset.entry(key).len();

            for i in 0..len {
                let each: felt252 = self.active_orders_by_asset.entry(key).at(i).read();
                active_orders.append(each);
            };

            let mut result: Array<OrderResponse> = array![];
            let current_time = get_block_timestamp();
            
            let start: u64 = offset;
            let end: u64 = if offset + limit > len {
                len
            } else {
                offset + limit
            };
            
            let mut j: u32 = start.try_into().unwrap();
            while j < end.try_into().unwrap() {
                let order_id: felt252 = *active_orders.at(j);
                let order: Order = self.orders.read(order_id);
                
                // Only return active orders
                if is_order_active(order.status, order.expiry, current_time) {
                    result.append(order_to_response(order));
                }
                
                j += 1;
            };
            
            result
        }
        
        fn get_match(self: @ContractState, match_id: felt252) -> MatchResponse {
            let match_item: Match = self.matches.read(match_id);
            assert!(!match_item.match_id.is_zero(), "Match not found");
            match_to_response(match_item)
        }
        
        fn get_orderbook_stats(self: @ContractState) -> OrderbookStats {
            self.stats.read()
        }
        
        fn get_user_info(self: @ContractState, user: ContractAddress) -> UserOrderInfo {
            self.user_info.read(user)
        }
        
        fn verify_range_proof(self: @ContractState, proof: Array<felt252>, commitment: felt252) -> bool {
            // In production, would verify actual range proof
            // For hackathon, simplified verification
            verify_range_proof_simple(proof.span(), commitment)
        }
        
        fn verify_order_ownership(self: @ContractState, order_id: felt252, user: ContractAddress) -> bool {
            let order = self.orders.read(order_id);
            !order.order_id.is_zero() && order.owner == user
        }
        
        // Admin functions
        fn whitelist_relayer(ref self: ContractState, relayer: ContractAddress, fee_bps: u64) {
            assert!(self.accesscontrol.has_role(RELAYER_MANAGER_ROLE, get_caller_address()), "Caller does not have the Relayer Manager Role");
            
            assert!(!relayer.is_zero(), "Invalid relayer");
            assert!(fee_bps <= 1000, "Fee too high");
            
            self.relayers.write(relayer, RelayerInfo {
                relayer: relayer,
                fee_bps: fee_bps,
                is_active: true,
                total_matches: 0,
                total_volume: 0,
                whitelisted: true,
            });
            
            self.whitelisted_relayers.write(relayer, true);
            self.accesscontrol._grant_role(RELAYER_ROLE, relayer);
            
            self.emit(RelayerWhitelisted {
                relayer: relayer,
                fee_bps: fee_bps,
                added_by: get_caller_address(),
                timestamp: get_block_timestamp(),
            });
        }
        
        fn remove_relayer(ref self: ContractState, relayer: ContractAddress) {
            assert!(self.accesscontrol.has_role(RELAYER_MANAGER_ROLE, get_caller_address()), "Caller does not have role Relayer Manager Role");
            
            self.whitelisted_relayers.write(relayer, false);
            
            let mut info: RelayerInfo = self.relayers.read(relayer);
            info.whitelisted = false;
            info.is_active = false;
            self.relayers.write(relayer, info);
            
            self.accesscontrol._revoke_role(RELAYER_ROLE, relayer);
            
            self.emit(RelayerRemoved {
                relayer: relayer,
                removed_by: get_caller_address(),
                timestamp: get_block_timestamp(),
            });
        }
        
        fn blacklist_user(ref self: ContractState, user: ContractAddress) {

            assert!(self.accesscontrol.has_role(ADMIN_ROLE, get_caller_address()), "Caller does not have Admin Role");
            
            self.blacklisted_users.write(user, true);
            
            // Cancel all active orders for user
            // let user_orders = self.user_orders.read(user);
            let mut user_orders: Array<felt252> = array![];
            let len: u64 = self.user_orders.entry(user).len();

            for i in 0..len {
                let each: felt252 = self.user_orders.entry(user).at(i).read();

                user_orders.append(each);
            };
            
            let mut j: u32 = 0;
            while j < len.try_into().unwrap() {
                let order_id = *user_orders.at(j);
                let mut order = self.orders.read(order_id);
                
                if order.clone().status == ORDER_STATUS_ACTIVE {
                    order.status = ORDER_STATUS_CANCELLED;
                    self.orders.write(order_id, order);
                }
                
                j += 1;
            };
            
            // Update user info
            let mut user_info = self.user_info.read(user);
            user_info.active_orders = 0;
            self.user_info.write(user, user_info);
            
            self.emit(UserBlacklisted {
                user: user,
                blacklisted_by: get_caller_address(),
                timestamp: get_block_timestamp(),
            });
        }
        
        fn whitelist_user(ref self: ContractState, user: ContractAddress) {
            assert!(self.accesscontrol.has_role(ADMIN_ROLE, get_caller_address()), "Caller is not the Admin");
            
            self.blacklisted_users.write(user, false);
            
            self.emit(UserWhitelisted {
                user: user,
                whitelisted_by: get_caller_address(),
                timestamp: get_block_timestamp(),
            });
        }
        
        fn pause_orderbook(ref self: ContractState) {
            self.ownable.assert_only_owner();
            // self.paused.write(true);
            self.pausable.pause();
            
            self.emit(OrderbookPaused {
                paused_by: get_caller_address(),
                timestamp: get_block_timestamp(),
            });
        }
        
        fn unpause_orderbook(ref self: ContractState) {
            self.ownable.assert_only_owner();
            // self.paused.write(false);
            self.pausable.unpause();
            
            self.emit(OrderbookUnpaused {
                unpaused_by: get_caller_address(),
                timestamp: get_block_timestamp(),
            });
        }
        
        fn cleanup_expired_orders(ref self: ContractState) -> u64 {
           assert!(self.accesscontrol.has_role(CLEANER_ROLE, get_caller_address()), "Caller does not have the Cleaner Role");
            
            let current_time = get_block_timestamp();
            let mut expired_count = 0;
            
            // Iterate through all assets and sides
            // This is simplified - in production would have more efficient indexing
            let asset_types = array![
                ASSET_TYPE_BTC, ASSET_TYPE_STRK, ASSET_TYPE_ETH, 
                ASSET_TYPE_USDC, ASSET_TYPE_ZKBTC
            ];
            let sides = array![ORDER_SIDE_BUY, ORDER_SIDE_SELL];
            
            let mut a = 0;
            while a < asset_types.len() {
                let asset_type = *asset_types[a];
                
                let mut s = 0;
                while s < sides.len() {
                    let side = *sides[s];
                    let key = (asset_type, side);
                    // let active_orders = self.active_orders_by_asset.read(key);
                    let mut active_orders: Array<felt252> = array![];

                    let len: u64 = self.active_orders_by_asset.entry(key).len();

                    for i in 0..len {
                        let each: felt252 = self.active_orders_by_asset.entry(key).at(i).read();

                        active_orders.append(each);
                    }

                    
                    // let mut new_active: felt = VecTrait::new();
                    let mut j: u32 = 0;
                    
                    while j < active_orders.len() {
                        let order_id: felt252 = *active_orders.at(j);
                        let order: Order = self.orders.read(order_id);
                        
                        if is_order_expired(order.expiry, current_time) {
                            // Mark as expired
                            let mut expired_order: Order = order.clone();
                            expired_order.status = ORDER_STATUS_EXPIRED;
                            self.orders.write(order_id, expired_order);
                            
                            // Update user info
                            let mut user_info: UserOrderInfo = self.user_info.read(order.owner);
                            if user_info.active_orders > 0 {
                                user_info.active_orders -= 1;
                            }
                            self.user_info.write(order.owner, user_info);
                            
                            // Update stats
                            let mut stats: OrderbookStats = self.stats.read();
                            if stats.active_orders > 0 {
                                stats.active_orders -= 1;
                            }
                            self.stats.write(stats);
                            
                            self.emit(OrderExpired {
                                order_id: order_id,
                                owner: order.owner,
                                timestamp: current_time,
                            });
                            
                            expired_count += 1;
                        } else {
                            // new_active.append(order_id);
                            self.active_orders_by_asset.entry(key).push(order_id);
                        }
                        
                        j += 1;
                    };
                    
                    // self.active_orders_by_asset.write(key, new_active);
                    s += 1;
                };
                
                a += 1;
            };
            
            // Update cleanup timestamp
            let mut stats = self.stats.read();
            stats.last_cleanup_at = current_time;
            self.stats.write(stats);
            
            self.emit(CleanupExecuted {
                expired_orders_removed: expired_count,
                timestamp: current_time,
            });
            
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
        fn get_order_by_id(self: @ContractState, order_id: felt252) -> Order {
            let order = self.orders.read(order_id);
            assert(!order.order_id.is_zero(), ORDER_NOT_FOUND);
            order
        }
        
        fn hash_public_inputs(self: @ContractState, inputs: Span<felt252>) -> felt252 {
            let mut hasher: HashState = PoseidonTrait::new();
            let mut i: u32 = 0;
            while i < inputs.len() {
                hasher = hasher.update(*inputs[i]);
                i += 1;
            };
            hasher.finalize()
        }
    }
}