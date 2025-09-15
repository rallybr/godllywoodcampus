<script>
  import { onMount } from 'svelte';
  import { loadNotificacoes, marcarComoLida, marcarTodasComoLidas, deletarNotificacao, getNotificacaoIcon, getNotificacaoColor, formatNotificacaoDate } from '$lib/stores/notificacoes';
  import { user } from '$lib/stores/auth';
  import Button from '$lib/components/ui/Button.svelte';
  import Card from '$lib/components/ui/Card.svelte';
  import { goto } from '$app/navigation';
  
  let notificacoes = [];
  let loading = true;
  let error = '';
  let filtroTipo = '';
  let filtroStatus = '';
  
  onMount(async () => {
    if ($user) {
      await loadData();
    }
  });
  
  async function loadData() {
    loading = true;
    error = '';
    
    try {
      const data = await loadNotificacoes($user.id);
      notificacoes = data || [];
    } catch (err) {
      error = err.message;
    } finally {
      loading = false;
    }
  }
  
  // Função para filtrar notificações
  function getFilteredNotificacoes() {
    return notificacoes.filter(notificacao => {
      // Filtro por tipo
      if (filtroTipo && notificacao.tipo !== filtroTipo) {
        return false;
      }
      
      // Filtro por status
      if (filtroStatus === 'lidas' && !notificacao.lida) return false;
      if (filtroStatus === 'nao_lidas' && notificacao.lida) return false;
      
      return true;
    });
  }
  
  // Função para marcar como lida
  async function handleMarcarComoLida(notificacao) {
    if (!notificacao.lida) {
      await marcarComoLida(notificacao.id);
    }
    
    // Navegar para a URL da ação se existir
    if (notificacao.acao_url) {
      goto(notificacao.acao_url);
    }
  }
  
  // Função para marcar todas como lidas
  async function handleMarcarTodasComoLidas() {
    await marcarTodasComoLidas($user.id);
  }
  
  // Função para deletar notificação
  async function handleDeletar(notificacaoId, event) {
    event.stopPropagation();
    await deletarNotificacao(notificacaoId);
  }
  
  // Função para obter avatar do remetente
  function getAvatar(notificacao) {
    if (notificacao.remetente?.foto) {
      return notificacao.remetente.foto;
    }
    if (notificacao.jovem?.foto) {
      return notificacao.jovem.foto;
    }
    return null;
  }
  
  // Função para obter inicial do nome
  function getInicial(notificacao) {
    if (notificacao.remetente?.nome) {
      return notificacao.remetente.nome.charAt(0);
    }
    if (notificacao.jovem?.nome_completo) {
      return notificacao.jovem.nome_completo.charAt(0);
    }
    return 'S';
  }
  
  // Função para obter nome do remetente
  function getNomeRemetente(notificacao) {
    if (notificacao.remetente?.nome) {
      return notificacao.remetente.nome;
    }
    if (notificacao.jovem?.nome_completo) {
      return notificacao.jovem.nome_completo;
    }
    return 'Sistema';
  }
</script>

