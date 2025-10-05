// Service Worker para IntelliMen Campus PWA
const CACHE_NAME = 'campus-v1.0.0';
const STATIC_CACHE = 'campus-static-v1.0.0';
const DYNAMIC_CACHE = 'campus-dynamic-v1.0.0';

// Arquivos estáticos para cache
const STATIC_FILES = [
  '/',
  '/manifest.json',
  '/favicon.svg',
  '/logo.png',
  '/icon-72.png',
  '/icon-96.png',
  '/icon-128.png',
  '/icon-144.png',
  '/icon-152.png',
  '/icon-192.png',
  '/icon-384.png',
  '/icon-512.png',
  '/icon-192-maskable.png',
  '/icon-512-maskable.png'
];

// URLs que devem ser sempre buscadas da rede
const NETWORK_FIRST_URLS = [
  '/api/',
  '/auth/',
  '/supabase/'
];

// URLs que podem usar cache primeiro
const CACHE_FIRST_URLS = [
  '/static/',
  '/assets/',
  '/_app/'
];

// Instalar Service Worker
self.addEventListener('install', (event) => {
  console.log('🔧 Service Worker: Instalando...');
  
  event.waitUntil(
    Promise.all([
      // Cache dos arquivos estáticos
      caches.open(STATIC_CACHE).then((cache) => {
        console.log('📦 Service Worker: Cacheando arquivos estáticos...');
        return cache.addAll(STATIC_FILES);
      }),
      // Força a ativação imediata
      self.skipWaiting()
    ])
  );
});

// Ativar Service Worker
self.addEventListener('activate', (event) => {
  console.log('🚀 Service Worker: Ativando...');
  
  event.waitUntil(
    Promise.all([
      // Limpar caches antigos
      caches.keys().then((cacheNames) => {
        return Promise.all(
          cacheNames.map((cacheName) => {
            if (cacheName !== CACHE_NAME && 
                cacheName !== STATIC_CACHE && 
                cacheName !== DYNAMIC_CACHE) {
              console.log('🗑️ Service Worker: Removendo cache antigo:', cacheName);
              return caches.delete(cacheName);
            }
          })
        );
      }),
      // Tomar controle de todas as abas
      self.clients.claim()
    ])
  );
});

// Interceptar requisições
self.addEventListener('fetch', (event) => {
  const { request } = event;
  const url = new URL(request.url);
  
  // Ignorar requisições não-HTTP
  if (!request.url.startsWith('http')) {
    return;
  }
  
  // Estratégia de cache baseada na URL
  if (NETWORK_FIRST_URLS.some(pattern => url.pathname.includes(pattern))) {
    // Network First para APIs e autenticação
    event.respondWith(networkFirstStrategy(request));
  } else if (CACHE_FIRST_URLS.some(pattern => url.pathname.includes(pattern))) {
    // Cache First para assets estáticos
    event.respondWith(cacheFirstStrategy(request));
  } else {
    // Stale While Revalidate para páginas
    event.respondWith(staleWhileRevalidateStrategy(request));
  }
});

// Estratégia: Network First (para APIs)
async function networkFirstStrategy(request) {
  try {
    // Tentar buscar da rede primeiro
    const networkResponse = await fetch(request);
    
    // Se sucesso, cachear a resposta
    if (networkResponse.ok) {
      const cache = await caches.open(DYNAMIC_CACHE);
      cache.put(request, networkResponse.clone());
    }
    
    return networkResponse;
  } catch (error) {
    // Se falhar, tentar buscar do cache
    console.log('🌐 Service Worker: Rede falhou, buscando do cache:', request.url);
    const cachedResponse = await caches.match(request);
    
    if (cachedResponse) {
      return cachedResponse;
    }
    
    // Se não tiver no cache, retornar página offline
    if (request.destination === 'document') {
      return caches.match('/') || new Response('Página offline', {
        status: 503,
        statusText: 'Service Unavailable'
      });
    }
    
    throw error;
  }
}

// Estratégia: Cache First (para assets)
async function cacheFirstStrategy(request) {
  const cachedResponse = await caches.match(request);
  
  if (cachedResponse) {
    return cachedResponse;
  }
  
  try {
    const networkResponse = await fetch(request);
    
    if (networkResponse.ok) {
      const cache = await caches.open(STATIC_CACHE);
      cache.put(request, networkResponse.clone());
    }
    
    return networkResponse;
  } catch (error) {
    console.log('📦 Service Worker: Erro ao buscar asset:', request.url);
    throw error;
  }
}

// Estratégia: Stale While Revalidate (para páginas)
async function staleWhileRevalidateStrategy(request) {
  const cache = await caches.open(DYNAMIC_CACHE);
  const cachedResponse = await cache.match(request);
  
  // Buscar da rede em background
  const networkResponsePromise = fetch(request).then((response) => {
    if (response.ok) {
      cache.put(request, response.clone());
    }
    return response;
  }).catch(() => {
    // Ignorar erros de rede
  });
  
  // Retornar cache imediatamente se disponível
  if (cachedResponse) {
    return cachedResponse;
  }
  
  // Se não tiver cache, aguardar rede
  return networkResponsePromise;
}

// Gerenciar mensagens do cliente
self.addEventListener('message', (event) => {
  if (event.data && event.data.type === 'SKIP_WAITING') {
    self.skipWaiting();
  }
  
  if (event.data && event.data.type === 'GET_VERSION') {
    event.ports[0].postMessage({ version: CACHE_NAME });
  }
});

// Notificações push (para implementação futura)
self.addEventListener('push', (event) => {
  if (event.data) {
    const data = event.data.json();
    
    const options = {
      body: data.body,
      icon: '/icon-192.png',
      badge: '/icon-72.png',
      vibrate: [100, 50, 100],
      data: data.data,
      actions: data.actions || []
    };
    
    event.waitUntil(
      self.registration.showNotification(data.title, options)
    );
  }
});

// Clique em notificação
self.addEventListener('notificationclick', (event) => {
  event.notification.close();
  
  if (event.action === 'open') {
    event.waitUntil(
      clients.openWindow('/')
    );
  }
});

// Background sync (para implementação futura)
self.addEventListener('sync', (event) => {
  if (event.tag === 'background-sync') {
    event.waitUntil(doBackgroundSync());
  }
});

async function doBackgroundSync() {
  console.log('🔄 Service Worker: Executando sincronização em background...');
  // Implementar lógica de sincronização offline
}

// Limpeza periódica do cache
self.addEventListener('periodicsync', (event) => {
  if (event.tag === 'cache-cleanup') {
    event.waitUntil(cleanupCache());
  }
});

async function cleanupCache() {
  const cacheNames = await caches.keys();
  const oldCaches = cacheNames.filter(name => 
    name.startsWith('campus-') && 
    name !== CACHE_NAME && 
    name !== STATIC_CACHE && 
    name !== DYNAMIC_CACHE
  );
  
  await Promise.all(
    oldCaches.map(name => caches.delete(name))
  );
  
  console.log('🧹 Service Worker: Cache limpo');
}
