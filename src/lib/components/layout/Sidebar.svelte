<script>
  import { createEventDispatcher } from 'svelte';
  import { userProfile, hasPermission, hasRole } from '$lib/stores/auth';
  import { getUserLevelName } from '$lib/stores/niveis-acesso';
  import { page } from '$app/stores';
  import { jovemJaCadastrado, initializeCadastroCheck } from '$lib/stores/jovem-cadastro';
  
  export let showSidebar = true;
  
  const dispatch = createEventDispatcher();
  
  // Inicializar verificação de cadastro quando o perfil mudar
  $: if ($userProfile) {
    initializeCadastroCheck();
  }
  
  const menuItems = [
    { name: 'Feed', href: '/', icon: 'M3 7v10a2 2 0 002 2h14a2 2 0 002-2V9a2 2 0 00-2-2H5a2 2 0 00-2-2z', color: 'text-blue-600' },
    { name: 'Meu Perfil', href: '/profile', icon: 'M16 7a4 4 0 11-8 0 4 4 0 018 0zM12 14a7 7 0 00-7 7h14a7 7 0 00-7-7z', color: 'text-gray-600' },
    { name: 'Jovens', href: '/jovens', icon: 'M12 4.354a4 4 0 110 5.292M15 21H3v-1a6 6 0 0112 0v1zm0 0h6v-1a6 6 0 00-9-5.197m13.5-9a2.5 2.5 0 11-5 0 2.5 2.5 0 015 0z', color: 'text-green-600' },
    { name: 'Lista de Jovens', href: '/jovens/cards', icon: 'M4 6a2 2 0 012-2h2a2 2 0 012 2v2a2 2 0 01-2 2H6a2 2 0 01-2-2V6zM14 6a2 2 0 012-2h2a2 2 0 012 2v2a2 2 0 01-2 2h-2a2 2 0 01-2-2V6zM4 16a2 2 0 012-2h2a2 2 0 012 2v2a2 2 0 01-2 2H6a2 2 0 01-2-2v-2zM14 16a2 2 0 012-2h2a2 2 0 012 2v2a2 2 0 01-2 2h-2a2 2 0 01-2-2v-2z', color: 'text-green-600' },
    { name: 'Viagem', href: '/viagem', icon: 'M12 8c-3.866 0-7 3.134-7 7v1h14v-1c0-3.866-3.134-7-7-7zm0-2a3 3 0 100-6 3 3 0 000 6z', color: 'text-teal-600' },
    { name: 'Avaliações', href: '/avaliacoes', icon: 'M9 5H7a2 2 0 00-2 2v10a2 2 0 002 2h8a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2m-3 7h3m-3 4h3m-6-4h.01M9 16h.01', color: 'text-purple-600' },
    { name: 'Relatórios', href: '/relatorios', icon: 'M9 19v-6a2 2 0 00-2-2H5a2 2 0 00-2 2v6a2 2 0 002 2h2a2 2 0 002-2zm0 0V9a2 2 0 012-2h2a2 2 0 012 2v10m-6 0a2 2 0 002 2h2a2 2 0 002-2m0 0V5a2 2 0 012-2h2a2 2 0 012 2v14a2 2 0 01-2 2h-2a2 2 0 01-2-2z', color: 'text-orange-600', submenu: [ { name: 'Dashboard', href: '/relatorios', icon: 'M3 7v10a2 2 0 002 2h14a2 2 0 002-2V9a2 2 0 00-2-2H5a2 2 0 00-2-2z' }, { name: 'Avaliações', href: '/relatorios/avaliacoes', icon: 'M9 5H7a2 2 0 00-2 2v10a2 2 0 002 2h8a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2m-3 7h3m-3 4h3m-6-4h.01M9 16h.01' }, { name: 'Jovens', href: '/relatorios/jovens', icon: 'M12 4.354a4 4 0 110 5.292M15 21H3v-1a6 6 0 0112 0v1zm0 0h6v-1a6 6 0 00-9-5.197m13.5-9a2.5 2.5 0 11-5 0 2.5 2.5 0 015 0z' }, { name: 'Personalizados', href: '/relatorios/personalizados', icon: 'M12 6V4m0 2a2 2 0 100 4m0-4a2 2 0 110 4m-6 8a2 2 0 100-4m0 4a2 2 0 100 4m0-4v2m0-6V4m6 6v10m6-2a2 2 0 100-4m0 4a2 2 0 100 4m0-4v2m0-6V4' } ] },
    { name: 'Evolução', href: '/relatorio-condicao', icon: 'M13 7h8m0 0v8m0-8l-8 8-4-4-6 6', color: 'text-cyan-600' },
    { name: 'Usuários', href: '/usuarios', icon: 'M12 4.354a4 4 0 110 5.292M15 21H3v-1a6 6 0 0112 0v1zm0 0h6v-1a6 6 0 00-9-5.197m13.5-9a2.5 2.5 0 11-5 0 2.5 2.5 0 015 0z', color: 'text-pink-600', adminOnly: true },
    { name: 'Administração', href: '/administracao', icon: 'M19 21V5a2 2 0 00-2-2H7a2 2 0 00-2 2v16m14 0h2m-2 0h-5m-9 0H3m2 0h5M9 7h1m-1 4h1m4-4h1m-1 4h1m-5 10v-5a1 1 0 011-1h2a1 1 0 011 1v5m-4 0h4', color: 'text-indigo-600', adminOnly: true },
    { name: 'Auditoria', href: '/seguranca/auditoria', icon: 'M9 12h6m-6 4h6M5 8h14M7 4h10', color: 'text-red-600', adminOnly: true },
    { name: 'Histórico', href: '/seguranca/historico', icon: 'M3 7v10h18V7zM6 10h12', color: 'text-emerald-600', adminOnly: true },
    { name: 'Sessões', href: '/seguranca/sessoes', icon: 'M5 13l4 4L19 7', color: 'text-amber-600', adminOnly: true },
    { name: 'Notificações', href: '/notificacoes', icon: 'M15 17h5l-5 5v-5zM4.828 7l2.586 2.586a2 2 0 002.828 0L12.828 7H4.828zM4.828 17l2.586-2.586a2 2 0 012.828 0L12.828 17H4.828z', color: 'text-indigo-600' },
    { name: 'Configurações', href: '/config', icon: 'M10.325 4.317c.426-1.756 2.924-1.756 3.35 0a1.724 1.724 0 002.573 1.066c1.543-.94 3.31.826 2.37 2.37a1.724 1.724 0 001.065 2.572c1.756.426 1.756 2.924 0 3.35a1.724 1.724 0 00-1.066 2.573c.94 1.543-.826 3.31-2.37 2.37.996.608 2.296.07 2.572-1.065z M15 12a3 3 0 11-6 0 3 3 0 016 0z', color: 'text-gray-600' }
  ];
  
  $: profile = $userProfile;
  $: isJovem = getUserLevelName($userProfile) === 'Jovem';
  
  $: filteredMenuItems = isJovem
    ? (() => {
        const menuJovem = [
          { name: 'Feed', href: '/', icon: 'M3 7v10a2 2 0 002 2h14a2 2 0 002-2V9a2 2 0 00-2-2H5a2 2 0 00-2-2z', color: 'text-blue-600' },
          { name: 'Meu Perfil', href: '/profile', icon: 'M16 7a4 4 0 11-8 0 4 4 0 018 0zM12 14a7 7 0 00-7 7h14a7 7 0 00-7-7z', color: 'text-gray-600' }
        ];
        
        // Se ainda não se cadastrou, mostrar opção de cadastro
        if (!$jovemJaCadastrado) {
          menuJovem.push(
            { name: 'Cadastro', href: '/jovens/cadastrar', icon: 'M12 4.354a4 4 0 110 5.292M15 21H3v-1a6 6 0 0112 0v1', color: 'text-blue-600' }
          );
        }
        
        // Sempre mostrar viagem
        menuJovem.push(
          { name: 'Viagem', href: '/viagem', icon: 'M12 8c-3.866 0-7 3.134-7 7v1h14v-1c0-3.866-3.134-7-7-7zm0-2a3 3 0 100-6 3 3 0 000 6z', color: 'text-teal-600' }
        );
        
        // Sempre mostrar dados de núcleo
        menuJovem.push(
          { name: 'Dados de Núcleo', href: '/jovens/dados-nucleo', icon: 'M12 2l3.09 6.26L22 9.27l-5 4.87 1.18 6.88L12 17.77l-6.18 3.25L7 14.14 2 9.27l6.91-1.01L12 2z', color: 'text-yellow-600' }
        );
        
        return menuJovem;
      })()
    : menuItems.filter(item => item.adminOnly ? (profile?.nivel === 'administrador') : true);
  
  function isActive(href) { return $page.url.pathname === href; }
  function handleLinkClick() { dispatch('linkClick'); }
