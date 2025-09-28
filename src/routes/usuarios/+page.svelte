<script>
  import { onMount } from 'svelte';
  import { userProfile, hasRole } from '$lib/stores/auth';
  import { goto } from '$app/navigation';
  import Button from '$lib/components/ui/Button.svelte';
  import Card from '$lib/components/ui/Card.svelte';
  import EditarUsuarioModal from '$lib/components/modals/EditarUsuarioModal.svelte';
  import { buscarUsuarios, buscarUsuariosPorNome, buscarUsuariosComUltimoAcesso, registrarUltimoAcesso } from '$lib/stores/usuarios';

  let usuarios = [];
  let loading = true;
  let error = null;
  let busca = '';
  let resultadosBusca = [];
  let buscando = false;
  let showEditarModal = false;
  let usuarioSelecionado = null;

  // Verificar se pode ver todos os usuários (apenas administradores)
  $: podeVerTodos = hasRole('administrador')($userProfile);

  onMount(async () => {
    // Registrar último acesso do usuário atual
    try {
      await registrarUltimoAcesso();
    } catch (err) {
      console.warn('Erro ao registrar último acesso:', err);
    }
    
    await carregarUsuarios();
  });

  async function carregarUsuarios() {
    loading = true;
    error = null;
    try {
      if (podeVerTodos) {
        // Buscar usuários com dados de último acesso
        usuarios = await buscarUsuariosComUltimoAcesso();
      } else {
        // Usuário comum só vê seu próprio perfil
        usuarios = [$userProfile];
      }
    } catch (err) {
      error = err.message;
      console.error('Erro ao carregar usuários:', err);
    } finally {
      loading = false;
    }
  }

  async function handleBusca() {
    if (busca.length < 2) {
      resultadosBusca = [];
      return;
    }

    if (!podeVerTodos) {
      // Usuário comum só pode buscar seu próprio nome
      if (busca.toLowerCase().includes($userProfile?.nome?.toLowerCase() || '')) {
        resultadosBusca = [$userProfile];
      } else {
        resultadosBusca = [];
      }
      return;
    }

    buscando = true;
    try {
      resultadosBusca = await buscarUsuariosPorNome(busca);
    } catch (err) {
      console.error('Erro na busca:', err);
      resultadosBusca = [];
    } finally {
      buscando = false;
    }
  }

  function abrirEditarModal(usuario) {
    console.log('Tentando abrir modal para usuário:', usuario);
    console.log('showEditarModal antes:', showEditarModal);
    usuarioSelecionado = usuario;
    showEditarModal = true;
    console.log('showEditarModal depois:', showEditarModal);
    console.log('usuarioSelecionado:', usuarioSelecionado);
  }

  function fecharEditarModal() {
    showEditarModal = false;
    usuarioSelecionado = null;
  }

  async function handleUsuarioEditado() {
    // Recarregar lista após edição
    await carregarUsuarios();
    fecharEditarModal();
  }

  // Busca em tempo real
  $: if (busca) {
    handleBusca();
  } else {
    resultadosBusca = [];
  }
</script>

<svelte:head>
  <title>Usuários - Campus</title>
</svelte:head>

