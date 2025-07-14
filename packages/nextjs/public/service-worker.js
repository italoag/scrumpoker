// Service Worker básico para ScrumPoker DApp
const CACHE_NAME = "scrumpoker-v1";
const urlsToCache = ["/", "/manifest.json", "/logo.svg", "/favicon.png"];

self.addEventListener("install", function (event) {
  event.waitUntil(
    caches.open(CACHE_NAME).then(function (cache) {
      return cache.addAll(urlsToCache);
    }),
  );
});

self.addEventListener("fetch", function (event) {
  event.respondWith(
    caches.match(event.request).then(function (response) {
      // Cache hit - return response
      if (response) {
        return response;
      }
      return fetch(event.request);
    }),
  );
});
