import { createContractApi } from '../contract-utils';

export function createBTCVaultApi(address: string, starknetService?: any) {
  return createContractApi('BTCVault_ABI.json', address, starknetService);
}
