<script>
  import { createEventDispatcher } from 'svelte';
  import { roles, updateUsuario, updateUserRole } from '$lib/stores/usuarios';
  import Button from '$lib/components/ui/Button.svelte';
  
  export let isOpen = false;
  export let usuario = null;
  
  const dispatch = createEventDispatcher();
  
  let loading = false;
  let error = '';
  let formData = {
    nivel: '',
    role_id: ''
  };
  
  // Opções de nível
  const niveis = [
    { value: 'usuario', label: 'Usuário' },
    { value: 'colaborador', label: 'Colaborador' },
    { value: 'lider', label: 'Líder' },
    { value: 'administrador', label: 'Administrador' }
  ];
  
  // Função para atualizar o formulário
  function updateFormData() {
    if (!usuario) return;
    
    // Obter o role_id ativo do usuário
    let currentRoleId = '';
    if (usuario.user_roles && usuario.user_roles.length > 0) {
      const activeRole = usuario.user_roles.find(ur => ur.ativo);
      if (activeRole) {
        currentRoleId = activeRole.role_id;
      }
    }
    
    formData = {
      nivel: usuario.nivel || 'usuario',
      role_id: currentRoleId
    };
  }
  
  // Reatividade para preencher o formulário quando o usuário muda
  $: if (usuario) {
    updateFormData();
  }
  
  async function handleSubmit() {
    if (!usuario) return;
    
    loading = true;
    error = '';
    
    try {
      // Atualizar nível do usuário
      await updateUsuario(usuario.id, { nivel: formData.nivel });
      
      // Se um papel foi selecionado, atualizar user_roles
      if (formData.role_id) {
        await updateUserRole(usuario.id, formData.role_id, {
          estado_id: usuario.estado_id,
          bloco_id: usuario.bloco_id,
          regiao_id: usuario.regiao_id,
          igreja_id: usuario.igreja_id
        });
      }
      
      dispatch('success', { usuario: usuario.id, updates: formData });
      closeModal();
      
    } catch (err) {
      error = err.message;
      console.error('Erro ao atualizar usuário:', err);
    } finally {
      loading = false;
    }
  }
  
  function closeModal() {
    isOpen = false;
    error = '';
    formData = { nivel: '', role_id: '' };
    usuario = null;
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
          Editar Usuário
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
        {#if usuario}
          <!-- Informações do usuário -->
          <div class="mb-6">
            <div class="flex items-center space-x-3">
              {#if usuario.foto}
                <img class="w-12 h-12 rounded-full object-cover" src={usuario.foto} alt={usuario.nome} />
              {:else}
                <div class="w-12 h-12 bg-gradient-to-br from-blue-500 to-purple-600 rounded-full flex items-center justify-center">
                  <span class="text-white font-bold text-sm">{usuario.nome?.charAt(0) || 'U'}</span>
                </div>
              {/if}
              <div>
                <h4 class="font-medium text-gray-900">{usuario.nome}</h4>
                <p class="text-sm text-gray-500">{usuario.email}</p>
              </div>
            </div>
          </div>
          
            
            <!-- Formulário -->
          <form on:submit|preventDefault={handleSubmit} class="space-y-4">
            <!-- Nível -->
            <div>
              <label for="nivel" class="block text-sm font-medium text-gray-700 mb-1">
                Nível
              </label>
              <select
                id="nivel"
                bind:value={formData.nivel}
                class="block w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-blue-500"
                on:change={(e) => {
                  formData.nivel = e.target.value;
                }}
              >
                {#each niveis as nivel}
                  <option value={nivel.value}>{nivel.label}</option>
                {/each}
              </select>
            </div>
            
            <!-- Papel -->
            <div>
              <label for="role_id" class="block text-sm font-medium text-gray-700 mb-1">
                Papel
              </label>
              <select
                id="role_id"
                bind:value={formData.role_id}
                class="block w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-blue-500"
                on:change={(e) => {
                  formData.role_id = e.target.value;
                }}
              >
                <option value="">Selecione um papel</option>
                {#each $roles as role}
                  <option value={role.id}>{role.nome}</option>
                {/each}
              </select>
            </div>
            
            <!-- Erro -->
            {#if error}
              <div class="bg-red-50 border border-red-200 rounded-md p-3">
                <p class="text-sm text-red-600">{error}</p>
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
                Salvar
              </Button>
            </div>
          </form>
        {/if}
      </div>
    </div>
  </div>
{/if}
