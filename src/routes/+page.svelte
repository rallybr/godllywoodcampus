<script>
  import { onMount } from 'svelte';
  import { user, userProfile } from '$lib/stores/auth';
  import { getUserLevelName, canCadastrarJovem, canViewAcoesRapidas, canClickEstado } from '$lib/stores/niveis-acesso';
  import { goto } from '$app/navigation';
  import Button from '$lib/components/ui/Button.svelte';
  import AvaliacoesChart from '$lib/components/charts/AvaliacoesChart.svelte';
  import { estatisticas, loadEstatisticas, condicoesStats, loadCondicoesStats } from '$lib/stores/estatisticas';
  import { supabase } from '$lib/utils/supabase';
  import Autocomplete from '$lib/components/ui/Autocomplete.svelte';
  import JovemMiniCard from '$lib/components/jovens/JovemMiniCard.svelte';
  import JovensAssociadosCard from '$lib/components/estatisticas/JovensAssociadosCard.svelte';
  import CondicoesAssociadosCard from '$lib/components/estatisticas/CondicoesAssociadosCard.svelte';
  import { loadInitialData, edicoes } from '$lib/stores/geographic';
  
  let stats = {
    totalJovens: 0,
    avaliacoesPendentes: 0,
    avaliados: 0,
    aprovados: 0,
    ultimosCadastros: []
  };
  
  let recentActivities = [];
  let estadosStats = [];
  let loading = true;
  let edicaoSelecionada = '';
  // Estado para o card de jovens no feed (cópia do /jovens/cards)
  let jovensFeed = [];
  let loadingJovensFeed = true;
  let errorJovensFeed = '';
  let searchTermFeed = '';
  let pageFeed = 1;
  let pageSizeFeed = 24;
  let totalFeed = 0;
  // Filtros e caches para o card de jovens do feed
  let estadosFeed = [];
  let selectedEstadoFeed = '';
  let condicoesFeed = [];
  let selectedCondicaoFeed = '';
  let selectedEdicaoFeed = '';
  let idadeMinFeed = '';
  let idadeMaxFeed = '';
  
  onMount(async () => {
    if (!$user) {
      goto('/login');
    } else {
      await loadInitialData(); // Carregar edições
      
      // Aguardar o userProfile ser carregado antes de carregar os dados
      if (!$userProfile) {
        // Aguardar um pouco para o userProfile ser carregado
        await new Promise(resolve => setTimeout(resolve, 100));
      }
      
      await loadDashboardData();
      await Promise.all([loadEstadosFeed(), loadCondicoesFeed()]);
      await fetchJovensFeed();
    }
  });
  
  // Carregar dados reais do dashboard
  async function loadDashboardData() {
    loading = true;
    try {
      // Aguardar o userProfile ser carregado
      let attempts = 0;
      while (!$userProfile && attempts < 10) {
        await new Promise(resolve => setTimeout(resolve, 100));
        attempts++;
      }
      
      const userId = $userProfile?.id;
      const userLevel = $userProfile?.nivel;
      
      console.log('🔍 DEBUG - loadDashboardData - userProfile:', $userProfile);
      console.log('🔍 DEBUG - loadDashboardData - userId:', userId);
      console.log('🔍 DEBUG - loadDashboardData - userLevel:', userLevel);
      
      // Carregar estatísticas gerais
      await loadEstatisticas(userId, userLevel, $userProfile);
      
      // Carregar estatísticas das condições
      await loadCondicoesStats(userId, userLevel, $userProfile);
      
      // Carregar atividades recentes
      await loadRecentActivities(userId, userLevel);
      
      // Carregar últimos cadastros
      await loadUltimosCadastros(userId, userLevel);
      
      // Carregar estatísticas dos estados
      await loadEstadosStats();
      
      // Atualizar stats locais com dados do store
      stats = {
        totalJovens: $estatisticas.totalJovens || 0,
        avaliacoesPendentes: $estatisticas.pendentes || 0,
        avaliados: $estatisticas.avaliados || 0,
        aprovados: $estatisticas.aprovados || 0,
        ultimosCadastros: []
      };
      
    } catch (err) {
      console.error('Erro ao carregar dados do dashboard:', err);
    } finally {
      loading = false;
    }
  }
  
  // ===== Card de Jovens no Feed (cópia funcional de /jovens/cards) =====
  async function fetchJovensFeed() {
    loadingJovensFeed = true;
    errorJovensFeed = '';
    try {
      const from = (pageFeed - 1) * pageSizeFeed;
      const to = from + pageSizeFeed - 1;

      let query = supabase
        .from('jovens')
        .select(`
          id,
          nome_completo,
          foto,
          idade,
          aprovado,
          estado:estados!estado_id (
            id,
            nome,
            sigla,
            bandeira
          ),
          bloco:blocos!bloco_id (
            id,
            nome
          ),
          regiao:regioes!regiao_id (
            id,
            nome
          ),
          igreja:igrejas!igreja_id (
            id,
            nome
          ),
          edicao:edicoes!edicao_id (
            id,
            nome,
            numero
          )
        `, { count: 'exact' })
        .order('nome_completo', { ascending: true });

      // Aplicar filtros baseados na hierarquia de níveis de acesso
      if ($userProfile?.nivel === 'administrador') {
        // Administrador: acesso total - sem filtros
        console.log('🔍 DEBUG - Administrador: feed sem filtros');
      } else if ($userProfile?.nivel === 'lider_nacional_iurd' || $userProfile?.nivel === 'lider_nacional_fju') {
        // Líderes nacionais: acesso nacional - sem filtros
        console.log('🔍 DEBUG - Líder nacional: feed sem filtros');
      } else if ($userProfile?.nivel === 'lider_estadual_iurd' || $userProfile?.nivel === 'lider_estadual_fju') {
        // Líderes estaduais: acesso estadual OU jovens associados
        if ($userProfile?.estado_id) {
          console.log('🔍 DEBUG - Líder estadual: filtrando feed por estado OU associados:', { nivel: $userProfile.nivel, estado_id: $userProfile.estado_id, userId: $userProfile.id });
          query = query.or(`estado_id.eq.${$userProfile.estado_id},usuario_id.eq.${$userProfile.id}`);
        }
      } else if ($userProfile?.nivel === 'lider_bloco_iurd' || $userProfile?.nivel === 'lider_bloco_fju') {
        // Líderes de bloco: acesso ao bloco OU jovens associados
        if ($userProfile?.bloco_id) {
          console.log('🔍 DEBUG - Líder de bloco: filtrando feed por bloco OU associados:', { nivel: $userProfile.nivel, bloco_id: $userProfile.bloco_id, userId: $userProfile.id });
          query = query.or(`bloco_id.eq.${$userProfile.bloco_id},usuario_id.eq.${$userProfile.id}`);
        }
      } else if ($userProfile?.nivel === 'lider_regional_iurd') {
        // Líder regional: acesso à região OU jovens associados
        if ($userProfile?.regiao_id) {
          console.log('🔍 DEBUG - Líder regional: filtrando feed por região OU associados:', { nivel: $userProfile.nivel, regiao_id: $userProfile.regiao_id, userId: $userProfile.id });
          query = query.or(`regiao_id.eq.${$userProfile.regiao_id},usuario_id.eq.${$userProfile.id}`);
        }
      } else if ($userProfile?.nivel === 'lider_igreja_iurd') {
        // Líder de igreja: acesso à igreja OU jovens associados
        if ($userProfile?.igreja_id) {
          console.log('🔍 DEBUG - Líder de igreja: filtrando feed por igreja OU associados:', { nivel: $userProfile.nivel, igreja_id: $userProfile.igreja_id, userId: $userProfile.id });
          query = query.or(`igreja_id.eq.${$userProfile.igreja_id},usuario_id.eq.${$userProfile.id}`);
        }
      } else if ($userProfile?.nivel === 'colaborador' && $userProfile?.id) {
        // Colaborador: acesso aos jovens que ele cadastrou OU jovens associados
        console.log('🔍 DEBUG - Colaborador: filtrando feed por usuário que cadastrou OU associados:', { nivel: $userProfile.nivel, userId: $userProfile.id });
        query = query.eq('usuario_id', $userProfile.id);
      } else if ($userProfile?.nivel === 'jovem' && $userProfile?.id) {
        // Jovem: acesso apenas aos seus próprios dados
        console.log('🔍 DEBUG - Jovem: filtrando feed por usuário:', { nivel: $userProfile.nivel, userId: $userProfile.id });
        query = query.eq('usuario_id', $userProfile.id);
      } else {
        console.log('🔍 DEBUG - Nível não reconhecido ou sem filtros:', { nivel: $userProfile?.nivel, userId: $userProfile?.id });
      }

      if (searchTermFeed && searchTermFeed.trim().length > 0) {
        query = query.ilike('nome_completo', `%${searchTermFeed.trim()}%`);
      }

      // Filtros adicionais (estado/edição/condição/idade)
      if (selectedEstadoFeed) {
        query = query.eq('estado_id', selectedEstadoFeed);
      }
      if (selectedEdicaoFeed) {
        query = query.eq('edicao_id', selectedEdicaoFeed);
      }
      if (selectedCondicaoFeed) {
        query = query.eq('condicao', selectedCondicaoFeed);
      }
      if (idadeMinFeed !== '' && !Number.isNaN(Number(idadeMinFeed))) {
        query = query.gte('idade', Number(idadeMinFeed));
      }
      if (idadeMaxFeed !== '' && !Number.isNaN(Number(idadeMaxFeed))) {
        query = query.lte('idade', Number(idadeMaxFeed));
      }

      const { data, error: err, count } = await query.range(from, to);
      if (err) throw err;
      
      console.log('🔍 DEBUG - Feed - Dados retornados:', data);
      console.log('🔍 DEBUG - Feed - Total de registros:', count);
      console.log('🔍 DEBUG - Feed - Jovens encontrados:', data?.length);
      
      // Log detalhado de cada jovem no feed
      if (data && data.length > 0) {
        data.forEach((jovem, index) => {
          console.log(`🔍 DEBUG - Feed - Jovem ${index + 1}:`, {
            id: jovem.id,
            nome: jovem.nome_completo,
            usuario_id: jovem.usuario_id,
            estado: jovem.estado
          });
        });
      }
      
      jovensFeed = data || [];
      totalFeed = count || 0;
    } catch (e) {
      errorJovensFeed = e.message || 'Erro ao carregar jovens';
    } finally {
      loadingJovensFeed = false;
    }
  }

  async function loadEstadosFeed() {
    try {
      let query = supabase
        .from('estados')
        .select('id,nome,sigla')
        .order('sigla');
      
      // 🔧 APLICAR FILTROS BASEADOS NO NÍVEL DE ACESSO
      const userLevel = $userProfile?.nivel;
      
      if (userLevel === 'lider_estadual_iurd' || userLevel === 'lider_estadual_fju') {
        // Líder estadual: apenas seu estado
        if ($userProfile?.estado_id) {
          console.log('🔍 DEBUG - Filtrando estados para líder estadual (feed):', $userProfile.estado_id);
          query = query.eq('id', $userProfile.estado_id);
        }
      } else if (userLevel === 'lider_bloco_iurd' || userLevel === 'lider_bloco_fju') {
        // Líder de bloco: apenas estados do seu bloco
        if ($userProfile?.bloco_id) {
          console.log('🔍 DEBUG - Filtrando estados para líder de bloco (feed):', $userProfile.bloco_id);
          // Buscar estados que têm blocos com o bloco_id do usuário
          const { data: blocosData } = await supabase
            .from('blocos')
            .select('estado_id')
            .eq('id', $userProfile.bloco_id);
          
          if (blocosData && blocosData.length > 0) {
            query = query.eq('id', blocosData[0].estado_id);
          }
        }
      } else if (userLevel === 'lider_regional_iurd') {
        // Líder regional: apenas estados da sua região
        if ($userProfile?.regiao_id) {
          console.log('🔍 DEBUG - Filtrando estados para líder regional (feed):', $userProfile.regiao_id);
          // Buscar estados que têm regiões com o regiao_id do usuário
          const { data: regioesData } = await supabase
            .from('regioes')
            .select('estado_id')
            .eq('id', $userProfile.regiao_id);
          
          if (regioesData && regioesData.length > 0) {
            query = query.eq('id', regioesData[0].estado_id);
          }
        }
      } else if (userLevel === 'lider_igreja_iurd') {
        // Líder de igreja: apenas estados da sua igreja
        if ($userProfile?.igreja_id) {
          console.log('🔍 DEBUG - Filtrando estados para líder de igreja (feed):', $userProfile.igreja_id);
          // Buscar estados que têm igrejas com o igreja_id do usuário
          const { data: igrejasData } = await supabase
            .from('igrejas')
            .select('estado_id')
            .eq('id', $userProfile.igreja_id);
          
          if (igrejasData && igrejasData.length > 0) {
            query = query.eq('id', igrejasData[0].estado_id);
          }
        }
      }
      // Administrador e líderes nacionais: sem filtros adicionais
      
      const { data, error } = await query;
      if (error) throw error;
      estadosFeed = data || [];
    } catch (e) {
      console.warn('Falha ao carregar estados (feed):', e?.message || e);
      estadosFeed = [];
    }
  }

  async function loadCondicoesFeed() {
    try {
      let query = supabase
        .from('jovens')
        .select('condicao')
        .not('condicao', 'is', null)
        .neq('condicao', '')
        .order('condicao');
      
      // 🔧 APLICAR FILTROS BASEADOS NO NÍVEL DE ACESSO
      const userLevel = $userProfile?.nivel;
      
      if (userLevel === 'colaborador' && $userProfile?.id) {
        // Colaborador: apenas condições dos jovens que ele cadastrou
        console.log('🔍 DEBUG - Filtrando condições para colaborador (feed):', $userProfile.id);
        query = query.eq('usuario_id', $userProfile.id);
      } else if (userLevel === 'lider_estadual_iurd' || userLevel === 'lider_estadual_fju') {
        // Líder estadual: apenas condições dos jovens do seu estado
        if ($userProfile?.estado_id) {
          console.log('🔍 DEBUG - Filtrando condições para líder estadual (feed):', $userProfile.estado_id);
          query = query.eq('estado_id', $userProfile.estado_id);
        }
      } else if (userLevel === 'lider_bloco_iurd' || userLevel === 'lider_bloco_fju') {
        // Líder de bloco: apenas condições dos jovens do seu bloco
        if ($userProfile?.bloco_id) {
          console.log('🔍 DEBUG - Filtrando condições para líder de bloco (feed):', $userProfile.bloco_id);
          query = query.eq('bloco_id', $userProfile.bloco_id);
        }
      } else if (userLevel === 'lider_regional_iurd') {
        // Líder regional: apenas condições dos jovens da sua região
        if ($userProfile?.regiao_id) {
          console.log('🔍 DEBUG - Filtrando condições para líder regional (feed):', $userProfile.regiao_id);
          query = query.eq('regiao_id', $userProfile.regiao_id);
        }
      } else if (userLevel === 'lider_igreja_iurd') {
        // Líder de igreja: apenas condições dos jovens da sua igreja
        if ($userProfile?.igreja_id) {
          console.log('🔍 DEBUG - Filtrando condições para líder de igreja (feed):', $userProfile.igreja_id);
          query = query.eq('igreja_id', $userProfile.igreja_id);
        }
      }
      // Administrador e líderes nacionais: sem filtros adicionais
      
      const { data, error } = await query;
      if (error) throw error;
      condicoesFeed = Array.from(new Set((data || []).map(r => r.condicao)));
    } catch (e) {
      console.warn('Falha ao carregar condições (feed):', e?.message || e);
      condicoesFeed = [];
    }
  }

  function handleSearchSubmitFeed(e) {
    e?.preventDefault?.();
    pageFeed = 1;
    fetchJovensFeed();
  }

  function prevPageFeed() {
    if (pageFeed > 1) {
      pageFeed -= 1;
      fetchJovensFeed();
    }
  }

  function nextPageFeed() {
    const totalPages = Math.max(1, Math.ceil(totalFeed / pageSizeFeed));
    if (pageFeed < totalPages) {
      pageFeed += 1;
      fetchJovensFeed();
    }
  }

  // Carregar atividades recentes
  async function loadRecentActivities(userId = null, userLevel = null) {
    try {
      // Buscar últimos cadastros de jovens
      let query = supabase
        .from('jovens')
        .select('nome_completo, data_cadastro, edicao_obj:edicoes(nome), usuario_id, estado_id, bloco_id, regiao_id, igreja_id')
        .order('data_cadastro', { ascending: false })
        .limit(3);
      
      // Aplicar filtros baseados na hierarquia de níveis de acesso
      if (userLevel === 'administrador') {
        // Administrador: acesso total - sem filtros
        console.log('🔍 DEBUG - Administrador: atividades recentes sem filtros');
      } else if (userLevel === 'lider_nacional_iurd' || userLevel === 'lider_nacional_fju') {
        // Líderes nacionais: acesso nacional - sem filtros
        console.log('🔍 DEBUG - Líder nacional: atividades recentes sem filtros');
      } else if (userLevel === 'lider_estadual_iurd' || userLevel === 'lider_estadual_fju') {
        // Líderes estaduais: acesso estadual
        if ($userProfile?.estado_id) {
          console.log('🔍 DEBUG - Líder estadual: filtrando atividades por estado:', { userId, userLevel, estado_id: $userProfile.estado_id });
          query = query.eq('estado_id', $userProfile.estado_id);
        }
      } else if (userLevel === 'lider_bloco_iurd' || userLevel === 'lider_bloco_fju') {
        // Líderes de bloco: acesso ao bloco
        if ($userProfile?.bloco_id) {
          console.log('🔍 DEBUG - Líder de bloco: filtrando atividades por bloco:', { userId, userLevel, bloco_id: $userProfile.bloco_id });
          query = query.eq('bloco_id', $userProfile.bloco_id);
        }
      } else if (userLevel === 'lider_regional_iurd') {
        // Líder regional: acesso à região
        if ($userProfile?.regiao_id) {
          console.log('🔍 DEBUG - Líder regional: filtrando atividades por região:', { userId, userLevel, regiao_id: $userProfile.regiao_id });
          query = query.eq('regiao_id', $userProfile.regiao_id);
        }
      } else if (userLevel === 'lider_igreja_iurd') {
        // Líder de igreja: acesso à igreja
        if ($userProfile?.igreja_id) {
          console.log('🔍 DEBUG - Líder de igreja: filtrando atividades por igreja:', { userId, userLevel, igreja_id: $userProfile.igreja_id });
          query = query.eq('igreja_id', $userProfile.igreja_id);
        }
      } else if (userLevel === 'colaborador' && userId) {
        // Colaborador: acesso aos jovens que ele cadastrou
        console.log('🔍 DEBUG - Colaborador: filtrando atividades por usuário que cadastrou:', { userId, userLevel });
        query = query.eq('usuario_id', userId);
      } else if (userLevel === 'jovem' && userId) {
        // Jovem: acesso apenas aos seus próprios dados
        console.log('🔍 DEBUG - Jovem: filtrando atividades por usuário:', { userId, userLevel });
        query = query.eq('usuario_id', userId);
      }
      
      const { data: jovensRecentes, error: jovensError } = await query;
      
      if (jovensError) throw jovensError;
      
      // Buscar últimas avaliações com filtro por escopo do líder
      let avaliacoesQuery = supabase
        .from('avaliacoes')
        .select(`
          criado_em,
          jovem:jovens(id, nome_completo, estado_id, bloco_id, regiao_id, igreja_id, usuario_id),
          user:usuarios(nome)
        `)
        .order('criado_em', { ascending: false })
        .limit(2);

      const nivel = $userProfile?.nivel;
      const isNacional = nivel === 'administrador' || nivel === 'lider_nacional_iurd' || nivel === 'lider_nacional_fju';
      if (!isNacional && nivel) {
        if ((nivel === 'lider_estadual_iurd' || nivel === 'lider_estadual_fju') && $userProfile?.estado_id) {
          avaliacoesQuery = avaliacoesQuery.eq('jovem.estado_id', $userProfile.estado_id);
        } else if ((nivel === 'lider_bloco_iurd' || nivel === 'lider_bloco_fju') && $userProfile?.bloco_id) {
          avaliacoesQuery = avaliacoesQuery.eq('jovem.bloco_id', $userProfile.bloco_id);
        } else if (nivel === 'lider_regional_iurd' && $userProfile?.regiao_id) {
          avaliacoesQuery = avaliacoesQuery.eq('jovem.regiao_id', $userProfile.regiao_id);
        } else if (nivel === 'lider_igreja_iurd' && $userProfile?.igreja_id) {
          avaliacoesQuery = avaliacoesQuery.eq('jovem.igreja_id', $userProfile.igreja_id);
        } else if (nivel === 'colaborador' && $userProfile?.id) {
          // Para colaborador, buscar avaliações que ele fez OU de jovens que ele cadastrou
          // Usar filtro mais simples para evitar erro de sintaxe
          avaliacoesQuery = avaliacoesQuery.eq('user_id', $userProfile.id);
        }
      }

      const { data: avaliacoesRecentes, error: avaliacoesError } = await avaliacoesQuery;
      
      if (avaliacoesError) throw avaliacoesError;
      
      // Formatar atividades
      const atividades = [];
      
      // Adicionar cadastros recentes
      jovensRecentes.forEach((jovem, index) => {
        atividades.push({
          id: `cadastro-${index}`,
          type: 'cadastro',
          user: jovem.nome_completo,
          action: `foi cadastrado na ${jovem.edicao_obj?.nome || 'edição'}`,
          time: formatTimeAgo(jovem.data_cadastro),
          avatar: jovem.nome_completo.charAt(0).toUpperCase(),
          color: 'bg-green-100 text-green-600'
        });
      });
      
      // Adicionar avaliações recentes
      avaliacoesRecentes.forEach((avaliacao, index) => {
        atividades.push({
          id: `avaliacao-${index}`,
          type: 'avaliacao',
          user: avaliacao.jovem?.nome_completo || 'Jovem',
          action: `recebeu uma nova avaliação de ${avaliacao.user?.nome || 'Usuário'}`,
          time: formatTimeAgo(avaliacao.criado_em),
          avatar: (avaliacao.jovem?.nome_completo || 'J').charAt(0).toUpperCase(),
          color: 'bg-blue-100 text-blue-600'
        });
      });
      
      // Ordenar por data e pegar as 4 mais recentes
      recentActivities = atividades
        .sort((a, b) => new Date(b.time) - new Date(a.time))
        .slice(0, 4);
        
    } catch (err) {
      console.error('Erro ao carregar atividades recentes:', err);
      recentActivities = [];
    }
  }
  
  // Carregar últimos cadastros
  async function loadUltimosCadastros(userId = null, userLevel = null) {
    try {
      let query = supabase
        .from('jovens')
        .select(`
          nome_completo,
          data_cadastro,
          estado:estados(sigla),
          usuario_id
        `)
        .order('data_cadastro', { ascending: false })
        .limit(3);
      
      // Se for colaborador, filtrar apenas jovens que ele cadastrou
      if (userLevel === 'colaborador' && userId) {
        console.log('🔍 DEBUG - Filtrando últimos cadastros para colaborador:', { userId, userLevel });
        query = query.eq('usuario_id', userId);
      }
      
      const { data, error } = await query;
      
      if (error) throw error;
      
      stats.ultimosCadastros = data.map(jovem => ({
        nome: jovem.nome_completo,
        estado: jovem.estado?.sigla || 'N/A',
        data: formatDate(jovem.data_cadastro)
      }));
      
    } catch (err) {
      console.error('Erro ao carregar últimos cadastros:', err);
      stats.ultimosCadastros = [];
    }
  }
  
  // Função para formatar tempo relativo
  function formatTimeAgo(dateString) {
    const date = new Date(dateString);
    const now = new Date();
    const diffInHours = Math.floor((now - date) / (1000 * 60 * 60));
    
    if (diffInHours < 1) return 'Agora mesmo';
    if (diffInHours < 24) return `${diffInHours} hora${diffInHours > 1 ? 's' : ''} atrás`;
    
    const diffInDays = Math.floor(diffInHours / 24);
    if (diffInDays < 7) return `${diffInDays} dia${diffInDays > 1 ? 's' : ''} atrás`;
    
    const diffInWeeks = Math.floor(diffInDays / 7);
    return `${diffInWeeks} semana${diffInWeeks > 1 ? 's' : ''} atrás`;
  }
  
  // Função para formatar data
  function formatDate(dateString) {
    if (!dateString) return 'Não informado';
    try {
      return new Date(dateString + 'T00:00:00').toLocaleDateString('pt-BR');
    } catch {
      return dateString;
    }
  }
  
  // Carregar estatísticas dos estados
  async function loadEstadosStats(edicaoId = '') {
    try {
      
      // Buscar todos os estados
      const { data: estadosData, error: estadosError } = await supabase
        .from('estados')
        .select('id, nome, sigla, bandeira')
        .order('nome', { ascending: true });
      
      if (estadosError) throw estadosError;
      
      // Verificar se o usuário tem permissão para ver estatísticas por estado
      const userLevel = getUserLevelName($userProfile);
      
      // Verificar se o usuário tem qualquer papel relacionado a nível
      const isNivelUser = userLevel.includes('Nacional') || 
                          userLevel.includes('Estadual') || 
                          userLevel.includes('Bloco') || 
                          userLevel.includes('Regional') || 
                          userLevel.includes('Igreja') || 
                          userLevel === 'Administrador' || 
                          userLevel === 'Instrutor';
      
      
      // Apenas usuários com papel "Jovem" (que não são de nível) não podem ver estatísticas por estado
      if (userLevel === 'Jovem' && !isNivelUser) {
        estadosStats = [];
        return;
      }
      
      
      // Para usuários de nível, usar função RPC que contorna RLS
      if (isNivelUser) {
        try {
          const { data: rpcData, error: rpcError } = await supabase.rpc('get_jovens_por_estado_count', {
            p_edicao_id: edicaoId && edicaoId !== '' ? edicaoId : null
          });
          
          if (!rpcError && rpcData) {
            // Processar dados do RPC
            const contagemPorEstado = {};
            rpcData.forEach(item => {
              contagemPorEstado[item.estado_id] = item.total;
            });
            
            
            // Processar dados para incluir contagem (incluindo estados com 0 jovens)
            estadosStats = estadosData.map(estado => ({
              id: estado.id,
              nome: estado.nome,
              sigla: estado.sigla,
              bandeira: estado.bandeira,
              totalJovens: contagemPorEstado[estado.id] || 0
            })).sort((a, b) => b.totalJovens - a.totalJovens);
            
            return;
          }
        } catch (rpcErr) {
          // RPC não disponível, usar consulta normal
        }
      }
      
      // Consulta normal (pode ser limitada por RLS)
      let query = supabase
        .from('jovens')
        .select('estado_id, usuario_id')
        .not('estado_id', 'is', null);
      
      // Se for colaborador, filtrar apenas jovens que ele cadastrou
      if ($userProfile?.nivel === 'colaborador' && $userProfile?.id) {
        console.log('🔍 DEBUG - Filtrando estatísticas de estados para colaborador:', { userId: $userProfile.id, userLevel: $userProfile.nivel });
        query = query.eq('usuario_id', $userProfile.id);
      } else {
        console.log('🔍 DEBUG - Não filtrando estatísticas de estados:', { userId: $userProfile?.id, userLevel: $userProfile?.nivel });
      }
      
      // Aplicar filtro de edição se uma edição específica foi selecionada
      if (edicaoId) {
        query = query.eq('edicao_id', edicaoId);
      }
      
      const { data: jovensData, error: jovensError } = await query;
      
      if (jovensError) throw jovensError;
      console.log('🔍 DEBUG - Jovens encontrados para estatísticas de estados:', jovensData?.length);
      console.log('🔍 DEBUG - Primeiros 3 jovens:', jovensData?.slice(0, 3));
      
      // Contar jovens por estado
      const contagemPorEstado = {};
      jovensData.forEach(jovem => {
        contagemPorEstado[jovem.estado_id] = (contagemPorEstado[jovem.estado_id] || 0) + 1;
      });
      console.log('🔍 DEBUG - Contagem por estado:', contagemPorEstado);
      
      // Processar dados para incluir contagem (incluindo estados com 0 jovens)
      estadosStats = estadosData.map(estado => ({
        id: estado.id,
        nome: estado.nome,
        sigla: estado.sigla,
        bandeira: estado.bandeira,
        totalJovens: contagemPorEstado[estado.id] || 0
      })).sort((a, b) => b.totalJovens - a.totalJovens); // Ordenar do maior para o menor
      
      console.log('🔍 DEBUG - EstadosStats final:', estadosStats);
      console.log('🔍 DEBUG - EstadosStats com jovens:', estadosStats.filter(e => e.totalJovens > 0));
      
    } catch (err) {
      console.error('Erro ao carregar estatísticas dos estados:', err);
      estadosStats = [];
    }
  }
  
  // Função para lidar com mudança de edição
  async function handleEdicaoChange() {
    await loadEstadosStats(edicaoSelecionada);
  }
  
  // Reatividade para atualizar stats quando estatisticas mudarem
  $: if ($estatisticas) {
    stats = {
      ...stats,
      totalJovens: $estatisticas.totalJovens,
      avaliacoesPendentes: $estatisticas.pendentes,
      mediaGeral: $estatisticas.mediaGeral,
      crescimento: $estatisticas.crescimento
    };
  }
