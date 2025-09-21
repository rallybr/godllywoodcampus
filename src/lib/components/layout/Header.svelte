<script>
  import { createEventDispatcher } from 'svelte';
  import { userProfile, signOut } from '$lib/stores/auth';
  import { goto } from '$app/navigation';
  import NotificacoesDropdown from '$lib/components/notificacoes/NotificacoesDropdown.svelte';
  import UserAccessLevel from '$lib/components/security/UserAccessLevel.svelte';
  
  const dispatch = createEventDispatcher();
  
  let showUserMenu = false;
  let showNotifications = false;
  let showMobileSearch = false;
  
  function handleToggleSidebar() {
    dispatch('toggleSidebar');
  }
  
  async function handleSignOut() {
    await signOut();
    goto('/login');
  }
  
  function toggleUserMenu() {
    showUserMenu = !showUserMenu;
  }
  
  function toggleNotifications() {
    showNotifications = !showNotifications;
  }
  
  function toggleMobileSearch() {
    showMobileSearch = !showMobileSearch;
  }

  function goToProfile() {
    goto('/profile');
  }
</script>

<header class="fb-card rounded-none border-0 border-b relative z-40" style="background-color: var(--fb-white); box-shadow: var(--shadow-sm);">
  <div class="flex items-center justify-between px-4 py-3">
    <!-- Left side -->
    <div class="flex items-center space-x-4">
      <button
        type="button"
        class="p-2 rounded-full hover:bg-gray-100 transition-colors"
        on:click={handleToggleSidebar}
      >
        <svg class="h-6 w-6 text-gray-600" fill="none" viewBox="0 0 24 24" stroke="currentColor">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 6h16M4 12h16M4 18h16" />
        </svg>
      </button>
      
      <div class="flex items-center space-x-3">
        <img src="/logo.png" alt="IM" class="w-10 h-10 rounded-xl object-contain bg-white/70 p-1 ring-1 ring-white/40" />
        <h1 class="text-xl font-bold ig-gradient hidden sm:block">IntelliMen Campus</h1>
        <h1 class="text-lg font-bold ig-gradient sm:hidden">IM Campus</h1>
      </div>
    </div>
    
    <!-- Center - Search bar -->
    <div class="hidden md:flex flex-1 max-w-md mx-8">
      <div class="relative w-full">
        <div class="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none">
          <svg class="h-5 w-5 text-gray-400" fill="none" viewBox="0 0 24 24" stroke="currentColor">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z" />
          </svg>
        </div>
        <input
          type="text"
          placeholder="Pesquisar jovens, avaliações..."
          class="w-full pl-10 pr-4 py-2 bg-gray-100 border-0 rounded-full focus:ring-2 focus:ring-blue-500 focus:bg-white transition-colors"
        />
      </div>
    </div>
    
    <!-- Right side -->
    <div class="flex items-center space-x-2">
      <!-- Mobile Search Button -->
      <button
        type="button"
        class="md:hidden p-2 rounded-full hover:bg-gray-100 transition-colors"
        on:click={toggleMobileSearch}
      >
        <svg class="h-6 w-6 text-gray-600" fill="none" viewBox="0 0 24 24" stroke="currentColor">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z" />
        </svg>
      </button>
      
      <!-- Notifications -->
      <NotificacoesDropdown />
      
      <!-- User: avatar (vai para perfil) + caret (abre menu) -->
      <div class="relative flex items-center">
        <button
          type="button"
          class="flex items-center p-1 rounded-full hover:bg-gray-100 transition-colors"
          on:click={goToProfile}
          aria-label="Ir para meu perfil"
        >
          {#if $userProfile?.foto}
            <img
              class="profile-pic profile-pic-sm"
              src={$userProfile.foto}
              alt={$userProfile.nome}
            />
          {:else}
            <div class="profile-pic profile-pic-sm bg-gradient-to-br from-blue-500 to-purple-600 flex items-center justify-center">
              <span class="text-white font-medium text-sm">
                {$userProfile?.nome?.charAt(0) || 'U'}
              </span>
            </div>
          {/if}
        </button>
        <button
          type="button"
          class="p-1 rounded-full hover:bg-gray-100 transition-colors"
          on:click={toggleUserMenu}
          aria-label="Abrir menu do usuário"
        >
          <svg class="h-4 w-4 text-gray-400" fill="none" viewBox="0 0 24 24" stroke="currentColor">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 9l-7 7-7-7" />
          </svg>
        </button>
        
        <!-- User dropdown menu -->
        {#if showUserMenu}
          <div class="absolute right-0 top-full mt-2 w-56 bg-white rounded-lg shadow-lg border border-gray-200 z-[60]">
            <div class="p-4 border-b border-gray-200">
              <div class="flex items-center space-x-3">
                {#if $userProfile?.foto}
                  <img
                    class="profile-pic profile-pic-md"
                    src={$userProfile.foto}
                    alt={$userProfile.nome}
                  />
                {:else}
                  <div class="profile-pic profile-pic-md bg-gradient-to-br from-blue-500 to-purple-600 flex items-center justify-center">
                    <span class="text-white font-bold text-lg">
                      {$userProfile?.nome?.charAt(0) || 'U'}
                    </span>
                  </div>
                {/if}
                <div class="flex-1 min-w-0">
                  <p class="font-semibold text-gray-900 truncate">{$userProfile?.nome || 'Usuário'}</p>
                  <div class="flex items-center space-x-2">
                    <UserAccessLevel />
                  </div>
                </div>
              </div>
            </div>
            <div class="py-1">
              <a href="/profile" class="flex items-center px-4 py-2 text-sm text-gray-700 hover:bg-gray-100">
                <svg class="w-4 h-4 mr-3" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M16 7a4 4 0 11-8 0 4 4 0 018 0zM12 14a7 7 0 00-7 7h14a7 7 0 00-7-7z" />
                </svg>
                Meu Perfil
              </a>
              <a href="/settings" class="flex items-center px-4 py-2 text-sm text-gray-700 hover:bg-gray-100">
                <svg class="w-4 h-4 mr-3" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M10.325 4.317c.426-1.756 2.924-1.756 3.35 0a1.724 1.724 0 002.573 1.066c1.543-.94 3.31.826 2.37 2.37a1.724 1.724 0 001.065 2.572c1.756.426 1.756 2.924 0 3.35a1.724 1.724 0 00-1.066 2.573c.94 1.543-.826 3.31-2.37 2.37a1.724 1.724 0 00-2.572 1.065c-.426 1.756-2.924 1.756-3.35 0a1.724 1.724 0 00-2.573-1.066c-1.543.94-3.31-.826-2.37-2.37a1.724 1.724 0 00-1.065-2.572c-1.756-.426-1.756 2.924 0 3.35a1.724 1.724 0 00-1.066 2.573c.94 1.543-.826 3.31-2.37 2.37.996.608 2.296.07 2.572-1.065z M15 12a3 3 0 11-6 0 3 3 0 016 0z" />
                </svg>
                Configurações
              </a>
              <div class="border-t border-gray-100 my-1"></div>
              <button
                type="button"
                class="flex items-center w-full px-4 py-2 text-sm text-gray-700 hover:bg-gray-100"
                on:click={handleSignOut}
              >
                <svg class="w-4 h-4 mr-3" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M17 16l4-4m0 0l-4-4m4 4H7m6 4v1a3 3 0 01-3 3H6a3 3 0 01-3-3V7a3 3 0 013-3h4a3 3 0 013 3v1" />
                </svg>
                Sair
              </button>
            </div>
          </div>
        {/if}
      </div>
    </div>
  </div>
  
  <!-- Mobile Search Modal -->
  {#if showMobileSearch}
    <div class="md:hidden border-t border-gray-200 bg-white">
      <div class="px-4 py-3">
        <div class="relative">
          <div class="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none">
            <svg class="h-5 w-5 text-gray-400" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z" />
            </svg>
          </div>
          <input
            type="text"
            placeholder="Pesquisar jovens, avaliações..."
            class="w-full pl-10 pr-4 py-2 bg-gray-100 border-0 rounded-full focus:ring-2 focus:ring-blue-500 focus:bg-white transition-colors"
          />
          <button
            type="button"
            class="absolute right-3 top-1/2 transform -translate-y-1/2 p-1 rounded-full hover:bg-gray-200 transition-colors"
            on:click={toggleMobileSearch}
          >
            <svg class="h-4 w-4 text-gray-400" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12" />
            </svg>
          </button>
        </div>
      </div>
    </div>
  {/if}
</header>
