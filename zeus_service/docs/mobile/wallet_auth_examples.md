# Wallet Login (nonce + signature) Examples for React Native

This document shows a concise flow to authenticate mobile wallets (Braavos, Argent, Xverse, Leather) against the Zeus backend using the implemented nonce → signature → JWT flow.

Server endpoints
- `POST /auth/nonce`  { address }
- `POST /auth/wallet-login` { address, signature, publicKey? }
- Protected endpoints require `Authorization: Bearer <jwt>` (e.g. `GET /notification/inbox`).

General client flow
1. Request nonce: POST `/auth/nonce` body `{ address }`.
2. Ask the wallet to sign the nonce string.
3. Normalize signature (server accepts array or hex string - we normalize before sending).
4. POST `/auth/wallet-login` with `{ address, signature, publicKey? }` to receive JWT.
5. Store JWT securely (SecureStore / AsyncStorage) and send as `Authorization: Bearer <jwt>`.

Signature normalization helper (JS)

```js
function normalizeSignature(signature) {
  // signature may be an array [r, s] or a hex string '0x<r><s>' or various wallet SDK formats
  if (Array.isArray(signature)) return signature;
  if (typeof signature === 'string') {
    const hex = signature.replace(/^0x/, '');
    const half = Math.floor(hex.length / 2);
    const r = '0x' + hex.slice(0, half);
    const s = '0x' + hex.slice(half);
    return [r, s];
  }
  // fallback: stringify
  return [String(signature)];
}
```

Generic RN snippet (pseudo-code)

```js
// backendBaseUrl e.g. 'https://api.example.com'
async function walletLogin(walletProvider, backendBaseUrl, walletAddress) {
  // 1. get nonce
  const nonceRes = await fetch(`${backendBaseUrl}/auth/nonce`, {
    method: 'POST', headers: {'Content-Type':'application/json'},
    body: JSON.stringify({ address: walletAddress })
  });
  const { nonce } = await nonceRes.json();

  // 2. wallet signs nonce
  // Wallet SDK differs — common: signMessage(nonce) or signMessageHex(nonceHex)
  const signResult = await walletProvider.signMessage(nonce); // adapt per wallet
  const signature = signResult.signature ?? signResult;
  const publicKey = signResult.publicKey ?? undefined;

  // 3. normalize
  const sigNorm = normalizeSignature(signature);

  // 4. exchange for JWT
  const loginRes = await fetch(`${backendBaseUrl}/auth/wallet-login`, {
    method: 'POST', headers: {'Content-Type':'application/json'},
    body: JSON.stringify({ address: walletAddress, signature: sigNorm, publicKey })
  });
  const json = await loginRes.json();
  const jwt = json.token;
  return jwt;
}
```

Per-wallet notes & tips

- Braavos
  - Braavos mobile typically exposes `window.starknet` or a provider with `signMessage` returning signature array or hex; call `signMessage(nonce)` and pass resulting signature and optional publicKey to the backend.
  - Example: `const { signature, publicKey } = await braavosProvider.signMessage(nonce);`

- Argent / Argent X (mobile-ready wallets)
  - Argent family exposes `signMessage` that may return two-felt array or hex; use `normalizeSignature` to ensure server-friendly format.
  - Argent often supplies the public key in the signature response — include it to allow server verification.

- Xverse
  - Xverse APIs vary; many wallets provide `signMessage` or `signMessageHex`. If you receive a hex string, the client snippet above will split it; include `publicKey` if provided.

- Leather
  - Leather's mobile SDK usually returns signature as hex; normalize by splitting into two felts as above.

Server expectations & compatibility
- The backend attempts to verify using the installed `starknet` lib if available and `publicKey` was provided.
- The server accepts either a signature array (`[r, s]`) or a hex string. The client normalization above sends an array form which works across both formats.
- In development (NODE_ENV != production), the server accepts the login even if verification cannot be performed. For production, ensure:
  - `starknet` lib present on server
  - Wallet provides an on-chain public key or the signature format that can be verified off-chain.

React Native storage & usage
- Store JWT securely (recommend SecureStore or Keychain). Use AsyncStorage only for dev.

```js
// save
await SecureStore.setItemAsync('jwt', jwt);
// use
const token = await SecureStore.getItemAsync('jwt');
fetch('/notification/inbox', { headers: { Authorization: `Bearer ${token}` } });
```

Troubleshooting
- If login returns `nonce not found or expired` -> request a new nonce.
- If login returns `signature verification failed` -> check the wallet's signature format and include `publicKey` if available. Log the signature on the client (do not share secrets) to confirm format.
- If verification fails only on server: ensure `starknet` lib version on server supports `ec.verify` and `hash.computeHashOnElements`.

If you want, I can add small per-wallet micro-snippets using specific SDK calls (e.g. Braavos provider sample, ArgentX mobile sample). Tell me which exact RN wallet SDK(s) you will integrate and I will add concrete code tailored to those SDKs.

Realtime (WebSocket) client — reconnection, backoff, subscribe

Below are short examples using `socket.io-client` (works in browser and React Native with the client package). These show: connect, authenticate with JWT, subscribe/unsubscribe to rooms, and an exponential reconnect/backoff strategy.

Browser / RN (socket.io-client) example

```js
import { io } from 'socket.io-client';

function createRealtimeClient(serverUrl, jwt) {
  // socket.io has built-in reconnect with backoff; configure conservatively
  const socket = io(serverUrl, {
    auth: { token: jwt },
    transports: ['websocket'],
    reconnection: true,
    reconnectionAttempts: 10,
    reconnectionDelay: 1000,
    reconnectionDelayMax: 10000,
  });

  socket.on('connect', () => {
    console.log('ws connected', socket.id);
    // prefer explicit auth event so token isn't leaked in querystrings
    socket.emit('authenticate', { token: jwt });
  });

  socket.on('connect_error', (err) => {
    console.warn('connect_error', err);
  });

  socket.on('disconnect', (reason) => {
    console.log('ws disconnected', reason);
  });

  // subscribe to a room/topic
  function subscribe(room) {
    socket.emit('subscribe', { room });
  }
  function unsubscribe(room) {
    socket.emit('unsubscribe', { room });
  }

  // listen for concise deltas
  socket.on('swap.delta', (d) => console.log('swap delta', d));
  socket.on('order.delta', (d) => console.log('order delta', d));
  socket.on('vault.delta', (d) => console.log('vault delta', d));

  // fallback generic notification channel
  socket.on('notification', (n) => console.log('notification', n));

  return { socket, subscribe, unsubscribe };
}

// Usage example
// const { socket, subscribe } = createRealtimeClient('http://localhost:3000', '<JWT>');
// subscribe('swap:<swapId>');
// subscribe('market:BTC-USD');
```

Notes
- Use the `authenticate` event immediately after connect to attach the JWT. The server maps sockets to userIds.
- Prefer listening to specific delta channels (`swap.delta`, `order.delta`, `vault.delta`) to receive compact real-time updates suitable for UI state updates.
- The server also emits full `notification` records for stored in-app notifications; rely on deltas when you only need a lightweight update.

React Native specifics
- If using `socket.io-client` in RN, install `socket.io-client` and use the same code. Ensure network permissions and correct server URL (use IP for emulators when needed).
- For robust reconnection on background/foreground transitions, re-check token validity on `AppState` changes and re-authenticate if necessary.

If you want, I can add a small RN component example that hooks into your Redux/Context store to apply delta updates to UI state.
