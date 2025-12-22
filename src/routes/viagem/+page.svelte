<script>
  import { onMount } from 'svelte';
  import ViagemCard from '$lib/components/viagem/ViagemCard.svelte';
  import UploadComprovante from '$lib/components/viagem/UploadComprovanteSimples.svelte';
  import { 
    loadViagensCards, 
    loadViagensCardsForJovem,
    filteredViagens, 
    loading, 
    error,
    pagination,
    uploadComprovantePagamento,
    uploadComprovanteIda,
    uploadComprovanteVolta,
    removeComprovante,
    deleteViagemCard,
    getEdicaoAtiva
  } from '$lib/stores/viagem';
  import { userProfile, hasRole } from '$lib/stores/auth';
  import { estadosCache, edicoesCache, condicoesCache, loadEstadosOnce, loadEdicoesOnce, loadCondicoesOnce } from '$lib/stores/viagem';

  function getViagemData(jovem) { 
    if (!jovem) return null;
    return jovem.viagem || null; 
  }

  let edicaoAtiva = null;
  let uploadModal = {
    isOpen: false,
    tipo: undefined,
    jovemId: '',
    edicaoId: '',
    loading: false
  };

  // Controles
  let sortBy = 'estado_id';
  let sortDir = 'asc';
  let pageSize = 20;
  let selectedEstado = '';
  let selectedEdicao = '';
  let selectedCondicao = '';

  // Flags de controle de carregamento
  let readyToLoad = false;
  let initialLoaded = false;

  onMount(async () => {
    try {
      console.log('🚀 Iniciando carregamento da página de viagem...');

      // Carregar edição ativa primeiro
      try {
        edicaoAtiva = await getEdicaoAtiva();
        console.log('✅ Edição ativa carregada:', edicaoAtiva);
      } catch (edicaoError) {
        console.error('❌ Erro ao carregar edição ativa:', edicaoError);
        edicaoAtiva = null;
      }

      // Carregar caches auxiliares (estados/edições/condições)
      try {
        await Promise.all([loadEstadosOnce(), loadEdicoesOnce(), loadCondicoesOnce()]);
      } catch (viagemError) {
        console.error('❌ Erro ao carregar caches iniciais:', viagemError);
      }

      // Sinaliza que estamos prontos para carregar conforme o perfil
      readyToLoad = true;
    } catch (e) {
      console.error('❌ Erro geral ao carregar dados:', e);
      console.error('Stack trace:', e.stack);
    }
  });

  // Reage quando o perfil do usuário estiver disponível para decidir a fonte de dados
  $: if (readyToLoad && !initialLoaded && $userProfile !== null) {
    (async () => {
      try {
        if (hasRole('jovem')($userProfile)) {
          await loadViagensCardsForJovem();
        } else {
          const userId = $userProfile?.id;
          const userLevel = $userProfile?.nivel;
          const scope = {
            estadoId: $userProfile?.estado_id || undefined,
            blocoId: $userProfile?.bloco_id || undefined,
            regiaoId: $userProfile?.regiao_id || undefined,
            igrejaId: $userProfile?.igreja_id || undefined
          };
          await loadViagensCards(1, pageSize, userId, userLevel, { sortBy, sortDir, estadoId: selectedEstado || undefined, edicaoId: selectedEdicao || undefined, condicao: selectedCondicao || undefined, scope });
        }
        initialLoaded = true;
        console.log('✅ Dados de viagem carregados com sucesso (perfil pronto)');
      } catch (err) {
        console.error('❌ Erro ao carregar dados de viagem (perfil pronto):', err);
      }
    })();
  }

  function handleUpload(event) {
    const { tipo, jovemId, edicaoId } = event.detail;
    console.log('🚀 Modal de upload aberto:', { tipo, jovemId, edicaoId, edicaoAtiva: edicaoAtiva?.id });
    uploadModal = {
      isOpen: true,
      tipo: tipo,
      jovemId,
      edicaoId: edicaoId || edicaoAtiva?.id,
      loading: false
    };
  }

  function handleUploadSubmit(event) {
    const { tipo, jovemId, edicaoId, file, dataPassagem } = event.detail;
    console.log('📤 Iniciando upload:', { tipo, jovemId, edicaoId, fileName: file?.name, dataPassagem });

    uploadModal.loading = true;

    // Executar upload baseado no tipo
    let uploadPromise;
    switch (tipo) {
      case 'pagamento':
        uploadPromise = uploadComprovantePagamento(jovemId, edicaoId, file);
        break;
      case 'ida':
        uploadPromise = uploadComprovanteIda(jovemId, edicaoId, dataPassagem, file);
        break;
      case 'volta':
        uploadPromise = uploadComprovanteVolta(jovemId, edicaoId, dataPassagem, file);
        break;
      default:
        console.error('Tipo de upload inválido:', tipo);
        uploadModal.loading = false;
        return;
    }

    uploadPromise
      .then(() => {
        uploadModal.isOpen = false;
        uploadModal.loading = false;
      })
      .catch((err) => {
        console.error('Erro no upload:', err);
        uploadModal.loading = false;
      });
  }

  function handleRemove(event) {
    const { tipo, jovemId, edicaoId } = event.detail;

    if (confirm(`Tem certeza que deseja remover o comprovante de ${tipo}?`)) {
      removeComprovante(jovemId, edicaoId, tipo)
        .catch((err) => {
          console.error('Erro ao remover comprovante:', err);
        });
    }
  }

  async function handleDelete(event) {
    const { jovemId, edicaoId } = event.detail;
    if (!jovemId) return;

    if (confirm('Tem certeza que deseja remover este card e todos os comprovantes?')) {
      try {
        await deleteViagemCard(jovemId, edicaoId);
      } catch (err) {
        console.error('Erro ao remover card/viagem:', err);
        alert('Falha ao remover card. Verifique suas permissões e tente novamente.');
      }
    }
  }

  function handleCloseModal() {
    uploadModal.isOpen = false;
    uploadModal.loading = false;
  }
  
  async function handleRefresh() {
    // Recarregar dados de viagem
    const userId = $userProfile?.id;
    const userLevel = $userProfile?.nivel;
    await applyControls($pagination.page);
  }

  async function applyControls(page = 1) {
    const userId = $userProfile?.id;
    const userLevel = $userProfile?.nivel;
    if (hasRole('jovem')($userProfile)) {
      await loadViagensCardsForJovem();
    } else {
      const scope = {
        estadoId: $userProfile?.estado_id || undefined,
        blocoId: $userProfile?.bloco_id || undefined,
        regiaoId: $userProfile?.regiao_id || undefined,
        igrejaId: $userProfile?.igreja_id || undefined
      };
      await loadViagensCards(page, Number(pageSize), userId, userLevel, { sortBy, sortDir, estadoId: selectedEstado || undefined, edicaoId: selectedEdicao || undefined, condicao: selectedCondicao || undefined, scope });
    }
  }
