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

// Store para estatísticas de jovens associados
export const jovensAssociadosStats = writable({
  totalAssociados: 0,
  pendentesAvaliacao: 0,
  avaliados: 0,
  aprovados: 0
});

// Store para condições dos jovens associados
export const condicoesAssociadosStats = writable({
  auxPastor: 0,
  iburd: 0,
  obreiro: 0,
  colaborador: 0,
  cpo: 0,
  batizadoES: 0
});

export const loading = writable(false);
export const error = writable(null);

const ESTATISTICAS_CACHE_TTL_MS = 30000;
let estatisticasInFlight = null;
let estatisticasCache = { key: null, at: 0, data: null };

function getEscopoKey(userId, userLevel, userProfile) {
  return JSON.stringify({
    userId: userId || null,
    userLevel: userLevel || null,
    estado_id: userProfile?.estado_id || null,
    bloco_id: userProfile?.bloco_id || null,
    regiao_id: userProfile?.regiao_id || null,
    igreja_id: userProfile?.igreja_id || null
  });
}

/** Aplica filtros de hierarquia em queries da tabela jovens */
function applyJovensEscopo(query, userId = null, userLevel = null, userProfile = null) {
  if (userLevel === 'administrador' || userLevel === 'lider_nacional_iurd' || userLevel === 'lider_nacional_fju') {
    return query;
  }
  if ((userLevel === 'lider_estadual_iurd' || userLevel === 'lider_estadual_fju') && userProfile?.estado_id) {
    return query.eq('estado_id', userProfile.estado_id);
  }
  if ((userLevel === 'lider_bloco_iurd' || userLevel === 'lider_bloco_fju') && userProfile?.bloco_id) {
    return query.eq('bloco_id', userProfile.bloco_id);
  }
  if (userLevel === 'lider_regional_iurd' && userProfile?.regiao_id) {
    return query.eq('regiao_id', userProfile.regiao_id);
  }
  if (userLevel === 'lider_igreja_iurd' && userProfile?.igreja_id) {
    return query.eq('igreja_id', userProfile.igreja_id);
  }
  if ((userLevel === 'colaborador' || userLevel === 'jovem') && userId) {
    return query.eq('usuario_id', userId);
  }
  return query;
}

async function countJovens(userId, userLevel, userProfile, extraFilter = null) {
  let query = supabase
    .from('jovens')
    .select('id', { count: 'exact', head: true });

  query = applyJovensEscopo(query, userId, userLevel, userProfile);
  if (extraFilter) {
    query = extraFilter(query);
  }

  const { count, error: countError } = await query;
  if (countError) throw countError;
  return count || 0;
}

function buildAvaliacoesQuery(userId, userLevel, userProfile) {
  const baseSelect = 'nota, jovem_id, espirito, caractere, disposicao, user_id';

  if (userLevel === 'colaborador' && userId) {
    return supabase
      .from('avaliacoes')
      .select(baseSelect)
      .eq('user_id', userId);
  }

  if ((userLevel === 'lider_estadual_iurd' || userLevel === 'lider_estadual_fju') && userProfile?.estado_id) {
    return supabase
      .from('avaliacoes')
      .select(`${baseSelect}, jovens!inner(estado_id)`)
      .eq('jovens.estado_id', userProfile.estado_id);
  }

  if ((userLevel === 'lider_bloco_iurd' || userLevel === 'lider_bloco_fju') && userProfile?.bloco_id) {
    return supabase
      .from('avaliacoes')
      .select(`${baseSelect}, jovens!inner(bloco_id)`)
      .eq('jovens.bloco_id', userProfile.bloco_id);
  }

  if (userLevel === 'lider_regional_iurd' && userProfile?.regiao_id) {
    return supabase
      .from('avaliacoes')
      .select(`${baseSelect}, jovens!inner(regiao_id)`)
      .eq('jovens.regiao_id', userProfile.regiao_id);
  }

  if (userLevel === 'lider_igreja_iurd' && userProfile?.igreja_id) {
    return supabase
      .from('avaliacoes')
      .select(`${baseSelect}, jovens!inner(igreja_id)`)
      .eq('jovens.igreja_id', userProfile.igreja_id);
  }

  return supabase.from('avaliacoes').select(baseSelect);
}

