import { writable } from 'svelte/store';
import { supabase } from '$lib/utils/supabase';
import { user, userProfile } from '$lib/stores/auth';

// Stores para segurança
export const permissoes = writable([]);
export const userPermissoes = writable([]);
export const loading = writable(false);
export const error = writable(null);

// Níveis de permissão
export const PERMISSOES = {
  // Jovens
  JOVENS_VER: 'jovens.ver',
  JOVENS_CRIAR: 'jovens.criar',
  JOVENS_EDITAR: 'jovens.editar',
  JOVENS_DELETAR: 'jovens.deletar',
  JOVENS_APROVAR: 'jovens.aprovar',
  
  // Avaliações
  AVALIACOES_VER: 'avaliacoes.ver',
  AVALIACOES_CRIAR: 'avaliacoes.criar',
  AVALIACOES_EDITAR: 'avaliacoes.editar',
  AVALIACOES_DELETAR: 'avaliacoes.deletar',
  
  // Usuários
  USUARIOS_VER: 'usuarios.ver',
  USUARIOS_CRIAR: 'usuarios.criar',
  USUARIOS_EDITAR: 'usuarios.editar',
  USUARIOS_DELETAR: 'usuarios.deletar',
  USUARIOS_TRANSFERIR: 'usuarios.transferir',
  
  // Relatórios
  RELATORIOS_VER: 'relatorios.ver',
  RELATORIOS_EXPORTAR: 'relatorios.exportar',
  
  // Sistema
  SISTEMA_CONFIGURAR: 'sistema.configurar',
  SISTEMA_AUDITORIA: 'sistema.auditoria'
};

// Níveis hierárquicos (alinhados com o banco de dados)
export const NIVEIS_HIERARQUICOS = {
  ADMINISTRADOR: 1,
  LIDER_NACIONAL_IURD: 2,
  LIDER_NACIONAL_FJU: 2,
  LIDER_ESTADUAL_IURD: 3,
  LIDER_ESTADUAL_FJU: 3,
  LIDER_BLOCO_IURD: 4,
  LIDER_BLOCO_FJU: 4,
  LIDER_REGIONAL_IURD: 5,
  LIDER_IGREJA_IURD: 6,
  COLABORADOR: 7,
  JOVEM: 8
};

// Função para carregar permissões do usuário
export async function loadUserPermissoes(usuarioId) {
  loading.set(true);
  error.set(null);
  
  try {
    const { data, error: fetchError } = await supabase
      .from('user_roles')
      .select(`
        *,
        role:roles(nome, slug, nivel_hierarquico, permissoes),
        estado:estados(nome, sigla),
        bloco:blocos(nome),
        regiao:regioes(nome),
        igreja:igrejas(nome)
      `)
      .eq('user_id', usuarioId)
      .eq('ativo', true);
    
    if (fetchError) throw fetchError;
    
    userPermissoes.set(data || []);
    return data;
  } catch (err) {
    error.set(err.message);
    console.error('Error loading user permissions:', err);
    return [];
  } finally {
    loading.set(false);
  }
}

// Função para verificar se o usuário tem uma permissão específica
export function hasPermission(permissao, usuarioId = null) {
  const currentUser = $user;
  const currentProfile = $userProfile;
  
  if (!currentUser || !currentProfile) return false;
  
  // Administrador tem todas as permissões
  if (currentProfile.nivel === 'administrador') return true;
  
  // Verificar permissões do usuário
  const userRoles = $userPermissoes;
  
  for (const userRole of userRoles) {
    if (userRole.role?.permissoes?.includes(permissao)) {
      return true;
    }
  }
  
  return false;
}

// Função para verificar se o usuário pode acessar um recurso
export function canAccess(resource, action, usuarioId = null) {
  const permissao = `${resource}.${action}`;
  return hasPermission(permissao, usuarioId);
}

