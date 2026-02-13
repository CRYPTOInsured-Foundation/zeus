#[derive(Drop, Serde, Copy, PartialEq)]
pub enum SwapStatus {
    Created,
    Funded,
    Completed,
    Refunded,
    Expired,
}

#[derive(Drop, Serde, Copy, PartialEq)]
pub enum SwapType {
    BitcoinToStarknet,
    StarknetToBitcoin,
    StarknetToStarknet,
}

#[derive(Drop, Serde, Copy, PartialEq)]
pub enum RefundEligibility {
    Eligible,
    NotEligible,
    AlreadyRefunded,
}