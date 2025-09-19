<script>
  import { onMount } from 'svelte';
  import { 
    loadSessoesAtivas, 
    sessoesAtivas, 
    loading, 
    error, 
    pagination,
    filters,
    aplicarFiltros,
    limparFiltros,
    exportarSessoesCSV,
    invalidarSessao,
    invalidarTodasSessoesUsuario,
    limparSessoesExpiradas,
    getSessaoStatus
  } from '$lib/stores/sessoes';
  import Button from '$lib/components/ui/Button.svelte';
  import Card from '$lib/components/ui/Card.svelte';
  import Input from '$lib/components/ui/Input.svelte';
  import Select from '$lib/components/ui/Select.svelte';

  onMount(async () => {
    await loadSessoesAtivas();
  });

  function mudarPagina(novaPagina) {
    if (novaPagina >= 1 && novaPagina <= $pagination.totalPages) {
      loadSessoesAtivas(novaPagina, $pagination.limit);
    }
  }

  function formatarData(data) {
    return new Date(data).toLocaleString('pt-BR', {
      day: '2-digit',
      month: '2-digit',
      year: 'numeric',
      hour: '2-digit',
      minute: '2-digit',
      second: '2-digit'
    });
  }

  async function handleInvalidarSessao(sessaoId) {
    if (confirm('Tem certeza que deseja invalidar esta sessão?')) {
      try {
        await invalidarSessao(sessaoId);
      } catch (err) {
        alert('Erro ao invalidar sessão: ' + err.message);
      }
    }
  }

  async function handleInvalidarTodasSessoes(usuarioId) {
    if (confirm('Tem certeza que deseja invalidar TODAS as sessões deste usuário?')) {
      try {
        await invalidarTodasSessoesUsuario(usuarioId);
      } catch (err) {
        alert('Erro ao invalidar sessões: ' + err.message);
      }
    }
  }

  async function handleLimparExpiradas() {
    if (confirm('Tem certeza que deseja limpar todas as sessões expiradas?')) {
      try {
        await limparSessoesExpiradas();
        alert('Sessões expiradas foram limpas com sucesso!');
      } catch (err) {
        alert('Erro ao limpar sessões: ' + err.message);
      }
    }
  }
</script>

