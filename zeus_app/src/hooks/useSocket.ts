import { useEffect, useState } from 'react';
import { initSocket, getSocket } from '../services/socket';

export default function useSocket() {
  const [connected, setConnected] = useState(false);

  useEffect(() => {
    let mounted = true;

    initSocket().then((s) => {
      if (!mounted) return;
      setConnected(!!s.connected);
      s.on('connect', () => setConnected(true));
      s.on('disconnect', () => setConnected(false));
    }).catch(() => {});

    return () => {
      mounted = false;
      const s = getSocket();
      if (s) {
        s.off('connect');
        s.off('disconnect');
      }
    };
  }, []);

  return { connected, socket: getSocket() } as const;
}
