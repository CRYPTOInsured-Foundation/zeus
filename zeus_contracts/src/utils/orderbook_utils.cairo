use starknet::ContractAddress;
use core::poseidon::PoseidonTrait;
use core::hash::HashStateTrait;
use crate::structs::orderbook_structs::{Order, OrderResponse, Match, MatchResponse};
use crate::constants::orderbook_constants::{
    ORDER_STATUS_ACTIVE, ORDER_STATUS_MATCHED, ORDER_STATUS_CANCELLED, 
    ORDER_STATUS_EXPIRED, ORDER_STATUS_PARTIAL, ORDER_SIDE_BUY, ORDER_SIDE_SELL
};
use core::num::traits::Zero;


// Convert Order storage struct to response struct
pub fn order_to_response(order: Order) -> OrderResponse {
    OrderResponse {
        order_id: order.order_id,
        owner: order.owner,
        asset_type: order.asset_type,
        side: order.side,
        amount_commitment: order.amount_commitment,
        price_commitment: order.price_commitment,
        expiry: order.expiry,
        created_at: order.created_at,
        status: order.status,
        matched_amount: order.matched_amount,
        remaining_amount: order.remaining_amount,
        nullifier: order.nullifier,
    }
}

// Convert Match storage struct to response struct
pub fn match_to_response(match_item: Match) -> MatchResponse {
    MatchResponse {
        match_id: match_item.match_id,
        buy_order_id: match_item.buy_order_id,
        sell_order_id: match_item.sell_order_id,
        matched_amount: match_item.matched_amount,
        match_price: match_item.match_price,
        timestamp: match_item.timestamp,
        relayer: match_item.relayer,
        proof_hash: match_item.proof_hash,
    }
}

// Generate order ID
pub fn generate_order_id(
    owner: ContractAddress,
    asset_type: u8,
    side: u8,
    commitment: felt252,
    timestamp: u64
) -> felt252 {
    PoseidonTrait::new()
        .update(owner.into())
        .update(asset_type.into())
        .update(side.into())
        .update(commitment)
        .update(timestamp.into())
        .finalize()
}

// Generate match ID
pub fn generate_match_id(
    buy_order_id: felt252,
    sell_order_id: felt252,
    timestamp: u64
) -> felt252 {
    PoseidonTrait::new()
        .update(buy_order_id)
        .update(sell_order_id)
        .update(timestamp.into())
        .finalize()
}

// Generate nullifier from order data
pub fn generate_nullifier(
    owner: ContractAddress,
    commitment: felt252,
    timestamp: u64
) -> felt252 {
    PoseidonTrait::new()
        .update(owner.into())
        .update(commitment)
        .update(timestamp.into())
        .finalize()
}

// Check if order is active
pub fn is_order_active(status: u8, expiry: u64, current_time: u64) -> bool {
    status == ORDER_STATUS_ACTIVE && current_time < expiry
}

// Check if order is expired
pub fn is_order_expired(expiry: u64, current_time: u64) -> bool {
    current_time >= expiry
}

// Convert side code to string
pub fn side_to_string(side: u8) -> felt252 {
    if side == ORDER_SIDE_BUY {
        'BUY'
    } else if side == ORDER_SIDE_SELL {
        'SELL'
    } else {
        'UNKNOWN'
    }
}

// Convert status code to string
pub fn status_to_string(status: u8) -> felt252 {
    if status == ORDER_STATUS_ACTIVE {
        'ACTIVE'
    } else if status == ORDER_STATUS_MATCHED {
        'MATCHED'
    } else if status == ORDER_STATUS_CANCELLED {
        'CANCELLED'
    } else if status == ORDER_STATUS_EXPIRED {
        'EXPIRED'
    } else if status == ORDER_STATUS_PARTIAL {
        'PARTIAL'
    } else {
        'UNKNOWN'
    }
}

// Verify range proof (simplified)
pub fn verify_range_proof_simple(proof: Span<felt252>, commitment: felt252) -> bool {
    // In production, this would verify actual cryptographic range proof
    // For hackathon, simplified check
    proof.len() > 0 && !commitment.is_zero()
}

// Calculate fee
pub fn calculate_fee(amount: u256, fee_bps: u64) -> u256 {
    (amount * fee_bps.into()) / 10000
}

// Build merkle proof (simplified)
pub fn build_merkle_proof(leaf: felt252, root: felt252) -> Array<felt252> {
    // In production, would build actual merkle proof
    // For hackathon, return empty array
    ArrayTrait::new()
}

// Verify merkle proof (simplified)
pub fn verify_merkle_proof(leaf: felt252, proof: Span<felt252>, root: felt252) -> bool {
    // In production, would verify actual merkle proof
    // For hackathon, simplified check
    !leaf.is_zero() && !root.is_zero()
}

// Compute order root from orders (simplified)
pub fn compute_order_root(orders: Span<felt252>) -> felt252 {
    let mut hasher = PoseidonTrait::new();
    let mut i = 0;
    while i < orders.len() {
        hasher = hasher.update(*orders[i]);
        i += 1;
    };
    hasher.finalize()
}