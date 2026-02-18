import React from 'react';
import { View, Text, StyleSheet } from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';
import { useNavigation } from '@react-navigation/native';
import WalletConnect from '@/components/WalletConnect';

const LandingScreen = () => {
  const navigation = useNavigation<any>();

  const handleConnect = () => {
    navigation.navigate('Home');
  };

  return (
    <SafeAreaView style={styles.container}>
      <View style={styles.content}>
        <Text style={styles.logoText}>ZEUS</Text>
        <Text style={styles.tagline}>Private BTC ↔ STRK swaps on Starknet</Text>
        <View style={styles.card}>
          <Text style={styles.cardTitle}>Connect Wallet</Text>
          <WalletConnect type="Starknet" onConnect={handleConnect} />
          <WalletConnect type="Bitcoin" onConnect={handleConnect} />
        </View>
      </View>
    </SafeAreaView>
  );
};

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#020617',
  },
  content: {
    flex: 1,
    padding: 24,
    justifyContent: 'center',
  },
  logoText: {
    fontSize: 40,
    fontWeight: 'bold',
    color: '#FFD700',
    letterSpacing: 6,
    textAlign: 'center',
    marginBottom: 12,
  },
  tagline: {
    color: '#A0A0B0',
    fontSize: 14,
    textAlign: 'center',
    marginBottom: 32,
  },
  card: {
    backgroundColor: '#0B1120',
    borderRadius: 20,
    padding: 20,
    borderWidth: 1,
    borderColor: '#1E293B',
  },
  cardTitle: {
    color: '#FFFFFF',
    fontSize: 16,
    fontWeight: 'bold',
    marginBottom: 16,
  },
});

export default LandingScreen;

