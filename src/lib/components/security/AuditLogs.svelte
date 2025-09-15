<script>
  import { onMount } from 'svelte';
  import { supabase } from '$lib/utils/supabase';
  import Button from '$lib/components/ui/Button.svelte';
  import Card from '$lib/components/ui/Card.svelte';
  import Input from '$lib/components/ui/Input.svelte';
  import Select from '$lib/components/ui/Select.svelte';
  
  let logs = [];
  let loading = true;
  let error = '';
  let totalLogs = 0;
  let paginaAtual = 1;
  let registrosPorPagina = 50;
  
  // Filtros
  let filtros = {
    usuario_id: '',
    acao: '',
    data_inicio: '',
    data_fim: '',
    ip_address: ''
  };
  
  onMount(async () => {
    await loadLogs();
  });
  
  // Função para carregar logs
  async function loadLogs() {
    loading = true;
    error = '';
    
    try {
      let query = supabase
        .from('logs_auditoria')
        .select(`
          *,
          usuario:usuarios!logs_auditoria_user_id_fkey(nome, email)
        `, { count: 'exact' });
      
      // Aplicar filtros
      if (filtros.usuario_id) {
        query = query.eq('usuario_id', filtros.usuario_id);
      }
      if (filtros.acao) {
        query = query.ilike('acao', `%${filtros.acao}%`);
      }
      if (filtros.data_inicio) {
        query = query.gte('criado_em', filtros.data_inicio);
      }
      if (filtros.data_fim) {
        query = query.lte('criado_em', filtros.data_fim);
      }
      if (filtros.ip_address) {
        query = query.ilike('ip_address', `%${filtros.ip_address}%`);
      }
      
      // Ordenar e paginar
      query = query
        .order('criado_em', { ascending: false })
        .range(
          (paginaAtual - 1) * registrosPorPagina,
          paginaAtual * registrosPorPagina - 1
        );
      
      const { data, error: fetchError, count } = await query;
      
      if (fetchError) throw fetchError;
      
      logs = data || [];
      totalLogs = count || 0;
    } catch (err) {
      error = err.message;
    } finally {
      loading = false;
    }
  }
  
  // Função para aplicar filtros
  function aplicarFiltros() {
    paginaAtual = 1;
    loadLogs();
  }
  
  // Função para limpar filtros
  function limparFiltros() {
    filtros = {
      usuario_id: '',
      acao: '',
      data_inicio: '',
      data_fim: '',
      ip_address: ''
    };
    paginaAtual = 1;
    loadLogs();
  }
  
  // Função para obter cor da ação
  function getAcaoColor(acao) {
    const colors = {
      'cadastro': 'text-green-600 bg-green-100',
      'edicao': 'text-blue-600 bg-blue-100',
      'exclusao': 'text-red-600 bg-red-100',
      'avaliacao': 'text-purple-600 bg-purple-100',
      'aprovacao': 'text-yellow-600 bg-yellow-100',
      'transferencia': 'text-orange-600 bg-orange-100',
      'login': 'text-gray-600 bg-gray-100',
      'logout': 'text-gray-600 bg-gray-100'
    };
    
    return colors[acao] || 'text-gray-600 bg-gray-100';
  }
  
  // Função para formatar data
  function formatDate(dateString) {
    return new Date(dateString).toLocaleDateString('pt-BR', {
      day: '2-digit',
      month: '2-digit',
      year: 'numeric',
      hour: '2-digit',
      minute: '2-digit',
      second: '2-digit'
    });
  }
  
  // Função para obter dados paginados
  function getDadosPaginados() {
    return logs;
  }
  
  // Função para obter total de páginas
  function getTotalPaginas() {
    return Math.ceil(totalLogs / registrosPorPagina);
  }
  
  // Função para mudar página
  function mudarPagina(novaPagina) {
    if (novaPagina >= 1 && novaPagina <= getTotalPaginas()) {
      paginaAtual = novaPagina;
      loadLogs();
    }
  }
  
  // Função para exportar logs
  function exportarLogs() {
    const csv = [
      'Data,Usuário,Ação,Detalhe,IP,User Agent',
      ...logs.map(log => [
        formatDate(log.criado_em),
        log.usuario?.nome || 'N/A',
        log.acao,
        log.detalhe,
        log.ip_address,
        log.user_agent
      ].join(','))
    ].join('\n');
    
    const blob = new Blob([csv], { type: 'text/csv;charset=utf-8;' });
    const link = document.createElement('a');
    const url = URL.createObjectURL(blob);
    link.setAttribute('href', url);
    link.setAttribute('download', `audit_logs_${new Date().toISOString().split('T')[0]}.csv`);
    link.style.visibility = 'hidden';
    document.body.appendChild(link);
    link.click();
    document.body.removeChild(link);
  }
</script>

