<script>
  import { onMount } from 'svelte';
  import { page } from '$app/stores';
  import { user, userProfile } from '$lib/stores/auth';
  import { supabase } from '$lib/utils/supabase';
  import JovemCard from '$lib/components/jovens/JovemCard.svelte';
  import Button from '$lib/components/ui/Button.svelte';
  import { getUserLevelName } from '$lib/stores/niveis-acesso';
  
  let jovens = [];
  let loading = true;
  let error = null;
  let total = 0;
  let pageSize = 20;
  let currentPage = 1;
  let status = '';
  
  // Obter status da URL
  $: status = $page.url.searchParams.get('status') || '';
  
  onMount(async () => {
    if (!$user) {
      window.location.href = '/login';
    } else if ($userProfile?.nivel === 'jovem') {
      window.location.href = '/';
    } else {
      await loadJovensAssociados();
    }
  });
  
  async function loadJovensAssociados() {
    loading = true;
    error = null;
    
    try {
      console.log('🔍 DEBUG - Carregando jovens associados para usuário:', $userProfile?.id);
      console.log('🔍 DEBUG - Status filtro:', status);
      
      // Buscar jovens associados ao usuário
      let query = supabase
        .from('jovens')
        .select(`
          *,
          estado:estados(id, nome, sigla),
          bloco:blocos(id, nome),
          regiao:regioes(id, nome),
          igreja:igrejas(id, nome),
          edicao:edicoes(id, nome, numero),
          avaliacoes(
            id,
            jovem_id,
            espirito,
            caractere,
            disposicao,
            criado_em
          )
        `, { count: 'exact' })
        .eq('usuario_id', $userProfile.id)
        .order('data_cadastro', { ascending: false });
      
      // Aplicar filtro por status se especificado
      if (status === 'aprovado') {
        // Jovens aprovados
        query = query.eq('aprovado', 'aprovado');
      }
      // Para 'pendente' e 'avaliado', vamos filtrar depois da consulta
      
      const { data, error: fetchError, count } = await query
        .range((currentPage - 1) * pageSize, currentPage * pageSize - 1);
      
      if (fetchError) {
        console.error('Erro ao buscar jovens associados:', fetchError);
        throw fetchError;
      }
      
      console.log('🔍 DEBUG - Jovens associados encontrados:', data?.length || 0);
      console.log('🔍 DEBUG - Total:', count);
      
      // Filtrar por status se necessário
      let jovensFiltrados = data || [];
      
      if (status === 'pendente') {
        // Jovens sem avaliações
        jovensFiltrados = jovensFiltrados.filter(jovem => 
          !jovem.avaliacoes || jovem.avaliacoes.length === 0
        );
      } else if (status === 'avaliado') {
        // Jovens com avaliações
        jovensFiltrados = jovensFiltrados.filter(jovem => 
          jovem.avaliacoes && jovem.avaliacoes.length > 0
        );
      }
      
      jovens = jovensFiltrados;
      total = jovensFiltrados.length;
      
    } catch (err) {
      console.error('Erro ao carregar jovens associados:', err);
      error = err.message || 'Erro ao carregar jovens associados';
    } finally {
      loading = false;
    }
  }
  
  function getStatusTitle() {
    switch (status) {
      case 'pendente':
        return 'Jovens Associados - Pendentes de Avaliação';
      case 'avaliado':
        return 'Jovens Associados - Avaliados';
      case 'aprovado':
        return 'Jovens Associados - Aprovados';
      default:
        return 'Jovens Associados';
    }
  }
  
  function getStatusDescription() {
    switch (status) {
      case 'pendente':
        return 'Jovens associados a você que ainda não foram avaliados';
      case 'avaliado':
        return 'Jovens associados a você que já foram avaliados';
      case 'aprovado':
        return 'Jovens associados a você que foram aprovados';
      default:
        return 'Todos os jovens associados a você';
    }
  }
</script>

<svelte:head>
  <title>{getStatusTitle()} - IntelliMen Campus</title>
</svelte:head>

