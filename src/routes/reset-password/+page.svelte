<script>
  import { onMount } from 'svelte';
  import { goto } from '$app/navigation';
  import { page } from '$app/stores';
  import { supabase } from '$lib/utils/supabase';
  import Button from '$lib/components/ui/Button.svelte';
  
  let password = '';
  let confirmPassword = '';
  let isLoading = false;
  let error = '';
  let success = false;
  let isValidToken = false;
  
  onMount(async () => {
    try {
      // Verificar se há um token de recuperação na URL
      const { data, error: sessionError } = await supabase.auth.getSession();
      
      if (sessionError) {
        error = 'Link inválido ou expirado. Solicite um novo link de recuperação.';
        return;
      }
      
      if (data.session) {
        isValidToken = true;
      } else {
        error = 'Link inválido ou expirado. Solicite um novo link de recuperação.';
      }
    } catch (err) {
      error = 'Erro ao verificar o link. Tente novamente.';
      console.error('Reset password error:', err);
    }
  });
  
  async function handleSubmit() {
    if (!password || !confirmPassword) {
      error = 'Por favor, preencha todos os campos';
      return;
    }
    
    if (password !== confirmPassword) {
      error = 'As senhas não coincidem';
      return;
    }
    
    if (password.length < 6) {
      error = 'A senha deve ter pelo menos 6 caracteres';
      return;
    }
    
    isLoading = true;
    error = '';
    
    try {
      const { error: updateError } = await supabase.auth.updateUser({
        password: password
      });
      
      if (updateError) {
        error = updateError.message;
      } else {
        success = true;
        // Redirecionar para login após 3 segundos
        setTimeout(() => {
          goto('/login');
        }, 3000);
      }
    } catch (err) {
      error = 'Erro ao atualizar senha. Tente novamente.';
      console.error('Update password error:', err);
    } finally {
      isLoading = false;
    }
  }
  
  function handleKeydown(event) {
    if (event.key === 'Enter') {
      handleSubmit();
    }
  }
</script>

<svelte:head>
  <title>Redefinir Senha - IntelliMen Campus</title>
</svelte:head>

