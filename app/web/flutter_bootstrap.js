{{flutter_js}}
{{flutter_build_config}}

// Local previews must always reflect the latest build and cosmetic artwork.
(async () => {
  if (['localhost', '127.0.0.1', '::1'].includes(location.hostname)) {
    if ('serviceWorker' in navigator) {
      const registrations = await navigator.serviceWorker.getRegistrations();
      for (const registration of registrations) {
        const worker = registration.active || registration.waiting || registration.installing;
        if (worker && new URL(worker.scriptURL).pathname.endsWith('/flutter_service_worker.js')) {
          await registration.unregister();
        }
      }
    }
    if ('caches' in window) {
      for (const key of await caches.keys()) {
        if (key.startsWith('flutter-')) await caches.delete(key);
      }
    }
  }
  _flutter.loader.load();
})();
