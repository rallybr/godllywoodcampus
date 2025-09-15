<script>
  import { onMount } from 'svelte';
  import { solicitarPermissaoNotificacao } from '$lib/stores/notificacoes';
  import { user } from '$lib/stores/auth';
  import Button from '$lib/components/ui/Button.svelte';
  import Card from '$lib/components/ui/Card.svelte';
  import Input from '$lib/components/ui/Input.svelte';
  import Select from '$lib/components/ui/Select.svelte';
  
  let configuracoes = {
    notificacoes_email: true,
    notificacoes_push: false,
    notificacoes_cadastro: true,
    notificacoes_avaliacao: true,
    notificacoes_aprovacao: true,
    notificacoes_transferencia: true,
    notificacoes_sistema: true,
    frequencia_email: 'imediato',
    horario_notificacoes: '09:00'
  };
  
  let loading = false;
  let error = '';
  let success = '';
  let permissaoNotificacao = false;
  
  onMount(async () => {
    await verificarPermissaoNotificacao();
    await carregarConfiguracoes();
  });
  
  // Função para verificar permissão de notificação
  async function verificarPermissaoNotificacao() {
    permissaoNotificacao = await solicitarPermissaoNotificacao();
  }
  
  // Função para carregar configurações do usuário
  async function carregarConfiguracoes() {
    // Aqui você carregaria as configurações do usuário do banco de dados
    // Por enquanto, vamos usar as configurações padrão
    loading = false;
  }
  
  // Função para salvar configurações
  async function salvarConfiguracoes() {
    loading = true;
    error = '';
    success = '';
    
    try {
      // Aqui você salvaria as configurações no banco de dados
      // Por enquanto, vamos simular o salvamento
      await new Promise(resolve => setTimeout(resolve, 1000));
      
      success = 'Configurações salvas com sucesso!';
      
      // Limpar mensagem de sucesso após 3 segundos
      setTimeout(() => {
        success = '';
      }, 3000);
      
    } catch (err) {
      error = err.message;
    } finally {
      loading = false;
    }
  }
  
  // Função para solicitar permissão de notificação
  async function solicitarPermissao() {
    permissaoNotificacao = await solicitarPermissaoNotificacao();
    
    if (permissaoNotificacao) {
      configuracoes.notificacoes_push = true;
      success = 'Permissão de notificação concedida!';
    } else {
      error = 'Permissão de notificação negada. Você pode ativar manualmente nas configurações do navegador.';
    }
  }
  
  // Função para testar notificação
  function testarNotificacao() {
    if (permissaoNotificacao) {
      new Notification('Teste de Notificação', {
        body: 'Esta é uma notificação de teste do IntelliMen Campus',
        icon: '/favicon.svg'
      });
      success = 'Notificação de teste enviada!';
    } else {
      error = 'Permissão de notificação não concedida.';
    }
  }
</script>