<div class="space-y-6">
  <!-- Header -->
  <div class="flex items-center justify-between">
    <div>
      <h1 class="text-2xl font-bold text-gray-900">Notificações</h1>
      <p class="text-gray-600">Acompanhe as atividades do sistema</p>
    </div>
    
    {#if notificacoes.length > 0}
      <Button
        variant="outline"
        size="sm"
        on:click={handleMarcarTodasComoLidas}
      >
        <svg class="w-4 h-4 mr-2" fill="none" viewBox="0 0 24 24" stroke="currentColor">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7" />
        </svg>
        Marcar todas como lidas
      </Button>
    {/if}
  </div>
  
  <!-- Filtros -->
  <Card class="p-4">
    <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
      <select
        bind:value={filtroTipo}
        class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent"
      >
        <option value="">Todos os tipos</option>
        <option value="cadastro">Cadastro</option>
        <option value="avaliacao">Avaliação</option>
        <option value="aprovacao">Aprovação</option>
        <option value="transferencia">Transferência</option>
        <option value="sistema">Sistema</option>
      </select>
      
      <select
        bind:value={filtroStatus}
        class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent"
      >
        <option value="">Todos os status</option>
        <option value="nao_lidas">Não lidas</option>
        <option value="lidas">Lidas</option>
      </select>
    </div>
  </Card>
  
  <!-- Lista de Notificações -->
  <div class="space-y-4">
    {#if loading}
      <div class="flex items-center justify-center py-12">
        <div class="animate-spin rounded-full h-12 w-12 border-b-2 border-blue-600"></div>
      </div>
    {:else if error}
      <div class="bg-red-50 border border-red-200 rounded-lg p-4">
        <div class="flex items-center space-x-2">
          <svg class="w-5 h-5 text-red-500" fill="none" viewBox="0 0 24 24" stroke="currentColor">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8v4m0 4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
          </svg>
          <p class="text-sm text-red-600 font-medium">{error}</p>
        </div>
      </div>
    {:else if getFilteredNotificacoes().length === 0}
      <Card class="p-8">
        <div class="text-center">
          <div class="w-16 h-16 bg-gray-100 rounded-full flex items-center justify-center mx-auto mb-4">
            <svg class="w-8 h-8 text-gray-400" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 17h5l-5 5-5-5h5v-5a7.5 7.5 0 1 0-15 0v5h5l-5 5-5-5h5v-5a7.5 7.5 0 1 0 15 0v5z" />
            </svg>
          </div>
          <h3 class="text-lg font-semibold text-gray-900 mb-2">Nenhuma notificação encontrada</h3>
          <p class="text-gray-600">Você não possui notificações no momento.</p>
        </div>
      </Card>
    {:else}
      <!-- Lista de notificações -->
      <div class="space-y-3">
        {#each getFilteredNotificacoes() as notificacao}
          <Card class="p-4 cursor-pointer hover:bg-gray-50 transition-colors {
            notificacao.lida ? 'opacity-75' : 'bg-blue-50 border-blue-200'
          }" on:click={() => handleMarcarComoLida(notificacao)}>
            <div class="flex items-start space-x-3">
              <!-- Avatar -->
              <div class="flex-shrink-0">
                {#if getAvatar(notificacao)}
                  <img class="w-10 h-10 rounded-full object-cover" src={getAvatar(notificacao)} alt={getNomeRemetente(notificacao)} />
                {:else}
                  <div class="w-10 h-10 bg-gradient-to-br from-blue-500 to-purple-600 rounded-full flex items-center justify-center">
                    <span class="text-white font-bold text-sm">{getInicial(notificacao)}</span>
                  </div>
                {/if}
              </div>
              
              <!-- Conteúdo -->
              <div class="flex-1 min-w-0">
                <div class="flex items-start justify-between">
                  <div class="flex-1">
                    <div class="flex items-center space-x-2 mb-1">
                      <h4 class="text-sm font-medium text-gray-900">{notificacao.titulo}</h4>
                      <span class="inline-flex items-center px-2 py-0.5 rounded-full text-xs font-medium {getNotificacaoColor(notificacao.tipo)}">
                        {notificacao.tipo}
                      </span>
                    </div>
                    
                    <p class="text-sm text-gray-600 mb-2">{notificacao.mensagem}</p>
                    
                    <div class="flex items-center space-x-4 text-xs text-gray-500">
                      <span>{getNomeRemetente(notificacao)}</span>
                      <span>•</span>
                      <span>{formatNotificacaoDate(notificacao.criado_em)}</span>
                    </div>
                  </div>
                  
                  <!-- Ações -->
                  <div class="flex items-center space-x-2">
                    {#if !notificacao.lida}
                      <div class="w-2 h-2 bg-blue-500 rounded-full"></div>
                    {/if}
                    
                    <button
                      on:click={(e) => handleDeletar(notificacao.id, e)}
                      class="p-1 rounded-full hover:bg-gray-200 transition-colors"
                    >
                      <svg class="w-4 h-4 text-gray-400" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16" />
                      </svg>
                    </button>
                  </div>
                </div>
              </div>
            </div>
          </Card>
        {/each}
      </div>
    {/if}
  </div>
</div>
