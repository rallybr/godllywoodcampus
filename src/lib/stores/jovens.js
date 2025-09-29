import { writable, derived } from 'svelte/store';
import { supabase } from '$lib/utils/supabase';
import { createAuditLog } from '$lib/stores/security';
import { createLogHistorico } from '$lib/stores/logs-historico';
import { marcarJovemCadastrado } from '$lib/stores/jovem-cadastro';
import { notificarEventoJovem } from '$lib/stores/notificacoes';

export const jovens = writable([]);
export const loading = writable(false);
export const error = writable(null);
export const filters = writable({
  edicao: '',
  sexo: '',
  condicao: '',
  idade_min: '',
  idade_max: '',
  estado_id: '',
  bloco_id: '',
  regiao_id: '',
  igreja_id: '',
  aprovado: '',
  nome_like: ''
});

export const pagination = writable({
  page: 1,
  limit: 20,
  total: 0,
  totalPages: 0
});

// Derived store for filtered jovens
export const filteredJovens = derived(
  [jovens, filters],
  ([$jovens, $filters]) => {
    return $jovens.filter(jovem => {
      if ($filters.edicao) {
        // Verificar tanto o campo edicao quanto edicao_obj.nome
        const edicaoMatch = jovem.edicao === $filters.edicao || 
                           (jovem.edicao_obj && jovem.edicao_obj.nome === $filters.edicao);
        if (!edicaoMatch) return false;
      }
      if ($filters.sexo && jovem.sexo !== $filters.sexo) return false;
      if ($filters.condicao && jovem.condicao !== $filters.condicao) return false;
      if ($filters.idade_min && jovem.idade < parseInt($filters.idade_min)) return false;
      if ($filters.idade_max && jovem.idade > parseInt($filters.idade_max)) return false;
      if ($filters.estado_id && jovem.estado_id !== $filters.estado_id) return false;
      if ($filters.bloco_id && jovem.bloco_id !== $filters.bloco_id) return false;
      if ($filters.regiao_id && jovem.regiao_id !== $filters.regiao_id) return false;
      if ($filters.igreja_id && jovem.igreja_id !== $filters.igreja_id) return false;
      if ($filters.aprovado) {
        if ($filters.aprovado === 'avaliado') {
          // Filtrar jovens que têm avaliações (tem_avaliacoes = true)
          if (!jovem.tem_avaliacoes) return false;
        } else if ($filters.aprovado === 'null') {
          // Filtrar jovens não avaliados (aprovado = null)
          if (jovem.aprovado !== null) return false;
        } else {
          // Filtro normal para outros valores
          if (jovem.aprovado !== $filters.aprovado) return false;
        }
      }
      if ($filters.nome_like && !jovem.nome_completo.toLowerCase().includes($filters.nome_like.toLowerCase())) return false;
      return true;
    });
  }
);

export async function loadJovens(page = 1, limit = 20, userId = null, userLevel = null) {
  loading.set(true);
  error.set(null);
  
  try {
    // Consulta otimizada com relacionamentos
    let query = supabase
      .from('jovens')
      .select(`
        *,
        estado:estados(id, nome, sigla),
        bloco:blocos(id, nome),
        regiao:regioes(id, nome),
        igreja:igrejas(id, nome),
        edicao:edicoes(id, nome, numero)
      `, { count: 'exact' });
    
    // Se for colaborador, filtrar apenas jovens que ele cadastrou
    if (userLevel === 'colaborador' && userId) {
      query = query.eq('usuario_id', userId);
    }
    
    const { data, error: fetchError, count } = await query
      .order('data_cadastro', { ascending: false })
      .range((page - 1) * limit, page * limit - 1);
    
    if (fetchError) {
      console.error('Erro ao carregar jovens:', fetchError);
      throw fetchError;
    }
    
    // Buscar apenas avaliações (dados relacionados já vêm na consulta principal)
    const jovensIds = (data || []).map(j => j.id);
    const { data: avaliacoesData } = await supabase
      .from('avaliacoes')
      .select('jovem_id')
      .in('jovem_id', jovensIds);
    
    // Processar dados (relacionamentos já vêm na consulta)
    const processedData = (data || []).map(jovem => {
      const temAvaliacoes = avaliacoesData?.some(av => av.jovem_id === jovem.id) || false;
      
      return {
        ...jovem,
        tem_avaliacoes: temAvaliacoes
      };
    });
    
    jovens.set(processedData);
    pagination.set({
      page,
      limit,
      total: count || 0,
      totalPages: Math.ceil((count || 0) / limit)
    });
    
    console.log('=== JOVENS CARREGADOS COM SUCESSO ===');
  } catch (err) {
    console.error('=== ERRO AO CARREGAR JOVENS ===');
    console.error('Erro completo:', err);
    error.set(err.message);
  } finally {
    loading.set(false);
  }
}

