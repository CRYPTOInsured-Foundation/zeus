import React from 'react';
import { View, Text, StyleSheet, FlatList, TouchableOpacity } from 'react-native';
import { useNavigation } from '@react-navigation/native';
import { SafeAreaView } from 'react-native-safe-area-context';
import { useNotificationStore } from '@/services/stateStore';

const InboxScreen = () => {
  const { inbox, markRead, fetchInbox } = useNotificationStore();

  const navigation = useNavigation<any>();

  React.useEffect(() => {
    fetchInbox().catch(() => {});
  }, []);

  return (
    <SafeAreaView style={styles.container}>
      <View style={styles.header}>
        <Text style={styles.title}>Inbox</Text>
      </View>
      <FlatList
        data={inbox}
        keyExtractor={(item: any, index: number) => item?.id ? String(item.id) : String(index)}
        renderItem={({ item }: any) => (
          <TouchableOpacity style={styles.card} onPress={() => navigation.navigate('InboxDetail', { item })}>
            <View style={styles.cardContent}>
              <Text style={styles.cardTitle}>{item.title || 'Notification'}</Text>
              <Text style={styles.cardBody} numberOfLines={2}>{item.body || JSON.stringify(item.data || {})}</Text>
            </View>
            <TouchableOpacity style={styles.markButton} onPress={() => { markRead(item.id).catch(() => {}); }}>
              <Text style={styles.markText}>{item.read ? 'Read' : 'Mark'}</Text>
            </TouchableOpacity>
          </TouchableOpacity>
        )}
        contentContainerStyle={{ padding: 16 }}
      />
    </SafeAreaView>
  );
};

const styles = StyleSheet.create({
  container: { flex: 1, backgroundColor: '#020617' },
  header: { padding: 16, borderBottomWidth: 1, borderColor: '#111', backgroundColor: '#0B1120' },
  title: { color: '#FFD700', fontSize: 20, fontWeight: 'bold' },
  card: { flexDirection: 'row', alignItems: 'center', backgroundColor: '#0B1120', padding: 12, borderRadius: 10, marginBottom: 12 },
  cardContent: { flex: 1 },
  cardTitle: { color: '#FFFFFF', fontSize: 14, fontWeight: '600' },
  cardBody: { color: '#A0A0B0', fontSize: 12, marginTop: 6 },
  markButton: { paddingHorizontal: 12, paddingVertical: 8, borderRadius: 8, backgroundColor: '#00D4FF' },
  markText: { color: '#020617', fontWeight: '700' },
});

export default InboxScreen;
