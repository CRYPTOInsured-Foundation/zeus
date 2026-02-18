import React from 'react';
import { View, Text, StyleSheet, FlatList, TouchableOpacity } from 'react-native';
import Svg, { Path } from 'react-native-svg';

const BannerIcon = ({ color = "#1E293B" }) => (
  <Svg width="24" height="24" viewBox="0 0 24 24" fill="none">
    <Path d="M4 4V20M4 4H18L16 8L18 12H4M4 12V20" stroke={color} strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" />
  </Svg>
);

const OrderBook = () => {
  const orders = [
    { id: '1', side: 'buy', amount: '0.5 BTC', price: '25,000 STRK', privacy: 'Shielded' },
    { id: '2', side: 'sell', amount: '1.2 BTC', price: '60,000 STRK', privacy: 'High' },
    { id: '3', side: 'buy', amount: '0.1 BTC', price: '5,000 STRK', privacy: 'Quantum-Safe' },
    { id: '4', side: 'sell', amount: '0.8 BTC', price: '40,000 STRK', privacy: 'Shielded' },
  ];

  const renderItem = ({ item }: { item: any }) => (
    <TouchableOpacity style={styles.orderItem}>
      <View style={styles.bannerContainer}>
        <BannerIcon color={item.side === 'buy' ? '#00D4FF' : '#C41E3A'} />
      </View>
      <View style={styles.orderDetails}>
        <View style={styles.orderRow}>
          <Text style={[styles.amountText, styles.foggyText]}>
            {item.amount}
          </Text>
          <Text style={[styles.priceText, styles.foggyText]}>
            {item.price}
          </Text>
        </View>
        <View style={styles.privacyTag}>
          <Text style={styles.privacyText}>{item.privacy}</Text>
        </View>
      </View>
      <View style={styles.verifyButton}>
        <Text style={styles.verifyText}>VERIFY</Text>
      </View>
    </TouchableOpacity>
  );

  return (
    <View style={styles.container}>
      <Text style={styles.title}>Encrypted Orderbook</Text>
      <FlatList
        data={orders}
        renderItem={renderItem}
        keyExtractor={(item) => item.id}
        scrollEnabled={false}
      />
    </View>
  );
};

const styles = StyleSheet.create({
  container: {
    padding: 20,
    backgroundColor: '#020617',
  },
  title: {
    color: '#FFD700',
    fontSize: 18,
    fontWeight: 'bold',
    marginBottom: 20,
    letterSpacing: 1,
    textTransform: 'uppercase',
  },
  orderItem: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: '#0B1120',
    borderRadius: 12,
    padding: 15,
    marginBottom: 10,
    borderWidth: 1,
    borderColor: '#1E293B',
  },
  bannerContainer: {
    marginRight: 15,
  },
  orderDetails: {
    flex: 1,
  },
  orderRow: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    marginBottom: 5,
    paddingRight: 15,
  },
  amountText: {
    color: '#FFFFFF',
    fontSize: 14,
    fontWeight: 'bold',
  },
  priceText: {
    color: '#FFFFFF',
    fontSize: 14,
  },
  foggyText: {
    textShadowColor: 'rgba(255,255,255,0.3)',
    textShadowOffset: { width: 0, height: 0 },
    textShadowRadius: 8,
    color: 'rgba(255,255,255,0.6)',
  },
  privacyTag: {
    alignSelf: 'flex-start',
    backgroundColor: 'rgba(0, 212, 255, 0.1)',
    paddingHorizontal: 8,
    paddingVertical: 2,
    borderRadius: 4,
  },
  privacyText: {
    color: '#00D4FF',
    fontSize: 10,
    fontWeight: 'bold',
  },
  verifyButton: {
    paddingHorizontal: 12,
    paddingVertical: 6,
    borderRadius: 8,
    borderWidth: 1,
    borderColor: '#FFD700',
  },
  verifyText: {
    color: '#FFD700',
    fontSize: 10,
    fontWeight: 'bold',
  },
});

export default OrderBook;
