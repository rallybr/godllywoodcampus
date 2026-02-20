<script>
  import { onMount } from 'svelte';
  import { page } from '$app/stores';
  import { goto } from '$app/navigation';
  import { supabase } from '$lib/utils/supabase';
  import { userProfile, hasRole, hasPermission } from '$lib/stores/auth';
  import Card from '$lib/components/ui/Card.svelte';
  import Button from '$lib/components/ui/Button.svelte';
  import UserProfileView from '$lib/components/usuarios/UserProfileView.svelte';
  import UserProfileImpersonated from '$lib/components/usuarios/UserProfileImpersonated.svelte';

  let loading = true;
  let error = '';
  let targetUser = null;
  let isOwnProfile = false;
  let viewMode = 'admin'; // 'admin' ou 'impersonated'

  // Extrair ID do usuário da URL
  $: userId = $page.params.id;

  // Verificar se é o próprio perfil
  $: isOwnProfile = $userProfile?.id === userId;

  async function loadUserProfile() {
    try {
      loading = true;
      error = '';

      console.log('=== CARREGANDO PERFIL DO USUÁRIO ===');
      console.log('ID do usuário:', userId);
      console.log('UserProfile atual:', $userProfile);

      if (!userId) {
        error = 'ID do usuário não fornecido';
        console.error('ID do usuário não fornecido');
        return;
      }

      // Buscar dados do usuário alvo
      console.log('Buscando dados do usuário no banco...');
      const { data: userData, error: userError } = await supabase
        .from('usuarios')
        .select(`
          *,
          user_roles!user_roles_user_id_fkey (
            *,
            roles (*)
          )
        `)
        .eq('id', userId)
        .single();

      console.log('Resultado da busca:', { userData, userError });

      if (userError) {
        console.error('Erro ao buscar usuário:', userError);
        if (userError.code === 'PGRST116') {
          error = 'Usuário não encontrado';
        } else {
          throw userError;
        }
        return;
      }

      targetUser = userData;
      console.log('Usuário carregado com sucesso:', targetUser);
    } catch (e) {
      error = e?.message || 'Erro ao carregar perfil do usuário';
      console.error('Erro ao carregar perfil:', e);
    } finally {
      loading = false;
      console.log('Loading finalizado. targetUser:', targetUser);
    }
  }

  function goBack() {
    goto('/usuarios');
  }

  function goToOwnProfile() {
    goto('/profile');
  }

  onMount(loadUserProfile);
</script>

<svelte:head>
  <title>{targetUser?.nome || 'Perfil'} - Godllywood Campus</title>
</svelte:head>

<div class="max-w-4xl mx-auto px-4 sm:px-6 py-6 sm:py-8">
  <!-- Header com navegação -->
  <div class="mb-6">
    <div class="flex items-center justify-between">
      <div class="flex items-center space-x-4">
        <Button variant="ghost" on:click={goBack}>
          <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 19l-7-7 7-7" />
          </svg>
          <span>Voltar</span>
        </Button>
        
        {#if isOwnProfile}
          <div class="flex items-center space-x-2 text-sm text-blue-600">
            <svg class="w-4 h-4" fill="currentColor" viewBox="0 0 20 20">
              <path fill-rule="evenodd" d="M10 9a3 3 0 100-6 3 3 0 000 6zm-7 9a7 7 0 1114 0H3z" clip-rule="evenodd" />
            </svg>
            <span>Seu perfil</span>
          </div>
        {/if}
      </div>

      <div class="flex items-center space-x-2">
        {#if !isOwnProfile && hasPermission('view_user_profiles')($userProfile)}
          <div class="flex items-center space-x-2 bg-gray-100 rounded-lg p-1">
            <button
              class="px-3 py-1 text-sm rounded-md transition-colors {viewMode === 'admin' ? 'bg-white text-gray-900 shadow-sm' : 'text-gray-600 hover:text-gray-900'}"
              on:click={() => viewMode = 'admin'}
            >
              Visão Admin
            </button>
            <button
              class="px-3 py-1 text-sm rounded-md transition-colors {viewMode === 'impersonated' ? 'bg-white text-gray-900 shadow-sm' : 'text-gray-600 hover:text-gray-900'}"
              on:click={() => viewMode = 'impersonated'}
            >
              Como o Usuário
            </button>
          </div>
        {/if}
        
        {#if isOwnProfile}
          <Button variant="outline" on:click={goToOwnProfile}>
            Editar Perfil
          </Button>
        {/if}
      </div>
    </div>
  </div>

  <!-- Verificação de permissão -->
  {#if !hasPermission('view_user_profiles')($userProfile)}
    <Card padding="p-6">
      <div class="text-center">
        <div class="text-yellow-500 mb-4">
          <svg class="w-12 h-12 mx-auto" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 15v2m-6 4h12a2 2 0 002-2v-6a2 2 0 00-2-2H6a2 2 0 00-2 2v6a2 2 0 002 2zm10-10V7a4 4 0 00-8 0v4h8z" />
          </svg>
        </div>
        <h3 class="text-lg font-semibold text-gray-900 mb-2">Acesso Negado</h3>
        <p class="text-gray-600 mb-4">
          Você não tem permissão para visualizar perfis de outros usuários.
        </p>
        <Button on:click={goBack}>Voltar</Button>
      </div>
    </Card>
  {:else}
    {#if loading}
      <div class="flex items-center justify-center py-12">
        <div class="animate-spin rounded-full h-8 w-8 border-b-2 border-blue-600"></div>
      </div>
    {:else if error}
      <Card padding="p-6">
        <div class="text-center">
          <div class="text-red-500 mb-4">
            <svg class="w-12 h-12 mx-auto" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-2.5L13.732 4c-.77-.833-1.964-.833-2.732 0L3.732 16.5c-.77.833.192 2.5 1.732 2.5z" />
            </svg>
          </div>
          <h3 class="text-lg font-semibold text-gray-900 mb-2">Erro</h3>
          <p class="text-gray-600 mb-4">{error}</p>
          <Button on:click={goBack}>Voltar para Usuários</Button>
        </div>
      </Card>
    {:else if targetUser}
      {#if viewMode === 'impersonated' && !isOwnProfile}
        <UserProfileImpersonated {targetUser} />
      {:else}
        <UserProfileView {targetUser} {isOwnProfile} />
      {/if}
    {/if}
  {/if}
</div>
