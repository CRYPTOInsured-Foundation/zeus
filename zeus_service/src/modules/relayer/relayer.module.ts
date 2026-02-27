import { Module } from '@nestjs/common';
import { BitcoinWatchtowerService } from './watchtower/bitcoin-watchtower.service';
import { BitcoinModule } from '../bitcoin/bitcoin.module';

@Module({
  imports: [BitcoinModule],
  providers: [BitcoinWatchtowerService],
  exports: [BitcoinWatchtowerService],
})
export class RelayerModule {}
