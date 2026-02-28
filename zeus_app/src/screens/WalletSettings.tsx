import React from 'react';
import { View, Text, StyleSheet, TouchableOpacity, Alert } from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';
import { useStore } from '@/services/stateStore';
import { useWCManager } from '@/services/walletConnectWrapper';

const WalletSettings = () => {
  const wcAccounts = useStore((s) => s.wcAccounts);
  const { connector, disconnect } = useWCManager();

  const handleDisconnect = async () => {
    try {
      await disconnect();
      Alert.alert('Disconnected', 'WalletConnect session has been disconnected.');
    } catch (e: any) {
      Alert.alert('Error', String(e?.message || e));
    }
  };

  return (
    <SafeAreaView style={styles.container}>
      <View style={styles.header}><Text style={styles.title}>Wallet Settings</Text></View>
      <View style={styles.section}>
        <Text style={styles.sectionTitle}>WalletConnect Accounts</Text>
        {wcAccounts.length === 0 ? (
          <Text style={styles.empty}>No connected accounts</Text>
        ) : wcAccounts.map((a) => (
          <View key={a} style={styles.accountRow}>
            <Text style={styles.accountText}>{a}</Text>
          </View>
        ))}
      </View>
      <TouchableOpacity style={styles.disconnect} onPress={handleDisconnect}>
        <Text style={styles.disconnectText}>Disconnect WalletConnect</Text>
      </TouchableOpacity>
    </SafeAreaView>
  );
};

const styles = StyleSheet.create({
  container: { flex: 1, backgroundColor: '#020617', padding: 16 },
  header: { marginBottom: 12 },
  title: { color: '#FFD700', fontSize: 20, fontWeight: '700' },
  section: { marginTop: 12 },
  sectionTitle: { color: '#A0A0B0', marginBottom: 8 },
  empty: { color: '#888', fontStyle: 'italic' },
  accountRow: { paddingVertical: 8, borderBottomWidth: 1, borderColor: '#111' },
  accountText: { color: '#FFF' },
  disconnect: { marginTop: 24, padding: 12, backgroundColor: '#FF6B6B', borderRadius: 8, alignItems: 'center' },
  disconnectText: { color: '#020617', fontWeight: '800' },
});

export default WalletSettings;
