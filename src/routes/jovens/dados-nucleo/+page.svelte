<script>
  import { onMount } from 'svelte';
  import { userProfile } from '$lib/stores/auth';
  import { loadDadosNucleo, saveDadosNucleo } from '$lib/stores/dados-nucleo';
  import DadosNucleoForm from '$lib/components/jovens/DadosNucleoForm.svelte';
  import { goto } from '$app/navigation';

  let dadosNucleo = null;
  let loading = true;
  let error = null;

  onMount(async () => {
    // Verificar se o usuário está logado e é jovem
    if (!$userProfile) {
      goto('/login');
      return;
    }

    if ($userProfile.nivel !== 'jovem') {
      goto('/');
      return;
    }

    try {
      // Carregar dados do núcleo do jovem
      dadosNucleo = await loadDadosNucleo($userProfile.id);
    } catch (err) {
      console.error('Erro ao carregar dados do núcleo:', err);
      error = err.message || 'Erro ao carregar dados do núcleo';
    } finally {
      loading = false;
    }
  });

  async function handleSave(event) {
    try {
      console.log('🔍 DEBUG - handleSave chamado com evento:', event);
      console.log('🔍 DEBUG - userProfile.id:', $userProfile.id);
      
      // Extrair os dados do evento
      const dados = event.detail;
      console.log('🔍 DEBUG - Dados extraídos do evento:', dados);
      
      const result = await saveDadosNucleo($userProfile.id, dados);
      console.log('🔍 DEBUG - saveDadosNucleo retornou:', result);
      
      // Recarregar os dados após salvar
      dadosNucleo = await loadDadosNucleo($userProfile.id);
      console.log('🔍 DEBUG - dadosNucleo recarregado:', dadosNucleo);
    } catch (err) {
      console.error('Erro ao salvar dados do núcleo:', err);
      error = err.message || 'Erro ao salvar dados do núcleo';
    }
  }
</script>

<svelte:head>
  <title>Dados de Núcleo - IntelliMen Campus</title>
</svelte:head>

<div class="min-h-screen bg-gray-50">
  <!-- Header -->
  <div class="bg-white shadow-sm border-b border-gray-200">
    <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
      <div class="flex items-center justify-between h-16">
        <div class="flex items-center">
          <button
            on:click={() => goto('/')}
            class="flex items-center text-gray-600 hover:text-gray-900 transition-colors"
          >
            <svg class="h-5 w-5 mr-2" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 19l-7-7 7-7" />
            </svg>
            Voltar
          </button>
        </div>
        
        <div class="flex items-center space-x-4">
          <h1 class="text-xl font-semibold text-gray-900">Dados de Núcleo</h1>
        </div>
      </div>
    </div>
  </div>

  <!-- Content -->
  <div class="max-w-4xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
    {#if loading}
      <div class="flex items-center justify-center py-12">
        <div class="animate-spin rounded-full h-8 w-8 border-b-2 border-blue-600"></div>
        <span class="ml-3 text-gray-600">Carregando dados do núcleo...</span>
      </div>
    {:else if error}
      <div class="bg-red-50 border border-red-200 rounded-lg p-4 mb-6">
        <div class="flex">
          <svg class="h-5 w-5 text-red-400" fill="none" viewBox="0 0 24 24" stroke="currentColor">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8v4m0 4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
          </svg>
          <div class="ml-3">
            <h3 class="text-sm font-medium text-red-800">Erro ao carregar dados</h3>
            <p class="mt-1 text-sm text-red-700">{error}</p>
          </div>
        </div>
      </div>
    {:else}
      <DadosNucleoForm 
        jovemId={$userProfile.id}
        on:save={handleSave}
      />
    {/if}
  </div>
</div>
