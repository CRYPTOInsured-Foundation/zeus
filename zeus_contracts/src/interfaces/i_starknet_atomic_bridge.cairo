use starknet::ContractAddress;
use crate::structs::bridge_structs::{
    AtomicBridgeSwapResponse, BridgeStats, UserBridgeInfo, //BridgeFee
};

#[starknet::interface]
pub trait IStarknetAtomicBridge<TContractState> {
    // Core bridge functions
    fn initiate_swap(
        ref self: TContractState,
        counterparty: ContractAddress,
        bridge_type: u8,
        amount_btc: u256,
        amount_strk: u256,
        hashlock: felt252,
        timelock: u64
    ) -> felt252;
    
    fn fund_swap(ref self: TContractState, swap_id: felt252) -> bool;
    
    fn complete_swap(
        ref self: TContractState,
        swap_id: felt252,
        secret: felt252,
        btc_txid: felt252
    ) -> bool;
    
    fn refund_swap(ref self: TContractState, swap_id: felt252) -> bool;
    
    // Relayer functions
    fn relay_complete_swap(
        ref self: TContractState,
        swap_id: felt252,
        secret: felt252,
        btc_txid: felt252,
        relayer_fee_recipient: ContractAddress
    ) -> bool;
    
    // Proof functions
    fn submit_proof(
        ref self: TContractState,
        swap_id: felt252,
        proof_type: u8,
        proof_data: Array<felt252>
    ) -> felt252;
    
    fn verify_proof(
        ref self: TContractState,
        proof_id: felt252,
        expected_result: bool
    ) -> bool;
    
    // Retry functions
    fn retry_swap(ref self: TContractState, swap_id: felt252) -> bool;
    
    // View functions
    fn get_swap(self: @TContractState, swap_id: felt252) -> AtomicBridgeSwapResponse;
    fn get_user_swaps(self: @TContractState, user: ContractAddress, offset: u64, limit: u64) -> Array<AtomicBridgeSwapResponse>;
    fn get_pending_swaps(self: @TContractState, offset: u64, limit: u64) -> Array<AtomicBridgeSwapResponse>;
    fn get_bridge_stats(self: @TContractState) -> BridgeStats;
    fn get_user_info(self: @TContractState, user: ContractAddress) -> UserBridgeInfo;
    fn can_refund(self: @TContractState, swap_id: felt252) -> bool;
    fn get_required_confirmations(self: @TContractState, bridge_type: u8) -> u64;
    
    // Admin functions
    fn whitelist_relayer(ref self: TContractState, relayer: ContractAddress, fee_bps: u64);
    fn remove_relayer(ref self: TContractState, relayer: ContractAddress);
    fn set_fee_config(
        ref self: TContractState,
        protocol_fee_bps: u64,
        relayer_fee_bps: u64,
        min_fee: u256,
        max_fee: u256,
        fee_collector: ContractAddress
    );
    fn pause_bridge(ref self: TContractState, reason: felt252);
    fn unpause_bridge(ref self: TContractState);
    fn set_contract_address(
        ref self: TContractState,
        contract_type: felt252,
        contract_address: ContractAddress
    );
    fn cleanup_expired_swaps(ref self: TContractState) -> u64;
}