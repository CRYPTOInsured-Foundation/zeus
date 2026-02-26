#[derive(Drop, Serde, PartialEq)]
pub enum BitcoinTxType {
    P2PKH,
    P2SH,
    P2WPKH,
    P2WSH,
    P2TR,
}

#[derive(Drop, Serde, PartialEq)]
pub enum BitcoinProofType {
    Merkle,
    BlockHeader,
    Transaction,
}

#[derive(Drop, Serde, PartialEq)]
pub enum BitcoinNetwork {
    Mainnet,
    Testnet,
    Regtest,
}