pub mod constants {
    pub mod token_constants;
}
pub mod errors { 
    pub mod token_errors;
}
// pub mod enums {
//     pub mod enums
// }
pub mod structs {
    pub mod token_structs;
}
pub mod interfaces {
    pub mod i_zkbtc;
}
pub mod event_structs {
    pub mod token_events;
}
pub mod utils {
    pub mod token_utils;
}
// mod libraries;

pub mod contracts {
    // mod core {
//         mod ZKAtomicSwapVerifier;
//         mod BTCVault;
//         mod SwapEscrow;
//         mod ZKOrderBook;
    // }
    
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