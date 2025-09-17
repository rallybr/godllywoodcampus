<script>
  import { goto } from '$app/navigation';
  import Button from '$lib/components/ui/Button.svelte';
  
  export let jovem;
  
  function hasAvaliacoes(value) {
    if (value === true) return true;
    if (typeof value === 'number') return value > 0;
    if (typeof value === 'string') return value === 'true' || value === '1';
    if (Array.isArray(value)) return value.length > 0;
    return false;
  }

  function handleView() {
    goto(`/jovens/${jovem.id}`);
  }
  
  function handleEvaluate() {
    goto(`/jovens/${jovem.id}?tab=avaliacoes`);
  }
  
  function handleViewFicha() {
    goto(`/jovens/${jovem.id}/ficha-test`);
  }
  
  function getAprovadoColor(aprovado, temAvaliacoes) {
    if (hasAvaliacoes(temAvaliacoes)) {
      return 'bg-blue-100 text-blue-800 border-blue-200';
    }
    
    switch (aprovado) {
      case 'aprovado':
        return 'bg-green-100 text-green-800 border-green-200';
      case 'pre_aprovado':
        return 'bg-yellow-100 text-yellow-800 border-yellow-200';
      default:
        return 'bg-gray-100 text-gray-800 border-gray-200';
    }
  }
  
  function getAprovadoText(aprovado, temAvaliacoes) {
    if (hasAvaliacoes(temAvaliacoes)) {
      return 'Avaliado';
    }
    
    switch (aprovado) {
      case 'aprovado':
        return 'Aprovado';
      case 'pre_aprovado':
        return 'Pré-aprovado';
      default:
        return 'Pendente';
    }
  }
  
  function getAprovadoIcon(aprovado, temAvaliacoes) {
    if (hasAvaliacoes(temAvaliacoes)) {
      return 'M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z';
    }
    
    switch (aprovado) {
      case 'aprovado':
        return 'M5 13l4 4L19 7';
      case 'pre_aprovado':
        return 'M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z';
      default:
        return 'M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z';
    }
  }
</script>

