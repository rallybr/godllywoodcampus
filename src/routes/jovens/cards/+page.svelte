<script>
  import { onMount } from 'svelte';
  import { goto } from '$app/navigation';
  import { supabase } from '$lib/utils/supabase';
  import JovemMiniCard from '$lib/components/jovens/JovemMiniCard.svelte';
  import Autocomplete from '$lib/components/ui/Autocomplete.svelte';
  import { userProfile } from '$lib/stores/auth';

  let jovens = [];
  let loading = true;
  let error = '';
  let searchTerm = '';
  let page = 1;
  let pageSize = 24;
  let total = 0;

  async function fetchJovens() {
    loading = true;
    error = '';
    try {
      console.log('🔍 DEBUG - Iniciando fetchJovens');
      console.log('🔍 DEBUG - userProfile:', $userProfile);
      console.log('🔍 DEBUG - userProfile.nivel:', $userProfile?.nivel);
      console.log('🔍 DEBUG - userProfile.id:', $userProfile?.id);
      
      const from = (page - 1) * pageSize;
      const to = from + pageSize - 1;

      let query = supabase
        .from('jovens')
        .select(`
          id,
          nome_completo,
          foto,
          usuario_id,
          idade,
          aprovado,
          estado:estados!estado_id (
            id,
            nome,
            sigla,
            bandeira
          ),
          bloco:blocos!bloco_id (
            id,
            nome
          ),
          regiao:regioes!regiao_id (
            id,
            nome
          ),
          igreja:igrejas!igreja_id (
            id,
            nome
          ),
          edicao:edicoes!edicao_id (
            id,
            nome,
            numero
          )
        `, { count: 'exact' })
        .order('nome_completo', { ascending: true });

      // Se nível for jovem ou colaborador, restringe ao próprio usuário
      if (($userProfile?.nivel === 'jovem' || $userProfile?.nivel === 'colaborador') && $userProfile?.id) {
        console.log('🔍 DEBUG - Filtrando para usuário:', { nivel: $userProfile.nivel, userId: $userProfile.id });
        query = query.eq('usuario_id', $userProfile.id);
      } else {
        console.log('🔍 DEBUG - Não filtrando:', { nivel: $userProfile?.nivel, userId: $userProfile?.id });
      }

      if (searchTerm && searchTerm.trim().length > 0) {
        query = query.ilike('nome_completo', `%${searchTerm.trim()}%`);
      }

      const { data, error: err, count } = await query.range(from, to);
      if (err) throw err;
      
      console.log('🔍 DEBUG - Dados retornados:', data);
      console.log('🔍 DEBUG - Total de registros:', count);
      console.log('🔍 DEBUG - Jovens encontrados:', data?.length);
      
      // Log detalhado de cada jovem
      if (data && data.length > 0) {
        data.forEach((jovem, index) => {
          console.log(`🔍 DEBUG - Jovem ${index + 1}:`, {
            id: jovem.id,
            nome: jovem.nome_completo,
            usuario_id: jovem.usuario_id,
            estado: jovem.estado
          });
        });
      }
      
      jovens = data || [];
      total = count || 0;
    } catch (e) {
      error = e.message || 'Erro ao carregar jovens';
    } finally {
      loading = false;
    }
  }

  onMount(async () => {
    fetchJovens();
  });

  function handleSearchSubmit(e) {
    e?.preventDefault?.();
    page = 1;
    fetchJovens();
  }

  function prevPage() {
    if (page > 1) {
      page -= 1;
      fetchJovens();
    }
  }

  function nextPage() {
    const totalPages = Math.max(1, Math.ceil(total / pageSize));
    if (page < totalPages) {
      page += 1;
      fetchJovens();
    }
  }
</script>

<svelte:head>
  <title>Jovens (Cards) - IntelliMen Campus</title>
</svelte:head>

<div class="px-4 sm:px-6 py-6 space-y-6">
  <div>
    <h1 class="text-2xl font-bold text-gray-900">Jovens</h1>
    <p class="text-gray-600">Lista em cartões compactos</p>
  </div>

  {#if $userProfile?.nivel !== 'jovem' && $userProfile?.nivel !== 'colaborador'}
    <!-- Busca com Autocomplete -->
    <div class="bg-white rounded-lg shadow p-4">
      <Autocomplete
        placeholder="Pesquisar por nome..."
        bind:value={searchTerm}
        on:input={(e) => { searchTerm = e.detail.value; if ((searchTerm || '').trim().length >= 2) { page = 1; fetchJovens(); } }}
        on:select={(e) => { searchTerm = e.detail.suggestion.nome_completo; page = 1; fetchJovens(); }}
        on:search={() => handleSearchSubmit()}
      />
    </div>
  {/if}

  {#if loading}
    <div class="flex items-center justify-center py-12">
      <div class="animate-spin rounded-full h-12 w-12 border-b-2 border-blue-600"></div>
    </div>
  {:else if error}
    <div class="bg-red-50 border border-red-200 rounded-md p-4">
      <p class="text-sm text-red-600">{error}</p>
    </div>
  {:else if !jovens || jovens.length === 0}
    <div class="bg-white rounded-lg shadow p-8 text-center text-gray-600">Nenhum jovem encontrado</div>
  {:else}
    <div class="grid grid-cols-1 sm:grid-cols-2 md:grid-cols-3 gap-4">
      {#each jovens as jovem (jovem.id)}
        <JovemMiniCard {jovem} on:deleted={() => fetchJovens()} />
      {/each}
    </div>

    {#if $userProfile?.nivel !== 'jovem' && $userProfile?.nivel !== 'colaborador'}
      <!-- Paginação -->
      <div class="flex items-center justify-center gap-3 mt-6">
        <button on:click={prevPage} disabled={page <= 1} class="px-3 py-2 border rounded disabled:opacity-50">Anterior</button>
        <span class="text-sm text-gray-600">Página {page} de {Math.max(1, Math.ceil(total / pageSize))}</span>
        <button on:click={nextPage} disabled={page >= Math.max(1, Math.ceil(total / pageSize))} class="px-3 py-2 border rounded disabled:opacity-50">Próxima</button>
      </div>
    {/if}
  {/if}
</div>



