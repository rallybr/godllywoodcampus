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
  mediaEspirito: 0,
  mediaCaractere: 0,
  mediaDisposicao: 0,
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
export async function loadEstatisticas(userId = null, userLevel = null, userProfile = null) {
  loading.set(true);
  error.set(null);
  
  try {
    // Buscar estatísticas dos jovens
    let jovensQuery = supabase
      .from('jovens')
      .select('aprovado, data_cadastro, id, usuario_id, estado_id, bloco_id, regiao_id, igreja_id');
    
    // Aplicar filtros baseados na hierarquia de níveis de acesso
    if (userLevel === 'administrador') {
      // Administrador: acesso total - sem filtros
      console.log('🔍 DEBUG - Administrador: acesso total sem filtros');
    } else if (userLevel === 'lider_nacional_iurd' || userLevel === 'lider_nacional_fju') {
      // Líderes nacionais: acesso nacional - sem filtros
      console.log('🔍 DEBUG - Líder nacional: acesso nacional sem filtros');
    } else if (userLevel === 'lider_estadual_iurd' || userLevel === 'lider_estadual_fju') {
      // Líderes estaduais: acesso estadual
      if (userProfile?.estado_id) {
        console.log('🔍 DEBUG - Líder estadual: filtrando por estado:', { userId, userLevel, estado_id: userProfile.estado_id });
        jovensQuery = jovensQuery.eq('estado_id', userProfile.estado_id);
      } else {
        console.log('⚠️  WARNING - Líder estadual sem estado_id definido');
      }
    } else if (userLevel === 'lider_bloco_iurd' || userLevel === 'lider_bloco_fju') {
      // Líderes de bloco: acesso ao bloco
      if (userProfile?.bloco_id) {
        console.log('🔍 DEBUG - Líder de bloco: filtrando por bloco:', { userId, userLevel, bloco_id: userProfile.bloco_id });
        jovensQuery = jovensQuery.eq('bloco_id', userProfile.bloco_id);
      } else {
        console.log('⚠️  WARNING - Líder de bloco sem bloco_id definido');
      }
    } else if (userLevel === 'lider_regional_iurd') {
      // Líder regional: acesso à região
      if (userProfile?.regiao_id) {
        console.log('🔍 DEBUG - Líder regional: filtrando por região:', { userId, userLevel, regiao_id: userProfile.regiao_id });
        jovensQuery = jovensQuery.eq('regiao_id', userProfile.regiao_id);
      } else {
        console.log('⚠️  WARNING - Líder regional sem regiao_id definido');
      }
    } else if (userLevel === 'lider_igreja_iurd') {
      // Líder de igreja: acesso à igreja
      if (userProfile?.igreja_id) {
        console.log('🔍 DEBUG - Líder de igreja: filtrando por igreja:', { userId, userLevel, igreja_id: userProfile.igreja_id });
        jovensQuery = jovensQuery.eq('igreja_id', userProfile.igreja_id);
      } else {
        console.log('⚠️  WARNING - Líder de igreja sem igreja_id definido');
      }
    } else if (userLevel === 'colaborador' && userId) {
      // Colaborador: acesso aos jovens que ele cadastrou
      console.log('🔍 DEBUG - Colaborador: filtrando por usuário que cadastrou:', { userId, userLevel });
      jovensQuery = jovensQuery.eq('usuario_id', userId);
    } else if (userLevel === 'jovem' && userId) {
      // Jovem: acesso apenas aos seus próprios dados
      console.log('🔍 DEBUG - Jovem: filtrando por usuário:', { userId, userLevel });
      jovensQuery = jovensQuery.eq('usuario_id', userId);
    } else {
      console.log('🔍 DEBUG - Nível não reconhecido ou sem filtros:', { userId, userLevel });
    }
    
    const { data: jovensData, error: jovensError } = await jovensQuery;
    
    if (jovensError) throw jovensError;
    
    console.log('🔍 DEBUG - Jovens carregados para estatísticas:', jovensData?.length);
    console.log('🔍 DEBUG - Primeiros 3 jovens:', jovensData?.slice(0, 3));
    
    // Buscar estatísticas das avaliações
    let avaliacoesQuery = supabase
      .from('avaliacoes')
      .select('nota, criado_em, jovem_id, espirito, caractere, disposicao, user_id');
    
    // 🔧 APLICAR FILTROS NAS AVALIAÇÕES BASEADOS NO NÍVEL DE ACESSO
    if (userLevel === 'colaborador' && userId) {
      // Colaborador: apenas avaliações que ele fez
      console.log('🔍 DEBUG - Filtrando estatísticas de avaliações para colaborador:', { userId, userLevel });
      avaliacoesQuery = avaliacoesQuery.eq('user_id', userId);
    } else if (userLevel === 'lider_estadual_iurd' || userLevel === 'lider_estadual_fju') {
      // Líder estadual: apenas avaliações de jovens do seu estado
      if (userProfile?.estado_id) {
        console.log('🔍 DEBUG - Filtrando avaliações por estado:', { userLevel, estado_id: userProfile.estado_id });
        // Filtrar avaliações que pertencem a jovens do estado
        avaliacoesQuery = avaliacoesQuery.in('jovem_id', 
          jovensData.map(j => j.id)
        );
      }
    } else if (userLevel === 'lider_bloco_iurd' || userLevel === 'lider_bloco_fju') {
      // Líder de bloco: apenas avaliações de jovens do seu bloco
      if (userProfile?.bloco_id) {
        console.log('🔍 DEBUG - Filtrando avaliações por bloco:', { userLevel, bloco_id: userProfile.bloco_id });
        avaliacoesQuery = avaliacoesQuery.in('jovem_id', 
          jovensData.map(j => j.id)
        );
      }
    } else if (userLevel === 'lider_regional_iurd') {
      // Líder regional: apenas avaliações de jovens da sua região
      if (userProfile?.regiao_id) {
        console.log('🔍 DEBUG - Filtrando avaliações por região:', { userLevel, regiao_id: userProfile.regiao_id });
        avaliacoesQuery = avaliacoesQuery.in('jovem_id', 
          jovensData.map(j => j.id)
        );
      }
    } else if (userLevel === 'lider_igreja_iurd') {
      // Líder de igreja: apenas avaliações de jovens da sua igreja
      if (userProfile?.igreja_id) {
        console.log('🔍 DEBUG - Filtrando avaliações por igreja:', { userLevel, igreja_id: userProfile.igreja_id });
        avaliacoesQuery = avaliacoesQuery.in('jovem_id', 
          jovensData.map(j => j.id)
        );
      }
    } else {
      console.log('🔍 DEBUG - Não filtrando estatísticas de avaliações:', { userId, userLevel });
    }
    
    const { data: avaliacoesData, error: avaliacoesError } = await avaliacoesQuery;
    
    if (avaliacoesError) throw avaliacoesError;
    
    console.log('🔍 DEBUG - Avaliações carregadas para estatísticas:', avaliacoesData?.length);
    console.log('🔍 DEBUG - Primeiras 3 avaliações:', avaliacoesData?.slice(0, 3));
    
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
    
    console.log('🔍 DEBUG - Estatísticas calculadas:', {
      totalJovens,
      aprovados,
      preAprovados,
      pendentes
    });
    
    // Calcular jovens avaliados (que têm pelo menos uma avaliação)
    const jovensAvaliadosIds = [...new Set(avaliacoesData.map(a => a.jovem_id))];
    const avaliados = jovensAvaliadosIds.length;
    
    // Calcular estatísticas das avaliações
    const totalAvaliacoes = avaliacoesData.length;
    const mediaGeral = totalAvaliacoes > 0 
      ? avaliacoesData.reduce((acc, av) => acc + (av.nota || 0), 0) / totalAvaliacoes 
      : 0;
    
    // Calcular médias específicas
    const avaliacoesComEspirito = avaliacoesData.filter(av => av.espirito);
    const mediaEspirito = avaliacoesComEspirito.length > 0 
      ? avaliacoesComEspirito.reduce((acc, av) => {
          const valorEspirito = av.espirito === 'excelente' ? 5 : 
                               av.espirito === 'muito_bom' ? 4 :
                               av.espirito === 'bom' ? 3 :
                               av.espirito === 'regular' ? 2 : 1;
          return acc + valorEspirito;
        }, 0) / avaliacoesComEspirito.length
      : 0;
    
    const avaliacoesComCaractere = avaliacoesData.filter(av => av.caractere);
    const mediaCaractere = avaliacoesComCaractere.length > 0 
      ? avaliacoesComCaractere.reduce((acc, av) => {
          const valorCaractere = av.caractere === 'excelente' ? 5 : 
                                av.caractere === 'muito_bom' ? 4 :
                                av.caractere === 'bom' ? 3 :
                                av.caractere === 'regular' ? 2 : 1;
          return acc + valorCaractere;
        }, 0) / avaliacoesComCaractere.length
      : 0;
    
    const avaliacoesComDisposicao = avaliacoesData.filter(av => av.disposicao);
    const mediaDisposicao = avaliacoesComDisposicao.length > 0 
      ? avaliacoesComDisposicao.reduce((acc, av) => {
          const valorDisposicao = av.disposicao === 'muito_disposto' ? 5 : 
                                 av.disposicao === 'disposto' ? 4 :
                                 av.disposicao === 'neutro' ? 3 :
                                 av.disposicao === 'pouco_disposto' ? 2 : 1;
          return acc + valorDisposicao;
        }, 0) / avaliacoesComDisposicao.length
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
      mediaEspirito: Math.round(mediaEspirito * 10) / 10,
      mediaCaractere: Math.round(mediaCaractere * 10) / 10,
      mediaDisposicao: Math.round(mediaDisposicao * 10) / 10,
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
    
    // Buscar dados do usuário para aplicar filtros
    const { data: userData, error: userError } = await supabase
      .from('usuarios')
      .select('nivel, estado_id, bloco_id, regiao_id, igreja_id')
      .eq('id', usuarioId)
      .single();
    
    if (userError) {
      console.error('Erro ao buscar dados do usuário:', userError);
      throw userError;
    }
    
    const userLevel = userData?.nivel;
    console.log('🔍 DEBUG - Nível do usuário:', userLevel);
    
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
    
    // Buscar total de jovens com filtros baseados no nível de acesso
    console.log('Buscando total de jovens...');
    let jovensQuery = supabase
      .from('jovens')
      .select('id, usuario_id');
    
    // 🔧 APLICAR FILTROS BASEADOS NO NÍVEL DE ACESSO
    if (userLevel === 'colaborador') {
      // Colaborador: apenas jovens que ele cadastrou
      console.log('🔍 DEBUG - Filtrando jovens para colaborador:', usuarioId);
      jovensQuery = jovensQuery.eq('usuario_id', usuarioId);
    } else if (userLevel === 'lider_estadual_iurd' || userLevel === 'lider_estadual_fju') {
      // Líder estadual: apenas jovens do seu estado
      if (userData?.estado_id) {
        console.log('🔍 DEBUG - Filtrando jovens por estado:', userData.estado_id);
        jovensQuery = jovensQuery.eq('estado_id', userData.estado_id);
      }
    } else if (userLevel === 'lider_bloco_iurd' || userLevel === 'lider_bloco_fju') {
      // Líder de bloco: apenas jovens do seu bloco
      if (userData?.bloco_id) {
        console.log('🔍 DEBUG - Filtrando jovens por bloco:', userData.bloco_id);
        jovensQuery = jovensQuery.eq('bloco_id', userData.bloco_id);
      }
    } else if (userLevel === 'lider_regional_iurd') {
      // Líder regional: apenas jovens da sua região
      if (userData?.regiao_id) {
        console.log('🔍 DEBUG - Filtrando jovens por região:', userData.regiao_id);
        jovensQuery = jovensQuery.eq('regiao_id', userData.regiao_id);
      }
    } else if (userLevel === 'lider_igreja_iurd') {
      // Líder de igreja: apenas jovens da sua igreja
      if (userData?.igreja_id) {
        console.log('🔍 DEBUG - Filtrando jovens por igreja:', userData.igreja_id);
        jovensQuery = jovensQuery.eq('igreja_id', userData.igreja_id);
      }
    }
    // Administrador e líderes nacionais: sem filtros adicionais
    
    const { data: jovensData, error: jovensError } = await jovensQuery;
    
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
export async function loadCondicoesStats(userId = null, userLevel = null, userProfile = null) {
  loading.set(true);
  error.set(null);
  
  try {
    // Buscar jovens com filtro baseado no nível do usuário
    let query = supabase
      .from('jovens')
      .select('condicao, responsabilidade_igreja, ja_obreiro, foi_obreiro, ja_colaborador, foi_colaborador, batizado_es, usuario_id, estado_id, bloco_id, regiao_id, igreja_id');
    
    // Aplicar filtros baseados na hierarquia de níveis de acesso
    if (userLevel === 'administrador') {
      // Administrador: acesso total - sem filtros
      console.log('🔍 DEBUG - Administrador: acesso total sem filtros');
    } else if (userLevel === 'lider_nacional_iurd' || userLevel === 'lider_nacional_fju') {
      // Líderes nacionais: acesso nacional - sem filtros
      console.log('🔍 DEBUG - Líder nacional: acesso nacional sem filtros');
    } else if (userLevel === 'lider_estadual_iurd' || userLevel === 'lider_estadual_fju') {
      // Líderes estaduais: acesso estadual
      if (userProfile?.estado_id) {
        console.log('🔍 DEBUG - Líder estadual: filtrando por estado:', { userId, userLevel, estado_id: userProfile.estado_id });
        query = query.eq('estado_id', userProfile.estado_id);
      } else {
        console.log('⚠️  WARNING - Líder estadual sem estado_id definido');
      }
    } else if (userLevel === 'lider_bloco_iurd' || userLevel === 'lider_bloco_fju') {
      // Líderes de bloco: acesso ao bloco
      if (userProfile?.bloco_id) {
        console.log('🔍 DEBUG - Líder de bloco: filtrando por bloco:', { userId, userLevel, bloco_id: userProfile.bloco_id });
        query = query.eq('bloco_id', userProfile.bloco_id);
      } else {
        console.log('⚠️  WARNING - Líder de bloco sem bloco_id definido');
      }
    } else if (userLevel === 'lider_regional_iurd') {
      // Líder regional: acesso à região
      if (userProfile?.regiao_id) {
        console.log('🔍 DEBUG - Líder regional: filtrando por região:', { userId, userLevel, regiao_id: userProfile.regiao_id });
        query = query.eq('regiao_id', userProfile.regiao_id);
      } else {
        console.log('⚠️  WARNING - Líder regional sem regiao_id definido');
      }
    } else if (userLevel === 'lider_igreja_iurd') {
      // Líder de igreja: acesso à igreja
      if (userProfile?.igreja_id) {
        console.log('🔍 DEBUG - Líder de igreja: filtrando por igreja:', { userId, userLevel, igreja_id: userProfile.igreja_id });
        query = query.eq('igreja_id', userProfile.igreja_id);
      } else {
        console.log('⚠️  WARNING - Líder de igreja sem igreja_id definido');
      }
    } else if (userLevel === 'colaborador' && userId) {
      // Colaborador: acesso aos jovens que ele cadastrou
      console.log('🔍 DEBUG - Colaborador: filtrando por usuário que cadastrou:', { userId, userLevel });
      query = query.eq('usuario_id', userId);
    } else if (userLevel === 'jovem' && userId) {
      // Jovem: acesso apenas aos seus próprios dados
      console.log('🔍 DEBUG - Jovem: filtrando por usuário:', { userId, userLevel });
      query = query.eq('usuario_id', userId);
    } else {
      console.log('🔍 DEBUG - Nível não reconhecido ou sem filtros:', { userId, userLevel });
    }
    
    const { data: jovensData, error: jovensError } = await query;
    
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
