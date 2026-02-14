use starknet::ContractAddress;
use core::poseidon::PoseidonTrait;
use core::hash::HashStateTrait;
// use crate::structs::bitcoin_structs::{UTXO, UTXOResponse, WithdrawalRequest, WithdrawalRequestResponse};
// use crate::constants::bitcoin_constants::{
//     UTXO_STATUS_UNSPENT, UTXO_STATUS_SPENT, UTXO_STATUS_LOCKED, UTXO_STATUS_PENDING,
//     WITHDRAWAL_STATUS_PENDING, WITHDRAWAL_STATUS_PROCESSING, WITHDRAWAL_STATUS_COMPLETED,
//     WITHDRAWAL_STATUS_FAILED, WITHDRAWAL_STATUS_EXPIRED
// };

use crate::constants::bitcoin_constants::*;
use crate::structs::bitcoin_structs::*;

use core::num::traits::Zero;


// Convert UTXO storage struct to response struct
pub fn utxo_to_response(utxo: UTXO) -> UTXOResponse {
    UTXOResponse {
        txid: utxo.txid,
        vout: utxo.vout,
        amount: utxo.amount,
        script_pubkey: utxo.script_pubkey,
        owner: utxo.owner,
        status: utxo.status,
        locked_until: utxo.locked_until,
        created_at: utxo.created_at,
        spent_at: utxo.spent_at,
        confirmations: utxo.confirmations,
    }
}

// Convert WithdrawalRequest storage struct to response struct
pub fn withdrawal_request_to_response(request: WithdrawalRequest) -> WithdrawalRequestResponse {
    WithdrawalRequestResponse {
        request_id: request.request_id,
        user: request.user,
        amount: request.amount,
        bitcoin_address: request.bitcoin_address,
        status: request.status,
        created_at: request.created_at,
        processed_at: request.processed_at,
        expiry: request.expiry,
        guardian_signatures: request.guardian_signatures,
        required_signatures: request.required_signatures,
        btc_txid: request.btc_txid,
    }
}

// Generate UTXO hash from txid and vout
pub fn generate_utxo_hash(txid: felt252, vout: u32) -> felt252 {
    PoseidonTrait::new()
        .update(txid)
        .update(vout.into())
        .finalize()
}

// Generate withdrawal request ID
pub fn generate_withdrawal_id(
    user: ContractAddress,
    amount: u256,
    bitcoin_address: felt252,
    timestamp: u64
) -> u64 {
    let hash = PoseidonTrait::new()
        .update(user.into())
        .update(amount.low.into())
        .update(amount.high.into())
        .update(bitcoin_address)
        .update(timestamp.into())
        .finalize();
    (hash.try_into().unwrap() % 10000000000000000) // Keep it as u64 range
}

// Validate Bitcoin address format (simplified)
pub fn validate_bitcoin_address(address: felt252) -> bool {
    // In production, implement proper Bitcoin address validation
    // For hackathon, just check not zero and length constraints
    !address.is_zero() && address != ''
}

// Check if UTXO is locked and lock hasn't expired
pub fn is_utxo_locked(status: u8, locked_until: u64, current_time: u64) -> bool {
    status == UTXO_STATUS_LOCKED && current_time < locked_until
}

// // Convert status code to string for events
// pub fn utxo_status_to_string(status: u8) -> felt252 {
//     match status {
//         UTXO_STATUS_UNSPENT => { 'UNSPENT' },
//         UTXO_STATUS_SPENT => { 'SPENT' },
//         UTXO_STATUS_LOCKED => { 'LOCKED' },
//         UTXO_STATUS_PENDING => { 'PENDING' },
//         _ => { 'UNKNOWN' }
//     }
// }

// // Convert withdrawal status code to string for events
// pub fn withdrawal_status_to_string(status: u8) -> felt252 {
//     match status {
//         WITHDRAWAL_STATUS_PENDING => { 'PENDING' },
//         WITHDRAWAL_STATUS_PROCESSING => { 'PROCESSING' },
//         WITHDRAWAL_STATUS_COMPLETED => { 'COMPLETED' },
//         WITHDRAWAL_STATUS_FAILED => { 'FAILED' },
//         WITHDRAWAL_STATUS_EXPIRED => { 'EXPIRED' },
//         _ => { 'UNKNOWN' }
//     }
// }


pub fn utxo_status_to_string(status: u8) -> felt252 {
    if status == 0_u8 {
        'UNSPENT'
    } else if status == 1_u8 {
        'SPENT'
    } else if status == 2_u8 {
        'LOCKED'
    } else if status == 3_u8 {
        'PENDING'
    } else {
        'UNKNOWN'
    }
}

pub fn withdrawal_status_to_string(status: u8) -> felt252 {
    if status == 0_u8 {
        'PENDING'
    } else if status == 1_u8 {
        'PROCESSING'
    } else if status == 2_u8 {
        'COMPLETED'
    } else if status == 3_u8 {
        'FAILED'
    } else if status == 4_u8 {
        'EXPIRED'
    } else {
        'UNKNOWN'
    }
}

// Verify merkle proof (simplified for hackathon)
pub fn verify_merkle_proof(
    txid: felt252,
    merkle_root: felt252,
    merkle_proof: felt252
) -> bool {
    // In production, implement actual Merkle proof verification
    // For hackathon, simplified check
    let computed_root = PoseidonTrait::new()
        .update(txid)
        .update(merkle_proof)
        .finalize();
    
    computed_root == merkle_root
}

// Check if amount is above dust limit
pub fn is_above_dust_limit(amount: u64) -> bool {
    amount >= 546 // Standard Bitcoin dust limit
}