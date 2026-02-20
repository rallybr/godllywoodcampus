<script>
  import { userProfile } from '$lib/stores/auth';
  import { getUserLevelName } from '$lib/stores/niveis-acesso';
  import ConfiguracoesNotificacao from '$lib/components/notificacoes/ConfiguracoesNotificacao.svelte';
</script>

<svelte:head>
  <title>Configurações de Notificação - Godllywood Campus</title>
</svelte:head>

<!-- Página de Configurações de Notificações (não mostrar para jovens) -->
{#if getUserLevelName($userProfile) !== 'Jovem'}
<div class="max-w-4xl mx-auto py-8">
  <ConfiguracoesNotificacao />
</div>
{:else}
<!-- Mensagem para usuários jovens -->
<div class="max-w-4xl mx-auto py-8">
  <div class="text-center">
    <div class="w-16 h-16 bg-gray-100 rounded-full flex items-center justify-center mx-auto mb-4">
      <svg class="w-8 h-8 text-gray-400" fill="none" viewBox="0 0 24 24" stroke="currentColor">
        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 17h5l-5 5v-5zM4.828 7l2.586 2.586a2 2 0 002.828 0L12.828 7H4.828zM4.828 17l2.586-2.586a2 2 0 012.828 0L12.828 17H4.828z" />
      </svg>
    </div>
    <h1 class="text-2xl font-bold text-gray-900 mb-2">Acesso Restrito</h1>
    <p class="text-gray-600">Você não tem permissão para acessar esta página.</p>
  </div>
</div>
{/if}
