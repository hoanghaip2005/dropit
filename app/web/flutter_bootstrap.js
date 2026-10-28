{{flutter_js}}
{{flutter_build_config}}

// This app uses live deployments without offline service-worker caching.
(async () => {
  {
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
