<script>
  import { onMount } from 'svelte';
  import { 
    notificacoes, 
    loading, 
    error,
    loadNotificacoes, 
    marcarComoLida, 
    marcarTodasComoLidas,
    getIconeNotificacao,
    getCorNotificacao,
    formatarDataNotificacao
  } from '$lib/stores/notificacoes';
  import { goto } from '$app/navigation';
  import Card from '$lib/components/ui/Card.svelte';
  import Button from '$lib/components/ui/Button.svelte';
  
  let paginaAtual = 1;
  let carregandoMais = false;
  const itensPorPagina = 20;
  let filtroTipo = '';
  let filtroStatus = 'todas'; // todas | nao_lidas | lidas
  
  onMount(() => {
    loadNotificacoes(itensPorPagina, 0);
  });
  
  async function carregarMais() {
    if (carregandoMais) return;
    
    carregandoMais = true;
    paginaAtual++;
    
    try {
      await loadNotificacoes(itensPorPagina, (paginaAtual - 1) * itensPorPagina);
    } finally {
      carregandoMais = false;
    }
  }
  
  // Lista filtrada em memória
  $: listaFiltrada = ($notificacoes || []).filter(n => {
    if (filtroTipo && n.tipo !== filtroTipo) return false;
    if (filtroStatus === 'nao_lidas' && n.lida) return false;
    if (filtroStatus === 'lidas' && !n.lida) return false;
    return true;
  });
  
  async function handleNotificationClick(notificacao) {
    // Marcar como lida se não estiver lida
    if (!notificacao.lida) {
      await marcarComoLida(notificacao.id);
    }
    
    // Navegar para a URL da ação se existir
    if (notificacao.acao_url) {
      goto(notificacao.acao_url);
    }
  }
  
  async function handleMarcarTodasLidas() {
    await marcarTodasComoLidas();
  }
</script>

<svelte:head>
  <title>Notificações - IntelliMen Campus</title>
</svelte:head>

<div class="max-w-4xl mx-auto py-8">
  <!-- Header -->
  <div class="mb-8">
    <div class="flex items-center justify-between">
      <div>
        <h1 class="text-3xl font-bold text-gray-900">Notificações</h1>
        <p class="text-gray-600 mt-2">Acompanhe todas as suas notificações do sistema</p>
      </div>
      
      <!-- Filtros -->
      <div class="flex items-center space-x-2">
        <select bind:value={filtroTipo} class="border rounded-md px-2 py-1 text-sm">
          <option value="">Todos os tipos</option>
          <option value="avaliacao">Avaliação</option>
          <option value="aprovacao">Aprovação</option>
          <option value="cadastro">Cadastro</option>
          <option value="sistema">Sistema</option>
        </select>
        <select bind:value={filtroStatus} class="border rounded-md px-2 py-1 text-sm">
          <option value="todas">Todas</option>
          <option value="nao_lidas">Não lidas</option>
          <option value="lidas">Lidas</option>
        </select>
        {#if $notificacoes.length > 0}
          <Button on:click={handleMarcarTodasLidas} variant="outline" size="sm">
            Marcar todas como lidas
          </Button>
        {/if}
      </div>
    </div>
  </div>
  
  <!-- Lista de notificações -->
  <Card class="p-0">
    {#if $loading && $notificacoes.length === 0}
      <!-- Loading skeleton -->
      <div class="p-6">
        <div class="space-y-4">
          {#each Array(5) as _}
            <div class="flex items-start space-x-3 animate-pulse">
              <div class="w-10 h-10 bg-gray-200 rounded-full"></div>
              <div class="flex-1 space-y-2">
                <div class="h-4 bg-gray-200 rounded w-3/4"></div>
                <div class="h-3 bg-gray-200 rounded w-1/2"></div>
              </div>
            </div>
          {/each}
        </div>
      </div>
    {:else if $notificacoes.length === 0}
      <!-- Estado vazio -->
      <div class="p-12 text-center">
        <svg class="w-16 h-16 mx-auto mb-4 text-gray-300" fill="none" viewBox="0 0 24 24" stroke="currentColor">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 17h5l-5 5v-5zM4.828 7l2.586 2.586a2 2 0 002.828 0L12.828 7H4.828zM4.828 17l2.586-2.586a2 2 0 012.828 0L12.828 17H4.828z" />
        </svg>
        <h3 class="text-lg font-medium text-gray-900 mb-2">Nenhuma notificação</h3>
        <p class="text-gray-500">Você não possui notificações no momento.</p>
      </div>
    {:else}
      <!-- Lista de notificações -->
      <div class="divide-y divide-gray-200">
        {#each listaFiltrada as notificacao}
          <button
            on:click={() => handleNotificationClick(notificacao)}
            class="w-full px-6 py-4 text-left hover:bg-gray-50 transition-colors {notificacao.lida ? 'bg-white' : 'bg-blue-50'}"
          >
            <div class="flex items-start space-x-4">
              <!-- Ícone -->
              <div class="flex-shrink-0 mt-1">
                <div class="w-10 h-10 rounded-full flex items-center justify-center {getCorNotificacao(notificacao.tipo)}">
                  <svg class="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d={getIconeNotificacao(notificacao.tipo)} />
                  </svg>
                </div>
              </div>
              
              <!-- Conteúdo -->
              <div class="flex-1 min-w-0">
                <div class="flex items-center justify-between">
                  <h3 class="text-sm font-medium text-gray-900 truncate">
                    {notificacao.titulo}
                  </h3>
                  <div class="flex items-center space-x-2">
                    {#if !notificacao.lida}
                      <div class="w-2 h-2 bg-blue-500 rounded-full flex-shrink-0"></div>
                    {/if}
                    <span class="text-xs text-gray-400">
                      {formatarDataNotificacao(notificacao.criado_em)}
                    </span>
                  </div>
                </div>
                <p class="text-sm text-gray-600 mt-1">
                  {notificacao.mensagem}
                </p>
                {#if notificacao.acao_url}
                  <p class="text-xs text-blue-600 mt-2">
                    Clique para ver detalhes →
                  </p>
                {/if}
              </div>
            </div>
          </button>
        {/each}
      </div>
      
      <!-- Botão carregar mais -->
      {#if $notificacoes.length >= itensPorPagina}
        <div class="p-6 border-t border-gray-200">
          <Button
            on:click={carregarMais}
            variant="outline"
            disabled={carregandoMais}
            class="w-full"
          >
            {carregandoMais ? 'Carregando...' : 'Carregar mais notificações'}
          </Button>
        </div>
      {/if}
    {/if}
  </Card>
  
  <!-- Error state -->
  {#if $error}
    <div class="mt-4 p-4 bg-red-50 border border-red-200 rounded-lg">
      <div class="flex">
        <svg class="w-5 h-5 text-red-400 mt-0.5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8v4m0 4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
        </svg>
        <div class="ml-3">
          <h3 class="text-sm font-medium text-red-800">Erro ao carregar notificações</h3>
          <p class="text-sm text-red-700 mt-1">{$error}</p>
        </div>
      </div>
    </div>
  {/if}
</div>