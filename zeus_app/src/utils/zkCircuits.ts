/**
 * ZK Circuits Placeholder
 * Descriptions for STARK circuits used in Zeus for privacy-preserving swaps.
 */

export const swapCircuit = {
  name: 'private_swap_stark',
  inputs: {
    public: ['starknet_recipient', 'amount_min', 'hash_lock'],
    private: ['bitcoin_secret', 'starknet_private_key'],
  },
  constraints: [
    'verify_hash_lock(bitcoin_secret, hash_lock)',
    'verify_ownership(starknet_private_key, starknet_recipient)',
  ],
  description: 'Ensures the Starknet transaction is only valid if the Bitcoin secret is revealed and correctly hashed.',
};

export const orderbookCircuit = {
  name: 'encrypted_orderbook_match',
  inputs: {
    public: ['merkle_root', 'min_price'],
    private: ['order_details', 'signature'],
  },
  description: 'Allows matching orders without revealing full amounts or counterparties until execution.',
};
