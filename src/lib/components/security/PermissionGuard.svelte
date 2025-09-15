<script>
  import { onMount } from 'svelte';
  import { hasPermission, canAccess, canAccessLocation, getUserLevel, initializeSecurity } from '$lib/stores/security';
  import { user } from '$lib/stores/auth';
  
  export let permission = null;
  export let resource = null;
  export let action = null;
  export let estadoId = null;
  export let blocoId = null;
  export let regiaoId = null;
  export let igrejaId = null;
  export let minLevel = null;
  export let fallback = null;
  export let showError = false;
  
  let hasAccess = false;
  let loading = true;
  
  onMount(async () => {
    if ($user) {
      await initializeSecurity();
      checkAccess();
    }
    loading = false;
  });
  
  function checkAccess() {
    // Verificar permissão específica
    if (permission) {
      hasAccess = hasPermission(permission);
      return;
    }
    
    // Verificar acesso a recurso
    if (resource && action) {
      hasAccess = canAccess(resource, action);
      return;
    }
    
    // Verificar acesso por localização
    if (estadoId || blocoId || regiaoId || igrejaId) {
      hasAccess = canAccessLocation(estadoId, blocoId, regiaoId, igrejaId);
      return;
    }
    
    // Verificar nível hierárquico
    if (minLevel !== null) {
      const userLevel = getUserLevel();
      hasAccess = userLevel <= minLevel;
      return;
    }
    
    // Se nenhuma condição for especificada, permitir acesso
    hasAccess = true;
  }
  
  // Reagir a mudanças nas permissões
  $: if ($user && !loading) {
    checkAccess();
  }
</script>

{#if loading}
  <div class="flex items-center justify-center py-4">
    <div class="animate-spin rounded-full h-6 w-6 border-b-2 border-blue-600"></div>
  </div>
{:else if hasAccess}
  <slot />
{:else if fallback}
  <slot name="fallback" />
{:else if showError}
  <div class="bg-red-50 border border-red-200 rounded-lg p-4">
    <div class="flex items-center space-x-2">
      <svg class="w-5 h-5 text-red-500" fill="none" viewBox="0 0 24 24" stroke="currentColor">
        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-2.5L13.732 4c-.77-.833-1.732-.833-2.5 0L4.268 19.5c-.77.833.192 2.5 1.732 2.5z" />
      </svg>
      <p class="text-sm text-red-600 font-medium">Você não tem permissão para acessar este recurso.</p>
    </div>
  </div>
{:else}
  <!-- Não renderizar nada se não tiver acesso -->
{/if}
