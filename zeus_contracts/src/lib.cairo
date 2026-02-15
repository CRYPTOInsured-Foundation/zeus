pub mod constants {
    pub mod token_constants;
    pub mod swap_constants;
    pub mod bitcoin_constants;
    pub mod verifier_constants;
}
pub mod errors { 
    pub mod token_errors;
    pub mod swap_errors;
    pub mod bitcoin_errors;
    pub mod verifier_errors;
}
pub mod enums {
    pub mod swap_enums;
    pub mod bitcoin_enums;
    pub mod verifier_enums;
}
pub mod structs {
    pub mod token_structs;
    pub mod swap_structs;
    pub mod bitcoin_structs;
    pub mod verifier_structs;
}
pub mod interfaces {
    pub mod i_zkbtc;
    pub mod i_swap_escrow;
    pub mod i_btc_vault;
    pub mod i_zk_atomic_swap_verifier;
    
}
pub mod event_structs {
    pub mod token_events;
    pub mod swap_events;
    pub mod bitcoin_events;
    pub mod verifier_events;
}
pub mod utils {
    pub mod token_utils;
    pub mod swap_utils;
    pub mod bitcoin_utils;
    pub mod verifier_utils;
}
// mod libraries;

pub mod contracts {
    mod core {
        mod ZKAtomicSwapVerifier;
        pub mod BTCVault;
        pub mod SwapEscrow;
//         mod ZKOrderBook;
    }
    
    pub mod tokens {
        pub mod ZKBTC;
//         mod ZeusShareToken;
    }
    
//     mod bridges {
//         mod BitcoinBridge;
//         mod StarknetAtomicBridge;
//     }
    
//     #[cfg(test)]
//     mod mock {
//         mod MockERC20;
//         mod MockBitcoinOracle;
//         mod MockZKProver;
//     }
}