/* Offline cache for Akshara Aata. Bump VERSION whenever a shell file changes. */
var VERSION = 'akshara-aata-v1';
var SHELL = [
  './',
  'index.html',
  'css/app.css',
  'js/data.js',
  'js/app.js',
  'manifest.webmanifest',
  'icons/icon.svg',
  'icons/icon-192.png',
  'icons/icon-512.png',
  'fonts/baloo-tamma-2-kannada-500-normal.woff2',
  'fonts/baloo-tamma-2-kannada-800-normal.woff2',
  'fonts/baloo-tamma-2-latin-500-normal.woff2',
  'fonts/baloo-tamma-2-latin-800-normal.woff2'
];

self.addEventListener('install', function (e) {
  e.waitUntil(caches.open(VERSION).then(function (c) { return c.addAll(SHELL); }).then(function () { return self.skipWaiting(); }));
});

self.addEventListener('activate', function (e) {
  e.waitUntil(caches.keys().then(function (keys) {
    return Promise.all(keys.filter(function (k) { return k !== VERSION; }).map(function (k) { return caches.delete(k); }));
  }).then(function () { return self.clients.claim(); }));
});

self.addEventListener('fetch', function (e) {
  if (e.request.method !== 'GET') return;
  e.respondWith(caches.match(e.request, { ignoreSearch: true }).then(function (hit) {
    return hit || fetch(e.request).then(function (res) {
      if (res.ok && new URL(e.request.url).origin === self.location.origin) {
        var copy = res.clone();
        caches.open(VERSION).then(function (c) { c.put(e.request, copy); });
      }
      return res;
    });
  }));
});
