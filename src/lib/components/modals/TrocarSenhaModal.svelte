<script>
  import { createEventDispatcher } from 'svelte';
  import { supabase } from '$lib/utils/supabase';
  import Button from '$lib/components/ui/Button.svelte';
  
  export let isOpen = false;
  
  const dispatch = createEventDispatcher();
  
  let loading = false;
  let error = '';
  let success = '';
  let formData = {
    senhaAtual: '',
    novaSenha: '',
    confirmarSenha: ''
  };
  
  // Validações
  let validationErrors = {};
  
  function validateForm() {
    validationErrors = {};
    
    if (!formData.senhaAtual) {
      validationErrors.senhaAtual = 'Senha atual é obrigatória';
    }
    
    if (!formData.novaSenha) {
      validationErrors.novaSenha = 'Nova senha é obrigatória';
    } else if (formData.novaSenha.length < 6) {
      validationErrors.novaSenha = 'Nova senha deve ter pelo menos 6 caracteres';
    }
    
    if (!formData.confirmarSenha) {
      validationErrors.confirmarSenha = 'Confirmação de senha é obrigatória';
    } else if (formData.novaSenha !== formData.confirmarSenha) {
      validationErrors.confirmarSenha = 'Senhas não coincidem';
    }
    
    return Object.keys(validationErrors).length === 0;
  }
  
  async function handleSubmit() {
    if (!validateForm()) return;
    
    loading = true;
    error = '';
    success = '';
    
    try {
      // Primeiro, verificar se a senha atual está correta
      const { error: signInError } = await supabase.auth.signInWithPassword({
        email: (await supabase.auth.getUser()).data.user?.email || '',
        password: formData.senhaAtual
      });
      
      if (signInError) {
        throw new Error('Senha atual incorreta');
      }
      
      // Atualizar a senha
      const { error: updateError } = await supabase.auth.updateUser({
        password: formData.novaSenha
      });
      
      if (updateError) throw updateError;
      
      success = 'Senha alterada com sucesso!';
      
      // Limpar formulário
      formData = {
        senhaAtual: '',
        novaSenha: '',
        confirmarSenha: ''
      };
      
      // Fechar modal após 2 segundos
      setTimeout(() => {
        closeModal();
      }, 2000);
      
    } catch (err) {
      error = err.message;
      console.error('Erro ao alterar senha:', err);
    } finally {
      loading = false;
    }
  }
  
  function closeModal() {
    isOpen = false;
    error = '';
    success = '';
    validationErrors = {};
    formData = {
      senhaAtual: '',
      novaSenha: '',
      confirmarSenha: ''
    };
    dispatch('close');
  }
  
  function handleKeydown(event) {
    if (event.key === 'Escape') {
      closeModal();
    }
  }
</script>

<svelte:window on:keydown={handleKeydown} />

{#if isOpen}
  <div class="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50 p-4">
    <div class="bg-white rounded-lg shadow-xl max-w-md w-full max-h-[90vh] overflow-y-auto">
      <!-- Header -->
      <div class="flex items-center justify-between p-6 border-b border-gray-200">
        <h3 class="text-lg font-semibold text-gray-900">
          Trocar Senha
        </h3>
        <button
          on:click={closeModal}
          class="text-gray-400 hover:text-gray-600 transition-colors"
        >
          <svg class="w-6 h-6" fill="none" viewBox="0 0 24 24" stroke="currentColor">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12" />
          </svg>
        </button>
      </div>
      
      <!-- Content -->
      <div class="p-6">
        <form on:submit|preventDefault={handleSubmit} class="space-y-4">
          <!-- Senha Atual -->
          <div>
            <label for="senhaAtual" class="block text-sm font-medium text-gray-700 mb-1">
              Senha Atual *
            </label>
            <input
              id="senhaAtual"
              type="password"
              bind:value={formData.senhaAtual}
              class="block w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-blue-500"
              placeholder="Digite sua senha atual"
            />
            {#if validationErrors.senhaAtual}
              <p class="mt-1 text-sm text-red-600">{validationErrors.senhaAtual}</p>
            {/if}
          </div>
          
          <!-- Nova Senha -->
          <div>
            <label for="novaSenha" class="block text-sm font-medium text-gray-700 mb-1">
              Nova Senha *
            </label>
            <input
              id="novaSenha"
              type="password"
              bind:value={formData.novaSenha}
              class="block w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-blue-500"
              placeholder="Digite sua nova senha"
            />
            {#if validationErrors.novaSenha}
              <p class="mt-1 text-sm text-red-600">{validationErrors.novaSenha}</p>
            {/if}
            <p class="mt-1 text-xs text-gray-500">Mínimo de 6 caracteres</p>
          </div>
          
          <!-- Confirmar Senha -->
          <div>
            <label for="confirmarSenha" class="block text-sm font-medium text-gray-700 mb-1">
              Confirmar Nova Senha *
            </label>
            <input
              id="confirmarSenha"
              type="password"
              bind:value={formData.confirmarSenha}
              class="block w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-blue-500"
              placeholder="Confirme sua nova senha"
            />
            {#if validationErrors.confirmarSenha}
              <p class="mt-1 text-sm text-red-600">{validationErrors.confirmarSenha}</p>
            {/if}
          </div>
          
          <!-- Mensagens de Erro/Sucesso -->
          {#if error}
            <div class="bg-red-50 border border-red-200 rounded-md p-3">
              <p class="text-sm text-red-600">{error}</p>
            </div>
          {/if}
          
          {#if success}
            <div class="bg-green-50 border border-green-200 rounded-md p-3">
              <p class="text-sm text-green-600">{success}</p>
            </div>
          {/if}
          
          <!-- Botões -->
          <div class="flex space-x-3 pt-4">
            <Button
              type="button"
              variant="outline"
              on:click={closeModal}
              class="flex-1"
              disabled={loading}
            >
              Cancelar
            </Button>
            <Button
              type="submit"
              variant="primary"
              class="flex-1"
              disabled={loading}
            >
              {#if loading}
                <svg class="animate-spin -ml-1 mr-2 h-4 w-4 text-white" fill="none" viewBox="0 0 24 24">
                  <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle>
                  <path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
                </svg>
              {/if}
              {loading ? 'Alterando...' : 'Alterar Senha'}
            </Button>
          </div>
        </form>
      </div>
    </div>
  </div>
{/if}
