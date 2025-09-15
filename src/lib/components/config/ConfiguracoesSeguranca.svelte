<script>
  import { onMount } from 'svelte';
  import { 
    configuracoesSeguranca, 
    loadingConfiguracoes, 
    errorConfiguracoes,
    carregarConfiguracoes,
    salvarConfiguracoesSeguranca 
  } from '$lib/stores/configuracoes';
  import { supabase } from '$lib/utils/supabase';
  import Card from '$lib/components/ui/Card.svelte';
  import Button from '$lib/components/ui/Button.svelte';
  import Input from '$lib/components/ui/Input.svelte';
  
  let formData = {
    autenticacao_2f: false,
    sessao_duracao: 24,
    login_automatico: false,
    notificar_logins: true,
    backup_automatico: true,
    criptografia_dados: true
  };
  
  let senhaAtual = '';
  let novaSenha = '';
  let confirmarSenha = '';
  let senhaErrors = {};
  let alterandoSenha = false;
  
  onMount(() => {
    carregarConfiguracoes();
    
    // Subscribe to store changes
    const unsubscribe = configuracoesSeguranca.subscribe(config => {
      formData = { ...config };
    });
    
    return unsubscribe;
  });
  
  async function handleSubmit() {
    try {
      await salvarConfiguracoesSeguranca(formData);
      alert('Configurações de segurança salvas com sucesso!');
    } catch (err) {
      console.error('Erro ao salvar:', err);
    }
  }
  
  function validateSenha() {
    senhaErrors = {};
    
    if (!senhaAtual) {
      senhaErrors.senhaAtual = 'Senha atual é obrigatória';
    }
    
    if (!novaSenha) {
      senhaErrors.novaSenha = 'Nova senha é obrigatória';
    } else if (novaSenha.length < 6) {
      senhaErrors.novaSenha = 'Nova senha deve ter pelo menos 6 caracteres';
    }
    
    if (novaSenha !== confirmarSenha) {
      senhaErrors.confirmarSenha = 'As senhas não coincidem';
    }
    
    return Object.keys(senhaErrors).length === 0;
  }
  
  async function handleAlterarSenha() {
    if (!validateSenha()) return;
    
    alterandoSenha = true;
    try {
      const { error } = await supabase.auth.updateUser({
        password: novaSenha
      });
      
      if (error) throw error;
      
      alert('Senha alterada com sucesso!');
      senhaAtual = '';
      novaSenha = '';
      confirmarSenha = '';
      senhaErrors = {};
    } catch (err) {
      console.error('Erro ao alterar senha:', err);
      alert('Erro ao alterar senha: ' + err.message);
    } finally {
      alterandoSenha = false;
    }
  }
  
  const opcoesDuracaoSessao = [
    { value: 1, label: '1 hora' },
    { value: 4, label: '4 horas' },
    { value: 8, label: '8 horas' },
    { value: 12, label: '12 horas' },
    { value: 24, label: '24 horas' },
    { value: 168, label: '7 dias' },
    { value: 720, label: '30 dias' }
  ];
</script>

