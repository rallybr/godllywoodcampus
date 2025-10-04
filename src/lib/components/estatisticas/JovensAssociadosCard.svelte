<script>
  import { onMount } from 'svelte';
  import { jovensAssociadosStats, loadEstatisticasJovensAssociados } from '$lib/stores/estatisticas';
  import { userProfile } from '$lib/stores/auth';
  import { getUserLevelName } from '$lib/stores/niveis-acesso';
  
  let loading = false;
  
  onMount(async () => {
    if ($userProfile?.id) {
      loading = true;
      try {
        await loadEstatisticasJovensAssociados($userProfile.id);
      } catch (error) {
        console.error('Erro ao carregar estatísticas de jovens associados:', error);
      } finally {
        loading = false;
      }
    }
  });
  
  // Calcular percentuais
  $: totalAssociados = $jovensAssociadosStats?.totalAssociados || 0;
  $: pendentesAvaliacao = $jovensAssociadosStats?.pendentesAvaliacao || 0;
  $: avaliados = $jovensAssociadosStats?.avaliados || 0;
  $: aprovados = $jovensAssociadosStats?.aprovados || 0;
  
  $: percentualPendentes = totalAssociados > 0 ? ((pendentesAvaliacao / totalAssociados) * 100).toFixed(1) : 0;
  $: percentualAvaliados = totalAssociados > 0 ? ((avaliados / totalAssociados) * 100).toFixed(1) : 0;
  $: percentualAprovados = totalAssociados > 0 ? ((aprovados / totalAssociados) * 100).toFixed(1) : 0;
</script>

<!-- Card de Jovens Associados (não mostrar para jovens) -->
{#if getUserLevelName($userProfile) !== 'Jovem'}
<div class="space-y-4">
  <!-- Título do Card -->
  <div class="fb-card p-4">
    <div class="flex items-center space-x-3 mb-4">
      <div class="w-10 h-10 bg-purple-100 rounded-full flex items-center justify-center">
        <svg class="w-5 h-5 text-purple-600" fill="none" viewBox="0 0 24 24" stroke="currentColor">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M17 20h5v-2a3 3 0 00-5.356-1.857M17 20H7m10 0v-2c0-.656-.126-1.283-.356-1.857M7 20H2v-2a3 3 0 015.356-1.857M7 20v-2c0-.656.126-1.283.356-1.857m0 0a5.002 5.002 0 019.288 0M15 7a3 3 0 11-6 0 3 3 0 016 0zm6 3a2 2 0 11-4 0 2 2 0 014 0zM7 10a2 2 0 11-4 0 2 2 0 014 0z" />
        </svg>
      </div>
      <div>
        <h3 class="text-lg font-semibold text-gray-900">JOVENS ASSOCIADOS</h3>
        <p class="text-sm text-gray-500">Estatísticas dos jovens associados a você</p>
      </div>
    </div>
    
    {#if loading}
      <div class="grid grid-cols-2 sm:grid-cols-4 gap-3 sm:gap-4">
        {#each Array(4) as _}
          <div class="text-center">
            <div class="w-10 h-10 sm:w-12 sm:h-12 bg-gray-200 rounded-full mx-auto mb-2 animate-pulse"></div>
            <div class="h-6 sm:h-8 bg-gray-200 rounded w-12 sm:w-16 mx-auto mb-2 animate-pulse"></div>
            <div class="h-3 sm:h-4 bg-gray-200 rounded w-16 sm:w-20 mx-auto animate-pulse"></div>
          </div>
        {/each}
      </div>
    {:else}
      <div class="grid grid-cols-2 sm:grid-cols-4 gap-3 sm:gap-4">
        <!-- Total de Jovens Associados -->
        <a href="/jovens/associados" class="text-center group cursor-pointer hover:bg-gray-50 rounded-lg p-3 sm:p-4 transition-colors">
          <div class="w-10 h-10 sm:w-12 sm:h-12 bg-purple-100 rounded-full flex items-center justify-center mx-auto mb-2 group-hover:bg-purple-200 transition-colors">
            <svg class="w-5 h-5 sm:w-6 sm:h-6 text-purple-600" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M17 20h5v-2a3 3 0 00-5.356-1.857M17 20H7m10 0v-2c0-.656-.126-1.283-.356-1.857M7 20H2v-2a3 3 0 015.356-1.857M7 20v-2c0-.656.126-1.283.356-1.857m0 0a5.002 5.002 0 019.288 0M15 7a3 3 0 11-6 0 3 3 0 016 0zm6 3a2 2 0 11-4 0 2 2 0 014 0zM7 10a2 2 0 11-4 0 2 2 0 014 0z" />
            </svg>
          </div>
          <p class="text-xl sm:text-2xl font-bold text-gray-900 group-hover:text-purple-600 transition-colors">{totalAssociados}</p>
          <p class="text-xs sm:text-sm text-gray-500 group-hover:text-gray-700 transition-colors">Associados</p>
        </a>
        
        <!-- Pendentes de Avaliação -->
        <a href="/jovens/associados?status=pendente" class="text-center group cursor-pointer hover:bg-gray-50 rounded-lg p-3 sm:p-4 transition-colors">
          <div class="w-10 h-10 sm:w-12 sm:h-12 bg-yellow-100 rounded-full flex items-center justify-center mx-auto mb-2 group-hover:bg-yellow-200 transition-colors">
            <svg class="w-5 h-5 sm:w-6 sm:h-6 text-yellow-600" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z" />
            </svg>
          </div>
          <p class="text-xl sm:text-2xl font-bold text-gray-900 group-hover:text-yellow-600 transition-colors">{pendentesAvaliacao}</p>
          <p class="text-xs sm:text-sm text-gray-500 group-hover:text-gray-700 transition-colors">Pendentes</p>
        </a>
        
        <!-- Avaliados -->
        <a href="/jovens/associados?status=avaliado" class="text-center group cursor-pointer hover:bg-gray-50 rounded-lg p-3 sm:p-4 transition-colors">
          <div class="w-10 h-10 sm:w-12 sm:h-12 bg-blue-100 rounded-full flex items-center justify-center mx-auto mb-2 group-hover:bg-blue-200 transition-colors">
            <svg class="w-5 h-5 sm:w-6 sm:h-6 text-blue-600" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5H7a2 2 0 00-2 2v10a2 2 0 002 2h8a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2m-3 7h3m-3 4h3m-6-4h.01M9 16h.01" />
            </svg>
          </div>
          <p class="text-xl sm:text-2xl font-bold text-gray-900 group-hover:text-blue-600 transition-colors">{avaliados}</p>
          <p class="text-xs sm:text-sm text-gray-500 group-hover:text-gray-700 transition-colors">Avaliados</p>
        </a>
        
        <!-- Aprovados -->
        <a href="/jovens/associados?status=aprovado" class="text-center group cursor-pointer hover:bg-gray-50 rounded-lg p-3 sm:p-4 transition-colors">
          <div class="w-10 h-10 sm:w-12 sm:h-12 bg-green-100 rounded-full flex items-center justify-center mx-auto mb-2 group-hover:bg-green-200 transition-colors">
            <svg class="w-5 h-5 sm:w-6 sm:h-6 text-green-600" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z" />
            </svg>
          </div>
          <p class="text-xl sm:text-2xl font-bold text-gray-900 group-hover:text-green-600 transition-colors">{aprovados}</p>
          <p class="text-xs sm:text-sm text-gray-500 group-hover:text-gray-700 transition-colors">Aprovados</p>
        </a>
      </div>
    {/if}
  </div>
</div>
{/if}
