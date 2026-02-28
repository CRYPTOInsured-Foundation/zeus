# Zeus Mobile App

Zero-Knowledge Encrypted Unified Swaps — a mobile-first React Native client for private, trustless BTC ↔ STRK trading. This app connects to the local `zeus_service` NestJS backend (or a deployed instance) and provides wallet-auth, real-time updates, encrypted orderbook interactions, and swap flows.

**Contents**
- **Quickstart** — run backend + Expo Go for local development
- **Architecture** — high level app structure and key modules
- **Wallets & Auth** — supported flows and requirements
- **Realtime** — websocket behavior and room subscriptions
- **Environment & Troubleshooting** — LAN access, firewall, and native WalletConnect notes
- **Files** — useful places to look in the source

**Quickstart**

- Prerequisites: `node` (18+), `npm`, `expo-cli` (or use `npx expo`), and a device on the same Wi‑Fi network as your dev machine.

- Start the local backend (from repo root):

```powershell
cd zeus_service
npm install
npm run start:dev
```

- Start the Expo app (use `--lan` when on the same network):

```powershell
cd zeus_app
npm install
expo start --lan
```

- Open the app in Expo Go on your device. If the app cannot reach the backend automatically, set the API URL explicitly in `App.tsx` before other imports with:

```ts
(global as any).ZEUS_API_URL = 'http://<YOUR_LAN_IP>:3000';
```

Replace `<YOUR_LAN_IP>` with your machine's IPv4 address (see `ipconfig` on Windows).

**Architecture**
- **Front-end:** React Native (Expo), TypeScript, `zustand` unified store, `react-query` for server caching.
- **Key client modules:**
  - `src/services/apiClient.ts` — axios client and `setAuthToken` helper.
  - `src/services/socket.ts` — `socket.io-client` wrapper and event listeners for `notification`, `orderbook:update`, `swap:update`.
  - `src/services/stateStore.ts` — unified `useStore` (auth, wallet, swap, orderbook, notifications).
  - `src/services/walletAuth.ts` — signing helpers for Starknet wallets (Argent/Braavos), Bitcoin (Xverse via `sats-connect`), and `WalletConnect` flows.
  - `src/services/WCSessionManager.tsx` and `components/WalletConnect.tsx` — WalletConnect integration and session sync.

**Wallets & Authentication**
- Supported flows:
  - WalletConnect sessions (preferred for multi-wallet support).
  - Starknet injected providers (Argent/Braavos) via `starknet` helpers.
  - Xverse / Bitcoin sign via `sats-connect` (optional dependency).
- Auth flow summary:
  1. Client requests a nonce from `/api/auth/nonce` with wallet `address`.
 2. Wallet signs the nonce. Client posts signature to `/api/auth/wallet-login`.
 3. Server returns a JWT which is stored via secure storage and passed to `apiClient` via `setAuthToken`.

**Realtime / WebSockets**
- The client uses Socket.IO and after connect emits `authenticate` with the JWT so the backend maps socket ⇄ user.
- Subscriptions use `subscribe`/`unsubscribe` room commands for topics like `orderbook`, `swap:<id>`, and `vault:<address>`.
- Incoming events update the `useStore` (notifications, orderbook deltas, swap updates).

**Environment & Troubleshooting**
- LAN access: ensure your device and dev machine are on the same network and Windows Firewall allows incoming connections to Node (port 3000).
- Expo host mode: prefer `expo start --lan` to allow manifest detection of debugger host used by `src/services/apiClient.ts`.
- Native WalletConnect notes:
  - `@walletconnect/react-native-dapp` and `react-native-get-random-values` are in `optionalDependencies`. For proper native behavior follow the package install and platform setup (pods for iOS, prebuild for Android).
  - If native WalletConnect is not set up, fallback signing flows may be used (mocks/dynamic requires).

**WalletConnect (optional) & alternatives**

- This app supports WalletConnect but the package is optional to avoid native build failures on some developer machines (Windows without native toolchain, older Node versions).
- If you can't or don't want to install native dependencies, use the following alternatives:
  - Bitcoin wallets: `sats-connect` (already included) — works via deep links and doesn't require native C++ build tools.
  - Starknet wallets: use injected providers (Argent/Braavos) via the `starknet` helpers in `src/services/walletAuth.ts`.