<div class="bg-white rounded-2xl shadow-lg hover:shadow-xl transition-all duration-300 group overflow-hidden border border-gray-100">
  <!-- Header with photo and basic info -->
  <div class="bg-gradient-to-r from-blue-50 to-indigo-50 p-6 border-b border-gray-100">
    <div class="flex items-start space-x-6">
      <!-- Profile picture with enhanced styling -->
      <div class="relative">
        <div class="w-20 h-20 rounded-2xl overflow-hidden border-4 border-white shadow-lg">
          {#if jovem.foto}
            <img
              class="w-full h-full object-cover"
              src={jovem.foto}
              alt={jovem.nome_completo}
            />
          {:else}
            <div class="w-full h-full bg-gradient-to-br from-blue-500 to-purple-600 flex items-center justify-center">
              <span class="text-white font-bold text-2xl">
                {jovem.nome_completo?.charAt(0) || 'J'}
              </span>
            </div>
          {/if}
        </div>
      </div>
      
      <div class="flex-1 min-w-0">
        <!-- Name and basic info -->
        <div class="mb-4">
          <div class="flex items-center justify-between mb-2">
            <h3 class="text-2xl font-bold text-gray-900">
              {jovem.nome_completo}
            </h3>
            <!-- Status badge -->
            <span class="inline-flex items-center px-3 py-1 rounded-full text-xs font-semibold border-2 border-white shadow-md {getAprovadoColor(jovem.aprovado, jovem.tem_avaliacoes)}">
              <svg class="w-3 h-3 mr-1" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d={getAprovadoIcon(jovem.aprovado, jovem.tem_avaliacoes)} />
              </svg>
              {getAprovadoText(jovem.aprovado, jovem.tem_avaliacoes)}
            </span>
          </div>
          <div class="flex items-center space-x-4 text-sm text-gray-600">
            <div class="flex items-center space-x-1">
              <svg class="w-4 h-4 text-blue-500" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M8 7V3m8 4V3m-9 8h10M5 21h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v12a2 2 0 002 2z" />
              </svg>
              <span class="font-semibold">{jovem.idade} anos</span>
            </div>
            <div class="flex items-center space-x-1">
              <svg class="w-4 h-4 text-green-500" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M17.657 16.657L13.414 20.9a1.998 1.998 0 01-2.827 0l-4.244-4.243a8 8 0 1111.314 0z" />
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 11a3 3 0 11-6 0 3 3 0 016 0z" />
              </svg>
              <span class="font-semibold">{jovem.estado?.sigla || 'N/A'}</span>
            </div>
          </div>
          <div class="mt-2">
            <span class="inline-flex items-center px-3 py-1 rounded-full text-sm font-medium bg-blue-100 text-blue-800">
              <svg class="w-4 h-4 mr-1" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 6.253v13m0-13C10.832 5.477 9.246 5 7.5 5S4.168 5.477 3 6.253v13C4.168 18.477 5.754 18 7.5 18s3.332.477 4.5 1.253m0-13C13.168 5.477 14.754 5 16.5 5c1.746 0 3.332.477 4.5 1.253v13C19.832 18.477 18.246 18 16.5 18c-1.746 0-3.332.477-4.5 1.253" />
              </svg>
              {jovem.edicao}
            </span>
          </div>
        </div>
      </div>
    </div>
  </div>
  
  <!-- Content area with organized information -->
  <div class="p-6">
    <div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-6">
      <!-- Igreja -->
      <div class="flex items-center space-x-3 p-4 bg-gray-50 rounded-xl hover:bg-gray-100 transition-colors">
        <div class="w-10 h-10 bg-purple-100 rounded-lg flex items-center justify-center">
          <svg class="w-5 h-5 text-purple-600" fill="none" viewBox="0 0 24 24" stroke="currentColor">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 21V5a2 2 0 00-2-2H7a2 2 0 00-2 2v16m14 0h2m-2 0h-5m-9 0H3m2 0h5M9 7h1m-1 4h1m4-4h1m-1 4h1m-5 10v-5a1 1 0 011-1h2a1 1 0 011 1v5m-4 0h4" />
          </svg>
        </div>
        <div>
          <p class="text-xs font-medium text-gray-500 uppercase tracking-wide">Igreja</p>
          <p class="text-sm font-semibold text-gray-900 truncate">
            {jovem.igreja?.nome || 'N/A'}
          </p>
        </div>
      </div>
      
      <!-- Região -->
      <div class="flex items-center space-x-3 p-4 bg-gray-50 rounded-xl hover:bg-gray-100 transition-colors">
        <div class="w-10 h-10 bg-green-100 rounded-lg flex items-center justify-center">
          <svg class="w-5 h-5 text-green-600" fill="none" viewBox="0 0 24 24" stroke="currentColor">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M17.657 16.657L13.414 20.9a1.998 1.998 0 01-2.827 0l-4.244-4.243a8 8 0 1111.314 0z" />
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 11a3 3 0 11-6 0 3 3 0 016 0z" />
          </svg>
        </div>
        <div>
          <p class="text-xs font-medium text-gray-500 uppercase tracking-wide">Região</p>
          <p class="text-sm font-semibold text-gray-900 truncate">
            {jovem.regiao?.nome || 'N/A'}
          </p>
        </div>
      </div>
      
      <!-- Bloco -->
      <div class="flex items-center space-x-3 p-4 bg-gray-50 rounded-xl hover:bg-gray-100 transition-colors">
        <div class="w-10 h-10 bg-orange-100 rounded-lg flex items-center justify-center">
          <svg class="w-5 h-5 text-orange-600" fill="none" viewBox="0 0 24 24" stroke="currentColor">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 11H5m14 0a2 2 0 012 2v6a2 2 0 01-2 2H5a2 2 0 01-2-2v-6a2 2 0 012-2m14 0V9a2 2 0 00-2-2M5 11V9a2 2 0 012-2m0 0V5a2 2 0 012-2h6a2 2 0 012 2v2M7 7h10" />
          </svg>
        </div>
        <div>
          <p class="text-xs font-medium text-gray-500 uppercase tracking-wide">Bloco</p>
          <p class="text-sm font-semibold text-gray-900 truncate">
            {jovem.bloco?.nome || 'N/A'}
          </p>
        </div>
      </div>
    </div>
  </div>
  
  <!-- Actions -->
  <div class="px-6 py-5 bg-gradient-to-r from-gray-50 to-gray-100 border-t border-gray-200">
    <div class="flex space-x-2">
      <button 
        on:click={handleView}
        class="flex-1 flex items-center justify-center py-3 px-4 rounded-xl border-2 border-gray-300 text-gray-700 font-semibold hover:bg-blue-50 hover:border-blue-400 hover:text-blue-700 transition-all duration-200 group-hover:shadow-md"
      >
        <svg class="w-5 h-5 mr-2" fill="none" viewBox="0 0 24 24" stroke="currentColor">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 12a3 3 0 11-6 0 3 3 0 016 0z" />
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M2.458 12C3.732 7.943 7.523 5 12 5c4.478 0 8.268 2.943 9.542 7-1.274 4.057-5.064 7-9.542 7-4.477 0-8.268-2.943-9.542-7z" />
        </svg>
        Ver Perfil
      </button>
      
      <button 
        on:click={handleViewFicha}
        class="flex-1 flex items-center justify-center py-3 px-4 rounded-xl border-2 border-purple-300 text-purple-700 font-semibold hover:bg-purple-50 hover:border-purple-400 hover:text-purple-800 transition-all duration-200 group-hover:shadow-md"
      >
        <svg class="w-5 h-5 mr-2" fill="none" viewBox="0 0 24 24" stroke="currentColor">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z" />
        </svg>
        Ver Ficha
      </button>
      
      <button 
        on:click={handleEvaluate}
        class="flex-1 flex items-center justify-center py-3 px-4 rounded-xl bg-gradient-to-r from-blue-600 to-indigo-600 hover:from-blue-700 hover:to-indigo-700 text-white font-semibold shadow-lg hover:shadow-xl transition-all duration-200"
      >
        <svg class="w-5 h-5 mr-2" fill="none" viewBox="0 0 24 24" stroke="currentColor">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5H7a2 2 0 00-2 2v10a2 2 0 002 2h8a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2m-3 7h3m-3 4h3m-6-4h.01M9 16h.01" />
        </svg>
        Avaliar
      </button>
    </div>
  </div>
</div>
