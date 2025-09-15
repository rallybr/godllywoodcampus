<script>
  import { onMount } from 'svelte';
  import { 
    configuracoesPerfil, 
    loadingConfiguracoes, 
    errorConfiguracoes,
    carregarConfiguracoes,
    salvarConfiguracoesPerfil 
  } from '$lib/stores/configuracoes';
  // import { upload } from '$lib/stores/upload';
  import Card from '$lib/components/ui/Card.svelte';
  import Button from '$lib/components/ui/Button.svelte';
  import Input from '$lib/components/ui/Input.svelte';
  import Textarea from '$lib/components/ui/Textarea.svelte';
  
  let formData = {
    nome: '',
    email: '',
    telefone: '',
    foto: '',
    bio: '',
    cargo: '',
    departamento: ''
  };
  
  let validationErrors = {};
  let fileInput;
  let previewUrl = '';
  
  onMount(() => {
    carregarConfiguracoes();
    
    // Subscribe to store changes
    const unsubscribe = configuracoesPerfil.subscribe(config => {
      formData = { ...config };
      previewUrl = config.foto || '';
    });
    
    return unsubscribe;
  });
  
  function validateForm() {
    validationErrors = {};
    
    if (!formData.nome.trim()) {
      validationErrors.nome = 'Nome é obrigatório';
    }
    
    if (!formData.email.trim()) {
      validationErrors.email = 'Email é obrigatório';
    } else if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(formData.email)) {
      validationErrors.email = 'Email inválido';
    }
    
    if (formData.telefone && !/^\(\d{2}\)\s\d{4,5}-\d{4}$/.test(formData.telefone)) {
      validationErrors.telefone = 'Telefone deve estar no formato (11) 99999-9999';
    }
    
    return Object.keys(validationErrors).length === 0;
  }
  
  async function handleFileSelect(event) {
    const file = event.target.files[0];
    if (!file) return;
    
    // Validar tipo de arquivo
    if (!file.type.startsWith('image/')) {
      alert('Por favor, selecione apenas arquivos de imagem');
      return;
    }
    
    // Validar tamanho (máximo 5MB)
    if (file.size > 5 * 1024 * 1024) {
      alert('A imagem deve ter no máximo 5MB');
      return;
    }
    
    // Por enquanto, apenas criar uma URL local para preview
    try {
      const reader = new FileReader();
      reader.onload = (e) => {
        previewUrl = e.target.result;
        formData.foto = e.target.result;
      };
      reader.readAsDataURL(file);
    } catch (err) {
      console.error('Erro ao processar arquivo:', err);
      alert('Erro ao processar a imagem');
    }
  }
  
  function handleRemovePhoto() {
    formData.foto = '';
    previewUrl = '';
    if (fileInput) fileInput.value = '';
  }
  
  async function handleSubmit() {
    if (!validateForm()) return;
    
    try {
      await salvarConfiguracoesPerfil(formData);
      alert('Configurações salvas com sucesso!');
    } catch (err) {
      console.error('Erro ao salvar:', err);
    }
  }
  
  function formatPhone(value) {
    // Remove tudo que não é dígito
    const numbers = value.replace(/\D/g, '');
    
    // Aplica a máscara (11) 99999-9999
    if (numbers.length <= 2) {
      return numbers;
    } else if (numbers.length <= 6) {
      return `(${numbers.slice(0, 2)}) ${numbers.slice(2)}`;
    } else if (numbers.length <= 10) {
      return `(${numbers.slice(0, 2)}) ${numbers.slice(2, 6)}-${numbers.slice(6)}`;
    } else {
      return `(${numbers.slice(0, 2)}) ${numbers.slice(2, 7)}-${numbers.slice(7, 11)}`;
    }
  }
  
  function handlePhoneInput(event) {
    const formatted = formatPhone(event.target.value);
    formData.telefone = formatted;
    event.target.value = formatted;
  }
</script>

