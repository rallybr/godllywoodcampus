<script>
  import { onMount } from 'svelte';
  import { goto } from '$app/navigation';
  import { user } from '$lib/stores/auth';
  import { loadJovens, filteredJovens, filters, loading, error, pagination } from '$lib/stores/jovens';
  import { loadEstatisticas, estatisticas, estatisticasFiltradas } from '$lib/stores/estatisticas';
  import Button from '$lib/components/ui/Button.svelte';
  import Input from '$lib/components/ui/Input.svelte';
  import Select from '$lib/components/ui/Select.svelte';
  import Card from '$lib/components/ui/Card.svelte';
  import JovemCard from '$lib/components/jovens/JovemCard.svelte';
  
  let searchTerm = '';
  let currentPage = 1;
  let viewMode = 'grid'; // 'grid' or 'list'
  
  onMount(() => {
    if (!$user) {
      goto('/login');
    } else {
      loadJovens();
      loadEstatisticas();
    }
  });
  
  function handleSearch() {
    filters.update(f => ({ ...f, nome_like: searchTerm }));
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
  
  const edicaoOptions = [
    { value: '', label: 'Todas as edições' },
    { value: '1ª Edição IntelliMen Campus', label: '1ª Edição' },
    { value: '2ª Edição IntelliMen Campus', label: '2ª Edição' },
    { value: '3ª Edição IntelliMen Campus', label: '3ª Edição' },
    { value: '4ª Edição IntelliMen Campus', label: '4ª Edição' },
    { value: '5ª Edição IntelliMen Campus', label: '5ª Edição' }
  ];
  
  const sexoOptions = [
    { value: '', label: 'Todos' },
    { value: 'masculino', label: 'Masculino' },
    { value: 'feminino', label: 'Feminino' }
  ];
  
  const condicaoOptions = [
    { value: '', label: 'Todas' },
    { value: 'jovem_batizado_es', label: 'Jovem Batizado(a) ES' },
    { value: 'cpo', label: 'CPO' },
    { value: 'colaborador', label: 'Colaborador(a)' },
    { value: 'obreiro', label: 'Obreiro(a)' },
    { value: 'iburd', label: 'IBURD' },
    { value: 'namorada', label: 'Namorada' },
    { value: 'noiva', label: 'Noiva' }
  ];
  
  const aprovadoOptions = [
    { value: '', label: 'Todos' },
    { value: 'null', label: 'Não avaliado' },
    { value: 'avaliado', label: 'Avaliado' },
    { value: 'pre_aprovado', label: 'Pré-aprovado' },
    { value: 'aprovado', label: 'Aprovado' }
  ];
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
      
      <Button href="/jovens/cadastrar" variant="primary">
        <svg class="w-5 h-5 mr-2" fill="none" viewBox="0 0 24 24" stroke="currentColor">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 6v6m0 0v6m0-6h6m-6 0H6" />
        </svg>
        Cadastrar Jovem
      </Button>
    </div>
  </div>
  
  <!-- Stats cards -->
  <div class="grid grid-cols-1 md:grid-cols-4 gap-4">
    <div class="fb-card p-4">
      <div class="flex items-center">
        <div class="w-10 h-10 bg-blue-100 rounded-lg flex items-center justify-center">
          <svg class="w-5 h-5 text-blue-600" fill="none" viewBox="0 0 24 24" stroke="currentColor">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4.354a4 4 0 110 5.292M15 21H3v-1a6 6 0 0112 0v1zm0 0h6v-1a6 6 0 00-9-5.197m13.5-9a2.5 2.5 0 11-5 0 2.5 2.5 0 015 0z" />
          </svg>
        </div>
        <div class="ml-3">
          <p class="text-sm font-medium text-gray-500">Total</p>
          <p class="text-lg font-semibold text-gray-900">{$estatisticasFiltradas.total}</p>
        </div>
      </div>
    </div>
    
    <div class="fb-card p-4">
      <div class="flex items-center">
        <div class="w-10 h-10 bg-green-100 rounded-lg flex items-center justify-center">
          <svg class="w-5 h-5 text-green-600" fill="none" viewBox="0 0 24 24" stroke="currentColor">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7" />
          </svg>
        </div>
        <div class="ml-3">
          <p class="text-sm font-medium text-gray-500">Aprovados</p>
          <p class="text-lg font-semibold text-gray-900">{$estatisticasFiltradas.aprovados}</p>
        </div>
      </div>
    </div>
    
    <div class="fb-card p-4">
      <div class="flex items-center">
        <div class="w-10 h-10 bg-yellow-100 rounded-lg flex items-center justify-center">
          <svg class="w-5 h-5 text-yellow-600" fill="none" viewBox="0 0 24 24" stroke="currentColor">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z" />
          </svg>
        </div>
        <div class="ml-3">
          <p class="text-sm font-medium text-gray-500">Pendentes</p>
          <p class="text-lg font-semibold text-gray-900">{$estatisticasFiltradas.pendentes}</p>
        </div>
      </div>
    </div>
    
    <div class="fb-card p-4">
      <div class="flex items-center">
        <div class="w-10 h-10 bg-purple-100 rounded-lg flex items-center justify-center">
          <svg class="w-5 h-5 text-purple-600" fill="none" viewBox="0 0 24 24" stroke="currentColor">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 7h8m0 0v8m0-8l-8 8-4-4-6 6" />
          </svg>
        </div>
        <div class="ml-3">
          <p class="text-sm font-medium text-gray-500">Crescimento</p>
          <p class="text-lg font-semibold text-gray-900">{$estatisticas.crescimento > 0 ? '+' : ''}{$estatisticas.crescimento}%</p>
        </div>
      </div>
    </div>
  </div>
  
  <!-- Filters -->
  <div class="fb-card p-4 sm:p-6">
    <!-- Primeira linha: Selects -->
    <div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-3 sm:gap-4 mb-4 sm:mb-6">
      <div>
        <Select
          label="Edição"
          options={edicaoOptions}
          value={$filters.edicao}
          on:change={(e) => $filters.edicao = e.detail.value || ''}
        />
      </div>
      
      <div>
        <Select
          label="Sexo"
          options={sexoOptions}
          value={$filters.sexo}
          on:change={(e) => $filters.sexo = e.detail.value || ''}
        />
      </div>
      
      <div>
        <Select
          label="Condição"
          options={condicaoOptions}
          value={$filters.condicao}
          on:change={(e) => $filters.condicao = e.detail.value || ''}
        />
      </div>
      
      <div>
        <Select
          label="Aprovado"
          options={aprovadoOptions}
          value={$filters.aprovado}
          on:change={(e) => $filters.aprovado = e.detail.value || ''}
        />
      </div>
    </div>
    
    <!-- Segunda linha: Busca e Botões -->
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
            on:input={(e) => searchTerm = e.target?.value || ''}
            on:keydown={(e) => e.key === 'Enter' && handleSearch()}
            class="w-full pl-10 pr-4 py-2.5 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent transition-colors"
          />
        </div>
      </div>
      
      <div class="flex flex-col sm:flex-row gap-2 sm:gap-3">
        <Button variant="outline" on:click={handleSearch} class="w-full sm:w-auto">
          Filtrar
        </Button>
        <Button variant="ghost" on:click={handleClearFilters} class="w-full sm:w-auto">
          Limpar
        </Button>
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
    <div class="fb-card p-12">
      <div class="text-center">
        <svg class="mx-auto h-12 w-12 text-gray-400" fill="none" viewBox="0 0 24 24" stroke="currentColor">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4.354a4 4 0 110 5.292M15 21H3v-1a6 6 0 0112 0v1zm0 0h6v-1a6 6 0 00-9-5.197m13.5-9a2.5 2.5 0 11-5 0 2.5 2.5 0 015 0z" />
        </svg>
        <h3 class="mt-2 text-sm font-medium text-gray-900">Nenhum jovem encontrado</h3>
        <p class="mt-1 text-sm text-gray-500">Tente ajustar os filtros ou cadastrar um novo jovem.</p>
        <div class="mt-6">
          <Button href="/jovens/cadastrar" variant="primary">
            <svg class="w-5 h-5 mr-2" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 6v6m0 0v6m0-6h6m-6 0H6" />
            </svg>
            Cadastrar Jovem
          </Button>
        </div>
      </div>
    </div>
  {:else}
    <!-- Jovens grid/list -->
    {#if viewMode === 'grid'}
      <div class="grid grid-cols-1 gap-6">
        {#each $filteredJovens as jovem}
          <JovemCard {jovem} />
        {/each}
      </div>
    {:else}
      <div class="space-y-4">
        {#each $filteredJovens as jovem}
          <div class="fb-card p-4 hover:shadow-md transition-shadow">
            <div class="flex items-center space-x-4">
              {#if jovem.foto}
                <img
                  class="profile-pic profile-pic-md"
                  src={jovem.foto}
                  alt={jovem.nome_completo}
                />
              {:else}
                <div class="profile-pic profile-pic-md bg-gradient-to-br from-blue-500 to-purple-600 flex items-center justify-center">
                  <span class="text-white font-bold text-sm">
                    {jovem.nome_completo?.charAt(0) || 'J'}
                  </span>
                </div>
              {/if}
              
              <div class="flex-1 min-w-0">
                <h3 class="text-lg font-semibold text-gray-900 truncate">
                  {jovem.nome_completo}
                </h3>
                <p class="text-sm text-gray-600">
                  {jovem.idade} anos • {jovem.estado?.sigla || 'N/A'} • {jovem.edicao}
                </p>
                <p class="text-sm text-gray-500">
                  {jovem.igreja?.nome || 'N/A'} • {jovem.regiao?.nome || 'N/A'}
                </p>
              </div>
              
              <div class="flex items-center space-x-3">
                <span class="inline-flex items-center px-2 py-1 rounded-full text-xs font-medium border {jovem.aprovado === 'aprovado' ? 'bg-green-100 text-green-800 border-green-200' : jovem.aprovado === 'pre_aprovado' ? 'bg-yellow-100 text-yellow-800 border-yellow-200' : 'bg-gray-100 text-gray-800 border-gray-200'}">
                  {jovem.aprovado === 'aprovado' ? 'Aprovado' : jovem.aprovado === 'pre_aprovado' ? 'Pré-aprovado' : 'Não avaliado'}
                </span>
                
                <Button variant="outline" size="sm" href="/jovens/{jovem.id}">
                  Ver Perfil
                </Button>
              </div>
            </div>
          </div>
        {/each}
      </div>
    {/if}
    
    <!-- Pagination -->
    {#if $pagination.totalPages > 1}
      <div class="flex items-center justify-between">
        <div class="text-sm text-gray-700">
          Mostrando {($pagination.page - 1) * $pagination.limit + 1} a {Math.min($pagination.page * $pagination.limit, $pagination.total)} de {$pagination.total} resultados
        </div>
        
        <div class="flex space-x-2">
          <Button
            variant="outline"
            disabled={$pagination.page === 1}
            on:click={() => handlePageChange($pagination.page - 1)}
          >
            Anterior
          </Button>
          
          {#each Array.from({ length: $pagination.totalPages }, (_, i) => i + 1) as page}
            <Button
              variant={page === $pagination.page ? 'primary' : 'outline'}
              on:click={() => handlePageChange(page)}
            >
              {page}
            </Button>
          {/each}
          
          <Button
            variant="outline"
            disabled={$pagination.page === $pagination.totalPages}
            on:click={() => handlePageChange($pagination.page + 1)}
          >
            Próxima
          </Button>
        </div>
      </div>
    {/if}
  {/if}
</div>
