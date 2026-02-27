// Minimal sample that uses the compiled StarknetAccountService to invoke a contract.
// Usage: set STARKNET_ACCOUNT_PRIVATE_KEY and STARKNET_ACCOUNT_ADDRESS in .env
// then run: node scripts/starknet-invoke-sample.js <contractAddress> <entrypoint> [calldata...]
const path = require('path');
const dotenv = require('dotenv');
dotenv.config({ path: path.join(__dirname, '..', '.env') });

async function main() {
  try {
    const [,, contractAddress, entrypoint, ...calldata] = process.argv;
    if (!contractAddress || !entrypoint) {
      console.error('Usage: node scripts/starknet-invoke-sample.js <contractAddress> <entrypoint> [calldata...]');
      process.exit(2);
    }

    // require the compiled account service from dist
    const svcPath = path.join(__dirname, '..', 'dist', 'modules', 'starknet', 'account.service.js');
    const mod = require(svcPath);
    const ServiceClass = mod && (mod.StarknetAccountService || mod.default);
    if (!ServiceClass) {
      console.error('StarknetAccountService not found in compiled module:', svcPath);
      process.exit(3);
    }

    // Minimal config provider: we only need get() for env keys used in the service.
    const config = { get: (k) => process.env[k] };

    // load the StarknetService stub as well (compiled)
    const starknetSvcPath = path.join(__dirname, '..', 'dist', 'modules', 'starknet', 'starknet.service.js');
    const starknetMod = require(starknetSvcPath);
    const StarknetService = starknetMod && (starknetMod.StarknetService || starknetMod.default);
    const starknet = StarknetService ? new StarknetService() : { invokeContract: async () => ({ status: 'stub' }) };

    const svc = new ServiceClass(config, starknet);

    console.log('Invoking', entrypoint, 'on', contractAddress, 'with calldata', calldata);
    const res = await svc.invoke(contractAddress, entrypoint, calldata);
    console.log('Invoke result:', JSON.stringify(res, null, 2));
  } catch (err) {
    console.error('Sample invoke failed:', err && err.stack ? err.stack : String(err));
    process.exit(4);
  }
}

main();
