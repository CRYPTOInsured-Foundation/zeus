import React from 'react';
import { View, Text, StyleSheet, ScrollView, TouchableOpacity } from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';
import { useNotificationStore } from '@/services/stateStore';
import { useNavigation, useRoute } from '@react-navigation/native';

const InboxDetailScreen = () => {
  const { markRead } = useNotificationStore();
  const navigation = useNavigation<any>();
  const route = useRoute<any>();
  const item = route.params?.item;

  const handleMark = async () => {
    if (!item?.id) return navigation.goBack();
    try {
      await markRead(item.id);
    } catch (e) {}
    navigation.goBack();
  };

  return (
    <SafeAreaView style={styles.container}>
      <ScrollView contentContainerStyle={styles.content}>
        <Text style={styles.title}>{item?.title || 'Notification'}</Text>
        <Text style={styles.time}>{item?.createdAt ? new Date(item.createdAt).toLocaleString() : ''}</Text>
        <View style={styles.bodyCard}>
          <Text style={styles.bodyText}>{item?.body || JSON.stringify(item?.data || {}, null, 2)}</Text>
        </View>
        <TouchableOpacity style={styles.markButton} onPress={handleMark}>
          <Text style={styles.markText}>Mark as read</Text>
        </TouchableOpacity>
      </ScrollView>
    </SafeAreaView>
  );
};

const styles = StyleSheet.create({
  container: { flex: 1, backgroundColor: '#020617' },
  content: { padding: 16 },
  title: { color: '#FFD700', fontSize: 20, fontWeight: '700', marginBottom: 6 },
  time: { color: '#A0A0B0', fontSize: 12, marginBottom: 12 },
  bodyCard: { backgroundColor: '#0B1120', borderRadius: 8, padding: 12, marginBottom: 20 },
  bodyText: { color: '#FFFFFF', fontSize: 14 },
  markButton: { backgroundColor: '#00D4FF', padding: 12, borderRadius: 8, alignItems: 'center' },
  markText: { color: '#020617', fontWeight: '800' },
});

export default InboxDetailScreen;
