#[derive(Drop, Serde, Copy, PartialEq)]
pub enum UTXOStatus {
    Unspent,
    Spent,
    Locked,
    Pending,
}

#[derive(Drop, Serde, Copy, PartialEq)]
pub enum WithdrawalStatus {
    Pending,
    Processing,
    Completed,
    Failed,
    Expired,
}

#[derive(Drop, Serde, Copy, PartialEq)]
pub enum VaultRole {
    Guardian,
    Relayer,
    SwapEscrow,
    Admin,
}