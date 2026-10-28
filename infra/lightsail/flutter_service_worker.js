// Retire older Flutter offline caches, including cached root navigation.
self.addEventListener('install', () => self.skipWaiting());
self.addEventListener('activate', (event) => {
  event.waitUntil((async () => {
    for (const key of await caches.keys()) {
      if (key.startsWith('flutter-')) await caches.delete(key);
    }
    await self.clients.claim();
    await self.registration.unregister();
    for (const client of await self.clients.matchAll({ type: 'window' })) {
      // No fetch handler: navigation now reaches the server's current index.
      await client.navigate(client.url);
    }
  })());
});
