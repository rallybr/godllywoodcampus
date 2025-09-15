<script>
  import { onMount } from 'svelte';
  import { supabase } from '$lib/utils/supabase';
  import Button from '$lib/components/ui/Button.svelte';
  import Card from '$lib/components/ui/Card.svelte';
  import Input from '$lib/components/ui/Input.svelte';
  import Select from '$lib/components/ui/Select.svelte';
  import FormValidator from './FormValidator.svelte';
  
  let configuracoes = {
    max_tentativas_login: 5,
    tempo_bloqueio_minutos: 30,
    sessao_timeout_horas: 24,
    log_retention_days: 90,
    rate_limit_requests: 100,
    rate_limit_window_minutes: 60,
    password_min_length: 8,
    password_require_special: true,
    password_require_numbers: true,
    password_require_uppercase: true,
    two_factor_enabled: false,
    email_verification_required: true,
    ip_whitelist: '',
    maintenance_mode: false
  };
  
  let loading = false;
  let error = '';
  let success = '';
  
  // Regras de validação
  const validationRules = {
    max_tentativas_login: { required: true, type: 'number', min: 1, max: 10 },
    tempo_bloqueio_minutos: { required: true, type: 'number', min: 5, max: 1440 },
    sessao_timeout_horas: { required: true, type: 'number', min: 1, max: 168 },
    log_retention_days: { required: true, type: 'number', min: 30, max: 365 },
    rate_limit_requests: { required: true, type: 'number', min: 10, max: 1000 },
    rate_limit_window_minutes: { required: true, type: 'number', min: 1, max: 1440 },
    password_min_length: { required: true, type: 'number', min: 6, max: 32 },
    ip_whitelist: { 
      type: 'text', 
      custom: (value) => {
        if (value && !/^(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}(,\s*)?)+$/.test(value)) {
          return 'Formato de IP inválido. Use: 192.168.1.1, 10.0.0.1';
        }
        return null;
      }
    }
  };
  
  onMount(async () => {
    await loadConfiguracoes();
  });
  
  // Função para carregar configurações
  async function loadConfiguracoes() {
    loading = true;
    error = '';
    
    try {
      // Aqui você carregaria as configurações do banco de dados
      // Por enquanto, vamos usar as configurações padrão
      await new Promise(resolve => setTimeout(resolve, 500));
      loading = false;
    } catch (err) {
      error = err.message;
      loading = false;
    }
  }
  
  // Função para salvar configurações
  async function salvarConfiguracoes() {
    loading = true;
    error = '';
    success = '';
    
    try {
      // Aqui você salvaria as configurações no banco de dados
      await new Promise(resolve => setTimeout(resolve, 1000));
      
      success = 'Configurações de segurança salvas com sucesso!';
      
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
  
  // Função para testar configurações
  function testarConfiguracoes() {
    // Aqui você testaria as configurações
    success = 'Configurações testadas com sucesso!';
    
    setTimeout(() => {
      success = '';
    }, 3000);
  }
  
  // Função para resetar configurações
  function resetarConfiguracoes() {
    configuracoes = {
      max_tentativas_login: 5,
      tempo_bloqueio_minutos: 30,
      sessao_timeout_horas: 24,
      log_retention_days: 90,
      rate_limit_requests: 100,
      rate_limit_window_minutes: 60,
      password_min_length: 8,
      password_require_special: true,
      password_require_numbers: true,
      password_require_uppercase: true,
      two_factor_enabled: false,
      email_verification_required: true,
      ip_whitelist: '',
      maintenance_mode: false
    };
  }
</script>

<FormValidator bind:data={configuracoes} rules={validationRules}>
  <div class="space-y-6">
    <!-- Header -->
    <div>
      <h1 class="text-2xl font-bold text-gray-900">Configurações de Segurança</h1>
      <p class="text-gray-600">Gerencie as configurações de segurança do sistema</p>
    </div>
    
    <!-- Configurações de Login -->
    <Card class="p-6">
      <h3 class="text-lg font-semibold text-gray-900 mb-4">Configurações de Login</h3>
      
      <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
        <Input
          label="Máximo de Tentativas de Login"
          type="number"
          bind:value={configuracoes.max_tentativas_login}
          min="1"
          max="10"
        />
        
        <Input
          label="Tempo de Bloqueio (minutos)"
          type="number"
          bind:value={configuracoes.tempo_bloqueio_minutos}
          min="5"
          max="1440"
        />
        
        <Input
          label="Timeout da Sessão (horas)"
          type="number"
          bind:value={configuracoes.sessao_timeout_horas}
          min="1"
          max="168"
        />
        
        <div class="flex items-center justify-between">
          <div>
            <h4 class="text-sm font-medium text-gray-900">Verificação de Email Obrigatória</h4>
            <p class="text-sm text-gray-500">Exigir verificação de email para novos usuários</p>
          </div>
          <label class="relative inline-flex items-center cursor-pointer">
            <input
              type="checkbox"
              bind:checked={configuracoes.email_verification_required}
              class="sr-only peer"
            />
            <div class="w-11 h-6 bg-gray-200 peer-focus:outline-none peer-focus:ring-4 peer-focus:ring-blue-300 rounded-full peer peer-checked:after:translate-x-full peer-checked:after:border-white after:content-[''] after:absolute after:top-[2px] after:left-[2px] after:bg-white after:border-gray-300 after:border after:rounded-full after:h-5 after:w-5 after:transition-all peer-checked:bg-blue-600"></div>
          </label>
        </div>
      </div>
    </Card>
    
    <!-- Configurações de Senha -->
    <Card class="p-6">
      <h3 class="text-lg font-semibold text-gray-900 mb-4">Configurações de Senha</h3>
      
      <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
        <Input
          label="Tamanho Mínimo da Senha"
          type="number"
          bind:value={configuracoes.password_min_length}
          min="6"
          max="32"
        />
        
        <div class="space-y-4">
          <div class="flex items-center justify-between">
            <div>
              <h4 class="text-sm font-medium text-gray-900">Exigir Caracteres Especiais</h4>
              <p class="text-sm text-gray-500">Exigir símbolos como !@#$%</p>
            </div>
            <label class="relative inline-flex items-center cursor-pointer">
              <input
                type="checkbox"
                bind:checked={configuracoes.password_require_special}
                class="sr-only peer"
              />
              <div class="w-11 h-6 bg-gray-200 peer-focus:outline-none peer-focus:ring-4 peer-focus:ring-blue-300 rounded-full peer peer-checked:after:translate-x-full peer-checked:after:border-white after:content-[''] after:absolute after:top-[2px] after:left-[2px] after:bg-white after:border-gray-300 after:border after:rounded-full after:h-5 after:w-5 after:transition-all peer-checked:bg-blue-600"></div>
            </label>
          </div>
          
          <div class="flex items-center justify-between">
            <div>
              <h4 class="text-sm font-medium text-gray-900">Exigir Números</h4>
              <p class="text-sm text-gray-500">Exigir pelo menos um número</p>
            </div>
            <label class="relative inline-flex items-center cursor-pointer">
              <input
                type="checkbox"
                bind:checked={configuracoes.password_require_numbers}
                class="sr-only peer"
              />
              <div class="w-11 h-6 bg-gray-200 peer-focus:outline-none peer-focus:ring-4 peer-focus:ring-blue-300 rounded-full peer peer-checked:after:translate-x-full peer-checked:after:border-white after:content-[''] after:absolute after:top-[2px] after:left-[2px] after:bg-white after:border-gray-300 after:border after:rounded-full after:h-5 after:w-5 after:transition-all peer-checked:bg-blue-600"></div>
            </label>
          </div>
          
          <div class="flex items-center justify-between">
            <div>
              <h4 class="text-sm font-medium text-gray-900">Exigir Maiúsculas</h4>
              <p class="text-sm text-gray-500">Exigir pelo menos uma letra maiúscula</p>
            </div>
            <label class="relative inline-flex items-center cursor-pointer">
              <input
                type="checkbox"
                bind:checked={configuracoes.password_require_uppercase}
                class="sr-only peer"
              />
              <div class="w-11 h-6 bg-gray-200 peer-focus:outline-none peer-focus:ring-4 peer-focus:ring-blue-300 rounded-full peer peer-checked:after:translate-x-full peer-checked:after:border-white after:content-[''] after:absolute after:top-[2px] after:left-[2px] after:bg-white after:border-gray-300 after:border after:rounded-full after:h-5 after:w-5 after:transition-all peer-checked:bg-blue-600"></div>
            </label>
          </div>
        </div>
      </div>
    </Card>
    
    <!-- Configurações de Rate Limiting -->
    <Card class="p-6">
      <h3 class="text-lg font-semibold text-gray-900 mb-4">Rate Limiting</h3>
      
      <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
        <Input
          label="Máximo de Requisições"
          type="number"
          bind:value={configuracoes.rate_limit_requests}
          min="10"
          max="1000"
        />
        
        <Input
          label="Janela de Tempo (minutos)"
          type="number"
          bind:value={configuracoes.rate_limit_window_minutes}
          min="1"
          max="1440"
        />
      </div>
    </Card>
    
    <!-- Configurações de Logs -->
    <Card class="p-6">
      <h3 class="text-lg font-semibold text-gray-900 mb-4">Configurações de Logs</h3>
      
      <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
        <Input
          label="Retenção de Logs (dias)"
          type="number"
          bind:value={configuracoes.log_retention_days}
          min="30"
          max="365"
        />
        
        <Input
          label="Lista de IPs Permitidos"
          type="text"
          bind:value={configuracoes.ip_whitelist}
          placeholder="192.168.1.1, 10.0.0.1"
        />
      </div>
    </Card>
    
    <!-- Configurações Avançadas -->
    <Card class="p-6">
      <h3 class="text-lg font-semibold text-gray-900 mb-4">Configurações Avançadas</h3>
      
      <div class="space-y-4">
        <div class="flex items-center justify-between">
          <div>
            <h4 class="text-sm font-medium text-gray-900">Autenticação de Dois Fatores</h4>
            <p class="text-sm text-gray-500">Exigir 2FA para todos os usuários</p>
          </div>
          <label class="relative inline-flex items-center cursor-pointer">
            <input
              type="checkbox"
              bind:checked={configuracoes.two_factor_enabled}
              class="sr-only peer"
            />
            <div class="w-11 h-6 bg-gray-200 peer-focus:outline-none peer-focus:ring-4 peer-focus:ring-blue-300 rounded-full peer peer-checked:after:translate-x-full peer-checked:after:border-white after:content-[''] after:absolute after:top-[2px] after:left-[2px] after:bg-white after:border-gray-300 after:border after:rounded-full after:h-5 after:w-5 after:transition-all peer-checked:bg-blue-600"></div>
          </label>
        </div>
        
        <div class="flex items-center justify-between">
          <div>
            <h4 class="text-sm font-medium text-gray-900">Modo de Manutenção</h4>
            <p class="text-sm text-gray-500">Bloquear acesso de usuários comuns</p>
          </div>
          <label class="relative inline-flex items-center cursor-pointer">
            <input
              type="checkbox"
              bind:checked={configuracoes.maintenance_mode}
              class="sr-only peer"
            />
            <div class="w-11 h-6 bg-gray-200 peer-focus:outline-none peer-focus:ring-4 peer-focus:ring-blue-300 rounded-full peer peer-checked:after:translate-x-full peer-checked:after:border-white after:content-[''] after:absolute after:top-[2px] after:left-[2px] after:bg-white after:border-gray-300 after:border after:rounded-full after:h-5 after:w-5 after:transition-all peer-checked:bg-blue-600"></div>
          </label>
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
        on:click={resetarConfiguracoes}
      >
        Resetar
      </Button>
      
      <Button
        variant="outline"
        on:click={testarConfiguracoes}
      >
        Testar
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
</FormValidator>