export async function loadJovemById(id) {
  loading.set(true);
  error.set(null);
  
  try {
    const { data, error: fetchError } = await supabase
      .from('jovens')
      .select(`
        *,
        estado:estados(nome, sigla),
        bloco:blocos(nome),
        regiao:regioes(nome),
        igreja:igrejas(nome)
      `)
      .eq('id', id)
      .single();
    
    if (fetchError) throw fetchError;
    return data;
  } catch (err) {
    error.set(err.message);
    console.error('Error loading jovem:', err);
    return null;
  } finally {
    loading.set(false);
  }
}

export async function createJovem(jovemData) {
  loading.set(true);
  error.set(null);
  
  try {
    console.log('createJovem - Dados recebidos:', jovemData);
    console.log('createJovem - Campo edicao:', jovemData.edicao);
    console.log('createJovem - Campo edicao_id:', jovemData.edicao_id);
    console.log('createJovem - Campo foto:', jovemData.foto);
    console.log('=== REDES SOCIAIS NO CREATEJOVEM ===');
    console.log('Instagram:', jovemData.instagram);
    console.log('Facebook:', jovemData.facebook);
    console.log('TikTok:', jovemData.tiktok);
    console.log('Obs Redes:', jovemData.obs_redes);
    
    // Validar dados obrigatórios
    if (!jovemData.nome_completo) throw new Error('Nome completo é obrigatório');
    if (!jovemData.data_nasc) throw new Error('Data de nascimento é obrigatória');
    if (!jovemData.estado_id) throw new Error('Estado é obrigatório');
    if (!jovemData.edicao_id) throw new Error('Edição é obrigatória');
    
    console.log('createJovem - Validações básicas passaram');
    
    // Calcular idade automaticamente
    const hoje = new Date();
    
    // Garantir associação do cadastro ao usuário logado (necessário para RLS)
    let usuarioIdInsercao = null;
    try {
      const { data: authData } = await supabase.auth.getUser();
      const authUser = authData?.user;
      if (authUser?.id) {
        const { data: usuarioRow } = await supabase
          .from('usuarios')
          .select('id')
          .eq('id_auth', authUser.id)
          .single();
        usuarioIdInsercao = usuarioRow?.id || null;
      }
    } catch (e) {
      console.warn('createJovem - Não foi possível resolver usuario_id para inserção:', e);
    }
    
    // Validar e formatar data de nascimento
    let dataNascimento = jovemData.data_nasc;
    console.log('createJovem - Data de nascimento original:', dataNascimento, 'Tipo:', typeof dataNascimento);
    
    if (typeof dataNascimento === 'string' && dataNascimento.includes('/')) {
      console.log('createJovem - Convertendo data de DD/MM/YYYY para YYYY-MM-DD');
      // Converter de DD/MM/YYYY para YYYY-MM-DD
      const [day, month, year] = dataNascimento.split('/');
      dataNascimento = `${year}-${month.padStart(2, '0')}-${day.padStart(2, '0')}`;
      console.log('createJovem - Data convertida:', dataNascimento);
    }
    
    const nascimento = new Date(dataNascimento);
    console.log('createJovem - Objeto Date criado:', nascimento);
    
    // Verificar se a data é válida
    if (isNaN(nascimento.getTime())) {
      throw new Error('Data de nascimento inválida');
    }
    
    let idade = hoje.getFullYear() - nascimento.getFullYear();
    const mesAtual = hoje.getMonth();
    const mesNascimento = nascimento.getMonth();
    
    if (mesAtual < mesNascimento || (mesAtual === mesNascimento && hoje.getDate() < nascimento.getDate())) {
      idade--;
    }
    
    // Buscar o nome da edição selecionada
    let nomeEdicao = '2024'; // Valor padrão
    if (jovemData.edicao_id) {
      try {
        const { data: edicaoData } = await supabase
          .from('edicoes')
          .select('nome')
          .eq('id', jovemData.edicao_id)
          .single();
        
        if (edicaoData) {
          nomeEdicao = edicaoData.nome;
          console.log('createJovem - Nome da edição encontrado:', nomeEdicao);
        }
      } catch (err) {
        console.warn('createJovem - Erro ao buscar nome da edição:', err);
      }
    }
    
    // Preparar dados para inserção
    const dadosCompletos = {
      ...jovemData,
      data_nasc: dataNascimento, // Usar data formatada
      edicao: nomeEdicao, // Usar o nome da edição selecionada
      idade: idade,
      data_cadastro: new Date().toISOString(),
      aprovado: 'null', // Status inicial
      // Se o formulário não preencheu, usar o usuário logado
      usuario_id: jovemData.usuario_id || usuarioIdInsercao || jovemData.usuarioId || null
    };
    
    // Remover campos vazios que podem causar problemas no banco
    Object.keys(dadosCompletos).forEach(key => {
      if (dadosCompletos[key] === '') {
        // Remover campos de data vazios
        if (key.includes('data')) {
          console.log('createJovem - Removendo campo de data vazio:', key);
          delete dadosCompletos[key];
        }
        // Remover campos numéricos vazios
        else if (key === 'valor_divida') {
          console.log('createJovem - Removendo campo numérico vazio:', key);
          delete dadosCompletos[key];
        }
        // NÃO remover campo foto vazio - pode ser intencional
        else if (key === 'foto') {
          console.log('createJovem - Mantendo campo foto vazio (opcional)');
        }
      }
    });
    
    console.log('createJovem - Dados após limpeza:', dadosCompletos);
    console.log('createJovem - Campo foto após limpeza:', dadosCompletos.foto);
    
    console.log('createJovem - Tentando inserir dados:', dadosCompletos);
    
    const { data, error: createError } = await supabase
      .from('jovens')
      .insert([dadosCompletos])
      .select(`
        *,
        estado:estados(nome, sigla),
        bloco:blocos(nome),
        regiao:regioes(nome),
        igreja:igrejas(nome)
      `)
      .single();
    
    console.log('createJovem - Resultado da inserção:', { data, createError });
    
    if (createError) {
      console.error('createJovem - Erro detalhado:', createError);
      throw createError;
    }
    
    // Criar logs de auditoria e histórico
    try {
      await createAuditLog(
        'cadastro',
        `Jovem ${data.nome_completo} foi cadastrado no sistema`,
        null,
        data
      );
      
      await createLogHistorico(
        data.id,
        'cadastro',
        `Jovem ${data.nome_completo} foi cadastrado no sistema`,
        null,
        data
      );
    } catch (logError) {
      console.warn('Erro ao criar logs:', logError);
    }
    
    // Marcar jovem como cadastrado
    marcarJovemCadastrado();
    
    // Reload the list
    await loadJovens();
    return data;
  } catch (err) {
    error.set(err.message);
    console.error('Error creating jovem:', err);
    throw err;
  } finally {
    loading.set(false);
  }
}

