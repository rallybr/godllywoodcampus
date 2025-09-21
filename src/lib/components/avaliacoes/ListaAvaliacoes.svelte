<script>
  import { onMount } from 'svelte';
  import { loadAvaliacoes, calculateAvaliacaoStats } from '$lib/stores/avaliacoes';
  import Button from '$lib/components/ui/Button.svelte';
  import Card from '$lib/components/ui/Card.svelte';
  
  let avaliacoes = [];
  let loading = true;
  let error = '';
  let stats = null;
  let searchTerm = '';
  let filterStatus = 'all';
  
  onMount(async () => {
    await loadAvaliacoesData();
  });
  
  async function loadAvaliacoesData() {
    loading = true;
    error = '';
    
    try {
      const data = await loadAvaliacoes();
      avaliacoes = data || [];
      stats = calculateAvaliacaoStats(avaliacoes);
    } catch (err) {
      error = err.message;
    } finally {
      loading = false;
    }
  }
  
  function getEnumLabel(value, type) {
    const labels = {
      espirito: {
        'ruim': 'Ruim',
        'ser_observar': 'Ser Observado',
        'bom': 'Bom',
        'excelente': 'Excelente'
      },
      caractere: {
        'excelente': 'Excelente',
        'bom': 'Bom',
        'ser_observar': 'Ser Observado',
        'ruim': 'Ruim'
      },
      disposicao: {
        'muito_disposto': 'Muito Disposto',
        'normal': 'Normal',
        'pacato': 'Pacato',
        'desanimado': 'Desanimado'
      }
    };
    
    return labels[type]?.[value] || value;
  }
  
  function getEnumColor(value, type) {
    const colors = {
      espirito: {
        'ruim': 'bg-red-100 text-red-800',
        'ser_observar': 'bg-yellow-100 text-yellow-800',
        'bom': 'bg-green-100 text-green-800',
        'excelente': 'bg-blue-100 text-blue-800'
      },
      caractere: {
        'excelente': 'bg-blue-100 text-blue-800',
        'bom': 'bg-green-100 text-green-800',
        'ser_observar': 'bg-yellow-100 text-yellow-800',
        'ruim': 'bg-red-100 text-red-800'
      },
      disposicao: {
        'muito_disposto': 'bg-green-100 text-green-800',
        'normal': 'bg-blue-100 text-blue-800',
        'pacato': 'bg-yellow-100 text-yellow-800',
        'desanimado': 'bg-red-100 text-red-800'
      }
    };
    
    return colors[type]?.[value] || 'bg-gray-100 text-gray-800';
  }
  
  function getNotaColor(nota) {
    const numNota = parseInt(nota);
    if (numNota >= 8) return 'text-green-600';
    if (numNota >= 6) return 'text-yellow-600';
    if (numNota >= 4) return 'text-orange-600';
    return 'text-red-600';
  }
  
  function formatDate(dateString) {
    if (!dateString) return 'Não informado';
    try {
      return new Date(dateString).toLocaleDateString('pt-BR', {
        day: '2-digit',
        month: '2-digit',
        year: 'numeric',
        hour: '2-digit',
        minute: '2-digit'
      });
    } catch {
      return dateString;
    }
  }
  
  // Filtrar avaliações
  $: filteredAvaliacoes = avaliacoes.filter(avaliacao => {
    const matchesSearch = !searchTerm || 
      avaliacao.jovem?.nome_completo?.toLowerCase().includes(searchTerm.toLowerCase()) ||
      avaliacao.avaliador?.nome?.toLowerCase().includes(searchTerm.toLowerCase());
    
    return matchesSearch;
  });
</script>

