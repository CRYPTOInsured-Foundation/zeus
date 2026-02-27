import { createContractApi } from '../contract-utils';

export function createZeusGovTokenApi(address: string, starknetService?: any) {
  return createContractApi('ZEUS_GOVTOKEN_ABI.json', address, starknetService);
}