export async function updateJovem(id, updates) {
  loading.set(true);
  error.set(null);
  
  try {
    // Buscar dados antigos para auditoria
    const { data: oldData } = await supabase
      .from('jovens')
      .select('*')
      .eq('id', id)
      .single();
    
    const { data, error: updateError } = await supabase
      .from('jovens')
      .update(updates)
      .eq('id', id)
      .select()
      .single();
    
    if (updateError) throw updateError;
    
    // Criar logs de auditoria e histórico
    try {
      await createAuditLog(
        'edicao',
        `Jovem ${data.nome_completo} foi editado`,
        oldData,
        data
      );
      
      await createLogHistorico(
        data.id,
        'edicao',
        `Jovem ${data.nome_completo} foi editado`,
        oldData,
        data
      );
    } catch (logError) {
      console.warn('Erro ao criar logs:', logError);
    }
    
    // Update local store
    jovens.update(jovens => 
      jovens.map(j => j.id === id ? { ...j, ...updates } : j)
    );
    
    // Notificações por mudanças relevantes
    try {
      const mudouAssociacao = Object.prototype.hasOwnProperty.call(updates, 'usuario_id') && updates.usuario_id !== oldData.usuario_id;
      const mudouCondicao = (Object.prototype.hasOwnProperty.call(updates, 'condicao') && updates.condicao !== oldData.condicao)
        || (Object.prototype.hasOwnProperty.call(updates, 'condicao_campus') && updates.condicao_campus !== oldData.condicao_campus);
      if (mudouAssociacao) {
        try {
          await supabase.rpc('notificar_associacao_jovem', {
            p_jovem_id: id,
            p_usuario_associado_id: updates.usuario_id,
            p_titulo: 'Jovem associado a usuário',
            p_mensagem: 'O jovem foi associado ao usuário selecionado.',
            p_acao_url: `/jovens/${id}`
          });
        } catch (rpcErr) {
          console.warn('RPC notificar_associacao_jovem falhou, fallback para frontend:', rpcErr);
          await notificarEventoJovem(id, 'sistema', 'Jovem associado a usuário', 'Um jovem foi associado a um usuário.');
        }
      }
      if (mudouCondicao) {
        try {
          await supabase.rpc('notificar_evento_jovem', {
            p_jovem_id: id,
            p_tipo: 'aprovacao',
            p_titulo: 'Condição atualizada',
            p_mensagem: 'A condição do jovem foi atualizada.',
            p_acao_url: `/jovens/${id}`
          });
        } catch (rpcErr2) {
          console.warn('RPC notificar_evento_jovem (condição) falhou, fallback:', rpcErr2);
          await notificarEventoJovem(id, 'aprovacao', 'Condição atualizada', 'A condição do jovem foi atualizada.');
        }
      }
      if (!mudouAssociacao && !mudouCondicao) {
        try {
          await supabase.rpc('notificar_evento_jovem', {
            p_jovem_id: id,
            p_tipo: 'sistema',
            p_titulo: 'Perfil do jovem atualizado',
            p_mensagem: 'Dados do jovem foram atualizados.',
            p_acao_url: `/jovens/${id}`
          });
        } catch (rpcErr3) {
          console.warn('RPC notificar_evento_jovem (edicao genérica) falhou, fallback:', rpcErr3);
          await notificarEventoJovem(id, 'sistema', 'Perfil do jovem atualizado', 'Dados do jovem foram atualizados.');
        }
      }
    } catch (e) {
      console.warn('Falha ao notificar edição de jovem:', e);
    }
    
    return data;
  } catch (err) {
    error.set(err.message);
    console.error('Error updating jovem:', err);
    throw err;
  } finally {
    loading.set(false);
  }
}

