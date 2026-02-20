<script>
  import { userProfile } from '$lib/stores/auth';
  import { getUserLevelName } from '$lib/stores/niveis-acesso';
  import RelatorioJovens from '$lib/components/relatorios/RelatorioJovens.svelte';
</script>

<svelte:head>
  <title>Relatório de Jovens - Godllywood Campus</title>
</svelte:head>

<!-- Página de Relatório de Jovens (não mostrar para jovens) -->
{#if getUserLevelName($userProfile) !== 'Jovem'}
<div class="max-w-7xl mx-auto py-8 px-4 sm:px-6 overflow-x-hidden">
  <RelatorioJovens />
</div>
{:else}
<!-- Mensagem para usuários jovens -->
<div class="max-w-7xl mx-auto py-8 px-4 sm:px-6 overflow-x-hidden">
  <div class="text-center">
    <div class="w-16 h-16 bg-gray-100 rounded-full flex items-center justify-center mx-auto mb-4">
      <svg class="w-8 h-8 text-gray-400" fill="none" viewBox="0 0 24 24" stroke="currentColor">
        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5H7a2 2 0 00-2 2v10a2 2 0 002 2h8a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2m-3 7h3m-3 4h3m-6-4h.01M9 16h.01" />
      </svg>
    </div>
    <h1 class="text-2xl font-bold text-gray-900 mb-2">Acesso Restrito</h1>
    <p class="text-gray-600">Você não tem permissão para acessar esta página.</p>
  </div>
</div>
{/if}