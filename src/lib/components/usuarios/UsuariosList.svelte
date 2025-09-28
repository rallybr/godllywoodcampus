<script>
  import { onMount } from 'svelte';
  import { writable } from 'svelte/store';
  import { buscarUsuarios, updateUsuario, roles, loadRoles, usuarios, deleteUsuario } from '$lib/stores/usuarios';
  import { loadUserRoles } from '$lib/stores/niveis-acesso';
  import { userProfile } from '$lib/stores/auth';
  import { createLogHistorico } from '$lib/stores/logs-historico';
  import { goto } from '$app/navigation';
  import Button from '$lib/components/ui/Button.svelte';
  import Card from '$lib/components/ui/Card.svelte';
  import Input from '$lib/components/ui/Input.svelte';
  import Select from '$lib/components/ui/Select.svelte';
  import EditarUsuarioModal from '$lib/components/modals/EditarUsuarioModal.svelte';
  import Autocomplete from '$lib/components/ui/Autocomplete.svelte';
  
  let userRoles = [];
  let loading = true;
  let error = '';
  let searchTerm = '';
  let filterRole = '';
  let filterStatus = '';
  let forceUpdate = 0; // Para forçar reatividade
  
  // Store reativo para searchTerm
  const searchTermStore = writable('');
  
  // Modal de edição
  let showEditModal = false;
  let usuarioParaEditar = null;
  
  onMount(async () => {
    await loadData();
  });
  
  async function loadData() {
    loading = true;
    error = '';
    
    try {
      await Promise.all([
        buscarUsuarios(),
        loadUserRoles(),
        loadRoles()
      ]);
      console.log('Dados carregados, usuários:', $usuarios);
      console.log('Primeiro usuário:', $usuarios[0]);
      console.log('Estrutura do primeiro usuário:', $usuarios[0] ? Object.keys($usuarios[0]) : 'Nenhum usuário');
    } catch (err) {
      error = err.message;
    } finally {
      loading = false;
    }
  }
  
  // Utilitários de normalização
  function normalize(str) {
    return (str || '')
      .toString()
      .normalize('NFD')
      .replace(/\p{Diacritic}+/gu, '')
      .toLowerCase();
  }

  // Lista filtrada reativa (derivada)
  $: filteredUsuarios = (() => {
    const currentSearchTerm = $searchTermStore || searchTerm;
    console.log('derived filteredUsuarios com searchTerm:', currentSearchTerm, 'forceUpdate:', forceUpdate);

    const termNorm = normalize((currentSearchTerm || '').trim());

    const result = ($usuarios || []).filter((usuario) => {
      // Filtro por termo de busca
      if (termNorm) {
        const nomeNorm = normalize(usuario?.nome);
        const emailNorm = normalize(usuario?.email);
        if (!nomeNorm.includes(termNorm) && !emailNorm.includes(termNorm)) return false;
      }

      // Filtro por papel
      if (filterRole) {
        const userRole = userRoles.find((ur) => ur.user_id === usuario.id && ur.ativo);
        if (!userRole || userRole.role_id !== filterRole) return false;
      }

      // Filtro por status
      if (filterStatus === 'ativo' && !usuario.ativo) return false;
      if (filterStatus === 'inativo' && usuario.ativo) return false;

      return true;
    });

    console.log('Usuários filtrados (derived):', result.length, 'de', $usuarios.length);
    return result;
  })();
  
  // Função para obter papel do usuário
  function getUserRole(usuarioId) {
    return userRoles.find(ur => ur.user_id === usuarioId && ur.ativo);
  }
  
  // Função para obter cor do papel
  function getRoleColor(roleSlug) {
    const colors = {
      'administrador': 'bg-red-100 text-red-800',
      'colaborador': 'bg-blue-100 text-blue-800',
      'lider_nacional_iurd': 'bg-purple-100 text-purple-800',
      'lider_nacional_fju': 'bg-purple-100 text-purple-800',
      'lider_estadual_iurd': 'bg-green-100 text-green-800',
      'lider_estadual_fju': 'bg-green-100 text-green-800',
      'lider_bloco_iurd': 'bg-yellow-100 text-yellow-800',
      'lider_bloco_fju': 'bg-yellow-100 text-yellow-800',
      'lider_regional_iurd': 'bg-orange-100 text-orange-800',
      'lider_igreja_iurd': 'bg-gray-100 text-gray-800'
    };
    
    return colors[roleSlug] || 'bg-gray-100 text-gray-800';
  }
  
  // Função para alternar status do usuário
  async function toggleUsuarioStatus(usuario) {
    try {
      await updateUsuario(usuario.id, { ativo: !usuario.ativo });
      await loadData();
    } catch (err) {
      error = err.message;
    }
  }

  async function handleDeleteUsuario(usuario) {
    if ($userProfile?.nivel !== 'administrador') return;
    const confirmed = confirm(`Excluir o usuário "${usuario.nome}"? Esta ação não pode ser desfeita.`);
    if (!confirmed) return;

    try {
      const dadosAnteriores = { id: usuario.id, nome: usuario.nome, email: usuario.email };
      await deleteUsuario(usuario.id);
      // log (sem jovem_id)
      try {
        await createLogHistorico(null, 'exclusao_usuario', `Usuário excluído: ${usuario.email}`, dadosAnteriores, null);
      } catch (e) {
        console.warn('Falha ao registrar log de exclusão de usuário:', e);
      }
      await loadData();
    } catch (err) {
      error = err.message;
    }
  }
  
  // Função para formatar data
  function formatDate(dateString) {
    if (!dateString) return 'Não informado';
    try {
      return new Date(dateString + 'T00:00:00').toLocaleDateString('pt-BR');
    } catch {
      return dateString;
    }
  }
  
  // Função para abrir modal de edição
  function openEditModal(usuario) {
    usuarioParaEditar = usuario;
    showEditModal = true;
  }
  
  // Função para fechar modal
  function closeEditModal() {
    showEditModal = false;
    usuarioParaEditar = null;
  }
  
  // Função para lidar com sucesso da edição
  async function handleEditSuccess(event) {
    const { usuario: usuarioId, updates } = event.detail;
    
    // Recarregar dados
    await loadData();
    
    closeEditModal();
  }
  
  // Função para lidar com seleção de sugestão no autocomplete
  function handleSelectSuggestion(suggestion) {
    console.log('Sugestão selecionada:', suggestion);
    
    searchTerm = suggestion.nome;
    searchTermStore.set(suggestion.nome); // Atualizar store reativo
    forceUpdate++; // Forçar reatividade
    console.log('searchTerm definido como:', searchTerm, 'forceUpdate:', forceUpdate);
    
    // Forçar re-renderização
    setTimeout(() => {
      forceUpdate++;
      console.log('Forçando re-renderização, forceUpdate:', forceUpdate);
    }, 10);
  }
