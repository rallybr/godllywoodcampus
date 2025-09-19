<script>
  import { createEventDispatcher } from 'svelte';
  import { onMount } from 'svelte';
  
  export let isOpen = false;
  export let comprovanteUrl = '';
  export let tipo = '';
  export let nomeJovem = '';
  
  const dispatch = createEventDispatcher();
  
  // Função para fechar o modal
  function closeModal() {
    dispatch('close');
  }
  
  // Função para fechar com ESC
  function handleKeydown(event) {
    if (event.key === 'Escape') {
      closeModal();
    }
  }
  
  // Função para fechar clicando no backdrop
  function handleBackdropClick(event) {
    if (event.target === event.currentTarget) {
      closeModal();
    }
  }
  
  // Determinar o tipo de arquivo
  $: fileType = comprovanteUrl ? comprovanteUrl.split('.').pop()?.toLowerCase() || '' : '';
  $: isImage = ['jpg', 'jpeg', 'png', 'gif', 'webp'].includes(fileType);
  $: isPdf = fileType === 'pdf';
  
  // Título do modal baseado no tipo
  $: modalTitle = (() => {
    switch (tipo) {
      case 'pagamento': return 'Comprovante de Pagamento';
      case 'ida': return 'Comprovante de Passagem - Ida';
      case 'volta': return 'Comprovante de Passagem - Volta';
      default: return 'Comprovante';
    }
  })();
  
  // Adicionar listener para ESC quando o modal abrir
  $: if (isOpen) {
    document.addEventListener('keydown', handleKeydown);
  } else {
    document.removeEventListener('keydown', handleKeydown);
  }
</script>

