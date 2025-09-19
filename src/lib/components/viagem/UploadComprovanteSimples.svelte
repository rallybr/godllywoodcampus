<script>
  import { createEventDispatcher } from 'svelte';
  
  export let isOpen = false;
  export let tipo = 'pagamento';
  export let jovemId = '';
  export let edicaoId = '';
  export let loading = false;
  
  const dispatch = createEventDispatcher();
  
  let file = null;
  let dataPassagem = '';
  let error = '';
  
  // Reset form when modal opens/closes
  $: if (isOpen) {
    file = null;
    dataPassagem = '';
    error = '';
  }
  
  // Labels e textos baseados no tipo
  $: labels = {
    pagamento: {
      title: 'Enviar Comprovante de Pagamento',
      description: 'Envie o comprovante de pagamento das despesas do acampamento.',
      button: 'Enviar Comprovante',
      fileLabel: 'Comprovante de Pagamento',
      fileAccept: '.pdf,.jpg,.jpeg,.png',
      showDate: false
    },
    ida: {
      title: 'Enviar Comprovante de Passagem - Ida',
      description: 'Envie o comprovante da passagem de ida para o acampamento.',
      button: 'Enviar Comprovante',
      fileLabel: 'Comprovante de Passagem (Ida)',
      fileAccept: '.pdf,.jpg,.jpeg,.png',
      showDate: true
    },
    volta: {
      title: 'Enviar Comprovante de Passagem - Volta',
      description: 'Envie o comprovante da passagem de volta do acampamento.',
      button: 'Enviar Comprovante',
      fileLabel: 'Comprovante de Passagem (Volta)',
      fileAccept: '.pdf,.jpg,.jpeg,.png',
      showDate: true
    }
  };
  
  $: currentLabels = labels[tipo] || labels.pagamento;
  
  function handleFileChange(event) {
    const target = event.target;
    const selectedFile = target.files?.[0];
    if (selectedFile) {
      // Validar tamanho do arquivo (máximo 10MB)
      if (selectedFile.size > 10 * 1024 * 1024) {
        error = 'Arquivo muito grande. Tamanho máximo: 10MB';
        return;
      }
      
      // Validar tipo do arquivo
      const allowedTypes = ['application/pdf', 'image/jpeg', 'image/jpg', 'image/png'];
      if (!allowedTypes.includes(selectedFile.type)) {
        error = 'Tipo de arquivo não permitido. Use PDF, JPG ou PNG.';
        return;
      }
      
      file = selectedFile;
      error = '';
    }
  }
  
  function handleDataChange(event) {
    const target = event.target;
    dataPassagem = target.value;
  }
  
  function handleSubmit() {
    if (!file) {
      error = 'Selecione um arquivo para enviar.';
      return;
    }
    
    if (currentLabels.showDate && !dataPassagem) {
      error = 'Informe a data da passagem.';
      return;
    }
    
    dispatch('upload', {
      tipo,
      jovemId,
      edicaoId,
      file,
      dataPassagem: currentLabels.showDate ? dataPassagem : null
    });
  }
  
  function handleClose() {
    dispatch('close');
  }
</script>

