<script>
  // @ts-nocheck
  import { onMount } from 'svelte';
  import { createUsuario, roles } from '$lib/stores/usuarios';
  import { loadInitialData, estados, blocos, regioes, igrejas, edicoes, loadBlocos, loadRegioes, loadIgrejas, clearHierarchy } from '$lib/stores/geographic';
  import { uploadUserPhoto, compressImage } from '$lib/stores/upload';
  import { generateUUID } from '$lib/utils/uuid';
  import Button from '$lib/components/ui/Button.svelte';
  import Input from '$lib/components/ui/Input.svelte';
  import Select from '$lib/components/ui/Select.svelte';
  import Card from '$lib/components/ui/Card.svelte';
  
  // Estados do formulário
  let isLoading = false;
  let error = '';
  let success = false;
  
  // Dados do formulário
  let formData = {
    nome: '',
    email: '',
    password: '',
    confirmPassword: '',
    sexo: '',
    foto: '',
    nivel: '',
    role_id: '',
    estado_id: '',
    bloco_id: '',
    regiao_id: '',
    igreja_id: ''
  };
  
  // Foto
  let fotoFile = null;
  let fotoPreview = '';
  let fotoInputRef;
  
  // Validação
  let validationErrors = {};
  
  onMount(async () => {
    await loadInitialData();
  });
  
  // Função para validar o formulário
  function validateForm() {
    validationErrors = {};
    
    if (!formData.nome) validationErrors.nome = 'Nome é obrigatório';
    if (!formData.email) validationErrors.email = 'Email é obrigatório';
    if (!formData.password) validationErrors.password = 'Senha é obrigatória';
    if (formData.password !== formData.confirmPassword) {
      validationErrors.confirmPassword = 'Senhas não coincidem';
    }
    if (!formData.sexo) validationErrors.sexo = 'Sexo é obrigatório';
    if (!formData.nivel) validationErrors.nivel = 'Nível é obrigatório';
    if (!formData.role_id) validationErrors.role_id = 'Papel é obrigatório';
    
    return Object.keys(validationErrors).length === 0;
  }
  
  // Função para lidar com mudança de estado
  async function handleEstadoChange(event) {
    const estadoId = event.detail.value;
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
    const blocoId = event.detail.value;
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
    const regiaoId = event.detail.value;
    formData.regiao_id = regiaoId;
    formData.igreja_id = '';
    igrejas.set([]);
    
    if (regiaoId) {
      await loadIgrejas(regiaoId);
    }
  }
  
  // Função para lidar com upload de foto
  async function handleFotoUpload(event) {
    const file = event.target.files[0];
    if (!file) return;
    
    try {
      // Comprimir imagem
      const compressedFile = await compressImage(file);
      fotoFile = compressedFile;
      
      // Criar preview
      const reader = new FileReader();
      reader.onload = (e) => {
        fotoPreview = e.target.result;
      };
      reader.readAsDataURL(compressedFile);
    } catch (err) {
      error = 'Erro ao processar imagem: ' + err.message;
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
      // Upload da foto se houver
      if (fotoFile) {
        // Gerar ID temporário para o usuário
        const tempId = generateUUID();
        formData.foto = await uploadUserPhoto(tempId, fotoFile);
      }
      
      // Criar usuário
      const usuario = await createUsuario(formData);
      
      success = true;
      
      // Resetar formulário após 2 segundos
      setTimeout(() => {
        success = false;
        resetForm();
      }, 2000);
      
    } catch (err) {
      error = err.message;
    } finally {
      isLoading = false;
    }
  }
  
  // Função para resetar o formulário
  function resetForm() {
    formData = {
      nome: '',
      email: '',
      password: '',
      confirmPassword: '',
      sexo: '',
      foto: '',
      nivel: '',
      role_id: '',
      estado_id: '',
      bloco_id: '',
      regiao_id: '',
      igreja_id: ''
    };
    fotoFile = null;
    fotoPreview = '';
    validationErrors = {};
    error = '';
  }
</script>

