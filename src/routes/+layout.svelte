<script lang="ts">
  import { onMount } from 'svelte';
  import { user, loading, userProfile, hasRole } from '$lib/stores/auth';
  import { getUserLevelName, canCadastrarJovem, canViewAcoesRapidas } from '$lib/stores/niveis-acesso';
  import { goto } from '$app/navigation';
  import { page } from '$app/stores';
  import { supabase } from '$lib/utils/supabase';
  import Header from '$lib/components/layout/Header.svelte';
  import Sidebar from '$lib/components/layout/Sidebar.svelte';
  import EstatisticasUsuario from '$lib/components/estatisticas/EstatisticasUsuario.svelte';
  import StatusJovensCards from '$lib/components/estatisticas/StatusJovensCards.svelte';
  import MediasAvaliacoesCard from '$lib/components/estatisticas/MediasAvaliacoesCard.svelte';
  import PWAInstallPrompt from '$lib/components/PWAInstallPrompt.svelte';
  import '../app.css';
  
  let showSidebar = false; // Começar fechado em todas as telas
  let isMobile = false;
  
  onMount(() => {
    // Check if user is authenticated
    $user;
    
    // Detectar se é mobile
    const checkMobile = () => {
      // Detecta apenas o breakpoint; não altera o estado da sidebar
      // para manter fechada por padrão em qualquer dispositivo
      isMobile = window.innerWidth < 768; // md breakpoint
    };
    
    checkMobile();
    window.addEventListener('resize', checkMobile);
    
    return () => {
      window.removeEventListener('resize', checkMobile);
    };
  });
  
  // Debug: Log do nível do usuário
  $: if ($userProfile) {
    const papelExibido = getUserLevelName($userProfile);
  }

  // Redirecionar automaticamente usuários com papel "jovem" para o cadastro
  // (exceto para páginas permitidas como /viagem)
  $: (async () => {
    if (!$user || !$userProfile) return;
    const isJovem = hasRole('jovem')($userProfile);
    if (!isJovem) return;
    const currentPath = $page?.url?.pathname || '';
    
    // Páginas permitidas para jovens (além do cadastro)
    const allowedPaths = ['/jovens/cadastrar', '/viagem', '/profile'];
    const isAllowedPath = allowedPaths.some(path => currentPath.startsWith(path));
    
    // Permitir edição do próprio perfil para jovens
    const isEditingOwnProfile = currentPath.startsWith('/jovens/') && currentPath.endsWith('/editar');
    
    try {
      const { data, error } = await supabase
        .from('jovens')
        .select('id')
        .eq('usuario_id', $userProfile.id)
        .limit(1)
        .maybeSingle();
      if (error) return;
      const hasCadastro = !!data?.id;
      
      // Se não tem cadastro e não está em página permitida, redirecionar para cadastro
      if (!hasCadastro && !isAllowedPath && !isEditingOwnProfile) {
        goto('/jovens/cadastrar');
      } 
      // Se tem cadastro e está na página de cadastro, redirecionar para perfil
      else if (hasCadastro && currentPath.startsWith('/jovens/cadastrar')) {
        goto(`/jovens/${data.id}`);
      }
      // Se está tentando editar perfil de outro jovem, redirecionar para seu próprio perfil
      else if (isEditingOwnProfile && hasCadastro) {
        const pathParts = currentPath.split('/');
        const jovemIdInPath = pathParts[2]; // /jovens/[id]/editar
        if (jovemIdInPath !== data.id) {
          goto(`/jovens/${data.id}/editar`);
        }
      }
    } catch (e) {
      console.error('Falha ao verificar cadastro do jovem:', e);
    }
  })();
  
  function toggleSidebar() {
    showSidebar = !showSidebar;
  }
  
  // Fechar sidebar ao clicar em um link em mobile
  function handleSidebarLink() {
    if (isMobile) {
      showSidebar = false;
    }
  }
  
  // Verificar se é a página da ficha do jovem
  $: isFichaPage = $page?.url?.pathname?.includes('/ficha');
</script>

<svelte:head>
  <title>IntelliMen Campus</title>
  <meta name="description" content="Sistema de Gerenciamento de Jovens doIntelliMen Campus" />
</svelte:head>

