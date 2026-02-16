#[derive(Drop, Serde, Copy, PartialEq)]
pub enum BridgeStatus {
    Pending,
    Active,
    Completed,
    Refunded,
    Expired,
    Failed,
}

#[derive(Drop, Serde, Copy, PartialEq)]
pub enum BridgeType {
    BTCToStarknet,
    StarknetToBTC,
}

#[derive(Drop, Serde, Copy, PartialEq)]
pub enum ProofType {
    BitcoinProof,
    StarknetProof,
    ZKProof,
}