<div class="min-h-screen flex items-center justify-center py-4 sm:py-8 lg:py-12 px-4 sm:px-6 lg:px-8 relative overflow-hidden" style="background-color: var(--fb-gray-light);">
  <!-- Background effects -->
  <div class="absolute inset-0 bg-gradient-to-r from-blue-500/5 via-purple-500/5 to-pink-500/5"></div>
  <div class="absolute top-0 left-0 w-full h-full bg-[radial-gradient(ellipse_at_center,_var(--tw-gradient-stops))] from-blue-500/3 via-transparent to-transparent"></div>
  
  <!-- Floating particles effect -->
  <div class="absolute inset-0 overflow-hidden">
    <div class="absolute top-1/4 left-1/4 w-2 h-2 bg-blue-500 rounded-full animate-pulse opacity-60"></div>
    <div class="absolute top-3/4 right-1/4 w-1 h-1 bg-pink-500 rounded-full animate-pulse opacity-40"></div>
    <div class="absolute top-1/2 right-1/3 w-1.5 h-1.5 bg-purple-500 rounded-full animate-pulse opacity-50"></div>
    <div class="absolute bottom-1/4 left-1/3 w-1 h-1 bg-blue-400 rounded-full animate-pulse opacity-30"></div>
  </div>
  
  <div class="w-full max-w-sm sm:max-w-md lg:max-w-lg space-y-6 sm:space-y-8 relative z-10">
    <!-- Logo and title -->
    <div class="text-center">
      <img src="/logo.png" alt="IntelliMen Campus" class="mx-auto h-16 w-16 sm:h-20 sm:w-20 rounded-2xl shadow-lg ring-1 ring-white/40 object-contain bg-white/70 p-2" />
      <h2 class="mt-4 sm:mt-6 text-2xl sm:text-3xl lg:text-4xl font-bold ig-gradient">
        IntelliMen Campus
      </h2>
      <p class="mt-2 text-sm sm:text-base lg:text-lg text-gray-600">
        Sistema de avaliação de jovens
      </p>
    </div>
    
    {#if success}
      <!-- Success message -->
      <div class="fb-card p-8 text-center">
        <div class="w-16 h-16 bg-green-100 rounded-full flex items-center justify-center mx-auto mb-4">
          <svg class="w-8 h-8 text-green-600" fill="none" viewBox="0 0 24 24" stroke="currentColor">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7" />
          </svg>
        </div>
        
        <h3 class="text-xl font-semibold text-gray-900 mb-2">Senha redefinida!</h3>
        <p class="text-gray-600 mb-6">
          Sua senha foi atualizada com sucesso.
        </p>
        <p class="text-sm text-gray-500 mb-6">
          Você será redirecionado para a página de login em alguns segundos.
        </p>
        
        <Button
          variant="primary"
          class="w-full"
          on:click={() => goto('/login')}
        >
          Ir para Login
        </Button>
      </div>
    {:else if !isValidToken}
      <!-- Invalid token message -->
      <div class="fb-card p-8 text-center">
        <div class="w-16 h-16 bg-red-100 rounded-full flex items-center justify-center mx-auto mb-4">
          <svg class="w-8 h-8 text-red-600" fill="none" viewBox="0 0 24 24" stroke="currentColor">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8v4m0 4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
          </svg>
        </div>
        
        <h3 class="text-xl font-semibold text-gray-900 mb-2">Link inválido</h3>
        <p class="text-gray-600 mb-6">
          Este link de recuperação é inválido ou expirou.
        </p>
        <p class="text-sm text-gray-500 mb-6">
          Solicite um novo link de recuperação de senha.
        </p>
        
        <div class="space-y-3">
          <Button
            variant="primary"
            class="w-full"
            on:click={() => goto('/forgot-password')}
          >
            Solicitar Novo Link
          </Button>
          
          <Button
            variant="outline"
            class="w-full"
            on:click={() => goto('/login')}
          >
            Voltar ao Login
          </Button>
        </div>
      </div>
    {:else}
      <!-- Reset password form -->
      <div class="fb-card p-8">
        <div class="text-center mb-6">
          <h3 class="text-xl sm:text-2xl font-bold text-gray-900">
            Redefinir Senha
          </h3>
          <p class="text-gray-600 mt-2 text-sm sm:text-base">
            Digite sua nova senha
          </p>
        </div>
        
        <form on:submit|preventDefault={handleSubmit} class="space-y-6">
          <div>
            <label for="password" class="block text-sm font-medium text-gray-700 mb-2">
              Nova Senha
            </label>
            <input
              id="password"
              type="password"
              placeholder="Digite sua nova senha"
              value={password}
              required
              minlength="6"
              on:input={(e) => password = e.target.value}
              on:keydown={handleKeydown}
              class="w-full px-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent transition-colors"
            />
            <p class="text-xs text-gray-500 mt-1">Mínimo de 6 caracteres</p>
          </div>
          
          <div>
            <label for="confirmPassword" class="block text-sm font-medium text-gray-700 mb-2">
              Confirmar Nova Senha
            </label>
            <input
              id="confirmPassword"
              type="password"
              placeholder="Confirme sua nova senha"
              value={confirmPassword}
              required
              minlength="6"
              on:input={(e) => confirmPassword = e.target.value}
              on:keydown={handleKeydown}
              class="w-full px-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent transition-colors"
            />
          </div>
          
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
          
          <div class="space-y-4">
            <Button
              type="submit"
              variant="primary"
              size="lg"
              class="w-full"
              loading={isLoading}
              disabled={isLoading}
            >
              {isLoading ? 'Atualizando...' : 'Redefinir Senha'}
            </Button>
            
            <Button
              type="button"
              variant="outline"
              size="lg"
              class="w-full"
              on:click={() => goto('/login')}
            >
              <svg class="w-5 h-5 mr-2" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M10 19l-7-7m0 0l7-7m-7 7h18" />
              </svg>
              Voltar ao Login
            </Button>
          </div>
        </form>
      </div>
    {/if}
    
    <!-- Footer -->
    <div class="text-center text-sm text-gray-500">
      <p>© 2024 IntelliMen Campus. Todos os direitos reservados.</p>
    </div>
  </div>
</div>