<Card class="p-6">
  <div class="mb-6">
    <h2 class="text-2xl font-bold text-gray-900">Configurações de Segurança</h2>
    <p class="text-gray-600 mt-2">Gerencie a segurança da sua conta e dados</p>
  </div>
  
  <div class="space-y-8">
    <!-- Alterar Senha -->
    <div>
      <h3 class="text-lg font-medium text-gray-900 mb-4">Alterar Senha</h3>
      
      <form on:submit|preventDefault={handleAlterarSenha} class="space-y-4 max-w-md">
        <div>
          <label for="senhaAtual" class="block text-sm font-medium text-gray-700 mb-2">
            Senha Atual
          </label>
          <Input
            id="senhaAtual"
            type="password"
            bind:value={senhaAtual}
            placeholder="Digite sua senha atual"
            class={senhaErrors.senhaAtual ? 'border-red-300 focus:ring-red-500' : ''}
          />
          {#if senhaErrors.senhaAtual}
            <p class="mt-1 text-sm text-red-600">{senhaErrors.senhaAtual}</p>
          {/if}
        </div>
        
        <div>
          <label for="novaSenha" class="block text-sm font-medium text-gray-700 mb-2">
            Nova Senha
          </label>
          <Input
            id="novaSenha"
            type="password"
            bind:value={novaSenha}
            placeholder="Digite sua nova senha"
            class={senhaErrors.novaSenha ? 'border-red-300 focus:ring-red-500' : ''}
          />
          {#if senhaErrors.novaSenha}
            <p class="mt-1 text-sm text-red-600">{senhaErrors.novaSenha}</p>
          {/if}
        </div>
        
        <div>
          <label for="confirmarSenha" class="block text-sm font-medium text-gray-700 mb-2">
            Confirmar Nova Senha
          </label>
          <Input
            id="confirmarSenha"
            type="password"
            bind:value={confirmarSenha}
            placeholder="Confirme sua nova senha"
            class={senhaErrors.confirmarSenha ? 'border-red-300 focus:ring-red-500' : ''}
          />
          {#if senhaErrors.confirmarSenha}
            <p class="mt-1 text-sm text-red-600">{senhaErrors.confirmarSenha}</p>
          {/if}
        </div>
        
        <Button
          type="submit"
          disabled={alterandoSenha}
          class="w-full"
        >
          {alterandoSenha ? 'Alterando...' : 'Alterar Senha'}
        </Button>
      </form>
    </div>
    
    <!-- Configurações de Segurança -->
    <form on:submit|preventDefault={handleSubmit} class="space-y-6">
      <div>
        <h3 class="text-lg font-medium text-gray-900 mb-4">Configurações de Segurança</h3>
        
        <div class="space-y-4">
          <div class="flex items-center justify-between">
            <div>
              <div class="font-medium text-gray-900">Autenticação de Dois Fatores (2FA)</div>
              <div class="text-sm text-gray-500">Adicionar uma camada extra de segurança à sua conta</div>
            </div>
            <label class="relative inline-flex items-center cursor-pointer">
              <input
                type="checkbox"
                bind:checked={formData.autenticacao_2f}
                class="sr-only peer"
              />
              <div class="w-11 h-6 bg-gray-200 peer-focus:outline-none peer-focus:ring-4 peer-focus:ring-blue-300 rounded-full peer peer-checked:after:translate-x-full peer-checked:after:border-white after:content-[''] after:absolute after:top-[2px] after:left-[2px] after:bg-white after:border-gray-300 after:border after:rounded-full after:h-5 after:w-5 after:transition-all peer-checked:bg-blue-600"></div>
            </label>
          </div>
          
          <div class="flex items-center justify-between">
            <div>
              <div class="font-medium text-gray-900">Login Automático</div>
              <div class="text-sm text-gray-500">Manter-se logado mesmo após fechar o navegador</div>
            </div>
            <label class="relative inline-flex items-center cursor-pointer">
              <input
                type="checkbox"
                bind:checked={formData.login_automatico}
                class="sr-only peer"
              />
              <div class="w-11 h-6 bg-gray-200 peer-focus:outline-none peer-focus:ring-4 peer-focus:ring-blue-300 rounded-full peer peer-checked:after:translate-x-full peer-checked:after:border-white after:content-[''] after:absolute after:top-[2px] after:left-[2px] after:bg-white after:border-gray-300 after:border after:rounded-full after:h-5 after:w-5 after:transition-all peer-checked:bg-blue-600"></div>
            </label>
          </div>
          
          <div class="flex items-center justify-between">
            <div>
              <div class="font-medium text-gray-900">Notificar Logins</div>
              <div class="text-sm text-gray-500">Receber notificação quando alguém fizer login na sua conta</div>
            </div>
            <label class="relative inline-flex items-center cursor-pointer">
              <input
                type="checkbox"
                bind:checked={formData.notificar_logins}
                class="sr-only peer"
              />
              <div class="w-11 h-6 bg-gray-200 peer-focus:outline-none peer-focus:ring-4 peer-focus:ring-blue-300 rounded-full peer peer-checked:after:translate-x-full peer-checked:after:border-white after:content-[''] after:absolute after:top-[2px] after:left-[2px] after:bg-white after:border-gray-300 after:border after:rounded-full after:h-5 after:w-5 after:transition-all peer-checked:bg-blue-600"></div>
            </label>
          </div>
          
          <div class="flex items-center justify-between">
            <div>
              <div class="font-medium text-gray-900">Backup Automático</div>
              <div class="text-sm text-gray-500">Fazer backup automático dos seus dados</div>
            </div>
            <label class="relative inline-flex items-center cursor-pointer">
              <input
                type="checkbox"
                bind:checked={formData.backup_automatico}
                class="sr-only peer"
              />
              <div class="w-11 h-6 bg-gray-200 peer-focus:outline-none peer-focus:ring-4 peer-focus:ring-blue-300 rounded-full peer peer-checked:after:translate-x-full peer-checked:after:border-white after:content-[''] after:absolute after:top-[2px] after:left-[2px] after:bg-white after:border-gray-300 after:border after:rounded-full after:h-5 after:w-5 after:transition-all peer-checked:bg-blue-600"></div>
            </label>
          </div>
          
          <div class="flex items-center justify-between">
            <div>
              <div class="font-medium text-gray-900">Criptografia de Dados</div>
              <div class="text-sm text-gray-500">Criptografar dados sensíveis armazenados</div>
            </div>
            <label class="relative inline-flex items-center cursor-pointer">
              <input
                type="checkbox"
                bind:checked={formData.criptografia_dados}
                class="sr-only peer"
              />
              <div class="w-11 h-6 bg-gray-200 peer-focus:outline-none peer-focus:ring-4 peer-focus:ring-blue-300 rounded-full peer peer-checked:after:translate-x-full peer-checked:after:border-white after:content-[''] after:absolute after:top-[2px] after:left-[2px] after:bg-white after:border-gray-300 after:border after:rounded-full after:h-5 after:w-5 after:transition-all peer-checked:bg-blue-600"></div>
            </label>
          </div>
        </div>
      </div>
      
      <!-- Duração da Sessão -->
      <div>
        <h3 class="text-lg font-medium text-gray-900 mb-4">Duração da Sessão</h3>
        
        <div>
          <label for="sessao_duracao" class="block text-sm font-medium text-gray-700 mb-2">
            Tempo de Sessão Ativa
          </label>
          <select
            id="sessao_duracao"
            bind:value={formData.sessao_duracao}
            class="w-full px-3 py-2 border border-gray-300 rounded-md focus:ring-2 focus:ring-blue-500 focus:border-transparent"
          >
            {#each opcoesDuracaoSessao as opcao}
              <option value={opcao.value}>{opcao.label}</option>
            {/each}
          </select>
          <p class="mt-1 text-sm text-gray-500">Tempo que você permanecerá logado sem atividade</p>
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
  </div>
  
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
