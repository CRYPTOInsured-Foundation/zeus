let storeGetter: (() => any) | null = null;

export const setStoreGetter = (g: () => any) => {
  storeGetter = g;
};

export const getStoreGetter = () => storeGetter;

export default {
  setStoreGetter,
  getStoreGetter,
};
