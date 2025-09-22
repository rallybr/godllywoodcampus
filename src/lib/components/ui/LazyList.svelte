<script>
  import { onMount, onDestroy } from 'svelte';
  
  export let items = [];
  export let itemComponent = '';
  export let itemProps = {};
  export let itemsPerPage = 20;
  export let threshold = 100; // pixels from bottom to trigger load
  
  let container;
  let loading = false;
  let hasMore = true;
  let currentPage = 1;
  let visibleItems = [];
  let ItemComponent = null;
  
  // Carregar componente quando items mudarem
  $: if (items.length > 0 && !ItemComponent) {
    loadComponent();
  }
  
  // Atualizar itens visíveis
  $: if (items.length > 0 && ItemComponent) {
    updateVisibleItems();
  }
  
  async function loadComponent() {
    if (!itemComponent) return;
    
    try {
      const module = await import(/* @vite-ignore */ itemComponent);
      ItemComponent = module.default;
    } catch (err) {
      console.error('Erro ao carregar componente de item:', err);
    }
  }
  
  function updateVisibleItems() {
    const endIndex = currentPage * itemsPerPage;
    visibleItems = items.slice(0, endIndex);
    hasMore = endIndex < items.length;
  }
  
  function loadMore() {
    if (loading || !hasMore) return;
    
    loading = true;
    currentPage += 1;
    
    // Simular delay de carregamento
    setTimeout(() => {
      updateVisibleItems();
      loading = false;
    }, 300);
  }
  
  function handleScroll() {
    if (!container || loading || !hasMore) return;
    
    const { scrollTop, scrollHeight, clientHeight } = container;
    const distanceFromBottom = scrollHeight - scrollTop - clientHeight;
    
    if (distanceFromBottom < threshold) {
      loadMore();
    }
  }
  
  onMount(() => {
    if (container) {
      container.addEventListener('scroll', handleScroll);
    }
  });
  
  onDestroy(() => {
    if (container) {
      container.removeEventListener('scroll', handleScroll);
    }
  });
  
  // Reset quando items mudarem
  $: if (items) {
    currentPage = 1;
    visibleItems = [];
    hasMore = true;
  }
</script>

<div bind:this={container} class="h-full overflow-y-auto">
  {#if ItemComponent}
    {#each visibleItems as item, index (item.id || index)}
      <svelte:component 
        this={ItemComponent} 
        {item} 
        {...itemProps} 
      />
    {/each}
    
    {#if loading}
      <div class="flex items-center justify-center p-4">
        <div class="animate-spin rounded-full h-6 w-6 border-b-2 border-blue-600"></div>
        <span class="ml-2 text-sm text-gray-600">Carregando mais...</span>
      </div>
    {/if}
    
    {#if !hasMore && items.length > 0}
      <div class="text-center p-4 text-sm text-gray-500">
        Todos os itens foram carregados
      </div>
    {/if}
  {:else}
    <div class="flex items-center justify-center p-8">
      <div class="animate-spin rounded-full h-8 w-8 border-b-2 border-blue-600"></div>
      <span class="ml-3 text-gray-600">Carregando componentes...</span>
    </div>
  {/if}
</div>
