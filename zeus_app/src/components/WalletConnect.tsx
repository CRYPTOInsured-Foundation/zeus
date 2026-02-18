import React from 'react';
import { View, Text, StyleSheet, TouchableOpacity } from 'react-native';
import Svg, { Path } from 'react-native-svg';

const WalletIcon = () => (
  <Svg width="24" height="24" viewBox="0 0 24 24" fill="none">
    <Path d="M19 7H5C3.89543 7 3 7.89543 3 9V18C3 19.1046 3.89543 20 5 20H19C20.1046 20 21 19.1046 21 18V9C21 7.89543 20.1046 7 19 7Z" stroke="#FFD700" strokeWidth="2" />
    <Path d="M16 11C16 11.5523 15.5523 12 15 12C14.4477 12 14 11.5523 14 11C14 10.4477 14.4477 10 15 10C15.5523 10 16 10.4477 16 11Z" fill="#FFD700" />
    <Path d="M3 12H7" stroke="#FFD700" strokeWidth="2" />
    <Path d="M21 12H17" stroke="#FFD700" strokeWidth="2" />
  </Svg>
);

const WalletConnect = ({ type, onConnect }: { type: 'Starknet' | 'Bitcoin', onConnect: () => void }) => {
  return (
    <TouchableOpacity style={styles.container} onPress={onConnect}>
      <View style={styles.iconContainer}>
        <WalletIcon />
      </View>
      <View style={styles.textContainer}>
        <Text style={styles.title}>Connect {type} Wallet</Text>
        <Text style={styles.subtitle}>
          {type === 'Starknet' ? 'Argent X / Braavos' : 'Xverse / Leather'}
        </Text>
      </View>
      <View style={styles.chevron}>
        <Text style={styles.chevronText}>→</Text>
      </View>
    </TouchableOpacity>
  );
};

const styles = StyleSheet.create({
  container: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: '#0B1120',
    borderRadius: 15,
    padding: 15,
    marginBottom: 15,
    borderWidth: 1,
    borderColor: '#1E293B',
  },
  iconContainer: {
    width: 45,
    height: 45,
    borderRadius: 22.5,
    backgroundColor: 'rgba(255, 215, 0, 0.1)',
    justifyContent: 'center',
    alignItems: 'center',
    marginRight: 15,
  },
  textContainer: {
    flex: 1,
  },
  title: {
    color: '#FFFFFF',
    fontSize: 16,
    fontWeight: 'bold',
  },
  subtitle: {
    color: '#A0A0B0',
    fontSize: 12,
    marginTop: 2,
  },
  chevron: {
    marginLeft: 10,
  },
  chevronText: {
    color: '#FFD700',
    fontSize: 20,
    fontWeight: 'bold',
  },
});

export default WalletConnect;
