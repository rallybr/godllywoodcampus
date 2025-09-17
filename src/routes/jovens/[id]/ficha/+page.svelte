<script>
  import { onMount } from 'svelte';
  import { page } from '$app/stores';
  import { loadJovemById } from '$lib/stores/jovens-simple';
  import FichaJovem from '$lib/components/jovens/FichaJovem.svelte';
  import { goto } from '$app/navigation';

  let jovem: any = null;
  let loading = true;
  let error: any = null;

  onMount(async () => {
    const jovemId = $page.params.id;
    if (!jovemId) {
      error = 'ID do jovem não fornecido';
      loading = false;
      return;
    }

    try {
      console.log('=== CARREGANDO FICHA DO JOVEM ===');
      console.log('ID do jovem:', jovemId);
      
      const data = await loadJovemById(jovemId);
      console.log('Dados carregados:', data);
      
      if (data) {
        jovem = data;
        console.log('Jovem carregado com sucesso');
      } else {
        error = 'Jovem não encontrado';
        console.log('Jovem não encontrado');
      }
    } catch (err) {
      error = 'Erro ao carregar dados do jovem';
      console.error('Erro ao carregar ficha:', err);
    } finally {
      loading = false;
    }
  });

  function voltar() {
    goto('/jovens');
  }

  function imprimir() {
    window.print();
  }
</script>

<svelte:head>
  <title>Ficha do Jovem - IntelliMen Campus</title>
  <style>
    @media print {
      body * {
        visibility: hidden;
      }
      .printable, .printable * {
        visibility: visible;
      }
      .printable {
        position: absolute;
        left: 0;
        top: 0;
        width: 100%;
      }
      .no-print {
        display: none !important;
      }
    }
  </style>
</svelte:head>

<div class="min-h-screen bg-gray-50 py-8">
  <div class="max-w-6xl mx-auto px-4">
    <!-- Header com ações -->
    <div class="mb-6 no-print">
      <div class="flex items-center justify-between">
        <div class="flex items-center space-x-4">
          <button
            on:click={voltar}
            class="flex items-center space-x-2 px-4 py-2 text-gray-600 hover:text-gray-900 transition-colors"
          >
            <svg class="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 19l-7-7 7-7" />
            </svg>
            <span>Voltar</span>
          </button>
          <h1 class="text-2xl font-bold text-gray-900">Ficha do Jovem</h1>
        </div>
        
        <div class="flex items-center space-x-3">
          <button
            on:click={imprimir}
            class="flex items-center space-x-2 px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition-colors"
          >
            <svg class="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M17 17h2a2 2 0 002-2v-4a2 2 0 00-2-2H5a2 2 0 00-2 2v4a2 2 0 002 2h2m2 4h6a2 2 0 002-2v-4a2 2 0 00-2-2H9a2 2 0 00-2 2v4a2 2 0 002 2zm8-12V5a2 2 0 00-2-2H9a2 2 0 00-2 2v4h10z" />
            </svg>
            <span>Imprimir</span>
          </button>
        </div>
      </div>
    </div>

    <!-- Loading -->
    {#if loading}
      <div class="flex items-center justify-center py-12">
        <div class="text-center">
          <div class="animate-spin rounded-full h-12 w-12 border-b-2 border-blue-600 mx-auto mb-4"></div>
          <p class="text-gray-600">Carregando dados do jovem...</p>
        </div>
      </div>
    {/if}

    <!-- Error -->
    {#if error}
      <div class="bg-red-50 border border-red-200 rounded-lg p-6 text-center">
        <svg class="w-12 h-12 text-red-400 mx-auto mb-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-2.5L13.732 4c-.77-.833-1.732-.833-2.5 0L4.268 19.5c-.77.833.192 2.5 1.732 2.5z" />
        </svg>
        <h3 class="text-lg font-semibold text-red-800 mb-2">Erro</h3>
        <p class="text-red-600 mb-4">{error}</p>
        <button
          on:click={voltar}
          class="px-4 py-2 bg-red-600 text-white rounded-lg hover:bg-red-700 transition-colors"
        >
          Voltar para Lista
        </button>
      </div>
    {/if}

    <!-- Ficha do Jovem -->
    {#if jovem}
      <div class="printable">
        <FichaJovem {jovem} showAvaliacoes={true} />
      </div>
    {/if}
  </div>
</div>
