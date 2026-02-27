import { Module } from '@nestjs/common';
import { OrderbookService } from './orderbook.service';
import { OrderbookController } from './orderbook.controller';
import { StarknetModule } from '../starknet/starknet.module';
import { AuthModule } from '../auth/auth.module';
import { NotificationModule } from '../notification/notification.module';

@Module({
  imports: [StarknetModule, AuthModule, NotificationModule],
  providers: [OrderbookService],
  controllers: [OrderbookController],
  exports: [OrderbookService],
})
export class OrderbookModule {}
