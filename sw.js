// WinStock service worker: always asks the server for the newest version first
// (bypassing the browser's HTTP cache), and falls back to the cache when offline.
const CACHE = 'winstock-v4';
const FILES = ['./', './index.html', './manifest.webmanifest', './icon-192.png', './icon-512.png', './apple-touch-icon.png'];

self.addEventListener('install', e => {
  e.waitUntil(caches.open(CACHE).then(c => c.addAll(FILES.map(f => new Request(f, {cache: 'reload'})))));
  self.skipWaiting();
});

self.addEventListener('activate', e => {
  e.waitUntil(caches.keys().then(keys => Promise.all(keys.filter(k => k !== CACHE).map(k => caches.delete(k)))));
  self.clients.claim();
});

self.addEventListener('fetch', e => {
  if (e.request.method !== 'GET') return;
  const sameOrigin = new URL(e.request.url).origin === location.origin;
  const req = sameOrigin ? new Request(e.request.url, {cache: 'no-cache', credentials: 'same-origin'}) : e.request;
  e.respondWith(
    fetch(req).then(res => {
      if (sameOrigin && res.ok) { const copy = res.clone(); caches.open(CACHE).then(c => c.put(e.request.url, copy)); }
      return res;
    }).catch(() => caches.match(e.request.url).then(r => r || (e.request.mode === 'navigate' ? caches.match('./index.html') : undefined)))
  );
});
