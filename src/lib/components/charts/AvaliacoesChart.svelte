<script>
  import { onMount } from 'svelte';
  import { loadAvaliacoesByJovem, calculateAvaliacaoStats } from '$lib/stores/avaliacoes';
  import { userProfile } from '$lib/stores/auth';
  import { getUserLevelName } from '$lib/stores/niveis-acesso';
  
  export let jovemId;
  export let title = 'Estatísticas de Avaliações';
  
  let stats = null;
  let loading = true;
  let error = '';
  
  onMount(async () => {
    await loadStats();
  });
  
  async function loadStats() {
    loading = true;
    error = '';
    
    try {
      const avaliacoes = await loadAvaliacoesByJovem(jovemId);
      stats = calculateAvaliacaoStats(avaliacoes);
    } catch (err) {
      error = err.message;
    } finally {
      loading = false;
    }
  }
  
  function getProgressColor(value) {
    if (value >= 8) return 'bg-green-500';
    if (value >= 6) return 'bg-yellow-500';
    if (value >= 4) return 'bg-orange-500';
    return 'bg-red-500';
  }
  
  function getProgressWidth(value) {
    return Math.min((value / 10) * 100, 100);
  }
</script>

<!-- Gráfico de Avaliações (não mostrar para jovens) -->
{#if getUserLevelName($userProfile) !== 'Jovem'}
<div class="fb-card p-6">
  <h3 class="text-lg font-semibold text-gray-900 mb-4">{title}</h3>
  
  {#if loading}
    <div class="flex items-center justify-center py-8">
      <div class="animate-spin rounded-full h-8 w-8 border-b-2 border-blue-600"></div>
    </div>
  {:else if error}
    <div class="text-center py-4">
      <p class="text-sm text-red-600">{error}</p>
    </div>
  {:else if stats && stats.total > 0}
    <div class="space-y-6">
      <!-- Médias Principais -->
      <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
        <div>
          <div class="flex items-center justify-between mb-2">
            <span class="text-sm font-medium text-gray-700">Média Geral</span>
            <span class="text-lg font-bold text-gray-900">{stats.mediaGeral}</span>
          </div>
          <div class="w-full bg-gray-200 rounded-full h-2">
            <div 
              class="h-2 rounded-full {getProgressColor(stats.mediaGeral)}"
              style="width: {getProgressWidth(stats.mediaGeral)}%"
            ></div>
          </div>
        </div>
        
        <div>
          <div class="flex items-center justify-between mb-2">
            <span class="text-sm font-medium text-gray-700">Total de Avaliações</span>
            <span class="text-lg font-bold text-gray-900">{stats.total}</span>
          </div>
          <div class="text-sm text-gray-500">
            Última avaliação: {stats.ultimaAvaliacao ? new Date(stats.ultimaAvaliacao.criado_em).toLocaleDateString('pt-BR') : 'N/A'}
          </div>
        </div>
      </div>
      
      <!-- Médias por Categoria -->
      <div class="space-y-4">
        <h4 class="text-sm font-medium text-gray-700">Médias por Categoria</h4>
        
        <div class="space-y-3">
          <div>
            <div class="flex items-center justify-between mb-1">
              <span class="text-sm text-gray-600">Espírito</span>
              <span class="text-sm font-medium text-gray-900">{stats.mediaEspirito}</span>
            </div>
            <div class="w-full bg-gray-200 rounded-full h-2">
              <div 
                class="h-2 rounded-full bg-green-500"
                style="width: {getProgressWidth(stats.mediaEspirito)}%"
              ></div>
            </div>
          </div>
          
          <div>
            <div class="flex items-center justify-between mb-1">
              <span class="text-sm text-gray-600">Caráter</span>
              <span class="text-sm font-medium text-gray-900">{stats.mediaCaractere}</span>
            </div>
            <div class="w-full bg-gray-200 rounded-full h-2">
              <div 
                class="h-2 rounded-full bg-purple-500"
                style="width: {getProgressWidth(stats.mediaCaractere)}%"
              ></div>
            </div>
          </div>
          
          <div>
            <div class="flex items-center justify-between mb-1">
              <span class="text-sm text-gray-600">Disposição</span>
              <span class="text-sm font-medium text-gray-900">{stats.mediaDisposicao}</span>
            </div>
            <div class="w-full bg-gray-200 rounded-full h-2">
              <div 
                class="h-2 rounded-full bg-blue-500"
                style="width: {getProgressWidth(stats.mediaDisposicao)}%"
              ></div>
            </div>
          </div>
        </div>
      </div>
      
      <!-- Distribuição de Notas -->
      {#if Object.keys(stats.distribuicaoNotas).length > 0}
        <div class="space-y-3">
          <h4 class="text-sm font-medium text-gray-700">Distribuição de Notas</h4>
          <div class="grid grid-cols-5 gap-2">
            {#each [1, 2, 3, 4, 5, 6, 7, 8, 9, 10] as nota}
              <div class="text-center">
                <div class="text-xs text-gray-500 mb-1">{nota}</div>
                <div class="w-full bg-gray-200 rounded-full h-8 flex items-center justify-center">
                  <span class="text-xs font-medium text-gray-700">
                    {stats.distribuicaoNotas[nota] || 0}
                  </span>
                </div>
              </div>
            {/each}
          </div>
        </div>
      {/if}
    </div>
  {:else}
    <div class="text-center py-8">
      <div class="w-16 h-16 bg-gray-100 rounded-full flex items-center justify-center mx-auto mb-4">
        <svg class="w-8 h-8 text-gray-400" fill="none" viewBox="0 0 24 24" stroke="currentColor">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 19v-6a2 2 0 00-2-2H5a2 2 0 00-2 2v6a2 2 0 002 2h2a2 2 0 002-2zm0 0V9a2 2 0 012-2h2a2 2 0 012 2v10m-6 0a2 2 0 002 2h2a2 2 0 002-2m0 0V5a2 2 0 012-2h2a2 2 0 012 2v14a2 2 0 01-2 2h-2a2 2 0 01-2-2z" />
        </svg>
      </div>
      <h3 class="text-sm font-medium text-gray-900 mb-1">Nenhuma avaliação</h3>
      <p class="text-xs text-gray-500">Este jovem ainda não possui avaliações registradas.</p>
    </div>
  {/if}
</div>
{/if}
