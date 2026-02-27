import { createContractApi } from '../contract-utils';

export function createZkOrderBookApi(address: string, starknetService?: any) {
  return createContractApi('ZKOrderBook_ABI.json', address, starknetService);
}
