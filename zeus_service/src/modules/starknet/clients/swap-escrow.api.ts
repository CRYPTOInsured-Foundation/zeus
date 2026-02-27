import { createContractApi } from '../contract-utils';

export function createSwapEscrowApi(address: string, starknetService?: any) {
  return createContractApi('SwapEscrow_ABI.json', address, starknetService);
}
