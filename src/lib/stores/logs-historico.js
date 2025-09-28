import { writable, get } from 'svelte/store';
import { supabase } from '$lib/utils/supabase';

// Stores para logs de histórico
export const logsHistorico = writable([]);
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
  jovem_id: '',
  user_id: '',
  acao: '',
  data_inicio: '',
  data_fim: ''
});

/**
 * Carregar logs de histórico
 */
export async function loadLogsHistorico(page = 1, limit = 20) {
  loading.set(true);
  error.set(null);
  
  try {
    const currentFilters = get(filters);
    
    let query = supabase
      .from('logs_historico')
      .select(`
        *,
        jovem:jovens(nome_completo, foto),
        usuario:usuarios(nome, email)
      `, { count: 'exact' });
    
    // Aplicar filtros
    if (currentFilters.jovem_id) {
      query = query.eq('jovem_id', currentFilters.jovem_id);
    }
    if (currentFilters.user_id) {
      query = query.eq('user_id', currentFilters.user_id);
    }
    if (currentFilters.acao) {
      query = query.ilike('acao', `%${currentFilters.acao}%`);
    }
    if (currentFilters.data_inicio) {
      query = query.gte('created_at', currentFilters.data_inicio);
    }
    if (currentFilters.data_fim) {
      query = query.lte('created_at', currentFilters.data_fim);
    }
    
    // Ordenar e paginar
    query = query
      .order('created_at', { ascending: false })
      .range((page - 1) * limit, page * limit - 1);
    
    const { data, error: fetchError, count } = await query;
    
    if (fetchError) throw fetchError;
    
    logsHistorico.set(data || []);
    pagination.set({
      page,
      limit,
      total: count || 0,
      totalPages: Math.ceil((count || 0) / limit)
    });
    
  } catch (err) {
    error.set(err.message);
    console.error('Error loading logs histórico:', err);
  } finally {
    loading.set(false);
  }
}

/**
 * Criar log de histórico
 */
export async function createLogHistorico(jovemId, acao, detalhe, dadosAnteriores = null, dadosNovos = null) {
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
    
    const { data, error: insertError } = await supabase
      .from('logs_historico')
      .insert([{
        jovem_id: jovemId,
        user_id: usuario.id,
        acao,
        detalhe,
        dados_anteriores: dadosAnteriores ? JSON.stringify(dadosAnteriores) : null,
        dados_novos: dadosNovos ? JSON.stringify(dadosNovos) : null,
        created_at: new Date().toISOString()
      }])
      .select()
      .single();
    
    if (insertError) throw insertError;
    
    return data;
  } catch (err) {
    console.error('Error creating log histórico:', err);
    throw err;
  }
}

/**
 * Aplicar filtros
 */
export function aplicarFiltros() {
  pagination.update(p => ({ ...p, page: 1 }));
  loadLogsHistorico(1, get(pagination).limit);
}

/**
 * Limpar filtros
 */
export function limparFiltros() {
  filters.set({
    jovem_id: '',
    user_id: '',
    acao: '',
    data_inicio: '',
    data_fim: ''
  });
  aplicarFiltros();
}

/**
 * Exportar logs para CSV
 */
export function exportarLogsCSV() {
  const logs = get(logsHistorico);
  
  const csv = [
    'Data,Jovem,Usuário,Ação,Detalhe,Dados Anteriores,Dados Novos',
    ...logs.map(log => [
      new Date(log.created_at).toLocaleString('pt-BR'),
      log.jovem?.nome_completo || 'N/A',
      log.usuario?.nome || 'N/A',
      log.acao,
      log.detalhe,
      log.dados_anteriores || '',
      log.dados_novos || ''
    ].map(field => `"${field}"`).join(','))
  ].join('\n');
  
  const blob = new Blob([csv], { type: 'text/csv;charset=utf-8;' });
  const link = document.createElement('a');
  const url = URL.createObjectURL(blob);
  link.setAttribute('href', url);
  link.setAttribute('download', `logs_historico_${new Date().toISOString().split('T')[0]}.csv`);
  link.style.visibility = 'hidden';
  document.body.appendChild(link);
  link.click();
  document.body.removeChild(link);
}

/**
 * Obter cor da ação
 */
export function getAcaoColor(acao) {
  const colors = {
    'cadastro': 'text-green-600 bg-green-100',
    'edicao': 'text-blue-600 bg-blue-100',
    'exclusao': 'text-red-600 bg-red-100',
    'avaliacao': 'text-purple-600 bg-purple-100',
    'aprovacao': 'text-yellow-600 bg-yellow-100',
    'transferencia': 'text-orange-600 bg-orange-100',
    'upload': 'text-indigo-600 bg-indigo-100',
    'download': 'text-gray-600 bg-gray-100'
  };
  return colors[acao] || 'text-gray-600 bg-gray-100';
}
