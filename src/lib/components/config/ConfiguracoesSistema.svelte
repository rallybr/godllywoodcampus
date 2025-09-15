<script>
  import { onMount } from 'svelte';
  import { 
    configuracoesSistema, 
    loadingConfiguracoes, 
    errorConfiguracoes,
    carregarConfiguracoes,
    salvarConfiguracoesSistema,
    aplicarTema
  } from '$lib/stores/configuracoes';
  import Card from '$lib/components/ui/Card.svelte';
  import Button from '$lib/components/ui/Button.svelte';
  import Input from '$lib/components/ui/Input.svelte';
  
  let formData = {
    tema: 'light',
    idioma: 'pt-BR',
    fuso_horario: 'America/Sao_Paulo',
    formato_data: 'DD/MM/YYYY',
    formato_hora: '24h',
    itens_por_pagina: 20,
    notificacoes_email: true,
    notificacoes_push: true,
    notificacoes_som: true
  };
  
  onMount(() => {
    carregarConfiguracoes();
    
    // Subscribe to store changes
    const unsubscribe = configuracoesSistema.subscribe(config => {
      formData = { ...config };
    });
    
    return unsubscribe;
  });
  
  async function handleSubmit() {
    try {
      await salvarConfiguracoesSistema(formData);
      
      // Aplicar tema imediatamente
      aplicarTema(formData.tema);
      
      alert('Configurações salvas com sucesso!');
    } catch (err) {
      console.error('Erro ao salvar:', err);
    }
  }
  
  function handleTemaChange() {
    // Aplicar tema imediatamente para preview
    aplicarTema(formData.tema);
  }
  
  const temas = [
    { value: 'light', label: 'Claro', description: 'Tema claro padrão' },
    { value: 'dark', label: 'Escuro', description: 'Tema escuro para baixa luminosidade' },
    { value: 'auto', label: 'Automático', description: 'Segue as configurações do sistema' }
  ];
  
  const idiomas = [
    { value: 'pt-BR', label: 'Português (Brasil)', flag: '🇧🇷' },
    { value: 'en-US', label: 'English (US)', flag: '🇺🇸' },
    { value: 'es-ES', label: 'Español', flag: '🇪🇸' }
  ];
  
  const fusosHorarios = [
    { value: 'America/Sao_Paulo', label: 'Brasília (UTC-3)', offset: '-03:00' },
    { value: 'America/New_York', label: 'Nova York (UTC-5)', offset: '-05:00' },
    { value: 'Europe/London', label: 'Londres (UTC+0)', offset: '+00:00' },
    { value: 'Asia/Tokyo', label: 'Tóquio (UTC+9)', offset: '+09:00' }
  ];
  
  const formatosData = [
    { value: 'DD/MM/YYYY', label: 'DD/MM/AAAA', example: '25/12/2024' },
    { value: 'MM/DD/YYYY', label: 'MM/DD/AAAA', example: '12/25/2024' },
    { value: 'YYYY-MM-DD', label: 'AAAA-MM-DD', example: '2024-12-25' }
  ];
  
  const formatosHora = [
    { value: '24h', label: '24 horas', example: '14:30' },
    { value: '12h', label: '12 horas', example: '2:30 PM' }
  ];
  
  const opcoesItensPorPagina = [10, 20, 50, 100];
</script>

