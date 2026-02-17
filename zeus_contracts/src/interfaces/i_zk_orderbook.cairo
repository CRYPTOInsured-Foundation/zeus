use starknet::ContractAddress;
use crate::structs::orderbook_structs::{OrderResponse, MatchResponse, OrderbookStats, UserOrderInfo};

#[starknet::interface]
pub trait IZKOrderBook<TContractState> {
    // Core order functions
    fn place_order(
        ref self: TContractState,
        asset_type: u8,
        side: u8,
        amount_commitment: felt252,
        price_commitment: felt252,
        range_proof: Array<felt252>,
        expiry: u64
    ) -> felt252;
    
    fn cancel_order(ref self: TContractState, order_id: felt252) -> bool;
    
    fn cancel_batch_orders(ref self: TContractState, order_ids: Array<felt252>) -> bool;
    
    // Matching functions
    fn match_orders(
        ref self: TContractState,
        buy_order_ids: Array<felt252>,
        sell_order_ids: Array<felt252>,
        match_amounts: Array<u256>,
        match_prices: Array<u256>,
        zk_proof: Array<felt252>
    ) -> Array<felt252>;
    
    // Batch matching with proof
    fn match_orders_batch(
        ref self: TContractState,
        buy_order_commitments: Array<felt252>,
        sell_order_commitments: Array<felt252>,
        match_amounts: Array<u256>,
        match_prices: Array<u256>,
        batch_proof: Array<felt252>,
        total_volume_commitment: felt252,
        fee_commitment: felt252,
        match_count: u32
    ) -> bool;
    
    // View functions
    fn get_order(self: @TContractState, order_id: felt252) -> OrderResponse;
    fn get_user_orders(self: @TContractState, user: ContractAddress, offset: u64, limit: u64) -> Array<OrderResponse>;
    fn get_active_orders(self: @TContractState, asset_type: u8, side: u8, offset: u64, limit: u64) -> Array<OrderResponse>;
    fn get_match(self: @TContractState, match_id: felt252) -> MatchResponse;
    fn get_orderbook_stats(self: @TContractState) -> OrderbookStats;
    fn get_user_info(self: @TContractState, user: ContractAddress) -> UserOrderInfo;
    
    // Verification functions
    fn verify_range_proof(self: @TContractState, proof: Array<felt252>, commitment: felt252) -> bool;
    fn verify_order_ownership(self: @TContractState, order_id: felt252, user: ContractAddress) -> bool;
    
    // Admin functions
    fn whitelist_relayer(ref self: TContractState, relayer: ContractAddress, fee_bps: u64);
    fn remove_relayer(ref self: TContractState, relayer: ContractAddress);
    fn blacklist_user(ref self: TContractState, user: ContractAddress);
    fn whitelist_user(ref self: TContractState, user: ContractAddress);
    fn pause_orderbook(ref self: TContractState);
    fn unpause_orderbook(ref self: TContractState);
    fn cleanup_expired_orders(ref self: TContractState) -> u64;
}