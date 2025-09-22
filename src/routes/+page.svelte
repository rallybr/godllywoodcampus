<script>
  import { onMount } from 'svelte';
  import { user, userProfile } from '$lib/stores/auth';
  import { goto } from '$app/navigation';
  import Button from '$lib/components/ui/Button.svelte';
  import AvaliacoesChart from '$lib/components/charts/AvaliacoesChart.svelte';
  import { estatisticas, loadEstatisticas, condicoesStats, loadCondicoesStats } from '$lib/stores/estatisticas';
  import { supabase } from '$lib/utils/supabase';
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
  
  onMount(async () => {
    if (!$user) {
      goto('/login');
    } else {
      await loadInitialData(); // Carregar edições
      await loadDashboardData();
    }
  });
  
  // Carregar dados reais do dashboard
  async function loadDashboardData() {
    loading = true;
    try {
      const userId = $userProfile?.id;
      const userLevel = $userProfile?.nivel;
      
      // Carregar estatísticas gerais
      await loadEstatisticas(userId, userLevel);
      
      // Carregar estatísticas das condições
      await loadCondicoesStats();
      
      // Carregar atividades recentes
      await loadRecentActivities();
      
      // Carregar últimos cadastros
      await loadUltimosCadastros();
      
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
  
  // Carregar atividades recentes
  async function loadRecentActivities() {
    try {
      // Buscar últimos cadastros de jovens
      const { data: jovensRecentes, error: jovensError } = await supabase
        .from('jovens')
        .select('nome, data_cadastro, edicao_obj:edicoes(nome)')
        .order('data_cadastro', { ascending: false })
        .limit(3);
      
      if (jovensError) throw jovensError;
      
      // Buscar últimas avaliações
      const { data: avaliacoesRecentes, error: avaliacoesError } = await supabase
        .from('avaliacoes')
        .select(`
          criado_em,
          jovem:jovens(nome),
          user:usuarios(nome)
        `)
        .order('criado_em', { ascending: false })
        .limit(2);
      
      if (avaliacoesError) throw avaliacoesError;
      
      // Formatar atividades
      const atividades = [];
      
      // Adicionar cadastros recentes
      jovensRecentes.forEach((jovem, index) => {
        atividades.push({
          id: `cadastro-${index}`,
          type: 'cadastro',
          user: jovem.nome,
          action: `foi cadastrado na ${jovem.edicao_obj?.nome || 'edição'}`,
          time: formatTimeAgo(jovem.data_cadastro),
          avatar: jovem.nome.charAt(0).toUpperCase(),
          color: 'bg-green-100 text-green-600'
        });
      });
      
      // Adicionar avaliações recentes
      avaliacoesRecentes.forEach((avaliacao, index) => {
        atividades.push({
          id: `avaliacao-${index}`,
          type: 'avaliacao',
          user: avaliacao.jovem?.nome || 'Jovem',
          action: `recebeu uma nova avaliação de ${avaliacao.user?.nome || 'Usuário'}`,
          time: formatTimeAgo(avaliacao.criado_em),
          avatar: (avaliacao.jovem?.nome || 'J').charAt(0).toUpperCase(),
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
  async function loadUltimosCadastros() {
    try {
      const { data, error } = await supabase
        .from('jovens')
        .select(`
          nome,
          data_cadastro,
          estado:estados(sigla)
        `)
        .order('data_cadastro', { ascending: false })
        .limit(3);
      
      if (error) throw error;
      
      stats.ultimosCadastros = data.map(jovem => ({
        nome: jovem.nome,
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
      
      // Buscar contagem de jovens por estado (com filtro de edição se selecionada)
      let query = supabase
        .from('jovens')
        .select('estado_id')
        .not('estado_id', 'is', null);
      
      // Aplicar filtro de edição se uma edição específica foi selecionada
      if (edicaoId) {
        query = query.eq('edicao_id', edicaoId);
      }
      
      const { data: jovensData, error: jovensError } = await query;
      
      if (jovensError) throw jovensError;
      
      // Contar jovens por estado
      const contagemPorEstado = {};
      jovensData.forEach(jovem => {
        contagemPorEstado[jovem.estado_id] = (contagemPorEstado[jovem.estado_id] || 0) + 1;
      });
      
      // Processar dados para incluir contagem (incluindo estados com 0 jovens)
      estadosStats = estadosData.map(estado => ({
        id: estado.id,
        nome: estado.nome,
        sigla: estado.sigla,
        bandeira: estado.bandeira,
        totalJovens: contagemPorEstado[estado.id] || 0
      })).sort((a, b) => b.totalJovens - a.totalJovens); // Ordenar do maior para o menor
      
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
  {#if $userProfile?.nivel !== 'jovem'}
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
        {#if $userProfile?.nivel !== 'jovem'}
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
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4.318 6.318a4.5 4.5 0 000 6.364L12 20.364l7.682-7.682a4.5 4.5 0 00-6.364-6.364L12 7.636l-1.318-1.318a4.5 4.5 0 00-6.364 0z" />
            </svg>
          </div>
          <p class="text-xl sm:text-2xl font-bold text-gray-900 group-hover:text-pink-600 transition-colors">{$condicoesStats.batizadoES}</p>
          <p class="text-xs sm:text-sm text-gray-500 group-hover:text-gray-700 transition-colors">Jovem</p>
        </a>
      </div>
    {/if}
    </div>
  {/if}
  
  <!-- Estados dos Jovens -->
  {#if $userProfile?.nivel !== 'jovem'}
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
      <div class="grid grid-cols-3 sm:grid-cols-4 md:grid-cols-5 lg:grid-cols-6 xl:grid-cols-6 gap-2 sm:gap-3">
        {#each estadosStats as estado}
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
  
  <!-- Estatísticas de Avaliações -->
  {#if $userProfile?.nivel !== 'jovem'}
    <AvaliacoesChart jovemId={null} title="ESTATÍSTICAS GERAIS DE AVALIAÇÕES" />
    
    <!-- Quick actions -->
    <div class="fb-card p-6">
      <h3 class="text-lg font-semibold text-gray-900 mb-4">AÇÕES RÁPIDAS</h3>
    <div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-4">
      <Button href="/jovens/cadastrar" variant="primary" class="w-full justify-center">
        <svg class="w-5 h-5 mr-2" fill="none" viewBox="0 0 24 24" stroke="currentColor">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 6v6m0 0v6m0-6h6m-6 0H6" />
        </svg>
        Cadastrar Jovem
      </Button>
      
      <Button href="/avaliacoes" variant="outline" class="w-full justify-center">
        <svg class="w-5 h-5 mr-2" fill="none" viewBox="0 0 24 24" stroke="currentColor">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5H7a2 2 0 00-2 2v10a2 2 0 002 2h8a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2m-3 7h3m-3 4h3m-6-4h.01M9 16h.01" />
        </svg>
        Avaliar Jovens
      </Button>
      
      <Button href="/relatorios" variant="outline" class="w-full justify-center">
        <svg class="w-5 h-5 mr-2" fill="none" viewBox="0 0 24 24" stroke="currentColor">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 19v-6a2 2 0 00-2-2H5a2 2 0 00-2 2v6a2 2 0 002 2h2a2 2 0 002-2zm0 0V9a2 2 0 012-2h2a2 2 0 012 2v10m-6 0a2 2 0 002 2h2a2 2 0 002-2m0 0V5a2 2 0 012-2h2a2 2 0 012 2v14a2 2 0 01-2 2h-2a2 2 0 01-2-2z" />
        </svg>
        Ver Relatórios
      </Button>
    </div>
    </div>
  {/if}
</div>