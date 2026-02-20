<script>
  import { onMount } from 'svelte';
  import { goto } from '$app/navigation';
  import { user, userProfile } from '$lib/stores/auth';
  import { supabase } from '$lib/utils/supabase';
  import JovemCard from '$lib/components/jovens/JovemCard.svelte';
  import Button from '$lib/components/ui/Button.svelte';
  
  let jovens = [];
  let edicoes = [];
  let edicaoSelecionada = '';
  let loading = true;
  let error = null;
  let siglaEstado = '';
  let nomeEstado = '';
  let estadoId = null;
  
  // Filtros em cascata
  let blocos = [];
  let regioes = [];
  let igrejas = [];
  let blocoSelecionado = '';
  let regiaoSelecionada = '';
  let igrejaSelecionada = '';
  
  onMount(async () => {
    if (!$user) {
      goto('/login');
    } else if ($userProfile?.nivel === 'jovem') {
      // Usuários jovens não podem acessar páginas de jovens
      goto('/');
    } else {
      // Obter sigla do estado da URL
      const urlParams = new URLSearchParams(window.location.search);
      const pathParts = window.location.pathname.split('/');
      siglaEstado = pathParts[pathParts.length - 1]; // Último segmento da URL
      
      if (siglaEstado) {
        await loadEdicoes();
        await loadEstadoInfo();
        // Só carregar jovens se o estado foi encontrado
        if (estadoId) {
          await loadJovensPorEstado();
        }
      }
    }
  });
  
  async function loadEdicoes() {
    try {
      const { data, error: fetchError } = await supabase
        .from('edicoes')
        .select('id, numero, nome, ativa')
        .order('numero', { ascending: true });

      if (fetchError) throw fetchError;
      
      edicoes = [
        { id: '', numero: '', nome: 'Todas as Edições', ativa: false },
        ...data
      ];
    } catch (err) {
      console.error('Erro ao carregar edições:', err);
    }
  }

  async function loadEstadoInfo() {
    try {
      const { data, error } = await supabase
        .from('estados')
        .select('id, nome, sigla')
        .eq('sigla', siglaEstado.toUpperCase())
        .single();
      
      if (error) throw error;
      nomeEstado = data.nome;
      estadoId = data.id;
      
      // Carregar blocos do estado
      await loadBlocos();
    } catch (err) {
      console.error('Erro ao carregar informações do estado:', err);
      error = 'Estado não encontrado';
    }
  }

  async function loadBlocos() {
    if (!estadoId) return;
    
    try {
      const { data, error } = await supabase
        .from('blocos')
        .select('id, nome')
        .eq('estado_id', estadoId)
        .order('nome', { ascending: true });
      
      if (error) throw error;
      
      blocos = [
        { id: '', nome: 'Todos os Blocos' },
        ...data
      ];
    } catch (err) {
      console.error('Erro ao carregar blocos:', err);
    }
  }
  
  async function loadRegioes() {
    if (!blocoSelecionado) {
      regioes = [];
      return;
    }
    
    try {
      const { data, error } = await supabase
        .from('regioes')
        .select('id, nome')
        .eq('bloco_id', blocoSelecionado)
        .order('nome', { ascending: true });
      
      if (error) throw error;
      
      regioes = [
        { id: '', nome: 'Todas as Regiões' },
        ...data
      ];
    } catch (err) {
      console.error('Erro ao carregar regiões:', err);
    }
  }
  
  async function loadIgrejas() {
    if (!regiaoSelecionada) {
      igrejas = [];
      return;
    }
    
    try {
      const { data, error } = await supabase
        .from('igrejas')
        .select('id, nome')
        .eq('regiao_id', regiaoSelecionada)
        .order('nome', { ascending: true });
      
      if (error) throw error;
      
      igrejas = [
        { id: '', nome: 'Todas as Igrejas' },
        ...data
      ];
    } catch (err) {
      console.error('Erro ao carregar igrejas:', err);
    }
  }

  async function loadJovensPorEstado() {
    loading = true;
    error = null;
    
    try {
      if (!estadoId) {
        error = 'Estado não encontrado';
        return;
      }
      
      // Buscar jovens com filtros aplicados
      let query = supabase
        .from('jovens')
        .select(`
          *,
          estado:estados(nome, sigla),
          bloco:blocos(nome),
          regiao:regioes(nome),
          igreja:igrejas(nome),
          edicao_obj:edicoes(nome)
        `)
        .eq('estado_id', estadoId);
      
      // 🔧 APLICAR FILTROS BASEADOS NO NÍVEL DE ACESSO
      const userLevel = $userProfile?.nivel;
      const userId = $userProfile?.id;
      
      console.log('🔍 DEBUG - Carregando jovens por estado:', { userLevel, userId, estadoId, siglaEstado });
      
      if (userLevel === 'colaborador' && userId) {
        console.log('🔍 DEBUG - Filtrando por colaborador:', userId);
        query = query.eq('usuario_id', userId);
      } else if (userLevel === 'lider_estadual_iurd' || userLevel === 'lider_estadual_fju') {
        // Líder estadual: apenas jovens do seu estado (já filtrado por estado_id)
        console.log('🔍 DEBUG - Líder estadual: mostrando jovens do estado:', estadoId);
        // Não precisa de filtro adicional, já está filtrado por estado_id
      } else if (userLevel === 'lider_bloco_iurd' || userLevel === 'lider_bloco_fju') {
        // Líder de bloco: apenas jovens do seu bloco
        if ($userProfile?.bloco_id) {
          console.log('🔍 DEBUG - Filtrando por bloco:', $userProfile.bloco_id);
          query = query.eq('bloco_id', $userProfile.bloco_id);
        }
      } else if (userLevel === 'lider_regional_iurd') {
        // Líder regional: apenas jovens da sua região
        if ($userProfile?.regiao_id) {
          console.log('🔍 DEBUG - Filtrando por região:', $userProfile.regiao_id);
          query = query.eq('regiao_id', $userProfile.regiao_id);
        }
      } else if (userLevel === 'lider_igreja_iurd') {
        // Líder de igreja: apenas jovens da sua igreja
        if ($userProfile?.igreja_id) {
          console.log('🔍 DEBUG - Filtrando por igreja:', $userProfile.igreja_id);
          query = query.eq('igreja_id', $userProfile.igreja_id);
        }
      }
      // Administrador e líderes nacionais: sem filtros adicionais (podem ver todos os jovens do estado)
      
      // Aplicar filtros em cascata (se o usuário tiver permissão para usar)
      if (blocoSelecionado) {
        query = query.eq('bloco_id', blocoSelecionado);
      }
      
      if (regiaoSelecionada) {
        query = query.eq('regiao_id', regiaoSelecionada);
      }
      
      if (igrejaSelecionada) {
        query = query.eq('igreja_id', igrejaSelecionada);
      }
      
      // Filtrar por edição se selecionada
      if (edicaoSelecionada) {
        query = query.eq('edicao_id', edicaoSelecionada);
      }
      
      const { data, error: fetchError } = await query.order('nome_completo', { ascending: true });
      
      if (fetchError) throw fetchError;
      
      console.log('🔍 DEBUG - Jovens carregados:', data?.length);
      
      // Processar dados para incluir informações adicionais
      jovens = data.map(jovem => ({
        ...jovem,
        edicao: jovem.edicao_obj?.nome || 'N/A',
        tem_avaliacoes: false // Será implementado depois se necessário
      }));
      
    } catch (err) {
      error = err.message;
      console.error('Erro ao carregar jovens por estado:', err);
    } finally {
      loading = false;
    }
  }

  function handleEdicaoChange(event) {
    edicaoSelecionada = event.target.value;
    loadJovensPorEstado();
  }
  
  async function handleBlocoChange(event) {
    blocoSelecionado = event.target.value;
    regiaoSelecionada = '';
    igrejaSelecionada = '';
    
    await loadRegioes();
    await loadJovensPorEstado();
  }
  
  async function handleRegiaoChange(event) {
    regiaoSelecionada = event.target.value;
    igrejaSelecionada = '';
    
    await loadIgrejas();
    await loadJovensPorEstado();
  }
  
  async function handleIgrejaChange(event) {
    igrejaSelecionada = event.target.value;
    await loadJovensPorEstado();
  }
  
  function goBack() {
    goto('/');
  }
