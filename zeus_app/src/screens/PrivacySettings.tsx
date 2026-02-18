import React from 'react';
import { View, Text, StyleSheet, Switch, TouchableOpacity } from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';
import { useNavigation } from '@react-navigation/native';
import { useAppStore } from '@/services/stateStore';

const PrivacySettings = () => {
  const navigation = useNavigation();
  const { isBiometricsEnabled, setBiometricsEnabled } = useAppStore();

  return (
    <SafeAreaView style={styles.container}>
      <View style={styles.header}>
        <TouchableOpacity onPress={() => navigation.goBack()}>
          <Text style={styles.backButton}>←</Text>
        </TouchableOpacity>
        <Text style={styles.title}>ARCANE SETTINGS</Text>
      </View>
      <View style={styles.content}>
        <View style={styles.settingItem}>
          <View>
            <Text style={styles.settingLabel}>Max Privacy Mode</Text>
            <Text style={styles.settingDesc}>Always use encrypted orderbook</Text>
          </View>
          <Switch value={true} onValueChange={() => {}} trackColor={{ false: '#1E293B', true: '#00D4FF' }} />
        </View>
        <View style={styles.settingItem}>
          <View>
            <Text style={styles.settingLabel}>Biometrics Lock</Text>
            <Text style={styles.settingDesc}>Secure your vault with fingerprints</Text>
          </View>
          <Switch value={isBiometricsEnabled} onValueChange={setBiometricsEnabled} trackColor={{ false: '#1E293B', true: '#00D4FF' }} />
        </View>
        <View style={styles.settingItem}>
          <View>
            <Text style={styles.settingLabel}>Quantum-Safe Proofs</Text>
            <Text style={styles.settingDesc}>Enforce STARK proof generation</Text>
          </View>
          <Switch value={true} disabled trackColor={{ false: '#1E293B', true: '#00D4FF' }} />
        </View>
      </View>
    </SafeAreaView>
  );
};

const styles = StyleSheet.create({
  container: { flex: 1, backgroundColor: '#020617' },
  header: { flexDirection: 'row', alignItems: 'center', padding: 20 },
  backButton: { color: '#FFD700', fontSize: 24, marginRight: 20 },
  title: { color: '#FFD700', fontSize: 20, fontWeight: 'bold', letterSpacing: 2 },
  content: { padding: 20 },
  settingItem: { flexDirection: 'row', justifyContent: 'space-between', alignItems: 'center', paddingVertical: 20, borderBottomWidth: 1, borderBottomColor: '#1E293B' },
  settingLabel: { color: '#FFFFFF', fontSize: 16, fontWeight: 'bold' },
  settingDesc: { color: '#A0A0B0', fontSize: 12, marginTop: 2 },
});

export default PrivacySettings;
