import React, { useEffect } from 'react';
import { useWC } from './walletConnectWrapper';
import { useStore } from './stateStore';

export default function WCSessionManager() {
  const connector = useWC();
  const setWcAccounts = useStore((s) => s.setWcAccounts);

  useEffect(() => {
    try {
      if (connector?.connected) {
        const accounts = connector.accounts || [];
        setWcAccounts(accounts.map((a: any) => String(a)));
      } else {
        setWcAccounts([]);
      }
    } catch (e) {
      setWcAccounts([]);
    }
  }, [connector?.connected, connector?.accounts?.length]);

  return null;
}
