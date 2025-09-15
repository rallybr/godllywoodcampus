<script>
  import { onMount } from 'svelte';
  import Card from '$lib/components/ui/Card.svelte';
  import Button from '$lib/components/ui/Button.svelte';
  
  let formData = {
    nome: '',
    email: '',
    telefone: '',
    bio: '',
    cargo: '',
    departamento: ''
  };
  
  let loading = false;
  let error = '';
  
  onMount(() => {
    // Carregar dados do usuário
    formData = {
      nome: 'João Silva',
      email: 'joao@exemplo.com',
      telefone: '(11) 99999-9999',
      bio: 'Desenvolvedor apaixonado por tecnologia',
      cargo: 'Desenvolvedor',
      departamento: 'TI'
    };
  });
  
  async function handleSubmit() {
    loading = true;
    error = '';
    
    try {
      // Simular salvamento
      await new Promise(resolve => setTimeout(resolve, 1000));
      alert('Configurações salvas com sucesso!');
    } catch (err) {
      error = 'Erro ao salvar configurações';
      console.error('Erro ao salvar:', err);
    } finally {
      loading = false;
    }
  }
  
  function formatPhone(value) {
    if (!value) return '';
    const numbers = value.replace(/\D/g, '');
    
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
    const target = event.target;
    if (target) {
      const formatted = formatPhone(target.value);
      formData.telefone = formatted;
      target.value = formatted;
    }
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
        <input
          id="nome"
          type="text"
          bind:value={formData.nome}
          placeholder="Seu nome completo"
          class="w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm focus:ring-2 focus:ring-blue-500 focus:border-blue-500"
          required
        />
      </div>
      
      <div>
        <label for="email" class="block text-sm font-medium text-gray-700 mb-2">
          Email *
        </label>
        <input
          id="email"
          type="email"
          bind:value={formData.email}
          placeholder="seu@email.com"
          class="w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm focus:ring-2 focus:ring-blue-500 focus:border-blue-500"
          required
        />
      </div>
    </div>
    
    <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
      <div>
        <label for="telefone" class="block text-sm font-medium text-gray-700 mb-2">
          Telefone
        </label>
        <input
          id="telefone"
          type="text"
          bind:value={formData.telefone}
          on:input={handlePhoneInput}
          placeholder="(11) 99999-9999"
          class="w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm focus:ring-2 focus:ring-blue-500 focus:border-blue-500"
        />
      </div>
      
      <div>
        <label for="cargo" class="block text-sm font-medium text-gray-700 mb-2">
          Cargo
        </label>
        <input
          id="cargo"
          type="text"
          bind:value={formData.cargo}
          placeholder="Seu cargo na organização"
          class="w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm focus:ring-2 focus:ring-blue-500 focus:border-blue-500"
        />
      </div>
    </div>
    
    <div>
      <label for="departamento" class="block text-sm font-medium text-gray-700 mb-2">
        Departamento
      </label>
      <input
        id="departamento"
        type="text"
        bind:value={formData.departamento}
        placeholder="Seu departamento"
        class="w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm focus:ring-2 focus:ring-blue-500 focus:border-blue-500"
      />
    </div>
    
    <div>
      <label for="bio" class="block text-sm font-medium text-gray-700 mb-2">
        Biografia
      </label>
      <textarea
        id="bio"
        bind:value={formData.bio}
        placeholder="Conte um pouco sobre você..."
        rows="4"
        class="w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm focus:ring-2 focus:ring-blue-500 focus:border-blue-500 resize-vertical"
      ></textarea>
      <p class="mt-1 text-sm text-gray-500">Máximo 500 caracteres</p>
    </div>
    
    <!-- Botões de ação -->
    <div class="flex justify-end space-x-3 pt-6 border-t border-gray-200">
      <Button
        type="button"
        variant="outline"
        disabled={loading}
      >
        Cancelar
      </Button>
      <Button
        type="submit"
        disabled={loading}
      >
        {loading ? 'Salvando...' : 'Salvar Alterações'}
      </Button>
    </div>
  </form>
  
  <!-- Error state -->
  {#if error}
    <div class="mt-4 p-4 bg-red-50 border border-red-200 rounded-lg">
      <div class="flex">
        <svg class="w-5 h-5 text-red-400 mt-0.5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8v4m0 4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
        </svg>
        <div class="ml-3">
          <h3 class="text-sm font-medium text-red-800">Erro ao salvar configurações</h3>
          <p class="text-sm text-red-700 mt-1">{error}</p>
        </div>
      </div>
    </div>
  {/if}
</Card>
