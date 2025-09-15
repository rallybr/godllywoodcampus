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

export async function loadJovens(page = 1, limit = 20) {
  loading.set(true);
  error.set(null);
  
  try {
    const { data, error: fetchError, count } = await supabase
      .from('jovens')
      .select(`
        *,
        estado:estados(nome, sigla),
        bloco:blocos(nome),
        regiao:regioes(nome),
        igreja:igrejas(nome),
        edicao_obj:edicoes(nome, numero),
        avaliacoes:avaliacoes(count)
      `, { count: 'exact' })
      .order('data_cadastro', { ascending: false })
      .range((page - 1) * limit, page * limit - 1);
    
    if (fetchError) throw fetchError;
    
    // Processar dados para incluir informação sobre avaliações
    const processedData = (data || []).map(jovem => ({
      ...jovem,
      tem_avaliacoes: jovem.avaliacoes && jovem.avaliacoes.length > 0
    }));
    
    jovens.set(processedData);
    pagination.set({
      page,
      limit,
      total: count || 0,
      totalPages: Math.ceil((count || 0) / limit)
    });
  } catch (err) {
    error.set(err.message);
    console.error('Error loading jovens:', err);
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
    
    // Validar dados obrigatórios
    if (!jovemData.nome_completo) throw new Error('Nome completo é obrigatório');
    if (!jovemData.data_nasc) throw new Error('Data de nascimento é obrigatória');
    if (!jovemData.estado_id) throw new Error('Estado é obrigatório');
    if (!jovemData.edicao_id) throw new Error('Edição é obrigatória');
    
    console.log('createJovem - Validações básicas passaram');
    
    // Calcular idade automaticamente
    const hoje = new Date();
    
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
      aprovado: 'null' // Status inicial
    };
    
    // Remover campos de data vazios
    Object.keys(dadosCompletos).forEach(key => {
      if (dadosCompletos[key] === '' && key.includes('data')) {
        console.log('createJovem - Removendo campo de data vazio:', key);
        delete dadosCompletos[key];
      }
    });
    
    console.log('createJovem - Dados após limpeza:', dadosCompletos);
    
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
    
    // Criar log de auditoria
    try {
      await supabase.rpc('criar_log_auditoria', {
        p_jovem_id: data.id,
        p_acao: 'cadastro',
        p_detalhe: 'Jovem cadastrado no sistema',
        p_dados_novos: JSON.stringify(dadosCompletos)
      });
    } catch (logError) {
      console.warn('Erro ao criar log de auditoria:', logError);
    }
    
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
    const { data, error: updateError } = await supabase
      .from('jovens')
      .update(updates)
      .eq('id', id)
      .select()
      .single();
    
    if (updateError) throw updateError;
    
    // Update local store
    jovens.update(jovens => 
      jovens.map(j => j.id === id ? { ...j, ...updates } : j)
    );
    
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
    const { error: deleteError } = await supabase
      .from('jovens')
      .delete()
      .eq('id', id);
    
    if (deleteError) throw deleteError;
    
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
    const { data, error: updateError } = await supabase
      .from('jovens')
      .update({ aprovado: status })
      .eq('id', id)
      .select()
      .single();
    
    if (updateError) throw updateError;
    
    // Criar log de auditoria
    try {
      await supabase.rpc('criar_log_auditoria', {
        p_jovem_id: id,
        p_acao: 'aprovacao',
        p_detalhe: `Status de aprovação alterado para: ${status}`,
        p_dados_novos: JSON.stringify({ aprovado: status })
      });
    } catch (logError) {
      console.warn('Erro ao criar log de auditoria:', logError);
    }
    
    // Update local store
    jovens.update(jovens => 
      jovens.map(j => j.id === id ? { ...j, aprovado: status } : j)
    );
    
    return data;
  } catch (err) {
    error.set(err.message);
    console.error('Error updating jovem approval:', err);
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
