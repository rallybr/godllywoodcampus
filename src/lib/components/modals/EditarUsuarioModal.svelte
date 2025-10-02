<script>
  import { createEventDispatcher } from 'svelte';
  import { userProfile, hasRole } from '$lib/stores/auth';
  import { atualizarUsuario, uploadFotoUsuario, deletarFotoAntiga, buscarPapeisDisponiveis, buscarPapeisUsuario, atribuirPapelUsuario, removerPapelUsuario } from '$lib/stores/usuarios';
  import { loadInitialData, estados, blocos, regioes, igrejas, loadBlocos, loadRegioes, loadIgrejas, clearHierarchy } from '$lib/stores/geographic';
  import Button from '$lib/components/ui/Button.svelte';
  import Card from '$lib/components/ui/Card.svelte';
  import Select from '$lib/components/ui/Select.svelte';

  const dispatch = createEventDispatcher();

  export let usuario;
  export let isOpen = true;

  // Debug logs
  $: console.log('EditarUsuarioModal - usuario:', usuario);
  $: console.log('EditarUsuarioModal - isOpen:', isOpen);

  let loading = false;
  let error = null;
  let success = null;
  let fotoPreview = null;
  let arquivoFoto = null;
  let papeisDisponiveis = [];
  let papeisUsuario = [];
  let carregandoPapeis = false;
  let novoPapel = '';
  let estadoId = null;
  let blocoId = null;
  let regiaoId = null;
  let igrejaId = null;
  let dadosFormulario = {
    nome: usuario?.nome || '',
    email: usuario?.email || '',
    sexo: usuario?.sexo || '',
    nivel: usuario?.nivel || '',
    ativo: usuario?.ativo !== undefined ? usuario.ativo : true
  };

  // Verificar se pode editar (próprio perfil ou administrador)
  $: podeEditar = hasRole('administrador')($userProfile) || usuario?.id === $userProfile?.id;

  // Verificar se pode alterar nível (apenas administradores)
  $: podeAlterarNivel = hasRole('administrador')($userProfile);

  // Verificar se pode alterar status ativo (apenas administradores)
  $: podeAlterarStatus = hasRole('administrador')($userProfile);

  // Carregar papéis quando o modal abrir
  $: if (isOpen && usuario?.id) {
    carregarPapeisDisponiveis();
    carregarPapeisUsuario();
    carregarDadosGeograficos();
  }

  // Carregar dados geográficos iniciais
  async function carregarDadosGeograficos() {
    await loadInitialData();
    
    // Pré-selecionar valores atuais do usuário se existirem
    if (usuario?.estado_id) {
      estadoId = usuario.estado_id;
      await loadBlocos(usuario.estado_id);
      
      if (usuario?.bloco_id) {
        blocoId = usuario.bloco_id;
        await loadRegioes(usuario.bloco_id);
        
        if (usuario?.regiao_id) {
          regiaoId = usuario.regiao_id;
          await loadIgrejas(usuario.regiao_id);
          
          if (usuario?.igreja_id) {
            igrejaId = usuario.igreja_id;
          }
        }
      }
    }
  }

  // Pré-selecionar o papel atual quando os papéis estiverem carregados
  $: if (papeisDisponiveis.length > 0 && usuario?.nivel) {
    const papelAtual = papeisDisponiveis.find(p => p.slug === usuario.nivel);
    if (papelAtual) {
      novoPapel = papelAtual.id;
    }
  }

  function fecharModal() {
    dispatch('close');
  }

  // Função para lidar com mudança de estado
  async function handleEstadoChange(event) {
    const novoEstadoId = event.detail.value;
    estadoId = novoEstadoId;
    blocoId = null;
    regiaoId = null;
    igrejaId = null;
    clearHierarchy();
    
    if (novoEstadoId) {
      await loadBlocos(novoEstadoId);
    }
  }

  // Função para lidar com mudança de bloco
  async function handleBlocoChange(event) {
    const novoBlocoId = event.detail.value;
    blocoId = novoBlocoId;
    regiaoId = null;
    igrejaId = null;
    regioes.set([]);
    igrejas.set([]);
    
    if (novoBlocoId) {
      await loadRegioes(novoBlocoId);
    }
  }

  // Função para lidar com mudança de região
  async function handleRegiaoChange(event) {
    const novaRegiaoId = event.detail.value;
    regiaoId = novaRegiaoId;
    igrejaId = null;
    igrejas.set([]);
    
    if (novaRegiaoId) {
      await loadIgrejas(novaRegiaoId);
    }
  }

  // Função para lidar com mudança de igreja
  function handleIgrejaChange(event) {
    igrejaId = event.detail.value;
  }

  // Carregar papéis disponíveis
  async function carregarPapeisDisponiveis() {
    try {
      carregandoPapeis = true;
      papeisDisponiveis = await buscarPapeisDisponiveis();
    } catch (err) {
      console.error('Erro ao carregar papéis:', err);
      error = 'Erro ao carregar papéis disponíveis';
    } finally {
      carregandoPapeis = false;
    }
  }

  // Carregar papéis do usuário
  async function carregarPapeisUsuario() {
    try {
      papeisUsuario = await buscarPapeisUsuario(usuario?.id);
    } catch (err) {
      console.error('Erro ao carregar papéis do usuário:', err);
    }
  }

  // Atribuir novo papel (substitui o papel existente)
  async function atribuirNovoPapel() {
    if (!novoPapel) return;
    
    try {
      loading = true;
      error = null;
      
      // Primeiro, remover todos os papéis existentes
      for (const papel of papeisUsuario) {
        await removerPapelUsuario(papel.id);
      }
      
      // Encontrar o papel selecionado para obter o slug
      const papelSelecionado = papeisDisponiveis.find(p => p.id === novoPapel);
      if (!papelSelecionado) {
        error = 'Papel selecionado não encontrado';
        return;
      }
      
      // Depois, atribuir o novo papel
      const resultado = await atribuirPapelUsuario(
        usuario?.id,
        novoPapel,
        estadoId,
        blocoId,
        regiaoId,
        igrejaId
      );
      
      if (resultado.success) {
        await carregarPapeisUsuario();
        // Atualizar o nível do usuário para corresponder ao papel
        dadosFormulario.nivel = papelSelecionado.slug;
        success = 'Papel atualizado com sucesso!';
      } else {
        error = resultado.error || 'Erro ao atribuir papel';
      }
    } catch (err) {
      error = 'Erro ao atribuir papel: ' + err.message;
    } finally {
      loading = false;
    }
  }

  // Remover papel
  async function removerPapel(papelId) {
    if (!confirm('Tem certeza que deseja remover este papel?')) return;
    
    try {
      loading = true;
      error = null;
      
      const resultado = await removerPapelUsuario(papelId);
      
      if (resultado.success) {
        await carregarPapeisUsuario();
        success = 'Papel removido com sucesso!';
      } else {
        error = resultado.error || 'Erro ao remover papel';
      }
    } catch (err) {
      error = 'Erro ao remover papel: ' + err.message;
    } finally {
      loading = false;
    }
  }

  function handleFotoChange(event) {
    const arquivo = event.target.files[0];
    if (arquivo) {
      // Validar tipo de arquivo
      if (!arquivo.type.startsWith('image/')) {
        error = 'Por favor, selecione apenas arquivos de imagem.';
        return;
      }

      // Validar tamanho (máximo 5MB)
      if (arquivo.size > 5 * 1024 * 1024) {
        error = 'A imagem deve ter no máximo 5MB.';
        return;
      }

      arquivoFoto = arquivo;
      
      // Criar preview
      const reader = new FileReader();
      reader.onload = (e) => {
        fotoPreview = e.target.result;
      };
      reader.readAsDataURL(arquivo);
    }
  }

  function removerFoto() {
    arquivoFoto = null;
    fotoPreview = null;
    document.getElementById('foto-input').value = '';
  }

  async function handleSubmit() {
    if (!podeEditar) {
      error = 'Você não tem permissão para editar este usuário.';
      return;
    }

    loading = true;
    error = null;
    success = null;

    try {
      let dadosAtualizacao = { 
        ...dadosFormulario,
        estado_id: estadoId,
        bloco_id: blocoId,
        regiao_id: regiaoId,
        igreja_id: igrejaId
      };

      // Upload da nova foto se houver
      if (arquivoFoto) {
      // Deletar foto antiga se existir
      if (usuario?.foto) {
        await deletarFotoAntiga(usuario.foto);
      }

        // Upload da nova foto
        const novaFotoUrl = await uploadFotoUsuario(usuario?.id, arquivoFoto);
        dadosAtualizacao.foto = novaFotoUrl;
      }

      // Atualizar usuário
      await atualizarUsuario(usuario?.id, dadosAtualizacao);

      success = 'Usuário atualizado com sucesso!';
      
      // Emitir evento de sucesso
      setTimeout(() => {
        dispatch('usuario-editado');
      }, 1000);

    } catch (err) {
      error = err.message || 'Erro ao atualizar usuário.';
      console.error('Erro ao atualizar usuário:', err);
    } finally {
      loading = false;
    }
  }

  function handleKeydown(event) {
    if (event.key === 'Escape') {
      fecharModal();
    }
  }
