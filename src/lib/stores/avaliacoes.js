import { writable } from 'svelte/store';
import { supabase } from '$lib/utils/supabase';
import { notificarEventoJovem } from '$lib/stores/notificacoes';

// Stores para avaliações
export const avaliacoes = writable([]);
export const loading = writable(false);
export const error = writable(null);

// Função para carregar todas as avaliações do sistema
export async function loadAvaliacoes(userId = null, userLevel = null, userProfile = null) {
  loading.set(true);
  error.set(null);
  
  try {
    let query = supabase
      .from('avaliacoes')
      .select(`
        *,
        jovem:jovens(id, nome_completo, foto, usuario_id, estado_id, bloco_id, regiao_id, igreja_id),
        avaliador:usuarios!avaliacoes_user_id_fkey(nome, foto, email)
      `);
    
    // Regras de escopo por nível/papel
    if ((userLevel || userProfile) && userProfile) {
      const nivel = (userProfile?.user_roles?.[0]?.roles?.slug) || userLevel;

      // Administrador e líderes nacionais: visão total
      const isNacional = nivel === 'lider_nacional_iurd' || nivel === 'lider_nacional_fju' || nivel === 'administrador';
      if (!isNacional) {
        // Para evitar problemas de alias/joins no PostgREST, filtramos por IDs de jovens do escopo
        let jovensIds = [];
        let jovensQuery = supabase.from('jovens').select('id');

        if (nivel === 'lider_estadual_iurd' || nivel === 'lider_estadual_fju') {
          if (!userProfile?.estado_id) { avaliacoes.set([]); return []; }
          jovensQuery = jovensQuery.eq('estado_id', userProfile.estado_id);
        } else if (nivel === 'lider_bloco_iurd' || nivel === 'lider_bloco_fju') {
          if (!userProfile?.bloco_id) { avaliacoes.set([]); return []; }
          jovensQuery = jovensQuery.eq('bloco_id', userProfile.bloco_id);
        } else if (nivel === 'lider_regional_iurd') {
          if (!userProfile?.regiao_id) { avaliacoes.set([]); return []; }
          jovensQuery = jovensQuery.eq('regiao_id', userProfile.regiao_id);
        } else if (nivel === 'lider_igreja_iurd') {
          if (!userProfile?.igreja_id) { avaliacoes.set([]); return []; }
          jovensQuery = jovensQuery.eq('igreja_id', userProfile.igreja_id);
        } else if (nivel === 'colaborador' && userId) {
          // colaborador: ver avaliações dele ou de jovens que cadastrou
          // Primeiro, IDs dos jovens que ele cadastrou
          const { data: jovensDoColab } = await supabase.from('jovens').select('id').eq('usuario_id', userId);
          const idsJovensColab = (jovensDoColab || []).map(j => j.id);
          if (idsJovensColab.length === 0) {
            // sem jovens cadastrados, filtra apenas as avaliações criadas pelo colaborador
            query = query.eq('user_id', userId);
          } else {
            query = query.or(`user_id.eq.${userId},jovem_id.in.(${idsJovensColab.join(',')})`);
          }
        }

        if (nivel !== 'colaborador') {
          const { data: jovensData, error: jovensErr } = await jovensQuery.limit(10000);
          if (jovensErr) throw jovensErr;
          jovensIds = (jovensData || []).map(j => j.id);
          if (jovensIds.length === 0) { avaliacoes.set([]); return []; }
          query = query.in('jovem_id', jovensIds);
        }
      }
    } else if (userLevel === 'colaborador' && userId) {
      // Fallback caso não tenha sido passado o profile
      query = query.eq('user_id', userId);
    }
    
    const { data, error: fetchError } = await query.order('criado_em', { ascending: false });
    
    if (fetchError) throw fetchError;
    
    console.log('Avaliações carregadas:', data);
    
    avaliacoes.set(data || []);
    return data;
  } catch (err) {
    error.set(err.message);
    console.error('Error loading avaliações:', err);
    return [];
  } finally {
    loading.set(false);
  }
}

// Função para carregar avaliações de um jovem
export async function loadAvaliacoesByJovem(jovemId) {
  loading.set(true);
  error.set(null);
  
  try {
    // Verificar se jovemId é válido
    if (!jovemId) {
      console.warn('loadAvaliacoesByJovem: jovemId é null ou undefined');
      avaliacoes.set([]);
      return [];
    }
    
    const { data, error: fetchError } = await supabase
      .from('avaliacoes')
      .select(`
        *,
        avaliador:usuarios!avaliacoes_user_id_fkey(nome, foto, email)
      `)
      .eq('jovem_id', jovemId)
      .order('criado_em', { ascending: false });
    
    if (fetchError) throw fetchError;
    
    console.log('Dados das avaliações carregados:', data);
    console.log('Primeira avaliação:', data?.[0]);
    console.log('Avaliador da primeira avaliação:', data?.[0]?.avaliador);
    
    avaliacoes.set(data || []);
    return data;
  } catch (err) {
    error.set(err.message);
    console.error('Error loading avaliações:', err);
    return [];
  } finally {
    loading.set(false);
  }
}

