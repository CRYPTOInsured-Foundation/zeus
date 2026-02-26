use starknet::ContractAddress;
use crate::structs::bitcoin_bridge_structs::{
    BitcoinUTXOResponse, BitcoinBridgeStats, BitcoinProof
};

#[starknet::interface]
pub trait IBitcoinBridge<TContractState> {
    // Deposit functions
    fn deposit_btc(
        ref self: TContractState,
        txid: felt252,
        vout: u32,
        amount: u64,
        script_pubkey: felt252,
        address: felt252,
        proof: Array<felt252>,
        block_height: u64
    ) -> felt252;
    
    // Withdrawal functions
    fn initiate_withdrawal(
        ref self: TContractState,
        amount: u256,
        btc_address: felt252
    ) -> felt252;
    
    fn sign_withdrawal(
        ref self: TContractState,
        withdrawal_id: felt252
    ) -> bool;
    
    fn execute_withdrawal(
        ref self: TContractState,
        withdrawal_id: felt252,
        btc_txid: felt252
    ) -> bool;
    
    // Proof functions
    fn submit_proof(
        ref self: TContractState,
        txid: felt252,
        proof_type: u8,
        merkle_root: felt252,
        merkle_proof: felt252,
        block_header: felt252,
        block_height: u64
    ) -> felt252;
    
    fn verify_proof(
        ref self: TContractState,
        proof_id: felt252
    ) -> bool;
    
    // View functions
    fn get_utxo(self: @TContractState, utxo_hash: felt252) -> BitcoinUTXOResponse;
    fn get_user_utxos(self: @TContractState, user: ContractAddress, offset: u64, limit: u64) -> Array<BitcoinUTXOResponse>;
    fn get_proof(self: @TContractState, proof_id: felt252) -> BitcoinProof;
    fn get_bridge_stats(self: @TContractState) -> BitcoinBridgeStats;
    fn is_tx_processed(self: @TContractState, txid: felt252, vout: u32) -> bool;
    
    // Admin functions
    fn whitelist_relayer(ref self: TContractState, relayer: ContractAddress);
    fn remove_relayer(ref self: TContractState, relayer: ContractAddress);
    fn set_config(
        ref self: TContractState,
        required_confirmations: u64,
        min_deposit_amount: u64,
        max_deposit_amount: u64,
        protocol_fee_bps: u64,
        fee_collector: ContractAddress
    );
    fn pause_bridge(ref self: TContractState, reason: felt252);
    fn unpause_bridge(ref self: TContractState);
}