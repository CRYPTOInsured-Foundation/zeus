import React from 'react';
import { createStackNavigator } from '@react-navigation/stack';
import LandingScreen from '@/screens/LandingScreen';
import HomeScreen from '@/screens/HomeScreen';
import SwapScreen from '@/screens/SwapScreen';
import PortfolioScreen from '@/screens/PortfolioScreen';
import PrivacySettings from '@/screens/PrivacySettings';
import TransactionHistory from '@/screens/TransactionHistory';

const Stack = createStackNavigator();

const AppNavigator = () => {
  return (
    <Stack.Navigator
      initialRouteName="Landing"
      screenOptions={{
        headerShown: false,
        cardStyle: { backgroundColor: '#020617' },
      }}
    >
      <Stack.Screen name="Landing" component={LandingScreen} />
      <Stack.Screen name="Home" component={HomeScreen} />
      <Stack.Screen name="Swap" component={SwapScreen} />
      <Stack.Screen name="Portfolio" component={PortfolioScreen} />
      <Stack.Screen name="Privacy" component={PrivacySettings} />
      <Stack.Screen name="History" component={TransactionHistory} />
    </Stack.Navigator>
  );
};

export default AppNavigator;
