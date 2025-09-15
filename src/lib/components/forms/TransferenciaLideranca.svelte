<script>
  import { onMount } from 'svelte';
  import { transferirLideranca, loadUsuarios, loadUserRoles } from '$lib/stores/usuarios';
  import { loadInitialData, estados, blocos, regioes, igrejas, loadBlocos, loadRegioes, loadIgrejas, clearHierarchy } from '$lib/stores/geographic';
  import Button from '$lib/components/ui/Button.svelte';
  import Input from '$lib/components/ui/Input.svelte';
  import Select from '$lib/components/ui/Select.svelte';
  import Card from '$lib/components/ui/Card.svelte';
  import Modal from '$lib/components/ui/Modal.svelte';
  
  export let isOpen = false;
  
  const dispatch = createEventDispatcher();
  
  let isLoading = false;
  let error = '';
  let success = false;
  
  // Dados do formulário
  let formData = {
    usuario_atual_id: '',
    novo_usuario_id: '',
    estado_id: '',
    bloco_id: '',
    regiao_id: '',
    igreja_id: ''
  };
  
  // Validação
  let validationErrors = {};
  
  onMount(async () => {
    await loadInitialData();
  });
  
  // Função para fechar o modal
  function closeModal() {
    isOpen = false;
    resetForm();
    dispatch('close');
  }
  
  // Função para resetar o formulário
  function resetForm() {
    formData = {
      usuario_atual_id: '',
      novo_usuario_id: '',
      estado_id: '',
      bloco_id: '',
      regiao_id: '',
      igreja_id: ''
    };
    error = '';
    success = false;
    validationErrors = {};
  }
  
  // Função para validar o formulário
  function validateForm() {
    validationErrors = {};
    
    if (!formData.usuario_atual_id) {
      validationErrors.usuario_atual_id = 'Usuário atual é obrigatório';
    }
    
    if (!formData.novo_usuario_id) {
      validationErrors.novo_usuario_id = 'Novo usuário é obrigatório';
    }
    
    if (formData.usuario_atual_id === formData.novo_usuario_id) {
      validationErrors.novo_usuario_id = 'O novo usuário deve ser diferente do atual';
    }
    
    if (!formData.estado_id) {
      validationErrors.estado_id = 'Estado é obrigatório';
    }
    
    return Object.keys(validationErrors).length === 0;
  }
  
  // Função para lidar com mudança de estado
  async function handleEstadoChange(event) {
    const estadoId = event.target.value;
    formData.estado_id = estadoId;
    formData.bloco_id = '';
    formData.regiao_id = '';
    formData.igreja_id = '';
    clearHierarchy();
    
    if (estadoId) {
      await loadBlocos(estadoId);
    }
  }
  
  // Função para lidar com mudança de bloco
  async function handleBlocoChange(event) {
    const blocoId = event.target.value;
    formData.bloco_id = blocoId;
    formData.regiao_id = '';
    formData.igreja_id = '';
    regioes.set([]);
    igrejas.set([]);
    
    if (blocoId) {
      await loadRegioes(blocoId);
    }
  }
  
  // Função para lidar com mudança de região
  async function handleRegiaoChange(event) {
    const regiaoId = event.target.value;
    formData.regiao_id = regiaoId;
    formData.igreja_id = '';
    igrejas.set([]);
    
    if (regiaoId) {
      await loadIgrejas(regiaoId);
    }
  }
  
  // Função para submeter o formulário
  async function handleSubmit() {
    if (!validateForm()) {
      return;
    }
    
    isLoading = true;
    error = '';
    
    try {
      const localizacao = {
        estado_id: formData.estado_id,
        bloco_id: formData.bloco_id,
        regiao_id: formData.regiao_id,
        igreja_id: formData.igreja_id
      };
      
      await transferirLideranca(
        formData.usuario_atual_id,
        formData.novo_usuario_id,
        localizacao
      );
      
      success = true;
      
      // Fechar modal após 2 segundos
      setTimeout(() => {
        closeModal();
        dispatch('success');
      }, 2000);
      
    } catch (err) {
      error = err.message;
    } finally {
      isLoading = false;
    }
  }
  
  // Função para obter usuários por localização
  function getUsuariosByLocation() {
    return $usuarios.filter(usuario => {
      if (formData.estado_id && usuario.estado_id !== formData.estado_id) return false;
      if (formData.bloco_id && usuario.bloco_id !== formData.bloco_id) return false;
      if (formData.regiao_id && usuario.regiao_id !== formData.regiao_id) return false;
      if (formData.igreja_id && usuario.igreja_id !== formData.igreja_id) return false;
      return usuario.ativo;
    });
  }
  
  // Função para obter nome do usuário
  function getUsuarioNome(usuarioId) {
    const usuario = $usuarios.find(u => u.id === usuarioId);
    return usuario ? usuario.nome : 'Usuário não encontrado';
  }