// Função para verificar se o usuário pode acessar dados de uma localização
export function canAccessLocation(estadoId, blocoId, regiaoId, igrejaId) {
  const currentProfile = $userProfile;
  
  if (!currentProfile) return false;
  
  // Administrador pode acessar tudo
  if (currentProfile.nivel === 'administrador') return true;
  
  // Verificar hierarquia
  const userRoles = $userPermissoes;
  
  for (const userRole of userRoles) {
    // Verificar se o usuário tem acesso à localização
    if (estadoId && userRole.estado_id && userRole.estado_id !== estadoId) continue;
    if (blocoId && userRole.bloco_id && userRole.bloco_id !== blocoId) continue;
    if (regiaoId && userRole.regiao_id && userRole.regiao_id !== regiaoId) continue;
    if (igrejaId && userRole.igreja_id && userRole.igreja_id !== igrejaId) continue;
    
    return true;
  }
  
  return false;
}

// Função para obter nível hierárquico do usuário
export function getUserLevel() {
  const currentProfile = $userProfile;
  
  if (!currentProfile) return 999; // Nível mais baixo
  
  const userRoles = $userPermissoes;
  let minLevel = 999;
  
  for (const userRole of userRoles) {
    const level = NIVEIS_HIERARQUICOS[userRole.role?.slug?.toUpperCase()] || 999;
    if (level < minLevel) {
      minLevel = level;
    }
  }
  
  return minLevel;
}

// Função para verificar se o usuário pode gerenciar outro usuário
export function canManageUser(targetUserId, targetUserLevel) {
  const currentLevel = getUserLevel();
  return currentLevel < targetUserLevel;
}

// Função para obter filtros de localização baseados nas permissões
export function getLocationFilters() {
  const currentProfile = $userProfile;
  
  if (!currentProfile) return {};
  
  // Administrador pode ver tudo
  if (currentProfile.nivel === 'administrador') return {};
  
  const userRoles = $userPermissoes;
  const filters = {};
  
  for (const userRole of userRoles) {
    if (userRole.estado_id) {
      filters.estado_id = userRole.estado_id;
    }
    if (userRole.bloco_id) {
      filters.bloco_id = userRole.bloco_id;
    }
    if (userRole.regiao_id) {
      filters.regiao_id = userRole.regiao_id;
    }
    if (userRole.igreja_id) {
      filters.igreja_id = userRole.igreja_id;
    }
  }
  
  return filters;
}

// Função para criar log de auditoria
export async function createAuditLog(acao, detalhe, dadosAntigos = null, dadosNovos = null) {
  try {
    const { data, error: logError } = await supabase
      .from('logs_auditoria')
      .insert([{
        usuario_id: $user?.id,
        acao,
        detalhe,
        dados_antigos: dadosAntigos ? JSON.stringify(dadosAntigos) : null,
        dados_novos: dadosNovos ? JSON.stringify(dadosNovos) : null,
        ip_address: await getClientIP(),
        user_agent: navigator.userAgent,
        criado_em: new Date().toISOString()
      }]);
    
    if (logError) throw logError;
    
    return data;
  } catch (err) {
    console.error('Error creating audit log:', err);
    throw err;
  }
}

// Função para obter IP do cliente
async function getClientIP() {
  try {
    const response = await fetch('https://api.ipify.org?format=json');
    const data = await response.json();
    return data.ip;
  } catch (err) {
    return 'unknown';
  }
}

// Função para validar dados de entrada
export function validateInput(data, rules) {
  const errors = {};
  
  for (const [field, rule] of Object.entries(rules)) {
    const value = data[field];
    
    // Required
    if (rule.required && (!value || value.toString().trim() === '')) {
      errors[field] = `${field} é obrigatório`;
      continue;
    }
    
    // Type validation
    if (value && rule.type) {
      switch (rule.type) {
        case 'email':
          if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(value)) {
            errors[field] = 'Email inválido';
          }
          break;
        case 'phone':
          if (!/^\(\d{2}\)\s\d{4,5}-\d{4}$/.test(value)) {
            errors[field] = 'Telefone inválido';
          }
          break;
        case 'cpf':
          if (!/^\d{3}\.\d{3}\.\d{3}-\d{2}$/.test(value)) {
            errors[field] = 'CPF inválido';
          }
          break;
        case 'number':
          if (isNaN(value)) {
            errors[field] = 'Deve ser um número';
          }
          break;
        case 'date':
          if (isNaN(Date.parse(value))) {
            errors[field] = 'Data inválida';
          }
          break;
      }
    }
    
    // Length validation
    if (value && rule.minLength && value.length < rule.minLength) {
      errors[field] = `Mínimo ${rule.minLength} caracteres`;
    }
    
    if (value && rule.maxLength && value.length > rule.maxLength) {
      errors[field] = `Máximo ${rule.maxLength} caracteres`;
    }
    
    // Range validation
    if (value && rule.min && Number(value) < rule.min) {
      errors[field] = `Valor mínimo: ${rule.min}`;
    }
    
    if (value && rule.max && Number(value) > rule.max) {
      errors[field] = `Valor máximo: ${rule.max}`;
    }
    
    // Custom validation
    if (value && rule.custom) {
      const customError = rule.custom(value, data);
      if (customError) {
        errors[field] = customError;
      }
    }
  }
  
  return {
    isValid: Object.keys(errors).length === 0,
    errors
  };
}

