import { createContractApi } from '../contract-utils';

export function createBitcoinBridgeApi(address: string, starknetService?: any) {
  return createContractApi('BitcoinBridge_ABI.json', address, starknetService);
}