</script>

<svelte:head>
  <title>Status de Viagem</title>
</svelte:head>

<div class="p-3 sm:p-6 space-y-4 sm:space-y-6 overflow-x-hidden">
  <!-- Cabeçalho estilizado -->
  <div class="bg-gradient-to-r from-blue-600 via-purple-600 to-indigo-600 rounded-2xl p-6 sm:p-8 shadow-2xl border border-white/10 relative overflow-hidden">
    <!-- Elementos decorativos de fundo -->
    <div class="absolute top-0 right-0 w-32 h-32 bg-white/5 rounded-full -translate-y-16 translate-x-16"></div>
    <div class="absolute bottom-0 left-0 w-24 h-24 bg-white/5 rounded-full translate-y-12 -translate-x-12"></div>
    
    <!-- Conteúdo do cabeçalho -->
    <div class="relative z-10">
      <div class="flex items-center justify-center sm:justify-start space-x-4">
        <!-- Ícone de viagem -->
        <div class="w-12 h-12 sm:w-16 sm:h-16 bg-white/20 rounded-2xl flex items-center justify-center backdrop-blur-sm">
          <svg class="w-6 h-6 sm:w-8 sm:h-8 text-white" fill="none" viewBox="0 0 24 24" stroke="currentColor">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M17.657 16.657L13.414 20.9a1.998 1.998 0 01-2.827 0l-4.244-4.243a8 8 0 1111.314 0z" />
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 11a3 3 0 11-6 0 3 3 0 016 0z" />
          </svg>
        </div>
        
        <!-- Título e descrição -->
        <div class="text-center sm:text-left">
          <h1 class="text-2xl sm:text-4xl font-bold text-white mb-2">
            Status de Viagem
          </h1>
          <p class="text-blue-100 text-sm sm:text-base font-medium">
            Acompanhe o status dos comprovantes de viagem dos jovens
          </p>
        </div>
      </div>
      
      <!-- Linha 1: Filtros + Total de Jovens -->
      <div class="mt-6 grid grid-cols-1 sm:grid-cols-2 gap-4 items-stretch">
        <div class="bg-white/10 backdrop-blur-sm rounded-xl p-4 flex flex-col gap-2">
          <div class="grid grid-cols-2 gap-2">
            <select class="bg-white/80 rounded px-2 py-1 text-sm" bind:value={selectedEstado} on:change={() => applyControls(1)}>
              <option value="">Todos estados</option>
              {#each $estadosCache as st}
                <option value={st.id}>{st.sigla} - {st.nome}</option>
              {/each}
            </select>
            <select class="bg-white/80 rounded px-2 py-1 text-sm" bind:value={sortBy} on:change={() => applyControls(1)}>
              <option value="estado_id">Estado</option>
              <option value="nome_completo">Nome</option>
              <option value="data_cadastro">Data Cadastro</option>
            </select>
          </div>
          <div class="grid grid-cols-2 gap-2">
            <select class="bg-white/80 rounded px-2 py-1 text-sm" bind:value={selectedEdicao} on:change={() => applyControls(1)}>
              <option value="">Todas edições</option>
              {#each $edicoesCache as ed}
                <option value={ed.id}>Edição {ed.numero} {ed.ativa ? '(Ativa)' : ''}</option>
              {/each}
            </select>
            <select class="bg-white/80 rounded px-2 py-1 text-sm" bind:value={selectedCondicao} on:change={() => applyControls(1)}>
              <option value="">Todas condições</option>
              {#each $condicoesCache as c}
                <option value={c}>{c}</option>
              {/each}
            </select>
          </div>
          <div class="grid grid-cols-2 gap-2">
            <select class="bg-white/80 rounded px-2 py-1 text-sm" bind:value={sortDir} on:change={() => applyControls(1)}>
              <option value="asc">Asc</option>
              <option value="desc">Desc</option>
            </select>
            <select class="bg-white/80 rounded px-2 py-1 text-sm" bind:value={pageSize} on:change={() => applyControls(1)}>
              <option value={10}>10 por página</option>
              <option value={20}>20 por página</option>
              <option value={50}>50 por página</option>
            </select>
          </div>
        </div>
        <div class="bg-white/10 backdrop-blur-sm rounded-xl p-4 text-center">
          <div class="text-2xl sm:text-3xl font-bold text-white mb-1">
            {hasRole('jovem')($userProfile) ? $filteredViagens.length : ($pagination.total || $filteredViagens.length)}
          </div>
          <div class="text-blue-100 text-xs sm:text-sm">Jovens Cadastrados</div>
        </div>
      </div>

      <!-- Linha 2: Enviados + Taxa -->
      <div class="mt-4 grid grid-cols-1 sm:grid-cols-2 gap-4 items-stretch">
        <div class="bg-white/10 backdrop-blur-sm rounded-xl p-4 text-center">
          <div class="text-2xl sm:text-3xl font-bold text-white mb-1">
            {$filteredViagens.reduce((total, j) => {
              let count = 0;
              if (j.comprovante_pagamento) count++;
              if (j.comprovante_passagem_ida) count++;
              if (j.comprovante_passagem_volta) count++;
              return total + count;
            }, 0)}
          </div>
          <div class="text-blue-100 text-xs sm:text-sm">Comprovantes Enviados</div>
        </div>
        <div class="bg-white/10 backdrop-blur-sm rounded-xl p-4 text-center">
          <div class="text-2xl sm:text-3xl font-bold text-white mb-1">
            {Math.round(($filteredViagens.filter(j => j.comprovante_pagamento).length / Math.max($filteredViagens.length, 1)) * 100)}%
          </div>
          <div class="text-blue-100 text-xs sm:text-sm">Taxa de Conclusão</div>
        </div>
      </div>

      <!-- Linha 3: Paginação -->
      {#if !hasRole('jovem')($userProfile)}
        <div class="mt-4 bg-white/10 backdrop-blur-sm rounded-xl p-4 flex items-center justify-center">
          {#if $pagination.totalPages > 1}
            <div class="flex items-center gap-3">
              <button class="px-3 py-1 bg-white/10 text-white rounded disabled:opacity-50" on:click={() => applyControls(Math.max(1, $pagination.page - 1))} disabled={$pagination.page <= 1}>Anterior</button>
              <div class="text-white/90 text-sm">Página {$pagination.page} de {$pagination.totalPages}</div>
              <button class="px-3 py-1 bg-white/10 text-white rounded disabled:opacity-50" on:click={() => applyControls(Math.min($pagination.totalPages, $pagination.page + 1))} disabled={$pagination.page >= $pagination.totalPages}>Próxima</button>
            </div>
          {:else}
            <div class="text-white/70 text-sm">Página única</div>
          {/if}
        </div>
      {/if}
    </div>
  </div>

  {#if $loading}
    <div class="text-center py-12">
      <div class="inline-flex items-center space-x-2 text-gray-600">
        <svg class="animate-spin h-5 w-5" fill="none" viewBox="0 0 24 24">
          <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle>
          <path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
        </svg>
        <span>Carregando dados de viagem...</span>
      </div>
    </div>
  {:else if $error}
    <div class="text-center py-12">
      <div class="bg-red-50 border border-red-200 rounded-lg p-6 max-w-md mx-auto">
        <div class="flex items-center justify-center w-12 h-12 mx-auto mb-4 bg-red-100 rounded-full">
          <svg class="w-6 h-6 text-red-600" fill="none" viewBox="0 0 24 24" stroke="currentColor">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-2.5L13.732 4c-.77-.833-1.964-.833-2.732 0L3.732 16.5c-.77.833.192 2.5 1.732 2.5z" />
          </svg>
        </div>
        <h3 class="text-lg font-medium text-red-800 mb-2">Erro ao carregar</h3>
        <p class="text-red-600">{$error}</p>
      </div>
    </div>
  {:else if $filteredViagens.length === 0}
    <div class="text-center py-12">
      <div class="bg-gray-50 border border-gray-200 rounded-lg p-6 max-w-md mx-auto">
        <div class="flex items-center justify-center w-12 h-12 mx-auto mb-4 bg-gray-100 rounded-full">
          <svg class="w-6 h-6 text-gray-600" fill="none" viewBox="0 0 24 24" stroke="currentColor">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M17.657 16.657L13.414 20.9a1.998 1.998 0 01-2.827 0l-4.244-4.243a8 8 0 1111.314 0z" />
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 11a3 3 0 11-6 0 3 3 0 016 0z" />
          </svg>
        </div>
        <h3 class="text-lg font-medium text-gray-800 mb-2">Nenhum jovem encontrado</h3>
        <p class="text-gray-600">Não há jovens cadastrados para exibir o status de viagem.</p>
      </div>
    </div>
  {:else}
    <div class="grid grid-cols-1 gap-4 sm:gap-6 max-w-2xl mx-auto">
      {#each $filteredViagens as jovem}
        <ViagemCard 
          {jovem} 
          viagem={getViagemData(jovem)} 
          edicaoId={edicaoAtiva?.id || null}
          on:upload={handleUpload}
          on:remove={handleRemove}
          on:delete={handleDelete}
          on:refresh={handleRefresh}
        />
      {/each}
      <!-- Paginação -->
      {#if !hasRole('jovem')($userProfile) && $pagination.totalPages > 1}
        <div class="flex items-center justify-center gap-2 py-2">
          <button class="px-3 py-1 bg-white/10 text-white rounded disabled:opacity-50" on:click={() => applyControls(Math.max(1, $pagination.page - 1))} disabled={$pagination.page <= 1}>
            Anterior
          </button>
          <div class="text-white/90 text-sm">Página {$pagination.page} de {$pagination.totalPages}</div>
          <button class="px-3 py-1 bg-white/10 text-white rounded disabled:opacity-50" on:click={() => applyControls(Math.min($pagination.totalPages, $pagination.page + 1))} disabled={$pagination.page >= $pagination.totalPages}>
            Próxima
          </button>
        </div>
      {/if}
    </div>
  {/if}

  <!-- Modal de Upload -->
  <UploadComprovante
    bind:isOpen={uploadModal.isOpen}
    tipo={uploadModal.tipo}
    jovemId={uploadModal.jovemId}
    edicaoId={uploadModal.edicaoId}
    loading={uploadModal.loading}
    on:upload={handleUploadSubmit}
    on:close={handleCloseModal}
  />
</div>
