// Smoke test: require the compiled Starknet account service and report status
try {
  const path = require('path');
  const file = path.join(__dirname, '..', 'dist', 'modules', 'starknet', 'account.service.js');
  console.log('Checking file:', file);
  const mod = require(file);
  const keys = Object.keys(mod || {});
  console.log('Module exports:', keys);
  if (mod && (mod.StarknetAccountService || mod.default)) {
    console.log('StarknetAccountService appears available.');
    process.exit(0);
  }
  console.error('StarknetAccountService not found in module exports.');
  process.exit(2);
} catch (err) {
  console.error('Smoke test error:', err && err.stack ? err.stack : String(err));
  process.exit(3);
}
