<script>
  import { onMount } from 'svelte';
  import { goto } from '$app/navigation';
  import { page } from '$app/stores';
  import { user, userProfile } from '$lib/stores/auth';
  
  let loading = true;
  let error = '';
  
  onMount(async () => {
    try {
      // Wait a moment for auth state to update
      await new Promise(resolve => setTimeout(resolve, 1000));
      
      if ($user) {
        // Check if user has completed profile
        if ($userProfile) {
          // Profile exists, redirect to dashboard
          goto('/');
        } else {
          // Profile doesn't exist, redirect to complete profile
          goto('/complete-profile');
        }
      } else {
        // No user, redirect to login
        goto('/login');
      }
    } catch (err) {
      error = 'Erro ao processar confirmação de email';
      console.error('Auth callback error:', err);
    } finally {
      loading = false;
    }
  });
</script>

<svelte:head>
  <title>Confirmando Email - IntelliMen Campus</title>
</svelte:head>

<div class="min-h-screen bg-gray-100 flex items-center justify-center">
  <div class="bg-white rounded-lg shadow-md p-8 text-center">
    {#if loading}
      <div class="animate-spin rounded-full h-12 w-12 border-b-2 border-blue-600 mx-auto mb-4"></div>
      <h2 class="text-xl font-semibold text-gray-900 mb-2">Confirmando seu email...</h2>
      <p class="text-gray-600">Aguarde enquanto processamos sua confirmação.</p>
    {:else if error}
      <div class="w-12 h-12 bg-red-100 rounded-full flex items-center justify-center mx-auto mb-4">
        <svg class="w-6 h-6 text-red-600" fill="none" viewBox="0 0 24 24" stroke="currentColor">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8v4m0 4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
        </svg>
      </div>
      <h2 class="text-xl font-semibold text-gray-900 mb-2">Erro na Confirmação</h2>
      <p class="text-gray-600 mb-4">{error}</p>
      <button
        class="bg-blue-600 text-white px-4 py-2 rounded-lg hover:bg-blue-700"
        on:click={() => goto('/login')}
      >
        Ir para Login
      </button>
    {:else}
      <div class="w-12 h-12 bg-green-100 rounded-full flex items-center justify-center mx-auto mb-4">
        <svg class="w-6 h-6 text-green-600" fill="none" viewBox="0 0 24 24" stroke="currentColor">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7" />
        </svg>
      </div>
      <h2 class="text-xl font-semibold text-gray-900 mb-2">Email Confirmado!</h2>
      <p class="text-gray-600">Redirecionando...</p>
    {/if}
  </div>
</div>
