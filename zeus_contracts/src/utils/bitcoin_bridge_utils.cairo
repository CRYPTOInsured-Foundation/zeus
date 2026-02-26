use starknet::ContractAddress;
use core::poseidon::PoseidonTrait;
use core::hash::HashStateTrait;
use crate::structs::bitcoin_bridge_structs::{
    BitcoinUTXO, BitcoinUTXOResponse, //BitcoinProof
};

use core::num::traits::Zero;


pub fn utxo_to_response(utxo: BitcoinUTXO) -> BitcoinUTXOResponse {
    BitcoinUTXOResponse {
        utxo_hash: utxo.utxo_hash,
        txid: utxo.txid,
        vout: utxo.vout,
        amount: utxo.amount,
        script_pubkey: utxo.script_pubkey,
        address: utxo.address,
        owner: utxo.owner,
        block_height: utxo.block_height,
        processed_at: utxo.processed_at,
        spent: utxo.spent,
    }
}

pub fn generate_utxo_hash(txid: felt252, vout: u32) -> felt252 {
    PoseidonTrait::new()
        .update(txid)
        .update(vout.into())
        .finalize()
}

pub fn generate_withdrawal_id(
    user: ContractAddress,
    amount: u256,
    btc_address: felt252,
    timestamp: u64
) -> felt252 {
    PoseidonTrait::new()
        .update(user.into())
        .update(amount.low.into())
        .update(amount.high.into())
        .update(btc_address)
        .update(timestamp.into())
        .finalize()
}

pub fn generate_proof_id(
    txid: felt252,
    proof_type: u8,
    submitter: ContractAddress,
    timestamp: u64
) -> felt252 {
    PoseidonTrait::new()
        .update(txid)
        .update(proof_type.into())
        .update(submitter.into())
        .update(timestamp.into())
        .finalize()
}

pub fn validate_btc_address(address: felt252) -> bool {
    // Simplified validation - in production would check format
    !address.is_zero()
}

pub fn validate_script(script: felt252) -> bool {
    // Simplified validation - in production would check script format
    !script.is_zero()
}

pub fn calculate_btc_fee(amount: u256, fee_bps: u64) -> u256 {
    (amount * fee_bps.into()) / 10000
}

pub fn verify_merkle_proof(
    txid: felt252,
    merkle_root: felt252,
    merkle_proof: felt252,
    index: u32
) -> bool {
    // Simplified - in production would verify actual Merkle proof
    !txid.is_zero() && !merkle_root.is_zero() && !merkle_proof.is_zero()
}

pub fn verify_block_header(header: felt252, block_height: u64) -> bool {
    // Simplified - in production would verify PoW
    !header.is_zero() && block_height > 0
}