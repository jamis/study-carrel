// Study is online-only for now (offline support is deferred). This worker exists so browsers
// treat the app as installable; it passes every request straight through to the network.
self.addEventListener("install", () => self.skipWaiting())
self.addEventListener("activate", event => event.waitUntil(self.clients.claim()))
self.addEventListener("fetch", () => {})
