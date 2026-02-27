import axios from 'axios';

export const BITCOIN_RPC = 'BITCOIN_RPC';

export const bitcoinRpcProvider = {
  provide: BITCOIN_RPC,
  useFactory: () => {
    const url = process.env.BITCOIN_RPC_URL;
    if (!url) {
      throw new Error('BITCOIN_RPC_URL not set in environment');
    }

    return {
      call: async (method: string, params: any[] = []) => {
        const payload = { jsonrpc: '1.0', id: 'zeus', method, params };
        const res = await axios.post(url, payload, { timeout: 15000 });
        return res.data;
      },
    };
  },
};
