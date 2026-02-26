use starknet::ContractAddress;
use crate::structs::bitcoin_structs::{
    UTXOResponse, WithdrawalRequestResponse, VaultStats
};

#[starknet::interface]
pub trait IBTCVault<TContractState> {
    // Deposit functions
    fn deposit_utxo(
        ref self: TContractState,
        txid: felt252,
        vout: u32,
        amount: u64,
        script_pubkey: felt252,
        merkle_proof: felt252,
        block_height: u64,
        block_time: u64
    ) -> felt252;
    
    // Withdrawal functions
    fn request_withdrawal(
        ref self: TContractState,
        amount: u256,
        bitcoin_address: felt252
    ) -> u64;
    
    fn sign_withdrawal(
        ref self: TContractState,
        request_id: u64
    ) -> bool;
    
    fn execute_withdrawal(
        ref self: TContractState,
        request_id: u64,
        btc_txid: felt252,
        guardian_signatures: Array<felt252>
    ) -> bool;
    
    // UTXO management
    fn lock_utxo(
        ref self: TContractState,
        utxo_hash: felt252,
        swap_id: felt252,
        duration: u64
    ) -> bool;
    
    fn unlock_utxo(
        ref self: TContractState,
        utxo_hash: felt252,
        swap_id: felt252
    ) -> bool;
    
    fn spend_utxo(
        ref self: TContractState,
        utxo_hash: felt252,
        btc_txid: felt252
    ) -> bool;
    
    // View functions
    fn get_utxo(self: @TContractState, utxo_hash: felt252) -> UTXOResponse;
    fn get_withdrawal_request(self: @TContractState, request_id: u64) -> WithdrawalRequestResponse;
    fn get_vault_stats(self: @TContractState) -> VaultStats;
    fn get_user_utxos(self: @TContractState, user: ContractAddress, offset: u64, limit: u64) -> Array<UTXOResponse>;
    fn get_total_btc_locked(self: @TContractState) -> u256;
    fn is_guardian(self: @TContractState, guardian: ContractAddress) -> bool;
    fn get_threshold(self: @TContractState) -> u8;
    fn get_guardian_count(self: @TContractState) -> u8;

    fn add_guardian(ref self: TContractState, guardian: ContractAddress);
    fn remove_guardian(ref self: TContractState, guardian: ContractAddress);
    fn set_threshold(ref self: TContractState, new_threshold: u8);
    fn whitelist_swap_escrow(ref self: TContractState, swap_escrow: ContractAddress);
    fn remove_swap_escrow(ref self: TContractState, swap_escrow: ContractAddress);
    fn pause_vault(ref self: TContractState);
    fn unpause_vault(ref self: TContractState);
}