#[derive(Drop, Serde, Copy, PartialEq)]
pub enum OrderStatus {
    Active,
    Matched,
    Cancelled,
    Expired,
    Partial,
}

#[derive(Drop, Serde, Copy, PartialEq)]
pub enum OrderSide {
    Buy,
    Sell,
}

#[derive(Drop, Serde, Copy, PartialEq)]
pub enum AssetType {
    BTC,
    STRK,
    ETH,
    USDC,
    ZKBTC,
}