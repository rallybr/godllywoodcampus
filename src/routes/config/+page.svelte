<script>
  import { onMount } from 'svelte';
  import { userProfile } from '$lib/stores/auth';
  import Card from '$lib/components/ui/Card.svelte';
  import Button from '$lib/components/ui/Button.svelte';
  import ConfiguracoesPerfilBasico from '$lib/components/config/ConfiguracoesPerfilBasico.svelte';
  // import ConfiguracoesSistema from '$lib/components/config/ConfiguracoesSistema.svelte';
  // import ConfiguracoesNotificacoes from '$lib/components/config/ConfiguracoesNotificacoes.svelte';
  // import ConfiguracoesSeguranca from '$lib/components/config/ConfiguracoesSeguranca.svelte';
  
  let activeTab = 'perfil';
  let loading = false;
  
  const tabs = [
    {
      id: 'perfil',
      name: 'Perfil',
      icon: 'M16 7a4 4 0 11-8 0 4 4 0 018 0zM12 14a7 7 0 00-7 7h14a7 7 0 00-7-7z',
      description: 'Gerencie suas informações pessoais'
    },
    {
      id: 'sistema',
      name: 'Sistema',
      icon: 'M10.325 4.317c.426-1.756 2.924-1.756 3.35 0a1.724 1.724 0 002.573 1.066c1.543-.94 3.31.826 2.37 2.37a1.724 1.724 0 001.065 2.572c1.756.426 1.756 2.924 0 3.35a1.724 1.724 0 00-1.066 2.573c.94 1.543-.826 3.31-2.37 2.37a1.724 1.724 0 00-2.572 1.065c-.426 1.756-2.924 1.756-3.35 0a1.724 1.724 0 00-2.573-1.066c-1.543.94-3.31-.826-2.37-2.37a1.724 1.724 0 00-1.065-2.572c-1.756-.426-1.756-2.924 0-3.35a1.724 1.724 0 001.066-2.573c-.94-1.543.826-3.31 2.37-2.37.996.608 2.296.07 2.572-1.065z M15 12a3 3 0 11-6 0 3 3 0 016 0z',
      description: 'Configurações gerais do sistema'
    },
    {
      id: 'notificacoes',
      name: 'Notificações',
      icon: 'M15 17h5l-5 5v-5zM4.828 7l2.586 2.586a2 2 0 002.828 0L12.828 7H4.828zM4.828 17l2.586-2.586a2 2 0 012.828 0L12.828 17H4.828z',
      description: 'Configure suas preferências de notificação'
    },
    {
      id: 'seguranca',
      name: 'Segurança',
      icon: 'M9 12l2 2 4-4m5.618-4.016A11.955 11.955 0 0112 2.944a11.955 11.955 0 01-8.618 3.04A12.02 12.02 0 003 9c0 5.591 3.824 10.29 9 11.622 5.176-1.332 9-6.03 9-11.622 0-1.042-.133-2.052-.382-3.016z',
      description: 'Gerencie senhas e segurança da conta'
    }
  ];
  
  function setActiveTab(tabId) {
    activeTab = tabId;
  }
</script>

<svelte:head>
  <title>Configurações - Godllywood Campus</title>
</svelte:head>

<div class="max-w-7xl mx-auto py-8 px-4 sm:px-6 overflow-x-hidden">
  <!-- Header -->
  <div class="mb-8">
    <h1 class="text-3xl font-bold text-gray-900">Configurações</h1>
    <p class="text-gray-600 mt-2">Gerencie suas preferências e configurações do sistema</p>
  </div>
  
  <div class="grid grid-cols-1 gap-6">
    <!-- Sidebar de navegação -->
    <div>
      <Card padding="p-6" class="overflow-hidden">
        <nav class="space-y-2">
          {#each tabs as tab}
            <button
              on:click={() => setActiveTab(tab.id)}
              class="w-full flex items-center space-x-3 px-4 py-3 text-left rounded-lg transition-colors {activeTab === tab.id ? 'bg-blue-50 text-blue-700 border border-blue-200' : 'text-gray-700 hover:bg-gray-50'}"
            >
              <svg class="w-5 h-5 flex-shrink-0" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d={tab.icon} />
              </svg>
              <div class="flex-1 min-w-0">
                <div class="font-medium">{tab.name}</div>
                <div class="text-sm text-gray-500 truncate">{tab.description}</div>
              </div>
            </button>
          {/each}
        </nav>
      </Card>
    </div>
    
    <!-- Conteúdo principal -->
    <div class="min-w-0">
      {#if activeTab === 'perfil'}
        <ConfiguracoesPerfilBasico />
      {:else if activeTab === 'sistema'}
        <div class="p-6 bg-white rounded-lg border">
          <h3 class="text-lg font-medium text-gray-900 mb-4">Configurações do Sistema</h3>
          <p class="text-gray-600">Em desenvolvimento...</p>
        </div>
      {:else if activeTab === 'notificacoes'}
        <div class="p-6 bg-white rounded-lg border">
          <h3 class="text-lg font-medium text-gray-900 mb-4">Configurações de Notificações</h3>
          <p class="text-gray-600">Em desenvolvimento...</p>
        </div>
      {:else if activeTab === 'seguranca'}
        <div class="p-6 bg-white rounded-lg border">
          <h3 class="text-lg font-medium text-gray-900 mb-4">Configurações de Segurança</h3>
          <p class="text-gray-600">Em desenvolvimento...</p>
        </div>
      {/if}
    </div>
  </div>
</div>