<Card class="p-6">
  <div class="mb-6">
    <h2 class="text-2xl font-bold text-gray-900">Configurações do Perfil</h2>
    <p class="text-gray-600 mt-2">Gerencie suas informações pessoais e foto de perfil</p>
  </div>
  
  <form on:submit|preventDefault={handleSubmit} class="space-y-6">
    <!-- Foto de perfil -->
    <div class="flex items-start space-x-6">
      <div class="flex-shrink-0">
        <div class="w-24 h-24 rounded-full overflow-hidden bg-gray-100 border-2 border-gray-200">
          {#if previewUrl}
            <img src={previewUrl} alt="Foto de perfil" class="w-full h-full object-cover" />
          {:else}
            <div class="w-full h-full flex items-center justify-center text-gray-400">
              <svg class="w-8 h-8" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M16 7a4 4 0 11-8 0 4 4 0 018 0zM12 14a7 7 0 00-7 7h14a7 7 0 00-7-7z" />
              </svg>
            </div>
          {/if}
        </div>
      </div>
      
      <div class="flex-1">
        <h3 class="text-lg font-medium text-gray-900 mb-2">Foto de Perfil</h3>
        <p class="text-sm text-gray-600 mb-4">Escolha uma foto para seu perfil. Formatos aceitos: JPG, PNG. Tamanho máximo: 5MB.</p>
        
        <div class="flex space-x-3">
          <input
            bind:this={fileInput}
            type="file"
            accept="image/*"
            on:change={handleFileSelect}
            class="hidden"
          />
          <Button
            type="button"
            variant="outline"
            size="sm"
            on:click={() => fileInput?.click()}
          >
            Escolher Foto
          </Button>
          {#if previewUrl}
            <Button
              type="button"
              variant="outline"
              size="sm"
              on:click={handleRemovePhoto}
              class="text-red-600 hover:text-red-700"
            >
              Remover
            </Button>
          {/if}
        </div>
      </div>
    </div>
    
    <!-- Informações básicas -->
    <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
      <div>
        <label for="nome" class="block text-sm font-medium text-gray-700 mb-2">
          Nome Completo *
        </label>
        <Input
          id="nome"
          bind:value={formData.nome}
          placeholder="Seu nome completo"
          class={validationErrors.nome ? 'border-red-300 focus:ring-red-500' : ''}
        />
        {#if validationErrors.nome}
          <p class="mt-1 text-sm text-red-600">{validationErrors.nome}</p>
        {/if}
      </div>
      
      <div>
        <label for="email" class="block text-sm font-medium text-gray-700 mb-2">
          Email *
        </label>
        <Input
          id="email"
          type="email"
          bind:value={formData.email}
          placeholder="seu@email.com"
          class={validationErrors.email ? 'border-red-300 focus:ring-red-500' : ''}
        />
        {#if validationErrors.email}
          <p class="mt-1 text-sm text-red-600">{validationErrors.email}</p>
        {/if}
      </div>
    </div>
    
    <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
      <div>
        <label for="telefone" class="block text-sm font-medium text-gray-700 mb-2">
          Telefone
        </label>
        <Input
          id="telefone"
          bind:value={formData.telefone}
          on:input={handlePhoneInput}
          placeholder="(11) 99999-9999"
          class={validationErrors.telefone ? 'border-red-300 focus:ring-red-500' : ''}
        />
        {#if validationErrors.telefone}
          <p class="mt-1 text-sm text-red-600">{validationErrors.telefone}</p>
        {/if}
      </div>
      
      <div>
        <label for="cargo" class="block text-sm font-medium text-gray-700 mb-2">
          Cargo
        </label>
        <Input
          id="cargo"
          bind:value={formData.cargo}
          placeholder="Seu cargo na organização"
        />
      </div>
    </div>
    
    <div>
      <label for="departamento" class="block text-sm font-medium text-gray-700 mb-2">
        Departamento
      </label>
      <Input
        id="departamento"
        bind:value={formData.departamento}
        placeholder="Seu departamento"
      />
    </div>
    
    <div>
      <label for="bio" class="block text-sm font-medium text-gray-700 mb-2">
        Biografia
      </label>
      <Textarea
        id="bio"
        bind:value={formData.bio}
        placeholder="Conte um pouco sobre você..."
        rows="4"
      />
      <p class="mt-1 text-sm text-gray-500">Máximo 500 caracteres</p>
    </div>
    
    <!-- Botões de ação -->
    <div class="flex justify-end space-x-3 pt-6 border-t border-gray-200">
      <Button
        type="button"
        variant="outline"
        on:click={() => carregarConfiguracoes()}
        disabled={$loadingConfiguracoes}
      >
        Cancelar
      </Button>
      <Button
        type="submit"
        disabled={$loadingConfiguracoes}
      >
        {$loadingConfiguracoes ? 'Salvando...' : 'Salvar Alterações'}
      </Button>
    </div>
  </form>
  
  <!-- Error state -->
  {#if $errorConfiguracoes}
    <div class="mt-4 p-4 bg-red-50 border border-red-200 rounded-lg">
      <div class="flex">
        <svg class="w-5 h-5 text-red-400 mt-0.5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8v4m0 4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
        </svg>
        <div class="ml-3">
          <h3 class="text-sm font-medium text-red-800">Erro ao salvar configurações</h3>
          <p class="text-sm text-red-700 mt-1">{$errorConfiguracoes}</p>
        </div>
      </div>
    </div>
  {/if}
</Card>
