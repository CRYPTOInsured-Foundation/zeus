use starknet::ContractAddress;
// use starknet::poseidon_hash;
// use core::poseidon::poseidon_hash;
// use core::poseidon::poseidon_hash_span;
use core::poseidon::PoseidonTrait;
use core::hash::HashStateTrait;
use crate::structs::swap_structs::{AtomicSwap, AtomicSwapResponse};
use crate::enums::swap_enums::SwapStatus;

// Convert AtomicSwap to response struct
pub fn atomic_swap_to_response(swap: AtomicSwap) -> AtomicSwapResponse {
    AtomicSwapResponse {
        swap_id: swap.swap_id,
        initiator: swap.initiator,
        counterparty: swap.counterparty,
        token_a: swap.token_a,
        token_b: swap.token_b,
        amount_a: swap.amount_a,
        amount_b: swap.amount_b,
        hashlock: swap.hashlock,
        timelock: swap.timelock,
        status: match swap.status_code {
            0 => { SwapStatus::Created },
            1 => { SwapStatus::Funded },
            2 => { SwapStatus::Completed },
            3 => { SwapStatus::Refunded },
            4 => { SwapStatus::Expired },
            _ => { SwapStatus::Expired }
        },
        secret: swap.secret,
        secret_revealed: swap.secret_revealed,
        created_at: swap.created_at,
        funded_at: swap.funded_at,
        completed_at: swap.completed_at,
    }
}


pub fn atomic_swap_status_to_code(status: SwapStatus) -> u8 {
   
        let code : u8 = match status {
            SwapStatus::Created  => 0,
            SwapStatus::Funded => 1,
            SwapStatus::Completed => 2,
            SwapStatus::Refunded => 3,
            SwapStatus::Expired  => 4,
        };

        code
       
}

pub fn atomic_swap_code_to_status(code: u8) -> SwapStatus {
   
    let status : SwapStatus = match code {
        0 => SwapStatus::Created,  
        1 => SwapStatus::Funded,
        2 => SwapStatus::Completed,
        3 => SwapStatus::Refunded,
        4 => SwapStatus::Expired,
        _ => SwapStatus::Expired
    };

    status
   
}

// Generate unique swap ID

pub fn generate_swap_id(
    initiator: ContractAddress,
    counterparty: ContractAddress,
    hashlock: felt252,
    timestamp: u64
) -> felt252 {
    PoseidonTrait::new()
        .update(initiator.into())
        .update(counterparty.into())
        .update(hashlock)
        .update(timestamp.into())
        .finalize()
}

// Calculate fee based on basis points
pub fn calculate_fee(amount: u256, fee_bps: u64) -> u256 {
    (amount * fee_bps.into()) / 10000
}

// Validate hashlock (simple check for now)
pub fn validate_hashlock(hashlock: felt252) -> bool {
    hashlock != 0
}

// Validate timelock duration
pub fn validate_timelock(timelock: u64, min_duration: u64, max_duration: u64) -> bool {
    timelock >= min_duration && timelock <= max_duration
}

// Check if swap is expired
pub fn is_swap_expired(timelock: u64, current_time: u64) -> bool {
    current_time >= timelock
}