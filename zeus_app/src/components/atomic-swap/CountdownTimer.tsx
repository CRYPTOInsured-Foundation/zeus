import React, { useState, useEffect } from 'react';
import { Text, StyleSheet, View } from 'react-native';

interface CountdownTimerProps {
  initialSeconds: number;
  onExpiry?: () => void;
}

const CountdownTimer: React.FC<CountdownTimerProps> = ({ initialSeconds, onExpiry }) => {
  const [seconds, setSeconds] = useState(initialSeconds);

  useEffect(() => {
    if (seconds <= 0) {
      onExpiry?.();
      return;
    }

    const timer = setInterval(() => {
      setSeconds((prev) => prev - 1);
    }, 1000);

    return () => clearInterval(timer);
  }, [seconds]);

  const formatTime = (totalSeconds: number) => {
    const hours = Math.floor(totalSeconds / 3600);
    const minutes = Math.floor((totalSeconds % 3600) / 60);
    const secs = totalSeconds % 60;
    return `${hours.toString().padStart(2, '0')}:${minutes
      .toString()
      .padStart(2, '0')}:${secs.toString().padStart(2, '0')}`;
  };

  return (
    <View style={styles.container}>
      <Text style={styles.timerText}>{formatTime(seconds)}</Text>
    </View>
  );
};

const styles = StyleSheet.create({
  container: {
    padding: 10,
    backgroundColor: 'rgba(196, 30, 58, 0.1)',
    borderRadius: 8,
    borderWidth: 1,
    borderColor: 'rgba(196, 30, 58, 0.3)',
  },
  timerText: {
    color: '#C41E3A',
    fontSize: 16,
    fontWeight: 'bold',
    fontFamily: 'monospace',
  },
});

export default CountdownTimer;
