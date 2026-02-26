#[derive(Drop, Serde, Copy, PartialEq)]
pub enum ProofStatus {
    Pending,
    Success,
    Failed,
    Expired,
}

#[derive(Drop, Serde, Copy, PartialEq)]
pub enum CircuitType {
    OrderMatching,
    SwapValidity,
    RangeProof,
    Ownership,
}

#[derive(Drop, Serde, Copy, PartialEq)]
pub enum VerifierType {
    STARK,
    SNARK,
}