<div class="min-h-screen bg-gray-50 py-6">
  <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
    <!-- Header -->
    <div class="mb-6">
      <h1 class="text-2xl sm:text-3xl font-bold text-gray-900">Usuários</h1>
      <p class="mt-2 text-gray-600">
        {#if podeVerTodos}
          Gerencie todos os usuários do sistema
        {:else}
          Edite seu perfil
        {/if}
      </p>
    </div>

    <!-- Busca -->
    <div class="mb-6">
      <div class="relative">
        <div class="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none">
          <svg class="h-5 w-5 text-gray-400" fill="none" viewBox="0 0 24 24" stroke="currentColor">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z" />
          </svg>
        </div>
        <input
          type="text"
          bind:value={busca}
          placeholder={podeVerTodos ? "Buscar usuários por nome..." : "Buscar seu nome..."}
          class="block w-full pl-10 pr-3 py-2 border border-gray-300 rounded-md leading-5 bg-white placeholder-gray-500 focus:outline-none focus:placeholder-gray-400 focus:ring-1 focus:ring-blue-500 focus:border-blue-500 sm:text-sm relative z-10"
          style="pointer-events: auto; z-index: 10;"
        />
        {#if buscando}
          <div class="absolute inset-y-0 right-0 pr-3 flex items-center">
            <svg class="animate-spin h-5 w-5 text-gray-400" fill="none" viewBox="0 0 24 24">
              <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle>
              <path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
            </svg>
          </div>
        {/if}
      </div>

      <!-- Resultados da Busca -->
      {#if busca && resultadosBusca.length > 0}
        <div class="mt-2 bg-white border border-gray-200 rounded-md shadow-lg max-h-60 overflow-y-auto relative z-20">
          {#each resultadosBusca as usuario}
            {#if usuario}
              <button
                on:click={() => abrirEditarModal(usuario)}
                class="w-full px-4 py-3 text-left hover:bg-gray-50 focus:outline-none focus:bg-gray-50 border-b border-gray-100 last:border-b-0 relative z-30 cursor-pointer"
                style="pointer-events: auto; z-index: 30;"
              >
                <div class="flex items-center space-x-3">
                  {#if usuario.foto}
                    <img src={usuario.foto} alt={usuario.nome || 'Usuário'} class="w-10 h-10 rounded-full object-cover" />
                  {:else}
                    <div class="w-10 h-10 rounded-full bg-gray-200 flex items-center justify-center">
                      <span class="text-gray-600 font-medium">{usuario.nome?.charAt(0) || 'U'}</span>
                    </div>
                  {/if}
                  <div class="flex-1 min-w-0">
                    <p class="text-sm font-medium text-gray-900 truncate">{usuario.nome || 'Nome não informado'}</p>
                    <p class="text-sm text-gray-500 truncate">{usuario.email || 'Email não informado'}</p>
                  </div>
                  <div class="flex-shrink-0">
                    <span class="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-blue-100 text-blue-800">
                      {usuario.nivel || 'Nível não informado'}
                    </span>
                  </div>
                </div>
              </button>
            {/if}
          {/each}
        </div>
      {/if}
    </div>

    <!-- Lista de Usuários -->
    {#if loading}
      <div class="flex justify-center items-center py-12">
        <div class="animate-spin rounded-full h-8 w-8 border-b-2 border-blue-600"></div>
      </div>
    {:else if error}
      <Card class="p-6">
        <div class="text-center">
          <svg class="mx-auto h-12 w-12 text-red-400" fill="none" viewBox="0 0 24 24" stroke="currentColor">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-2.5L13.732 4c-.77-.833-1.732-.833-2.5 0L4.268 19.5c-.77.833.192 2.5 1.732 2.5z" />
          </svg>
          <h3 class="mt-2 text-sm font-medium text-gray-900">Erro ao carregar usuários</h3>
          <p class="mt-1 text-sm text-gray-500">{error}</p>
          <div class="mt-6">
            <Button on:click={carregarUsuarios} variant="outline">
              Tentar Novamente
            </Button>
          </div>
        </div>
      </Card>
    {:else}
      <div class="grid grid-cols-1 sm:grid-cols-2 gap-4 sm:gap-6">
        {#each usuarios as usuario}
          {#if usuario}
            <Card class="group relative overflow-hidden bg-gradient-to-br from-white via-blue-50/30 to-indigo-50/20 border border-gray-200/60 hover:border-blue-300/60 shadow-lg hover:shadow-2xl transition-all duration-500 transform hover:-translate-y-1 p-4">
              <!-- Decorative background pattern -->
              <div class="absolute inset-0 bg-gradient-to-br from-blue-500/5 via-transparent to-indigo-500/5 opacity-0 group-hover:opacity-100 transition-opacity duration-500"></div>
              
              <!-- Content -->
              <div class="relative">
                <!-- Header com Avatar e Nome -->
                <div class="flex items-start space-x-4 mb-4">
                  {#if usuario.foto}
                    <div class="relative">
                      <img 
                        src={usuario.foto} 
                        alt={usuario.nome || 'Usuário'} 
                        class="w-20 h-20 rounded-full object-cover border-4 border-white shadow-lg ring-2 ring-blue-100 group-hover:ring-blue-200 transition-all duration-300"
                        on:error={(e) => {
                          console.log('Erro ao carregar foto:', usuario.foto, e);
                          // Se a imagem falhar, vamos usar o avatar padrão
                          usuario.foto = null;
                          // Forçar re-render
                          usuarios = [...usuarios];
                        }}
                      />
                      <div class="absolute -bottom-1 -right-1 w-6 h-6 bg-green-400 rounded-full border-2 border-white shadow-lg flex items-center justify-center">
                        <svg class="w-3 h-3 text-white" fill="currentColor" viewBox="0 0 20 20">
                          <path fill-rule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zm3.707-9.293a1 1 0 00-1.414-1.414L9 10.586 7.707 9.293a1 1 0 00-1.414 1.414l2 2a1 1 0 001.414 0l4-4z" clip-rule="evenodd" />
                        </svg>
                      </div>
                    </div>
                  {:else}
                    <div class="relative">
                      <div class="w-20 h-20 rounded-full bg-gradient-to-br from-blue-500 via-blue-600 to-indigo-600 flex items-center justify-center border-4 border-white shadow-lg ring-2 ring-blue-100 group-hover:ring-blue-200 transition-all duration-300">
                        <span class="text-white font-bold text-2xl">{usuario.nome?.charAt(0) || 'U'}</span>
                      </div>
                      <div class="absolute -bottom-1 -right-1 w-6 h-6 bg-green-400 rounded-full border-2 border-white shadow-lg flex items-center justify-center">
                        <svg class="w-3 h-3 text-white" fill="currentColor" viewBox="0 0 20 20">
                          <path fill-rule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zm3.707-9.293a1 1 0 00-1.414-1.414L9 10.586 7.707 9.293a1 1 0 00-1.414 1.414l2 2a1 1 0 001.414 0l4-4z" clip-rule="evenodd" />
                        </svg>
                      </div>
                    </div>
                  {/if}
                  <div class="flex-1 min-w-0">
                    <h3 class="text-xl font-bold text-gray-900 truncate mb-1 group-hover:text-blue-900 transition-colors duration-300">{usuario.nome || 'Nome não informado'}</h3>
                    <p class="text-sm text-gray-600 truncate mb-2 flex items-center">
                      <svg class="w-4 h-4 mr-2 text-gray-400" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M16 12a4 4 0 10-8 0 4 4 0 008 0zm0 0v1.5a2.5 2.5 0 005 0V12a9 9 0 10-9 9m4.5-1.206a8.959 8.959 0 01-4.5 1.207" />
                      </svg>
                      {usuario.email || 'Email não informado'}
                    </p>
                  </div>
                </div>

                <!-- Tags de Status -->
                <div class="flex flex-wrap items-center gap-2 mb-4">
                  <span class="inline-flex items-center px-3 py-1.5 rounded-full text-xs font-semibold bg-gradient-to-r from-blue-500 to-blue-600 text-white shadow-lg hover:shadow-xl transition-all duration-300 transform hover:scale-105">
                    <svg class="w-3 h-3 mr-1.5" fill="currentColor" viewBox="0 0 20 20">
                      <path fill-rule="evenodd" d="M6 6V5a3 3 0 013-3h2a3 3 0 013 3v1h2a2 2 0 012 2v3.57A22.952 22.952 0 0110 13a22.95 22.95 0 01-8-1.43V8a2 2 0 012-2h2zm2-1a1 1 0 011-1h2a1 1 0 011 1v1H8V5zm1 5a1 1 0 011-1h.01a1 1 0 110 2H10a1 1 0 01-1-1z" clip-rule="evenodd" />
                    </svg>
                    {usuario.nivel || 'Nível não informado'}
                  </span>
                  {#if usuario.ativo !== undefined}
                    {#if usuario.ativo}
                      <span class="inline-flex items-center px-3 py-1.5 rounded-full text-xs font-semibold bg-gradient-to-r from-green-500 to-green-600 text-white shadow-lg hover:shadow-xl transition-all duration-300 transform hover:scale-105">
                        <svg class="w-3 h-3 mr-1.5" fill="currentColor" viewBox="0 0 20 20">
                          <path fill-rule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zm3.707-9.293a1 1 0 00-1.414-1.414L9 10.586 7.707 9.293a1 1 0 00-1.414 1.414l2 2a1 1 0 001.414 0l4-4z" clip-rule="evenodd" />
                        </svg>
                        Ativo
                      </span>
                    {:else}
                      <span class="inline-flex items-center px-3 py-1.5 rounded-full text-xs font-semibold bg-gradient-to-r from-red-500 to-red-600 text-white shadow-lg hover:shadow-xl transition-all duration-300 transform hover:scale-105">
                        <svg class="w-3 h-3 mr-1.5" fill="currentColor" viewBox="0 0 20 20">
                          <path fill-rule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zM8.707 7.293a1 1 0 00-1.414 1.414L8.586 10l-1.293 1.293a1 1 0 101.414 1.414L10 11.414l1.293 1.293a1 1 0 001.414-1.414L11.414 10l1.293-1.293a1 1 0 00-1.414-1.414L10 8.586 8.707 7.293z" clip-rule="evenodd" />
                        </svg>
                        Inativo
                      </span>
                    {/if}
                  {/if}
                </div>

                <!-- Seção de Último Acesso -->
                <div class="bg-gradient-to-r from-gray-50 to-blue-50/50 rounded-2xl p-4 mb-4 border border-gray-200/50 shadow-inner">
                  <div class="flex items-center space-x-3 mb-3">
                    <div class="p-2 bg-blue-100 rounded-full">
                      <svg class="w-5 h-5 text-blue-600" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z" />
                      </svg>
                    </div>
                    <span class="text-sm font-semibold text-gray-800">Último Acesso</span>
                  </div>
                  
                  {#if usuario.ultimo_acesso}
                    <div class="space-y-3">
                      <!-- Status do dia -->
                      <div class="flex justify-center">
                        {#if usuario.dias_sem_acesso === 0}
                          <span class="inline-flex items-center px-3 py-1.5 rounded-full text-sm font-semibold bg-gradient-to-r from-green-500 to-green-600 text-white shadow-lg">
                            <svg class="w-4 h-4 mr-1.5" fill="currentColor" viewBox="0 0 20 20">
                              <path fill-rule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zm3.707-9.293a1 1 0 00-1.414-1.414L9 10.586 7.707 9.293a1 1 0 00-1.414 1.414l2 2a1 1 0 001.414 0l4-4z" clip-rule="evenodd" />
                            </svg>
                            Hoje
                          </span>
                        {:else if usuario.dias_sem_acesso <= 7}
                          <span class="inline-flex items-center px-3 py-1.5 rounded-full text-sm font-semibold bg-gradient-to-r from-yellow-500 to-yellow-600 text-white shadow-lg">
                            {usuario.dias_sem_acesso} dias
                          </span>
                        {:else if usuario.dias_sem_acesso <= 30}
                          <span class="inline-flex items-center px-3 py-1.5 rounded-full text-sm font-semibold bg-gradient-to-r from-orange-500 to-orange-600 text-white shadow-lg">
                            {usuario.dias_sem_acesso} dias
                          </span>
                        {:else}
                          <span class="inline-flex items-center px-3 py-1.5 rounded-full text-sm font-semibold bg-gradient-to-r from-red-500 to-red-600 text-white shadow-lg">
                            {usuario.dias_sem_acesso} dias
                          </span>
                        {/if}
                      </div>
                      
                      <!-- Data e hora -->
                      <div>
                        <p class="text-base font-medium text-gray-700">
                          {new Date(usuario.ultimo_acesso).toLocaleString('pt-BR', {
                            day: '2-digit',
                            month: '2-digit',
                            year: 'numeric',
                            hour: '2-digit',
                            minute: '2-digit'
                          })}
                        </p>
                      </div>
                      
                      <!-- Tempo decorrido -->
                      <div class="text-sm text-gray-600 flex items-center">
                        <svg class="w-4 h-4 mr-2 text-gray-400" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z" />
                        </svg>
                        {#if usuario.ultimo_acesso}
                          {@const tempoDecorrido = Math.floor((new Date() - new Date(usuario.ultimo_acesso)) / (1000 * 60))}
                          {#if tempoDecorrido < 60}
                            Há {tempoDecorrido} minutos
                          {:else if tempoDecorrido < 1440}
                            Há {Math.floor(tempoDecorrido / 60)} horas
                          {:else}
                            Há {Math.floor(tempoDecorrido / 1440)} dias
                          {/if}
                        {/if}
                      </div>
                    </div>
                  {:else}
                    <div class="flex items-center space-x-3 text-gray-500">
                      <svg class="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z" />
                      </svg>
                      <span class="text-sm font-medium">Nunca acessou</span>
                    </div>
                  {/if}
                </div>

                <!-- Botão de Ação -->
                <div class="flex justify-center relative z-10">
                  <button
                    on:click={() => {
                      console.log('Botão clicado para usuário:', usuario);
                      abrirEditarModal(usuario);
                    }}
                    class="bg-gradient-to-r from-blue-600 to-indigo-600 hover:from-blue-700 hover:to-indigo-700 text-white font-semibold px-6 py-2.5 rounded-lg shadow-lg hover:shadow-xl transition-all duration-300 transform hover:scale-105 border-0 text-sm flex items-center justify-center relative z-20 cursor-pointer"
                    style="pointer-events: auto; z-index: 20;"
                  >
                    <svg class="w-4 h-4 mr-2" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M11 5H6a2 2 0 00-2 2v11a2 2 0 002 2h11a2 2 0 002-2v-5m-1.414-9.414a2 2 0 112.828 2.828L11.828 15H9v-2.828l8.586-8.586z" />
                    </svg>
                    Editar Usuário
                  </button>
                </div>
              </div>
            </Card>
          {/if}
        {/each}
      </div>

      {#if usuarios.length === 0}
        <Card class="p-6">
          <div class="text-center">
            <svg class="mx-auto h-12 w-12 text-gray-400" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M17 20h5v-2a3 3 0 00-5.356-1.857M17 20H7m10 0v-2c0-.656-.126-1.283-.356-1.857M7 20H2v-2a3 3 0 015.356-1.857M7 20v-2c0-.656.126-1.283.356-1.857m0 0a5.002 5.002 0 019.288 0M15 7a3 3 0 11-6 0 3 3 0 016 0zm6 3a2 2 0 11-4 0 2 2 0 014 0zM7 10a2 2 0 11-4 0 2 2 0 014 0z" />
            </svg>
            <h3 class="mt-2 text-sm font-medium text-gray-900">Nenhum usuário encontrado</h3>
            <p class="mt-1 text-sm text-gray-500">
              {podeVerTodos ? 'Não há usuários cadastrados no sistema.' : 'Você não tem permissão para ver outros usuários.'}
            </p>
          </div>
        </Card>
      {/if}
    {/if}
  </div>
</div>

<!-- Modal de Edição -->
{#if showEditarModal && usuarioSelecionado}
  <EditarUsuarioModal
    usuario={usuarioSelecionado}
    on:close={fecharEditarModal}
    on:usuario-editado={handleUsuarioEditado}
  />
{:else}
  <!-- Debug: Modal não está sendo exibido -->
  <div style="display: none;">
    Debug: showEditarModal = {showEditarModal}, usuarioSelecionado = {usuarioSelecionado?.nome || 'null'}
  </div>
{/if}