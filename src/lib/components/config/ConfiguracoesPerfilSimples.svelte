<script>
  import { onMount } from 'svelte';
  import { 
    configuracoesPerfil, 
    loadingConfiguracoes, 
    errorConfiguracoes,
    carregarConfiguracoes,
    salvarConfiguracoesPerfil 
  } from '$lib/stores/configuracoes';
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
  
  onMount(() => {
    carregarConfiguracoes();
    
    // Subscribe to store changes
    const unsubscribe = configuracoesPerfil.subscribe(config => {
      formData = { ...config };
    });
    
    return unsubscribe;
  });
  
  function validateForm() {
    validationErrors = {};
    
    if (!formData.nome || !formData.nome.trim()) {
      validationErrors.nome = 'Nome é obrigatório';
    }
    
    if (!formData.email || !formData.email.trim()) {
      validationErrors.email = 'Email é obrigatório';
    } else if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(formData.email)) {
      validationErrors.email = 'Email inválido';
    }
    
    return Object.keys(validationErrors).length === 0;
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
    if (!value) return '';
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

<Card padding="p-6">
  <div class="mb-6">
    <h2 class="text-2xl font-bold text-gray-900">Configurações do Perfil</h2>
    <p class="text-gray-600 mt-2">Gerencie suas informações pessoais</p>
  </div>
  
  <form on:submit|preventDefault={handleSubmit} class="space-y-6">
    <!-- Informações básicas -->
    <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
      <div>
        <label for="nome" class="block text-sm font-medium text-gray-700 mb-2">
          Nome Completo *
        </label>
        <Input
          bind:value={formData.nome}
          placeholder="Seu nome completo"
          error={validationErrors.nome}
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
          type="email"
          bind:value={formData.email}
          placeholder="seu@email.com"
          error={validationErrors.email}
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
          bind:value={formData.telefone}
          on:input={handlePhoneInput}
          placeholder="(11) 99999-9999"
        />
      </div>
      
      <div>
        <label for="cargo" class="block text-sm font-medium text-gray-700 mb-2">
          Cargo
        </label>
        <Input
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
        bind:value={formData.departamento}
        placeholder="Seu departamento"
      />
    </div>
    
    <div>
      <label for="bio" class="block text-sm font-medium text-gray-700 mb-2">
        Biografia
      </label>
      <Textarea
        bind:value={formData.bio}
        placeholder="Conte um pouco sobre você..."
        rows={4}
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
