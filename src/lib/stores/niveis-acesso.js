import { writable, derived, get } from 'svelte/store';
import { supabase } from '$lib/utils/supabase';
import { user, userProfile } from './auth';

// Store para níveis de acesso
export const userRoles = writable([]);
export const userHierarchyLevel = writable(999);
export const loading = writable(false);
export const error = writable(null);

// Constantes dos níveis hierárquicos
export const HIERARCHY_LEVELS = {
  ADMINISTRADOR: 1,
  LIDER_NACIONAL: 2,
  LIDER_ESTADUAL: 3,
  LIDER_BLOCO: 4,
  LIDER_REGIONAL: 5,
  LIDER_IGREJA: 6,
  COLABORADOR: 7,
  JOVEM: 8
};

// Constantes dos papéis
export const ROLES = {
  ADMINISTRADOR: 'administrador',
  LIDER_NACIONAL_IURD: 'lider_nacional_iurd',
  LIDER_NACIONAL_FJU: 'lider_nacional_fju',
  LIDER_ESTADUAL_IURD: 'lider_estadual_iurd',
  LIDER_ESTADUAL_FJU: 'lider_estadual_fju',
  LIDER_BLOCO_IURD: 'lider_bloco_iurd',
  LIDER_BLOCO_FJU: 'lider_bloco_fju',
  LIDER_REGIONAL_IURD: 'lider_regional_iurd',
  LIDER_IGREJA_IURD: 'lider_igreja_iurd',
  COLABORADOR: 'colaborador',
  JOVEM: 'jovem'
};

// Store derivado para verificar se é administrador
export const isAdmin = derived(
  userHierarchyLevel,
  $level => $level === HIERARCHY_LEVELS.ADMINISTRADOR
);

// Store derivado para verificar se é líder nacional
export const isLiderNacional = derived(
  userHierarchyLevel,
  $level => $level === HIERARCHY_LEVELS.LIDER_NACIONAL
);

// Store derivado para verificar se é jovem
export const isJovem = derived(
  userHierarchyLevel,
  $level => $level === HIERARCHY_LEVELS.JOVEM
);

// Store derivado para verificar se é colaborador
export const isColaborador = derived(
  userHierarchyLevel,
  $level => $level === HIERARCHY_LEVELS.COLABORADOR
);

/**
 * Carregar nível de acesso do usuário
 */
export async function loadUserRoles() {
  loading.set(true);
  error.set(null);
  
  try {
    // Usar o userProfile que já está carregado
    const profile = $userProfile;
    
    if (!profile) {
      userRoles.set([]);
      userHierarchyLevel.set(999);
      return;
    }
    
    // Mapear o campo 'nivel' para o nível hierárquico
    const nivelHierarquico = getNivelHierarquico(profile.nivel);
    
    userRoles.set([{
      role_slug: profile.nivel,
      nivel_hierarquico: nivelHierarquico,
      estado_id: profile.estado_id,
      bloco_id: profile.bloco_id,
      regiao_id: profile.regiao_id,
      igreja_id: profile.igreja_id
    }]);
    
    userHierarchyLevel.set(nivelHierarquico);
    
  } catch (err) {
    error.set(err.message);
    console.error('Error loading user roles:', err);
  } finally {
    loading.set(false);
  }
}

/**
 * Mapear campo 'nivel' para nível hierárquico
 */
function getNivelHierarquico(nivel) {
  const mapping = {
    'administrador': HIERARCHY_LEVELS.ADMINISTRADOR,
    'lider_nacional_iurd': HIERARCHY_LEVELS.LIDER_NACIONAL,
    'lider_nacional_fju': HIERARCHY_LEVELS.LIDER_NACIONAL,
    'lider_estadual_iurd': HIERARCHY_LEVELS.LIDER_ESTADUAL,
    'lider_estadual_fju': HIERARCHY_LEVELS.LIDER_ESTADUAL,
    'lider_bloco_iurd': HIERARCHY_LEVELS.LIDER_BLOCO,
    'lider_bloco_fju': HIERARCHY_LEVELS.LIDER_BLOCO,
    'lider_regional_iurd': HIERARCHY_LEVELS.LIDER_REGIONAL,
    'lider_igreja_iurd': HIERARCHY_LEVELS.LIDER_IGREJA,
    'colaborador': HIERARCHY_LEVELS.COLABORADOR,
    'jovem': HIERARCHY_LEVELS.JOVEM
  };
  
  return mapping[nivel] || 999;
}

