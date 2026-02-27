# Zeus Service — Backend

Zeus Service is the backend for the Zeus protocol: a mobile-first, privacy-preserving swap platform integrating Starknet and Bitcoin. It provides HTTP and realtime APIs for wallet authentication, swap & orderbook flows, Starknet contract integrations, Bitcoin vault operations, and a notification system with in-app and queued delivery.

This README explains how to set up a local development environment (Postgres, Redis, bitcoind/regtest), run the server, and exercise the realtime/mobile flows.

## Key capabilities
- Non-custodial swap workflows with on-chain Starknet escrow helpers.
- Bitcoin vault integration and withdrawal request APIs.
- Nonce-based wallet login and JWT sessions for mobile apps.
- ABI-driven Starknet contract runtime clients and an admin contract proxy.
- In-app notifications with WebSocket delivery, persistent metrics, and queued retry via Redis.
- Compact realtime deltas: `swap.delta`, `order.delta`, `vault.delta` for efficient mobile UI updates.

## Repository layout (important files)
- [src/app.module.ts](src/app.module.ts) — application wiring and TypeORM config.
- [src/modules/notification/notification.gateway.ts](src/modules/notification/notification.gateway.ts) — Socket.IO gateway (authenticate/subscribe/unsubscribe).
- [src/modules/notification/notification.service.ts](src/modules/notification/notification.service.ts) — notification persistence, push, metrics and queue enqueue.
- [src/modules/notification/notification-metric.entity.ts](src/modules/notification/notification-metric.entity.ts) — persisted delivery metrics.
- [src/modules/swap](src/modules/swap) — swap domain APIs and on-chain helpers.
- [src/modules/orderbook](src/modules/orderbook) — orderbook submission and market deltas.
- [src/queue](src/queue) — `QueueService` (Redis) and queue processor scaffolding.

## Prerequisites
- Node.js >= 18
- npm (or yarn)
- Redis (for queue) — single instance is fine for dev
- PostgreSQL — used by TypeORM (or you can use a local Docker DB for dev)
- Bitcoin Core (bitcoind) in `regtest` mode for full Bitcoin flows (optional for some dev modes)

You can run Redis/Postgres/bitcoind locally, or use the Docker Compose recipe below to create a development environment quickly.

## Environment variables
Create a `.env` file in the project root with the values you want. Important variables (defaults shown are development-friendly):

```
PORT=3000
NODE_ENV=development

POSTGRES_URL=postgres://postgres:postgres@localhost:5432/zeus_db
REDIS_URL=redis://127.0.0.1:6379/0

API_KEY=dev-api-key
JWT_SECRET=dev-jwt-secret

# Starknet
STARKNET_RPC_URL=https://alpha4.starknet.io
STARKNET_ACCOUNT_PRIVATE_KEY=
STARKNET_ACCOUNT_ADDRESS=

# Bitcoin RPC (regtest)
BITCOIN_RPC_URL=http://user:pass@127.0.0.1:18443

# Email (optional)
SMTP_HOST=
SMTP_PORT=
SMTP_USER=
SMTP_PASS=
SMTP_FROM=

# Queue & retry tuning
ENABLE_NOTIFICATION_QUEUE=true
NOTIFICATION_MAX_RETRY_ATTEMPTS=5
NOTIFICATION_RETRY_INTERVAL_MS=15000

```

Adjust production secrets and never commit them to source control.

## Quickstart (recommended dev flow)
The easiest way to run everything for local testing is with Docker Compose (you can create containers for Postgres, Redis, and bitcoind/regtest). Example snippet (add to `docker-compose.yml` or run similar containers):

```yaml
version: '3.8'
services:
  postgres:
    image: postgres:15
    environment:
      POSTGRES_PASSWORD: postgres
      POSTGRES_DB: zeus_db
    ports: ['5432:5432']

  redis:
    image: redis:7
    ports: ['6379:6379']

  bitcoind:
    image: ruimarinho/bitcoin-core:24
    command: -regtest -server -rpcallowip=::/0 -rpcbind=0.0.0.0 -rpcuser=user -rpcpassword=pass -fallbackfee=0.0002
    ports: ['18443:18443']

```

After starting containers, set `.env` accordingly and run:

```bash
npm install --legacy-peer-deps
npm run build
npm run start
```

The server starts on `http://localhost:3000` by default. WebSocket gateway is available on the same host using Socket.IO.

## API summary
Not exhaustive — see controllers under `src/modules`.

- Auth
  - `POST /auth/nonce` — request nonce for wallet login
  - `POST /auth/wallet-login` — sign nonce + exchange for JWT
- Notifications
  - `POST /notification/send` — admin: store & send in-app/email/sms
  - `POST /notification/publish` — admin: publish payload to room/topic
  - `GET /notification/inbox` — user JWT: list in-app messages
  - `POST /notification/:id/read` — mark read (user JWT)
  - `GET /notification/metrics` — admin: delivery metrics
- Swap & Orderbook
  - `POST /swap` — create swap order
  - `POST /orderbook/submit` — submit order
  - Realtime deltas emitted as `swap.delta`, `order.delta`, `vault.delta`
- Starknet
  - `POST /starknet/proxy` — admin proxy to call contract ABI methods

Routes are guarded with `ApiKeyGuard` (admin) or `JwtAuthGuard` for user actions. See `src/modules/auth` for details.

## Realtime (mobile) integration notes
- Connect with `socket.io-client` from React Native or web. Example pattern is in `docs/mobile/wallet_auth_examples.md` and `docs/mobile/realtime_component.md`.
- After connecting, authenticate by emitting `authenticate` with `{ token: '<JWT>' }`.
- Subscribe to rooms: emit `subscribe` with `{ room: 'swap:<swapId>' }` or `market:<symbol>` or `vault:<address>`.
- Listen for compact deltas (`swap.delta`, `order.delta`, `vault.delta`) for efficient UI updates and `notification` for full in-app messages.

## Notifications, delivery and retries
- Notifications are persisted (Postgres) and attempted over WebSocket. Delivery attempts are tracked in `notification_metrics`.
- Failed deliveries are enqueued to Redis (`queue:notification_retry`) and processed by a background worker which retries up to `NOTIFICATION_MAX_RETRY_ATTEMPTS`.
- The queue processor lives in `src/queue/notification-queue.processor.ts` and `QueueService` handles enqueue/brpop using Redis.

## Local testing tips
- Use Postman or curl to exercise HTTP endpoints.
- Use `socket.io-client` to test realtime (see docs in `docs/mobile`).
- For Starknet on-chain behavior, set `STARKNET_ACCOUNT_PRIVATE_KEY` and `STARKNET_ACCOUNT_ADDRESS` or use a devnet and deploy contracts with the helper scripts in `scripts/`.
- For Bitcoin flows, run `bitcoind` in regtest and fund a wallet for testing withdrawals.

## Security & production notes
- Rotate and protect `JWT_SECRET` and `API_KEY` in production.
- Replace `synchronize: true` (TypeORM) with proper migrations for production databases.
- Consider persisting retry queues in a robust job system (BullMQ/RabbitMQ) and scaling workers separately.
- Add monitoring/alerting around queue depth and undelivered metrics. Use the `MonitoringModule` hooks already present for instrumentation.

## Contributing
- Follow existing code style and tests. Unit tests live in `test/` and use Jest.
- Open PRs against `main` and include a short description of changes and any migration steps.

## Where to look next
- `src/modules/notification` — realtime + metrics + queue
- `src/modules/swap` — swap life-cycle
- `src/modules/starknet` — contract API factory and Starknet helpers
- `docs/mobile` — RN wallet auth + realtime examples

