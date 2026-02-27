import { Injectable, Logger } from '@nestjs/common';

@Injectable()
export class WalletService {
  private readonly logger = new Logger(WalletService.name);

  async connect(providerName: string, opts: any = {}) {
    this.logger.debug(`connect provider=${providerName}`);
    return { connected: true, provider: providerName };
  }

  async signMessage(address: string, message: string) {
    // dev stub — do not use in production
    return `sig_${address}_${message}`;
  }
}
