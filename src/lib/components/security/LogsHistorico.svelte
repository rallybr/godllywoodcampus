<script>
  import { onMount } from 'svelte';
  import { 
    loadLogsHistorico, 
    logsHistorico, 
    loading, 
    error, 
    pagination,
    filters,
    aplicarFiltros,
    limparFiltros,
    exportarLogsCSV,
    getAcaoColor
  } from '$lib/stores/logs-historico';
  import Button from '$lib/components/ui/Button.svelte';
  import Card from '$lib/components/ui/Card.svelte';
  import Input from '$lib/components/ui/Input.svelte';
  import Select from '$lib/components/ui/Select.svelte';

  onMount(async () => {
    await loadLogsHistorico();
  });

  function mudarPagina(novaPagina) {
    if (novaPagina >= 1 && novaPagina <= $pagination.totalPages) {
      loadLogsHistorico(novaPagina, $pagination.limit);
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

  function formatarJSON(jsonString) {
    if (!jsonString) return 'N/A';
    try {
      const obj = JSON.parse(jsonString);
      return JSON.stringify(obj, null, 2);
    } catch {
      return jsonString;
    }
  }
</script>

<div class="space-y-6">
  <!-- Header -->
  <div class="flex items-center justify-between">
    <div>
      <h1 class="text-2xl font-bold text-gray-900">Logs de Histórico</h1>
      <p class="text-gray-600">Acompanhe o histórico de mudanças nos dados dos jovens</p>
    </div>
    
    {#if $logsHistorico.length > 0}
      <Button variant="outline" size="sm" on:click={exportarLogsCSV}>
        <svg class="w-4 h-4 mr-2" fill="none" viewBox="0 0 24 24" stroke="currentColor">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 10v6m0 0l-3-3m3 3l3-3m2 8H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z" />
        </svg>
        Exportar CSV
      </Button>
    {/if}
  </div>
  
  <!-- Filtros -->
  <Card>
    <div class="grid grid-cols-1 md:grid-cols-3 gap-4">
      <Input 
        label="ID do Jovem" 
        type="text" 
        bind:value={$filters.jovem_id} 
        placeholder="UUID do jovem" 
      />
      <Input 
        label="ID do Usuário" 
        type="text" 
        bind:value={$filters.user_id} 
        placeholder="UUID do usuário" 
      />
      <Input 
        label="Ação" 
        type="text" 
        bind:value={$filters.acao} 
        placeholder="Tipo de ação" 
      />
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
  
  <!-- Lista de Logs -->
  <Card>
    <div class="flex items-center justify-between mb-6">
      <div>
        <h3 class="text-lg font-semibold text-gray-900">Histórico de Mudanças</h3>
        <p class="text-sm text-gray-600">
          {$pagination.total} registro{$pagination.total !== 1 ? 's' : ''} encontrado{$pagination.total !== 1 ? 's' : ''}
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
    {:else if $logsHistorico.length === 0}
      <div class="text-center py-12">
        <div class="w-16 h-16 bg-gray-100 rounded-full flex items-center justify-center mx-auto mb-4">
          <svg class="w-8 h-8 text-gray-400" fill="none" viewBox="0 0 24 24" stroke="currentColor">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5H7a2 2 0 00-2 2v10a2 2 0 002 2h8a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2m-3 7h3m-3 4h3m-6-4h.01M9 16h.01" />
          </svg>
        </div>
        <h3 class="text-lg font-semibold text-gray-900 mb-2">Nenhum log encontrado</h3>
        <p class="text-gray-600">Não há logs de histórico para os filtros aplicados.</p>
      </div>
    {:else}
      <div class="space-y-4">
        {#each $logsHistorico as log}
          <div class="border border-gray-200 rounded-lg p-4 hover:bg-gray-50 transition-colors">
            <div class="flex items-start justify-between">
              <div class="flex-1">
                <div class="flex items-center space-x-3 mb-2">
                  <span class="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium {getAcaoColor(log.acao)}">
                    {log.acao}
                  </span>
                  <span class="text-sm text-gray-500">
                    {log.jovem?.nome_completo || 'Jovem N/A'}
                  </span>
                  <span class="text-sm text-gray-500">
                    por {log.usuario?.nome || 'Usuário N/A'}
                  </span>
                  <span class="text-sm text-gray-400">{formatarData(log.created_at)}</span>
                </div>
                <p class="text-sm text-gray-900 mb-2">{log.detalhe}</p>
                
                <!-- Dados Anteriores e Novos -->
                {#if log.dados_anteriores || log.dados_novos}
                  <div class="grid grid-cols-1 md:grid-cols-2 gap-4 mt-3">
                    {#if log.dados_anteriores}
                      <div>
                        <h4 class="text-xs font-medium text-gray-700 mb-1">Dados Anteriores:</h4>
                        <pre class="text-xs bg-gray-100 p-2 rounded border max-h-32 overflow-y-auto">{formatarJSON(log.dados_anteriores)}</pre>
                      </div>
                    {/if}
                    {#if log.dados_novos}
                      <div>
                        <h4 class="text-xs font-medium text-gray-700 mb-1">Dados Novos:</h4>
                        <pre class="text-xs bg-gray-100 p-2 rounded border max-h-32 overflow-y-auto">{formatarJSON(log.dados_novos)}</pre>
                      </div>
                    {/if}
                  </div>
                {/if}
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
