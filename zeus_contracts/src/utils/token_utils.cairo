use crate::structs::token_structs::*;

// Utility function to convert MintLimit storage struct to response struct
pub fn mint_limit_to_response(limit: MintLimit) -> MintLimitResponse {
    MintLimitResponse {
        daily_minted: limit.daily_minted,
        last_reset_day: limit.last_reset_day,
        daily_cap: limit.daily_cap,
    }
}

// Utility function to convert FeeConfig storage struct to response struct
pub fn fee_config_to_response(config: FeeConfig) -> FeeConfigResponse {
    FeeConfigResponse {
        mint_fee_bps: config.mint_fee_bps,
        burn_fee_bps: config.burn_fee_bps,
        fee_collector: config.fee_collector,
    }
}

// Utility function to convert BridgeMintRequest storage struct to response struct
pub fn bridge_mint_request_to_response(request: BridgeMintRequest) -> BridgeMintRequestResponse {
    BridgeMintRequestResponse {
        bridge_address: request.bridge_address,
        amount: request.amount,
        btc_txid: request.btc_txid,
        timestamp: request.timestamp,
        processed: request.processed,
    }
}