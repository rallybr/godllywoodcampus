<script>
  import { onMount } from 'svelte';
  import { goto } from '$app/navigation';
  import { user, signIn, loading } from '$lib/stores/auth';
  import Button from '$lib/components/ui/Button.svelte';
  import Input from '$lib/components/ui/Input.svelte';
  import logo from '../../logos/logo.png';
  
  let email = '';
  let password = '';
  let error = '';
  let isLoading = false;
  
  onMount(() => {
    if ($user) {
      goto('/');
    }
  });
  
  async function handleSubmit() {
    if (!email || !password) {
      error = 'Por favor, preencha todos os campos';
      return;
    }
    
    isLoading = true;
    error = '';
    
    try {
      const { data, error: signInError } = await signIn(email, password);
      
      if (signInError) {
        error = signInError.message;
      } else {
        goto('/');
      }
    } catch (err) {
      error = 'Erro ao fazer login. Tente novamente.';
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
  <title>Login - IntelliMen Campus</title>
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
  
  <div class="w-full max-w-sm sm:max-w-md lg:max-w-xl space-y-6 sm:space-y-8 relative z-10">
    <!-- Logo and title -->
    <div class="text-center">
      <img src={logo} alt="IntelliMen Campus" class="mx-auto h-16 w-16 sm:h-20 sm:w-20 rounded-2xl shadow-lg ring-1 ring-white/40 object-contain bg-white/70 p-2" />
      <h2 class="mt-4 sm:mt-6 text-2xl sm:text-3xl lg:text-4xl font-bold ig-gradient">
        IntelliMen Campus
      </h2>
      <p class="mt-2 text-sm sm:text-base lg:text-lg text-gray-600">
        Sistema de avaliação de jovens
      </p>
    </div>
    
    <!-- Login form -->
    <div class="p-8 rounded-2xl bg-white/70 backdrop-blur-xl shadow-xl ring-1 ring-white/60 border border-white/60">
      <div class="text-center mb-6">
        <h3 class="text-xl sm:text-2xl font-bold text-gray-900">
          Acesse sua conta
        </h3>
        <p class="text-gray-600 mt-2 text-sm sm:text-base">
          Entre com suas credenciais para continuar
        </p>
      </div>
      
      <form on:submit|preventDefault={handleSubmit} class="space-y-6">
        <div>
          <label class="block text-sm font-medium text-gray-700 mb-2">
            E-mail
          </label>
          <input
            type="email"
            placeholder="seu@email.com"
            value={email}
            required
            on:input={(e) => email = e.target.value}
            on:keydown={handleKeydown}
            class="w-full px-4 py-3 rounded-xl bg-white/80 border border-gray-200 focus:ring-2 focus:ring-blue-500 focus:border-transparent outline-none shadow-sm"
          />
        </div>
        
        <div>
          <label class="block text-sm font-medium text-gray-700 mb-2">
            Senha
          </label>
          <input
            type="password"
            placeholder="Sua senha"
            value={password}
            required
            on:input={(e) => password = e.target.value}
            on:keydown={handleKeydown}
            class="w-full px-4 py-3 rounded-xl bg-white/80 border border-gray-200 focus:ring-2 focus:ring-blue-500 focus:border-transparent outline-none shadow-sm"
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
        
        <div class="flex flex-col sm:flex-row gap-4">
          <Button
            type="submit"
            variant="primary"
            size="lg"
            class="flex-1 bg-gradient-to-r from-blue-600 to-purple-600 hover:from-blue-500 hover:to-purple-500 shadow-lg hover:shadow-xl transition-all"
            loading={isLoading}
            disabled={isLoading}
          >
            {isLoading ? 'Entrando...' : 'Entrar'}
          </Button>

          <Button
            type="button"
            variant="outline"
            size="lg"
            class="flex-1"
            on:click={() => goto('/register')}
            disabled={isLoading}
          >
            Criar Conta
          </Button>
        </div>
        
        <div class="flex justify-start items-center text-xs sm:text-sm">
          <a href="/forgot-password" class="text-blue-600 hover:text-blue-800 transition-colors duration-300">
            Esqueceu sua senha?
          </a>
        </div>
      </form>
    </div>
    
    <!-- Footer -->
    <div class="text-center text-sm text-gray-500">
      <p>© 2024 IntelliMen Campus. Todos os direitos reservados.</p>
    </div>
  </div>
</div>