{#if isOpen}
  <!-- Backdrop -->
  <div 
    class="fixed inset-0 bg-black bg-opacity-75 flex items-center justify-center z-50 p-2 sm:p-4"
    on:click={handleBackdropClick}
    role="dialog"
    aria-modal="true"
    aria-labelledby="modal-title"
    tabindex="-1"
  >
    <!-- Modal Content -->
    <div class="bg-gray-900 rounded-xl sm:rounded-2xl shadow-2xl border border-gray-700 max-w-xs sm:max-w-2xl lg:max-w-4xl w-full max-h-[95vh] sm:max-h-[90vh] overflow-hidden">
      <!-- Header -->
      <div class="flex items-center justify-between p-4 sm:p-6 border-b border-gray-700">
        <div class="flex-1 min-w-0">
          <h2 id="modal-title" class="text-lg sm:text-xl font-semibold text-white truncate">
            {modalTitle}
          </h2>
          {#if nomeJovem}
            <p class="text-gray-400 text-xs sm:text-sm mt-1 truncate">
              {nomeJovem}
            </p>
          {/if}
        </div>
        <button
          on:click={closeModal}
          class="text-gray-400 hover:text-white transition-colors p-1 sm:p-2 hover:bg-gray-800 rounded-lg flex-shrink-0 ml-2"
          aria-label="Fechar modal"
        >
          <svg class="w-5 h-5 sm:w-6 sm:h-6" fill="none" viewBox="0 0 24 24" stroke="currentColor">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12" />
          </svg>
        </button>
      </div>
      
      <!-- Content -->
      <div class="p-3 sm:p-6 overflow-auto max-h-[calc(95vh-140px)] sm:max-h-[calc(90vh-120px)]">
        {#if comprovanteUrl}
          {#if isImage}
            <!-- Exibir imagem -->
            <div class="flex justify-center">
              <img
                src={comprovanteUrl}
                alt={modalTitle}
                class="max-w-full max-h-[50vh] sm:max-h-[60vh] object-contain rounded-lg shadow-lg"
                loading="lazy"
              />
            </div>
          {:else if isPdf}
            <!-- Exibir PDF -->
            <div class="w-full h-[50vh] sm:h-[60vh]">
              <iframe
                src={comprovanteUrl}
                class="w-full h-full rounded-lg border border-gray-600"
                title={modalTitle}
              ></iframe>
            </div>
          {:else}
            <!-- Arquivo não suportado para visualização -->
            <div class="text-center py-8 sm:py-12">
              <div class="w-12 h-12 sm:w-16 sm:h-16 bg-gray-700 rounded-full flex items-center justify-center mx-auto mb-3 sm:mb-4">
                <svg class="w-6 h-6 sm:w-8 sm:h-8 text-gray-400" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z" />
                </svg>
              </div>
              <h3 class="text-base sm:text-lg font-medium text-white mb-2">
                Arquivo não pode ser visualizado
              </h3>
              <p class="text-gray-400 text-sm sm:text-base mb-4 px-4">
                Este tipo de arquivo não pode ser visualizado no navegador.
              </p>
              <a
                href={comprovanteUrl}
                target="_blank"
                rel="noopener noreferrer"
                class="inline-flex items-center gap-2 px-3 sm:px-4 py-2 bg-blue-600 hover:bg-blue-700 text-white rounded-lg transition-colors text-sm sm:text-base"
              >
                <svg class="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 10v6m0 0l-3-3m3 3l3-3m2 8H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z" />
                </svg>
                Baixar arquivo
              </a>
            </div>
          {/if}
        {:else}
          <!-- URL não fornecida -->
          <div class="text-center py-8 sm:py-12">
            <div class="w-12 h-12 sm:w-16 sm:h-16 bg-gray-700 rounded-full flex items-center justify-center mx-auto mb-3 sm:mb-4">
              <svg class="w-6 h-6 sm:w-8 sm:h-8 text-gray-400" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-2.5L13.732 4c-.77-.833-1.964-.833-2.732 0L3.732 16.5c-.77.833.192 2.5 1.732 2.5z" />
              </svg>
            </div>
            <h3 class="text-base sm:text-lg font-medium text-white mb-2">
              Comprovante não encontrado
            </h3>
            <p class="text-gray-400 text-sm sm:text-base px-4">
              O comprovante não está disponível para visualização.
            </p>
          </div>
        {/if}
      </div>
      
      <!-- Footer -->
      <div class="flex flex-col sm:flex-row items-center justify-between p-4 sm:p-6 border-t border-gray-700 gap-3 sm:gap-0">
        <div class="text-xs sm:text-sm text-gray-400 text-center sm:text-left">
          {#if comprovanteUrl}
            <span class="inline-flex items-center gap-1">
              <svg class="w-3 h-3 sm:w-4 sm:h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 16h-1v-4h-1m1-4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
              </svg>
              <span class="hidden sm:inline">Clique fora do modal ou pressione ESC para fechar</span>
              <span class="sm:hidden">Toque fora ou pressione ESC</span>
            </span>
          {/if}
        </div>
        <div class="flex gap-2 sm:gap-3 w-full sm:w-auto">
          {#if comprovanteUrl}
            <a
              href={comprovanteUrl}
              target="_blank"
              rel="noopener noreferrer"
              class="flex-1 sm:flex-none inline-flex items-center justify-center gap-1.5 sm:gap-2 px-3 sm:px-4 py-2 bg-gray-700 hover:bg-gray-600 text-white rounded-lg transition-colors text-sm"
            >
              <svg class="w-3 h-3 sm:w-4 sm:h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M10 6H6a2 2 0 00-2 2v10a2 2 0 002 2h10a2 2 0 002-2v-4M14 4h6m0 0v6m0-6L10 14" />
              </svg>
              <span class="hidden sm:inline">Abrir em nova aba</span>
              <span class="sm:hidden">Nova aba</span>
            </a>
          {/if}
          <button
            on:click={closeModal}
            class="flex-1 sm:flex-none px-3 sm:px-4 py-2 bg-blue-600 hover:bg-blue-700 text-white rounded-lg transition-colors text-sm"
          >
            Fechar
          </button>
        </div>
      </div>
    </div>
  </div>
{/if}

<style>
  /* Garantir que o modal fique acima de tudo */
  :global(.modal-open) {
    overflow: hidden;
  }
</style>