/** Fallback caso o join jovens!inner falhe (nome de FK / schema) */
async function fetchAvaliacoesScopedFallback(userId, userLevel, userProfile) {
  const scoped = applyJovensEscopo(
    supabase.from('jovens').select('id'),
    userId,
    userLevel,
    userProfile
  );
  const { data: jovensData, error: jovensError } = await scoped;
  if (jovensError) throw jovensError;

  const ids = (jovensData || []).map((j) => j.id);
  if (ids.length === 0) {
    return { data: [], error: null };
  }

  // PostgREST limita .in() — busca em lotes se necessário
  const chunkSize = 200;
  const all = [];
  for (let i = 0; i < ids.length; i += chunkSize) {
    const chunk = ids.slice(i, i + chunkSize);
    const { data, error } = await supabase
      .from('avaliacoes')
      .select('nota, jovem_id, espirito, caractere, disposicao, user_id')
      .in('jovem_id', chunk);
    if (error) throw error;
    if (data?.length) all.push(...data);
  }
  return { data: all, error: null };
}

function mapQualitativo(valor, mapa, padrao = 1) {
  return mapa[valor] ?? padrao;
}

// Função para carregar estatísticas gerais
export async function loadEstatisticas(userId = null, userLevel = null, userProfile = null) {
  const cacheKey = getEscopoKey(userId, userLevel, userProfile);
  const now = Date.now();

  if (estatisticasCache.key === cacheKey && now - estatisticasCache.at < ESTATISTICAS_CACHE_TTL_MS) {
    estatisticas.set(estatisticasCache.data);
    return estatisticasCache.data;
  }

  if (estatisticasInFlight && estatisticasInFlight.key === cacheKey) {
    return estatisticasInFlight.promise;
  }

  loading.set(true);
  error.set(null);

  const promise = (async () => {
    try {
      const hoje = new Date();
      const mesAtual = new Date(hoje.getFullYear(), hoje.getMonth(), 1);
      const mesAnterior = new Date(hoje.getFullYear(), hoje.getMonth() - 1, 1);
      const mesAtualIso = mesAtual.toISOString();
      const mesAnteriorIso = mesAnterior.toISOString();

      const [
        totalJovens,
        aprovados,
        preAprovados,
        pendentes,
        jovensMesAtual,
        jovensMesAnterior,
        avaliacoesResult
      ] = await Promise.all([
        countJovens(userId, userLevel, userProfile),
        countJovens(userId, userLevel, userProfile, (q) => q.eq('aprovado', 'aprovado')),
        countJovens(userId, userLevel, userProfile, (q) => q.eq('aprovado', 'pre_aprovado')),
        // Mantém a regra atual: null + pre_aprovado
        countJovens(userId, userLevel, userProfile, (q) =>
          q.or('aprovado.is.null,aprovado.eq.pre_aprovado')
        ),
        countJovens(userId, userLevel, userProfile, (q) => q.gte('data_cadastro', mesAtualIso)),
        countJovens(userId, userLevel, userProfile, (q) =>
          q.gte('data_cadastro', mesAnteriorIso).lt('data_cadastro', mesAtualIso)
        ),
        buildAvaliacoesQuery(userId, userLevel, userProfile)
      ]);

      let avaliacoes = [];
      if (avaliacoesResult?.error) {
        console.warn('Fallback de avaliações (join):', avaliacoesResult.error.message);
        const fallback = await fetchAvaliacoesScopedFallback(userId, userLevel, userProfile);
        if (fallback.error) throw fallback.error;
        avaliacoes = fallback.data || [];
      } else {
        avaliacoes = avaliacoesResult?.data || [];
      }
      const jovensAvaliadosIds = new Set(avaliacoes.map((a) => a.jovem_id).filter(Boolean));
      const avaliados = jovensAvaliadosIds.size;
      const totalAvaliacoes = avaliacoes.length;

      const mediaGeral = totalAvaliacoes > 0
        ? avaliacoes.reduce((acc, av) => acc + (av.nota || 0), 0) / totalAvaliacoes
        : 0;

      const mapaEspirito = { excelente: 5, muito_bom: 4, bom: 3, regular: 2, ruim: 1 };
      const mapaCaractere = { excelente: 5, muito_bom: 4, bom: 3, regular: 2, ruim: 1 };
      const mapaDisposicao = {
        muito_disposto: 5,
        disposto: 4,
        neutro: 3,
        pouco_disposto: 2,
        indisposto: 1
      };

      const comEspirito = avaliacoes.filter((av) => av.espirito);
      const mediaEspirito = comEspirito.length > 0
        ? comEspirito.reduce((acc, av) => acc + mapQualitativo(av.espirito, mapaEspirito), 0) / comEspirito.length
        : 0;

      const comCaractere = avaliacoes.filter((av) => av.caractere);
      const mediaCaractere = comCaractere.length > 0
        ? comCaractere.reduce((acc, av) => acc + mapQualitativo(av.caractere, mapaCaractere), 0) / comCaractere.length
        : 0;

      const comDisposicao = avaliacoes.filter((av) => av.disposicao);
      const mediaDisposicao = comDisposicao.length > 0
        ? comDisposicao.reduce((acc, av) => acc + mapQualitativo(av.disposicao, mapaDisposicao), 0) / comDisposicao.length
        : 0;

      const crescimento = jovensMesAnterior > 0
        ? Math.round(((jovensMesAtual - jovensMesAnterior) / jovensMesAnterior) * 100)
        : 0;

      const payload = {
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
      };

      estatisticas.set(payload);
      estatisticasCache = { key: cacheKey, at: Date.now(), data: payload };
      return payload;
    } catch (err) {
      error.set(err.message);
      console.error('Error loading estatísticas:', err);
      return null;
    } finally {
      loading.set(false);
      if (estatisticasInFlight?.key === cacheKey) {
        estatisticasInFlight = null;
      }
    }
  })();

  estatisticasInFlight = { key: cacheKey, promise };
  return promise;
}

