#!/usr/bin/env node
const { execSync, spawnSync } = require('child_process');
const fs = require('fs');
const path = require('path');

const ROOT = path.join(__dirname, '..');
const MANIFEST = path.join(ROOT, 'scripts', 'deploy-manifest.json');
const CONTRACTS_ROOT = path.resolve(__dirname, '..', '..', 'zeus_contracts');
const TARGET_DIR = path.join(CONTRACTS_ROOT, 'target');
const ENV_PATH = path.join(ROOT, '.env');

const gateway = process.env.STARKNET_RPC_URL || 'http://127.0.0.1:5050';

function findArtifact(contractName) {
  if (!fs.existsSync(TARGET_DIR)) return null;
  const files = fs.readdirSync(TARGET_DIR);
  const candidates = files.filter(f => f.toLowerCase().includes(contractName.toLowerCase()));
  if (candidates.length === 0) return null;
  // prefer sierra/casm/json
  const pick = candidates.find(f => f.endsWith('.sierra.json')) || candidates.find(f => f.endsWith('.json')) || candidates[0];
  return path.join(TARGET_DIR, pick);
}

function runDeploy(contractPath) {
  console.log('Running deploy for:', contractPath);
  try {
    // If `starknet` CLI is not available this will throw; we echo and return null instead
    const cmd = `starknet deploy --contract ${contractPath} --gateway_url ${gateway}`;
    console.log('exec:', cmd);
    const out = execSync(cmd, { encoding: 'utf8', stdio: 'pipe' });
    console.log(out);
    // Try to extract address from output
    const m = out.match(/(0x[0-9a-fA-F]{1,})/);
    if (m) return m[1];
    return null;
  } catch (err) {
    console.warn('deploy command failed (CLI missing or error). Output:', err.stdout ? err.stdout.toString() : err.message);
    return null;
  }
}

function updateEnv(updates) {
  let env = {};
  if (fs.existsSync(ENV_PATH)) {
    const raw = fs.readFileSync(ENV_PATH, 'utf8');
    raw.split(/\r?\n/).forEach(line => {
      if (!line || line.startsWith('#')) return;
      const idx = line.indexOf('=');
      if (idx === -1) return;
      const k = line.slice(0, idx);
      const v = line.slice(idx+1);
      env[k] = v;
    });
  }
  Object.assign(env, updates);
  const out = Object.entries(env).map(([k,v]) => `${k}=${v}`).join('\n') + '\n';
  fs.writeFileSync(ENV_PATH, out, 'utf8');
  console.log('Updated', ENV_PATH);
}

function main() {
  if (!fs.existsSync(MANIFEST)) {
    console.error('Missing deploy manifest:', MANIFEST);
    process.exit(1);
  }
  const manifest = JSON.parse(fs.readFileSync(MANIFEST, 'utf8'));
  const deployed = {};

  for (const item of manifest.deployOrder || []) {
    console.log('\n--- Deploying', item.name, '---');
    let contractPath = item.path;
    if (contractPath.includes('<artifact>') || !fs.existsSync(contractPath)) {
      const found = findArtifact(item.name) || findArtifact(item.name.replace(/_/g, ''));
      if (found) {
        contractPath = found;
        console.log('Found artifact for', item.name, '=>', contractPath);
      } else {
        console.warn('No compiled artifact found for', item.name, "under", TARGET_DIR);
        console.warn('Please compile contracts in ../zeus_contracts and update deploy-manifest.json with artifact paths. Skipping.');
        continue;
      }
    }

    const addr = runDeploy(contractPath);
    if (addr) {
      deployed[item.name] = addr;
      console.log('Deployed', item.name, 'at', addr);
    } else {
      console.log('Could not auto-deploy', item.name, '- CLI may be missing or returned no address. Please deploy manually and update env.');
    }
  }

  // Map known names to env keys
  const mapping = {
    'SwapEscrow': 'SWAP_ESCROW_ADDRESS',
    'BTCVault': 'BTC_VAULT_ADDRESS',
    'ZKAtomicSwapVerifier': 'ZK_VERIFIER_ADDRESS',
    'ZKBTC': 'ZKBTC_ADDRESS',
    'StarknetAtomicBridge': 'STARKNET_ATOMIC_BRIDGE_ADDRESS',
    'BitcoinBridge': 'BITCOIN_BRIDGE_ADDRESS',
    'ZKOrderBook': 'ZK_ORDERBOOK_ADDRESS'
  };

  const envUpdates = {};
  for (const [name, addr] of Object.entries(deployed)) {
    if (mapping[name]) envUpdates[mapping[name]] = addr;
  }

  if (Object.keys(envUpdates).length > 0) updateEnv(envUpdates);
  else console.log('No addresses to write to .env');
}

main();
