// Simple test script to POST a swap to the running API
const axios = require('axios');
const path = require('path');
const dotenv = require('dotenv');
dotenv.config({ path: path.join(__dirname, '..', '.env') });

async function main() {
  try {
    const url = `http://localhost:${process.env.PORT || 3000}/swap`;
    const body = {
      initiator: '0x1',
      counterparty: '0x2',
      tokenA: '0x3',
      tokenB: '0x4',
      amountA: '1000',
      amountB: '2000',
      timelock: Math.floor(Date.now() / 1000) + 3600,
    };
    console.log('POST', url, 'body:', body);
    const res = await axios.post(url, body, { timeout: 10000 });
    console.log('Response status:', res.status);
    console.log('Response data:', res.data);
  } catch (err) {
    if (err.response) {
      console.error('HTTP error:', err.response.status, err.response.data);
    } else {
      console.error('Request failed:', err.message);
    }
    process.exit(2);
  }
}

main();
