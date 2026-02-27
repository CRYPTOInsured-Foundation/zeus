export default () => ({
  starknetRpcUrl: process.env.STARKNET_RPC_URL ?? 'http://127.0.0.1:5050',
  accountPrivateKey: process.env.STARKNET_ACCOUNT_PRIVATE_KEY,
  accountAddress: process.env.STARKNET_ACCOUNT_ADDRESS,
});
