<script>
  import { createEventDispatcher } from 'svelte';
  import { createAvaliacao } from '$lib/stores/avaliacoes';
  import { getEnumOptions } from '$lib/stores/avaliacoes';
  import Button from '$lib/components/ui/Button.svelte';
  import Input from '$lib/components/ui/Input.svelte';
  import Select from '$lib/components/ui/Select.svelte';
  import Modal from '$lib/components/ui/Modal.svelte';
  
  export let isOpen = false;
  export let jovem = null;
  export let avaliacao = null; // Para edição
  
  const dispatch = createEventDispatcher();
  
  let isLoading = false;
  let error = '';
  let success = false;
  
  // Dados do formulário
  let formData = {
    espirito: '',
    caractere: '',
    disposicao: '',
    avaliacao_texto: '',
    nota: ''
  };
  
  // Opções dos enums
  const enumOptions = getEnumOptions();
  
  // Função para fechar o modal
  function closeModal() {
    isOpen = false;
    resetForm();
    dispatch('close');
  }
  
  // Função para resetar o formulário
  function resetForm() {
    formData = {
      espirito: '',
      caractere: '',
      disposicao: '',
      avaliacao_texto: '',
      nota: ''
    };
    error = '';
    success = false;
  }
  
  // Função para validar o formulário
  function validateForm() {
    error = '';
    
    if (!formData.espirito) {
      error = 'Avaliação do espírito é obrigatória';
      return false;
    }
    
    if (!formData.caractere) {
      error = 'Avaliação do caráter é obrigatória';
      return false;
    }
    
    if (!formData.disposicao) {
      error = 'Avaliação da disposição é obrigatória';
      return false;
    }
    
    if (!formData.nota) {
      error = 'Nota é obrigatória';
      return false;
    }
    
    return true;
  }
  
  // Função para submeter o formulário
  async function handleSubmit() {
    if (!validateForm()) return;
    
    isLoading = true;
    error = '';
    
    try {
      const avaliacaoData = {
        jovem_id: jovem.id,
        ...formData,
        nota: parseInt(formData.nota)
      };
      
      await createAvaliacao(avaliacaoData);
      
      success = true;
      
      // Fechar modal após 1 segundo
      setTimeout(() => {
        closeModal();
        dispatch('success');
      }, 1000);
      
    } catch (err) {
      error = err.message;
    } finally {
      isLoading = false;
    }
  }
  
  // Função para obter cor da nota
  function getNotaColor(nota) {
    const numNota = parseInt(nota);
    if (numNota >= 8) return 'text-green-600';
    if (numNota >= 6) return 'text-yellow-600';
    if (numNota >= 4) return 'text-orange-600';
    return 'text-red-600';
  }
  
  // Função para obter descrição da nota
  function getNotaDescription(nota) {
    const numNota = parseInt(nota);
    if (numNota >= 9) return 'Excepcional';
    if (numNota >= 7) return 'Muito Bom';
    if (numNota >= 5) return 'Bom';
    if (numNota >= 3) return 'Regular';
    return 'Ruim';
  }
</script>

