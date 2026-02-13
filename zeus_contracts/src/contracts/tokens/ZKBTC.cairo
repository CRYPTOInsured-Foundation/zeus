#[starknet::contract]
pub mod ZKBTC {
    use openzeppelin::token::erc20::{ERC20Component, ERC20HooksEmptyImpl};
    use openzeppelin::access::ownable::OwnableComponent;
    use openzeppelin::security::pausable::PausableComponent;

    use openzeppelin_access::accesscontrol::AccessControlComponent;
    use openzeppelin::introspection::src5::SRC5Component;


    use openzeppelin::upgrades::UpgradeableComponent;
    use openzeppelin::upgrades::interface::IUpgradeable;
    use starknet::{ ContractAddress, ClassHash };
    use starknet::get_caller_address;
    use starknet::get_contract_address;
    use starknet::get_block_timestamp;

    // use zeroable::Zeroable;
    use core::num::traits::Zero;


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

    
    // Import local modules
    use crate::constants::token_constants::{
        ZKBTC_NAME, ZKBTC_SYMBOL, ZKBTC_DECIMALS,
        MAX_SUPPLY, MINTER_ROLE, BURNER_ROLE, VAULT_ROLE,
        MINT_FEE_BPS, BURN_FEE_BPS, MAX_FEE_BPS,
        MINT_CAP_PER_TX, BURN_CAP_PER_TX, DAILY_MINT_CAP
    };
    use crate::errors::token_errors::{
        MINTING_NOT_ALLOWED, BURNING_NOT_ALLOWED,
        EXCEEDS_MAX_SUPPLY, EXCEEDS_MINT_CAP, EXCEEDS_BURN_CAP,
        EXCEEDS_DAILY_MINT_CAP, INVALID_FEE_BPS, FEE_EXCEEDS_MAX,
        INSUFFICIENT_BALANCE, UNAUTHORIZED, ENVELOPED_PAUSED
    };
    use crate::structs::token_structs::*;
    use crate::event_structs::token_events::{
        TokensMinted, TokensBurned, MinterAdded, MinterRemoved,
        FeeUpdated, FeeCollectorUpdated, DailyMintCapUpdated,
        BridgeWhitelisted, BridgeRemoved, ContractPaused, ContractUnpaused
    };

    use crate::interfaces::i_zkbtc::IZKBTC;

    use crate::utils::token_utils::*;

    
    component!(path: ERC20Component, storage: erc20, event: ERC20Event);

    component!(path: UpgradeableComponent, storage: upgradeable, event: UpgradeableEvent);

    component!(path: OwnableComponent, storage: ownable, event: OwnableEvent);

    component!(path: PausableComponent, storage: pausable, event: PausableEvent);



    component!(path: AccessControlComponent, storage: accesscontrol, event: AccessControlEvent);
    component!(path: SRC5Component, storage: src5, event: SRC5Event);




    #[abi(embed_v0)]
    impl ERC20Impl = ERC20Component::ERC20Impl<ContractState>;

    #[abi(embed_v0)]
    impl ERC20CamelOnlyImpl = ERC20Component::ERC20CamelOnlyImpl<ContractState>;
    impl ERC20InternalImpl = ERC20Component::InternalImpl<ContractState>;


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
    
    #[storage]
    struct Storage {
        // OpenZeppelin Components
        #[substorage(v0)]
        erc20: ERC20Component::Storage,
        #[substorage(v0)]
        upgradeable: UpgradeableComponent::Storage,
        #[substorage(v0)]
        ownable: OwnableComponent::Storage,

        #[substorage(v0)]
        pausable: PausableComponent::Storage,
        
        #[substorage(v0)]
        accesscontrol: AccessControlComponent::Storage,

        #[substorage(v0)]
        src5: SRC5Component::Storage,
        
        // Custom Storage
        decimals: u8,
        mint_limits: Map::<ContractAddress, MintLimit>,
        fee_config: FeeConfig,
        whitelisted_bridges: Map::<ContractAddress, bool>,
        bridge_mint_requests: Map::<felt252, BridgeMintRequest>,
        total_supply_cap: u256,
        max_supply: u256,
        mint_tx_counter: u64
    }
    
    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        #[flat]
        ERC20Event: ERC20Component::Event,
        #[flat]
        UpgradeableEvent: UpgradeableComponent::Event,
        #[flat]
        OwnableEvent: OwnableComponent::Event,

