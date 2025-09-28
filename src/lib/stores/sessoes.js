import { writable, get } from 'svelte/store';
import { supabase } from '$lib/utils/supabase';

// Stores para sessões
export const sessoesAtivas = writable([]);
export const loading = writable(false);
export const error = writable(null);
export const pagination = writable({
  page: 1,
  limit: 20,
  total: 0,
  totalPages: 0
});

// Filtros
export const filters = writable({
  usuario_id: '',
  ip_address: '',
  ativo: '',
  data_inicio: '',
  data_fim: ''
});

/**
 * Carregar sessões ativas
 */
export async function loadSessoesAtivas(page = 1, limit = 20) {
  loading.set(true);
  error.set(null);
  
  try {
    const currentFilters = get(filters);
    
    let query = supabase
      .from('sessoes_usuario')
      .select(`
        *,
        usuario:usuarios(nome, email, foto)
      `, { count: 'exact' });
    
    // Aplicar filtros
    if (currentFilters.usuario_id) {
      query = query.eq('usuario_id', currentFilters.usuario_id);
    }
    if (currentFilters.ip_address) {
      query = query.ilike('ip_address', `%${currentFilters.ip_address}%`);
    }
    if (currentFilters.ativo !== '') {
      query = query.eq('ativo', currentFilters.ativo === 'true');
    }
    if (currentFilters.data_inicio) {
      query = query.gte('criado_em', currentFilters.data_inicio);
    }
    if (currentFilters.data_fim) {
      query = query.lte('criado_em', currentFilters.data_fim);
    }
    
    // Ordenar e paginar
    query = query
      .order('criado_em', { ascending: false })
      .range((page - 1) * limit, page * limit - 1);
    
    const { data, error: fetchError, count } = await query;
    
    if (fetchError) throw fetchError;
    
    sessoesAtivas.set(data || []);
    pagination.set({
      page,
      limit,
      total: count || 0,
      totalPages: Math.ceil((count || 0) / limit)
    });
    
  } catch (err) {
    error.set(err.message);
    console.error('Error loading sessões:', err);
  } finally {
    loading.set(false);
  }
}

/**
 * Criar nova sessão
 */
export async function createSessao(tokenHash, ipAddress, userAgent) {
  try {
    const { data: { user } } = await supabase.auth.getUser();
    if (!user) throw new Error('Usuário não autenticado');
    
    // Buscar ID do usuário na tabela usuarios
    const { data: usuario } = await supabase
      .from('usuarios')
      .select('id')
      .eq('id_auth', user.id)
      .single();
    
    if (!usuario) throw new Error('Usuário não encontrado');
    
    // Calcular expiração (24 horas por padrão)
    const expiraEm = new Date();
    expiraEm.setHours(expiraEm.getHours() + 24);
    
    const { data, error: insertError } = await supabase
      .from('sessoes_usuario')
      .insert([{
        usuario_id: usuario.id,
        token_hash: tokenHash,
        ip_address: ipAddress,
        user_agent: userAgent,
        ativo: true,
        expira_em: expiraEm.toISOString(),
        criado_em: new Date().toISOString()
      }])
      .select()
      .single();
    
    if (insertError) throw insertError;
    
    return data;
  } catch (err) {
    console.error('Error creating sessão:', err);
    throw err;
  }
}

/**
 * Invalidar sessão
 */
export async function invalidarSessao(sessaoId) {
  try {
    const { error: updateError } = await supabase
      .from('sessoes_usuario')
      .update({ 
        ativo: false,
        atualizado_em: new Date().toISOString()
      })
      .eq('id', sessaoId);
    
    if (updateError) throw updateError;
    
    // Recarregar lista
    await loadSessoesAtivas(get(pagination).page, get(pagination).limit);
    
  } catch (err) {
    console.error('Error invalidating sessão:', err);
    throw err;
  }
}

/**
 * Invalidar todas as sessões de um usuário
 */
export async function invalidarTodasSessoesUsuario(usuarioId) {
  try {
    const { error: updateError } = await supabase
      .from('sessoes_usuario')
      .update({ 
        ativo: false,
        atualizado_em: new Date().toISOString()
      })
      .eq('usuario_id', usuarioId)
      .eq('ativo', true);
    
    if (updateError) throw updateError;
    
    // Recarregar lista
    await loadSessoesAtivas(get(pagination).page, get(pagination).limit);
    
  } catch (err) {
    console.error('Error invalidating all sessões:', err);
    throw err;
  }
}

/**
 * Limpar sessões expiradas
 */
export async function limparSessoesExpiradas() {
  try {
    const { error: updateError } = await supabase
      .from('sessoes_usuario')
      .update({ 
        ativo: false,
        atualizado_em: new Date().toISOString()
      })
      .eq('ativo', true)
      .lt('expira_em', new Date().toISOString());
    
    if (updateError) throw updateError;
    
    // Recarregar lista
    await loadSessoesAtivas(get(pagination).page, get(pagination).limit);
    
  } catch (err) {
    console.error('Error cleaning expired sessões:', err);
    throw err;
  }
}

/**
 * Aplicar filtros
 */
export function aplicarFiltros() {
  pagination.update(p => ({ ...p, page: 1 }));
  loadSessoesAtivas(1, get(pagination).limit);
}

/**
 * Limpar filtros
 */
export function limparFiltros() {
  filters.set({
    usuario_id: '',
    ip_address: '',
    ativo: '',
    data_inicio: '',
    data_fim: ''
  });
  aplicarFiltros();
}

/**
 * Exportar sessões para CSV
 */
export function exportarSessoesCSV() {
  const sessoes = get(sessoesAtivas);
  
  const csv = [
    'Data Criação,Usuário,IP,User Agent,Ativo,Expira Em',
    ...sessoes.map(sessao => [
      new Date(sessao.criado_em).toLocaleString('pt-BR'),
      sessao.usuario?.nome || 'N/A',
      sessao.ip_address,
      sessao.user_agent,
      sessao.ativo ? 'Sim' : 'Não',
      new Date(sessao.expira_em).toLocaleString('pt-BR')
    ].map(field => `"${field}"`).join(','))
  ].join('\n');
  
  const blob = new Blob([csv], { type: 'text/csv;charset=utf-8;' });
  const link = document.createElement('a');
  const url = URL.createObjectURL(blob);
  link.setAttribute('href', url);
  link.setAttribute('download', `sessoes_ativas_${new Date().toISOString().split('T')[0]}.csv`);
  link.style.visibility = 'hidden';
  document.body.appendChild(link);
  link.click();
  document.body.removeChild(link);
}

/**
 * Verificar se sessão está ativa
 */
export function isSessaoAtiva(sessao) {
  if (!sessao.ativo) return false;
  return new Date(sessao.expira_em) > new Date();
}

/**
 * Obter status da sessão
 */
export function getSessaoStatus(sessao) {
  if (!sessao.ativo) return { text: 'Inativa', color: 'text-red-600 bg-red-100' };
  if (new Date(sessao.expira_em) <= new Date()) return { text: 'Expirada', color: 'text-orange-600 bg-orange-100' };
  return { text: 'Ativa', color: 'text-green-600 bg-green-100' };
}
