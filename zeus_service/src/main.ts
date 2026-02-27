import { NestFactory } from '@nestjs/core';
import { AppModule } from './app.module';
import { BitcoinWatchtowerService } from './modules/relayer/watchtower/bitcoin-watchtower.service';

async function bootstrap() {
  const app = await NestFactory.create(AppModule);

  // Start Bitcoin watchtower in development for devnet polling
  if ((process.env.NODE_ENV ?? 'development') === 'development') {
    try {
      const watchtower = app.get(BitcoinWatchtowerService);
      // start in background (non-blocking)
      watchtower.startPolling(5000).catch((e) => console.warn('watchtower error', e));
    } catch (err) {
      // service may not be available in some contexts; ignore
      // eslint-disable-next-line no-console
      console.warn('BitcoinWatchtowerService not available:', err?.message ?? err);
    }
  }

  await app.listen(process.env.PORT ?? 3000);
}

bootstrap();