- Enabling WalletConnect (when you have native toolchain):
  1. Install packages:

```bash
cd zeus_app
npm install @walletconnect/react-native-dapp react-native-get-random-values
```

  2. If on macOS and using native modules: `npx pod-install ios`.
  3. The app will dynamically load WalletConnect when available. If the package is not installed the UI falls back and wallet connect buttons use the alternative flows above.

  **Platform-specific notes (Linux & macOS)**

  - Prerequisites (recommended): `node` (18+), `npm` or `pnpm`, `npx`, and the Expo CLI (`npm install -g expo-cli` or use `npx expo`). On macOS, install Homebrew (https://brew.sh/) to manage native packages.

  - Finding your LAN IP (use this when setting `ZEUS_API_URL` for devices):
    - macOS (Wi‑Fi):

      ```bash
      ipconfig getifaddr en0
      ```

    - macOS (all interfaces) / Linux:

      ```bash
      ifconfig   # or: ip addr show
      ```

    - Linux (quick):

      ```bash
      hostname -I | awk '{print $1}'
      ```

  - iOS simulator (macOS):
    - The iOS Simulator can use `localhost` to reach your machine. To test on simulator, run `expo start` and press `i` to open the simulator, or use `expo run:ios` for a native build.
    - If using native WalletConnect or other native modules, run `npx pod-install ios` (or `cd ios && pod install`) after any native module install.

  - Android emulator:
    - The Android emulator maps host `localhost` to `10.0.2.2` in most setups. The app's `apiClient` already falls back to `http://10.0.2.2:3000` for Android emulators.

  - CocoaPods (macOS native builds):
    - Install CocoaPods if you plan to run native iOS flows: `brew install cocoapods` or `sudo gem install cocoapods`.
    - After native dependency installs: `npx pod-install ios`.

  - Firewall / networking:
    - macOS: System Settings → Network → Firewall → allow incoming connections for `node`/Terminal, or temporarily disable Firewall while testing.
    - Linux (ufw): `sudo ufw allow 3000/tcp` (or configure your distro firewall accordingly).

  - Native WalletConnect notes (macOS/Linux):
    - `@walletconnect/react-native-dapp` and `react-native-get-random-values` require native linking or prebuild steps for real WalletConnect behavior. On macOS run `npx pod-install ios` and for Android follow Expo/React Native docs for adding native packages.
    - If you are using Expo managed workflow but need native modules, run `expo prebuild` and follow platform-specific install steps, or use EAS build.

  **Quick macOS checklist**

  ```bash
  # 1) Install homebrew (if needed)
  # /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  brew install cocoapods

  # 2) Backend
  cd zeus_service
  npm install
  npm run start:dev

  # 3) App
  cd ../zeus_app
  npm install
  npx pod-install ios   # only if using native modules / building for iOS
  expo start --lan
  ```

  **Quick Linux checklist**

  ```bash
  # 1) Backend
  cd zeus_service
  npm install
  npm run start:dev

  # 2) App
  cd ../zeus_app
  npm install
  expo start --lan

  # 3) If firewall blocks port 3000
  sudo ufw allow 3000/tcp
  ```

**Design / Assets**
- App uses `assets/zeus_logo.png`. Screens have been updated to render the logo responsively (Landing/Home). See `src/screens/LandingScreen.tsx` and `src/screens/HomeScreen.tsx`.

**Files & Entrypoints**
- App entry: `App.tsx` — sets up providers (WalletConnect, react-query, navigation).
- Navigator: `src/navigation/AppNavigator.tsx` — app routes and screens.
- Stores: `src/services/stateStore.ts` — unified zustand store.
- API client: `src/services/apiClient.ts`.
- Socket: `src/services/socket.ts`.
- Wallet helpers: `src/services/walletAuth.ts`.

**Project structure (key files & folders)**

```
zeus_app/
├─ app.json
├─ App.tsx
├─ assets/
│  ├─ adaptive-icon.png
│  ├─ favicon.png
│  ├─ icon.png
│  ├─ splash-icon.png
│  └─ zeus_logo.png
├─ abis/
├─ android/
├─ babel.config.js
├─ package.json
├─ tsconfig.json
└─ src/
  ├─ components/
  │  ├─ atomic-swap/
  │  ├─ OrderBook.tsx
  │  ├─ WalletConnect.tsx
  │  └─ ZKProofStatus.tsx
  ├─ hooks/
  │  ├─ useAtomicSwap.ts
  │  ├─ useSocket.ts
  │  ├─ useWalletBalance.ts
  │  └─ useZKProof.ts
  ├─ navigation/
  │  └─ AppNavigator.tsx
  ├─ screens/
  │  ├─ HomeScreen.tsx
  │  ├─ InboxDetailScreen.tsx
  │  ├─ InboxScreen.tsx
  │  ├─ LandingScreen.tsx
  │  ├─ PortfolioScreen.tsx
  │  ├─ PrivacySettings.tsx
  │  ├─ SwapScreen.tsx
  │  ├─ TransactionHistory.tsx
  │  └─ WalletSettings.tsx
  ├─ services/
  │  ├─ apiClient.ts
  │  ├─ bitcoinService.ts
  │  ├─ relayerService.ts
  │  ├─ secureStorage.ts
  │  ├─ socket.ts
  │  ├─ starknetService.ts
  │  ├─ stateStore.ts
  │  ├─ walletAuth.ts
  │  ├─ walletConnectWrapper.tsx
  │  ├─ WCSessionManager.tsx
  │  └─ zkProofService.ts
  └─ utils/
    ├─ bitcoinScript.ts
    ├─ cryptoUtils.ts
    └─ zkCircuits.ts
```
---
## QR Code: 
![WhatsApp Image 2026-02-28 at 10 26 13 AM](https://github.com/user-attachments/assets/cfc96b49-1b44-4899-8f0f-ccd6ee8e5a1e)

---
## 📱 Screens

<table style="width: 100%; text-align: center;">
  <tr>
    <td width="33%"><img src="https://github.com/user-attachments/assets/e855de18-af05-4325-8329-337cdc6eacc3" alt="Screen 1" /></td>
    <td width="33%"><img src="https://github.com/user-attachments/assets/b18b042c-9893-47df-9f63-04924021562b" alt="Screen 2" /></td>
    <td width="33%"><img src="https://github.com/user-attachments/assets/885d3392-95ff-4479-a19c-4b99c47d5102" alt="Screen 3" /></td>
  </tr>
  <tr>
    <td><img src="https://github.com/user-attachments/assets/f57d1f24-14f1-47fb-a6e7-6f5911c77df0" alt="Screen 4" /></td>
    <td><img src="https://github.com/user-attachments/assets/eed9940d-76ec-4237-bc0c-f2b6b3ea2bf3" alt="Screen 5" /></td>
    <td><img src="https://github.com/user-attachments/assets/aade90e6-a2a3-48bb-b2e8-2952fc4122b7" alt="Screen 6" /></td>
  </tr>
  <tr>
    <td><img src="https://github.com/user-attachments/assets/1ed4f237-0075-41d0-b490-66f6b46beac4" alt="Screen 7" /></td>
    <td><img src="https://github.com/user-attachments/assets/a87c09dd-9ed5-44b5-ba46-eed276baa5cb" alt="Screen 8" /></td>
    <td><img src="https://github.com/user-attachments/assets/9011092a-b127-467c-b688-19dee3103083" alt="Screen 9" /></td>
  </tr>
</table>

---
**Development tips**
- If the app can't authenticate via wallets locally, verify the backend `zeus_service` is reachable and the `/api/auth/nonce` route returns a nonce.
- When testing WalletConnect flows, ensure deep link / redirect URL (`zeusapp://`) is registered for native builds and that Expo/WalletConnect settings match.

**Contributing**
- Please open PRs against the `zeus_app` folder. Keep UI/UX changes separated from core networking/auth changes. Add tests for any logic-heavy helpers.

**License & Contact**
- See repository LICENSE (root) for terms. For questions, check the project README at the repository root.
