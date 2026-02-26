use starknet::ContractAddress;
use crate::structs::token_structs::{MintLimitResponse, FeeConfigResponse, BridgeMintRequestResponse};

#[starknet::interface]
pub trait IZKBTC<TContractState> {
    // Mint/Burn - Custom ZKBTC functionality
    fn native_mint(ref self: TContractState, to: ContractAddress, amount: u256, btc_txid: felt252);
    fn native_burn(ref self: TContractState, from: ContractAddress, amount: u256, btc_address: felt252);
    fn bridge_mint(ref self: TContractState, to: ContractAddress, amount: u256, btc_txid: felt252);

    fn _transfer_from(
        ref self: TContractState,
        from: ContractAddress,
        to: ContractAddress,
        amount: u256
    );

    fn _transfer(
        ref self: TContractState,
        recipient: ContractAddress,
        amount: u256
    );    
    
    // Admin - Custom configuration
    fn set_fee_config(ref self: TContractState, mint_fee_bps: u64, burn_fee_bps: u64, fee_collector: ContractAddress);
    fn set_daily_mint_cap(ref self: TContractState, new_cap: u256);
    fn whitelist_bridge(ref self: TContractState, bridge: ContractAddress);
    fn remove_bridge(ref self: TContractState, bridge: ContractAddress);
    fn pause(ref self: TContractState);
    fn unpause(ref self: TContractState);
    
    // Views - Custom getters
    fn get_mint_limit(self: @TContractState, account: ContractAddress) -> MintLimitResponse;
    fn get_fee_config(self: @TContractState) -> FeeConfigResponse;
    fn is_bridge_whitelisted(self: @TContractState, bridge: ContractAddress) -> bool;
    fn get_mint_request(self: @TContractState, btc_txid: felt252) -> BridgeMintRequestResponse;
    fn get_total_supply_cap(self: @TContractState) -> u256;
}