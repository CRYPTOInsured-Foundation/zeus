import React, { useEffect } from 'react';
import { View, Text, StyleSheet } from 'react-native';
import Animated, { 
  useSharedValue, 
  useAnimatedStyle, 
  withRepeat, 
  withTiming, 
  withSequence,
  interpolateColor
} from 'react-native-reanimated';
import Svg, { Path, Circle, G } from 'react-native-svg';

interface HTLCProgressProps {
  step: number;
}

const HTLCProgress: React.FC<HTLCProgressProps> = ({ step }) => {
  const progress = useSharedValue(0);

  useEffect(() => {
    progress.value = withRepeat(
      withTiming(1, { duration: 2000 }),
      -1,
      false
    );
  }, []);

  const chainStyle = useAnimatedStyle(() => {
    return {
      opacity: 0.5 + progress.value * 0.5,
      transform: [{ scale: 1 + progress.value * 0.05 }],
    };
  });

  return (
    <View style={styles.container}>
      <Text style={styles.title}>Atomic HTLC Lock Active</Text>
      
      <View style={styles.chainContainer}>
        <Animated.View style={[styles.link, chainStyle]}>
          <Svg width="40" height="40" viewBox="0 0 24 24" fill="none">
            <Path d="M9 17H7C5.34315 17 4 15.6569 4 14V10C4 8.34315 5.34315 7 7 7H9" stroke="#FFD700" strokeWidth="2" />
            <Path d="M15 7H17C18.6569 7 20 8.34315 20 10V14C20 15.6569 18.6569 17 17 17H15" stroke="#FFD700" strokeWidth="2" />
            <Path d="M8 12H16" stroke="#FFD700" strokeWidth="2" />
          </Svg>
        </Animated.View>
        
        <View style={styles.progressTrack}>
          <View style={[styles.progressBar, { width: '65%' }]} />
        </View>
      </View>
      
      <View style={styles.timerContainer}>
        <Text style={styles.timerText}>Timelock: 23:59:45</Text>
        <Text style={styles.statusText}>Waiting for counterparty lock...</Text>
      </View>
    </View>
  );
};

const styles = StyleSheet.create({
  container: {
    width: '100%',
    alignItems: 'center',
    padding: 20,
    backgroundColor: 'rgba(11, 17, 32, 0.8)',
    borderRadius: 20,
    borderWidth: 1,
    borderColor: 'rgba(255, 215, 0, 0.2)',
  },
  title: {
    color: '#FFD700',
    fontSize: 16,
    fontWeight: 'bold',
    marginBottom: 20,
    letterSpacing: 1,
  },
  chainContainer: {
    flexDirection: 'row',
    alignItems: 'center',
    width: '100%',
    marginBottom: 20,
  },
  link: {
    marginRight: 15,
  },
  progressTrack: {
    flex: 1,
    height: 8,
    backgroundColor: '#020617',
    borderRadius: 4,
    overflow: 'hidden',
  },
  progressBar: {
    height: '100%',
    backgroundColor: '#00D4FF',
    shadowColor: '#00D4FF',
    shadowOffset: { width: 0, height: 0 },
    shadowOpacity: 1,
    shadowRadius: 10,
  },
  timerContainer: {
    alignItems: 'center',
  },
  timerText: {
    color: '#FFFFFF',
    fontSize: 14,
    fontWeight: '600',
    fontFamily: 'monospace',
  },
  statusText: {
    color: '#A0A0B0',
    fontSize: 12,
    marginTop: 5,
    fontStyle: 'italic',
  },
});

export default HTLCProgress;
