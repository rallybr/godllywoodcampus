<script>
  import { createEventDispatcher, onMount, onDestroy } from 'svelte';
  import { supabase } from '$lib/utils/supabase';
  
  export let placeholder = 'Digite para buscar...';
  export let value = '';
  export let label = '';
  export let error = '';
  export let disabled = false;
  export let required = false;
  export let minLength = 2;
  export let debounceMs = 300;
  export let searchFunction = null; // Função personalizada de busca
  
  const dispatch = createEventDispatcher();
  
  let inputElement;
  let suggestions = [];
  let showSuggestions = false;
  let selectedIndex = -1;
  let loading = false;
  let debounceTimer;
  
  // Função para buscar sugestões
  async function searchSuggestions(searchTerm) {
    console.log('searchSuggestions chamada com:', searchTerm);
    console.log('minLength:', minLength);
    console.log('searchFunction existe:', !!searchFunction);
    
    if (searchTerm.length < minLength) {
      suggestions = [];
      showSuggestions = false;
      return;
    }
    
    loading = true;
    
    try {
      let data = [];
      
      // Se uma função personalizada foi fornecida, usá-la
      if (searchFunction && typeof searchFunction === 'function') {
        console.log('Usando searchFunction personalizada');
        data = await searchFunction(searchTerm);
        console.log('Dados retornados pela searchFunction:', data);
      } else {
        console.log('Usando busca padrão na tabela jovens');
        // Busca padrão na tabela jovens
        const { data: fetchData, error: fetchError } = await supabase
          .from('jovens')
          .select('id, nome_completo, whatsapp, estado:estados(sigla)')
          .ilike('nome_completo', `%${searchTerm}%`)
          .order('nome_completo')
          .limit(10);
        
        if (fetchError) {
          console.error('Erro ao buscar sugestões:', fetchError);
          data = [];
        } else {
          data = fetchData || [];
        }
      }
      
      suggestions = data;
      showSuggestions = suggestions.length > 0;
      selectedIndex = -1;
      console.log('Sugestões finais:', suggestions);
      console.log('showSuggestions:', showSuggestions);
    } catch (err) {
      console.error('Erro na busca:', err);
      suggestions = [];
      showSuggestions = false;
    } finally {
      loading = false;
    }
  }
  
  // Função com debounce para evitar muitas requisições
  function handleInput(event) {
    const searchTerm = event.target.value;
    console.log('handleInput chamado com:', searchTerm);
    
    // Limpar timer anterior
    if (debounceTimer) {
      clearTimeout(debounceTimer);
    }
    
    // Definir novo timer
    debounceTimer = setTimeout(() => {
      console.log('Executando searchSuggestions após debounce');
      searchSuggestions(searchTerm);
    }, debounceMs);
    
    dispatch('input', { value: searchTerm });
  }
  
  // Função para selecionar uma sugestão
  function selectSuggestion(suggestion) {
    // Determinar o valor a ser exibido baseado na estrutura dos dados
    let displayValue = '';
    if (suggestion.nome_completo) {
      displayValue = suggestion.nome_completo;
    } else if (suggestion.nome) {
      displayValue = suggestion.nome;
    } else if (suggestion.display) {
      displayValue = suggestion.display;
    } else {
      displayValue = suggestion.toString();
    }
    
    value = displayValue;
    showSuggestions = false;
    selectedIndex = -1;
    dispatch('select', { suggestion });
    dispatch('input', { value: displayValue });
  }
  
  // Função para lidar com teclas
  function handleKeydown(event) {
    if (!showSuggestions || suggestions.length === 0) {
      if (event.key === 'Enter') {
        dispatch('search', { value });
      }
      return;
    }
    
    switch (event.key) {
      case 'ArrowDown':
        event.preventDefault();
        selectedIndex = Math.min(selectedIndex + 1, suggestions.length - 1);
        break;
      case 'ArrowUp':
        event.preventDefault();
        selectedIndex = Math.max(selectedIndex - 1, -1);
        break;
      case 'Enter':
        event.preventDefault();
        if (selectedIndex >= 0 && selectedIndex < suggestions.length) {
          selectSuggestion(suggestions[selectedIndex]);
        } else {
          dispatch('search', { value });
        }
        break;
      case 'Escape':
        showSuggestions = false;
        selectedIndex = -1;
        break;
    }
  }
  
  // Função para fechar sugestões ao clicar fora
  function handleClickOutside(event) {
    if (inputElement && !inputElement.contains(event.target)) {
      showSuggestions = false;
      selectedIndex = -1;
    }
  }
  
  // Função para limpar busca
  function clearSearch() {
    value = '';
    suggestions = [];
    showSuggestions = false;
    selectedIndex = -1;
    dispatch('input', { value: '' });
    if (inputElement) {
      inputElement.focus();
    }
  }
  
  onMount(() => {
    document.addEventListener('click', handleClickOutside);
  });
  
  onDestroy(() => {
    document.removeEventListener('click', handleClickOutside);
    if (debounceTimer) {
      clearTimeout(debounceTimer);
    }
  });
