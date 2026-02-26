use starknet::ContractAddress;
use core::poseidon::PoseidonTrait;
use core::hash::HashStateTrait;
use crate::structs::bridge_structs::{
    AtomicBridgeSwap, AtomicBridgeSwapResponse, //BridgeStats, UserBridgeInfo
};

use core::num::traits::Zero;
use crate::constants::bridge_constants::{
    BRIDGE_STATUS_PENDING, BRIDGE_STATUS_ACTIVE, BRIDGE_STATUS_COMPLETED,
    BRIDGE_STATUS_REFUNDED, BRIDGE_STATUS_EXPIRED, BRIDGE_STATUS_FAILED,
    BRIDGE_TYPE_BTC_TO_STRK, BRIDGE_TYPE_STRK_TO_BTC
};

// Convert AtomicBridgeSwap storage struct to response struct
pub fn bridge_swap_to_response(swap: AtomicBridgeSwap) -> AtomicBridgeSwapResponse {
    AtomicBridgeSwapResponse {
        swap_id: swap.swap_id,
        initiator: swap.initiator,
        counterparty: swap.counterparty,
        bridge_type: swap.bridge_type,
        amount_btc: swap.amount_btc,
        amount_strk: swap.amount_strk,
        hashlock: swap.hashlock,
        timelock: swap.timelock,
        status: swap.status,
        secret: swap.secret,
        secret_revealed: swap.secret_revealed,
        btc_txid: swap.btc_txid,
        strk_tx_hash: swap.strk_tx_hash,
        created_at: swap.created_at,
        funded_at: swap.funded_at,
        completed_at: swap.completed_at,
        expires_at: swap.expires_at,
        retry_count: swap.retry_count,
    }
}

// Generate swap ID
pub fn generate_swap_id(
    initiator: ContractAddress,
    counterparty: ContractAddress,
    bridge_type: u8,
    hashlock: felt252,
    timestamp: u64
) -> felt252 {
    PoseidonTrait::new()
        .update(initiator.into())
        .update(counterparty.into())
        .update(bridge_type.into())
        .update(hashlock)
        .update(timestamp.into())
        .finalize()
}

// Generate proof ID
pub fn generate_proof_id(
    swap_id: felt252,
    proof_type: u8,
    submitter: ContractAddress,
    timestamp: u64
) -> felt252 {
    PoseidonTrait::new()
        .update(swap_id)
        .update(proof_type.into())
        .update(submitter.into())
        .update(timestamp.into())
        .finalize()
}

// Check if swap is active
pub fn is_swap_active(status: u8, expires_at: u64, current_time: u64) -> bool {
    status == BRIDGE_STATUS_ACTIVE && current_time < expires_at
}

// Check if swap can be refunded
pub fn can_refund_swap(status: u8, expires_at: u64, current_time: u64) -> bool {
    status == BRIDGE_STATUS_ACTIVE && current_time >= expires_at
}

// Check if swap is expired
pub fn is_swap_expired(expires_at: u64, current_time: u64) -> bool {
    current_time >= expires_at
}

// Calculate bridge fee
pub fn calculate_bridge_fee(
    amount: u256,
    protocol_fee_bps: u64,
    relayer_fee_bps: u64,
    min_fee: u256,
    max_fee: u256
) -> (u256, u256) {
    let protocol_fee = (amount * protocol_fee_bps.into()) / 10000;
    let relayer_fee = (amount * relayer_fee_bps.into()) / 10000;
    let total_fee = protocol_fee + relayer_fee;
    
    // Apply min/max constraints
    let final_fee = if total_fee < min_fee {
        min_fee
    } else if total_fee > max_fee {
        max_fee
    } else {
        total_fee
    };
    
    // Split fee proportionally
    let protocol_portion = (final_fee * protocol_fee_bps.into()) / (protocol_fee_bps + relayer_fee_bps).into();
    let relayer_portion = final_fee - protocol_portion;
    
    (protocol_portion, relayer_portion)
}

// Validate hashlock format
pub fn validate_hashlock(hashlock: felt252) -> bool {
    !hashlock.is_zero()
}

// Validate secret against hashlock (simplified)
pub fn validate_secret(secret: felt252, hashlock: felt252) -> bool {
    // In production, would hash secret and compare
    !secret.is_zero() && !hashlock.is_zero()
}

// Convert status code to string for events
pub fn bridge_status_to_string(status: u8) -> felt252 {
    if status == BRIDGE_STATUS_PENDING {
        'PENDING'
    } else if status == BRIDGE_STATUS_ACTIVE {
        'ACTIVE'
    } else if status == BRIDGE_STATUS_COMPLETED {
        'COMPLETED'
    } else if status == BRIDGE_STATUS_REFUNDED {
        'REFUNDED'
    } else if status == BRIDGE_STATUS_EXPIRED {
        'EXPIRED'
    } else if status == BRIDGE_STATUS_FAILED {
        'FAILED'
    } else {
        'UNKNOWN'
    }
}

// Convert bridge type to string
pub fn bridge_type_to_string(bridge_type: u8) -> felt252 {
    if bridge_type == BRIDGE_TYPE_BTC_TO_STRK {
        'BTC_TO_STRK'
    } else if bridge_type == BRIDGE_TYPE_STRK_TO_BTC {
        'STRK_TO_BTC'
    } else {
        'UNKNOWN'
    }
}

// Check if retry is allowed
pub fn can_retry(retry_count: u8, last_attempt: u64, current_time: u64) -> bool {
    retry_count < 3 && (current_time - last_attempt) >= 3600 // At least 1 hour between retries
}

// Validate amount
pub fn validate_amount(amount: u256, min_amount: u256, max_amount: u256) -> bool {
    amount >= min_amount && amount <= max_amount
}

// Get required confirmations based on bridge type
pub fn get_confirmations_for_type(bridge_type: u8) -> u64 {
    if bridge_type == BRIDGE_TYPE_BTC_TO_STRK {
        6 // Bitcoin confirmations
    } else {
        12 // Starknet confirmations
    }
}