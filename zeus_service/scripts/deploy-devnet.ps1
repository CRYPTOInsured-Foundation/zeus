# PowerShell scaffold for deploying Zeus contracts to a local Starknet devnet
param(
  [string]$DevnetUrl = "http://127.0.0.1:5050"
)

Write-Host "Starknet devnet URL: $DevnetUrl"

Write-Host "1) Start starknet-devnet (if not running):"
Write-Host "   starknet-devnet --port 5050 &"

Write-Host "2) Example deploy commands (fill compiled contract paths and constructor inputs):"
Write-Host "   # Deploy ZKBTC"
Write-Host "   starknet deploy --contract <path_to/ZKBTC.sierra> --gateway_url $DevnetUrl --inputs <OWNER> 'ZKBTC' 'ZKBTC' 18 0 340282366920938463463374607431768211455 <FEE_COLLECTOR>"

Write-Host "   # Deploy BTCVault"
Write-Host "   starknet deploy --contract <path_to/BTCVault.sierra> --gateway_url $DevnetUrl --inputs <OWNER> <ZKBTC_ADDR> 3"

Write-Host "   # Deploy SwapEscrow"
Write-Host "   starknet deploy --contract <path_to/SwapEscrow.sierra> --gateway_url $DevnetUrl --inputs <OWNER> <FEE_COLLECTOR>"

Write-Host "   # Deploy StarknetAtomicBridge"
Write-Host "   starknet deploy --contract <path_to/StarknetAtomicBridge.sierra> --gateway_url $DevnetUrl --inputs <OWNER> <BTCVAULT_ADDR> <SWAPESCROW_ADDR> <ZKVERIFIER_ADDR> <ZKBTC_ADDR> <STRK_ADDR>"

Write-Host "   # Deploy BitcoinBridge"
Write-Host "   starknet deploy --contract <path_to/BitcoinBridge.sierra> --gateway_url $DevnetUrl --inputs <OWNER> <BTCVAULT_ADDR> <ZKVERIFIER_ADDR> <ZKBTC_ADDR>"

Write-Host "3) After deploy, save addresses to zeus_service/.env"
