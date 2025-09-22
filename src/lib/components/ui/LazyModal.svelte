<script>
  import { onMount } from 'svelte';
  
  export let isOpen = false;
  export let componentPath = '';
  export let componentProps = {};
  
  let ModalComponent = null;
  let loading = false;
  let error = '';
  
  // Carregar componente quando o modal for aberto
  $: if (isOpen && !ModalComponent && !loading && !error) {
    loadComponent();
  }
  
  async function loadComponent() {
    if (!componentPath) return;
    
    loading = true;
    error = '';
    
    try {
      // Importação dinâmica do componente
      const module = await import(/* @vite-ignore */ componentPath);
      ModalComponent = module.default;
    } catch (err) {
      error = `Erro ao carregar componente: ${err.message}`;
      console.error('Erro no lazy loading:', err);
    } finally {
      loading = false;
    }
  }
  
  // Limpar componente quando modal fechar
  $: if (!isOpen) {
    // Manter componente em cache por 30 segundos
    setTimeout(() => {
      if (!isOpen) {
        ModalComponent = null;
      }
    }, 30000);
  }
</script>

{#if isOpen}
  <div class="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50 p-4">
    <div class="bg-white rounded-lg shadow-xl max-w-md w-full max-h-[90vh] overflow-y-auto">
      {#if loading}
        <!-- Loading state -->
        <div class="flex items-center justify-center p-8">
          <div class="animate-spin rounded-full h-8 w-8 border-b-2 border-blue-600"></div>
          <span class="ml-3 text-gray-600">Carregando...</span>
        </div>
      {:else if error}
        <!-- Error state -->
        <div class="p-6 text-center">
          <div class="text-red-500 mb-4">
            <svg class="w-12 h-12 mx-auto" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8v4m0 4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
            </svg>
          </div>
          <h3 class="text-lg font-semibold text-gray-900 mb-2">Erro ao carregar</h3>
          <p class="text-sm text-gray-600 mb-4">{error}</p>
          <button
            on:click={loadComponent}
            class="px-4 py-2 bg-blue-600 text-white rounded-md hover:bg-blue-700 transition-colors"
          >
            Tentar novamente
          </button>
        </div>
      {:else if ModalComponent}
        <!-- Componente carregado -->
        <svelte:component this={ModalComponent} {...componentProps} />
      {/if}
    </div>
  </div>
{/if}