// Função para carregar estatísticas do usuário logado
export async function loadEstatisticasUsuario(usuarioId) {
  loading.set(true);
  error.set(null);
  
  try {
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

    // Associações (quando aplicável) + avaliações do usuário em paralelo
    const needsAssociados = [
      'lider_estadual_iurd', 'lider_estadual_fju',
      'lider_bloco_iurd', 'lider_bloco_fju',
      'lider_regional_iurd', 'lider_igreja_iurd'
    ].includes(userLevel);

    const [avaliacoesResult, associadosResult] = await Promise.all([
      supabase
        .from('avaliacoes')
        .select('nota')
        .eq('user_id', usuarioId),
      needsAssociados
        ? supabase
            .from('jovens_usuarios_associacoes')
            .select('jovem_id')
            .eq('usuario_id', usuarioId)
        : Promise.resolve({ data: [], error: null })
    ]);

    if (avaliacoesResult.error) {
      console.error('Erro ao buscar avaliações:', avaliacoesResult.error);
      throw avaliacoesResult.error;
    }

    const avaliacoesUsuario = avaliacoesResult.data || [];
    const totalAvaliacoes = avaliacoesUsuario.length;
    const mediaGeral = totalAvaliacoes > 0
      ? avaliacoesUsuario.reduce((acc, av) => acc + (av.nota || 0), 0) / totalAvaliacoes
      : 0;

    let jovensQuery = supabase
      .from('jovens')
      .select('id', { count: 'exact', head: true });

    const associadosIds = (associadosResult.data || []).map((a) => a.jovem_id).filter(Boolean);

    if (userLevel === 'colaborador') {
      jovensQuery = jovensQuery.eq('usuario_id', usuarioId);
    } else if ((userLevel === 'lider_estadual_iurd' || userLevel === 'lider_estadual_fju') && userData?.estado_id) {
      jovensQuery = associadosIds.length > 0
        ? jovensQuery.or(`estado_id.eq.${userData.estado_id},id.in.(${associadosIds.join(',')})`)
        : jovensQuery.eq('estado_id', userData.estado_id);
    } else if ((userLevel === 'lider_bloco_iurd' || userLevel === 'lider_bloco_fju') && userData?.bloco_id) {
      jovensQuery = associadosIds.length > 0
        ? jovensQuery.or(`bloco_id.eq.${userData.bloco_id},id.in.(${associadosIds.join(',')})`)
        : jovensQuery.eq('bloco_id', userData.bloco_id);
    } else if (userLevel === 'lider_regional_iurd' && userData?.regiao_id) {
      jovensQuery = associadosIds.length > 0
        ? jovensQuery.or(`regiao_id.eq.${userData.regiao_id},id.in.(${associadosIds.join(',')})`)
        : jovensQuery.eq('regiao_id', userData.regiao_id);
    } else if (userLevel === 'lider_igreja_iurd' && userData?.igreja_id) {
      jovensQuery = associadosIds.length > 0
        ? jovensQuery.or(`igreja_id.eq.${userData.igreja_id},id.in.(${associadosIds.join(',')})`)
        : jovensQuery.eq('igreja_id', userData.igreja_id);
    }

    const { count, error: jovensError } = await jovensQuery;
    if (jovensError) {
      console.error('Erro ao buscar jovens:', jovensError);
      throw jovensError;
    }

    return {
      totalJovens: count || 0,
      avaliacoesFeitas: totalAvaliacoes,
      mediaGeral: Math.round(mediaGeral * 10) / 10
    };
    
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
    
    // Pendentes inclui tanto null quanto pre_aprovado (ambos estão pendentes de aprovação final)
    const pendentes = $filteredJovens.filter(j => {
      const aprovado = j.aprovado;
      return aprovado === null || 
             aprovado === 'null' ||
             aprovado === undefined ||
             aprovado === 'pre_aprovado';
    }).length;
    
    return {
      total,
      aprovados,
      preAprovados,
      pendentes
    };
  }
);

