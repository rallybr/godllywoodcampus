<script>
  import { onMount } from 'svelte';
  import { 
    configuracoesNotificacoes, 
    loadingConfiguracoes, 
    errorConfiguracoes,
    carregarConfiguracoes,
    salvarConfiguracoesNotificacoes 
  } from '$lib/stores/configuracoes';
  import Card from '$lib/components/ui/Card.svelte';
  import Button from '$lib/components/ui/Button.svelte';
  import Input from '$lib/components/ui/Input.svelte';
  
  let formData = {
    email_cadastros: true,
    email_avaliacoes: true,
    email_status: true,
    email_lembretes: true,
    email_relatorios: false,
    push_cadastros: true,
    push_avaliacoes: true,
    push_status: true,
    push_lembretes: true,
    push_relatorios: false,
    frequencia_lembretes: 'diario',
    horario_lembretes: '09:00'
  };
  
  onMount(() => {
    carregarConfiguracoes();
    
    // Subscribe to store changes
    const unsubscribe = configuracoesNotificacoes.subscribe(config => {
      formData = { ...config };
    });
    
    return unsubscribe;
  });
  
  async function handleSubmit() {
    try {
      await salvarConfiguracoesNotificacoes(formData);
      alert('Configurações de notificações salvas com sucesso!');
    } catch (err) {
      console.error('Erro ao salvar:', err);
    }
  }
  
  const frequencias = [
    { value: 'diario', label: 'Diário', description: 'Todos os dias' },
    { value: 'semanal', label: 'Semanal', description: 'Uma vez por semana' },
    { value: 'mensal', label: 'Mensal', description: 'Uma vez por mês' }
  ];
</script>

