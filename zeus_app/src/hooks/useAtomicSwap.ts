import { useState } from 'react';
import { createHTLC, claimHTLC } from '@/services/bitcoinService';
import { executeStarknetSwap } from '@/services/starknetService';

export const useAtomicSwap = () => {
  const [status, setStatus] = useState<'idle' | 'locking' | 'locked' | 'claiming' | 'completed' | 'failed'>('idle');

  const startSwap = async (amount: string, secretHash: string) => {
    setStatus('locking');
    try {
      // 1. Lock on Bitcoin
      const btcHtlc = await createHTLC(parseFloat(amount), 24, secretHash);
      
      // 2. Lock on Starknet
      const starknetTx = await executeStarknetSwap(amount, secretHash);
      
      setStatus('locked');
      return { btcHtlc, starknetTx };
    } catch (e) {
      setStatus('failed');
      throw e;
    }
  };

  return { startSwap, status };
};