async function countCondicao(userId, userLevel, userProfile, condicao) {
  return countJovens(userId, userLevel, userProfile, (q) => q.eq('condicao', condicao));
}

// Função para carregar estatísticas das condições
export async function loadCondicoesStats(userId = null, userLevel = null, userProfile = null) {
  loading.set(true);
  error.set(null);
  
  try {
    // Contagens no banco pela condição principal (caminho prioritário do formulário)
    const [auxPastor, iburd, obreiro, colaborador, cpo, batizadoES, semCondicaoResult] = await Promise.all([
      countCondicao(userId, userLevel, userProfile, 'auxiliar_pastor'),
      countCondicao(userId, userLevel, userProfile, 'iburd'),
      countCondicao(userId, userLevel, userProfile, 'obreiro'),
      countCondicao(userId, userLevel, userProfile, 'colaborador'),
      countCondicao(userId, userLevel, userProfile, 'cpo'),
      countCondicao(userId, userLevel, userProfile, 'jovem_batizado_es'),
      // Fallback legado: só baixa quem não tem condição preenchida
      applyJovensEscopo(
        supabase
          .from('jovens')
          .select('condicao, responsabilidade_igreja, ja_obreiro, foi_obreiro, ja_colaborador, foi_colaborador')
          .or('condicao.is.null,condicao.eq.'),
        userId,
        userLevel,
        userProfile
      )
    ]);

    const stats = {
      auxPastor,
      iburd,
      obreiro,
      colaborador,
      cpo,
      batizadoES
    };

    if (semCondicaoResult.error) throw semCondicaoResult.error;
    const fallbackStats = calcularCondicoes(semCondicaoResult.data || []);
    stats.auxPastor += fallbackStats.auxPastor;
    stats.iburd += fallbackStats.iburd;
    stats.obreiro += fallbackStats.obreiro;
    stats.colaborador += fallbackStats.colaborador;
    stats.cpo += fallbackStats.cpo;
    stats.batizadoES += fallbackStats.batizadoES;

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
      }
    }
  });
  
  return stats;
}

// Função para carregar estatísticas de jovens associados
export async function loadEstatisticasJovensAssociados(usuarioId) {
  loading.set(true);
  error.set(null);
  
  try {
    console.log('🔍 DEBUG - Carregando estatísticas de jovens associados para usuário:', usuarioId);
    
    const { data: associacoes, error: associacoesError } = await supabase
      .from('jovens_usuarios_associacoes')
      .select('jovem_id')
      .eq('usuario_id', usuarioId);

    if (associacoesError) throw associacoesError;
    
    let jovensAssociados = [];
    if (associacoes?.length > 0) {
      const jovensIds = associacoes.map(a => a.jovem_id);
      const { data: jovensData, error: jovensError } = await supabase
        .from('jovens')
        .select(`
          id,
          aprovado
        `)
        .in('id', jovensIds);
      
      if (jovensError) throw jovensError;
      jovensAssociados = jovensData || [];
    }
    
    console.log('🔍 DEBUG - Jovens associados encontrados:', jovensAssociados?.length || 0);
    
    // Calcular estatísticas
    const stats = {
      totalAssociados: jovensAssociados?.length || 0,
      pendentesAvaliacao: 0,
      avaliados: 0,
      aprovados: 0
    };
    
    // Buscar avaliações para cada jovem associado
    if (jovensAssociados && jovensAssociados.length > 0) {
      const jovensIds = jovensAssociados.map(j => j.id);
      
      const { data: avaliacoes, error: avaliacoesError } = await supabase
        .from('avaliacoes')
        .select('jovem_id')
        .in('jovem_id', jovensIds);
      
      if (avaliacoesError) {
        console.warn('Erro ao buscar avaliações:', avaliacoesError);
      }
      
      // Criar mapa de jovens com avaliações
      const jovensComAvaliacao = new Set(avaliacoes?.map(a => a.jovem_id) || []);
      
      // Processar cada jovem associado
      jovensAssociados.forEach(jovem => {
        const temAvaliacoes = jovensComAvaliacao.has(jovem.id);
        
        if (temAvaliacoes) {
          stats.avaliados++;
          
          // Verificar se está aprovado
          if (jovem.aprovado === 'aprovado') {
            stats.aprovados++;
          }
        } else {
          // Sem avaliações = pendente
          stats.pendentesAvaliacao++;
        }
      });
    }
    
    console.log('🔍 DEBUG - Estatísticas de jovens associados:', stats);
    
    // Atualizar o store
    jovensAssociadosStats.set(stats);
    
    return stats;
    
  } catch (err) {
    console.error('Erro ao carregar estatísticas de jovens associados:', err);
    error.set(err.message || 'Erro ao carregar estatísticas de jovens associados');
    throw err;
  } finally {
    loading.set(false);
  }
}

