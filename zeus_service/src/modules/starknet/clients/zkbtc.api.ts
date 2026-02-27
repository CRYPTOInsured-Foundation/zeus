import { createContractApi } from '../contract-utils';

export function createZkBTCApi(address: string, starknetService?: any) {
  return createContractApi('ZKBTC_ABI.json', address, starknetService);
}