</script>

<svelte:head>
  <title>Feed - IntelliMen Campus</title>
</svelte:head>

<div class="space-y-6 px-4 sm:px-6">
  <!-- Welcome post -->
  <div class="fb-card p-6">
    <div class="flex items-center space-x-4 mb-4">
      {#if $userProfile?.foto}
        <img
          class="profile-pic profile-pic-lg"
          src={$userProfile.foto}
          alt={$userProfile.nome}
        />
      {:else}
        <div class="profile-pic profile-pic-lg bg-gradient-to-br from-blue-500 to-purple-600 flex items-center justify-center">
          <span class="text-white font-bold text-xl">
            {$userProfile?.nome?.charAt(0) || 'U'}
          </span>
        </div>
      {/if}
      <div class="flex-1">
        <h3 class="font-semibold text-gray-900">{$userProfile?.nome || 'Usuário'}</h3>
        <p class="text-sm text-gray-500">Bem-vindo ao IntelliMen Campus</p>
      </div>
    </div>
    <div class="bg-gray-50 rounded-lg p-4">
      <p class="text-gray-700">
        Evolução dos jovens que estiveram no IntelliMen Campus.
      </p>
    </div>
  </div>
  
  <!-- Stats overview -->
  {#if getUserLevelName($userProfile) !== 'Jovem'}
    <div class="fb-card p-6">
      <h3 class="text-lg font-semibold text-gray-900 mb-4">RESUMO GERAL</h3>
    {#if loading}
      <div class="grid grid-cols-2 sm:grid-cols-4 gap-3 sm:gap-4">
        {#each Array(4) as _}
          <div class="text-center">
            <div class="w-10 h-10 sm:w-12 sm:h-12 bg-gray-200 rounded-full mx-auto mb-2 animate-pulse"></div>
            <div class="h-6 sm:h-8 bg-gray-200 rounded w-12 sm:w-16 mx-auto mb-2 animate-pulse"></div>
            <div class="h-3 sm:h-4 bg-gray-200 rounded w-16 sm:w-20 mx-auto animate-pulse"></div>
          </div>
        {/each}
      </div>
    {:else}
      <div class="grid grid-cols-2 sm:grid-cols-4 gap-3 sm:gap-4">
        {#if getUserLevelName($userProfile) !== 'Jovem'}
          <a href="/jovens/todos" class="text-center group cursor-pointer hover:bg-gray-50 rounded-lg p-3 sm:p-4 transition-colors">
            <div class="w-10 h-10 sm:w-12 sm:h-12 bg-blue-100 rounded-full flex items-center justify-center mx-auto mb-2 group-hover:bg-blue-200 transition-colors">
              <svg class="w-5 h-5 sm:w-6 sm:h-6 text-blue-600" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4.354a4 4 0 110 5.292M15 21H3v-1a6 6 0 0112 0v1zm0 0h6v-1a6 6 0 00-9-5.197m13.5-9a2.5 2.5 0 11-5 0 2.5 2.5 0 015 0z" />
              </svg>
            </div>
            <p class="text-xl sm:text-2xl font-bold text-gray-900 group-hover:text-blue-600 transition-colors">{stats.totalJovens}</p>
            <p class="text-xs sm:text-sm text-gray-500 group-hover:text-gray-700 transition-colors">Jovens</p>
          </a>
          <a href="/jovens/pendentes" class="text-center group cursor-pointer hover:bg-gray-50 rounded-lg p-3 sm:p-4 transition-colors">
            <div class="w-10 h-10 sm:w-12 sm:h-12 bg-yellow-100 rounded-full flex items-center justify-center mx-auto mb-2 group-hover:bg-yellow-200 transition-colors">
              <svg class="w-5 h-5 sm:w-6 sm:h-6 text-yellow-600" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z" />
              </svg>
            </div>
            <p class="text-xl sm:text-2xl font-bold text-gray-900 group-hover:text-yellow-600 transition-colors">{stats.avaliacoesPendentes}</p>
            <p class="text-xs sm:text-sm text-gray-500 group-hover:text-gray-700 transition-colors">Pendentes</p>
          </a>
          <a href="/jovens/avaliados" class="text-center group cursor-pointer hover:bg-gray-50 rounded-lg p-3 sm:p-4 transition-colors">
            <div class="w-10 h-10 sm:w-12 sm:h-12 bg-green-100 rounded-full flex items-center justify-center mx-auto mb-2 group-hover:bg-green-200 transition-colors">
              <svg class="w-5 h-5 sm:w-6 sm:h-6 text-green-600" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 19v-6a2 2 0 00-2-2H5a2 2 0 00-2 2v6a2 2 0 002 2h2a2 2 0 002-2zm0 0V9a2 2 0 012-2h2a2 2 0 012 2v10m-6 0a2 2 0 002 2h2a2 2 0 002-2m0 0V5a2 2 0 012-2h2a2 2 0 012 2v14a2 2 0 01-2 2h-2a2 2 0 01-2-2z" />
              </svg>
            </div>
            <p class="text-xl sm:text-2xl font-bold text-gray-900 group-hover:text-green-600 transition-colors">{stats.avaliados}</p>
            <p class="text-xs sm:text-sm text-gray-500 group-hover:text-gray-700 transition-colors">Avaliados</p>
          </a>
          <a href="/jovens/aprovados" class="text-center group cursor-pointer hover:bg-gray-50 rounded-lg p-3 sm:p-4 transition-colors">
            <div class="w-10 h-10 sm:w-12 sm:h-12 bg-purple-100 rounded-full flex items-center justify-center mx-auto mb-2 group-hover:bg-purple-200 transition-colors">
              <svg class="w-5 h-5 sm:w-6 sm:h-6 text-purple-600" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z" />
              </svg>
            </div>
            <p class="text-xl sm:text-2xl font-bold text-gray-900 group-hover:text-purple-600 transition-colors">{stats.aprovados}</p>
            <p class="text-xs sm:text-sm text-gray-500 group-hover:text-gray-700 transition-colors">Aprovados</p>
          </a>
        {:else}
          <!-- Para usuários jovens, mostrar apenas os números sem links -->
          <div class="text-center">
            <div class="w-10 h-10 sm:w-12 sm:h-12 bg-blue-100 rounded-full flex items-center justify-center mx-auto mb-2">
              <svg class="w-5 h-5 sm:w-6 sm:h-6 text-blue-600" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4.354a4 4 0 110 5.292M15 21H3v-1a6 6 0 0112 0v1zm0 0h6v-1a6 6 0 00-9-5.197m13.5-9a2.5 2.5 0 11-5 0 2.5 2.5 0 015 0z" />
              </svg>
            </div>
            <p class="text-xl sm:text-2xl font-bold text-gray-900">{stats.totalJovens}</p>
            <p class="text-xs sm:text-sm text-gray-500">Jovens</p>
          </div>
          <div class="text-center">
            <div class="w-10 h-10 sm:w-12 sm:h-12 bg-yellow-100 rounded-full flex items-center justify-center mx-auto mb-2">
              <svg class="w-5 h-5 sm:w-6 sm:h-6 text-yellow-600" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z" />
              </svg>
            </div>
            <p class="text-xl sm:text-2xl font-bold text-gray-900">{stats.avaliacoesPendentes}</p>
            <p class="text-xs sm:text-sm text-gray-500">Pendentes</p>
          </div>
          <div class="text-center">
            <div class="w-10 h-10 sm:w-12 sm:h-12 bg-green-100 rounded-full flex items-center justify-center mx-auto mb-2">
              <svg class="w-5 h-5 sm:w-6 sm:h-6 text-green-600" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 19v-6a2 2 0 00-2-2H5a2 2 0 00-2 2v6a2 2 0 002 2h2a2 2 0 002-2zm0 0V9a2 2 0 012-2h2a2 2 0 012 2v10m-6 0a2 2 0 002 2h2a2 2 0 002-2m0 0V5a2 2 0 012-2h2a2 2 0 012 2v14a2 2 0 01-2 2h-2a2 2 0 01-2-2z" />
              </svg>
            </div>
            <p class="text-xl sm:text-2xl font-bold text-gray-900">{stats.avaliados}</p>
            <p class="text-xs sm:text-sm text-gray-500">Avaliados</p>
          </div>
          <div class="text-center">
            <div class="w-10 h-10 sm:w-12 sm:h-12 bg-purple-100 rounded-full flex items-center justify-center mx-auto mb-2">
              <svg class="w-5 h-5 sm:w-6 sm:h-6 text-purple-600" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z" />
              </svg>
            </div>
            <p class="text-xl sm:text-2xl font-bold text-gray-900">{stats.aprovados}</p>
            <p class="text-xs sm:text-sm text-gray-500">Aprovados</p>
          </div>
        {/if}
      </div>
    {/if}
    </div>
  {/if}
  
  <!-- Condições dos Jovens -->
  {#if $userProfile?.nivel !== 'jovem'}
    <div class="fb-card p-6">
      <h3 class="text-lg font-semibold text-gray-900 mb-4">CONDIÇÃO DOS JOVENS</h3>
    {#if loading}
      <div class="grid grid-cols-1 xs:grid-cols-2 lg:grid-cols-3 gap-4">
        {#each Array(6) as _}
          <div class="text-center">
            <div class="w-12 h-12 bg-gray-200 rounded-full mx-auto mb-2 animate-pulse"></div>
            <div class="h-8 bg-gray-200 rounded w-16 mx-auto mb-2 animate-pulse"></div>
            <div class="h-4 bg-gray-200 rounded w-20 mx-auto animate-pulse"></div>
          </div>
        {/each}
      </div>
    {:else}
      <div class="grid grid-cols-2 sm:grid-cols-3 lg:grid-cols-6 gap-3 sm:gap-4">
        <a href="/condicoes?condicao=auxiliar_pastor" class="text-center group cursor-pointer hover:bg-gray-50 rounded-lg p-3 sm:p-4 transition-colors">
          <div class="w-10 h-10 sm:w-12 sm:h-12 bg-purple-100 rounded-full flex items-center justify-center mx-auto mb-2 group-hover:bg-purple-200 transition-colors">
            <svg class="w-5 h-5 sm:w-6 sm:h-6 text-purple-600" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 21V5a2 2 0 00-2-2H7a2 2 0 00-2 2v16m14 0h2m-2 0h-5m-9 0H3m2 0h5M9 7h1m-1 4h1m4-4h1m-1 4h1m-5 10v-5a1 1 0 011-1h2a1 1 0 011 1v5m-4 0h4" />
            </svg>
          </div>
          <p class="text-xl sm:text-2xl font-bold text-gray-900 group-hover:text-purple-600 transition-colors">{$condicoesStats.auxPastor}</p>
          <p class="text-xs sm:text-sm text-gray-500 group-hover:text-gray-700 transition-colors">Aux. de Pastor</p>
        </a>
        <a href="/condicoes?condicao=iburd" class="text-center group cursor-pointer hover:bg-gray-50 rounded-lg p-3 sm:p-4 transition-colors">
          <div class="w-10 h-10 sm:w-12 sm:h-12 bg-blue-100 rounded-full flex items-center justify-center mx-auto mb-2 group-hover:bg-blue-200 transition-colors">
            <svg class="w-5 h-5 sm:w-6 sm:h-6 text-blue-600" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4.354a4 4 0 110 5.292M15 21H3v-1a6 6 0 0112 0v1zm0 0h6v-1a6 6 0 00-9-5.197m13.5-9a2.5 2.5 0 11-5 0 2.5 2.5 0 015 0z" />
            </svg>
          </div>
          <p class="text-xl sm:text-2xl font-bold text-gray-900 group-hover:text-blue-600 transition-colors">{$condicoesStats.iburd}</p>
          <p class="text-xs sm:text-sm text-gray-500 group-hover:text-gray-700 transition-colors">IBURD</p>
        </a>
        <a href="/condicoes?condicao=obreiro" class="text-center group cursor-pointer hover:bg-gray-50 rounded-lg p-3 sm:p-4 transition-colors">
          <div class="w-10 h-10 sm:w-12 sm:h-12 bg-green-100 rounded-full flex items-center justify-center mx-auto mb-2 group-hover:bg-green-200 transition-colors">
            <svg class="w-5 h-5 sm:w-6 sm:h-6 text-green-600" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M21 13.255A23.931 23.931 0 0112 15c-3.183 0-6.22-.62-9-1.745M16 6V4a2 2 0 00-2-2h-4a2 2 0 00-2-2v2m8 0V6a2 2 0 012 2v6a2 2 0 01-2 2H6a2 2 0 01-2-2V8a2 2 0 012-2V6" />
            </svg>
          </div>
          <p class="text-xl sm:text-2xl font-bold text-gray-900 group-hover:text-green-600 transition-colors">{$condicoesStats.obreiro}</p>
          <p class="text-xs sm:text-sm text-gray-500 group-hover:text-gray-700 transition-colors">Obreiro</p>
        </a>
        <a href="/condicoes?condicao=colaborador" class="text-center group cursor-pointer hover:bg-gray-50 rounded-lg p-3 sm:p-4 transition-colors">
          <div class="w-10 h-10 sm:w-12 sm:h-12 bg-orange-100 rounded-full flex items-center justify-center mx-auto mb-2 group-hover:bg-orange-200 transition-colors">
            <svg class="w-5 h-5 sm:w-6 sm:h-6 text-orange-600" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M17 20h5v-2a3 3 0 00-5.356-1.857M17 20H7m10 0v-2c0-.656-.126-1.283-.356-1.857M7 20H2v-2a3 3 0 015.356-1.857M7 20v-2c0-.656.126-1.283.356-1.857m0 0a5.002 5.002 0 019.288 0M15 7a3 3 0 11-6 0 3 3 0 016 0zm6 3a2 2 0 11-4 0 2 2 0 014 0zM7 10a2 2 0 11-4 0 2 2 0 014 0z" />
            </svg>
          </div>
          <p class="text-xl sm:text-2xl font-bold text-gray-900 group-hover:text-orange-600 transition-colors">{$condicoesStats.colaborador}</p>
          <p class="text-xs sm:text-sm text-gray-500 group-hover:text-gray-700 transition-colors">Colaborador</p>
        </a>
        <a href="/condicoes?condicao=cpo" class="text-center group cursor-pointer hover:bg-gray-50 rounded-lg p-3 sm:p-4 transition-colors">
          <div class="w-10 h-10 sm:w-12 sm:h-12 bg-teal-100 rounded-full flex items-center justify-center mx-auto mb-2 group-hover:bg-teal-200 transition-colors">
            <svg class="w-5 h-5 sm:w-6 sm:h-6 text-teal-600" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z" />
            </svg>
          </div>
          <p class="text-xl sm:text-2xl font-bold text-gray-900 group-hover:text-teal-600 transition-colors">{$condicoesStats.cpo}</p>
          <p class="text-xs sm:text-sm text-gray-500 group-hover:text-gray-700 transition-colors">CPO</p>
        </a>
        <a href="/condicoes?condicao=jovem_batizado_es" class="text-center group cursor-pointer hover:bg-gray-50 rounded-lg p-3 sm:p-4 transition-colors">
          <div class="w-10 h-10 sm:w-12 sm:h-12 bg-pink-100 rounded-full flex items-center justify-center mx-auto mb-2 group-hover:bg-pink-200 transition-colors">
            <svg class="w-5 h-5 sm:w-6 sm:h-6 text-pink-600" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M16 7a4 4 0 11-8 0 4 4 0 018 0zM12 14a7 7 0 00-7 7h14a7 7 0 00-7-7z" />
            </svg>
          </div>
          <p class="text-xl sm:text-2xl font-bold text-gray-900 group-hover:text-pink-600 transition-colors">{$condicoesStats.batizadoES}</p>
          <p class="text-xs sm:text-sm text-gray-500 group-hover:text-gray-700 transition-colors">Jovem</p>
        </a>
      </div>
    {/if}
    </div>
  {/if}
  
  <!-- Jovens Associados -->
  <JovensAssociadosCard />
  
  <!-- Condições dos Jovens Associados -->
  <CondicoesAssociadosCard />
  
  <!-- Estados dos Jovens -->
  {#if getUserLevelName($userProfile) !== 'Jovem'}
    <div class="fb-card p-6">
      <div class="flex flex-col sm:flex-row items-start sm:items-center justify-between mb-4">
        <h3 class="text-lg font-semibold text-gray-900 mb-3 sm:mb-0">JOVENS POR ESTADO</h3>
        
        <!-- Filtro por Edição -->
        <div class="flex flex-col sm:flex-row sm:items-center space-y-1 sm:space-y-0 sm:space-x-2">
          <label for="edicao-filter" class="text-xs sm:text-sm font-medium text-gray-700 whitespace-nowrap">
            EDIÇÃO:
          </label>
          <select
            id="edicao-filter"
            bind:value={edicaoSelecionada}
            on:change={handleEdicaoChange}
            class="px-3 py-2 border border-gray-300 rounded-lg text-sm focus:ring-2 focus:ring-blue-500 focus:border-blue-500 bg-white min-w-0"
          >
            <option value="">Todas as edições</option>
            {#each $edicoes as edicao}
              <option value={edicao.id}>{edicao.nome}</option>
            {/each}
          </select>
        </div>
      </div>
    {#if loading}
      <div class="grid grid-cols-1 xs:grid-cols-2 lg:grid-cols-3 gap-4">
        {#each Array(6) as _}
          <div class="text-center">
            <div class="w-12 h-12 bg-gray-200 rounded-full mx-auto mb-2 animate-pulse"></div>
            <div class="h-8 bg-gray-200 rounded w-16 mx-auto mb-2 animate-pulse"></div>
            <div class="h-4 bg-gray-200 rounded w-12 mx-auto animate-pulse"></div>
          </div>
        {/each}
      </div>
    {:else if estadosStats.length > 0}
      <div class="grid grid-cols-2 sm:grid-cols-3 md:grid-cols-5 lg:grid-cols-6 xl:grid-cols-6 gap-2 sm:gap-3">
        {#each estadosStats as estado}
          {#if canClickEstado(estado.id)}
            <a href="/estados/{estado.sigla}" class="group cursor-pointer hover:scale-105 transition-all duration-300">
              <div class="bg-white rounded-t-2xl shadow-md hover:shadow-lg border border-gray-100 p-2 sm:p-3 group-hover:border-blue-200 transition-all duration-300">
                <!-- Bandeira Circular -->
                <div class="w-10 h-10 sm:w-12 sm:h-12 bg-white border border-gray-200 rounded-full flex items-center justify-center mx-auto mb-2 group-hover:border-blue-300 transition-all duration-300 overflow-hidden shadow-sm">
                  {#if estado.bandeira}
                    <img 
                      src={estado.bandeira} 
                      alt={estado.nome}
                      class="w-full h-full object-cover rounded-full"
                    />
                  {:else}
                    <div class="w-full h-full bg-gradient-to-br from-blue-100 to-blue-200 rounded-full flex items-center justify-center">
                      <span class="text-blue-600 font-bold text-xs">{estado.sigla}</span>
                    </div>
                  {/if}
                </div>
                
                <!-- Sigla e Número -->
                <div class="flex items-center justify-between">
                  <div class="inline-flex items-center px-2 py-1 transition-all duration-300">
                    <span class="text-xs font-semibold text-gray-700 group-hover:text-blue-700 transition-colors">
                      {estado.sigla}
                    </span>
                  </div>
                  
                  <div class="text-right">
                    <p class="text-lg sm:text-xl font-bold bg-gradient-to-r from-blue-600 to-purple-600 bg-clip-text text-transparent group-hover:from-blue-700 group-hover:to-purple-700 transition-all duration-300" style="font-weight: bold;">
                      {estado.totalJovens}
                    </p>
                  </div>
                </div>
              </div>
            </a>
          {:else}
            <div class="group cursor-not-allowed opacity-60">
              <div class="bg-white rounded-t-2xl shadow-md border border-gray-100 p-2 sm:p-3">
                <!-- Bandeira Circular -->
                <div class="w-10 h-10 sm:w-12 sm:h-12 bg-white border border-gray-200 rounded-full flex items-center justify-center mx-auto mb-2 overflow-hidden shadow-sm">
                  {#if estado.bandeira}
                    <img 
                      src={estado.bandeira} 
                      alt={estado.nome}
                      class="w-full h-full object-cover rounded-full"
                    />
                  {:else}
                    <div class="w-full h-full bg-gradient-to-br from-gray-100 to-gray-200 rounded-full flex items-center justify-center">
                      <span class="text-gray-600 font-bold text-xs">{estado.sigla}</span>
                    </div>
                  {/if}
                </div>
                
                <!-- Sigla e Número -->
                <div class="flex items-center justify-between">
                  <div class="inline-flex items-center px-2 py-1">
                    <span class="text-xs font-semibold text-gray-500">
                      {estado.sigla}
                    </span>
                  </div>
                  
                  <div class="text-right">
                    <p class="text-lg sm:text-xl font-bold text-gray-500" style="font-weight: bold;">
                      {estado.totalJovens}
                    </p>
                  </div>
                </div>
              </div>
            </div>
          {/if}
        {/each}
      </div>
    {:else}
      <div class="text-center py-8">
        <svg class="w-12 h-12 text-gray-400 mx-auto mb-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M17.657 16.657L13.414 20.9a1.998 1.998 0 01-2.827 0l-4.244-4.243a8 8 0 1111.314 0z" />
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 11a3 3 0 11-6 0 3 3 0 016 0z" />
        </svg>
        <p class="text-gray-500">Nenhum estado com jovens cadastrados</p>
      </div>
    {/if}
    </div>
  {/if}
  
  <!-- Jovens (Cards) no Feed -->
  {#if $userProfile?.nivel !== 'jovem'}
    <div class="fb-card p-6">
      <h3 class="text-lg font-semibold text-gray-900 mb-4">BUSCAR JOVENS POR:</h3>
      <!-- Banner neon-glass (igual ao de /jovens/cards) -->
      <div class="rounded-3xl p-1 bg-gradient-to-br from-[#0c0d11] via-[#12131a] to-[#0a0b0f] mb-6">
        <div class="relative neon-glass rounded-2xl p-4 sm:p-6 overflow-hidden">
          <div class="pointer-events-none absolute inset-0 opacity-60"
               style="background:
                 radial-gradient(1200px 400px at -10% -10%, rgba(59,130,246,0.08), transparent 60%),
                 radial-gradient(800px 300px at 110% 0%, rgba(168,85,247,0.09), transparent 60%),
                 radial-gradient(800px 300px at 50% 120%, rgba(99,102,241,0.08), transparent 60%);"></div>

          <Autocomplete
            placeholder="Pesquisar por nome..."
            bind:value={searchTermFeed}
            on:input={(e) => { searchTermFeed = e.detail.value; if ((searchTermFeed || '').trim().length >= 2) { pageFeed = 1; fetchJovensFeed(); } }}
            on:select={(e) => { searchTermFeed = e.detail.suggestion.nome_completo; pageFeed = 1; fetchJovensFeed(); }}
            on:search={() => handleSearchSubmitFeed()}
          />

          <div class="mt-3 grid grid-cols-1 sm:grid-cols-2 gap-3">
            <div>
              <label for="estadoSelectFeed" class="block text-sm text-blue-100 mb-1">Filtrar por estado</label>
              <select
                id="estadoSelectFeed"
                class="w-full bg-white/10 text-white placeholder-gray-300 border border-white/20 rounded px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-blue-400/70"
                bind:value={selectedEstadoFeed}
                on:change={() => { pageFeed = 1; fetchJovensFeed(); }}
              >
                <option value="">Todos os estados</option>
                {#each estadosFeed as st}
                  <option value={st.id}>{st.sigla} - {st.nome}</option>
                {/each}
              </select>
            </div>
            <div>
              <label for="edicaoSelectFeed" class="block text-sm text-blue-100 mb-1">Filtrar por edição</label>
              <select
                id="edicaoSelectFeed"
                class="w-full bg-white/10 text-white placeholder-gray-300 border border-white/20 rounded px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-fuchsia-400/70"
                bind:value={selectedEdicaoFeed}
                on:change={() => { pageFeed = 1; fetchJovensFeed(); }}
              >
                <option value="">Todas as edições</option>
                {#each $edicoes as ed}
                  <option value={ed.id}>Edição {ed.numero} {ed.ativa ? '(Ativa)' : ''}</option>
                {/each}
              </select>
            </div>
          </div>

          <div class="mt-3 grid grid-cols-1 sm:grid-cols-2 gap-3">
            <div>
              <label for="condicaoSelectFeed" class="block text-sm text-blue-100 mb-1">Filtrar por condição</label>
              <select
                id="condicaoSelectFeed"
                class="w-full bg-white/10 text-white placeholder-gray-300 border border-white/20 rounded px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-indigo-400/70"
                bind:value={selectedCondicaoFeed}
                on:change={() => { pageFeed = 1; fetchJovensFeed(); }}
              >
                <option value="">Todas as condições</option>
                {#each condicoesFeed as c}
                  <option value={c}>{c}</option>
                {/each}
              </select>
            </div>
            <div>
              <label class="block text-sm text-blue-100 mb-1" for="idadeMinFeed">Filtrar por idade</label>
              <div class="flex items-center gap-2">
                <input id="idadeMinFeed" type="number" min="0" placeholder="Mín"
                  class="w-full bg-white/10 text-white placeholder-gray-300 border border-white/20 rounded px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-blue-400/70"
                  bind:value={idadeMinFeed}
                  on:change={() => { pageFeed = 1; fetchJovensFeed(); }} />
                <span class="text-sm text-blue-200">-</span>
                <input id="idadeMaxFeed" type="number" min="0" placeholder="Máx"
                  class="w-full bg-white/10 text-white placeholder-gray-300 border border-white/20 rounded px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-purple-400/70"
                  bind:value={idadeMaxFeed}
                  on:change={() => { pageFeed = 1; fetchJovensFeed(); }} />
              </div>
            </div>
          </div>
        </div>
      </div>

      {#if loadingJovensFeed}
        <div class="flex items-center justify-center py-12">
          <div class="animate-spin rounded-full h-12 w-12 border-b-2 border-blue-600"></div>
        </div>
      {:else if errorJovensFeed}
        <div class="bg-red-50 border border-red-200 rounded-md p-4">
          <p class="text-sm text-red-600">{errorJovensFeed}</p>
        </div>
      {:else if !jovensFeed || jovensFeed.length === 0}
        <div class="bg-white rounded-lg shadow p-8 text-center text-gray-600">Nenhum jovem encontrado</div>
      {:else}
        <div class="grid grid-cols-1 sm:grid-cols-2 md:grid-cols-3 gap-4">
          {#each jovensFeed as jovem (jovem.id)}
            <JovemMiniCard {jovem} on:deleted={() => fetchJovensFeed()} />
          {/each}
        </div>

        <div class="flex items-center justify-center gap-3 mt-6">
          <button on:click={prevPageFeed} disabled={pageFeed <= 1} class="px-3 py-2 border rounded disabled:opacity-50">Anterior</button>
          <span class="text-sm text-gray-600">Página {pageFeed} de {Math.max(1, Math.ceil(totalFeed / pageSizeFeed))}</span>
          <button on:click={nextPageFeed} disabled={pageFeed >= Math.max(1, Math.ceil(totalFeed / pageSizeFeed))} class="px-3 py-2 border rounded disabled:opacity-50">Próxima</button>
        </div>
      {/if}
    </div>
  {/if}

  <!-- Recent activities feed -->
  {#if $userProfile?.nivel !== 'jovem'}
    <div class="fb-card p-6">
      <h3 class="text-lg font-semibold text-gray-900 mb-4">ATIVIDADES RECENTES</h3>
    {#if loading}
      <div class="space-y-4">
        {#each Array(4) as _}
          <div class="flex items-start space-x-3 p-3 rounded-lg animate-pulse">
            <div class="w-10 h-10 bg-gray-200 rounded-full flex-shrink-0"></div>
            <div class="flex-1 min-w-0">
              <div class="h-4 bg-gray-200 rounded w-3/4 mb-2"></div>
              <div class="h-3 bg-gray-200 rounded w-1/2"></div>
            </div>
          </div>
        {/each}
      </div>
    {:else if recentActivities.length > 0}
      <div class="space-y-4">
        {#each recentActivities as activity}
          <div class="flex items-start space-x-3 p-3 rounded-lg hover:bg-gray-50 transition-colors">
            <div class="w-10 h-10 {activity.color} rounded-full flex items-center justify-center flex-shrink-0">
              <span class="text-sm font-semibold">{activity.avatar}</span>
            </div>
            <div class="flex-1 min-w-0">
              <p class="text-sm text-gray-900">
                <span class="font-semibold">{activity.user}</span> {activity.action}
              </p>
              <p class="text-xs text-gray-500 mt-1">{activity.time}</p>
            </div>
            <div class="flex-shrink-0">
              <button class="p-1 rounded-full hover:bg-gray-200 transition-colors">
                <svg class="w-4 h-4 text-gray-400" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 5v.01M12 12v.01M12 19v.01M12 6a1 1 0 110-2 1 1 0 010 2zm0 7a1 1 0 110-2 1 1 0 010 2zm0 7a1 1 0 110-2 1 1 0 010 2z" />
                </svg>
              </button>
            </div>
          </div>
        {/each}
      </div>
    {:else}
      <div class="text-center py-8">
        <svg class="w-12 h-12 text-gray-400 mx-auto mb-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5H7a2 2 0 00-2 2v10a2 2 0 002 2h8a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2m-3 7h3m-3 4h3m-6-4h.01M9 16h.01" />
        </svg>
        <p class="text-gray-500">Nenhuma atividade recente</p>
      </div>
    {/if}
    </div>
  {/if}
  
  <!-- Estatísticas de Avaliações (não mostrar para jovens) -->
  {#if getUserLevelName($userProfile) !== 'Jovem'}
    <AvaliacoesChart jovemId={null} title="ESTATÍSTICAS GERAIS DE AVALIAÇÕES" />
    
    <!-- Quick actions (não mostrar para jovens) -->
    {#if getUserLevelName($userProfile) !== 'Jovem' && canViewAcoesRapidas()}
    <div class="fb-card p-6">
      <h3 class="text-lg font-semibold text-gray-900 mb-4">AÇÕES RÁPIDAS</h3>
    <div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-4">
      {#if canCadastrarJovem()}
      <Button href="/jovens/cadastrar" variant="primary">
        <svg class="w-5 h-5 mr-2" fill="none" viewBox="0 0 24 24" stroke="currentColor">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 6v6m0 0v6m0-6h6m-6 0H6" />
        </svg>
        Cadastrar Jovem
      </Button>
      {/if}
      
      <Button href="/avaliacoes" variant="outline">
        <svg class="w-5 h-5 mr-2" fill="none" viewBox="0 0 24 24" stroke="currentColor">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5H7a2 2 0 00-2 2v10a2 2 0 002 2h8a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2m-3 7h3m-3 4h3m-6-4h.01M9 16h.01" />
        </svg>
        Avaliar Jovens
      </Button>
      
      <Button href="/relatorios" variant="outline">
        <svg class="w-5 h-5 mr-2" fill="none" viewBox="0 0 24 24" stroke="currentColor">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 19v-6a2 2 0 00-2-2H5a2 2 0 00-2 2v6a2 2 0 002 2h2a2 2 0 002-2zm0 0V9a2 2 0 012-2h2a2 2 0 012 2v10m-6 0a2 2 0 002 2h2a2 2 0 002-2m0 0V5a2 2 0 012-2h2a2 2 0 012 2v14a2 2 0 01-2 2h-2a2 2 0 01-2-2z" />
        </svg>
        Ver Relatórios
      </Button>
    </div>
    </div>
    {/if}
  {/if}
</div>