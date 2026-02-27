import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { StarknetService } from './starknet.service';
import { StarknetAccountService } from './account.service';
import { StarknetProxyService } from './starknet-proxy.service';
import { StarknetController } from './starknet.controller';

@Module({
  imports: [ConfigModule],
  providers: [StarknetService, StarknetAccountService, StarknetProxyService],
  controllers: [StarknetController],
  exports: [StarknetService, StarknetAccountService, StarknetProxyService],
})
export class StarknetModule {}
