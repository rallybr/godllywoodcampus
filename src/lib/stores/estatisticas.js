import { writable, derived } from 'svelte/store';
import { supabase } from '$lib/utils/supabase';
import { filteredJovens } from './jovens';

// Store para estatísticas gerais
export const estatisticas = writable({
  totalJovens: 0,
  aprovados: 0,
  pendentes: 0,
  preAprovados: 0,
  totalAvaliacoes: 0,
  mediaGeral: 0,
  crescimento: 0
});

// Store para estatísticas das condições
export const condicoesStats = writable({
  auxPastor: 0,
  iburd: 0,
  obreiro: 0,
  colaborador: 0,
  cpo: 0,
  batizadoES: 0
});

export const loading = writable(false);
export const error = writable(null);

// Função para carregar estatísticas gerais
export async function loadEstatisticas() {
  loading.set(true);
  error.set(null);
  
  try {
    // Buscar estatísticas dos jovens
    const { data: jovensData, error: jovensError } = await supabase
      .from('jovens')
      .select('aprovado, data_cadastro, id');
    
    if (jovensError) throw jovensError;
    
    // Buscar estatísticas das avaliações
    const { data: avaliacoesData, error: avaliacoesError } = await supabase
      .from('avaliacoes')
      .select('nota, criado_em, jovem_id');
    
    if (avaliacoesError) throw avaliacoesError;
    
    // Calcular estatísticas dos jovens
    const totalJovens = jovensData.length;
    
    const aprovados = jovensData.filter(j => 
      j.aprovado === 'aprovado'
    ).length;
    
    const preAprovados = jovensData.filter(j => 
      j.aprovado === 'pre_aprovado'
    ).length;
    
    const pendentes = jovensData.filter(j => 
      j.aprovado === null || 
      j.aprovado === 'null' ||
      j.aprovado === undefined
    ).length;
    
    // Calcular jovens avaliados (que têm pelo menos uma avaliação)
    const jovensAvaliadosIds = [...new Set(avaliacoesData.map(a => a.jovem_id))];
    const avaliados = jovensAvaliadosIds.length;
    
    // Calcular estatísticas das avaliações
    const totalAvaliacoes = avaliacoesData.length;
    const mediaGeral = totalAvaliacoes > 0 
      ? avaliacoesData.reduce((acc, av) => acc + (av.nota || 0), 0) / totalAvaliacoes 
      : 0;
    
    // Calcular crescimento (comparar com mês anterior)
    const hoje = new Date();
    const mesAtual = new Date(hoje.getFullYear(), hoje.getMonth(), 1);
    const mesAnterior = new Date(hoje.getFullYear(), hoje.getMonth() - 1, 1);
    
    const jovensMesAtual = jovensData.filter(j => 
      new Date(j.data_cadastro) >= mesAtual
    ).length;
    
    const jovensMesAnterior = jovensData.filter(j => {
      const dataCadastro = new Date(j.data_cadastro);
      return dataCadastro >= mesAnterior && dataCadastro < mesAtual;
    }).length;
    
    const crescimento = jovensMesAnterior > 0 
      ? Math.round(((jovensMesAtual - jovensMesAnterior) / jovensMesAnterior) * 100)
      : 0;
    
    estatisticas.set({
      totalJovens,
      aprovados,
      pendentes,
      preAprovados,
      avaliados,
      totalAvaliacoes,
      mediaGeral: Math.round(mediaGeral * 10) / 10,
      crescimento
    });
    
  } catch (err) {
    error.set(err.message);
    console.error('Error loading estatísticas:', err);
  } finally {
    loading.set(false);
  }
}