<Modal bind:isOpen on:close={closeModal}>
  <div class="max-w-2xl mx-auto">
    <!-- Header -->
    <div class="flex items-center justify-between mb-6">
      <div>
        <h2 class="text-xl font-semibold text-gray-900">
          {avaliacao ? 'Editar Avaliação' : 'Nova Avaliação'}
        </h2>
        {#if jovem}
          <p class="text-sm text-gray-600">
            Avaliando: <span class="font-medium">{jovem.nome_completo}</span>
          </p>
        {/if}
      </div>
    </div>
    
    {#if success}
      <!-- Success Message -->
      <div class="text-center py-8">
        <div class="w-16 h-16 bg-green-100 rounded-full flex items-center justify-center mx-auto mb-4">
          <svg class="w-8 h-8 text-green-600" fill="none" viewBox="0 0 24 24" stroke="currentColor">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7" />
          </svg>
        </div>
        <h3 class="text-lg font-semibold text-gray-900 mb-2">Avaliação salva com sucesso!</h3>
        <p class="text-gray-600">A avaliação foi registrada no sistema.</p>
      </div>
    {:else}
      <!-- Form -->
      <form on:submit|preventDefault={handleSubmit} class="space-y-6">
        <!-- Avaliações por Categoria -->
        <div class="grid grid-cols-1 md:grid-cols-3 gap-6">
          <div>
            <Select
              label="Espírito *"
              bind:value={formData.espirito}
              options={enumOptions.espirito}
              error={error.includes('espírito') ? error : ''}
            />
            <p class="text-xs text-gray-500 mt-1">
              Avalie o espírito do jovem
            </p>
          </div>
          
          <div>
            <Select
              label="Caráter *"
              bind:value={formData.caractere}
              options={enumOptions.caractere}
              error={error.includes('caráter') ? error : ''}
            />
            <p class="text-xs text-gray-500 mt-1">
              Avalie o caráter do jovem
            </p>
          </div>
          
          <div>
            <Select
              label="Disposição *"
              bind:value={formData.disposicao}
              options={enumOptions.disposicao}
              error={error.includes('disposição') ? error : ''}
            />
            <p class="text-xs text-gray-500 mt-1">
              Avalie a disposição do jovem
            </p>
          </div>
        </div>
        
        <!-- Nota Geral -->
        <div>
          <label class="block text-sm font-medium text-gray-700 mb-2">
            Nota Geral (1-10) *
          </label>
          <div class="grid grid-cols-5 gap-2">
            {#each [1, 2, 3, 4, 5, 6, 7, 8, 9, 10] as nota}
              <label class="relative">
                <input
                  type="radio"
                  bind:group={formData.nota}
                  value={nota.toString()}
                  class="sr-only"
                />
                <div class="w-full h-12 rounded-lg border-2 flex items-center justify-center text-sm font-medium transition-all cursor-pointer {
                  formData.nota === nota.toString() 
                    ? 'border-blue-500 bg-blue-50 text-blue-700' 
                    : 'border-gray-300 hover:border-gray-400 text-gray-700'
                }">
                  {nota}
                </div>
              </label>
            {/each}
          </div>
          
          {#if formData.nota}
            <div class="mt-2 text-center">
              <span class="text-sm font-medium {getNotaColor(formData.nota)}">
                {formData.nota} - {getNotaDescription(formData.nota)}
              </span>
            </div>
          {/if}
        </div>
        
        <!-- Observações -->
        <div>
          <label class="block text-sm font-medium text-gray-700 mb-2">
            Observações
          </label>
          <textarea
            bind:value={formData.avaliacao_texto}
            rows="4"
            class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent"
            placeholder="Descreva suas observações sobre o jovem..."
          ></textarea>
          <p class="text-xs text-gray-500 mt-1">
            Comentários adicionais sobre a avaliação
          </p>
        </div>
        
        <!-- Error Message -->
        {#if error}
          <div class="bg-red-50 border border-red-200 rounded-lg p-4">
            <div class="flex items-center space-x-2">
              <svg class="w-5 h-5 text-red-500" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8v4m0 4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
              </svg>
              <p class="text-sm text-red-600 font-medium">{error}</p>
            </div>
          </div>
        {/if}
        
        <!-- Action Buttons -->
        <div class="flex justify-end space-x-3 pt-4 border-t border-gray-200">
          <Button
            type="button"
            variant="outline"
            on:click={closeModal}
            disabled={isLoading}
          >
            Cancelar
          </Button>
          
          <Button
            type="submit"
            variant="primary"
            loading={isLoading}
            disabled={isLoading}
          >
            {isLoading ? 'Salvando...' : 'Salvar Avaliação'}
          </Button>
        </div>
      </form>
    {/if}
  </div>
</Modal>