        #[flat]
        PausableEvent: PausableComponent::Event,
        
        #[flat]
        AccessControlEvent: AccessControlComponent::Event,

        #[flat]
        SRC5Event: SRC5Component::Event,
        
        // Custom Events
        TokensMinted: TokensMinted,
        TokensBurned: TokensBurned,
        MinterAdded: MinterAdded,
        MinterRemoved: MinterRemoved,
        FeeUpdated: FeeUpdated,
        FeeCollectorUpdated: FeeCollectorUpdated,
        DailyMintCapUpdated: DailyMintCapUpdated,
        BridgeWhitelisted: BridgeWhitelisted,
        BridgeRemoved: BridgeRemoved,
        ContractPaused: ContractPaused,
        ContractUnpaused: ContractUnpaused
    }



    const ADMIN_ROLE: felt252 = selector!("ADMIN_ROLE");

    
    #[constructor]
    fn constructor(
        ref self: ContractState,
        owner: ContractAddress,
        name: ByteArray,     
        symbol: ByteArray,     
        decimals: u8,        
        initial_supply: u256,
        max_supply: u256,
        fee_collector: ContractAddress
    ) {
        // Initialize ERC20
        // self.erc20.initializer(ZKBTC_NAME, ZKBTC_SYMBOL, ZKBTC_DECIMALS);

        self.max_supply.write(max_supply);
        self.erc20.initializer(name, symbol);
        self.erc20.mint(owner, initial_supply);
        
        // Initialize Ownable
        self.ownable.initializer(owner);

        
        // Initialize AccessControl
        self.accesscontrol.initializer();
        self.accesscontrol._grant_role(MINTER_ROLE, owner);
        self.accesscontrol._grant_role(BURNER_ROLE, owner);
        self.accesscontrol._grant_role(VAULT_ROLE, owner);

        self.accesscontrol._grant_role(AccessControlComponent::DEFAULT_ADMIN_ROLE, owner);
        self.accesscontrol._grant_role(ADMIN_ROLE, owner);
        
        // Initialize fee config
        self.fee_config.write(FeeConfig {
            mint_fee_bps: MINT_FEE_BPS,
            burn_fee_bps: BURN_FEE_BPS,
            fee_collector: fee_collector
        });
        
        // Initialize total supply cap
        // self.total_supply_cap.write(MAX_SUPPLY);
        
        // Initialize counter
        self.mint_tx_counter.write(0);
    }


    #[abi(embed_v0)]
    pub impl ZKBTCImpl of IZKBTC<ContractState> {
        fn native_mint(
            ref self: ContractState,
            to: ContractAddress,
            amount: u256,
            btc_txid: felt252
        ) {
            // Check permissions and pause status
            assert!(self.accesscontrol.has_role(MINTER_ROLE, get_caller_address()), "AccessControl: Caller is not the Minter");

            self.pausable.assert_not_paused();
            
            // Validate amount
            assert!(amount > 0, "Amount must be positive");
            assert(amount <= MINT_CAP_PER_TX, EXCEEDS_MINT_CAP);
            
            // Check total supply cap - using ERC20 component's total_supply
            let current_supply = self.erc20.total_supply();
            assert(current_supply + amount <= self.total_supply_cap.read(), EXCEEDS_MAX_SUPPLY);
            
            // Check daily mint limit for caller
            self.check_and_update_mint_limit(get_caller_address(), amount);
            
            // Calculate and deduct fee
            let fee = self.calculate_mint_fee(amount);
            let amount_after_fee = amount - fee;
            
            // Mint tokens to recipient - using ERC20 component's _mint
            self.erc20.mint(to, amount_after_fee);
            
            // Mint fee tokens to fee collector
            if fee > 0 {
                let fee_collector = self.fee_config.read().fee_collector;
                self.erc20.mint(fee_collector, fee);
            }
            
            // Increment counter and emit event
            let tx_id = self.mint_tx_counter.read() + 1;
            self.mint_tx_counter.write(tx_id);
            

            let tokens_minted_event: TokensMinted = TokensMinted {
                minter: get_caller_address(),
                to: to,
                amount: amount_after_fee,
                fee: fee,
                btc_txid: btc_txid
            };

            self.emit(tokens_minted_event);

        }
        
        fn native_burn(
            ref self: ContractState,
            from: ContractAddress,
            amount: u256,
            btc_address: felt252
        ) {
            // Check permissions and pause status
            assert!(self.accesscontrol.has_role(BURNER_ROLE, get_caller_address()), "AccessControl: Caller is not the Burner");

            self.pausable.assert_not_paused();
            
            // Validate amount
            assert!(amount > 0, "Amount must be positive");
            assert(amount <= BURN_CAP_PER_TX, EXCEEDS_BURN_CAP);
            
            // Check balance - using ERC20 component's balance_of
            let balance = self.erc20.balance_of(from);
            assert(balance >= amount, INSUFFICIENT_BALANCE);
            
            // Calculate fee
            let fee = self.calculate_burn_fee(amount);
            let mut amount_to_burn = amount;
            
            // Transfer fee to fee collector if caller is not fee collector
            if fee > 0 {
                let fee_collector = self.fee_config.read().fee_collector;
                if from != fee_collector {
                    // Using ERC20 component's transfer_from
                    self.erc20.transfer(fee_collector, fee);
                    amount_to_burn = amount - fee;
                }
            }
            
            // Burn tokens - using ERC20 component's _burn
            self.erc20.burn(from, amount_to_burn);

            let tokens_burned_event: TokensBurned = TokensBurned {
                burner: get_caller_address(),
                from: from,
                amount: amount_to_burn,
                fee: fee,
                btc_address: btc_address
            };

            self.emit(tokens_burned_event);
        }
        
        fn bridge_mint(
            ref self: ContractState,
            to: ContractAddress,
            amount: u256,
            btc_txid: felt252
        ) {
            // Only whitelisted bridges can call this
            assert(self.whitelisted_bridges.read(get_caller_address()), UNAUTHORIZED);
            
            // Store mint request for audit
            let request = BridgeMintRequest {
                bridge_address: get_caller_address(),
                amount: amount,
                btc_txid: btc_txid,
                timestamp: get_block_timestamp(),
                processed: true
            };
            
            self.bridge_mint_requests.write(btc_txid, request);
            
            // Mint tokens
            self.native_mint(to, amount, btc_txid);
        }
        
        fn set_fee_config(
            ref self: ContractState,
            mint_fee_bps: u64,
            burn_fee_bps: u64,
            fee_collector: ContractAddress
        ) {
            // Only owner can set fees
            self.ownable.assert_only_owner();
            
            // Validate fees
            assert(mint_fee_bps <= MAX_FEE_BPS, FEE_EXCEEDS_MAX);
            assert(burn_fee_bps <= MAX_FEE_BPS, FEE_EXCEEDS_MAX);
            assert!(!fee_collector.is_zero(), "Invalid fee collector");
            
            let old_config = self.fee_config.read();
            self.fee_config.write(FeeConfig {
                mint_fee_bps: mint_fee_bps,
                burn_fee_bps: burn_fee_bps,
                fee_collector: fee_collector
            });

            let fee_updated_event: FeeUpdated = FeeUpdated {
                mint_fee_bps: mint_fee_bps,
                burn_fee_bps: burn_fee_bps,
                updated_by: get_caller_address()
            };

            self.emit(fee_updated_event);
        
            let fee_collector_updated_event: FeeCollectorUpdated = FeeCollectorUpdated {
                old_collector: old_config.fee_collector,
                new_collector: fee_collector,
                updated_by: get_caller_address()
            };

            self.emit(fee_collector_updated_event);
        }
        
        fn set_daily_mint_cap(ref self: ContractState, new_cap: u256) {
            self.ownable.assert_only_owner();
            
            let old_cap = DAILY_MINT_CAP;
        
            let daily_mint_cap_updated_event: DailyMintCapUpdated = DailyMintCapUpdated {
                old_cap: old_cap,
                new_cap: new_cap,
                updated_by: get_caller_address()
            };

            self.emit(daily_mint_cap_updated_event);
        }
        
        fn whitelist_bridge(ref self: ContractState, bridge: ContractAddress) {
            self.ownable.assert_only_owner();
            assert!(!bridge.is_zero(), "Invalid bridge address");
            
            self.whitelisted_bridges.write(bridge, true);
            
            let bridge_whitelisted_event: BridgeWhitelisted = BridgeWhitelisted {
                bridge: bridge,
                added_by: get_caller_address()
            };

            self.emit(bridge_whitelisted_event);
        }
        
        fn remove_bridge(ref self: ContractState, bridge: ContractAddress) {
            self.ownable.assert_only_owner();
            
            self.whitelisted_bridges.write(bridge, false);

            let bridge_removed_event: BridgeRemoved = BridgeRemoved {
                bridge: bridge,
                removed_by: get_caller_address()
            };

            self.emit(bridge_removed_event);
        }
        
        fn pause(ref self: ContractState) {
            self.ownable.assert_only_owner();
            self.pausable.pause();
        
            let contract_paused_event: ContractPaused = ContractPaused {
                paused_by: get_caller_address()
            };

            self.emit(contract_paused_event);
        }
        
        fn unpause(ref self: ContractState) {
            self.ownable.assert_only_owner();
            self.pausable.unpause();

            let contract_unpaused_event: ContractUnpaused = ContractUnpaused {
                unpaused_by: get_caller_address()
            };

            self.emit(contract_unpaused_event);
        }
        
        // View functions
        // fn get_mint_limit(self: @ContractState, account: ContractAddress) -> MintLimit {
        //     self.mint_limits.read(account)
        // }

        fn get_mint_limit(self: @ContractState, account: ContractAddress) -> MintLimitResponse {
            let limit = self.mint_limits.read(account);
            mint_limit_to_response(limit)
        }
        
        // fn get_fee_config(self: @ContractState) -> FeeConfig {
        //     self.fee_config.read()
        // }

        fn get_fee_config(self: @ContractState) -> FeeConfigResponse {
            let config = self.fee_config.read();
            fee_config_to_response(config)
        }
        
        fn is_bridge_whitelisted(self: @ContractState, bridge: ContractAddress) -> bool {
            self.whitelisted_bridges.read(bridge)
        }
        
        // fn get_mint_request(self: @ContractState, btc_txid: felt252) -> BridgeMintRequest {
        //     self.bridge_mint_requests.read(btc_txid)
        // }

        fn get_mint_request(self: @ContractState, btc_txid: felt252) -> BridgeMintRequestResponse {
            let request = self.bridge_mint_requests.read(btc_txid);
            bridge_mint_request_to_response(request)
        }
        
        fn get_total_supply_cap(self: @ContractState) -> u256 {
            self.total_supply_cap.read()
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

        fn _set_decimals(ref self: ContractState, decimals: u8) {
            self.decimals.write(decimals);
        }
    
        fn _read_decimals(self: @ContractState) -> u8 {
            self.decimals.read()
        }

        fn calculate_mint_fee(ref self: ContractState, amount: u256) -> u256 {
            let fee_bps = self.fee_config.read().mint_fee_bps;
            (amount * fee_bps.into()) / 10000
        }
        
        fn calculate_burn_fee(ref self: ContractState, amount: u256) -> u256 {
            let fee_bps = self.fee_config.read().burn_fee_bps;
            (amount * fee_bps.into()) / 10000
        }
        
        fn check_and_update_mint_limit(
            ref self: ContractState,
            minter: ContractAddress,
            amount: u256
        ) {
            let current_day = get_block_timestamp() / 86400;
            let mut limit = self.mint_limits.read(minter);
            
            // Reset if new day
            if limit.last_reset_day != current_day {
                limit.daily_minted = 0;
                limit.last_reset_day = current_day;
                limit.daily_cap = DAILY_MINT_CAP;
            }
            
            // Check cap
            assert(limit.daily_minted + amount <= limit.daily_cap, EXCEEDS_DAILY_MINT_CAP);
            
            // Update
            limit.daily_minted += amount;
            self.mint_limits.write(minter, limit);
        }
    }
}