<div class="min-h-screen bg-gradient-to-br from-blue-50 via-indigo-50 to-purple-50 py-6 sm:py-8">
  <div class="max-w-5xl mx-auto px-4 sm:px-6 lg:px-8">
    <!-- Header -->
    <div class="text-center mb-8">
      <div class="inline-flex items-center justify-center w-16 h-16 bg-gradient-to-r from-blue-600 to-purple-600 rounded-full mb-4">
        <svg class="w-8 h-8 text-white" fill="none" viewBox="0 0 24 24" stroke="currentColor">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4.354a4 4 0 110 5.292M15 21H3v-1a6 6 0 0112 0v1zm0 0h6v-1a6 6 0 00-9-5.197m13.5-9a2.5 2.5 0 11-5 0 2.5 2.5 0 015 0z" />
        </svg>
      </div>
      <h1 class="text-4xl font-bold bg-gradient-to-r from-gray-900 to-gray-700 bg-clip-text text-transparent mb-2">
        Cadastro de Usuário
      </h1>
      <p class="text-lg text-gray-600">Cadastre um novo usuário no sistema IntelliMen Campus</p>
    </div>
    
    {#if success}
      <!-- Success State -->
      <div class="max-w-2xl mx-auto">
        <div class="bg-white rounded-2xl shadow-xl p-8 text-center">
          <div class="w-20 h-20 bg-gradient-to-r from-green-400 to-green-600 rounded-full flex items-center justify-center mx-auto mb-6">
            <svg class="w-10 h-10 text-white" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7" />
            </svg>
          </div>
          <h3 class="text-2xl font-bold text-gray-900 mb-3">Usuário Cadastrado com Sucesso!</h3>
          <p class="text-gray-600 mb-6">O usuário foi criado e pode fazer login no sistema.</p>
          <div class="bg-green-50 border border-green-200 rounded-lg p-4">
            <p class="text-sm text-green-800">
              <span class="font-semibold">Próximos passos:</span> O usuário receberá um email com instruções para acessar o sistema.
            </p>
          </div>
        </div>
      </div>
    {:else}
      <!-- Form -->
      <div class="bg-white rounded-2xl shadow-xl overflow-hidden">
        <form on:submit|preventDefault={handleSubmit} class="p-6 sm:p-8">
          <!-- Informações Básicas -->
          <div class="mb-12">
            <div class="flex items-center mb-6">
              <div class="w-10 h-10 bg-gradient-to-r from-blue-500 to-blue-600 rounded-lg flex items-center justify-center mr-4">
                <svg class="w-5 h-5 text-white" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M16 7a4 4 0 11-8 0 4 4 0 018 0zM12 14a7 7 0 00-7 7h14a7 7 0 00-7-7z" />
                </svg>
              </div>
              <h2 class="text-2xl font-bold text-gray-900">Informações Básicas</h2>
            </div>
            
            <!-- Foto do Usuário -->
            <div class="mb-8">
              <div class="flex items-center space-x-6 sm:space-x-8">
                <div class="flex-shrink-0">
                <button type="button" class="relative group cursor-pointer" on:click={() => fotoInputRef?.click()} aria-label="Alterar foto do usuário">
                    {#if fotoPreview}
                      <img 
                        class="w-32 h-32 rounded-2xl object-cover shadow-lg border-4 border-white ring-4 ring-blue-100" 
                        src={fotoPreview} 
                        alt="Preview" 
                      />
                      <div class="absolute inset-0 bg-black bg-opacity-0 group-hover:bg-opacity-20 rounded-2xl transition-all duration-200 flex items-center justify-center">
                        <svg class="w-8 h-8 text-white opacity-0 group-hover:opacity-100 transition-opacity duration-200" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 16l4.586-4.586a2 2 0 012.828 0L16 16m-2-2l1.586-1.586a2 2 0 012.828 0L20 14m-6-6h.01M6 20h12a2 2 0 002-2V6a2 2 0 00-2-2H6a2 2 0 00-2 2v12a2 2 0 002 2z" />
                        </svg>
                      </div>
                    {:else}
                      <div class="w-32 h-32 bg-gradient-to-br from-gray-100 to-gray-200 rounded-2xl flex items-center justify-center shadow-lg border-4 border-white ring-4 ring-blue-100 group-hover:ring-blue-200 transition-all duration-200">
                        <div class="text-center">
                          <svg class="w-12 h-12 text-gray-400 mx-auto mb-2" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M16 7a4 4 0 11-8 0 4 4 0 018 0zM12 14a7 7 0 00-7 7h14a7 7 0 00-7-7z" />
                          </svg>
                          <p class="text-xs text-gray-500 font-medium">Adicionar Foto</p>
                        </div>
                      </div>
                    {/if}
                  </button>
                  <!-- Input file oculto -->
                  <input
                    type="file"
                    accept="image/*"
                    bind:this={fotoInputRef}
                    on:change={handleFotoUpload}
                    class="hidden"
                    id="user-foto-input"
                  />
                </div>
                <div class="flex-1">
                  <label class="block text-sm font-semibold text-gray-700 mb-3" for="user-foto-input">Foto do Usuário</label>
                  <div class="space-y-3">
                    <button
                      type="button"
                      on:click={() => fotoInputRef?.click()}
                      class="block w-full text-sm text-gray-500 py-3 px-6 rounded-xl border-0 text-sm font-semibold bg-gradient-to-r from-blue-500 to-blue-600 text-white hover:from-blue-600 hover:to-blue-700 transition-all duration-200 cursor-pointer"
                    >
                      Escolher arquivo
                    </button>
                    <div class="flex items-center space-x-2 text-xs text-gray-500">
                      <svg class="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 16h-1v-4h-1m1-4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
                      </svg>
                      <span>JPG, PNG ou WEBP. Máximo 5MB</span>
                    </div>
                  </div>
                </div>
              </div>
            </div>
            
            <!-- Campos de Informações Básicas -->
            <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
              <div class="space-y-2">
                <Input
                  label="Nome Completo *"
                  type="text"
                  bind:value={formData.nome}
                  error={validationErrors.nome}
                  placeholder="Digite o nome completo"
                />
              </div>
              
              <div class="space-y-2">
                <Input
                  label="Email *"
                  type="email"
                  bind:value={formData.email}
                  error={validationErrors.email}
                  placeholder="usuario@exemplo.com"
                />
              </div>
              
              <div class="space-y-2">
                <Input
                  label="Senha *"
                  type="password"
                  bind:value={formData.password}
                  error={validationErrors.password}
                  placeholder="Mínimo 6 caracteres"
                />
              </div>
              
              <div class="space-y-2">
                <Input
                  label="Confirmar Senha *"
                  type="password"
                  bind:value={formData.confirmPassword}
                  error={validationErrors.confirmPassword}
                  placeholder="Digite a senha novamente"
                />
              </div>
              
              <div class="space-y-2">
                <Select
                  label="Sexo *"
                  bind:value={formData.sexo}
                  error={validationErrors.sexo}
                  options={[
                    { value: '', label: 'Selecione o sexo' },
                    { value: 'masculino', label: 'Masculino' },
                    { value: 'feminino', label: 'Feminino' }
                  ]}
                />
              </div>
              
              <div class="space-y-2">
                <Select
                  label="Nível *"
                  bind:value={formData.nivel}
                  error={validationErrors.nivel}
                  placeholder="Selecione o nível"
                  options={$roles
                    .sort((a, b) => parseInt(a.nivel_hierarquico) - parseInt(b.nivel_hierarquico))
                    .map(role => ({
                      value: role.slug,
                      label: role.nome
                    }))
                  }
                />
              </div>
            </div>
          </div>
          
          <!-- Papel e Localização -->
          <div class="mb-12">
            <div class="flex items-center mb-6">
              <div class="w-10 h-10 bg-gradient-to-r from-purple-500 to-purple-600 rounded-lg flex items-center justify-center mr-4">
                <svg class="w-5 h-5 text-white" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M17.657 16.657L13.414 20.9a1.998 1.998 0 01-2.827 0l-4.244-4.243a8 8 0 1111.314 0z" />
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 11a3 3 0 11-6 0 3 3 0 016 0z" />
                </svg>
              </div>
              <h2 class="text-2xl font-bold text-gray-900">Papel e Localização</h2>
            </div>
            
            <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
              <div class="space-y-2">
                <Select
                  label="Papel *"
                  bind:value={formData.role_id}
                  error={validationErrors.role_id}
                  placeholder="Selecione o papel"
                  options={$roles.map(role => ({
                    value: role.id,
                    label: role.nome
                  }))}
                />
              </div>
              
              <div class="space-y-2">
                <Select
                  label="Estado"
                  bind:value={formData.estado_id}
                  on:change={handleEstadoChange}
                  placeholder="Selecione o estado"
                  options={$estados.map(estado => ({
                    value: estado.id,
                    label: estado.nome
                  }))}
                />
              </div>
              
              <div class="space-y-2">
                <Select
                  label="Bloco"
                  bind:value={formData.bloco_id}
                  on:change={handleBlocoChange}
                  disabled={!formData.estado_id}
                  placeholder="Selecione o bloco"
                  options={$blocos.map(bloco => ({
                    value: bloco.id,
                    label: bloco.nome
                  }))}
                />
              </div>
              
              <div class="space-y-2">
                <Select
                  label="Região"
                  bind:value={formData.regiao_id}
                  on:change={handleRegiaoChange}
                  disabled={!formData.bloco_id}
                  placeholder="Selecione a região"
                  options={$regioes.map(regiao => ({
                    value: regiao.id,
                    label: regiao.nome
                  }))}
                />
              </div>
              
              <div class="space-y-2 md:col-span-2">
                <Select
                  label="Igreja"
                  bind:value={formData.igreja_id}
                  disabled={!formData.regiao_id}
                  placeholder="Selecione a igreja"
                  options={$igrejas.map(igreja => ({
                    value: igreja.id,
                    label: igreja.nome
                  }))}
                />
              </div>
            </div>
          </div>
          
          <!-- Error Message -->
          {#if error}
            <div class="mb-8">
              <div class="bg-red-50 border-l-4 border-red-400 rounded-lg p-4">
                <div class="flex items-center">
                  <div class="flex-shrink-0">
                    <svg class="w-5 h-5 text-red-400" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8v4m0 4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
                    </svg>
                  </div>
                  <div class="ml-3">
                    <p class="text-sm text-red-700 font-medium">{error}</p>
                  </div>
                </div>
              </div>
            </div>
          {/if}
          
          <!-- Action Buttons -->
          <div class="flex flex-col sm:flex-row justify-end space-y-3 sm:space-y-0 sm:space-x-4 pt-8 border-t border-gray-200">
            <Button
              type="button"
              variant="outline"
              on:click={resetForm}
              disabled={isLoading}
              class="w-full sm:w-auto"
            >
              <svg class="w-4 h-4 mr-2" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 4v5h.582m15.356 2A8.001 8.001 0 004.582 9m0 0H9m11 11v-5h-.581m0 0a8.003 8.003 0 01-15.357-2m15.357 2H15" />
              </svg>
              Limpar Formulário
            </Button>
            
            <Button
              type="submit"
              variant="primary"
              loading={isLoading}
              disabled={isLoading}
              class="w-full sm:w-auto bg-gradient-to-r from-blue-600 to-purple-600 hover:from-blue-700 hover:to-purple-700"
            >
              {#if isLoading}
                <svg class="w-4 h-4 mr-2 animate-spin" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 4v5h.582m15.356 2A8.001 8.001 0 004.582 9m0 0H9m11 11v-5h-.581m0 0a8.003 8.003 0 01-15.357-2m15.357 2H15" />
                </svg>
                Cadastrando...
              {:else}
                <svg class="w-4 h-4 mr-2" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 6v6m0 0v6m0-6h6m-6 0H6" />
                </svg>
                Cadastrar Usuário
              {/if}
            </Button>
          </div>
        </form>
      </div>
    {/if}
  </div>
</div>
