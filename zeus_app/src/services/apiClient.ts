import axios from 'axios';
import Constants from 'expo-constants';
import { Platform } from 'react-native';

const envUrl = process.env.ZEUS_API_URL || (global as any).ZEUS_API_URL;

function resolveApiHost(): string {
  if (envUrl) return envUrl;

  // Try to extract the host IP from Expo manifest (Expo Go provides debuggerHost)
  const manifest: any = (Constants as any).manifest || (Constants as any).expoConfig;
  const debuggerHost = manifest?.debuggerHost || manifest?.hostUri || manifest?.packagerOpts?.host;

  if (debuggerHost && typeof debuggerHost === 'string') {
    const host = debuggerHost.split(':')[0];
    return `http://${host}:3000`;
  }

  // Emulator / simulator fallbacks
  if (Platform.OS === 'android') return 'http://10.0.2.2:3000';
  return 'http://localhost:3000';
}

const API_BASE = resolveApiHost();

const api = axios.create({
  baseURL: `${API_BASE}/api`,
  timeout: 10000,
});

export function setAuthToken(token: string | null) {
  if (token) api.defaults.headers.common['Authorization'] = `Bearer ${token}`;
  else delete api.defaults.headers.common['Authorization'];
}

export default api;