<div class="space-y-6">
  <!-- Header -->
  <div class="flex items-center justify-between">
    <div>
      <h1 class="text-2xl font-bold text-gray-900">Logs de Auditoria</h1>
      <p class="text-gray-600">Acompanhe todas as ações realizadas no sistema</p>
    </div>
    
    {#if logs.length > 0}
      <Button
        variant="outline"
        size="sm"
        on:click={exportarLogs}
      >
        <svg class="w-4 h-4 mr-2" fill="none" viewBox="0 0 24 24" stroke="currentColor">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 10v6m0 0l-3-3m3 3l3-3m2 8H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z" />
        </svg>
        Exportar CSV
      </Button>
    {/if}
  </div>
  
  <!-- Filtros -->
  <Card class="p-6">
    <div class="grid grid-cols-1 md:grid-cols-3 gap-4">
      <Input
        label="Usuário"
        type="text"
        bind:value={filtros.usuario_id}
        placeholder="ID do usuário"
      />
      
      <Input
        label="Ação"
        type="text"
        bind:value={filtros.acao}
        placeholder="Tipo de ação"
      />
      
      <Input
        label="IP"
        type="text"
        bind:value={filtros.ip_address}
        placeholder="Endereço IP"
      />
    </div>
    
    <div class="grid grid-cols-1 md:grid-cols-2 gap-4 mt-4">
      <Input
        label="Data Início"
        type="datetime-local"
        bind:value={filtros.data_inicio}
      />
      
      <Input
        label="Data Fim"
        type="datetime-local"
        bind:value={filtros.data_fim}
      />
    </div>
    
    <div class="flex justify-end space-x-3 mt-4">
      <Button
        variant="outline"
        on:click={limparFiltros}
      >
        Limpar
      </Button>
      
      <Button
        variant="primary"
        on:click={aplicarFiltros}
      >
        Aplicar Filtros
      </Button>
    </div>
  </Card>
  
  <!-- Lista de Logs -->
  <Card class="p-6">
    <div class="flex items-center justify-between mb-6">
      <div>
        <h3 class="text-lg font-semibold text-gray-900">Logs de Auditoria</h3>
        <p class="text-sm text-gray-600">
          {totalLogs} registro{totalLogs !== 1 ? 's' : ''} encontrado{totalLogs !== 1 ? 's' : ''}
        </p>
      </div>
    </div>
    
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
    {:else if logs.length === 0}
      <div class="text-center py-12">
        <div class="w-16 h-16 bg-gray-100 rounded-full flex items-center justify-center mx-auto mb-4">
          <svg class="w-8 h-8 text-gray-400" fill="none" viewBox="0 0 24 24" stroke="currentColor">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5H7a2 2 0 00-2 2v10a2 2 0 002 2h8a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2m-3 7h3m-3 4h3m-6-4h.01M9 16h.01" />
          </svg>
        </div>
        <h3 class="text-lg font-semibold text-gray-900 mb-2">Nenhum log encontrado</h3>
        <p class="text-gray-600">Não há logs de auditoria para os filtros aplicados.</p>
      </div>
    {:else}
      <!-- Lista de logs -->
      <div class="space-y-4">
        {#each getDadosPaginados() as log}
          <div class="border border-gray-200 rounded-lg p-4 hover:bg-gray-50 transition-colors">
            <div class="flex items-start justify-between">
              <div class="flex-1">
                <div class="flex items-center space-x-3 mb-2">
                  <span class="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium {getAcaoColor(log.acao)}">
                    {log.acao}
                  </span>
                  
                  <span class="text-sm text-gray-500">
                    {log.usuario?.nome || 'Usuário não encontrado'}
                  </span>
                  
                  <span class="text-sm text-gray-400">
                    {formatDate(log.criado_em)}
                  </span>
                </div>
                
                <p class="text-sm text-gray-900 mb-2">{log.detalhe}</p>
                
                <div class="flex items-center space-x-4 text-xs text-gray-500">
                  <span>IP: {log.ip_address}</span>
                  <span>•</span>
                  <span>User Agent: {log.user_agent?.substring(0, 50)}...</span>
                </div>
              </div>
            </div>
          </div>
        {/each}
      </div>
      
      <!-- Paginação -->
      {#if getTotalPaginas() > 1}
        <div class="flex items-center justify-between mt-6">
          <div class="text-sm text-gray-700">
            Mostrando {((paginaAtual - 1) * registrosPorPagina) + 1} a {Math.min(paginaAtual * registrosPorPagina, totalLogs)} de {totalLogs} registros
          </div>
          
          <div class="flex space-x-2">
            <Button
              variant="outline"
              size="sm"
              on:click={() => mudarPagina(paginaAtual - 1)}
              disabled={paginaAtual === 1}
            >
              Anterior
            </Button>
            
            <span class="px-3 py-2 text-sm text-gray-700">
              Página {paginaAtual} de {getTotalPaginas()}
            </span>
            
            <Button
              variant="outline"
              size="sm"
              on:click={() => mudarPagina(paginaAtual + 1)}
              disabled={paginaAtual === getTotalPaginas()}
            >
              Próxima
            </Button>
          </div>
        </div>
      {/if}
    {/if}
  </Card>
</div>
