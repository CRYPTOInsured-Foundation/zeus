import React, { useState, useEffect } from 'react';
import { View, Text, StyleSheet, TouchableOpacity, TextInput, Dimensions } from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';
import Animated, { 
  useSharedValue, 
  useAnimatedStyle, 
  withSpring, 
  withRepeat, 
  withSequence,
  withTiming,
  Easing
} from 'react-native-reanimated';
import Svg, { Path, Circle } from 'react-native-svg';
import { useSwapStore } from '@/services/stateStore';
import HTLCProgress from '@/components/atomic-swap/HTLCProgress';
import ZKProofStatus from '@/components/ZKProofStatus';

const { width } = Dimensions.get('window');

const LightningBolt = ({ color = "#00D4FF" }) => (
  <Svg width="40" height="40" viewBox="0 0 24 24" fill="none">
    <Path d="M13 2L3 14H12L11 22L21 10H12L13 2Z" fill={color} />
  </Svg>
);

const SwapScreen = () => {
  const { fromToken, toToken, amount, setAmount, isPrivate, togglePrivacy } = useSwapStore();
  const [isSwapping, setIsSwapping] = useState(false);
  const [swapStep, setSwapStep] = useState(0); // 0: input, 1: generating proof, 2: htlc lock, 3: complete

  const thunderOpacity = useSharedValue(0);

  const triggerThunder = () => {
    thunderOpacity.value = withSequence(
      withTiming(1, { duration: 50 }),
      withTiming(0, { duration: 100 }),
      withTiming(1, { duration: 50 }),
      withTiming(0, { duration: 300 })
    );
  };

  const handleSwap = async () => {
    setIsSwapping(true);
    setSwapStep(1);
    triggerThunder();
    
    // Simulate flow
    setTimeout(() => setSwapStep(2), 3000);
    setTimeout(() => {
      setSwapStep(3);
      triggerThunder();
    }, 8000);
  };

  const thunderStyle = useAnimatedStyle(() => ({
    opacity: thunderOpacity.value,
    position: 'absolute',
    top: 0,
    left: 0,
    right: 0,
    bottom: 0,
    backgroundColor: 'rgba(0, 212, 255, 0.2)',
    zIndex: 99,
    pointerEvents: 'none',
  }));

  return (
    <SafeAreaView style={styles.container}>
      <Animated.View style={thunderStyle} />
      
      <View style={styles.header}>
        <Text style={styles.headerTitle}>Thunder Swap</Text>
        <TouchableOpacity style={styles.privacyToggle} onPress={togglePrivacy}>
          <Text style={[styles.privacyText, isPrivate && styles.privacyActive]}>
            {isPrivate ? '🛡 SHIELDED' : '🔓 PUBLIC'}
          </Text>
        </TouchableOpacity>
      </View>

      <View style={styles.swapCard}>
        {/* From Token */}
        <View style={styles.tokenInputContainer}>
          <View style={styles.tokenInfo}>
            <View style={[styles.tokenIcon, { backgroundColor: '#F7931A' }]}>
              <Text style={styles.tokenSymbolText}>₿</Text>
            </View>
            <Text style={styles.tokenName}>Bitcoin</Text>
          </View>
          <TextInput
            style={styles.amountInput}
            placeholder="0.00"
            placeholderTextColor="#404060"
            keyboardType="numeric"
            value={amount}
            onChangeText={setAmount}
            editable={!isSwapping}
          />
        </View>

        {/* Bridge Icon */}
        <View style={styles.bridgeContainer}>
          <View style={styles.bridgeLine} />
          <TouchableOpacity style={styles.swapIconCircle} disabled={isSwapping}>
            <LightningBolt />
          </TouchableOpacity>
          <View style={styles.bridgeLine} />
        </View>

        {/* To Token */}
        <View style={styles.tokenInputContainer}>
          <View style={styles.tokenInfo}>
            <View style={[styles.tokenIcon, { backgroundColor: '#00D4FF' }]}>
              <Text style={styles.tokenSymbolText}>S</Text>
            </View>
            <Text style={styles.tokenName}>Starknet</Text>
          </View>
          <TextInput
            style={styles.amountInput}
            placeholder="0.00"
            placeholderTextColor="#404060"
            keyboardType="numeric"
            value={(parseFloat(amount || '0') * 10000).toString()} // Mock rate
            editable={false}
          />
        </View>
      </View>

      {/* Dynamic Content Based on Step */}
      <View style={styles.statusContainer}>
        {swapStep === 1 && <ZKProofStatus status="generating" />}
        {swapStep === 2 && <HTLCProgress step={2} />}
        {swapStep === 3 && (
          <View style={styles.successContainer}>
            <Text style={styles.successText}>SWAP COMPLETE</Text>
            <Text style={styles.successSubtext}>The runes have been balanced.</Text>
          </View>
        )}
      </View>

      {/* Main Action Button */}
      {swapStep === 0 && (
        <TouchableOpacity 
          style={styles.executeButton}
          onPress={handleSwap}
        >
          <Text style={styles.executeButtonText}>EXECUTE PRIVATE SWAP</Text>
        </TouchableOpacity>
      )}

      {swapStep === 3 && (
        <TouchableOpacity 
          style={[styles.executeButton, { borderColor: '#FFD700' }]}
          onPress={() => {
            setIsSwapping(false);
            setSwapStep(0);
          }}
        >
          <Text style={[styles.executeButtonText, { color: '#FFD700' }]}>NEW RITUAL</Text>
        </TouchableOpacity>
      )}
    </SafeAreaView>
  );
};

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#020617',
    padding: 20,
  },
  header: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: 40,
  },
  headerTitle: {
    color: '#FFD700',
    fontSize: 24,
    fontWeight: 'bold',
    fontFamily: 'serif',
    letterSpacing: 2,
  },
  privacyToggle: {
    paddingHorizontal: 12,
    paddingVertical: 6,
    borderRadius: 20,
    backgroundColor: '#0B1120',
    borderWidth: 1,
    borderColor: '#1E293B',
  },
  privacyText: {
    color: '#A0A0B0',
    fontSize: 12,
    fontWeight: 'bold',
  },
  privacyActive: {
    color: '#00D4FF',
  },
  swapCard: {
    backgroundColor: '#0B1120',
    borderRadius: 25,
    padding: 20,
    borderWidth: 1,
    borderColor: '#1E293B',
  },
  tokenInputContainer: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    paddingVertical: 10,
  },
  tokenInfo: {
    flexDirection: 'row',
    alignItems: 'center',
  },
  tokenIcon: {
    width: 40,
    height: 40,
    borderRadius: 20,
    justifyContent: 'center',
    alignItems: 'center',
    marginRight: 12,
  },
  tokenSymbolText: {
    color: '#FFFFFF',
    fontSize: 20,
    fontWeight: 'bold',
  },
  tokenName: {
    color: '#FFFFFF',
    fontSize: 18,
    fontWeight: '600',
  },
  amountInput: {
    color: '#FFFFFF',
    fontSize: 24,
    fontWeight: 'bold',
    textAlign: 'right',
    flex: 1,
  },
  bridgeContainer: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    marginVertical: 10,
  },
  bridgeLine: {
    flex: 1,
    height: 2,
    backgroundColor: '#1E293B',
  },
  swapIconCircle: {
    width: 60,
    height: 60,
    borderRadius: 30,
    backgroundColor: '#020617',
    borderWidth: 2,
    borderColor: '#00D4FF',
    justifyContent: 'center',
    alignItems: 'center',
    marginHorizontal: 15,
  },
  statusContainer: {
    marginTop: 40,
    alignItems: 'center',
    minHeight: 150,
  },
  executeButton: {
    marginTop: 'auto',
    height: 65,
    borderRadius: 15,
    borderWidth: 2,
    borderColor: '#00D4FF',
    justifyContent: 'center',
    alignItems: 'center',
    marginBottom: 20,
  },
  executeButtonText: {
    color: '#00D4FF',
    fontSize: 18,
    fontWeight: 'bold',
    letterSpacing: 2,
  },
  successContainer: {
    alignItems: 'center',
  },
  successText: {
    color: '#FFD700',
    fontSize: 28,
    fontWeight: 'bold',
    letterSpacing: 4,
    marginBottom: 10,
  },
  successSubtext: {
    color: '#A0A0B0',
    fontSize: 16,
    fontStyle: 'italic',
  },
});

export default SwapScreen;
