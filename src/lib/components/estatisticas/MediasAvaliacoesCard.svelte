<script>
  import { onMount } from 'svelte';
  import { estatisticas, loadEstatisticas } from '$lib/stores/estatisticas';
  import { userProfile } from '$lib/stores/auth';
  
  let loading = false;
  
  onMount(async () => {
    const userId = $userProfile?.id;
    const userLevel = $userProfile?.nivel;
    await loadEstatisticas(userId, userLevel);
  });
  
  // Calcular médias das avaliações
  $: mediaGeral = $estatisticas?.mediaGeral || 0;
  $: mediaEspirito = $estatisticas?.mediaEspirito || 0;
  $: mediaCaractere = $estatisticas?.mediaCaractere || 0;
  $: mediaDisposicao = $estatisticas?.mediaDisposicao || 0;
  
  // Função para determinar a cor do valor baseado na média
  function getValueColor(value) {
    if (value >= 8) return 'text-green-600';
    if (value >= 4) return 'text-orange-600';
    return 'text-red-600';
  }
  
  // Função para calcular a largura da barra de progresso (baseado em 10)
  function getProgressWidth(value) {
    return Math.min((value / 10) * 100, 100);
  }
</script>

<!-- Cards Médias de Avaliações -->
<div class="space-y-4">
  <!-- Card Header -->
  <div class="fb-card p-4">
    <div class="flex items-center space-x-3">
      <div class="w-10 h-10 bg-gradient-to-br from-purple-500 to-purple-600 rounded-lg flex items-center justify-center flex-shrink-0">
        <svg class="w-5 h-5 text-white" fill="none" viewBox="0 0 24 24" stroke="currentColor">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 7h8m0 0v8m0-8l-8 8-4-4-6 6" />
        </svg>
      </div>
      <div>
        <h3 class="text-lg font-bold text-purple-900">Médias de Avaliações</h3>
        <p class="text-sm text-purple-600">Performance geral dos jovens</p>
      </div>
    </div>
  </div>
  
  {#if loading}
    <div class="flex items-center justify-center py-8">
      <div class="animate-spin rounded-full h-8 w-8 border-b-2 border-blue-600"></div>
    </div>
  {:else}
    <!-- Card Média Geral -->
    <div class="fb-card p-4">
      <div class="flex items-center space-x-3">
        <div class="w-10 h-10 bg-gradient-to-br from-blue-500 to-blue-600 rounded-lg flex items-center justify-center flex-shrink-0">
          <svg class="w-5 h-5 text-white" fill="none" viewBox="0 0 24 24" stroke="currentColor">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 7h8m0 0v8m0-8l-8 8-4-4-6 6" />
          </svg>
        </div>
        <div class="flex-1 min-w-0">
          <div class="flex items-center justify-between mb-1">
            <span class="text-sm font-medium text-gray-900">Média Geral</span>
            <span class="text-sm font-bold {getValueColor(mediaGeral)}">{mediaGeral.toFixed(1)}</span>
          </div>
          <div class="w-full bg-gray-200 rounded-full h-2">
            <div 
              class="bg-blue-500 h-2 rounded-full transition-all duration-300" 
              style="width: {getProgressWidth(mediaGeral)}%"
            ></div>
          </div>
        </div>
      </div>
    </div>
    
    <!-- Card Média Espírito -->
    <div class="fb-card p-4">
      <div class="flex items-center space-x-3">
        <div class="w-10 h-10 bg-gradient-to-br from-green-500 to-green-600 rounded-lg flex items-center justify-center flex-shrink-0">
          <svg class="w-5 h-5 text-white" fill="none" viewBox="0 0 24 24" stroke="currentColor">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4.318 6.318a4.5 4.5 0 000 6.364L12 20.364l7.682-7.682a4.5 4.5 0 00-6.364-6.364L12 7.636l-1.318-1.318a4.5 4.5 0 00-6.364 0z" />
          </svg>
        </div>
        <div class="flex-1 min-w-0">
          <div class="flex items-center justify-between mb-1">
            <span class="text-sm font-medium text-gray-900">Média Espírito</span>
            <span class="text-sm font-bold {getValueColor(mediaEspirito)}">{mediaEspirito.toFixed(1)}</span>
          </div>
          <div class="w-full bg-gray-200 rounded-full h-2">
            <div 
              class="bg-green-500 h-2 rounded-full transition-all duration-300" 
              style="width: {getProgressWidth(mediaEspirito)}%"
            ></div>
          </div>
        </div>
      </div>
    </div>
    
    <!-- Card Média Caráter -->
    <div class="fb-card p-4">
      <div class="flex items-center space-x-3">
        <div class="w-10 h-10 bg-gradient-to-br from-purple-500 to-purple-600 rounded-lg flex items-center justify-center flex-shrink-0">
          <svg class="w-5 h-5 text-white" fill="none" viewBox="0 0 24 24" stroke="currentColor">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M16 7a4 4 0 11-8 0 4 4 0 018 0zM12 14a7 7 0 00-7 7h14a7 7 0 00-7-7z" />
          </svg>
        </div>
        <div class="flex-1 min-w-0">
          <div class="flex items-center justify-between mb-1">
            <span class="text-sm font-medium text-gray-900">Média Caráter</span>
            <span class="text-sm font-bold {getValueColor(mediaCaractere)}">{mediaCaractere.toFixed(1)}</span>
          </div>
          <div class="w-full bg-gray-200 rounded-full h-2">
            <div 
              class="bg-purple-500 h-2 rounded-full transition-all duration-300" 
              style="width: {getProgressWidth(mediaCaractere)}%"
            ></div>
          </div>
        </div>
      </div>
    </div>
    
    <!-- Card Média Disposição -->
    <div class="fb-card p-4">
      <div class="flex items-center space-x-3">
        <div class="w-10 h-10 bg-gradient-to-br from-blue-500 to-blue-600 rounded-lg flex items-center justify-center flex-shrink-0">
          <svg class="w-5 h-5 text-white" fill="none" viewBox="0 0 24 24" stroke="currentColor">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 10V3L4 14h7v7l9-11h-7z" />
          </svg>
        </div>
        <div class="flex-1 min-w-0">
          <div class="flex items-center justify-between mb-1">
            <span class="text-sm font-medium text-gray-900">Média Disposição</span>
            <span class="text-sm font-bold {getValueColor(mediaDisposicao)}">{mediaDisposicao.toFixed(1)}</span>
          </div>
          <div class="w-full bg-gray-200 rounded-full h-2">
            <div 
              class="bg-blue-500 h-2 rounded-full transition-all duration-300" 
              style="width: {getProgressWidth(mediaDisposicao)}%"
            ></div>
          </div>
        </div>
      </div>
    </div>
  {/if}
</div>