</script>

<Modal bind:isOpen on:close={closeModal}>
  <div class="max-w-2xl mx-auto">
    <!-- Header -->
    <div class="flex items-center justify-between mb-6">
      <div>
        <h2 class="text-xl font-semibold text-gray-900">Transferir Liderança</h2>
        <p class="text-sm text-gray-600">Transfira a liderança de um usuário para outro</p>
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
        <h3 class="text-lg font-semibold text-gray-900 mb-2">Liderança transferida com sucesso!</h3>
        <p class="text-gray-600">A transferência foi registrada no sistema.</p>
      </div>
    {:else}
      <!-- Form -->
      <form on:submit|preventDefault={handleSubmit} class="space-y-6">
        <!-- Localização -->
        <div class="space-y-4">
          <h3 class="text-lg font-semibold text-gray-900">Localização</h3>
          
          <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
            <Select
              label="Estado *"
              bind:value={formData.estado_id}
              error={validationErrors.estado_id}
              on:change={handleEstadoChange}
              options={[
                { value: '', label: 'Selecione o estado' },
                ...$estados.map(estado => ({
                  value: estado.id,
                  label: estado.nome
                }))
              ]}
            />
            
            <Select
              label="Bloco"
              bind:value={formData.bloco_id}
              on:change={handleBlocoChange}
              disabled={!formData.estado_id}
              options={[
                { value: '', label: 'Selecione o bloco' },
                ...$blocos.map(bloco => ({
                  value: bloco.id,
                  label: bloco.nome
                }))
              ]}
            />
            
            <Select
              label="Região"
              bind:value={formData.regiao_id}
              on:change={handleRegiaoChange}
              disabled={!formData.bloco_id}
              options={[
                { value: '', label: 'Selecione a região' },
                ...$regioes.map(regiao => ({
                  value: regiao.id,
                  label: regiao.nome
                }))
              ]}
            />
            
            <Select
              label="Igreja"
              bind:value={formData.igreja_id}
              disabled={!formData.regiao_id}
              options={[
                { value: '', label: 'Selecione a igreja' },
                ...$igrejas.map(igreja => ({
                  value: igreja.id,
                  label: igreja.nome
                }))
              ]}
            />
          </div>
        </div>
        
        <!-- Usuários -->
        <div class="space-y-4">
          <h3 class="text-lg font-semibold text-gray-900">Usuários</h3>
          
          <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
            <Select
              label="Usuário Atual *"
              bind:value={formData.usuario_atual_id}
              error={validationErrors.usuario_atual_id}
              options={[
                { value: '', label: 'Selecione o usuário atual' },
                ...getUsuariosByLocation().map(usuario => ({
                  value: usuario.id,
                  label: usuario.nome
                }))
              ]}
            />
            
            <Select
              label="Novo Usuário *"
              bind:value={formData.novo_usuario_id}
              error={validationErrors.novo_usuario_id}
              options={[
                { value: '', label: 'Selecione o novo usuário' },
                ...getUsuariosByLocation().map(usuario => ({
                  value: usuario.id,
                  label: usuario.nome
                }))
              ]}
            />
          </div>
        </div>
        
        <!-- Resumo -->
        {#if formData.usuario_atual_id && formData.novo_usuario_id}
          <div class="bg-blue-50 border border-blue-200 rounded-lg p-4">
            <h4 class="text-sm font-medium text-blue-900 mb-2">Resumo da Transferência</h4>
            <p class="text-sm text-blue-800">
              <strong>De:</strong> {getUsuarioNome(formData.usuario_atual_id)}<br>
              <strong>Para:</strong> {getUsuarioNome(formData.novo_usuario_id)}
            </p>
          </div>
        {/if}
        
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
            {isLoading ? 'Transferindo...' : 'Transferir Liderança'}
          </Button>
        </div>
      </form>
    {/if}
  </div>
</Modal>
