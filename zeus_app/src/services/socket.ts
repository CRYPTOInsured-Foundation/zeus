import { io, Socket } from 'socket.io-client';
import { getSecret } from './secureStorage';
import { getStoreGetter } from './storeRef';

const WS_URL = process.env.ZEUS_WS_URL || 'http://localhost:3000';

let socket: Socket | null = null;

function attachListeners(s: Socket) {
  // push in-app notifications into the store
  s.on('notification', (payload: any) => {
    try {
      const getter = getStoreGetter();
      getter && getter().pushNotification && getter().pushNotification(payload);
    } catch (e) {
      console.warn('pushNotification failed', e);
    }
  });

  // generic room publish updates may indicate orderbook changes
  s.on('orderbook:update', async () => {
    try {
      const getter = getStoreGetter();
      getter && getter().fetchOrders && await getter().fetchOrders();
    } catch (e) {}
  });

  // swap updates: surface as lightweight notifications
  s.on('swap:update', (payload: any) => {
    try {
      const getter = getStoreGetter();
      getter && getter().pushNotification && getter().pushNotification({ title: 'Swap update', body: JSON.stringify(payload), data: payload });
    } catch (e) {}
  });

  s.on('connect_error', (err) => {
    console.warn('Socket connect_error', err);
  });
}

export async function initSocket(): Promise<Socket> {
  if (socket) {
    // if socket exists, ensure authentication is emitted when token available
    const tokenNow = await getSecret('authToken');
    if (tokenNow) {
      if (socket.connected) socket.emit('authenticate', { token: tokenNow });
      else socket.once('connect', () => socket?.emit('authenticate', { token: tokenNow }));
    }
    return socket;
  }

  socket = io(WS_URL, {
    transports: ['websocket'],
    autoConnect: false,
    reconnection: true,
  });

  attachListeners(socket);

  const token = await getSecret('authToken');

  socket.on('connect', () => {
    if (token) socket?.emit('authenticate', { token });
  });

  socket.connect();

  return socket;
}

export function getSocket(): Socket | null {
  return socket;
}

export function subscribe(room: string) {
  socket?.emit('subscribe', { room });
}

export function unsubscribe(room: string) {
  socket?.emit('unsubscribe', { room });
}

export function closeSocket() {
  socket?.disconnect();
  socket = null;
}
