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
      .select('aprovado, data_cadastro');
    
    if (jovensError) throw jovensError;
    
    // Buscar estatísticas das avaliações
    const { data: avaliacoesData, error: avaliacoesError } = await supabase
      .from('avaliacoes')
      .select('nota, criado_em');
    
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