/**
 * Verificar se o usuário tem um papel específico
 */
export function hasRole(roleSlug) {
  const profile = $userProfile;
  return profile?.nivel === roleSlug;
}

/**
 * Verificar se o usuário tem acesso a uma localização específica
 */
export function canAccessLocation(estadoId, blocoId, regiaoId, igrejaId) {
  const profile = $userProfile;
  
  if (!profile) return false;
  
  // Administrador tem acesso total
  if (profile.nivel === 'administrador') return true;
  
  // Líderes nacionais têm acesso total
  if (profile.nivel === 'lider_nacional_iurd' || profile.nivel === 'lider_nacional_fju') return true;
  
  // Líderes estaduais têm acesso ao estado
  if (profile.nivel === 'lider_estadual_iurd' || profile.nivel === 'lider_estadual_fju') {
    return profile.estado_id === estadoId;
  }
  
  // Líderes de bloco têm acesso ao bloco
  if (profile.nivel === 'lider_bloco_iurd' || profile.nivel === 'lider_bloco_fju') {
    return profile.bloco_id === blocoId;
  }
  
  // Líder regional tem acesso à região
  if (profile.nivel === 'lider_regional_iurd') {
    return profile.regiao_id === regiaoId;
  }
  
  // Líder de igreja tem acesso à igreja
  if (profile.nivel === 'lider_igreja_iurd') {
    return profile.igreja_id === igrejaId;
  }
  
  // Colaborador e jovem têm acesso limitado (será verificado no backend)
  if (profile.nivel === 'colaborador' || profile.nivel === 'jovem') {
    return true; // O backend fará a verificação específica
  }
  
  return false;
}

/**
 * Verificar se o usuário pode acessar dados de um jovem específico
 */
export function canAccessJovem(jovemData) {
  if (!jovemData) return false;
  
  const profile = $userProfile;
  
  if (!profile) return false;
  
  // Administrador e líderes nacionais têm acesso total
  if (profile.nivel === 'administrador' || 
      profile.nivel === 'lider_nacional_iurd' || 
      profile.nivel === 'lider_nacional_fju') {
    return true;
  }
  
  // Verificar acesso por localização
  return canAccessLocation(
    jovemData.estado_id,
    jovemData.bloco_id,
    jovemData.regiao_id,
    jovemData.igreja_id
  );
}

/**
 * Verificar se o usuário pode acessar dados de viagem
 */
export function canAccessViagem(jovemData) {
  return canAccessJovem(jovemData);
}

/**
 * Obter filtros de localização baseados no nível de acesso
 */
export function getLocationFilters() {
  const profile = $userProfile;
  
  if (!profile) return {};
  
  // Administrador e líderes nacionais não têm filtros
  if (profile.nivel === 'administrador' || 
      profile.nivel === 'lider_nacional_iurd' || 
      profile.nivel === 'lider_nacional_fju') {
    return {};
  }
  
  // Líderes estaduais filtram por estado
  if (profile.nivel === 'lider_estadual_iurd' || profile.nivel === 'lider_estadual_fju') {
    return profile.estado_id ? { estado_id: profile.estado_id } : {};
  }
  
  // Líderes de bloco filtram por bloco
  if (profile.nivel === 'lider_bloco_iurd' || profile.nivel === 'lider_bloco_fju') {
    return profile.bloco_id ? { bloco_id: profile.bloco_id } : {};
  }
  
  // Líder regional filtra por região
  if (profile.nivel === 'lider_regional_iurd') {
    return profile.regiao_id ? { regiao_id: profile.regiao_id } : {};
  }
  
  // Líder de igreja filtra por igreja
  if (profile.nivel === 'lider_igreja_iurd') {
    return profile.igreja_id ? { igreja_id: profile.igreja_id } : {};
  }
  
  // Colaborador e jovem não têm filtros (será verificado no backend)
  return {};
}

