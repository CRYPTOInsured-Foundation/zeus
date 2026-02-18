import { useQuery } from 'react-query';
import { getStarknetBalance } from '@/services/starknetService';

export const useWalletBalance = (address: string | null, type: 'BTC' | 'STRK') => {
  return useQuery(['balance', address, type], async () => {
    if (!address) return '0.00';
    if (type === 'STRK') {
      return await getStarknetBalance(address);
    }
    // Mock BTC balance
    return '1.24';
  }, {
    enabled: !!address,
    refetchInterval: 30000,
  });
};