<div class="space-y-6">
  <!-- Header -->
  <div class="flex items-center justify-between">
    <div>
      <h1 class="text-2xl font-bold text-gray-900">Sessões Ativas</h1>
      <p class="text-gray-600">Gerencie as sessões de usuários no sistema</p>
    </div>
    
    <div class="flex space-x-3">
      <Button variant="outline" size="sm" on:click={handleLimparExpiradas}>
        <svg class="w-4 h-4 mr-2" fill="none" viewBox="0 0 24 24" stroke="currentColor">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16" />
        </svg>
        Limpar Expiradas
      </Button>
      
      {#if $sessoesAtivas.length > 0}
        <Button variant="outline" size="sm" on:click={exportarSessoesCSV}>
          <svg class="w-4 h-4 mr-2" fill="none" viewBox="0 0 24 24" stroke="currentColor">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 10v6m0 0l-3-3m3 3l3-3m2 8H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z" />
          </svg>
          Exportar CSV
        </Button>
      {/if}
    </div>
  </div>
  
  <!-- Filtros -->
  <Card>
    <div class="grid grid-cols-1 md:grid-cols-3 gap-4">
      <Input 
        label="ID do Usuário" 
        type="text" 
        bind:value={$filters.usuario_id} 
        placeholder="UUID do usuário" 
      />
      <Input 
        label="Endereço IP" 
        type="text" 
        bind:value={$filters.ip_address} 
        placeholder="Ex: 192.168.1.1" 
      />
      <Select 
        label="Status" 
        bind:value={$filters.ativo}
      >
        <option value="">Todos</option>
        <option value="true">Ativas</option>
        <option value="false">Inativas</option>
      </Select>
    </div>
    <div class="grid grid-cols-1 md:grid-cols-2 gap-4 mt-4">
      <Input 
        label="Data Início" 
        type="datetime-local" 
        bind:value={$filters.data_inicio} 
      />
      <Input 
        label="Data Fim" 
        type="datetime-local" 
        bind:value={$filters.data_fim} 
      />
    </div>
    <div class="flex justify-end space-x-3 mt-4">
      <Button variant="outline" on:click={limparFiltros}>Limpar</Button>
      <Button variant="primary" on:click={aplicarFiltros}>Aplicar Filtros</Button>
    </div>
  </Card>
  
  <!-- Lista de Sessões -->
  <Card>
    <div class="flex items-center justify-between mb-6">
      <div>
        <h3 class="text-lg font-semibold text-gray-900">Sessões de Usuários</h3>
        <p class="text-sm text-gray-600">
          {$pagination.total} sessão{$pagination.total !== 1 ? 'ões' : ''} encontrada{$pagination.total !== 1 ? 's' : ''}
        </p>
      </div>
    </div>
    
    {#if $loading}
      <div class="flex items-center justify-center py-12">
        <div class="animate-spin rounded-full h-12 w-12 border-b-2 border-blue-600"></div>
      </div>
    {:else if $error}
      <div class="bg-red-50 border border-red-200 rounded-lg p-4">
        <div class="flex items-center space-x-2">
          <svg class="w-5 h-5 text-red-500" fill="none" viewBox="0 0 24 24" stroke="currentColor">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8v4m0 4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
          </svg>
          <p class="text-sm text-red-600 font-medium">{$error}</p>
        </div>
      </div>
    {:else if $sessoesAtivas.length === 0}
      <div class="text-center py-12">
        <div class="w-16 h-16 bg-gray-100 rounded-full flex items-center justify-center mx-auto mb-4">
          <svg class="w-8 h-8 text-gray-400" fill="none" viewBox="0 0 24 24" stroke="currentColor">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 15v2m-6 4h12a2 2 0 002-2v-6a2 2 0 00-2-2H6a2 2 0 00-2 2v6a2 2 0 002 2zm10-10V7a4 4 0 00-8 0v4h8z" />
          </svg>
        </div>
        <h3 class="text-lg font-semibold text-gray-900 mb-2">Nenhuma sessão encontrada</h3>
        <p class="text-gray-600">Não há sessões para os filtros aplicados.</p>
      </div>
    {:else}
      <div class="space-y-4">
        {#each $sessoesAtivas as sessao}
          <div class="border border-gray-200 rounded-lg p-4 hover:bg-gray-50 transition-colors">
            <div class="flex items-start justify-between">
              <div class="flex-1">
                <div class="flex items-center space-x-3 mb-2">
                  <span class="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium {getSessaoStatus(sessao).color}">
                    {getSessaoStatus(sessao).text}
                  </span>
                  <span class="text-sm text-gray-500">
                    {sessao.usuario?.nome || 'Usuário N/A'}
                  </span>
                  <span class="text-sm text-gray-500">
                    {sessao.usuario?.email || 'Email N/A'}
                  </span>
                  <span class="text-sm text-gray-400">{formatarData(sessao.criado_em)}</span>
                </div>
                
                <div class="grid grid-cols-1 md:grid-cols-2 gap-4 text-sm text-gray-600">
                  <div>
                    <strong>IP:</strong> {sessao.ip_address}
                  </div>
                  <div>
                    <strong>Expira em:</strong> {formatarData(sessao.expira_em)}
                  </div>
                  <div class="md:col-span-2">
                    <strong>User Agent:</strong> {sessao.user_agent}
                  </div>
                </div>
              </div>
              
              <div class="flex space-x-2 ml-4">
                <Button 
                  variant="outline" 
                  size="sm" 
                  on:click={() => handleInvalidarSessao(sessao.id)}
                  disabled={!sessao.ativo}
                >
                  Invalidar
                </Button>
                <Button 
                  variant="outline" 
                  size="sm" 
                  on:click={() => handleInvalidarTodasSessoes(sessao.usuario_id)}
                >
                  Todas do Usuário
                </Button>
              </div>
            </div>
          </div>
        {/each}
      </div>
      
      <!-- Paginação -->
      {#if $pagination.totalPages > 1}
        <div class="flex items-center justify-between mt-6">
          <div class="text-sm text-gray-700">
            Mostrando {($pagination.page - 1) * $pagination.limit + 1} a {Math.min($pagination.page * $pagination.limit, $pagination.total)} de {$pagination.total} registros
          </div>
          <div class="flex space-x-2">
            <Button 
              variant="outline" 
              size="sm" 
              on:click={() => mudarPagina($pagination.page - 1)} 
              disabled={$pagination.page === 1}
            >
              Anterior
            </Button>
            <span class="px-3 py-2 text-sm text-gray-700">
              Página {$pagination.page} de {$pagination.totalPages}
            </span>
            <Button 
              variant="outline" 
              size="sm" 
              on:click={() => mudarPagina($pagination.page + 1)} 
              disabled={$pagination.page === $pagination.totalPages}
            >
              Próxima
            </Button>
          </div>
        </div>
      {/if}
    {/if}
  </Card>
</div>
