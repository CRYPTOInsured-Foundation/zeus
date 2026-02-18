export const fetchEncryptedOrderBook = async () => {
  // Mock data for encrypted orderbook
  return [
    { id: '1', side: 'buy', amount: '0.5 BTC', price: '25000 STRK', privacy: 'High' },
    { id: '2', side: 'sell', amount: '1.2 BTC', price: '60000 STRK', privacy: 'Shielded' },
    { id: '3', side: 'buy', amount: '0.1 BTC', price: '5000 STRK', privacy: 'Quantum-Safe' },
  ];
};

export const submitEncryptedOrder = async (order: any) => {
  console.log('Submitting encrypted order to relayer...', order);
  return { orderId: 'ord_' + Math.random().toString(36).substring(7) };
};
