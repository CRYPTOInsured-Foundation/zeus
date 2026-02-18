import React from 'react';
import { View, Text, StyleSheet, ScrollView, TouchableOpacity } from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';
import { useNavigation } from '@react-navigation/native';

const TransactionHistory = () => {
  const navigation = useNavigation();
  const transactions = [
    { id: '1', type: 'SWAP', from: 'BTC', to: 'STRK', amount: '0.05', status: 'CLAIMED', date: 'Feb 12, 14:30' },
    { id: '2', type: 'SWAP', from: 'STRK', to: 'BTC', amount: '500', status: 'REFUNDED', date: 'Feb 10, 09:15' },
    { id: '3', type: 'SWAP', from: 'BTC', to: 'STRK', amount: '0.12', status: 'LOCKED', date: 'Feb 13, 11:20' },
  ];

  return (
    <SafeAreaView style={styles.container}>
      <View style={styles.header}>
        <TouchableOpacity onPress={() => navigation.goBack()}>
          <Text style={styles.backButton}>←</Text>
        </TouchableOpacity>
        <Text style={styles.title}>SEALED SCROLLS</Text>
      </View>
      <ScrollView contentContainerStyle={styles.content}>
        {transactions.map((tx) => (
          <View key={tx.id} style={styles.txItem}>
            <View style={styles.txHeader}>
              <Text style={styles.txType}>{tx.type}</Text>
              <Text style={styles.txDate}>{tx.date}</Text>
            </View>
            <View style={styles.txBody}>
              <Text style={styles.txAssets}>{tx.from} → {tx.to}</Text>
              <Text style={styles.txAmount}>{tx.amount} {tx.from}</Text>
            </View>
            <View style={[styles.statusBadge, tx.status === 'CLAIMED' ? styles.statusSuccess : tx.status === 'LOCKED' ? styles.statusPending : styles.statusFailed]}>
              <Text style={styles.statusText}>{tx.status}</Text>
            </View>
          </View>
        ))}
      </ScrollView>
    </SafeAreaView>
  );
};

const styles = StyleSheet.create({
  container: { flex: 1, backgroundColor: '#020617' },
  header: { flexDirection: 'row', alignItems: 'center', padding: 20 },
  backButton: { color: '#FFD700', fontSize: 24, marginRight: 20 },
  title: { color: '#FFD700', fontSize: 20, fontWeight: 'bold', letterSpacing: 2 },
  content: { padding: 20 },
  txItem: { backgroundColor: '#0B1120', borderRadius: 15, padding: 20, marginBottom: 15, borderWidth: 1, borderColor: '#1E293B' },
  txHeader: { flexDirection: 'row', justifyContent: 'space-between', marginBottom: 10 },
  txType: { color: '#FFD700', fontSize: 12, fontWeight: 'bold' },
  txDate: { color: '#A0A0B0', fontSize: 12 },
  txBody: { flexDirection: 'row', justifyContent: 'space-between', alignItems: 'center', marginBottom: 15 },
  txAssets: { color: '#FFFFFF', fontSize: 18, fontWeight: 'bold' },
  txAmount: { color: '#FFFFFF', fontSize: 16 },
  statusBadge: { alignSelf: 'flex-start', paddingHorizontal: 10, paddingVertical: 4, borderRadius: 10 },
  statusSuccess: { backgroundColor: 'rgba(0, 212, 255, 0.2)' },
  statusPending: { backgroundColor: 'rgba(255, 215, 0, 0.2)' },
  statusFailed: { backgroundColor: 'rgba(196, 30, 58, 0.2)' },
  statusText: { color: '#FFFFFF', fontSize: 10, fontWeight: 'bold' },
});

export default TransactionHistory;
