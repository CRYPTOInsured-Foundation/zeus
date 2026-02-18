import React, { useEffect } from 'react';
import { View, Text, StyleSheet } from 'react-native';
import Animated, { 
  useSharedValue, 
  useAnimatedStyle, 
  withRepeat, 
  withTiming, 
  withSequence,
  Easing
} from 'react-native-reanimated';
import Svg, { Path, Circle, G, Defs, RadialGradient, Stop } from 'react-native-svg';

interface ZKProofStatusProps {
  status: 'generating' | 'verified' | 'failed';
}

const ZKProofStatus: React.FC<ZKProofStatusProps> = ({ status }) => {
  const rotation = useSharedValue(0);
  const scale = useSharedValue(1);

  useEffect(() => {
    rotation.value = withRepeat(
      withTiming(360, { duration: 4000, easing: Easing.linear }),
      -1,
      false
    );
    scale.value = withRepeat(
      withSequence(
        withTiming(1.1, { duration: 1000 }),
        withTiming(1, { duration: 1000 })
      ),
      -1,
      true
    );
  }, []);

  const runeStyle = useAnimatedStyle(() => ({
    transform: [
      { rotate: `${rotation.value}deg` },
      { scale: scale.value }
    ],
  }));

  return (
    <View style={styles.container}>
      <Animated.View style={[styles.runeContainer, runeStyle]}>
        <Svg width="100" height="100" viewBox="0 0 100 100">
          <Defs>
            <RadialGradient id="grad" cx="50" cy="50" r="50" gradientUnits="userSpaceOnUse">
              <Stop offset="0" stopColor="#00D4FF" stopOpacity="0.3" />
              <Stop offset="1" stopColor="#00D4FF" stopOpacity="0" />
            </RadialGradient>
          </Defs>
          <Circle cx="50" cy="50" r="45" stroke="#00D4FF" strokeWidth="1" strokeDasharray="5,5" fill="url(#grad)" />
          {/* Arcane Rune Pattern */}
          <Path 
            d="M50 15 L85 50 L50 85 L15 50 Z M50 25 L75 50 L50 75 L25 50 Z" 
            stroke="#00D4FF" 
            strokeWidth="2" 
            fill="none" 
          />
          <Circle cx="50" cy="50" r="5" fill="#00D4FF" />
        </Svg>
      </Animated.View>
      
      <View style={styles.textContainer}>
        <Text style={styles.statusText}>
          {status === 'generating' ? 'GENERATING STARK PROOF' : 'PROOF VERIFIED'}
        </Text>
        <Text style={styles.subtext}>
          {status === 'generating' ? 'Summoning zero-knowledge runes...' : 'Quantum-safe privacy secured.'}
        </Text>
      </View>
    </View>
  );
};

const styles = StyleSheet.create({
  container: {
    alignItems: 'center',
    justifyContent: 'center',
  },
  runeContainer: {
    marginBottom: 20,
  },
  textContainer: {
    alignItems: 'center',
  },
  statusText: {
    color: '#00D4FF',
    fontSize: 14,
    fontWeight: 'bold',
    letterSpacing: 2,
    textAlign: 'center',
  },
  subtext: {
    color: '#A0A0B0',
    fontSize: 12,
    marginTop: 5,
    fontStyle: 'italic',
    textAlign: 'center',
  },
});

export default ZKProofStatus;
