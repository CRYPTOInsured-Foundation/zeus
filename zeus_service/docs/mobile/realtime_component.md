# React Native Realtime Component (example)

This small example shows a React Native component that connects to the Zeus backend via Socket.IO, authenticates with JWT, subscribes to a swap room, and applies delta updates to local state.

```jsx
import React, { useEffect, useState } from 'react';
import { View, Text, Button } from 'react-native';
import { io } from 'socket.io-client';

export default function SwapRealtime({ serverUrl, jwt, swapId }) {
  const [socket, setSocket] = useState(null);
  const [events, setEvents] = useState([]);

  useEffect(() => {
    const s = io(serverUrl, { transports: ['websocket'] });
    setSocket(s);

    s.on('connect', () => {
      s.emit('authenticate', { token: jwt });
      s.emit('subscribe', { room: `swap:${swapId}` });
    });

    s.on('swap.delta', (d) => setEvents((e) => [d, ...e]));
    s.on('notification', (n) => setEvents((e) => [n, ...e]));

    return () => {
      try { s.emit('unsubscribe', { room: `swap:${swapId}` }); } catch (e) {}
      s.disconnect();
    };
  }, [serverUrl, jwt, swapId]);

  return (
    <View>
      <Text>Realtime for swap {swapId}</Text>
      <Button title="Force reconnect" onPress={() => socket && socket.connect()} />
      {events.slice(0, 10).map((ev, i) => (
        <View key={i} style={{ padding: 6 }}>
          <Text>{JSON.stringify(ev)}</Text>
        </View>
      ))}
    </View>
  );
}
```

Notes
- Keep JWT refreshed in secure storage and reconnect with new token when it expires.
- Use the `swap.delta` event for lightweight UI updates; fetch full state from `/swap/:id` on demand.
