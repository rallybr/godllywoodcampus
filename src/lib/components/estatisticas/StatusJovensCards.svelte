<script>
  import { onMount } from 'svelte';
  import { estatisticas, loadEstatisticas } from '$lib/stores/estatisticas';
  import { userProfile } from '$lib/stores/auth';
  import { getUserLevelName } from '$lib/stores/niveis-acesso';
  
  let loading = false;
  
  onMount(async () => {
    const userId = $userProfile?.id;
    const userLevel = $userProfile?.nivel;
    await loadEstatisticas(userId, userLevel);
  });
  
  // Calcular percentuais
  $: totalJovens = $estatisticas?.totalJovens || 0;
  $: aprovados = $estatisticas?.aprovados || 0;
  $: preAprovados = $estatisticas?.preAprovados || 0;
  $: pendentes = $estatisticas?.pendentes || 0;
  
  $: percentualAprovados = totalJovens > 0 ? ((aprovados / totalJovens) * 100).toFixed(1) : 0;
  $: percentualPreAprovados = totalJovens > 0 ? ((preAprovados / totalJovens) * 100).toFixed(1) : 0;
  $: percentualPendentes = totalJovens > 0 ? ((pendentes / totalJovens) * 100).toFixed(1) : 0;
</script>

<!-- Cards de Status dos Jovens (não mostrar para jovens) -->
{#if getUserLevelName($userProfile) !== 'Jovem'}
<div class="space-y-4">
  <!-- Card APROVADOS -->
  <div class="fb-card p-4">
    <div class="flex items-center justify-between mb-3">
      <div class="flex items-center space-x-3">
        <div class="w-10 h-10 bg-green-100 rounded-full flex items-center justify-center">
          <svg class="w-5 h-5 text-green-600" fill="none" viewBox="0 0 24 24" stroke="currentColor">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z" />
          </svg>
        </div>
        <div>
          <h4 class="font-semibold text-gray-900">APROVADOS</h4>
          <p class="text-xs text-gray-500">Jovens aprovados</p>
        </div>
      </div>
    </div>
    
    <div class="text-center">
      <div class="text-2xl font-bold text-gray-900 mb-1">{aprovados}</div>
      <div class="text-sm text-gray-500 mb-2">jovens aprovados</div>
      
      <!-- Barra de progresso -->
      <div class="w-full bg-gray-200 rounded-full h-2">
        <div 
          class="bg-green-500 h-2 rounded-full transition-all duration-300" 
          style="width: {percentualAprovados}%"
        ></div>
      </div>
      <div class="text-xs text-gray-500 mt-1">{percentualAprovados}%</div>
    </div>
  </div>
  
  <!-- Card PRÉ-APROVADOS -->
  <div class="fb-card p-4">
    <div class="flex items-center justify-between mb-3">
      <div class="flex items-center space-x-3">
        <div class="w-10 h-10 bg-orange-100 rounded-full flex items-center justify-center">
          <svg class="w-5 h-5 text-orange-600" fill="none" viewBox="0 0 24 24" stroke="currentColor">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z" />
          </svg>
        </div>
        <div>
          <h4 class="font-semibold text-gray-900">PRÉ-APROVADOS</h4>
          <p class="text-xs text-gray-500">Aguardando aprovação</p>
        </div>
      </div>
    </div>
    
    <div class="text-center">
      <div class="text-2xl font-bold text-gray-900 mb-1">{preAprovados}</div>
      <div class="text-sm text-gray-500 mb-2">jovens pré-aprovados</div>
      
      <!-- Barra de progresso -->
      <div class="w-full bg-gray-200 rounded-full h-2">
        <div 
          class="bg-yellow-500 h-2 rounded-full transition-all duration-300" 
          style="width: {percentualPreAprovados}%"
        ></div>
      </div>
      <div class="text-xs text-gray-500 mt-1">{percentualPreAprovados}%</div>
    </div>
  </div>
  
  <!-- Card PENDENTES -->
  <div class="fb-card p-4">
    <div class="flex items-center justify-between mb-3">
      <div class="flex items-center space-x-3">
        <div class="w-10 h-10 bg-gray-100 rounded-full flex items-center justify-center">
          <svg class="w-5 h-5 text-gray-600" fill="none" viewBox="0 0 24 24" stroke="currentColor">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5H7a2 2 0 00-2 2v10a2 2 0 002 2h8a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2m-3 7h3m-3 4h3m-6-4h.01M9 16h.01" />
          </svg>
        </div>
        <div>
          <h4 class="font-semibold text-gray-900">PENDENTES</h4>
          <p class="text-xs text-gray-500">Aguardando avaliação</p>
        </div>
      </div>
    </div>
    
    <div class="text-center">
      <div class="text-2xl font-bold text-gray-900 mb-1">{pendentes}</div>
      <div class="text-sm text-gray-500 mb-2">jovens pendentes</div>
      
      <!-- Barra de progresso -->
      <div class="w-full bg-gray-200 rounded-full h-2">
        <div 
          class="bg-gray-500 h-2 rounded-full transition-all duration-300" 
          style="width: {percentualPendentes}%"
        ></div>
      </div>
      <div class="text-xs text-gray-500 mt-1">{percentualPendentes}%</div>
    </div>
  </div>
</div>
{/if}
