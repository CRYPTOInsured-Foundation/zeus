#!/usr/bin/env bash
# Devnet deployment scaffold for Zeus contracts
#
# This script assumes you have `starknet-devnet` and the `starknet` CLI available
# and that the contracts in ../zeus_contracts have been compiled (class hashes / .sierra/.cairo files).
# It does not modify contracts — it only shows the deploy order and example CLI commands.

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
CONTRACTS_DIR="$ROOT_DIR/../zeus_contracts"

DEVNET_PORT=${DEVNET_PORT:-5050}
STARKNET_RPC_URL=${STARKNET_RPC_URL:-http://127.0.0.1:${DEVNET_PORT}}

echo "Using contracts dir: $CONTRACTS_DIR"
echo "Starknet RPC: $STARKNET_RPC_URL"

echo "\n# 1. Start starknet-devnet (if not running)"
echo "starknet-devnet --port ${DEVNET_PORT} &"

echo "\n# 2. Example deploy order (fill compiled paths, adjust constructor args)"
echo "# Deploy ZKAtomicSwapVerifier (constructor: owner)"
echo "starknet deploy --contract <path_to/ZKAtomicSwapVerifier.sierra> --gateway_url ${STARKNET_RPC_URL} --network alpha-goerli --inputs <OWNER_ADDRESS>"

echo "# Deploy ZKBTC (constructor: owner, name, symbol, decimals, initial_supply, max_supply, fee_collector)"
echo "starknet deploy --contract <path_to/ZKBTC.sierra> --gateway_url ${STARKNET_RPC_URL} --inputs <OWNER> 'ZKBTC' 'ZKBTC' 18 0 340282366920938463463374607431768211455 <FEE_COLLECTOR>"

echo "# Deploy BTCVault (constructor: owner, zkbtc_token, initial_threshold)"
echo "starknet deploy --contract <path_to/BTCVault.sierra> --gateway_url ${STARKNET_RPC_URL} --inputs <OWNER> <ZKBTC_ADDRESS> 3"

echo "# Deploy SwapEscrow (constructor: owner, fee_collector)"
echo "starknet deploy --contract <path_to/SwapEscrow.sierra> --gateway_url ${STARKNET_RPC_URL} --inputs <OWNER> <FEE_COLLECTOR>"

echo "# Deploy ZKAtomicSwapVerifier (already deployed)"

echo "# Deploy StarknetAtomicBridge (constructor: owner, btc_vault, swap_escrow, zk_verifier, zkbtc_token, strk_address)"
echo "starknet deploy --contract <path_to/StarknetAtomicBridge.sierra> --gateway_url ${STARKNET_RPC_URL} --inputs <OWNER> <BTCVAULT_ADDR> <SWAPESCROW_ADDR> <ZKVERIFIER_ADDR> <ZKBTC_ADDR> <STRK_ADDR>"

echo "# Deploy BitcoinBridge (constructor: owner, btc_vault, zk_verifier, zkbtc_token)"
echo "starknet deploy --contract <path_to/BitcoinBridge.sierra> --gateway_url ${STARKNET_RPC_URL} --inputs <OWNER> <BTCVAULT_ADDR> <ZKVERIFIER_ADDR> <ZKBTC_ADDR>"

echo "# Deploy ZKOrderBook (constructor: owner)"
echo "starknet deploy --contract <path_to/ZKOrderBook.sierra> --gateway_url ${STARKNET_RPC_URL} --inputs <OWNER>"

echo "\n# After deploying, capture addresses/class hashes and write them to zeus_service/.env as:
# SWAP_ESCROW_ADDRESS=0x...
# BTC_VAULT_ADDRESS=0x...
# ZK_VERIFIER_ADDRESS=0x...
# ZKBTCTOKEN_ADDRESS=0x...
# STARKNET_ATOMIC_BRIDGE_ADDRESS=0x...
# BITCOIN_BRIDGE_ADDRESS=0x...

echo "Done. Edit the commands above with actual compiled contract paths and deploy order." 