// Função para sanitizar dados
export function sanitizeInput(data) {
  const sanitized = {};
  
  for (const [key, value] of Object.entries(data)) {
    if (typeof value === 'string') {
      // Remove HTML tags
      sanitized[key] = value.replace(/<[^>]*>/g, '');
      
      // Escape special characters
      sanitized[key] = sanitized[key]
        .replace(/&/g, '&amp;')
        .replace(/</g, '&lt;')
        .replace(/>/g, '&gt;')
        .replace(/"/g, '&quot;')
        .replace(/'/g, '&#x27;');
    } else {
      sanitized[key] = value;
    }
  }
  
  return sanitized;
}

// Função para verificar rate limiting
const rateLimitStore = new Map();

export function checkRateLimit(key, maxRequests = 10, windowMs = 60000) {
  const now = Date.now();
  const windowStart = now - windowMs;
  
  if (!rateLimitStore.has(key)) {
    rateLimitStore.set(key, []);
  }
  
  const requests = rateLimitStore.get(key);
  
  // Remove old requests
  const validRequests = requests.filter(timestamp => timestamp > windowStart);
  
  if (validRequests.length >= maxRequests) {
    return {
      allowed: false,
      remaining: 0,
      resetTime: Math.min(...validRequests) + windowMs
    };
  }
  
  // Add current request
  validRequests.push(now);
  rateLimitStore.set(key, validRequests);
  
  return {
    allowed: true,
    remaining: maxRequests - validRequests.length,
    resetTime: now + windowMs
  };
}

// Função para obter permissões necessárias para uma ação
export function getRequiredPermissions(action) {
  const permissionMap = {
    'jovens.ver': [PERMISSOES.JOVENS_VER],
    'jovens.criar': [PERMISSOES.JOVENS_CRIAR],
    'jovens.editar': [PERMISSOES.JOVENS_EDITAR],
    'jovens.deletar': [PERMISSOES.JOVENS_DELETAR],
    'jovens.aprovar': [PERMISSOES.JOVENS_APROVAR],
    'avaliacoes.ver': [PERMISSOES.AVALIACOES_VER],
    'avaliacoes.criar': [PERMISSOES.AVALIACOES_CRIAR],
    'avaliacoes.editar': [PERMISSOES.AVALIACOES_EDITAR],
    'avaliacoes.deletar': [PERMISSOES.AVALIACOES_DELETAR],
    'usuarios.ver': [PERMISSOES.USUARIOS_VER],
    'usuarios.criar': [PERMISSOES.USUARIOS_CRIAR],
    'usuarios.editar': [PERMISSOES.USUARIOS_EDITAR],
    'usuarios.deletar': [PERMISSOES.USUARIOS_DELETAR],
    'usuarios.transferir': [PERMISSOES.USUARIOS_TRANSFERIR],
    'relatorios.ver': [PERMISSOES.RELATORIOS_VER],
    'relatorios.exportar': [PERMISSOES.RELATORIOS_EXPORTAR],
    'sistema.configurar': [PERMISSOES.SISTEMA_CONFIGURAR],
    'sistema.auditoria': [PERMISSOES.SISTEMA_AUDITORIA]
  };
  
  return permissionMap[action] || [];
}

// Função para inicializar segurança
export async function initializeSecurity() {
  // Verificar se há usuário logado através do userProfile
  const currentProfile = userProfile;
  if (currentProfile && $currentProfile) {
    await loadUserPermissoes($currentProfile.id);
  }
}
