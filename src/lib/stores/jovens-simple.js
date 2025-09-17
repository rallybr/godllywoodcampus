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

export async function loadJovens(page = 1, limit = 20) {
  loading.set(true);
  error.set(null);
  
  try {
    console.log('=== CARREGANDO JOVENS ===');
    console.log('Página:', page, 'Limite:', limit);
    
    // Consulta simples para testar
    const { data, error: fetchError, count } = await supabase
      .from('jovens')
      .select('*', { count: 'exact' })
      .order('data_cadastro', { ascending: false })
      .range((page - 1) * limit, page * limit - 1);
    
    console.log('Erro da consulta:', fetchError);
    console.log('Dados recebidos:', data);
    console.log('Count:', count);
    
    if (fetchError) {
      console.error('Erro detalhado:', fetchError);
      throw fetchError;
    }
    
    if (!data || data.length === 0) {
      console.log('Nenhum jovem encontrado');
      jovens.set([]);
      pagination.set({
        page,
        limit,
        total: 0,
        totalPages: 0
      });
      return;
    }
    
    // Buscar dados relacionados separadamente
    const jovensIds = data.map(j => j.id);
    
    // Buscar estados
    const { data: estadosData } = await supabase
      .from('estados')
      .select('id, nome, sigla')
      .in('id', [...new Set(data.map(j => j.estado_id).filter(Boolean))]);
    
    // Buscar blocos
    const { data: blocosData } = await supabase
      .from('blocos')
      .select('id, nome')
      .in('id', [...new Set(data.map(j => j.bloco_id).filter(Boolean))]);
    
    // Buscar regiões
    const { data: regioesData } = await supabase
      .from('regioes')
      .select('id, nome')
      .in('id', [...new Set(data.map(j => j.regiao_id).filter(Boolean))]);
    
    // Buscar igrejas
    const { data: igrejasData } = await supabase
      .from('igrejas')
      .select('id, nome')
      .in('id', [...new Set(data.map(j => j.igreja_id).filter(Boolean))]);
    
    // Buscar edições
    const { data: edicoesData } = await supabase
      .from('edicoes')
      .select('id, nome, numero')
      .in('id', [...new Set(data.map(j => j.edicao_id).filter(Boolean))]);
    
    // Buscar avaliações
    const { data: avaliacoesData } = await supabase
      .from('avaliacoes')
      .select('jovem_id')
      .in('jovem_id', jovensIds);
    
    console.log('Dados relacionados carregados');
    
    // Processar dados
    const processedData = data.map(jovem => {
      const estado = estadosData?.find(e => e.id === jovem.estado_id);
      const bloco = blocosData?.find(b => b.id === jovem.bloco_id);
      const regiao = regioesData?.find(r => r.id === jovem.regiao_id);
      const igreja = igrejasData?.find(i => i.id === jovem.igreja_id);
      const edicao = edicoesData?.find(e => e.id === jovem.edicao_id);
      const temAvaliacoes = avaliacoesData?.some(av => av.jovem_id === jovem.id) || false;
      
      return {
        ...jovem,
        estado,
        bloco,
        regiao,
        igreja,
        edicao_obj: edicao,
        tem_avaliacoes: temAvaliacoes
      };
    });
    
    console.log('Dados processados:', processedData);
    
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
    console.log('=== CARREGANDO JOVEM POR ID ===');
    console.log('ID recebido:', id);
    
    const { data, error: fetchError } = await supabase
      .from('jovens')
      .select(`
        *,
        estado:estados(nome, sigla),
        bloco:blocos(nome),
        regiao:regioes(nome),
        igreja:igrejas(nome),
        edicao_obj:edicoes(nome, numero)
      `)
      .eq('id', id)
      .single();
    
    console.log('Erro da consulta:', fetchError);
    console.log('Dados recebidos:', data);
    
    if (fetchError) {
      console.error('Erro detalhado:', fetchError);
      throw fetchError;
    }
    
    console.log('=== JOVEM CARREGADO COM SUCESSO ===');
    return data;
  } catch (err) {
    console.error('=== ERRO AO CARREGAR JOVEM ===');
    console.error('Erro completo:', err);
    error.set(err.message || 'Erro desconhecido');
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
  return updateJovem(id, { aprovado: status });
}
