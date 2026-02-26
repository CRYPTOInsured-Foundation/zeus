use starknet::ContractAddress;
use crate::structs::swap_structs::{
    AtomicSwapResponse, 
    // PendingSwap
};
// use crate::enums::swap_enums::SwapStatus;
// use crate::enums::swap_enums::SwapStatus;

#[starknet::interface]
pub trait ISwapEscrow<TContractState> {
    // Core swap functions
    fn initiate_swap(
        ref self: TContractState,
        counterparty: ContractAddress,
        token_a: ContractAddress,
        token_b: ContractAddress,
        amount_a: u256,
        amount_b: u256,
        hashlock: felt252,
        timelock: u64
    ) -> felt252;
    
    fn fund_swap(ref self: TContractState, swap_id: felt252) -> bool;
    
    fn complete_swap(ref self: TContractState, swap_id: felt252, secret: felt252) -> bool;
    
    fn refund_swap(ref self: TContractState, swap_id: felt252) -> bool;
    
    // Relayer functions
    fn relay_complete_swap(
        ref self: TContractState, 
        swap_id: felt252, 
        secret: felt252,
        relayer_fee_recipient: ContractAddress
    ) -> bool;
    
    // View functions
    fn get_swap(self: @TContractState, swap_id: felt252) -> AtomicSwapResponse;
    
    fn get_swap_status(self: @TContractState, swap_id: felt252) -> u8;
    
    fn can_refund(self: @TContractState, swap_id: felt252) -> bool;
    
    fn get_user_active_swaps(self: @TContractState, user: ContractAddress) -> u64;
    
    fn is_token_supported(self: @TContractState, token: ContractAddress) -> bool;
    
    fn is_relayer_whitelisted(self: @TContractState, relayer: ContractAddress) -> bool;
    
    fn get_swap_fees(self: @TContractState) -> (u64, u64, ContractAddress);

    fn whitelist_token(ref self: TContractState, token: ContractAddress);

    fn remove_token(ref self: TContractState, token: ContractAddress);

    fn whitelist_relayer(ref self: TContractState, relayer: ContractAddress, fee_bps: u64);

    fn remove_relayer(ref self: TContractState, relayer: ContractAddress);

    fn set_fee_config(ref self: TContractState, protocol_fee_bps: u64, relayer_fee_bps: u64, fee_collector: ContractAddress);
}