// Função para criar uma nova avaliação
export async function createAvaliacao(avaliacaoData) {
  loading.set(true);
  error.set(null);
  
  try {
    // Validar dados obrigatórios
    if (!avaliacaoData.jovem_id) throw new Error('ID do jovem é obrigatório');
    if (!avaliacaoData.user_id) throw new Error('ID do usuário é obrigatório');
    if (!avaliacaoData.espirito) throw new Error('Avaliação do espírito é obrigatória');
    if (!avaliacaoData.caractere) throw new Error('Avaliação do caráter é obrigatória');
    if (!avaliacaoData.disposicao) throw new Error('Avaliação da disposição é obrigatória');
    
    console.log('Criando avaliação com user_id:', avaliacaoData.user_id);
    
    const { data, error: createError } = await supabase
      .from('avaliacoes')
      .insert([{
        ...avaliacaoData,
        criado_em: new Date().toISOString()
      }])
      .select(`
        *,
        avaliador:usuarios!avaliacoes_user_id_fkey(nome, foto)
      `)
      .single();
    
    if (createError) throw createError;
    
    // Atualizar store local
    avaliacoes.update(avaliacoes => [data, ...avaliacoes]);
    
    // Criar log de auditoria
    try {
      await supabase.rpc('criar_log_auditoria', {
        p_jovem_id: avaliacaoData.jovem_id,
        p_acao: 'avaliacao',
        p_detalhe: `Nova avaliação criada - Nota: ${avaliacaoData.nota}`,
        p_dados_novos: JSON.stringify(avaliacaoData)
      });
    } catch (logError) {
      console.warn('Erro ao criar log de auditoria:', logError);
    }
    
    // Disparar notificação via RPC genérica (com fallback) com nomes
    try {
      const avaliadorNome = data?.avaliador?.nome || 'Um usuário';
      const { data: jovemData } = await supabase
        .from('jovens')
        .select('nome_completo')
        .eq('id', avaliacaoData.jovem_id)
        .single();
      const jovemNome = jovemData?.nome_completo || 'o jovem';
      const titulo = 'Avaliação registrada';
      const mensagem = `${avaliadorNome} avaliou ${jovemNome}.`;
      await supabase.rpc('notificar_evento_jovem', {
        p_jovem_id: avaliacaoData.jovem_id,
        p_tipo: 'avaliacao',
        p_titulo: titulo,
        p_mensagem: mensagem,
        p_acao_url: `/jovens/${avaliacaoData.jovem_id}`
      });
    } catch (e) {
      console.warn('RPC notificar_evento_jovem falhou, fallback para frontend:', e);
      await notificarEventoJovem(avaliacaoData.jovem_id, 'avaliacao', 'Avaliação registrada', 'Uma nova avaliação foi registrada.');
    }
    
    return data;
  } catch (err) {
    error.set(err.message);
    console.error('Error creating avaliação:', err);
    throw err;
  } finally {
    loading.set(false);
  }
}

// Função para atualizar uma avaliação
export async function updateAvaliacao(id, updates) {
  loading.set(true);
  error.set(null);
  
  try {
    const { data, error: updateError } = await supabase
      .from('avaliacoes')
      .update(updates)
      .eq('id', id)
      .select(`
        *,
        avaliador:usuarios!avaliacoes_user_id_fkey(nome, foto)
      `)
      .single();
    
    if (updateError) throw updateError;
    
    // Atualizar store local
    avaliacoes.update(avaliacoes => 
      avaliacoes.map(a => a.id === id ? data : a)
    );
    
    return data;
  } catch (err) {
    error.set(err.message);
    console.error('Error updating avaliação:', err);
    throw err;
  } finally {
    loading.set(false);
  }
}

// Função para deletar uma avaliação
export async function deleteAvaliacao(id) {
  loading.set(true);
  error.set(null);
  
  try {
    const { error: deleteError } = await supabase
      .from('avaliacoes')
      .delete()
      .eq('id', id);
    
    if (deleteError) throw deleteError;
    
    // Atualizar store local
    avaliacoes.update(avaliacoes => 
      avaliacoes.filter(a => a.id !== id)
    );
    
  } catch (err) {
    error.set(err.message);
    console.error('Error deleting avaliação:', err);
    throw err;
  } finally {
    loading.set(false);
  }
}