</script>

<svelte:window on:keydown={handleKeydown} />

{#if isOpen}
  <!-- Overlay -->
  <div 
    class="fixed inset-0 bg-gray-600 bg-opacity-50 overflow-y-auto h-full w-full z-50" 
    role="dialog"
    aria-label="Modal de edição de usuário"
  >
    <div 
      class="relative top-20 mx-auto p-5 border w-11/12 max-w-2xl shadow-lg rounded-md bg-white" 
      role="dialog"
      aria-modal="true"
      aria-labelledby="modal-title"
    >
      <!-- Header -->
      <div class="flex items-center justify-between mb-4">
        <h3 id="modal-title" class="text-lg font-medium text-gray-900">
          Editar Usuário
        </h3>
        <button
          on:click={fecharModal}
          class="text-gray-400 hover:text-gray-600 transition-colors"
        >
          <svg class="w-6 h-6" fill="none" viewBox="0 0 24 24" stroke="currentColor">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12" />
          </svg>
        </button>
      </div>

      <!-- Formulário -->
      <form on:submit|preventDefault={handleSubmit}>
        <div class="space-y-6">
          <!-- Foto do Usuário -->
          <div class="flex flex-col items-center space-y-4">
            <div class="relative">
              {#if fotoPreview}
                <img src={fotoPreview} alt="Preview" class="w-24 h-24 rounded-full object-cover border-4 border-white shadow-lg" />
              {:else if usuario?.foto}
                <img src={usuario.foto} alt={usuario?.nome || 'Usuário'} class="w-24 h-24 rounded-full object-cover border-4 border-white shadow-lg" />
              {:else}
                <div class="w-24 h-24 rounded-full bg-gray-200 flex items-center justify-center border-4 border-white shadow-lg">
                  <span class="text-gray-600 font-bold text-2xl">{usuario?.nome?.charAt(0) || 'U'}</span>
                </div>
              {/if}
              
              <!-- Botão de upload -->
              <label for="foto-input" class="absolute bottom-0 right-0 bg-blue-600 text-white rounded-full p-2 cursor-pointer hover:bg-blue-700 transition-colors">
                <svg class="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3 9a2 2 0 012-2h.93a2 2 0 001.664-.89l.812-1.22A2 2 0 0110.07 4h3.86a2 2 0 011.664.89l.812 1.22A2 2 0 0018.07 7H19a2 2 0 012 2v9a2 2 0 01-2 2H5a2 2 0 01-2-2V9z" />
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 13a3 3 0 11-6 0 3 3 0 016 0z" />
                </svg>
              </label>
              
              <input
                id="foto-input"
                type="file"
                accept="image/*"
                on:change={handleFotoChange}
                class="hidden"
              />
            </div>
            
            {#if arquivoFoto}
              <div class="flex items-center space-x-2">
                <span class="text-sm text-gray-600">Nova foto selecionada</span>
                <button
                  type="button"
                  on:click={removerFoto}
                  class="text-red-600 hover:text-red-800 text-sm"
                >
                  Remover
                </button>
              </div>
            {/if}
          </div>

          <!-- Informações Básicas -->
          <div class="grid grid-cols-1 sm:grid-cols-2 gap-4">
            <!-- Nome -->
            <div>
              <label for="nome" class="block text-sm font-medium text-gray-700 mb-1">
                Nome *
              </label>
              <input
                id="nome"
                type="text"
                bind:value={dadosFormulario.nome}
                required
                class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-blue-500"
                placeholder="Nome completo"
              />
            </div>

            <!-- Email -->
            <div>
              <label for="email" class="block text-sm font-medium text-gray-700 mb-1">
                Email *
              </label>
              <input
                id="email"
                type="email"
                bind:value={dadosFormulario.email}
                required
                class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-blue-500"
                placeholder="email@exemplo.com"
              />
            </div>

            <!-- Sexo -->
            <div>
              <label for="sexo" class="block text-sm font-medium text-gray-700 mb-1">
                Sexo
              </label>
              <select
                id="sexo"
                bind:value={dadosFormulario.sexo}
                class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-blue-500"
              >
                <option value="">Selecione</option>
                <option value="masculino">Masculino</option>
                <option value="feminino">Feminino</option>
                <option value="outro">Outro</option>
              </select>
            </div>

            <!-- Nível (apenas administradores) -->
            {#if podeAlterarNivel}
              <div>
                <label for="nivel" class="block text-sm font-medium text-gray-700 mb-1">
                  Nível
                </label>
                <select
                  id="nivel"
                  bind:value={dadosFormulario.nivel}
                  class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-blue-500"
                >
                  <option value="jovem">Jovem</option>
                  <option value="colaborador">Colaborador</option>
                  <option value="lider_igreja_iurd">Líder Igreja IURD</option>
                  <option value="lider_regional_iurd">Líder Regional IURD</option>
                  <option value="lider_bloco_fju">Líder Bloco FJU</option>
                  <option value="lider_bloco_iurd">Líder Bloco IURD</option>
                  <option value="lider_estadual_fju">Líder Estadual FJU</option>
                  <option value="lider_estadual_iurd">Líder Estadual IURD</option>
                  <option value="lider_nacional_fju">Líder Nacional FJU</option>
                  <option value="lider_nacional_iurd">Líder Nacional IURD</option>
                  <option value="administrador">Administrador</option>
                </select>
              </div>
            {/if}
          </div>

          <!-- Status Ativo (apenas administradores) -->
          {#if podeAlterarStatus}
            <div class="flex items-center">
              <input
                id="ativo"
                type="checkbox"
                bind:checked={dadosFormulario.ativo}
                class="h-4 w-4 text-blue-600 focus:ring-blue-500 border-gray-300 rounded"
              />
              <label for="ativo" class="ml-2 block text-sm text-gray-900">
                Usuário ativo
              </label>
            </div>
          {/if}

          <!-- Seção de Papéis (apenas administradores) -->
          {#if podeAlterarNivel}
            <div class="border-t pt-6">
              <h4 class="text-lg font-medium text-gray-900 mb-4">Gerenciar Papéis</h4>
              
              <!-- Papel Atual -->
              <div class="mb-6">
                <h5 class="text-sm font-medium text-gray-700 mb-3">Papel Atual</h5>
                {#if papeisUsuario.length > 0}
                  <div class="bg-gray-50 p-3 rounded-md">
                    <div class="flex items-center justify-between">
                      <div class="flex items-center space-x-3">
                        <span class="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-blue-100 text-blue-800">
                          {papeisUsuario[0].role_nome}
                        </span>
                        <span class="text-sm text-gray-600">
                          Nível: {papeisUsuario[0].nivel_hierarquico}
                        </span>
                      </div>
                      <button
                        on:click={() => removerPapel(papeisUsuario[0].id)}
                        class="text-red-600 hover:text-red-800 p-1"
                        title="Remover papel"
                      >
                        <svg class="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16" />
                        </svg>
                      </button>
                    </div>
                  </div>
                {:else}
                  <p class="text-sm text-gray-500 italic">Nenhum papel atribuído</p>
                {/if}
              </div>

              <!-- Alterar Papel -->
              <div>
                <h5 class="text-sm font-medium text-gray-700 mb-3">Alterar Papel</h5>
                <div class="space-y-4">
                  <div>
                    <label for="novo-papel" class="block text-sm font-medium text-gray-700 mb-1">
                      Papel
                    </label>
                    <select
                      id="novo-papel"
                      bind:value={novoPapel}
                      class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-blue-500"
                    >
                      <option value="">Selecione um papel</option>
                      {#each papeisDisponiveis as papel}
                        <option value={papel.id}>{papel.nome} (Nível {papel.nivel_hierarquico})</option>
                      {/each}
                    </select>
                  </div>

                  <div class="grid grid-cols-2 gap-4">
                    <div>
                      <Select
                        label="Estado (opcional)"
                        bind:value={estadoId}
                        on:change={handleEstadoChange}
                        placeholder="Selecione o estado"
                        options={$estados.map(estado => ({
                          value: estado.id,
                          label: estado.nome
                        }))}
                      />
                    </div>
                    <div>
                      <Select
                        label="Bloco (opcional)"
                        bind:value={blocoId}
                        on:change={handleBlocoChange}
                        disabled={!estadoId}
                        placeholder="Selecione o bloco"
                        options={$blocos.map(bloco => ({
                          value: bloco.id,
                          label: bloco.nome
                        }))}
                      />
                    </div>
                    <div>
                      <Select
                        label="Região (opcional)"
                        bind:value={regiaoId}
                        on:change={handleRegiaoChange}
                        disabled={!blocoId}
                        placeholder="Selecione a região"
                        options={$regioes.map(regiao => ({
                          value: regiao.id,
                          label: regiao.nome
                        }))}
                      />
                    </div>
                    <div>
                      <Select
                        label="Igreja (opcional)"
                        bind:value={igrejaId}
                        on:change={handleIgrejaChange}
                        disabled={!regiaoId}
                        placeholder="Selecione a igreja"
                        options={$igrejas.map(igreja => ({
                          value: igreja.id,
                          label: igreja.nome
                        }))}
                      />
                    </div>
                  </div>

                  <button
                    type="button"
                    on:click={atribuirNovoPapel}
                    disabled={!novoPapel || loading}
                    class="w-full bg-blue-600 text-white px-4 py-2 rounded-md hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:ring-offset-2 disabled:opacity-50 disabled:cursor-not-allowed"
                  >
                    {loading ? 'Alterando...' : 'Alterar Papel'}
                  </button>
                </div>
              </div>
            </div>
          {/if}

          <!-- Informações do Sistema (somente leitura) -->
          <div class="bg-gray-50 p-4 rounded-md">
            <h4 class="text-sm font-medium text-gray-900 mb-2">Informações do Sistema</h4>
            <div class="grid grid-cols-1 sm:grid-cols-2 gap-4 text-sm">
              <div>
                <span class="text-gray-600">ID:</span>
                <span class="ml-2 font-mono text-gray-900">{usuario.id}</span>
              </div>
              <div>
                <span class="text-gray-600">Criado em:</span>
                <span class="ml-2 text-gray-900">
                  {new Date(usuario.criado_em).toLocaleDateString('pt-BR')}
                </span>
              </div>
              <div>
                <span class="text-gray-600">Nível atual:</span>
                <span class="ml-2 text-gray-900">{usuario.nivel}</span>
              </div>
              <div>
                <span class="text-gray-600">Status:</span>
                <span class="ml-2 text-gray-900">
                  {usuario.ativo ? 'Ativo' : 'Inativo'}
                </span>
              </div>
            </div>
          </div>

          <!-- Mensagens de Erro/Sucesso -->
          {#if error}
            <div class="bg-red-50 border border-red-200 rounded-md p-3">
              <div class="flex">
                <svg class="h-5 w-5 text-red-400" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-2.5L13.732 4c-.77-.833-1.732-.833-2.5 0L4.268 19.5c-.77.833.192 2.5 1.732 2.5z" />
                </svg>
                <div class="ml-3">
                  <p class="text-sm text-red-800">{error}</p>
                </div>
              </div>
            </div>
          {/if}

          {#if success}
            <div class="bg-green-50 border border-green-200 rounded-md p-3">
              <div class="flex">
                <svg class="h-5 w-5 text-green-400" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z" />
                </svg>
                <div class="ml-3">
                  <p class="text-sm text-green-800">{success}</p>
                </div>
              </div>
            </div>
          {/if}
        </div>

        <!-- Botões -->
        <div class="flex justify-end space-x-3 mt-6 pt-4 border-t border-gray-200">
          <Button
            type="button"
            variant="outline"
            on:click={fecharModal}
            disabled={loading}
          >
            Cancelar
          </Button>
          <Button
            type="submit"
            disabled={loading || !podeEditar}
            class="bg-blue-600 hover:bg-blue-700 text-white"
          >
            {#if loading}
              <svg class="animate-spin -ml-1 mr-2 h-4 w-4 text-white" fill="none" viewBox="0 0 24 24">
                <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle>
                <path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
              </svg>
              Salvando...
            {:else}
              Salvar Alterações
            {/if}
          </Button>
        </div>
      </form>
    </div>
  </div>
{/if}