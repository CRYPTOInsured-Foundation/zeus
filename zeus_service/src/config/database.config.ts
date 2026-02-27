import { TypeOrmModuleOptions } from '@nestjs/typeorm';

export default function getDatabaseConfig(): TypeOrmModuleOptions {
  const url = process.env.POSTGRES_URL;

  return {
    type: 'postgres',
    url,
    synchronize: true,
    logging: false,
    autoLoadEntities: true,
    // keep defaults for now; adjust pool/ssl in env if needed
  } as TypeOrmModuleOptions;
}