</script>

<div class="relative">
  {#if label}
    <label for="autocomplete-input" class="block text-sm font-medium text-gray-700 mb-1">
      {label}
      {#if required}
        <span class="text-red-500">*</span>
      {/if}
    </label>
  {/if}
  
  <div class="relative">
    <div class="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none">
      <svg class="h-5 w-5 text-gray-400" fill="none" viewBox="0 0 24 24" stroke="currentColor">
        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z" />
      </svg>
    </div>
    
    <input
      id="autocomplete-input"
      bind:this={inputElement}
      type="text"
      {placeholder}
      bind:value
      {disabled}
      {required}
      on:input={handleInput}
      on:keydown={handleKeydown}
      on:focus={() => {
        if (suggestions.length > 0) {
          showSuggestions = true;
        }
      }}
      class="w-full pl-10 pr-20 py-2.5 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent transition-colors disabled:bg-gray-50 disabled:text-gray-500 {error ? 'border-red-300 focus:ring-red-500' : ''}"
    />
    
    <!-- Botão de limpar -->
    {#if value && !disabled}
      <button
        type="button"
        on:click={clearSearch}
        class="absolute inset-y-0 right-8 flex items-center pr-2 text-gray-400 hover:text-gray-600"
      >
        <svg class="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12" />
        </svg>
      </button>
    {/if}
    
    <!-- Loading indicator -->
    {#if loading}
      <div class="absolute inset-y-0 right-2 flex items-center">
        <div class="animate-spin rounded-full h-4 w-4 border-b-2 border-blue-600"></div>
      </div>
    {/if}
  </div>
  
  <!-- Sugestões -->
  {#if showSuggestions}
    <div class="absolute z-50 w-full mt-1 bg-white border border-gray-300 rounded-lg shadow-lg max-h-60 overflow-y-auto" style="position: absolute; z-index: 9999;">
      {#if suggestions.length > 0}
        {#each suggestions as suggestion, index}
          <button
            type="button"
            on:click={() => selectSuggestion(suggestion)}
            class="w-full px-4 py-3 text-left hover:bg-gray-50 focus:bg-gray-50 focus:outline-none {index === selectedIndex ? 'bg-blue-50' : ''}"
          >
            <div class="flex items-center justify-between">
              <div>
                <!-- Para usuários (com display) -->
                {#if suggestion.display}
                  <div class="font-medium text-gray-900">{suggestion.display}</div>
                <!-- Para jovens (com nome_completo) -->
                {:else if suggestion.nome_completo}
                  <div class="font-medium text-gray-900">{suggestion.nome_completo}</div>
                  {#if suggestion.whatsapp}
                    <div class="text-sm text-gray-500">{suggestion.whatsapp}</div>
                  {/if}
                <!-- Para outros casos -->
                {:else}
                  <div class="font-medium text-gray-900">{suggestion.nome || suggestion.toString()}</div>
                {/if}
              </div>
              {#if suggestion.estado?.sigla}
                <div class="text-sm text-gray-400">{suggestion.estado.sigla}</div>
              {/if}
            </div>
          </button>
        {/each}
      {:else}
        <div class="px-4 py-3 text-gray-500">Nenhuma sugestão encontrada</div>
      {/if}
    </div>
  {/if}
  
  <!-- Debug info -->
  {#if showSuggestions}
    <div class="absolute top-full left-0 bg-red-100 p-2 text-xs">
      Debug: showSuggestions={showSuggestions}, suggestions.length={suggestions.length}
    </div>
  {/if}
  
  <!-- Mensagem de erro -->
  {#if error}
    <p class="mt-1 text-sm text-red-600">{error}</p>
  {/if}
</div>
