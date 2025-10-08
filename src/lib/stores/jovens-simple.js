import { writable, derived } from 'svelte/store';
import { supabase } from '$lib/utils/supabase';

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
    if (!Array.isArray($jovens)) return [];
    
    return $jovens.filter(jovem => {
      if ($filters.edicao) {
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
          if (!jovem.tem_avaliacoes) return false;
        } else if (jovem.aprovado !== $filters.aprovado) {
          return false;
        }
      }
      if ($filters.nome_like) {
        const nomeMatch = jovem.nome_completo && 
                         jovem.nome_completo.toLowerCase().includes($filters.nome_like.toLowerCase());
        if (!nomeMatch) return false;
      }
      return true;
    });
  }
);

export async function loadJovens(page = 1, limit = 20, userId = null, userLevel = null, options = {}) {
  loading.set(true);
  error.set(null);
  
  try {
    // Consulta otimizada com relacionamentos
    let query = supabase
      .from('jovens')
      .select(`
        *,
        estado:estados!estado_id(id, nome, sigla, bandeira),
        bloco:blocos!bloco_id(id, nome),
        regiao:regioes!regiao_id(id, nome),
        igreja:igrejas!igreja_id(id, nome, endereco),
        edicao:edicoes!edicao_id(id, nome, numero)
      `, { count: 'exact' });
    
    // Escopo por nível (inclui jovens associados via tabela associativa)
    if (userLevel && userId) {
      if (userLevel === 'colaborador') {
        query = query.eq('usuario_id', userId);
      } else if (userLevel === 'lider_estadual_iurd' || userLevel === 'lider_estadual_fju') {
        const estadoId = options?.scope?.estadoId;
        if (estadoId) {
          // Buscar IDs de jovens associados ao usuário
          const { data: associados } = await supabase
            .from('jovens_usuarios_associacoes')
            .select('jovem_id')
            .eq('usuario_id', userId);
          
          const associadosIds = associados?.map(a => a.jovem_id) || [];
          if (associadosIds.length > 0) {
            query = query.or(`estado_id.eq.${estadoId},id.in.(${associadosIds.join(',')})`);
          } else {
            query = query.eq('estado_id', estadoId);
          }
        }
      } else if (userLevel === 'lider_bloco_iurd' || userLevel === 'lider_bloco_fju') {
        const blocoId = options?.scope?.blocoId;
        if (blocoId) {
          // Buscar IDs de jovens associados ao usuário
          const { data: associados } = await supabase
            .from('jovens_usuarios_associacoes')
            .select('jovem_id')
            .eq('usuario_id', userId);
          
          const associadosIds = associados?.map(a => a.jovem_id) || [];
          if (associadosIds.length > 0) {
            query = query.or(`bloco_id.eq.${blocoId},id.in.(${associadosIds.join(',')})`);
          } else {
            query = query.eq('bloco_id', blocoId);
          }
        }
      } else if (userLevel === 'lider_regional_iurd') {
        const regiaoId = options?.scope?.regiaoId;
        if (regiaoId) {
          // Buscar IDs de jovens associados ao usuário
          const { data: associados } = await supabase
            .from('jovens_usuarios_associacoes')
            .select('jovem_id')
            .eq('usuario_id', userId);
          
          const associadosIds = associados?.map(a => a.jovem_id) || [];
          if (associadosIds.length > 0) {
            query = query.or(`regiao_id.eq.${regiaoId},id.in.(${associadosIds.join(',')})`);
          } else {
            query = query.eq('regiao_id', regiaoId);
          }
        }
      } else if (userLevel === 'lider_igreja_iurd') {
        const igrejaId = options?.scope?.igrejaId;
        if (igrejaId) {
          // Buscar IDs de jovens associados ao usuário
          const { data: associados } = await supabase
            .from('jovens_usuarios_associacoes')
            .select('jovem_id')
            .eq('usuario_id', userId);
          
          const associadosIds = associados?.map(a => a.jovem_id) || [];
          if (associadosIds.length > 0) {
            query = query.or(`igreja_id.eq.${igrejaId},id.in.(${associadosIds.join(',')})`);
          } else {
            query = query.eq('igreja_id', igrejaId);
          }
        }
      }
    }
    
    const { data, error: fetchError, count } = await query
      .order('data_cadastro', { ascending: false })
      .range((page - 1) * limit, page * limit - 1);
    
    console.log('🔍 DEBUG - Dados brutos retornados:', data);
    console.log('🔍 DEBUG - Primeiro jovem completo:', data?.[0]);
    console.log('🔍 DEBUG - Relacionamentos do primeiro jovem:', {
      estado: data?.[0]?.estado,
      bloco: data?.[0]?.bloco,
      regiao: data?.[0]?.regiao,
      igreja: data?.[0]?.igreja
    });
    
    // Debug específico para dados geográficos
    if (data && data.length > 0) {
      const primeiroJovem = data[0];
      console.log('🔍 DEBUG - IDs geográficos do primeiro jovem:', {
        estado_id: primeiroJovem.estado_id,
        bloco_id: primeiroJovem.bloco_id,
        regiao_id: primeiroJovem.regiao_id,
        igreja_id: primeiroJovem.igreja_id
      });
      console.log('🔍 DEBUG - Objetos geográficos do primeiro jovem:', {
        estado: primeiroJovem.estado,
        bloco: primeiroJovem.bloco,
        regiao: primeiroJovem.regiao,
        igreja: primeiroJovem.igreja
      });
    }
    
    if (fetchError) {
      console.error('Erro ao carregar jovens:', fetchError);
      throw fetchError;
    }
    
    if (!data || data.length === 0) {
      jovens.set([]);
      pagination.set({
        page,
        limit,
        total: 0,
        totalPages: 0
      });
      return;
    }
    
    // Buscar apenas avaliações (dados relacionados já vêm na consulta principal)
    const jovensIds = data.map(j => j.id);
    const { data: avaliacoesData } = await supabase
      .from('avaliacoes')
      .select('jovem_id')
      .in('jovem_id', jovensIds);
    
    // Processar dados (relacionamentos já vêm na consulta)
    const processedData = data.map(jovem => {
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
    error.set(err.message || 'Erro desconhecido');
  } finally {
    loading.set(false);
  }
}

export async function loadJovemById(id) {
  loading.set(true);
  error.set(null);
  
  try {
    // Usar consulta direta em vez da função RPC
    const { data, error: fetchError } = await supabase
      .from('jovens')
      .select(`
        *,
        estados!estado_id(id, nome, sigla, bandeira),
        blocos!bloco_id(id, nome),
        regioes!regiao_id(id, nome),
        igrejas!igreja_id(id, nome, endereco),
        edicoes!edicao_id(id, nome, numero)
      `)
      .eq('id', id)
      .single();
    
    if (fetchError) throw fetchError;
    return data;
  } catch (err) {
    console.error('Erro ao carregar jovem:', err);
    error.set(err.message);
    return null;
  } finally {
    loading.set(false);
  }
}

export async function createJovem(jovemData) {
  loading.set(true);
  error.set(null);
  
  try {
    const { data, error: fetchError } = await supabase
      .from('jovens')
      .insert([jovemData])
      .select()
      .single();
    
    if (fetchError) throw fetchError;
    
    // Atualizar a lista local
    jovens.update(current => [data, ...current]);
    
    return data;
  } catch (err) {
    console.error('Error creating jovem:', err);
    error.set(err.message);
    return null;
  } finally {
    loading.set(false);
  }
}

export async function updateJovem(id, updates) {
  loading.set(true);
  error.set(null);
  
  try {
    const { data, error: fetchError } = await supabase
      .from('jovens')
      .update(updates)
      .eq('id', id)
      .select()
      .single();
    
    if (fetchError) throw fetchError;
    
    // Atualizar a lista local
    jovens.update(current => 
      current.map(jovem => jovem.id === id ? { ...jovem, ...data } : jovem)
    );
    
    return data;
  } catch (err) {
    console.error('Error updating jovem:', err);
    error.set(err.message);
    return null;
  } finally {
    loading.set(false);
  }
}

export async function deleteJovem(id) {
  loading.set(true);
  error.set(null);
  
  try {
    const { error: fetchError } = await supabase
      .from('jovens')
      .delete()
      .eq('id', id);
    
    if (fetchError) throw fetchError;
    
    // Atualizar a lista local
    jovens.update(current => current.filter(jovem => jovem.id !== id));
    
    return true;
  } catch (err) {
    console.error('Error deleting jovem:', err);
    error.set(err.message);
    return false;
  } finally {
    loading.set(false);
  }
}

export async function aprovarJovem(id, status) {
  loading.set(true);
  error.set(null);
  
  try {
    // Verificar se o usuário pode aprovar este jovem (incluindo associações)
    const canApprove = await verificarPermissaoAprovarJovem(id);
    if (!canApprove) {
      throw new Error('Sem permissão para aprovar este jovem');
    }

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

// Função para verificar se o usuário pode aprovar um jovem específico (incluindo associações)
export async function verificarPermissaoAprovarJovem(jovemId) {
  try {
    console.log('🔍 DEBUG - verificarPermissaoAprovarJovem - jovemId:', jovemId);
    
    // Obter usuário atual
    const { data: { user } } = await supabase.auth.getUser();
    if (!user) {
      console.log('❌ DEBUG - Usuário não autenticado');
      return false;
    }

    // Buscar dados do usuário
    const { data: usuarioData } = await supabase
      .from('usuarios')
      .select('id, nivel, estado_id, bloco_id, regiao_id, igreja_id')
      .eq('id_auth', user.id)
      .single();

    if (!usuarioData) {
      console.log('❌ DEBUG - Dados do usuário não encontrados');
      return false;
    }

    console.log('✅ DEBUG - Dados do usuário:', usuarioData);

    // Buscar dados do jovem
    const { data: jovemData } = await supabase
      .from('jovens')
      .select('id, estado_id, bloco_id, regiao_id, igreja_id')
      .eq('id', jovemId)
      .single();

    if (!jovemData) {
      console.log('❌ DEBUG - Dados do jovem não encontrados');
      return false;
    }

    console.log('✅ DEBUG - Dados do jovem:', jovemData);

    const { nivel, estado_id, bloco_id, regiao_id, igreja_id } = usuarioData;

    // Administrador e líderes nacionais podem aprovar qualquer jovem
    if (nivel === 'administrador' || nivel === 'lider_nacional_iurd' || nivel === 'lider_nacional_fju') {
      console.log('✅ DEBUG - Acesso por nível nacional/administrador');
      return true;
    }

    // Verificar acesso geográfico
    if (nivel === 'lider_estadual_iurd' || nivel === 'lider_estadual_fju') {
      console.log('🔍 DEBUG - Verificando acesso estadual:', { estado_id, jovem_estado: jovemData.estado_id });
      if (estado_id && jovemData.estado_id === estado_id) {
        console.log('✅ DEBUG - Acesso por escopo estadual');
        return true;
      }
    } else if (nivel === 'lider_bloco_iurd' || nivel === 'lider_bloco_fju') {
      console.log('🔍 DEBUG - Verificando acesso bloco:', { bloco_id, jovem_bloco: jovemData.bloco_id });
      if (bloco_id && jovemData.bloco_id === bloco_id) {
        console.log('✅ DEBUG - Acesso por escopo bloco');
        return true;
      }
    } else if (nivel === 'lider_regional_iurd') {
      console.log('🔍 DEBUG - Verificando acesso regional:', { regiao_id, jovem_regiao: jovemData.regiao_id });
      if (regiao_id && jovemData.regiao_id === regiao_id) {
        console.log('✅ DEBUG - Acesso por escopo regional');
        return true;
      }
    } else if (nivel === 'lider_igreja_iurd') {
      console.log('🔍 DEBUG - Verificando acesso igreja:', { igreja_id, jovem_igreja: jovemData.igreja_id });
      if (igreja_id && jovemData.igreja_id === igreja_id) {
        console.log('✅ DEBUG - Acesso por escopo igreja');
        return true;
      }
    }

    // Verificar se o jovem está associado ao usuário
    console.log('🔍 DEBUG - Verificando associação:', { jovemId, usuarioId: usuarioData.id });
    const { data: associacao, error: associacaoError } = await supabase
      .from('jovens_usuarios_associacoes')
      .select('id')
      .eq('jovem_id', jovemId)
      .eq('usuario_id', usuarioData.id)
      .single();

    console.log('🔍 DEBUG - Resultado associação:', { associacao, associacaoError });

    if (associacao) {
      console.log('✅ DEBUG - Acesso por associação');
      return true;
    }

    console.log('❌ DEBUG - Nenhuma permissão encontrada');
    return false;
  } catch (err) {
    console.error('❌ DEBUG - Error checking approval permission:', err);
    return false;
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
