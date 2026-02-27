import { Module } from '@nestjs/common';
import { bitcoinRpcProvider } from './providers/bitcoin-rpc.provider';
import { BitcoinVaultService } from './bitcoin-vault.service';
import { BitcoinController } from './bitcoin.controller';
import { StarknetModule } from '../starknet/starknet.module';
import { AuthModule } from '../auth/auth.module';
import { NotificationModule } from '../notification/notification.module';

@Module({
  imports: [StarknetModule, AuthModule, NotificationModule],
  providers: [bitcoinRpcProvider, BitcoinVaultService],
  exports: [bitcoinRpcProvider, BitcoinVaultService],
  controllers: [BitcoinController],
})
export class BitcoinModule {}