</script>

<div class="space-y-6">
  <!-- Header -->
  <div class="flex flex-col sm:flex-row sm:items-center sm:justify-between">
    <div>
      <h1 class="text-2xl font-bold text-gray-900">Usuários</h1>
      <p class="text-gray-600">Gerencie os usuários do sistema</p>
    </div>
    <div class="mt-4 sm:mt-0">
      <Button href="/usuarios/cadastrar" variant="primary">
        <svg class="w-5 h-5 mr-2" fill="none" viewBox="0 0 24 24" stroke="currentColor">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 6v6m0 0v6m0-6h6m-6 0H6" />
        </svg>
        Cadastrar Usuário
      </Button>
    </div>
  </div>
  
  <!-- Filtros -->
  <Card class="p-6">
    <div class="grid grid-cols-1 md:grid-cols-3 gap-4">
      <div>
        <label for="search-usuarios" class="block text-sm font-medium text-gray-700 mb-1">
          Buscar
        </label>
        <Autocomplete
          id="search-usuarios"
          placeholder="Nome ou email"
          bind:value={searchTerm}
          minLength={1}
          debounceMs={100}
          on:select={(e) => handleSelectSuggestion(e.detail.suggestion)}
          searchFunction={async (term) => {
            console.log('searchFunction chamada com term:', term);
            console.log('usuarios disponíveis:', $usuarios);
            if (!term || term.length < 1) return [];
            
            // Normalizar acentos e caixa
            const normalize = (s) => (s || '')
              .toString()
              .normalize('NFD')
              .replace(/\p{Diacritic}+/gu, '')
              .toLowerCase();

            const termNorm = normalize(term.trim());

            // Priorizar quem começa com o termo; depois quem contém
            const startsWith = [];
            const includes = [];

            for (const usuario of $usuarios) {
              const nomeNorm = normalize(usuario.nome);
              const emailNorm = normalize(usuario.email);
              const matchStart = nomeNorm.startsWith(termNorm) || emailNorm.startsWith(termNorm);
              const matchInclude = !matchStart && (nomeNorm.includes(termNorm) || emailNorm.includes(termNorm));
              if (matchStart) startsWith.push(usuario);
              else if (matchInclude) includes.push(usuario);
            }

            const result = [...startsWith, ...includes]
              .slice(0, 8)
              .map((usuario) => ({
                id: usuario.id,
                nome: usuario.nome,
                email: usuario.email,
                display: `${usuario.nome} (${usuario.email})`
              }));
            console.log('resultado filtrado:', result);
            return result;
          }}
        />
      </div>
      
      <Select
        label="Papel"
        bind:value={filterRole}
        options={[
          { value: '', label: 'Todos os papéis' },
          ...$roles.map(role => ({
            value: role.id,
            label: role.nome
          }))
        ]}
      />
      
      <Select
        label="Status"
        bind:value={filterStatus}
        options={[
          { value: '', label: 'Todos os status' },
          { value: 'ativo', label: 'Ativo' },
          { value: 'inativo', label: 'Inativo' }
        ]}
      />
    </div>
  </Card>
  
  <!-- Lista de Usuários -->
  <div class="space-y-4">
    {#if loading}
      <div class="flex items-center justify-center py-12">
        <div class="animate-spin rounded-full h-12 w-12 border-b-2 border-blue-600"></div>
      </div>
    {:else if error}
      <div class="bg-red-50 border border-red-200 rounded-lg p-4">
        <div class="flex items-center space-x-2">
          <svg class="w-5 h-5 text-red-500" fill="none" viewBox="0 0 24 24" stroke="currentColor">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8v4m0 4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
          </svg>
          <p class="text-sm text-red-600 font-medium">{error}</p>
        </div>
      </div>
    {:else if filteredUsuarios.length === 0}
      <Card class="p-8">
        <div class="text-center">
          <div class="w-16 h-16 bg-gray-100 rounded-full flex items-center justify-center mx-auto mb-4">
            <svg class="w-8 h-8 text-gray-400" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4.354a4 4 0 110 5.292M15 21H3v-1a6 6 0 0112 0v1zm0 0h6v-1a6 6 0 00-9-5.197m13.5-9a2.5 2.5 0 11-5 0 2.5 2.5 0 015 0z" />
            </svg>
          </div>
          <h3 class="text-lg font-semibold text-gray-900 mb-2">Nenhum usuário encontrado</h3>
          <p class="text-gray-600 mb-4">Não há usuários que correspondam aos filtros aplicados.</p>
          <Button href="/usuarios/cadastrar" variant="primary">
            Cadastrar Primeiro Usuário
          </Button>
        </div>
      </Card>
    {:else}
      <!-- Lista de usuários -->
      <div class="space-y-4">
        {#each filteredUsuarios as usuario}
          <Card class="p-6">
            <div class="flex items-start space-x-4">
              <!-- Foto -->
              <div class="flex-shrink-0">
                {#if usuario.foto}
                  <img class="w-12 h-12 rounded-full object-cover" src={usuario.foto} alt={usuario.nome} />
                {:else}
                  <div class="w-12 h-12 bg-gradient-to-br from-blue-500 to-purple-600 rounded-full flex items-center justify-center">
                    <span class="text-white font-bold text-sm">{usuario.nome?.charAt(0) || 'U'}</span>
                  </div>
                {/if}
              </div>
              
              <!-- Informações -->
              <div class="flex-1 min-w-0">
                <div class="flex items-start justify-between">
                  <div>
                    <h3 class="text-lg font-semibold text-gray-900">{usuario.nome}</h3>
                    <p class="text-sm text-gray-600">{usuario.email}</p>
                    <p class="text-xs text-gray-500 mt-1">
                      Cadastrado em {formatDate(usuario.criado_em)}
                    </p>
                  </div>
                  
                  <div class="flex items-center space-x-2">
                    <!-- Status -->
                    <span class="inline-flex items-center px-2 py-1 rounded-full text-xs font-medium {
                      usuario.ativo ? 'bg-green-100 text-green-800' : 'bg-red-100 text-red-800'
                    }">
                      {usuario.ativo ? 'Ativo' : 'Inativo'}
                    </span>
                    
                    <!-- Papel -->
                    {#if getUserRole(usuario.id)}
                      <span class="inline-flex items-center px-2 py-1 rounded-full text-xs font-medium {
                        getRoleColor(getUserRole(usuario.id).role.slug)
                      }">
                        {getUserRole(usuario.id).role.nome}
                      </span>
                    {/if}
                  </div>
                </div>
                
                <!-- Localização -->
                <div class="mt-2 text-sm text-gray-500">
                  {#if usuario.estado}
                    {usuario.estado.nome}
                    {#if usuario.bloco} • {usuario.bloco.nome}{/if}
                    {#if usuario.regiao} • {usuario.regiao.nome}{/if}
                    {#if usuario.igreja} • {usuario.igreja.nome}{/if}
                  {:else}
                    Sem localização definida
                  {/if}
                </div>
              </div>
              
              <!-- Ações -->
              <div class="flex flex-col sm:flex-row items-stretch sm:items-center space-y-2 sm:space-y-0 sm:space-x-2">
                <Button
                  size="sm"
                  variant="outline"
                  on:click={() => goto(`/usuarios/${usuario.id}`)}
                >
                  <svg class="w-4 h-4 mr-1" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M16 7a4 4 0 11-8 0 4 4 0 018 0zM12 14a7 7 0 00-7 7h14a7 7 0 00-7-7z" />
                  </svg>
                  Ver Perfil
                </Button>
                
                <Button
                  size="sm"
                  variant="outline"
                  on:click={() => openEditModal(usuario)}
                >
                  <svg class="w-4 h-4 mr-1" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M11 5H6a2 2 0 00-2 2v11a2 2 0 002 2h11a2 2 0 002-2v-5m-1.414-9.414a2 2 0 112.828 2.828L11.828 15H9v-2.828l8.586-8.586z" />
                  </svg>
                  Editar Papel
                </Button>
                
                <Button
                  size="sm"
                  variant={usuario.ativo ? 'outline' : 'primary'}
                  on:click={() => toggleUsuarioStatus(usuario)}
                >
                  {usuario.ativo ? 'Desativar' : 'Ativar'}
                </Button>

                {#if $userProfile?.nivel === 'administrador'}
                  <Button
                    size="sm"
                    variant="danger"
                    on:click={() => handleDeleteUsuario(usuario)}
                  >
                    <svg class="w-4 h-4 mr-1" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6M9 7h6m-7 0a2 2 0 002-2h2a2 2 0 002 2m-8 0h10" />
                    </svg>
                    Excluir
                  </Button>
                {/if}
              </div>
            </div>
          </Card>
        {/each}
      </div>
    {/if}
  </div>
  
  <!-- Modal de Edição -->
  <EditarUsuarioModal
    bind:isOpen={showEditModal}
    usuario={usuarioParaEditar}
    on:success={handleEditSuccess}
    on:close={closeEditModal}
  />
</div>
