/**
 * Sistema de cache simples e seguro para dados geográficos
 * Cache em memória com TTL (Time To Live) para dados que mudam raramente
 */

class SimpleCache {
  constructor() {
    this.cache = new Map();
    this.ttl = new Map(); // Time To Live
  }

  set(key, value, ttlMinutes = 30) {
    const expiresAt = Date.now() + (ttlMinutes * 60 * 1000);
    this.cache.set(key, value);
    this.ttl.set(key, expiresAt);
  }

  get(key) {
    const expiresAt = this.ttl.get(key);
    
    // Verificar se expirou
    if (expiresAt && Date.now() > expiresAt) {
      this.cache.delete(key);
      this.ttl.delete(key);
      return null;
    }
    
    return this.cache.get(key) || null;
  }

  has(key) {
    return this.get(key) !== null;
  }

  delete(key) {
    this.cache.delete(key);
    this.ttl.delete(key);
  }

  clear() {
    this.cache.clear();
    this.ttl.clear();
  }

  // Limpar entradas expiradas
  cleanup() {
    const now = Date.now();
    for (const [key, expiresAt] of this.ttl.entries()) {
      if (now > expiresAt) {
        this.cache.delete(key);
        this.ttl.delete(key);
      }
    }
  }
}

// Instância global do cache
export const cache = new SimpleCache();

// Limpar cache expirado a cada 5 minutos
if (typeof window !== 'undefined') {
  setInterval(() => {
    cache.cleanup();
  }, 5 * 60 * 1000);
}

/**
 * Função helper para cache com fallback
 */
export async function withCache(key, fetchFunction, ttlMinutes = 30) {
  // Tentar buscar do cache primeiro
  const cached = cache.get(key);
  if (cached) {
    return cached;
  }

  // Se não estiver no cache, buscar e armazenar
  try {
    const data = await fetchFunction();
    cache.set(key, data, ttlMinutes);
    return data;
  } catch (error) {
    console.error(`Erro ao buscar dados para cache key "${key}":`, error);
    throw error;
  }
}

/**
 * Chaves de cache padronizadas
 */
export const CACHE_KEYS = {
  ESTADOS: 'geographic:estados',
  BLOCOS: (estadoId) => `geographic:blocos:${estadoId}`,
  REGIOES: (blocoId) => `geographic:regioes:${blocoId}`,
  IGREJAS: (regiaoId) => `geographic:igrejas:${regiaoId}`,
  EDICOES: 'geographic:edicoes',
  ROLES: 'system:roles',
  CONFIGURACOES: 'system:configuracoes'
};
