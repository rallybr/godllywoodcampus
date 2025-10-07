<script>
  import { onMount } from 'svelte';
  import { goto } from '$app/navigation';
  import { user, userProfile } from '$lib/stores/auth';
  import { canCadastrarJovem } from '$lib/stores/niveis-acesso';
  import { supabase } from '$lib/utils/supabase';
  import JovemCard from '$lib/components/jovens/JovemCard.svelte';
  import Button from '$lib/components/ui/Button.svelte';
  
  let jovens = [];
  let edicoes = [];
  let edicaoSelecionada = '';
  let loading = true;
  let error = null;
  
  onMount(async () => {
    if (!$user) {
      goto('/login');
    } else if ($userProfile?.nivel === 'jovem') {
      // Usuários jovens não podem acessar páginas de jovens
      goto('/');
    } else {
      await Promise.all([
        loadEdicoes(),
        loadTodosJovens()
      ]);
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

  async function loadTodosJovens() {
    loading = true;
    error = null;
    
    try {
      let query = supabase
        .from('jovens')
        .select(`
          *,
          estado:estados(nome, sigla),
          bloco:blocos(nome),
          regiao:regioes(nome),
          igreja:igrejas(nome),
          edicao_obj:edicoes(nome)
        `);
      
      // 🔧 APLICAR FILTROS BASEADOS NO NÍVEL DE ACESSO
      const userLevel = $userProfile?.nivel;
      const userId = $userProfile?.id;
      
      console.log('🔍 DEBUG - Carregando todos os jovens:', { userLevel, userId, estado_id: $userProfile?.estado_id });
      
      if (userLevel === 'colaborador' && userId) {
        // Colaborador: apenas jovens que ele cadastrou
        console.log('🔍 DEBUG - Filtrando por colaborador:', userId);
        query = query.eq('usuario_id', userId);
      } else if (userLevel === 'lider_estadual_iurd' || userLevel === 'lider_estadual_fju') {
        // Líder estadual: jovens do estado OU associados ao usuário
        if ($userProfile?.estado_id) {
          console.log('🔍 DEBUG - Filtrando por estado/associados:', $userProfile.estado_id);
          const { data: assoc } = await supabase
            .from('jovens_usuarios_associacoes')
            .select('jovem_id')
            .eq('usuario_id', userId);
          const ids = (assoc || []).map(a => a.jovem_id);
          query = ids.length > 0
            ? query.or(`estado_id.eq.${$userProfile.estado_id},id.in.(${ids.join(',')})`)
            : query.eq('estado_id', $userProfile.estado_id);
        }
      } else if (userLevel === 'lider_bloco_iurd' || userLevel === 'lider_bloco_fju') {
        // Líder de bloco: jovens do bloco OU associados
        if ($userProfile?.bloco_id) {
          console.log('🔍 DEBUG - Filtrando por bloco/associados:', $userProfile.bloco_id);
          const { data: assoc } = await supabase
            .from('jovens_usuarios_associacoes')
            .select('jovem_id')
            .eq('usuario_id', userId);
          const ids = (assoc || []).map(a => a.jovem_id);
          query = ids.length > 0
            ? query.or(`bloco_id.eq.${$userProfile.bloco_id},id.in.(${ids.join(',')})`)
            : query.eq('bloco_id', $userProfile.bloco_id);
        }
      } else if (userLevel === 'lider_regional_iurd') {
        // Líder regional: jovens da região OU associados
        if ($userProfile?.regiao_id) {
          console.log('🔍 DEBUG - Filtrando por região/associados:', $userProfile.regiao_id);
          const { data: assoc } = await supabase
            .from('jovens_usuarios_associacoes')
            .select('jovem_id')
            .eq('usuario_id', userId);
          const ids = (assoc || []).map(a => a.jovem_id);
          query = ids.length > 0
            ? query.or(`regiao_id.eq.${$userProfile.regiao_id},id.in.(${ids.join(',')})`)
            : query.eq('regiao_id', $userProfile.regiao_id);
        }
      } else if (userLevel === 'lider_igreja_iurd') {
        // Líder de igreja: jovens da igreja OU associados
        if ($userProfile?.igreja_id) {
          console.log('🔍 DEBUG - Filtrando por igreja/associados:', $userProfile.igreja_id);
          const { data: assoc } = await supabase
            .from('jovens_usuarios_associacoes')
            .select('jovem_id')
            .eq('usuario_id', userId);
          const ids = (assoc || []).map(a => a.jovem_id);
          query = ids.length > 0
            ? query.or(`igreja_id.eq.${$userProfile.igreja_id},id.in.(${ids.join(',')})`)
            : query.eq('igreja_id', $userProfile.igreja_id);
        }
      }
      // Administrador e líderes nacionais: sem filtros adicionais
      
      // Filtrar por edição se selecionada
      if (edicaoSelecionada) {
        query = query.eq('edicao_id', edicaoSelecionada);
      }
      
      const { data, error: fetchError } = await query.order('nome_completo', { ascending: true });
      
      if (fetchError) throw fetchError;
      
      // Processar dados para incluir informações adicionais
      jovens = data.map(jovem => ({
        ...jovem,
        edicao: jovem.edicao_obj?.nome || 'N/A',
        tem_avaliacoes: false // Será implementado depois se necessário
      }));
      
      console.log('🔍 DEBUG - Todos os jovens carregados:', jovens.length);
      
    } catch (err) {
      error = err.message;
      console.error('Erro ao carregar todos os jovens:', err);
    } finally {
      loading = false;
    }
  }
  
  function handleEdicaoChange(event) {
    edicaoSelecionada = event.target.value;
    loadTodosJovens();
  }
  
  function goBack() {
    goto('/');
  }
</script>

<svelte:head>
  <title>Todos os Jovens | IntelliMen Campus</title>
</svelte:head>

<div class="min-h-screen bg-gray-50">
  <!-- Header -->
  <div class="bg-white shadow-sm border-b border-gray-200">
    <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
      <div class="flex flex-col sm:flex-row sm:items-center sm:justify-between py-4 sm:py-0 sm:h-16 space-y-4 sm:space-y-0">
        <!-- Título e Navegação -->
        <div class="flex items-center space-x-3 sm:space-x-4">
          <button
            on:click={goBack}
            class="p-2 rounded-lg hover:bg-gray-100 transition-colors flex-shrink-0"
          >
            <svg class="w-5 h-5 sm:w-6 sm:h-6 text-gray-600" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 19l-7-7 7-7" />
            </svg>
          </button>
          <div class="min-w-0 flex-1">
            <h1 class="text-xl sm:text-2xl font-bold text-gray-900 truncate">Todos os Jovens</h1>
            <p class="text-xs sm:text-sm text-gray-500">{jovens.length} jovens encontrados</p>
          </div>
        </div>
        
        <!-- Filtros e Ações -->
        <div class="flex flex-col sm:flex-row items-stretch sm:items-center space-y-3 sm:space-y-0 sm:space-x-3">
          <!-- Filtro por Edição -->
          <div class="flex flex-col sm:flex-row sm:items-center space-y-1 sm:space-y-0 sm:space-x-2">
            <label for="edicao-filter" class="text-xs sm:text-sm font-medium text-gray-700 whitespace-nowrap">
              Edição:
            </label>
            <select
              id="edicao-filter"
              bind:value={edicaoSelecionada}
              on:change={handleEdicaoChange}
              class="px-3 py-2 border border-gray-300 rounded-lg text-sm focus:ring-2 focus:ring-blue-500 focus:border-blue-500 bg-white min-w-0"
            >
              {#each edicoes as edicao}
                <option value={edicao.id}>{edicao.nome}</option>
              {/each}
            </select>
          </div>
          
          <!-- Botão Cadastrar -->
          {#if canCadastrarJovem()}
          <Button href="/jovens/cadastrar" variant="primary" class="w-full sm:w-auto">
            <svg class="w-4 h-4 sm:w-5 sm:h-5 mr-2" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 6v6m0 0v6m0-6h6m-6 0H6" />
            </svg>
            <span class="text-sm sm:text-base">Cadastrar Jovem</span>
          </Button>
          {/if}
        </div>
      </div>
    </div>
  </div>
  
  <!-- Content -->
  <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-4 sm:py-6 lg:py-8">
    {#if loading}
      <div class="grid grid-cols-1 gap-4 sm:gap-6">
        {#each Array(3) as _}
          <div class="bg-white rounded-2xl shadow-lg overflow-hidden animate-pulse">
            <div class="bg-gradient-to-r from-blue-50 to-indigo-50 p-4 sm:p-6">
              <div class="flex items-start space-x-4 sm:space-x-6">
                <div class="w-16 h-16 sm:w-20 sm:h-20 bg-gray-200 rounded-2xl flex-shrink-0"></div>
                <div class="flex-1 min-w-0">
                  <div class="h-5 sm:h-6 bg-gray-200 rounded w-3/4 mb-2"></div>
                  <div class="h-3 sm:h-4 bg-gray-200 rounded w-1/2 mb-3 sm:mb-4"></div>
                  <div class="h-4 sm:h-6 bg-gray-200 rounded w-1/3"></div>
                </div>
              </div>
            </div>
            <div class="p-4 sm:p-6">
              <div class="grid grid-cols-3 gap-3 sm:gap-4">
                {#each Array(3) as _}
                  <div class="h-12 sm:h-16 bg-gray-200 rounded-xl"></div>
                {/each}
              </div>
            </div>
            <div class="px-4 sm:px-6 py-4 sm:py-5 bg-gray-100">
              <div class="flex flex-col sm:flex-row space-y-2 sm:space-y-0 sm:space-x-2">
                {#each Array(3) as _}
                  <div class="flex-1 h-10 sm:h-12 bg-gray-200 rounded-xl"></div>
                {/each}
              </div>
            </div>
          </div>
        {/each}
      </div>
    {:else if error}
      <div class="text-center py-8 sm:py-12 px-4">
        <div class="w-12 h-12 sm:w-16 sm:h-16 bg-red-100 rounded-full flex items-center justify-center mx-auto mb-4">
          <svg class="w-6 h-6 sm:w-8 sm:h-8 text-red-600" fill="none" viewBox="0 0 24 24" stroke="currentColor">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8v4m0 4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
          </svg>
        </div>
        <h3 class="text-base sm:text-lg font-semibold text-gray-900 mb-2">Erro ao carregar dados</h3>
        <p class="text-sm sm:text-base text-gray-500 mb-4 max-w-md mx-auto">{error}</p>
        <Button on:click={loadTodosJovens} variant="outline" class="w-full sm:w-auto">
          Tentar Novamente
        </Button>
      </div>
    {:else if jovens.length === 0}
      <div class="text-center py-8 sm:py-12 px-4">
        <div class="w-12 h-12 sm:w-16 sm:h-16 bg-gray-100 rounded-full flex items-center justify-center mx-auto mb-4">
          <svg class="w-6 h-6 sm:w-8 sm:h-8 text-gray-400" fill="none" viewBox="0 0 24 24" stroke="currentColor">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4.354a4 4 0 110 5.292M15 21H3v-1a6 6 0 0112 0v1zm0 0h6v-1a6 6 0 00-9-5.197m13.5-9a2.5 2.5 0 11-5 0 2.5 2.5 0 015 0z" />
          </svg>
        </div>
        <h3 class="text-base sm:text-lg font-semibold text-gray-900 mb-2">Nenhum jovem encontrado</h3>
        <p class="text-sm sm:text-base text-gray-500 mb-4 max-w-md mx-auto">Não há jovens cadastrados no sistema</p>
        <Button href="/jovens/cadastrar" variant="primary" class="w-full sm:w-auto">
          Cadastrar Primeiro Jovem
        </Button>
      </div>
    {:else}
      <div class="grid grid-cols-1 gap-4 sm:gap-6">
        {#each jovens as jovem (jovem.id)}
          <JovemCard {jovem} />
        {/each}
      </div>
    {/if}
  </div>
</div>