</script>

<svelte:head>
  <title>Jovens - {nomeEstado} | Godllywood Campus</title>
</svelte:head>

<div class="min-h-screen bg-gray-50">
  <!-- Header -->
  <div class="bg-white shadow-sm border-b border-gray-200">
    <div class="max-w-7xl mx-auto px-3 sm:px-4 lg:px-8">
      <!-- Linha Principal: Título, Contagem e Filtro de Edição -->
      <div class="flex flex-col space-y-3 py-3 sm:py-4 lg:py-0 lg:h-16 lg:flex-row lg:items-center lg:justify-between lg:space-y-0">
        <!-- Título e Navegação -->
        <div class="flex items-center space-x-2 sm:space-x-3 lg:space-x-4">
          <button
            on:click={goBack}
            class="p-1.5 sm:p-2 rounded-lg hover:bg-gray-100 transition-colors flex-shrink-0"
          >
            <svg class="w-4 h-4 sm:w-5 sm:h-5 lg:w-6 lg:h-6 text-gray-600" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 19l-7-7 7-7" />
            </svg>
          </button>
          <div class="min-w-0 flex-1">
            <h1 class="text-lg sm:text-xl lg:text-2xl font-bold text-gray-900 truncate">{nomeEstado}</h1>
            <p class="text-xs sm:text-sm text-gray-500">{jovens.length} jovens encontrados</p>
          </div>
        </div>
        
        <!-- Filtro por Edição -->
        <div class="w-full sm:w-auto">
          <div class="flex flex-col space-y-1 sm:flex-row sm:items-center sm:space-y-0 sm:space-x-2">
            <label for="edicao-filter" class="text-xs sm:text-sm font-medium text-gray-700 whitespace-nowrap">
              Edição:
            </label>
            <select
              id="edicao-filter"
              bind:value={edicaoSelecionada}
              on:change={handleEdicaoChange}
              class="w-full sm:w-auto px-3 py-2 border border-gray-300 rounded-lg text-sm focus:ring-2 focus:ring-blue-500 focus:border-blue-500 bg-white"
            >
              {#each edicoes as edicao}
                <option value={edicao.id}>{edicao.nome}</option>
              {/each}
            </select>
          </div>
        </div>
      </div>
      
      <!-- Linha Separada: Filtros em Cascata -->
      <div class="border-t border-gray-200 py-3">
        <div class="grid grid-cols-1 gap-3 sm:grid-cols-2 lg:grid-cols-3 xl:flex xl:flex-row xl:items-center xl:space-x-3 xl:space-y-0 xl:gap-0">
          <!-- Filtro por Bloco -->
          <div class="flex flex-col space-y-1 sm:flex-row sm:items-center sm:space-y-0 sm:space-x-2">
            <label for="bloco-filter" class="text-xs sm:text-sm font-medium text-gray-700 whitespace-nowrap">
              Bloco:
            </label>
            <select
              id="bloco-filter"
              bind:value={blocoSelecionado}
              on:change={handleBlocoChange}
              class="w-full sm:w-auto px-3 py-2 border border-gray-300 rounded-lg text-sm focus:ring-2 focus:ring-blue-500 focus:border-blue-500 bg-white"
            >
              {#each blocos as bloco}
                <option value={bloco.id}>{bloco.nome}</option>
              {/each}
            </select>
          </div>
          
          <!-- Filtro por Região -->
          <div class="flex flex-col space-y-1 sm:flex-row sm:items-center sm:space-y-0 sm:space-x-2">
            <label for="regiao-filter" class="text-xs sm:text-sm font-medium text-gray-700 whitespace-nowrap">
              Região:
            </label>
            <select
              id="regiao-filter"
              bind:value={regiaoSelecionada}
              on:change={handleRegiaoChange}
              disabled={!blocoSelecionado}
              class="w-full sm:w-auto px-3 py-2 border border-gray-300 rounded-lg text-sm focus:ring-2 focus:ring-blue-500 focus:border-blue-500 bg-white disabled:bg-gray-100 disabled:text-gray-500"
            >
              {#each regioes as regiao}
                <option value={regiao.id}>{regiao.nome}</option>
              {/each}
            </select>
          </div>
          
          <!-- Filtro por Igreja -->
          <div class="flex flex-col space-y-1 sm:flex-row sm:items-center sm:space-y-0 sm:space-x-2">
            <label for="igreja-filter" class="text-xs sm:text-sm font-medium text-gray-700 whitespace-nowrap">
              Igreja:
            </label>
            <select
              id="igreja-filter"
              bind:value={igrejaSelecionada}
              on:change={handleIgrejaChange}
              disabled={!regiaoSelecionada}
              class="w-full sm:w-auto px-3 py-2 border border-gray-300 rounded-lg text-sm focus:ring-2 focus:ring-blue-500 focus:border-blue-500 bg-white disabled:bg-gray-100 disabled:text-gray-500"
            >
              {#each igrejas as igreja}
                <option value={igreja.id}>{igreja.nome}</option>
              {/each}
            </select>
          </div>
        </div>
      </div>
    </div>
  </div>
  
  <!-- Content -->
  <div class="max-w-7xl mx-auto px-3 sm:px-4 lg:px-8 py-3 sm:py-4 lg:py-8">
    {#if loading}
      <div class="grid grid-cols-1 gap-3 sm:gap-4 lg:gap-6">
        {#each Array(3) as _}
          <div class="bg-white rounded-xl sm:rounded-2xl shadow-lg overflow-hidden animate-pulse">
            <div class="bg-gradient-to-r from-blue-50 to-indigo-50 p-3 sm:p-4 lg:p-6">
              <div class="flex items-start space-x-3 sm:space-x-4 lg:space-x-6">
                <div class="w-12 h-12 sm:w-16 sm:h-16 lg:w-20 lg:h-20 bg-gray-200 rounded-xl sm:rounded-2xl flex-shrink-0"></div>
                <div class="flex-1 min-w-0">
                  <div class="h-4 sm:h-5 lg:h-6 bg-gray-200 rounded w-3/4 mb-2"></div>
                  <div class="h-3 sm:h-4 bg-gray-200 rounded w-1/2 mb-2 sm:mb-3 lg:mb-4"></div>
                  <div class="h-3 sm:h-4 lg:h-6 bg-gray-200 rounded w-1/3"></div>
                </div>
              </div>
            </div>
            <div class="p-3 sm:p-4 lg:p-6">
              <div class="grid grid-cols-3 gap-2 sm:gap-3 lg:gap-4">
                {#each Array(3) as _}
                  <div class="h-10 sm:h-12 lg:h-16 bg-gray-200 rounded-lg sm:rounded-xl"></div>
                {/each}
              </div>
            </div>
            <div class="px-3 sm:px-4 lg:px-6 py-3 sm:py-4 lg:py-5 bg-gray-100">
              <div class="flex flex-col sm:flex-row space-y-2 sm:space-y-0 sm:space-x-2">
                {#each Array(3) as _}
                  <div class="flex-1 h-8 sm:h-10 lg:h-12 bg-gray-200 rounded-lg sm:rounded-xl"></div>
                {/each}
              </div>
            </div>
          </div>
        {/each}
      </div>
    {:else if error}
      <div class="text-center py-6 sm:py-8 lg:py-12 px-3 sm:px-4">
        <div class="w-10 h-10 sm:w-12 sm:h-12 lg:w-16 lg:h-16 bg-red-100 rounded-full flex items-center justify-center mx-auto mb-3 sm:mb-4">
          <svg class="w-5 h-5 sm:w-6 sm:h-6 lg:w-8 lg:h-8 text-red-600" fill="none" viewBox="0 0 24 24" stroke="currentColor">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8v4m0 4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
          </svg>
        </div>
        <h3 class="text-sm sm:text-base lg:text-lg font-semibold text-gray-900 mb-2">Erro ao carregar dados</h3>
        <p class="text-xs sm:text-sm lg:text-base text-gray-500 mb-3 sm:mb-4 max-w-md mx-auto">{error}</p>
        <Button on:click={loadJovensPorEstado} variant="outline" class="w-full sm:w-auto text-sm sm:text-base">
          Tentar Novamente
        </Button>
      </div>
    {:else if jovens.length === 0}
      <div class="text-center py-6 sm:py-8 lg:py-12 px-3 sm:px-4">
        <div class="w-10 h-10 sm:w-12 sm:h-12 lg:w-16 lg:h-16 bg-gray-100 rounded-full flex items-center justify-center mx-auto mb-3 sm:mb-4">
          <svg class="w-5 h-5 sm:w-6 sm:h-6 lg:w-8 lg:h-8 text-gray-400" fill="none" viewBox="0 0 24 24" stroke="currentColor">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4.354a4 4 0 110 5.292M15 21H3v-1a6 6 0 0112 0v1zm0 0h6v-1a6 6 0 00-9-5.197m13.5-9a2.5 2.5 0 11-5 0 2.5 2.5 0 015 0z" />
          </svg>
        </div>
        <h3 class="text-sm sm:text-base lg:text-lg font-semibold text-gray-900 mb-2">Nenhum jovem encontrado</h3>
        <p class="text-xs sm:text-sm lg:text-base text-gray-500 mb-3 sm:mb-4 max-w-md mx-auto">Não há jovens cadastrados no estado "{nomeEstado}"</p>
        <Button href="/jovens/cadastrar" variant="primary" class="w-full sm:w-auto text-sm sm:text-base">
          Cadastrar Primeiro Jovem
        </Button>
      </div>
    {:else}
      <div class="grid grid-cols-1 gap-3 sm:gap-4 lg:gap-6">
        {#each jovens as jovem (jovem.id)}
          <JovemCard {jovem} />
        {/each}
      </div>
    {/if}
  </div>
</div>