// Função para carregar condições dos jovens associados
export async function loadCondicoesAssociadosStats(usuarioId) {
  loading.set(true);
  error.set(null);
  
  try {
    console.log('🔍 DEBUG - Carregando condições dos jovens associados para usuário:', usuarioId);
    
    const { data: associacoes, error: associacoesError } = await supabase
      .from('jovens_usuarios_associacoes')
      .select('jovem_id')
      .eq('usuario_id', usuarioId);

    if (associacoesError) throw associacoesError;
    
    let jovensAssociados = [];
    if (associacoes?.length > 0) {
      const jovensIds = associacoes.map(a => a.jovem_id);
      const { data: jovensData, error: jovensError } = await supabase
        .from('jovens')
        .select(`
          id,
          condicao,
          responsabilidade_igreja,
          ja_obreiro,
          foi_obreiro,
          ja_colaborador,
          foi_colaborador,
          batizado_es
        `)
        .in('id', jovensIds);
      
      if (jovensError) throw jovensError;
      jovensAssociados = jovensData || [];
    }
    
    console.log('🔍 DEBUG - Jovens associados encontrados para condições:', jovensAssociados?.length || 0);
    
    const stats = calcularCondicoes(jovensAssociados);
    
    console.log('🔍 DEBUG - Condições dos jovens associados:', stats);
    
    // Atualizar o store
    condicoesAssociadosStats.set(stats);
    
    return stats;
    
  } catch (err) {
    console.error('Erro ao carregar condições dos jovens associados:', err);
    error.set(err.message || 'Erro ao carregar condições dos jovens associados');
    throw err;
  } finally {
    loading.set(false);
  }
}

// Função para buscar usuários associados a um jovem
export async function loadUsuariosAssociadosJovem(jovemId) {
  loading.set(true);
  error.set(null);
  
  try {
    console.log('🔍 DEBUG - Carregando usuários associados ao jovem:', jovemId);
    
    // Buscar usuários associados ao jovem na tabela associativa
    const { data: associacoes, error: associacoesError } = await supabase
      .from('jovens_usuarios_associacoes')
      .select(`
        usuario_id,
        usuario:usuarios!jovens_usuarios_associacoes_usuario_id_fkey(
          id,
          nome,
          email,
          nivel,
          estado:estados(nome, sigla),
          bloco:blocos(nome),
          regiao:regioes(nome),
          igreja:igrejas(nome)
        )
      `)
      .eq('jovem_id', jovemId);
    
    if (associacoesError) {
      console.error('Erro ao buscar associações do jovem:', associacoesError);
      throw associacoesError;
    }
    
    console.log('🔍 DEBUG - Associações encontradas:', associacoes?.length || 0);
    
    return associacoes || [];
    
  } catch (err) {
    console.error('Erro ao carregar usuários associados ao jovem:', err);
    error.set(err.message || 'Erro ao carregar usuários associados ao jovem');
    throw err;
  } finally {
    loading.set(false);
  }
}

// Função para desassociar jovem de usuário
export async function desassociarJovemUsuario(jovemId, usuarioId) {
  loading.set(true);
  error.set(null);
  
  try {
    console.log('🔍 DEBUG - Desassociando jovem:', jovemId, 'do usuário:', usuarioId);
    
    // Remover a linha de associação
    const { error: updateError } = await supabase
      .from('jovens_usuarios_associacoes')
      .delete()
      .eq('jovem_id', jovemId)
      .eq('usuario_id', usuarioId);
    
    if (updateError) {
      console.error('Erro ao desassociar jovem:', updateError);
      throw updateError;
    }
    
    console.log('🔍 DEBUG - Jovem desassociado com sucesso');
    
    return true;
    
  } catch (err) {
    console.error('Erro ao desassociar jovem do usuário:', err);
    error.set(err.message || 'Erro ao desassociar jovem do usuário');
    throw err;
  } finally {
    loading.set(false);
  }
}