<Card class="p-6">
  <div class="mb-6">
    <h2 class="text-2xl font-bold text-gray-900">Configurações de Notificações</h2>
    <p class="text-gray-600 mt-2">Configure como e quando você deseja receber notificações</p>
  </div>
  
  <form on:submit|preventDefault={handleSubmit} class="space-y-8">
    <!-- Notificações por Email -->
    <div>
      <h3 class="text-lg font-medium text-gray-900 mb-4">Notificações por Email</h3>
      
      <div class="space-y-4">
        <div class="flex items-center justify-between">
          <div>
            <div class="font-medium text-gray-900">Novos Cadastros</div>
            <div class="text-sm text-gray-500">Receber email quando um novo jovem for cadastrado</div>
          </div>
          <label class="relative inline-flex items-center cursor-pointer">
            <input
              type="checkbox"
              bind:checked={formData.email_cadastros}
              class="sr-only peer"
            />
            <div class="w-11 h-6 bg-gray-200 peer-focus:outline-none peer-focus:ring-4 peer-focus:ring-blue-300 rounded-full peer peer-checked:after:translate-x-full peer-checked:after:border-white after:content-[''] after:absolute after:top-[2px] after:left-[2px] after:bg-white after:border-gray-300 after:border after:rounded-full after:h-5 after:w-5 after:transition-all peer-checked:bg-blue-600"></div>
          </label>
        </div>
        
        <div class="flex items-center justify-between">
          <div>
            <div class="font-medium text-gray-900">Novas Avaliações</div>
            <div class="text-sm text-gray-500">Receber email quando uma avaliação for realizada</div>
          </div>
          <label class="relative inline-flex items-center cursor-pointer">
            <input
              type="checkbox"
              bind:checked={formData.email_avaliacoes}
              class="sr-only peer"
            />
            <div class="w-11 h-6 bg-gray-200 peer-focus:outline-none peer-focus:ring-4 peer-focus:ring-blue-300 rounded-full peer peer-checked:after:translate-x-full peer-checked:after:border-white after:content-[''] after:absolute after:top-[2px] after:left-[2px] after:bg-white after:border-gray-300 after:border after:rounded-full after:h-5 after:w-5 after:transition-all peer-checked:bg-blue-600"></div>
          </label>
        </div>
        
        <div class="flex items-center justify-between">
          <div>
            <div class="font-medium text-gray-900">Mudanças de Status</div>
            <div class="text-sm text-gray-500">Receber email quando o status de um jovem for alterado</div>
          </div>
          <label class="relative inline-flex items-center cursor-pointer">
            <input
              type="checkbox"
              bind:checked={formData.email_status}
              class="sr-only peer"
            />
            <div class="w-11 h-6 bg-gray-200 peer-focus:outline-none peer-focus:ring-4 peer-focus:ring-blue-300 rounded-full peer peer-checked:after:translate-x-full peer-checked:after:border-white after:content-[''] after:absolute after:top-[2px] after:left-[2px] after:bg-white after:border-gray-300 after:border after:rounded-full after:h-5 after:w-5 after:transition-all peer-checked:bg-blue-600"></div>
          </label>
        </div>
        
        <div class="flex items-center justify-between">
          <div>
            <div class="font-medium text-gray-900">Lembretes de Avaliação</div>
            <div class="text-sm text-gray-500">Receber email com lembretes para avaliar jovens</div>
          </div>
          <label class="relative inline-flex items-center cursor-pointer">
            <input
              type="checkbox"
              bind:checked={formData.email_lembretes}
              class="sr-only peer"
            />
            <div class="w-11 h-6 bg-gray-200 peer-focus:outline-none peer-focus:ring-4 peer-focus:ring-blue-300 rounded-full peer peer-checked:after:translate-x-full peer-checked:after:border-white after:content-[''] after:absolute after:top-[2px] after:left-[2px] after:bg-white after:border-gray-300 after:border after:rounded-full after:h-5 after:w-5 after:transition-all peer-checked:bg-blue-600"></div>
          </label>
        </div>
        
        <div class="flex items-center justify-between">
          <div>
            <div class="font-medium text-gray-900">Relatórios</div>
            <div class="text-sm text-gray-500">Receber email com relatórios periódicos</div>
          </div>
          <label class="relative inline-flex items-center cursor-pointer">
            <input
              type="checkbox"
              bind:checked={formData.email_relatorios}
              class="sr-only peer"
            />
            <div class="w-11 h-6 bg-gray-200 peer-focus:outline-none peer-focus:ring-4 peer-focus:ring-blue-300 rounded-full peer peer-checked:after:translate-x-full peer-checked:after:border-white after:content-[''] after:absolute after:top-[2px] after:left-[2px] after:bg-white after:border-gray-300 after:border after:rounded-full after:h-5 after:w-5 after:transition-all peer-checked:bg-blue-600"></div>
          </label>
        </div>
      </div>
    </div>
    
    <!-- Notificações Push -->
    <div>
      <h3 class="text-lg font-medium text-gray-900 mb-4">Notificações Push (Navegador)</h3>
      
      <div class="space-y-4">
        <div class="flex items-center justify-between">
          <div>
            <div class="font-medium text-gray-900">Novos Cadastros</div>
            <div class="text-sm text-gray-500">Notificação no navegador para novos cadastros</div>
          </div>
          <label class="relative inline-flex items-center cursor-pointer">
            <input
              type="checkbox"
              bind:checked={formData.push_cadastros}
              class="sr-only peer"
            />
            <div class="w-11 h-6 bg-gray-200 peer-focus:outline-none peer-focus:ring-4 peer-focus:ring-blue-300 rounded-full peer peer-checked:after:translate-x-full peer-checked:after:border-white after:content-[''] after:absolute after:top-[2px] after:left-[2px] after:bg-white after:border-gray-300 after:border after:rounded-full after:h-5 after:w-5 after:transition-all peer-checked:bg-blue-600"></div>
          </label>
        </div>
        
        <div class="flex items-center justify-between">
          <div>
            <div class="font-medium text-gray-900">Novas Avaliações</div>
            <div class="text-sm text-gray-500">Notificação no navegador para novas avaliações</div>
          </div>
          <label class="relative inline-flex items-center cursor-pointer">
            <input
              type="checkbox"
              bind:checked={formData.push_avaliacoes}
              class="sr-only peer"
            />
            <div class="w-11 h-6 bg-gray-200 peer-focus:outline-none peer-focus:ring-4 peer-focus:ring-blue-300 rounded-full peer peer-checked:after:translate-x-full peer-checked:after:border-white after:content-[''] after:absolute after:top-[2px] after:left-[2px] after:bg-white after:border-gray-300 after:border after:rounded-full after:h-5 after:w-5 after:transition-all peer-checked:bg-blue-600"></div>
          </label>
        </div>
        
        <div class="flex items-center justify-between">
          <div>
            <div class="font-medium text-gray-900">Mudanças de Status</div>
            <div class="text-sm text-gray-500">Notificação no navegador para mudanças de status</div>
          </div>
          <label class="relative inline-flex items-center cursor-pointer">
            <input
              type="checkbox"
              bind:checked={formData.push_status}
              class="sr-only peer"
            />
            <div class="w-11 h-6 bg-gray-200 peer-focus:outline-none peer-focus:ring-4 peer-focus:ring-blue-300 rounded-full peer peer-checked:after:translate-x-full peer-checked:after:border-white after:content-[''] after:absolute after:top-[2px] after:left-[2px] after:bg-white after:border-gray-300 after:border after:rounded-full after:h-5 after:w-5 after:transition-all peer-checked:bg-blue-600"></div>
          </label>
        </div>
        
        <div class="flex items-center justify-between">
          <div>
            <div class="font-medium text-gray-900">Lembretes de Avaliação</div>
            <div class="text-sm text-gray-500">Notificação no navegador para lembretes</div>
          </div>
          <label class="relative inline-flex items-center cursor-pointer">
            <input
              type="checkbox"
              bind:checked={formData.push_lembretes}
              class="sr-only peer"
            />
            <div class="w-11 h-6 bg-gray-200 peer-focus:outline-none peer-focus:ring-4 peer-focus:ring-blue-300 rounded-full peer peer-checked:after:translate-x-full peer-checked:after:border-white after:content-[''] after:absolute after:top-[2px] after:left-[2px] after:bg-white after:border-gray-300 after:border after:rounded-full after:h-5 after:w-5 after:transition-all peer-checked:bg-blue-600"></div>
          </label>
        </div>
        
        <div class="flex items-center justify-between">
          <div>
            <div class="font-medium text-gray-900">Relatórios</div>
            <div class="text-sm text-gray-500">Notificação no navegador para relatórios</div>
          </div>
          <label class="relative inline-flex items-center cursor-pointer">
            <input
              type="checkbox"
              bind:checked={formData.push_relatorios}
              class="sr-only peer"
            />
            <div class="w-11 h-6 bg-gray-200 peer-focus:outline-none peer-focus:ring-4 peer-focus:ring-blue-300 rounded-full peer peer-checked:after:translate-x-full peer-checked:after:border-white after:content-[''] after:absolute after:top-[2px] after:left-[2px] after:bg-white after:border-gray-300 after:border after:rounded-full after:h-5 after:w-5 after:transition-all peer-checked:bg-blue-600"></div>
          </label>
        </div>
      </div>
    </div>
    
    <!-- Configurações de Lembretes -->
    <div>
      <h3 class="text-lg font-medium text-gray-900 mb-4">Configurações de Lembretes</h3>
      
      <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
        <div>
          <label for="frequencia_lembretes" class="block text-sm font-medium text-gray-700 mb-2">
            Frequência dos Lembretes
          </label>
          <select
            id="frequencia_lembretes"
            bind:value={formData.frequencia_lembretes}
            class="w-full px-3 py-2 border border-gray-300 rounded-md focus:ring-2 focus:ring-blue-500 focus:border-transparent"
          >
            {#each frequencias as freq}
              <option value={freq.value}>{freq.label} - {freq.description}</option>
            {/each}
          </select>
        </div>
        
        <div>
          <label for="horario_lembretes" class="block text-sm font-medium text-gray-700 mb-2">
            Horário dos Lembretes
          </label>
          <Input
            id="horario_lembretes"
            type="time"
            bind:value={formData.horario_lembretes}
          />
          <p class="mt-1 text-sm text-gray-500">Horário para envio dos lembretes diários</p>
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
