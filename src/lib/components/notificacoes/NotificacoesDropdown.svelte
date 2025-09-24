<script>
  import { onMount, createEventDispatcher } from 'svelte';
  import { goto } from '$app/navigation';
  import { 
    notificacoes, 
    notificacoesNaoLidas, 
    contadorNaoLidas,
    loadNotificacoes, 
    loadNotificacoesNaoLidas,
    marcarComoLida, 
    marcarTodasComoLidas,
    getIconeNotificacao,
    getCorNotificacao,
    formatarDataNotificacao
  } from '$lib/stores/notificacoes';
  
  const dispatch = createEventDispatcher();
  
  let showDropdown = false;
  let loading = false;
  
  onMount(() => {
    loadNotificacoes(10, 0);
    loadNotificacoesNaoLidas();
  });
  
  function toggleDropdown() {
    showDropdown = !showDropdown;
  }
  
  function closeDropdown() {
    showDropdown = false;
  }
  
  async function handleNotificationClick(notificacao) {
    // Marcar como lida se não estiver lida
    if (!notificacao.lida) {
      await marcarComoLida(notificacao.id);
    }
    
    // Navegar para a URL da ação se existir
    if (notificacao.acao_url) {
      goto(notificacao.acao_url);
    }
    
    closeDropdown();
  }
  
  async function handleMarcarTodasLidas() {
    loading = true;
    try {
      await marcarTodasComoLidas();
    } finally {
      loading = false;
    }
  }
  
  // Fechar dropdown ao clicar fora
  function handleClickOutside(event) {
    if (!event.target.closest('.notifications-dropdown')) {
      closeDropdown();
    }
  }
</script>

<svelte:window on:click={handleClickOutside} />

<div class="relative notifications-dropdown">
  <!-- Botão do sino -->
  <button
    on:click={toggleDropdown}
    class="relative p-2 text-gray-600 hover:text-gray-900 hover:bg-gray-100 rounded-lg transition-colors"
    aria-label="Notificações"
  >
    <!-- Ícone sino estilo YouTube -->
    <svg class="w-6 h-6" fill="none" viewBox="0 0 24 24" stroke="currentColor">
      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 17h5l-1.405-1.405A2.032 2.032 0 0118 14.158V11a6.002 6.002 0 00-4-5.659V4a2 2 0 10-4 0v1.341C7.67 6.165 6 8.388 6 11v3.159c0 .538-.214 1.055-.595 1.436L4 17h11z" />
      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13.73 21a2 2 0 01-3.46 0" />
    </svg>
    
    <!-- Badge de contador -->
    {#if $contadorNaoLidas > 0}
      <span class="absolute -top-1 -right-1 bg-red-500 text-white text-xs rounded-full h-6 w-6 flex items-center justify-center font-semibold">
        {$contadorNaoLidas > 99 ? '99+' : $contadorNaoLidas}
      </span>
    {/if}
  </button>
  
  <!-- Dropdown -->
  {#if showDropdown}
    <div class="absolute right-0 mt-2 w-80 bg-white rounded-lg shadow-lg border border-gray-200 z-50 max-h-96 overflow-hidden">
      <!-- Header -->
      <div class="px-4 py-3 border-b border-gray-200 flex items-center justify-between">
        <h3 class="text-lg font-semibold text-gray-900">Notificações</h3>
        {#if $notificacoesNaoLidas.length > 0}
          <button
            on:click={handleMarcarTodasLidas}
            disabled={loading}
            class="text-sm text-blue-600 hover:text-blue-800 font-medium disabled:opacity-50"
          >
            {loading ? 'Marcando...' : 'Marcar todas como lidas'}
          </button>
        {/if}
      </div>
      
      <!-- Lista de notificações -->
      <div class="max-h-80 overflow-y-auto">
        {#if $notificacoes.length === 0}
          <div class="px-4 py-8 text-center text-gray-500">
            <svg class="w-12 h-12 mx-auto mb-3 text-gray-300" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 17h5l-1.405-1.405A2.032 2.032 0 0118 14.158V11a6.002 6.002 0 00-4-5.659V4a2 2 0 10-4 0v1.341C7.67 6.165 6 8.388 6 11v3.159c0 .538-.214 1.055-.595 1.436L4 17h11z" />
            </svg>
            <p>Nenhuma notificação</p>
          </div>
        {:else}
          {#each $notificacoes as notificacao}
            <button
              on:click={() => handleNotificationClick(notificacao)}
              class="w-full px-4 py-3 text-left hover:bg-gray-50 border-b border-gray-100 last:border-b-0 transition-colors {notificacao.lida ? 'bg-white' : 'bg-blue-50'}"
            >
              <div class="flex items-start space-x-3">
                <!-- Ícone -->
                <div class="flex-shrink-0 mt-1">
                  <div class="w-8 h-8 rounded-full flex items-center justify-center {getCorNotificacao(notificacao.tipo)}">
                    <svg class="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d={getIconeNotificacao(notificacao.tipo)} />
                    </svg>
                  </div>
                </div>
                
                <!-- Conteúdo -->
                <div class="flex-1 min-w-0">
                  <div class="flex items-center justify-between">
                    <p class="text-sm font-medium text-gray-900 truncate">
                      {notificacao.titulo}
                    </p>
                    {#if !notificacao.lida}
                      <div class="w-2 h-2 bg-blue-500 rounded-full flex-shrink-0"></div>
                    {/if}
                  </div>
                  <p class="text-sm text-gray-600 mt-1 line-clamp-2">
                    {notificacao.mensagem}
                  </p>
                  <p class="text-xs text-gray-400 mt-1">
                    {formatarDataNotificacao(notificacao.criado_em)}
                  </p>
                </div>
              </div>
            </button>
          {/each}
        {/if}
      </div>
      
      <!-- Footer -->
      {#if $notificacoes.length > 0}
        <div class="px-4 py-3 border-t border-gray-200">
          <button
            on:click={() => {
              closeDropdown();
              goto('/notificacoes');
            }}
            class="w-full text-center text-sm text-blue-600 hover:text-blue-800 font-medium"
          >
            Ver todas as notificações
          </button>
        </div>
      {/if}
    </div>
  {/if}
</div>

<style>
  .line-clamp-2 {
    display: -webkit-box;
    -webkit-line-clamp: 2;
    -webkit-box-orient: vertical;
    overflow: hidden;
  }
</style>