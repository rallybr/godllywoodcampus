<script>
  import { onMount } from 'svelte';
  import { goto } from '$app/navigation';
  import { user } from '$lib/stores/auth';
  import { loadJovens, filteredJovens, filters, loading, error, pagination } from '$lib/stores/jovens-simple';
  import JovemCard from '$lib/components/jovens/JovemCard.svelte';
  
  let searchTerm = '';
  let currentPage = 1;
  let viewMode = 'grid';
  
  onMount(() => {
    if (!$user) {
      goto('/login');
    } else {
      loadJovens();
    }
  });
  
  function handleSearch() {
    filters.update(f => ({ ...f, nome_like: searchTerm || '' }));
  }
  
  function handleClearFilters() {
    searchTerm = '';
    filters.set({
      edicao: '',
      sexo: '',
      condicao: '',
      idade_min: '',
      idade_max: '',
      estado_id: '',
      bloco_id: '',
      regiao_id: '',
      igreja_id: '',
      aprovado: '',
      nome_like: ''
    });
  }
  
  function handlePageChange(page) {
    currentPage = page;
    loadJovens(page);
  }
</script>

<svelte:head>
  <title>Jovens - IntelliMen Campus</title>
</svelte:head>

<div class="space-y-6">
  <!-- Header -->
  <div class="flex flex-col sm:flex-row sm:items-center sm:justify-between">
    <div>
      <h1 class="text-2xl font-bold text-gray-900">Jovens</h1>
      <p class="text-gray-600">Gerencie os jovens cadastrados no acampamento</p>
    </div>
    <div class="mt-4 sm:mt-0 flex items-center space-x-3">
      <!-- View mode toggle -->
      <div class="flex items-center bg-gray-100 rounded-lg p-1">
        <button
          class="p-2 rounded-md {viewMode === 'grid' ? 'bg-white shadow-sm' : 'text-gray-500'}"
          on:click={() => viewMode = 'grid'}
        >
          <svg class="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 6a2 2 0 012-2h2a2 2 0 012 2v2a2 2 0 01-2 2H6a2 2 0 01-2-2V6zM14 6a2 2 0 012-2h2a2 2 0 012 2v2a2 2 0 01-2 2h-2a2 2 0 01-2-2V6zM4 16a2 2 0 012-2h2a2 2 0 012 2v2a2 2 0 01-2 2H6a2 2 0 01-2-2v-2zM14 16a2 2 0 012-2h2a2 2 0 012 2v2a2 2 0 01-2 2h-2a2 2 0 01-2-2v-2z" />
          </svg>
        </button>
        <button
          class="p-2 rounded-md {viewMode === 'list' ? 'bg-white shadow-sm' : 'text-gray-500'}"
          on:click={() => viewMode = 'list'}
        >
          <svg class="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 6h16M4 10h16M4 14h16M4 18h16" />
          </svg>
        </button>
      </div>
      
      <a href="/jovens/cadastrar" class="inline-flex items-center px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition-colors">
        <svg class="w-5 h-5 mr-2" fill="none" viewBox="0 0 24 24" stroke="currentColor">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 6v6m0 0v6m0-6h6m-6 0H6" />
        </svg>
        Cadastrar Jovem
      </a>
    </div>
  </div>
  
  <!-- Search -->
  <div class="bg-white rounded-lg shadow p-6">
    <div class="flex flex-col sm:flex-row gap-3 sm:gap-4 items-stretch sm:items-end">
      <div class="flex-1 min-w-0">
        <div class="relative">
          <div class="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none">
            <svg class="h-5 w-5 text-gray-400" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z" />
            </svg>
          </div>
          <input
            type="text"
            placeholder="Pesquisar por nome, WhatsApp..."
            value={searchTerm}
            on:input={(e) => searchTerm = e.target.value || ''}
            on:keydown={(e) => e.key === 'Enter' && handleSearch()}
            class="w-full pl-10 pr-4 py-2.5 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent transition-colors"
          />
        </div>
      </div>
      
      <div class="flex flex-col sm:flex-row gap-2 sm:gap-3">
        <button 
          on:click={handleSearch}
          class="w-full sm:w-auto px-4 py-2 border border-gray-300 rounded-lg text-gray-700 bg-white hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-blue-500"
        >
          Filtrar
        </button>
        <button 
          on:click={handleClearFilters}
          class="w-full sm:w-auto px-4 py-2 text-gray-600 bg-transparent hover:bg-gray-100 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
        >
          Limpar
        </button>
      </div>
    </div>
  </div>
  
  <!-- Results -->
  {#if $loading}
    <div class="flex items-center justify-center py-12">
      <div class="animate-spin rounded-full h-12 w-12 border-b-2 border-blue-600"></div>
    </div>
  {:else if $error}
    <div class="bg-red-50 border border-red-200 rounded-md p-4">
      <p class="text-sm text-red-600">{$error}</p>
    </div>
  {:else if $filteredJovens.length === 0}
    <div class="bg-white rounded-lg shadow p-12">
      <div class="text-center">
        <svg class="mx-auto h-12 w-12 text-gray-400" fill="none" viewBox="0 0 24 24" stroke="currentColor">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4.354a4 4 0 110 5.292M15 21H3v-1a6 6 0 0112 0v1zm0 0h6v-1a6 6 0 00-9-5.197m13.5-9a2.5 2.5 0 11-5 0 2.5 2.5 0 015 0z" />
        </svg>
        <h3 class="mt-2 text-sm font-medium text-gray-900">Nenhum jovem encontrado</h3>
        <p class="mt-1 text-sm text-gray-500">Tente ajustar os filtros ou cadastrar um novo jovem.</p>
        <div class="mt-6">
          <a href="/jovens/cadastrar" class="inline-flex items-center px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition-colors">
            <svg class="w-5 h-5 mr-2" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 6v6m0 0v6m0-6h6m-6 0H6" />
            </svg>
            Cadastrar Jovem
          </a>
        </div>
      </div>
    </div>
  {:else}
    <!-- Jovens grid -->
    <div class="grid grid-cols-1 gap-6">
      {#each $filteredJovens as jovem}
        <JovemCard {jovem} />
      {/each}
    </div>
    
    <!-- Pagination -->
    {#if $pagination.totalPages > 1}
      <div class="flex items-center justify-center space-x-2">
        <button
          on:click={() => handlePageChange($pagination.page - 1)}
          disabled={$pagination.page <= 1}
          class="px-3 py-2 text-sm font-medium text-gray-500 bg-white border border-gray-300 rounded-md hover:bg-gray-50 disabled:opacity-50 disabled:cursor-not-allowed"
        >
          Anterior
        </button>
        
        <span class="px-3 py-2 text-sm font-medium text-gray-700">
          Página {$pagination.page} de {$pagination.totalPages}
        </span>
        
        <button
          on:click={() => handlePageChange($pagination.page + 1)}
          disabled={$pagination.page >= $pagination.totalPages}
          class="px-3 py-2 text-sm font-medium text-gray-500 bg-white border border-gray-300 rounded-md hover:bg-gray-50 disabled:opacity-50 disabled:cursor-not-allowed"
        >
          Próxima
        </button>
      </div>
    {/if}
  {/if}
</div>
