import { Injectable, Logger } from '@nestjs/common';

@Injectable()
export class ZkService {
  private readonly logger = new Logger(ZkService.name);

  async generateProof(data: any) {
    this.logger.debug('generateProof');
    return { proof: 'proof_dummy', publicSignals: [] };
  }

  async verifyProof(proof: any) {
    this.logger.debug('verifyProof');
    return { valid: true };
  }
}