// Função para carregar estatísticas do usuário logado
export async function loadEstatisticasUsuario(usuarioId) {
  loading.set(true);
  error.set(null);
  
  try {
    console.log('=== CARREGANDO ESTATÍSTICAS DO USUÁRIO ===');
    console.log('ID do usuário recebido:', usuarioId);
    
    // Buscar avaliações feitas pelo usuário
    console.log('Buscando avaliações do usuário...');
    const { data: avaliacoesUsuario, error: avaliacoesError } = await supabase
      .from('avaliacoes')
      .select('nota, criado_em')
      .eq('user_id', usuarioId);
    
    if (avaliacoesError) {
      console.error('Erro ao buscar avaliações:', avaliacoesError);
      throw avaliacoesError;
    }
    
    console.log('Avaliações encontradas:', avaliacoesUsuario);
    
    // Calcular estatísticas do usuário
    const totalAvaliacoes = avaliacoesUsuario.length;
    const mediaGeral = totalAvaliacoes > 0 
      ? avaliacoesUsuario.reduce((acc, av) => acc + (av.nota || 0), 0) / totalAvaliacoes 
      : 0;
    
    // Buscar total de jovens (para contexto)
    console.log('Buscando total de jovens...');
    const { data: jovensData, error: jovensError } = await supabase
      .from('jovens')
      .select('id');
    
    if (jovensError) {
      console.error('Erro ao buscar jovens:', jovensError);
      throw jovensError;
    }
    
    console.log('Jovens encontrados:', jovensData);
    
    const resultado = {
      totalJovens: jovensData.length,
      avaliacoesFeitas: totalAvaliacoes,
      mediaGeral: Math.round(mediaGeral * 10) / 10
    };
    
    console.log('Resultado das estatísticas:', resultado);
    
    return resultado;
    
  } catch (err) {
    error.set(err.message);
    console.error('Error loading estatísticas do usuário:', err);
    return {
      totalJovens: 0,
      avaliacoesFeitas: 0,
      mediaGeral: 0
    };
  } finally {
    loading.set(false);
  }
}

// Derived store para estatísticas baseadas nos jovens filtrados
export const estatisticasFiltradas = derived(
  filteredJovens,
  ($filteredJovens) => {
    const total = $filteredJovens.length;
    
    const aprovados = $filteredJovens.filter(j => 
      j.aprovado === 'aprovado'
    ).length;
    
    const preAprovados = $filteredJovens.filter(j => 
      j.aprovado === 'pre_aprovado'
    ).length;
    
    const pendentes = $filteredJovens.filter(j => 
      j.aprovado === null || 
      j.aprovado === 'null' ||
      j.aprovado === undefined
    ).length;
    
    return {
      total,
      aprovados,
      preAprovados,
      pendentes
    };
  }
);

// Função para carregar estatísticas das condições
export async function loadCondicoesStats() {
  loading.set(true);
  error.set(null);
  
  try {
    // Buscar todos os jovens de todas as edições
    const { data: jovensData, error: jovensError } = await supabase
      .from('jovens')
      .select('condicao, responsabilidade_igreja, ja_obreiro, foi_obreiro, ja_colaborador, foi_colaborador, batizado_es');
    
    if (jovensError) throw jovensError;
    
    console.log('Jovens carregados para estatísticas das condições:', jovensData.length);
    console.log('Primeiros 5 jovens:', jovensData.slice(0, 5));
    
    const stats = calcularCondicoes(jovensData);
    console.log('Estatísticas calculadas:', stats);
    
    condicoesStats.set(stats);
    
  } catch (err) {
    error.set(err.message);
    console.error('Error loading estatísticas das condições:', err);
  } finally {
    loading.set(false);
  }
}

// Função auxiliar para calcular as condições
function calcularCondicoes(jovensData) {
  const stats = {
    auxPastor: 0,
    iburd: 0,
    obreiro: 0,
    colaborador: 0,
    cpo: 0,
    batizadoES: 0
  };
  
  jovensData.forEach(jovem => {
    const condicao = (jovem.condicao || '').toLowerCase();
    const responsabilidade = (jovem.responsabilidade_igreja || '').toLowerCase();
    
    // Classificar por condição (valores exatos do formulário) - PRIORIDADE 1
    if (condicao === 'auxiliar_pastor') {
      stats.auxPastor++;
    } else if (condicao === 'iburd') {
      stats.iburd++;
    } else if (condicao === 'obreiro') {
      stats.obreiro++;
    } else if (condicao === 'colaborador') {
      stats.colaborador++;
    } else if (condicao === 'cpo') {
      stats.cpo++;
    } else if (condicao === 'jovem_batizado_es') {
      stats.batizadoES++;
    } else {
      // Se não tem condição definida, classificar por responsabilidade
      if (responsabilidade.includes('aux') && responsabilidade.includes('pastor')) {
        stats.auxPastor++;
      } else if (responsabilidade.includes('iburd')) {
        stats.iburd++;
      } else if (responsabilidade.includes('obreiro') || jovem.ja_obreiro || jovem.foi_obreiro) {
        stats.obreiro++;
      } else if (responsabilidade.includes('colaborador') || jovem.ja_colaborador || jovem.foi_colaborador) {
        stats.colaborador++;
      } else if (responsabilidade.includes('cpo')) {
        stats.cpo++;
      } else {
        // Se não se encaixa em nenhuma categoria, não conta (ou poderia ser uma categoria "Outros")
        console.log('Jovem sem classificação:', jovem);
      }
    }
  });
  
  return stats;
}