<div class="space-y-6">
  <!-- Header com Estatísticas -->
  {#if stats && stats.total > 0}
    <Card class="p-6">
      <div class="flex items-center justify-between mb-6">
        <h3 class="text-lg font-semibold text-gray-900">Estatísticas das Avaliações</h3>
      </div>
      
      <!-- Total e Média Geral -->
      <div class="grid grid-cols-2 gap-4 mb-6">
        <div class="text-center bg-gray-50 rounded-lg p-4">
          <div class="text-2xl font-bold text-gray-900">{stats.total}</div>
          <div class="text-sm text-gray-500">Total de Avaliações</div>
        </div>
        
        <div class="text-center bg-blue-50 rounded-lg p-4">
          <div class="text-2xl font-bold text-blue-600">{stats.mediaGeral}</div>
          <div class="text-sm text-gray-500">Média Geral</div>
        </div>
      </div>
      
      <!-- Distribuição por Categoria -->
      <div class="grid grid-cols-1 md:grid-cols-3 gap-6">
        <!-- Espírito -->
        <div class="bg-gradient-to-br from-green-50 to-green-100 rounded-xl p-4 border border-green-200">
          <h4 class="text-lg font-semibold text-green-800 mb-3 flex items-center">
            <svg class="w-5 h-5 mr-2" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9.663 17h4.673M12 3v1m6.364 1.636l-.707.707M21 12h-1M4 12H3m3.343-5.657l-.707-.707m2.828 9.9a5 5 0 117.072 0l-.548.547A3.374 3.374 0 0014 18.469V19a2 2 0 11-4 0v-.531c0-.895-.356-1.754-.988-2.386l-.548-.547z" />
            </svg>
            Espírito
          </h4>
          <div class="space-y-2">
            {#each Object.entries(stats.distribuicaoEspirito || {}) as [label, quantidade]}
              <div class="flex justify-between items-center text-sm">
                <span class="text-gray-700">{label}</span>
                <span class="font-semibold text-green-700">{quantidade}</span>
              </div>
            {/each}
          </div>
        </div>
        
        <!-- Caráter -->
        <div class="bg-gradient-to-br from-purple-50 to-purple-100 rounded-xl p-4 border border-purple-200">
          <h4 class="text-lg font-semibold text-purple-800 mb-3 flex items-center">
            <svg class="w-5 h-5 mr-2" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z" />
            </svg>
            Caráter
          </h4>
          <div class="space-y-2">
            {#each Object.entries(stats.distribuicaoCaractere || {}) as [label, quantidade]}
              <div class="flex justify-between items-center text-sm">
                <span class="text-gray-700">{label}</span>
                <span class="font-semibold text-purple-700">{quantidade}</span>
              </div>
            {/each}
          </div>
        </div>
        
        <!-- Disposição -->
        <div class="bg-gradient-to-br from-orange-50 to-orange-100 rounded-xl p-4 border border-orange-200">
          <h4 class="text-lg font-semibold text-orange-800 mb-3 flex items-center">
            <svg class="w-5 h-5 mr-2" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 10V3L4 14h7v7l9-11h-7z" />
            </svg>
            Disposição
          </h4>
          <div class="space-y-2">
            {#each Object.entries(stats.distribuicaoDisposicao || {}) as [label, quantidade]}
              <div class="flex justify-between items-center text-sm">
                <span class="text-gray-700">{label}</span>
                <span class="font-semibold text-orange-700">{quantidade}</span>
              </div>
            {/each}
          </div>
        </div>
      </div>
    </Card>
  {/if}
  
  <!-- Filtros -->
  <Card class="p-6">
    <div class="flex flex-col md:flex-row gap-4">
      <div class="flex-1">
        <input
          type="text"
          placeholder="Pesquisar por jovem ou avaliador..."
          bind:value={searchTerm}
          class="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
        />
      </div>
    </div>
  </Card>
  
  <!-- Lista de Avaliações -->
  <div class="space-y-4">
    {#if loading}
      <div class="flex items-center justify-center py-12">
        <div class="animate-spin rounded-full h-12 w-12 border-b-2 border-blue-600"></div>
      </div>
    {:else if error}
      <div class="text-center py-12">
        <div class="w-16 h-16 bg-red-100 rounded-full flex items-center justify-center mx-auto mb-4">
          <svg class="w-8 h-8 text-red-600" fill="none" viewBox="0 0 24 24" stroke="currentColor">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-2.5L13.732 4c-.77-.833-1.964-.833-2.732 0L3.732 16.5c-.77.833.192 2.5 1.732 2.5z" />
          </svg>
        </div>
        <h3 class="text-lg font-semibold text-gray-900 mb-2">Erro ao carregar avaliações</h3>
        <p class="text-gray-600 mb-4">{error}</p>
        <Button on:click={loadAvaliacoesData} variant="primary">
          Tentar Novamente
        </Button>
      </div>
    {:else if filteredAvaliacoes.length === 0}
      <div class="text-center py-12">
        <div class="w-16 h-16 bg-gray-100 rounded-full flex items-center justify-center mx-auto mb-4">
          <svg class="w-8 h-8 text-gray-600" fill="none" viewBox="0 0 24 24" stroke="currentColor">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5H7a2 2 0 00-2 2v10a2 2 0 002 2h8a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2m-3 7h3m-3 4h3m-6-4h.01M9 16h.01" />
          </svg>
        </div>
        <h3 class="text-lg font-semibold text-gray-900 mb-2">Nenhuma avaliação encontrada</h3>
        <p class="text-gray-600">Não há avaliações cadastradas no sistema.</p>
      </div>
    {:else}
      <!-- Lista de avaliações -->
      <div class="space-y-4">
        {#each filteredAvaliacoes as avaliacao}
          <Card class="p-6">
            <div class="flex items-start justify-between">
              <div class="flex-1">
                <!-- Header da avaliação -->
                <div class="bg-gradient-to-r from-gray-50 to-gray-100 rounded-xl p-5 mb-6 border border-gray-200">
                  <div class="flex items-center justify-between">
                    <div class="flex items-center space-x-4">
                      {#if avaliacao.avaliador?.foto}
                        <img 
                          class="w-12 h-12 rounded-full object-cover border-2 border-white shadow-md" 
                          src={avaliacao.avaliador.foto} 
                          alt={avaliacao.avaliador.nome}
                        />
                      {:else}
                        <div class="w-12 h-12 bg-gradient-to-br from-purple-500 to-purple-600 rounded-full flex items-center justify-center border-2 border-white shadow-md">
                          <span class="text-white font-semibold text-lg">
                            {avaliacao.avaliador?.nome?.charAt(0) || 'A'}
                          </span>
                        </div>
                      {/if}
                      
                      <div>
                        <h4 class="text-lg font-semibold text-gray-900">
                          {avaliacao.jovem?.nome_completo || 'Jovem não encontrado'}
                        </h4>
                        <p class="text-sm text-gray-600">
                          Avaliado por: {avaliacao.avaliador?.nome || avaliacao.avaliador?.email || 'Usuário'}
                        </p>
                        <p class="text-xs text-gray-500 flex items-center mt-1">
                          <svg class="w-4 h-4 mr-1" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M8 7V3m8 4V3m-9 8h10M5 21h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v12a2 2 0 002 2z" />
                          </svg>
                          {formatDate(avaliacao.criado_em)}
                        </p>
                      </div>
                    </div>
                    
                    <!-- Nota -->
                    <div class="bg-white rounded-xl px-4 py-3 border border-gray-200 shadow-sm">
                      <div class="text-center">
                        <div class="text-2xl font-bold {getNotaColor(avaliacao.nota)}">
                          {avaliacao.nota}/10
                        </div>
                        <div class="text-xs text-gray-500 uppercase tracking-wide">
                          Nota Geral
                        </div>
                      </div>
                    </div>
                  </div>
                </div>
                
                <!-- Avaliações por categoria -->
                <div class="grid grid-cols-1 md:grid-cols-3 gap-4 mb-6">
                  <div class="bg-gradient-to-r from-blue-50 to-blue-100 rounded-xl p-4 border border-blue-200">
                    <div class="flex items-center justify-between mb-2">
                      <h5 class="text-sm font-semibold text-blue-800">Espírito</h5>
                      <svg class="w-5 h-5 text-blue-600" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4.318 6.318a4.5 4.5 0 000 6.364L12 20.364l7.682-7.682a4.5 4.5 0 00-6.364-6.364L12 7.636l-1.318-1.318a4.5 4.5 0 00-6.364 0z" />
                      </svg>
                    </div>
                    <span class="inline-flex items-center px-2 py-1 rounded-full text-xs font-medium {getEnumColor(avaliacao.espirito, 'espirito')}">
                      {getEnumLabel(avaliacao.espirito, 'espirito')}
                    </span>
                  </div>
                  
                  <div class="bg-gradient-to-r from-purple-50 to-purple-100 rounded-xl p-4 border border-purple-200">
                    <div class="flex items-center justify-between mb-2">
                      <h5 class="text-sm font-semibold text-purple-800">Caráter</h5>
                      <svg class="w-5 h-5 text-purple-600" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z" />
                      </svg>
                    </div>
                    <span class="inline-flex items-center px-2 py-1 rounded-full text-xs font-medium {getEnumColor(avaliacao.caractere, 'caractere')}">
                      {getEnumLabel(avaliacao.caractere, 'caractere')}
                    </span>
                  </div>
                  
                  <div class="bg-gradient-to-r from-green-50 to-green-100 rounded-xl p-4 border border-green-200">
                    <div class="flex items-center justify-between mb-2">
                      <h5 class="text-sm font-semibold text-green-800">Disposição</h5>
                      <svg class="w-5 h-5 text-green-600" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 10V3L4 14h7v7l9-11h-7z" />
                      </svg>
                    </div>
                    <span class="inline-flex items-center px-2 py-1 rounded-full text-xs font-medium {getEnumColor(avaliacao.disposicao, 'disposicao')}">
                      {getEnumLabel(avaliacao.disposicao, 'disposicao')}
                    </span>
                  </div>
                </div>
                
                <!-- Observações -->
                {#if avaliacao.avaliacao_texto}
                  <div class="mt-6">
                    <div class="bg-gradient-to-r from-amber-50 to-orange-50 rounded-xl p-5 border border-amber-200 shadow-sm">
                      <div class="flex items-center space-x-3 mb-4">
                        <div class="w-8 h-8 bg-amber-500 rounded-full flex items-center justify-center">
                          <svg class="w-4 h-4 text-white" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M11 5H6a2 2 0 00-2 2v11a2 2 0 002 2h11a2 2 0 002-2v-5m-1.414-9.414a2 2 0 112.828 2.828L11.828 15H9v-2.828l8.586-8.586z" />
                          </svg>
                        </div>
                        <h4 class="text-lg font-semibold text-gray-800">Observações</h4>
                      </div>
                      <div class="bg-white rounded-lg p-4 border border-amber-100">
                        <p class="text-base text-gray-700 leading-relaxed">
                          {avaliacao.avaliacao_texto}
                        </p>
                      </div>
                    </div>
                  </div>
                {/if}
              </div>
            </div>
          </Card>
        {/each}
      </div>
    {/if}
  </div>
</div>
