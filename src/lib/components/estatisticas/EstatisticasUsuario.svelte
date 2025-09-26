<script>
  import { onMount } from 'svelte';
  import { userProfile } from '$lib/stores/auth';
  import { getUserLevelName } from '$lib/stores/niveis-acesso';
  import { loadEstatisticasUsuario } from '$lib/stores/estatisticas';
  
  let estatisticasUsuario = {
    totalJovens: 0,
    avaliacoesFeitas: 0,
    mediaGeral: 0
  };
  
  let loading = false;
  
  // Reatividade para carregar estatísticas quando o perfil mudar
  $: if ($userProfile && $userProfile.id) {
    loadEstatisticas();
  }
  
  async function loadEstatisticas() {
    if (!$userProfile || !$userProfile.id) return;
    
    loading = true;
    try {
      estatisticasUsuario = await loadEstatisticasUsuario($userProfile.id);
    } catch (error) {
      console.error('Erro ao carregar estatísticas do usuário:', error);
    } finally {
      loading = false;
    }
  }
  
  onMount(() => {
    // Componente montado
  });
</script>

<!-- Estatísticas do Usuário (não mostrar para jovens) -->
{#if getUserLevelName($userProfile) !== 'Jovem'}
<div class="fb-card p-4">
    <h3 class="text-lg font-semibold text-gray-900 mb-4">Suas Estatísticas</h3>
    
    {#if loading}
      <div class="flex items-center justify-center py-8">
        <div class="animate-spin rounded-full h-8 w-8 border-b-2 border-blue-600"></div>
      </div>
    {:else}
      <div class="space-y-4">
        <!-- Jovens Cadastrados -->
        <div class="flex items-center justify-between">
          <div class="flex items-center space-x-3">
            <div class="w-8 h-8 bg-blue-100 rounded-lg flex items-center justify-center">
              <svg class="w-4 h-4 text-blue-600" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4.354a4 4 0 110 5.292M15 21H3v-1a6 6 0 0112 0v1zm0 0h6v-1a6 6 0 00-9-5.197m13.5-9a2.5 2.5 0 11-5 0 2.5 2.5 0 015 0z" />
              </svg>
            </div>
            <span class="text-sm font-medium text-gray-700">Jovens Cadastrados</span>
          </div>
          <span class="text-lg font-semibold text-blue-600">{estatisticasUsuario.totalJovens}</span>
        </div>
        
        <!-- Avaliações Feitas -->
        <div class="flex items-center justify-between">
          <div class="flex items-center space-x-3">
            <div class="w-8 h-8 bg-green-100 rounded-lg flex items-center justify-center">
              <svg class="w-4 h-4 text-green-600" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z" />
              </svg>
            </div>
            <span class="text-sm font-medium text-gray-700">Avaliações Feitas</span>
          </div>
          <span class="text-lg font-semibold text-green-600">{estatisticasUsuario.avaliacoesFeitas}</span>
        </div>
        
        <!-- Média Geral -->
        <div class="flex items-center justify-between">
          <div class="flex items-center space-x-3">
            <div class="w-8 h-8 bg-purple-100 rounded-lg flex items-center justify-center">
              <svg class="w-4 h-4 text-purple-600" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 7h8m0 0v8m0-8l-8 8-4-4-6 6" />
              </svg>
            </div>
            <span class="text-sm font-medium text-gray-700">Média Geral</span>
          </div>
          <span class="text-lg font-semibold text-purple-600">{estatisticasUsuario.mediaGeral}</span>
        </div>
      </div>
    {/if}
</div>
{/if}