<Card class="p-6">
  <div class="mb-6">
    <h2 class="text-2xl font-bold text-gray-900">Configurações do Sistema</h2>
    <p class="text-gray-600 mt-2">Personalize a aparência e comportamento do sistema</p>
  </div>
  
  <form on:submit|preventDefault={handleSubmit} class="space-y-8">
    <!-- Aparência -->
    <div>
      <h3 class="text-lg font-medium text-gray-900 mb-4">Aparência</h3>
      
      <div class="space-y-4">
        <div>
          <label class="block text-sm font-medium text-gray-700 mb-2">
            Tema
          </label>
          <div class="grid grid-cols-1 md:grid-cols-3 gap-4">
            {#each temas as tema}
              <label class="relative cursor-pointer">
                <input
                  type="radio"
                  bind:group={formData.tema}
                  value={tema.value}
                  on:change={handleTemaChange}
                  class="sr-only"
                />
                <div class="p-4 border-2 rounded-lg transition-colors {formData.tema === tema.value ? 'border-blue-500 bg-blue-50' : 'border-gray-200 hover:border-gray-300'}">
                  <div class="font-medium text-gray-900">{tema.label}</div>
                  <div class="text-sm text-gray-500 mt-1">{tema.description}</div>
                </div>
              </label>
            {/each}
          </div>
        </div>
      </div>
    </div>
    
    <!-- Localização -->
    <div>
      <h3 class="text-lg font-medium text-gray-900 mb-4">Localização</h3>
      
      <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
        <div>
          <label for="idioma" class="block text-sm font-medium text-gray-700 mb-2">
            Idioma
          </label>
          <select
            id="idioma"
            bind:value={formData.idioma}
            class="w-full px-3 py-2 border border-gray-300 rounded-md focus:ring-2 focus:ring-blue-500 focus:border-transparent"
          >
            {#each idiomas as idioma}
              <option value={idioma.value}>{idioma.flag} {idioma.label}</option>
            {/each}
          </select>
        </div>
        
        <div>
          <label for="fuso_horario" class="block text-sm font-medium text-gray-700 mb-2">
            Fuso Horário
          </label>
          <select
            id="fuso_horario"
            bind:value={formData.fuso_horario}
            class="w-full px-3 py-2 border border-gray-300 rounded-md focus:ring-2 focus:ring-blue-500 focus:border-transparent"
          >
            {#each fusosHorarios as fuso}
              <option value={fuso.value}>{fuso.label} ({fuso.offset})</option>
            {/each}
          </select>
        </div>
      </div>
    </div>
    
    <!-- Formato de Data e Hora -->
    <div>
      <h3 class="text-lg font-medium text-gray-900 mb-4">Formato de Data e Hora</h3>
      
      <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
        <div>
          <label for="formato_data" class="block text-sm font-medium text-gray-700 mb-2">
            Formato de Data
          </label>
          <select
            id="formato_data"
            bind:value={formData.formato_data}
            class="w-full px-3 py-2 border border-gray-300 rounded-md focus:ring-2 focus:ring-blue-500 focus:border-transparent"
          >
            {#each formatosData as formato}
              <option value={formato.value}>{formato.label} - {formato.example}</option>
            {/each}
          </select>
        </div>
        
        <div>
          <label for="formato_hora" class="block text-sm font-medium text-gray-700 mb-2">
            Formato de Hora
          </label>
          <select
            id="formato_hora"
            bind:value={formData.formato_hora}
            class="w-full px-3 py-2 border border-gray-300 rounded-md focus:ring-2 focus:ring-blue-500 focus:border-transparent"
          >
            {#each formatosHora as formato}
              <option value={formato.value}>{formato.label} - {formato.example}</option>
            {/each}
          </select>
        </div>
      </div>
    </div>
    
    <!-- Interface -->
    <div>
      <h3 class="text-lg font-medium text-gray-900 mb-4">Interface</h3>
      
      <div>
        <label for="itens_por_pagina" class="block text-sm font-medium text-gray-700 mb-2">
          Itens por Página
        </label>
        <select
          id="itens_por_pagina"
          bind:value={formData.itens_por_pagina}
          class="w-full px-3 py-2 border border-gray-300 rounded-md focus:ring-2 focus:ring-blue-500 focus:border-transparent"
        >
          {#each opcoesItensPorPagina as opcao}
            <option value={opcao}>{opcao} itens</option>
          {/each}
        </select>
        <p class="mt-1 text-sm text-gray-500">Número de itens exibidos por página em listas</p>
      </div>
    </div>
    
    <!-- Notificações -->
    <div>
      <h3 class="text-lg font-medium text-gray-900 mb-4">Notificações</h3>
      
      <div class="space-y-4">
        <div class="flex items-center justify-between">
          <div>
            <div class="font-medium text-gray-900">Notificações por Email</div>
            <div class="text-sm text-gray-500">Receber notificações via email</div>
          </div>
          <label class="relative inline-flex items-center cursor-pointer">
            <input
              type="checkbox"
              bind:checked={formData.notificacoes_email}
              class="sr-only peer"
            />
            <div class="w-11 h-6 bg-gray-200 peer-focus:outline-none peer-focus:ring-4 peer-focus:ring-blue-300 rounded-full peer peer-checked:after:translate-x-full peer-checked:after:border-white after:content-[''] after:absolute after:top-[2px] after:left-[2px] after:bg-white after:border-gray-300 after:border after:rounded-full after:h-5 after:w-5 after:transition-all peer-checked:bg-blue-600"></div>
          </label>
        </div>
        
        <div class="flex items-center justify-between">
          <div>
            <div class="font-medium text-gray-900">Notificações Push</div>
            <div class="text-sm text-gray-500">Receber notificações no navegador</div>
          </div>
          <label class="relative inline-flex items-center cursor-pointer">
            <input
              type="checkbox"
              bind:checked={formData.notificacoes_push}
              class="sr-only peer"
            />
            <div class="w-11 h-6 bg-gray-200 peer-focus:outline-none peer-focus:ring-4 peer-focus:ring-blue-300 rounded-full peer peer-checked:after:translate-x-full peer-checked:after:border-white after:content-[''] after:absolute after:top-[2px] after:left-[2px] after:bg-white after:border-gray-300 after:border after:rounded-full after:h-5 after:w-5 after:transition-all peer-checked:bg-blue-600"></div>
          </label>
        </div>
        
        <div class="flex items-center justify-between">
          <div>
            <div class="font-medium text-gray-900">Som de Notificação</div>
            <div class="text-sm text-gray-500">Reproduzir som ao receber notificações</div>
          </div>
          <label class="relative inline-flex items-center cursor-pointer">
            <input
              type="checkbox"
              bind:checked={formData.notificacoes_som}
              class="sr-only peer"
            />
            <div class="w-11 h-6 bg-gray-200 peer-focus:outline-none peer-focus:ring-4 peer-focus:ring-blue-300 rounded-full peer peer-checked:after:translate-x-full peer-checked:after:border-white after:content-[''] after:absolute after:top-[2px] after:left-[2px] after:bg-white after:border-gray-300 after:border after:rounded-full after:h-5 after:w-5 after:transition-all peer-checked:bg-blue-600"></div>
          </label>
        </div>
      </div>
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