<div class="space-y-6">
  <!-- Header -->
  <div>
    <h1 class="text-2xl font-bold text-gray-900">Configurações de Notificação</h1>
    <p class="text-gray-600">Gerencie suas preferências de notificação</p>
  </div>
  
  <!-- Status da Permissão -->
  <Card class="p-6">
    <h3 class="text-lg font-semibold text-gray-900 mb-4">Permissões do Navegador</h3>
    
    <div class="flex items-center justify-between">
      <div>
        <h4 class="text-sm font-medium text-gray-900">Notificações Push</h4>
        <p class="text-sm text-gray-500">
          {permissaoNotificacao ? 'Permitido' : 'Negado'}
        </p>
      </div>
      
      <div class="flex space-x-2">
        {#if !permissaoNotificacao}
          <Button
            variant="primary"
            size="sm"
            on:click={solicitarPermissao}
          >
            Solicitar Permissão
          </Button>
        {/if}
        
        {#if permissaoNotificacao}
          <Button
            variant="outline"
            size="sm"
            on:click={testarNotificacao}
          >
            Testar Notificação
          </Button>
        {/if}
      </div>
    </div>
  </Card>
  
  <!-- Configurações de Notificação -->
  <Card class="p-6">
    <h3 class="text-lg font-semibold text-gray-900 mb-4">Tipos de Notificação</h3>
    
    <div class="space-y-4">
      <div class="flex items-center justify-between">
        <div>
          <h4 class="text-sm font-medium text-gray-900">Notificações por Email</h4>
          <p class="text-sm text-gray-500">Receber notificações por email</p>
        </div>
        <label class="relative inline-flex items-center cursor-pointer">
          <input
            type="checkbox"
            bind:checked={configuracoes.notificacoes_email}
            class="sr-only peer"
          />
          <div class="w-11 h-6 bg-gray-200 peer-focus:outline-none peer-focus:ring-4 peer-focus:ring-blue-300 rounded-full peer peer-checked:after:translate-x-full peer-checked:after:border-white after:content-[''] after:absolute after:top-[2px] after:left-[2px] after:bg-white after:border-gray-300 after:border after:rounded-full after:h-5 after:w-5 after:transition-all peer-checked:bg-blue-600"></div>
        </label>
      </div>
      
      <div class="flex items-center justify-between">
        <div>
          <h4 class="text-sm font-medium text-gray-900">Notificações Push</h4>
          <p class="text-sm text-gray-500">Receber notificações no navegador</p>
        </div>
        <label class="relative inline-flex items-center cursor-pointer">
          <input
            type="checkbox"
            bind:checked={configuracoes.notificacoes_push}
            disabled={!permissaoNotificacao}
            class="sr-only peer"
          />
          <div class="w-11 h-6 bg-gray-200 peer-focus:outline-none peer-focus:ring-4 peer-focus:ring-blue-300 rounded-full peer peer-checked:after:translate-x-full peer-checked:after:border-white after:content-[''] after:absolute after:top-[2px] after:left-[2px] after:bg-white after:border-gray-300 after:border after:rounded-full after:h-5 after:w-5 after:transition-all peer-checked:bg-blue-600 disabled:opacity-50"></div>
        </label>
      </div>
    </div>
  </Card>
  
  <!-- Configurações por Tipo -->
  <Card class="p-6">
    <h3 class="text-lg font-semibold text-gray-900 mb-4">Notificações por Tipo</h3>
    
    <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
      <div class="space-y-4">
        <div class="flex items-center justify-between">
          <div>
            <h4 class="text-sm font-medium text-gray-900">Cadastros</h4>
            <p class="text-sm text-gray-500">Novos jovens cadastrados</p>
          </div>
          <label class="relative inline-flex items-center cursor-pointer">
            <input
              type="checkbox"
              bind:checked={configuracoes.notificacoes_cadastro}
              class="sr-only peer"
            />
            <div class="w-11 h-6 bg-gray-200 peer-focus:outline-none peer-focus:ring-4 peer-focus:ring-blue-300 rounded-full peer peer-checked:after:translate-x-full peer-checked:after:border-white after:content-[''] after:absolute after:top-[2px] after:left-[2px] after:bg-white after:border-gray-300 after:border after:rounded-full after:h-5 after:w-5 after:transition-all peer-checked:bg-blue-600"></div>
          </label>
        </div>
        
        <div class="flex items-center justify-between">
          <div>
            <h4 class="text-sm font-medium text-gray-900">Avaliações</h4>
            <p class="text-sm text-gray-500">Novas avaliações de jovens</p>
          </div>
          <label class="relative inline-flex items-center cursor-pointer">
            <input
              type="checkbox"
              bind:checked={configuracoes.notificacoes_avaliacao}
              class="sr-only peer"
            />
            <div class="w-11 h-6 bg-gray-200 peer-focus:outline-none peer-focus:ring-4 peer-focus:ring-blue-300 rounded-full peer peer-checked:after:translate-x-full peer-checked:after:border-white after:content-[''] after:absolute after:top-[2px] after:left-[2px] after:bg-white after:border-gray-300 after:border after:rounded-full after:h-5 after:w-5 after:transition-all peer-checked:bg-blue-600"></div>
          </label>
        </div>
        
        <div class="flex items-center justify-between">
          <div>
            <h4 class="text-sm font-medium text-gray-900">Aprovações</h4>
            <p class="text-sm text-gray-500">Mudanças de status de aprovação</p>
          </div>
          <label class="relative inline-flex items-center cursor-pointer">
            <input
              type="checkbox"
              bind:checked={configuracoes.notificacoes_aprovacao}
              class="sr-only peer"
            />
            <div class="w-11 h-6 bg-gray-200 peer-focus:outline-none peer-focus:ring-4 peer-focus:ring-blue-300 rounded-full peer peer-checked:after:translate-x-full peer-checked:after:border-white after:content-[''] after:absolute after:top-[2px] after:left-[2px] after:bg-white after:border-gray-300 after:border after:rounded-full after:h-5 after:w-5 after:transition-all peer-checked:bg-blue-600"></div>
          </label>
        </div>
      </div>
      
      <div class="space-y-4">
        <div class="flex items-center justify-between">
          <div>
            <h4 class="text-sm font-medium text-gray-900">Transferências</h4>
            <p class="text-sm text-gray-500">Transferências de liderança</p>
          </div>
          <label class="relative inline-flex items-center cursor-pointer">
            <input
              type="checkbox"
              bind:checked={configuracoes.notificacoes_transferencia}
              class="sr-only peer"
            />
            <div class="w-11 h-6 bg-gray-200 peer-focus:outline-none peer-focus:ring-4 peer-focus:ring-blue-300 rounded-full peer peer-checked:after:translate-x-full peer-checked:after:border-white after:content-[''] after:absolute after:top-[2px] after:left-[2px] after:bg-white after:border-gray-300 after:border after:rounded-full after:h-5 after:w-5 after:transition-all peer-checked:bg-blue-600"></div>
          </label>
        </div>
        
        <div class="flex items-center justify-between">
          <div>
            <h4 class="text-sm font-medium text-gray-900">Sistema</h4>
            <p class="text-sm text-gray-500">Notificações do sistema</p>
          </div>
          <label class="relative inline-flex items-center cursor-pointer">
            <input
              type="checkbox"
              bind:checked={configuracoes.notificacoes_sistema}
              class="sr-only peer"
            />
            <div class="w-11 h-6 bg-gray-200 peer-focus:outline-none peer-focus:ring-4 peer-focus:ring-blue-300 rounded-full peer peer-checked:after:translate-x-full peer-checked:after:border-white after:content-[''] after:absolute after:top-[2px] after:left-[2px] after:bg-white after:border-gray-300 after:border after:rounded-full after:h-5 after:w-5 after:transition-all peer-checked:bg-blue-600"></div>
          </label>
        </div>
      </div>
    </div>
  </Card>
  
  <!-- Configurações Avançadas -->
  <Card class="p-6">
    <h3 class="text-lg font-semibold text-gray-900 mb-4">Configurações Avançadas</h3>
    
    <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
      <div>
        <label class="block text-sm font-medium text-gray-700 mb-2">
          Frequência de Emails
        </label>
        <Select
          bind:value={configuracoes.frequencia_email}
          options={[
            { value: 'imediato', label: 'Imediato' },
            { value: 'diario', label: 'Diário' },
            { value: 'semanal', label: 'Semanal' },
            { value: 'mensal', label: 'Mensal' }
          ]}
        />
      </div>
      
      <div>
        <label class="block text-sm font-medium text-gray-700 mb-2">
          Horário de Notificações
        </label>
        <Input
          type="time"
          bind:value={configuracoes.horario_notificacoes}
        />
      </div>
    </div>
  </Card>
  
  <!-- Mensagens de Status -->
  {#if success}
    <div class="bg-green-50 border border-green-200 rounded-lg p-4">
      <div class="flex items-center space-x-2">
        <svg class="w-5 h-5 text-green-500" fill="none" viewBox="0 0 24 24" stroke="currentColor">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7" />
        </svg>
        <p class="text-sm text-green-600 font-medium">{success}</p>
      </div>
    </div>
  {/if}
  
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
  
  <!-- Botões de Ação -->
  <div class="flex justify-end space-x-3">
    <Button
      variant="outline"
      on:click={() => {
        // Resetar configurações
        configuracoes = {
          notificacoes_email: true,
          notificacoes_push: false,
          notificacoes_cadastro: true,
          notificacoes_avaliacao: true,
          notificacoes_aprovacao: true,
          notificacoes_transferencia: true,
          notificacoes_sistema: true,
          frequencia_email: 'imediato',
          horario_notificacoes: '09:00'
        };
      }}
    >
      Resetar
    </Button>
    
    <Button
      variant="primary"
      on:click={salvarConfiguracoes}
      loading={loading}
      disabled={loading}
    >
      {loading ? 'Salvando...' : 'Salvar Configurações'}
    </Button>
  </div>
</div>
