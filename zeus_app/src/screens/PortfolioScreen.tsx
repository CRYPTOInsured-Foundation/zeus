import React from 'react';
import { View, Text, StyleSheet, ScrollView, TouchableOpacity } from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';
import { useNavigation } from '@react-navigation/native';

const PortfolioScreen = () => {
  const navigation = useNavigation();
  return (
    <SafeAreaView style={styles.container}>
      <View style={styles.header}>
        <TouchableOpacity onPress={() => navigation.goBack()}>
          <Text style={styles.backButton}>←</Text>
        </TouchableOpacity>
        <Text style={styles.title}>MY TREASURY</Text>
      </View>
      <ScrollView contentContainerStyle={styles.content}>
        <View style={styles.statCard}>
          <Text style={styles.statLabel}>Total Shielded Value</Text>
          <Text style={styles.statValue}>$42,069.00</Text>
        </View>
        <View style={styles.assetList}>
          <Text style={styles.sectionTitle}>ASSETS</Text>
          <View style={styles.assetItem}>
            <Text style={styles.assetName}>Bitcoin (BTC)</Text>
            <Text style={styles.assetAmount}>1.24 BTC</Text>
          </View>
          <View style={styles.assetItem}>
            <Text style={styles.assetName}>Starknet (STRK)</Text>
            <Text style={styles.assetAmount}>12,450.00 STRK</Text>
          </View>
        </View>
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
  statCard: { backgroundColor: '#0B1120', padding: 25, borderRadius: 20, marginBottom: 30, borderWidth: 1, borderColor: '#1E293B' },
  statLabel: { color: '#A0A0B0', fontSize: 14, marginBottom: 5 },
  statValue: { color: '#FFFFFF', fontSize: 32, fontWeight: 'bold' },
  sectionTitle: { color: '#FFD700', fontSize: 16, fontWeight: 'bold', marginBottom: 15 },
  assetList: { backgroundColor: '#0B1120', borderRadius: 20, padding: 20 },
  assetItem: { flexDirection: 'row', justifyContent: 'space-between', paddingVertical: 15, borderBottomWidth: 1, borderBottomColor: '#1E293B' },
  assetName: { color: '#FFFFFF', fontSize: 16 },
  assetAmount: { color: '#00D4FF', fontSize: 16, fontWeight: 'bold' },
});

export default PortfolioScreen;