export async function deleteJovem(id) {
  loading.set(true);
  error.set(null);
  
  try {
    // Buscar dados antes de deletar para auditoria
    const { data: oldData } = await supabase
      .from('jovens')
      .select('*')
      .eq('id', id)
      .single();
    
    const { error: deleteError } = await supabase
      .from('jovens')
      .delete()
      .eq('id', id);
    
    if (deleteError) throw deleteError;
    
    // Criar logs de auditoria e histórico
    try {
      await createAuditLog(
        'exclusao',
        `Jovem ${oldData?.nome_completo || 'ID: ' + id} foi excluído`,
        oldData,
        null
      );
      
      await createLogHistorico(
        id,
        'exclusao',
        `Jovem ${oldData?.nome_completo || 'ID: ' + id} foi excluído`,
        oldData,
        null
      );
    } catch (logError) {
      console.warn('Erro ao criar logs:', logError);
    }
    
    // Update local store
    jovens.update(jovens => jovens.filter(j => j.id !== id));
    
    // Update pagination
    pagination.update(p => ({
      ...p,
      total: p.total - 1,
      totalPages: Math.ceil((p.total - 1) / p.limit)
    }));
  } catch (err) {
    error.set(err.message);
    console.error('Error deleting jovem:', err);
    throw err;
  } finally {
    loading.set(false);
  }
}