/**
 * Obter nome do nível de acesso
 */
export function getLevelName(level) {
  const names = {
    [HIERARCHY_LEVELS.ADMINISTRADOR]: 'Administrador',
    [HIERARCHY_LEVELS.LIDER_NACIONAL]: 'Líder Nacional',
    [HIERARCHY_LEVELS.LIDER_ESTADUAL]: 'Líder Estadual',
    [HIERARCHY_LEVELS.LIDER_BLOCO]: 'Líder de Bloco',
    [HIERARCHY_LEVELS.LIDER_REGIONAL]: 'Líder Regional',
    [HIERARCHY_LEVELS.LIDER_IGREJA]: 'Líder de Igreja',
    [HIERARCHY_LEVELS.COLABORADOR]: 'Colaborador',
    [HIERARCHY_LEVELS.JOVEM]: 'Jovem'
  };
  return names[level] || 'Desconhecido';
}

/**
 * Obter cor do nível de acesso
 */
export function getLevelColor(level) {
  const colors = {
    [HIERARCHY_LEVELS.ADMINISTRADOR]: 'text-red-600 bg-red-100',
    [HIERARCHY_LEVELS.LIDER_NACIONAL]: 'text-purple-600 bg-purple-100',
    [HIERARCHY_LEVELS.LIDER_ESTADUAL]: 'text-blue-600 bg-blue-100',
    [HIERARCHY_LEVELS.LIDER_BLOCO]: 'text-indigo-600 bg-indigo-100',
    [HIERARCHY_LEVELS.LIDER_REGIONAL]: 'text-cyan-600 bg-cyan-100',
    [HIERARCHY_LEVELS.LIDER_IGREJA]: 'text-teal-600 bg-teal-100',
    [HIERARCHY_LEVELS.COLABORADOR]: 'text-orange-600 bg-orange-100',
    [HIERARCHY_LEVELS.JOVEM]: 'text-green-600 bg-green-100'
  };
  return colors[level] || 'text-gray-600 bg-gray-100';
}

/**
 * Verificar se o usuário pode gerenciar outro usuário
 */
export function canManageUser(targetUserLevel) {
  const profile = $userProfile;
  
  if (!profile) return false;
  
  const currentLevel = getNivelHierarquico(profile.nivel);
  return currentLevel < targetUserLevel;
}

/**
 * Verificar se o usuário pode ver uma página específica
 */
export function canAccessPage(pagePath) {
  const profile = $userProfile;
  
  if (!profile) return false;
  
  // Páginas que apenas administradores podem acessar
  const adminOnlyPages = ['/usuarios', '/seguranca', '/config'];
  if (adminOnlyPages.some(page => pagePath.startsWith(page))) {
    return profile.nivel === 'administrador';
  }
  
  // Páginas que jovens não podem acessar
  const notForJovens = ['/jovens', '/avaliacoes', '/relatorios'];
  if (notForJovens.some(page => pagePath.startsWith(page))) {
    return profile.nivel !== 'jovem';
  }
  
  // Páginas que apenas jovens podem acessar
  const onlyForJovens = ['/viagem'];
  if (onlyForJovens.some(page => pagePath.startsWith(page))) {
    return profile.nivel === 'jovem';
  }
  
  return true;
}

/**
 * Inicializar sistema de níveis de acesso
 */
export async function initializeAccessLevels() {
  const profile = get(userProfile);
  if (profile) {
    await loadUserRoles();
  }
}
