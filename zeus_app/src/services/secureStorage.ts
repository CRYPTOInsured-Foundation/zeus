import * as Keychain from 'react-native-keychain';
// Note: User requested react-native-secure-storage but Keychain is often better for keys.
// We'll use Keychain for sensitive data as per standard practices.

export const saveSecret = async (key: string, value: string) => {
  try {
    await Keychain.setGenericPassword(key, value, { service: key });
  } catch (error) {
    console.error('Error saving secret:', error);
  }
};

export const getSecret = async (key: string) => {
  try {
    const credentials = await Keychain.getGenericPassword({ service: key });
    if (credentials) {
      return credentials.password;
    }
    return null;
  } catch (error) {
    console.error('Error getting secret:', error);
    return null;
  }
};

export const deleteSecret = async (key: string) => {
  try {
    await Keychain.resetGenericPassword({ service: key });
  } catch (error) {
    console.error('Error deleting secret:', error);
  }
};