{#if isOpen}
  <div class="fixed inset-0 z-50 overflow-y-auto" role="dialog" aria-modal="true">
    <!-- Backdrop -->
    <div class="fixed inset-0 bg-gray-500 bg-opacity-75 transition-opacity" on:click={handleClose}></div>
    
    <!-- Modal -->
    <div class="flex min-h-full items-center justify-center p-4">
      <div class="relative bg-white rounded-lg shadow-xl transform transition-all w-full max-w-lg">
        <!-- Header -->
        <div class="flex items-center justify-between p-6 border-b border-gray-200">
          <h3 class="text-lg font-medium text-gray-900">{currentLabels.title}</h3>
          <button
            type="button"
            class="text-gray-400 hover:text-gray-600 focus:outline-none focus:ring-2 focus:ring-blue-500 rounded-md p-1"
            on:click={handleClose}
          >
            <svg class="h-6 w-6" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12" />
            </svg>
          </button>
        </div>
        
        <!-- Content -->
        <div class="p-6">
          <p class="text-gray-600 mb-6">
            {currentLabels.description}
          </p>
          
          <form on:submit|preventDefault={handleSubmit} class="space-y-4">
            <!-- Data da passagem (apenas para ida e volta) -->
            {#if currentLabels.showDate}
              <div>
                <label class="block text-sm font-medium text-gray-700 mb-2">
                  Data e Hora da Passagem
                </label>
                <input
                  type="datetime-local"
                  value={dataPassagem}
                  on:input={handleDataChange}
                  class="w-full px-3 py-2 border border-gray-300 rounded-md focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                  required
                  disabled={loading}
                />
              </div>
            {/if}
            
            <!-- Upload de arquivo -->
            <div>
              <label class="block text-sm font-medium text-gray-700 mb-2">
                {currentLabels.fileLabel}
              </label>
              <div class="mt-1 flex justify-center px-6 pt-5 pb-6 border-2 border-gray-300 border-dashed rounded-md hover:border-gray-400 transition-colors">
                <div class="space-y-1 text-center">
                  <svg class="mx-auto h-12 w-12 text-gray-400" stroke="currentColor" fill="none" viewBox="0 0 48 48">
                    <path d="M28 8H12a4 4 0 00-4 4v20m32-12v8m0 0v8a4 4 0 01-4 4H12a4 4 0 01-4-4v-4m32-4l-3.172-3.172a4 4 0 00-5.656 0L28 28M8 32l9.172-9.172a4 4 0 015.656 0L28 28m0 0l4 4m4-24h8m-4-4v8m-12 4h.02" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" />
                  </svg>
                  <div class="flex text-sm text-gray-600">
                    <label for="file-upload" class="relative cursor-pointer bg-white rounded-md font-medium text-blue-600 hover:text-blue-500 focus-within:outline-none focus-within:ring-2 focus-within:ring-offset-2 focus-within:ring-blue-500">
                      <span>Selecionar arquivo</span>
                      <input
                        id="file-upload"
                        name="file-upload"
                        type="file"
                        class="sr-only"
                        accept={currentLabels.fileAccept}
                        on:change={handleFileChange}
                        disabled={loading}
                      />
                    </label>
                    <p class="pl-1">ou arraste e solte</p>
                  </div>
                  <p class="text-xs text-gray-500">
                    PDF, JPG ou PNG até 10MB
                  </p>
                </div>
              </div>
              
              {#if file}
                <div class="mt-2 flex items-center space-x-2 text-sm text-green-600">
                  <svg class="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z" />
                  </svg>
                  <span>{file.name}</span>
                  <span class="text-gray-500">({(file.size / 1024 / 1024).toFixed(2)} MB)</span>
                </div>
              {/if}
            </div>
            
            <!-- Erro -->
            {#if error}
              <div class="bg-red-50 border border-red-200 rounded-md p-3">
                <div class="flex items-center space-x-2">
                  <svg class="w-5 h-5 text-red-500" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8v4m0 4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
                  </svg>
                  <p class="text-sm text-red-600">{error}</p>
                </div>
              </div>
            {/if}
            
            <!-- Botões -->
            <div class="flex justify-end space-x-3 pt-4">
              <button
                type="button"
                class="px-4 py-2 border border-gray-300 rounded-md text-gray-700 bg-white hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-blue-500"
                on:click={handleClose}
                disabled={loading}
              >
                Cancelar
              </button>
              <button
                type="submit"
                class="px-4 py-2 bg-blue-600 text-white rounded-md hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-blue-500 disabled:opacity-50 disabled:cursor-not-allowed"
                disabled={loading || !file || (currentLabels.showDate && !dataPassagem)}
              >
                {#if loading}
                  <svg class="animate-spin -ml-1 mr-2 h-4 w-4 inline" fill="none" viewBox="0 0 24 24">
                    <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle>
                    <path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
                  </svg>
                {/if}
                {loading ? 'Enviando...' : currentLabels.button}
              </button>
            </div>
          </form>
        </div>
      </div>
    </div>
  </div>
{/if}