// Função para calcular estatísticas de avaliações
export function calculateAvaliacaoStats(avaliacoes) {
  if (!avaliacoes || avaliacoes.length === 0) {
    return {
      total: 0,
      mediaGeral: 0,
      distribuicaoEspirito: {},
      distribuicaoCaractere: {},
      distribuicaoDisposicao: {}
    };
  }
  
  const total = avaliacoes.length;
  const somaNotas = avaliacoes.reduce((acc, av) => acc + (av.nota || 0), 0);
  const mediaGeral = total > 0 ? somaNotas / total : 0;
  
  // Mapear enums para valores numéricos
  const enumValues = {
    espirito: { 'ruim': 2, 'ser_observar': 5, 'bom': 7, 'excelente': 10 },
    caractere: { 'ruim': 2, 'ser_observar': 5, 'bom': 7, 'excelente': 10 },
    disposicao: { 'desanimado': 2, 'pacato': 5, 'normal': 7, 'muito_disposto': 10 }
  };
  
  // Contar distribuição por categoria (quantidade de jovens)
  const distribuicaoEspirito = {};
  const distribuicaoCaractere = {};
  const distribuicaoDisposicao = {};
  
  avaliacoes.forEach(avaliacao => {
    // Espírito
    if (avaliacao.espirito) {
      const label = getEnumLabel(avaliacao.espirito, 'espirito');
      distribuicaoEspirito[label] = (distribuicaoEspirito[label] || 0) + 1;
    }
    
    // Caráter
    if (avaliacao.caractere) {
      const label = getEnumLabel(avaliacao.caractere, 'caractere');
      distribuicaoCaractere[label] = (distribuicaoCaractere[label] || 0) + 1;
    }
    
    // Disposição
    if (avaliacao.disposicao) {
      const label = getEnumLabel(avaliacao.disposicao, 'disposicao');
      distribuicaoDisposicao[label] = (distribuicaoDisposicao[label] || 0) + 1;
    }
  });
  
  return {
    total,
    mediaGeral: Math.round(mediaGeral * 10) / 10,
    distribuicaoEspirito,
    distribuicaoCaractere,
    distribuicaoDisposicao
  };
}

// Função auxiliar para obter labels dos enums
function getEnumLabel(value, type) {
  const labels = {
    espirito: {
      'ruim': 'Ruim',
      'ser_observar': 'Ser Observar',
      'bom': 'Bom',
      'excelente': 'Excelente'
    },
    caractere: {
      'excelente': 'Excelente',
      'bom': 'Bom',
      'ser_observar': 'Ser Observar',
      'ruim': 'Ruim'
    },
    disposicao: {
      'muito_disposto': 'Muito Disposta',
      'normal': 'Normal',
      'pacato': 'Pacata',
      'desanimado': 'Desanimada'
    }
  };
  
  return labels[type]?.[value] || value;
}

// Função para obter opções dos enums
export function getEnumOptions() {
  return {
    espirito: [
      { value: '', label: 'Selecione a avaliação' },
      { value: 'ruim', label: 'Ruim' },
      { value: 'ser_observar', label: 'Ser Observada' },
      { value: 'bom', label: 'Bom' },
      { value: 'excelente', label: 'Excelente' }
    ],
    caractere: [
      { value: '', label: 'Selecione a avaliação' },
      { value: 'excelente', label: 'Excelente' },
      { value: 'bom', label: 'Bom' },
      { value: 'ser_observar', label: 'Ser Observada' },
      { value: 'ruim', label: 'Ruim' }
    ],
    disposicao: [
      { value: '', label: 'Selecione a avaliação' },
      { value: 'muito_disposto', label: 'Muito Disposta' },
      { value: 'normal', label: 'Normal' },
      { value: 'pacato', label: 'Pacata' },
      { value: 'desanimado', label: 'Desanimada' }
    ],
    notas: [
      { value: '', label: 'Selecione a nota' },
      { value: '1', label: '1 - Muito Ruim' },
      { value: '2', label: '2 - Ruim' },
      { value: '3', label: '3 - Regular' },
      { value: '4', label: '4 - Abaixo da Média' },
      { value: '5', label: '5 - Média' },
      { value: '6', label: '6 - Acima da Média' },
      { value: '7', label: '7 - Bom' },
      { value: '8', label: '8 - Muito Bom' },
      { value: '9', label: '9 - Excelente' },
      { value: '10', label: '10 - Excepcional' }
    ]
  };
}
