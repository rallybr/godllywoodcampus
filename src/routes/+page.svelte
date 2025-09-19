<script>
  import { onMount } from 'svelte';
  import { user, userProfile } from '$lib/stores/auth';
  import { goto } from '$app/navigation';
  import Button from '$lib/components/ui/Button.svelte';
  import AvaliacoesChart from '$lib/components/charts/AvaliacoesChart.svelte';
  import { estatisticas, loadEstatisticas } from '$lib/stores/estatisticas';
  import { supabase } from '$lib/utils/supabase';
  
  let stats = {
    totalJovens: 0,
    avaliacoesPendentes: 0,
    mediaGeral: 0,
    crescimento: 0,
    ultimosCadastros: []
  };
  
  let recentActivities = [];
  let loading = true;
  
  onMount(async () => {
    if (!$user) {
      goto('/login');
    } else {
      await loadDashboardData();
    }
  });
  
  // Carregar dados reais do dashboard
  async function loadDashboardData() {
    loading = true;
    try {
      // Carregar estatísticas gerais
      await loadEstatisticas();
      
      // Carregar atividades recentes
      await loadRecentActivities();
      
      // Carregar últimos cadastros
      await loadUltimosCadastros();
      
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
    const date = new Date(dateString);
    return date.toLocaleDateString('pt-BR');
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
        Acompanhe o desenvolvimento dos jovens e gerencie as avaliações do acampamento IntelliMen Campus.
      </p>
    </div>
  </div>
  
  <!-- Stats overview -->
  <div class="fb-card p-6">
    <h3 class="text-lg font-semibold text-gray-900 mb-4">Resumo Geral</h3>
    {#if loading}
      <div class="grid grid-cols-1 xs:grid-cols-2 lg:grid-cols-4 gap-4">
        {#each Array(4) as _}
          <div class="text-center">
            <div class="w-12 h-12 bg-gray-200 rounded-full mx-auto mb-2 animate-pulse"></div>
            <div class="h-8 bg-gray-200 rounded w-16 mx-auto mb-2 animate-pulse"></div>
            <div class="h-4 bg-gray-200 rounded w-20 mx-auto animate-pulse"></div>
          </div>
        {/each}
      </div>
    {:else}
      <div class="grid grid-cols-1 xs:grid-cols-2 lg:grid-cols-4 gap-4">
        <div class="text-center">
          <div class="w-12 h-12 bg-blue-100 rounded-full flex items-center justify-center mx-auto mb-2">
            <svg class="w-6 h-6 text-blue-600" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4.354a4 4 0 110 5.292M15 21H3v-1a6 6 0 0112 0v1zm0 0h6v-1a6 6 0 00-9-5.197m13.5-9a2.5 2.5 0 11-5 0 2.5 2.5 0 015 0z" />
            </svg>
          </div>
          <p class="text-2xl font-bold text-gray-900">{stats.totalJovens}</p>
          <p class="text-sm text-gray-500">Jovens</p>
        </div>
        <div class="text-center">
          <div class="w-12 h-12 bg-yellow-100 rounded-full flex items-center justify-center mx-auto mb-2">
            <svg class="w-6 h-6 text-yellow-600" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z" />
            </svg>
          </div>
          <p class="text-2xl font-bold text-gray-900">{stats.avaliacoesPendentes}</p>
          <p class="text-sm text-gray-500">Pendentes</p>
        </div>
        <div class="text-center">
          <div class="w-12 h-12 bg-green-100 rounded-full flex items-center justify-center mx-auto mb-2">
            <svg class="w-6 h-6 text-green-600" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 19v-6a2 2 0 00-2-2H5a2 2 0 00-2 2v6a2 2 0 002 2h2a2 2 0 002-2zm0 0V9a2 2 0 012-2h2a2 2 0 012 2v10m-6 0a2 2 0 002 2h2a2 2 0 002-2m0 0V5a2 2 0 012-2h2a2 2 0 012 2v14a2 2 0 01-2 2h-2a2 2 0 01-2-2z" />
            </svg>
          </div>
          <p class="text-2xl font-bold text-gray-900">{stats.mediaGeral}</p>
          <p class="text-sm text-gray-500">Média</p>
        </div>
        <div class="text-center">
          <div class="w-12 h-12 bg-purple-100 rounded-full flex items-center justify-center mx-auto mb-2">
            <svg class="w-6 h-6 text-purple-600" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 7h8m0 0v8m0-8l-8 8-4-4-6 6" />
            </svg>
          </div>
          <p class="text-2xl font-bold text-gray-900">{stats.crescimento > 0 ? '+' : ''}{stats.crescimento}%</p>
          <p class="text-sm text-gray-500">Crescimento</p>
        </div>
      </div>
    {/if}
  </div>
  
  <!-- Recent activities feed -->
  <div class="fb-card p-6">
    <h3 class="text-lg font-semibold text-gray-900 mb-4">Atividades Recentes</h3>
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
  
  <!-- Estatísticas de Avaliações -->
  <AvaliacoesChart jovemId={null} title="Estatísticas Gerais de Avaliações" />
  
  <!-- Quick actions -->
  <div class="fb-card p-6">
    <h3 class="text-lg font-semibold text-gray-900 mb-4">Ações Rápidas</h3>
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
</div>