</script>

<!-- Overlay -->
{#if showSidebar}
  <div 
    class="fixed inset-0 bg-black bg-opacity-50 z-40" 
    role="button"
    tabindex="0"
    on:click={() => showSidebar = false}
    on:keydown={(e) => e.key === 'Enter' && (showSidebar = false)}
    aria-label="Fechar menu"
  ></div>
{/if}

<!-- Sidebar -->
<aside class="fixed inset-y-0 left-0 z-50 w-64 bg-white transform transition-transform duration-300 ease-in-out {showSidebar ? 'translate-x-0' : '-translate-x-full'} md:fixed md:transform md:transition-transform md:duration-300 md:ease-in-out md:{showSidebar ? 'translate-x-0' : '-translate-x-full'} border-r border-gray-200 shadow-lg drawer-mobile">
  <div class="flex flex-col h-full safe-area-all">
    <!-- Logo -->
    <div class="flex items-center justify-center h-16 px-4 border-b" style="border-color: var(--fb-border);">
      <div class="flex items-center space-x-2">
        <img src="/logo.png" alt="IntelliMen" class="w-8 h-8 rounded-lg object-contain bg-white/70 p-1 ring-1 ring-white/40" />
        <span class="font-bold text-gray-900">IntelliMen</span>
      </div>
    </div>
    
    
    <!-- Navigation -->
    <nav class="flex-1 px-4 py-6 space-y-1">
      {#each filteredMenuItems as item}
        <a
          href={item.href}
          class="flex items-center space-x-3 px-3 py-2 text-sm font-medium rounded-lg transition-colors {isActive(item.href) ? 'bg-blue-50 text-blue-600' : 'text-gray-700 hover:bg-gray-100'}"
          on:click={handleLinkClick}
        >
          <svg class="h-5 w-5 {isActive(item.href) ? item.color : 'text-gray-500'}" fill="none" viewBox="0 0 24 24" stroke="currentColor">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d={item.icon} />
          </svg>
          <span>{item.name}</span>
        </a>
      {/each}
    </nav>
    
    <!-- User info -->
    <div class="p-4 border-t" style="border-color: var(--fb-border);">
      <div class="flex items-center space-x-3">
        {#if profile?.foto}
          <img
            class="profile-pic profile-pic-sm"
            src={profile.foto}
            alt={profile.nome}
          />
        {:else}
          <div class="profile-pic profile-pic-sm bg-gradient-to-br from-blue-500 to-purple-600 flex items-center justify-center">
            <span class="text-white font-medium text-sm">
              {profile?.nome?.charAt(0) || 'U'}
            </span>
          </div>
        {/if}
        
        <div class="flex-1 min-w-0">
          <p class="text-sm font-medium text-gray-900 truncate">
            {profile?.nome || 'Usuário'}
          </p>
          <p class="text-xs text-gray-500 truncate">
            {profile?.user_roles?.[0]?.role?.nome || 'Usuário'}
          </p>
        </div>
      </div>
    </div>
  </div>
</aside>