export async function aprovarJovem(id, status) {
  loading.set(true);
  error.set(null);
  
  try {
    // Usar a nova função de aprovação múltipla
    const { data, error: rpcError } = await supabase.rpc('aprovar_jovem_multiplo', {
      p_jovem_id: id,
      p_tipo_aprovacao: status,
      p_observacao: null
    });
    
    if (rpcError) throw rpcError;
    
    if (!data.success) {
      throw new Error(data.error || 'Erro ao aprovar jovem');
    }
    
    // Buscar aprovações atualizadas para atualizar o status do jovem
    const { data: aprovacoes, error: aprovacoesError } = await supabase
      .from('aprovacoes_jovens')
      .select('tipo_aprovacao')
      .eq('jovem_id', id);
    
    if (!aprovacoesError && aprovacoes) {
      // Determinar o status mais alto (aprovado > pre_aprovado)
      let statusFinal = null;
      if (aprovacoes.some(a => a.tipo_aprovacao === 'aprovado')) {
        statusFinal = 'aprovado';
      } else if (aprovacoes.some(a => a.tipo_aprovacao === 'pre_aprovado')) {
        statusFinal = 'pre_aprovado';
      }
      
      // Atualizar o status na tabela jovens
      if (statusFinal) {
        await supabase
          .from('jovens')
          .update({ aprovado: statusFinal })
          .eq('id', id);
      }
    }
    
    // Notificar mudança de aprovação via RPC (com fallback)
    try {
      const titulo = status === 'aprovado' ? 'Jovem aprovado' : status === 'pre_aprovado' ? 'Jovem pré-aprovado' : 'Status atualizado';
      const mensagem = 'O jovem foi aprovado por um novo usuário.';
      await supabase.rpc('notificar_evento_jovem', {
        p_jovem_id: id,
        p_tipo: 'aprovacao',
        p_titulo: titulo,
        p_mensagem: mensagem,
        p_acao_url: `/jovens/${id}`
      });
    } catch (e) {
      console.warn('RPC notificar_evento_jovem falhou, fallback para frontend:', e);
      const titulo = status === 'aprovado' ? 'Jovem aprovado' : status === 'pre_aprovado' ? 'Jovem pré-aprovado' : 'Status atualizado';
      await notificarEventoJovem(id, 'aprovacao', titulo, 'O jovem foi aprovado por um novo usuário.');
    }
    
    return data;
  } catch (err) {
    error.set(err.message);
    console.error('Error updating jovem approval:', err);
    throw err;
  } finally {
    loading.set(false);
  }
}

// Função para buscar aprovações de um jovem
export async function buscarAprovacoesJovem(jovemId) {
  try {
    const { data, error } = await supabase.rpc('buscar_aprovacoes_jovem', {
      p_jovem_id: jovemId
    });
    
    if (error) throw error;
    return data;
  } catch (err) {
    console.error('Error fetching approvals:', err);
    throw err;
  }
}

// Função para verificar se o usuário atual já aprovou um jovem
export async function verificarSeUsuarioJaAprovou(jovemId, tipoAprovacao = null) {
  try {
    const { data, error } = await supabase.rpc('usuario_ja_aprovou', {
      p_jovem_id: jovemId,
      p_tipo_aprovacao: tipoAprovacao
    });

    if (error) throw error;
    return data;
  } catch (err) {
    console.error('Error checking user approval:', err);
    return false;
  }
}

// Função para remover aprovação (apenas administradores)
export async function removerAprovacaoAdmin(aprovacaoId) {
  loading.set(true);
  error.set(null);

  try {
    const { data, error: rpcError } = await supabase.rpc('remover_aprovacao_admin', {
      p_aprovacao_id: aprovacaoId
    });

    if (rpcError) throw rpcError;

    if (!data.success) {
      throw new Error(data.error || 'Erro ao remover aprovação');
    }

    return data;
  } catch (err) {
    error.set(err.message);
    console.error('Error removing approval:', err);
    throw err;
  } finally {
    loading.set(false);
  }
}

export async function getJovemStats() {
  try {
    const { data, error } = await supabase
      .from('jovens')
      .select('aprovado, estado_id, edicao_id');
    
    if (error) throw error;
    
    const stats = {
      total: data.length,
      aprovados: data.filter(j => j.aprovado === 'aprovado').length,
      preAprovados: data.filter(j => j.aprovado === 'pre_aprovado').length,
      pendentes: data.filter(j => j.aprovado === 'null').length,
      porEdicao: {},
      porEstado: {}
    };
    
    // Calcular estatísticas por edição
    data.forEach(jovem => {
      if (jovem.edicao_id) {
        if (!stats.porEdicao[jovem.edicao_id]) {
          stats.porEdicao[jovem.edicao_id] = { total: 0, aprovados: 0, preAprovados: 0, pendentes: 0 };
        }
        stats.porEdicao[jovem.edicao_id].total++;
        if (jovem.aprovado === 'aprovado') stats.porEdicao[jovem.edicao_id].aprovados++;
        else if (jovem.aprovado === 'pre_aprovado') stats.porEdicao[jovem.edicao_id].preAprovados++;
        else stats.porEdicao[jovem.edicao_id].pendentes++;
      }
    });
    
    return stats;
  } catch (err) {
    console.error('Error getting jovem stats:', err);
    return null;
  }
}

export function clearFilters() {
  filters.set({
    edicao: '',
    sexo: '',
    condicao: '',
    idade_min: '',
    idade_max: '',
    estado_id: '',
    bloco_id: '',
    regiao_id: '',
    igreja_id: '',
    aprovado: '',
    nome_like: ''
  });
}