<div class="px-4 sm:px-6 py-6 space-y-6">
  <!-- Header -->
  <div class="flex flex-col sm:flex-row sm:items-center justify-between">
    <div>
      <h1 class="text-2xl font-bold text-gray-900">{getStatusTitle()}</h1>
      <p class="text-gray-600 mt-1">{getStatusDescription()}</p>
    </div>
    
    <!-- Filtros -->
    <div class="mt-4 sm:mt-0 flex space-x-2">
      <Button 
        href="/jovens/associados" 
        variant={status === '' ? 'primary' : 'outline'}
        size="sm"
      >
        Todos ({total})
      </Button>
      <Button 
        href="/jovens/associados?status=pendente" 
        variant={status === 'pendente' ? 'primary' : 'outline'}
        size="sm"
      >
        Pendentes
      </Button>
      <Button 
        href="/jovens/associados?status=avaliado" 
        variant={status === 'avaliado' ? 'primary' : 'outline'}
        size="sm"
      >
        Avaliados
      </Button>
      <Button 
        href="/jovens/associados?status=aprovado" 
        variant={status === 'aprovado' ? 'primary' : 'outline'}
        size="sm"
      >
        Aprovados
      </Button>
    </div>
  </div>

  <!-- Loading -->
  {#if loading}
    <div class="grid grid-cols-1 gap-4 sm:gap-6">
      {#each Array(3) as _}
        <div class="fb-card p-6 animate-pulse">
          <div class="flex items-center space-x-4">
            <div class="w-12 h-12 bg-gray-200 rounded-full"></div>
            <div class="flex-1">
              <div class="h-4 bg-gray-200 rounded w-1/3 mb-2"></div>
              <div class="h-3 bg-gray-200 rounded w-1/2"></div>
            </div>
          </div>
        </div>
      {/each}
    </div>
  {:else if error}
    <!-- Error -->
    <div class="text-center py-8 sm:py-12 px-4">
      <div class="w-12 h-12 sm:w-16 sm:h-16 bg-red-100 rounded-full flex items-center justify-center mx-auto mb-4">
        <svg class="w-6 h-6 sm:w-8 sm:h-8 text-red-600" fill="none" viewBox="0 0 24 24" stroke="currentColor">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8v4m0 4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
        </svg>
      </div>
      <h3 class="text-base sm:text-lg font-semibold text-gray-900 mb-2">Erro ao carregar dados</h3>
      <p class="text-sm sm:text-base text-gray-500 mb-4 max-w-md mx-auto">{error}</p>
      <Button on:click={loadJovensAssociados} variant="outline" class="w-full sm:w-auto">
        Tentar Novamente
      </Button>
    </div>
  {:else if jovens.length === 0}
    <!-- Empty State -->
    <div class="text-center py-8 sm:py-12 px-4">
      <div class="w-12 h-12 sm:w-16 sm:h-16 bg-gray-100 rounded-full flex items-center justify-center mx-auto mb-4">
        <svg class="w-6 h-6 sm:w-8 sm:h-8 text-gray-400" fill="none" viewBox="0 0 24 24" stroke="currentColor">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M17 20h5v-2a3 3 0 00-5.356-1.857M17 20H7m10 0v-2c0-.656-.126-1.283-.356-1.857M7 20H2v-2a3 3 0 015.356-1.857M7 20v-2c0-.656.126-1.283.356-1.857m0 0a5.002 5.002 0 019.288 0M15 7a3 3 0 11-6 0 3 3 0 016 0zm6 3a2 2 0 11-4 0 2 2 0 014 0zM7 10a2 2 0 11-4 0 2 2 0 014 0z" />
        </svg>
      </div>
      <h3 class="text-base sm:text-lg font-semibold text-gray-900 mb-2">Nenhum jovem associado</h3>
      <p class="text-sm sm:text-base text-gray-500 mb-4 max-w-md mx-auto">
        {status === 'pendente' ? 'Não há jovens pendentes de avaliação associados a você.' :
         status === 'avaliado' ? 'Não há jovens avaliados associados a você.' :
         status === 'aprovado' ? 'Não há jovens aprovados associados a você.' :
         'Você ainda não tem jovens associados.'}
      </p>
      <Button href="/jovens/cadastrar" variant="primary" class="w-full sm:w-auto">
        Cadastrar Primeiro Jovem
      </Button>
    </div>
  {:else}
    <!-- Jovens List -->
    <div class="grid grid-cols-1 gap-4 sm:gap-6">
      {#each jovens as jovem (jovem.id)}
        <JovemCard {jovem} />
      {/each}
    </div>
    
    <!-- Pagination -->
    {#if total > pageSize}
      <div class="flex items-center justify-between mt-6">
        <div class="text-sm text-gray-500">
          Mostrando {((currentPage - 1) * pageSize) + 1} a {Math.min(currentPage * pageSize, total)} de {total} jovens
        </div>
        <div class="flex space-x-2">
          <Button 
            on:click={() => { currentPage = Math.max(1, currentPage - 1); loadJovensAssociados(); }}
            variant="outline"
            size="sm"
            disabled={currentPage <= 1}
          >
            Anterior
          </Button>
          <Button 
            on:click={() => { currentPage = Math.min(Math.ceil(total / pageSize), currentPage + 1); loadJovensAssociados(); }}
            variant="outline"
            size="sm"
            disabled={currentPage >= Math.ceil(total / pageSize)}
          >
            Próximo
          </Button>
        </div>
      </div>
    {/if}
  {/if}
</div>
