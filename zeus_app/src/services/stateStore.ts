import { create } from 'zustand';

interface WalletState {
  starknetAddress: string | null;
  bitcoinAddress: string | null;
  setStarknetAddress: (address: string | null) => void;
  setBitcoinAddress: (address: string | null) => void;
}

interface SwapState {
  fromToken: 'BTC' | 'STRK';
  toToken: 'BTC' | 'STRK';
  amount: string;
  isPrivate: boolean;
  setFromToken: (token: 'BTC' | 'STRK') => void;
  setToToken: (token: 'BTC' | 'STRK') => void;
  setAmount: (amount: string) => void;
  togglePrivacy: () => void;
}

interface AppState {
  isBiometricsEnabled: boolean;
  theme: 'dark' | 'light';
  setBiometricsEnabled: (enabled: boolean) => void;
  setTheme: (theme: 'dark' | 'light') => void;
}

export const useWalletStore = create<WalletState>((set) => ({
  starknetAddress: null,
  bitcoinAddress: null,
  setStarknetAddress: (address) => set({ starknetAddress: address }),
  setBitcoinAddress: (address) => set({ bitcoinAddress: address }),
}));

export const useSwapStore = create<SwapState>((set) => ({
  fromToken: 'BTC',
  toToken: 'STRK',
  amount: '',
  isPrivate: true,
  setFromToken: (token) => set({ fromToken: token }),
  setToToken: (token) => set({ toToken: token }),
  setAmount: (amount) => set({ amount }),
  togglePrivacy: () => set((state) => ({ isPrivate: !state.isPrivate })),
}));

export const useAppStore = create<AppState>((set) => ({
  isBiometricsEnabled: false,
  theme: 'dark',
  setBiometricsEnabled: (enabled) => set({ isBiometricsEnabled: enabled }),
  setTheme: (theme) => set({ theme }),
}));
