pub mod constants {
    pub mod token_constants;
    pub mod swap_constants;
}
pub mod errors { 
    pub mod token_errors;
    pub mod swap_errors;
}
pub mod enums {
    pub mod swap_enums;
}
pub mod structs {
    pub mod token_structs;
    pub mod swap_structs;
}
pub mod interfaces {
    pub mod i_zkbtc;
    pub mod i_swap_escrow;
}
pub mod event_structs {
    pub mod token_events;
    pub mod swap_events;
}
pub mod utils {
    pub mod token_utils;
    pub mod swap_utils;
}
// mod libraries;

pub mod contracts {
    mod core {
//         mod ZKAtomicSwapVerifier;
//         mod BTCVault;
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