<div class="min-h-screen" style="background-color: var(--fb-gray-light);">
  {#if $loading}
    <div class="flex items-center justify-center min-h-screen">
      <div class="relative">
        <div class="animate-spin rounded-full h-32 w-32 border-4 border-blue-200 border-t-blue-600"></div>
        <div class="absolute inset-0 animate-pulse rounded-full h-32 w-32 border-4 border-pink-200 border-t-pink-600"></div>
      </div>
    </div>
  {:else if !$user}
    <!-- Login page content will be rendered here -->
    <slot />
  {:else}
    {#if isFichaPage}
      <!-- Layout especial para ficha do jovem - sem sidebars -->
      <div class="min-h-screen bg-gray-50">
        <!-- Header simplificado -->
        <div class="bg-white shadow-sm border-b">
          <div class="max-w-full mx-auto px-6 py-4">
            <div class="flex items-center justify-between">
              <div class="flex items-center space-x-4">
                <button
                  on:click={() => goto('/jovens')}
                  class="flex items-center space-x-2 text-gray-600 hover:text-gray-900 transition-colors"
                >
                  <svg class="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 19l-7-7 7-7" />
                  </svg>
                  <span>Voltar</span>
                </button>
                <h1 class="text-xl font-semibold text-gray-900">Ficha do Jovem</h1>
              </div>
            </div>
          </div>
        </div>
        
        <!-- Conteúdo da ficha -->
        <main class="w-full">
          <slot />
        </main>
      </div>
    {:else}
      <!-- Main app layout - Facebook/Instagram style -->
      <div class="flex min-h-screen">
        <!-- Left Sidebar -->
        <Sidebar bind:showSidebar on:linkClick={handleSidebarLink} />
        
        <!-- Main content area -->
        <div class="flex-1 flex flex-col">
          <!-- Top Header -->
          <Header on:toggleSidebar={toggleSidebar} />
          
          <!-- Main content with social media layout -->
          <main class="flex-1 overflow-x-hidden overflow-y-auto" style="background-color: var(--fb-gray-light);">
            {#if hasRole('jovem')($userProfile)}
            <!-- Layout simplificado para jovem: conteúdo centralizado e mais estreito -->
            <div class="max-w-4xl mx-auto px-4 py-6">
              <div class="space-y-4">
                <slot />
              </div>
            </div>
            {:else}
            <div class="social-grid max-w-7xl mx-auto px-4 py-6">
              <!-- Left sidebar content (stories, shortcuts) -->
              {#if !hasRole('jovem')($userProfile)}
              <div class="hidden md:block">
                <div class="sticky top-4 space-y-4">
                  <!-- User profile card -->
                  <div class="fb-card p-4">
                    <div class="flex items-center space-x-3">
                      {#if $userProfile?.foto}
                        <img
                          class="profile-pic profile-pic-md status-online"
                          src={$userProfile.foto}
                          alt={$userProfile.nome}
                        />
                      {:else}
                        <div class="profile-pic profile-pic-md status-online bg-gradient-to-br from-blue-500 to-purple-600 flex items-center justify-center">
                          <span class="text-white font-bold text-lg">
                            {$userProfile?.nome?.charAt(0) || 'U'}
                          </span>
                        </div>
                      {/if}
                      <div class="flex-1 min-w-0">
                        <h3 class="font-semibold text-gray-900 truncate">
                          {$userProfile?.nome || 'Usuário'}
                        </h3>
                        <p class="text-sm text-gray-500 truncate">
                          {getUserLevelName($userProfile)}
                        </p>
                      </div>
                    </div>
                  </div>
                  
                  <!-- Estatísticas do Usuário (não mostrar para jovens) -->
                  {#if getUserLevelName($userProfile) !== 'Jovem'}
                    <EstatisticasUsuario />
                  {/if}
                  
                  <!-- Cards de Status dos Jovens -->
                  <StatusJovensCards />
                </div>
              </div>
              {/if}
              
              <!-- Center content -->
              <div class="space-y-4">
                <slot />
              </div>
              
              <!-- Right sidebar content (suggestions, activities) -->
              {#if !hasRole('jovem')($userProfile)}
              <div class="hidden md:block">
                <div class="sticky top-4 space-y-4">
                  <!-- Recent activities -->
                  <div class="fb-card p-4">
                    <h4 class="font-semibold text-gray-900 mb-3">Atividades Recentes</h4>
                    <div class="space-y-3">
                      <div class="flex items-center space-x-3">
                        <div class="w-8 h-8 bg-green-100 rounded-full flex items-center justify-center">
                          <svg class="w-4 h-4 text-green-600" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 6v6m0 0v6m0-6h6m-6 0H6" />
                          </svg>
                        </div>
                        <div class="flex-1 min-w-0">
                          <p class="text-sm text-gray-900">Novo jovem cadastrado</p>
                          <p class="text-xs text-gray-500">João Silva - 2h atrás</p>
                        </div>
                      </div>
                      <div class="flex items-center space-x-3">
                        <div class="w-8 h-8 bg-blue-100 rounded-full flex items-center justify-center">
                          <svg class="w-4 h-4 text-blue-600" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5H7a2 2 0 00-2 2v10a2 2 0 002 2h8a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2m-3 7h3m-3 4h3m-6-4h.01M9 16h.01" />
                          </svg>
                        </div>
                        <div class="flex-1 min-w-0">
                          <p class="text-sm text-gray-900">Avaliação realizada</p>
                          <p class="text-xs text-gray-500">Maria Santos - 4h atrás</p>
                        </div>
                      </div>
                    </div>
                  </div>
                  
                  <!-- Quick actions (não mostrar para jovens) -->
                  {#if getUserLevelName($userProfile) !== 'Jovem' && canViewAcoesRapidas()}
                  <div class="fb-card p-4">
                    <h4 class="font-semibold text-gray-900 mb-3">Ações Rápidas</h4>
                    <div class="space-y-2">
                      {#if canCadastrarJovem()}
                      <button class="w-full text-left p-2 rounded-lg hover:bg-gray-50 transition-colors">
                        <div class="flex items-center space-x-3">
                          <div class="w-8 h-8 bg-blue-100 rounded-full flex items-center justify-center">
                            <svg class="w-4 h-4 text-blue-600" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 6v6m0 0v6m0-6h6m-6 0H6" />
                            </svg>
                          </div>
                          <span class="text-sm font-medium">Cadastrar Jovem</span>
                        </div>
                      </button>
                      {/if}
                      <button class="w-full text-left p-2 rounded-lg hover:bg-gray-50 transition-colors">
                        <div class="flex items-center space-x-3">
                          <div class="w-8 h-8 bg-green-100 rounded-full flex items-center justify-center">
                            <svg class="w-4 h-4 text-green-600" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5H7a2 2 0 00-2 2v10a2 2 0 002 2h8a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2m-3 7h3m-3 4h3m-6-4h.01M9 16h.01" />
                            </svg>
                          </div>
                          <span class="text-sm font-medium">Avaliar Jovens</span>
                        </div>
                      </button>
                      <button class="w-full text-left p-2 rounded-lg hover:bg-gray-50 transition-colors">
                        <div class="flex items-center space-x-3">
                          <div class="w-8 h-8 bg-purple-100 rounded-full flex items-center justify-center">
                            <svg class="w-4 h-4 text-purple-600" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 19v-6a2 2 0 00-2-2H5a2 2 0 00-2 2v6a2 2 0 002 2h2a2 2 0 002-2zm0 0V9a2 2 0 012-2h2a2 2 0 012 2v10m-6 0a2 2 0 002 2h2a2 2 0 002-2m0 0V5a2 2 0 012-2h2a2 2 0 012 2v14a2 2 0 01-2 2h-2a2 2 0 01-2-2z" />
                            </svg>
                          </div>
                          <span class="text-sm font-medium">Ver Relatórios</span>
                        </div>
                      </button>
                    </div>
                  </div>
                  {/if}
                  
                  <!-- Médias de Avaliações (não mostrar para jovens) -->
                  {#if getUserLevelName($userProfile) !== 'Jovem'}
                    <MediasAvaliacoesCard />
                  {/if}
                </div>
              </div>
              {/if}
            </div>
            {/if}
          </main>
        </div>
      </div>
    {/if}
  {/if}
  
  <!-- PWA Install Prompt -->
  <PWAInstallPrompt />
</div>