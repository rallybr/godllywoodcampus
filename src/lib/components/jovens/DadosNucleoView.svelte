<script>
  import { onMount } from 'svelte';
  import { loadDadosNucleo } from '$lib/stores/dados-nucleo';
  
  export let jovemId;
  
  let dadosNucleo = null;
  let loading = true;
  let error = null;
  
  // Modal para fotos
  let showPhotoModal = false;
  let selectedPhoto = '';
  let selectedPhotoIndex = 0;
  
  // Carrossel de fotos
  let currentPhotoIndex = 0;
  let photos = [];
  let isTransitioning = false;
  
  onMount(async () => {
    try {
      dadosNucleo = await loadDadosNucleo(jovemId);
      
      // Preparar array de fotos para o carrossel
      if (dadosNucleo) {
        photos = [
          dadosNucleo.foto_1,
          dadosNucleo.foto_2,
          dadosNucleo.foto_3,
          dadosNucleo.foto_4,
          dadosNucleo.foto_5
        ].filter(photo => photo && photo.trim() !== '');
      }
    } catch (err) {
      console.error('Erro ao carregar dados do núcleo:', err);
      error = err.message || 'Erro ao carregar dados do núcleo';
    } finally {
      loading = false;
    }
  });
  
  function formatDiasSemana(dias) {
    if (!dias || !Array.isArray(dias)) return 'Não informado';
    return dias.join(', ');
  }
  
  function getVideoEmbedUrl(url, platform) {
    if (!url || !platform) return null;
    
    if (platform === 'youtube') {
      const videoId = extractYouTubeVideoId(url);
      if (videoId) {
        return `https://www.youtube.com/embed/${videoId}`;
      }
    }
    
    return url;
  }
  
  function extractYouTubeVideoId(url) {
    if (!url) return null;
    
    const patterns = [
      /(?:youtube\.com\/watch\?v=)([^&\n?#]+)/,
      /(?:youtu\.be\/)([^&\n?#]+)/,
      /(?:youtube\.com\/embed\/)([^&\n?#]+)/,
      /(?:youtube\.com\/v\/)([^&\n?#]+)/
    ];
    
    for (const pattern of patterns) {
      const match = url.match(pattern);
      if (match) return match[1];
    }
    
    return null;
  }
  
  function openPhotoModal(photo, index) {
    selectedPhoto = photo;
    selectedPhotoIndex = index;
    showPhotoModal = true;
  }
  
  function closePhotoModal() {
    showPhotoModal = false;
    selectedPhoto = '';
    selectedPhotoIndex = 0;
  }
  
  function handleKeydown(event) {
    if (event.key === 'Escape') {
      closePhotoModal();
    }
  }
  
  // Funções do carrossel com transições suaves
  async function nextPhoto() {
    if (photos.length > 0 && !isTransitioning) {
      isTransitioning = true;
      currentPhotoIndex = (currentPhotoIndex + 1) % photos.length;
      await new Promise(resolve => setTimeout(resolve, 500));
      isTransitioning = false;
    }
  }
  
  async function prevPhoto() {
    if (photos.length > 0 && !isTransitioning) {
      isTransitioning = true;
      currentPhotoIndex = currentPhotoIndex === 0 ? photos.length - 1 : currentPhotoIndex - 1;
      await new Promise(resolve => setTimeout(resolve, 500));
      isTransitioning = false;
    }
  }
  
  async function goToPhoto(index) {
    if (!isTransitioning && index !== currentPhotoIndex) {
      isTransitioning = true;
      currentPhotoIndex = index;
      await new Promise(resolve => setTimeout(resolve, 500));
      isTransitioning = false;
    }
  }
</script>

{#if loading}
  <div class="flex items-center justify-center py-8">
    <div class="animate-spin rounded-full h-8 w-8 border-b-2 border-blue-600"></div>
    <span class="ml-3 text-gray-600">Carregando dados do núcleo...</span>
  </div>
{:else if error}
  <div class="bg-red-50 border border-red-200 rounded-lg p-4">
    <div class="flex">
      <svg class="h-5 w-5 text-red-400" fill="none" viewBox="0 0 24 24" stroke="currentColor">
        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8v4m0 4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
      </svg>
      <div class="ml-3">
        <h3 class="text-sm font-medium text-red-800">Erro ao carregar dados</h3>
        <p class="mt-1 text-sm text-red-700">{error}</p>
      </div>
    </div>
  </div>
{:else if !dadosNucleo}
  <div class="text-center py-12">
    <div class="w-16 h-16 bg-gray-100 rounded-full flex items-center justify-center mx-auto mb-4">
      <svg class="w-8 h-8 text-gray-600" fill="none" viewBox="0 0 24 24" stroke="currentColor">
        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9.663 17h4.673M12 3v1m6.364 1.636l-.707.707M21 12h-1M4 12H3m3.343-5.657l-.707-.707m2.828 9.9a5 5 0 117.072 0l-.548.547A3.374 3.374 0 0014 18.469V19a2 2 0 11-4 0v-.531c0-.895-.356-1.754-.988-2.386l-.548-.547z" />
      </svg>
    </div>
    <h3 class="text-lg font-semibold text-gray-900 mb-2">Nenhum dado de núcleo encontrado</h3>
    <p class="text-gray-600">Este jovem ainda não preencheu os dados do seu núcleo de oração.</p>
  </div>
{:else}
  <div class="space-y-8">
    <!-- Pergunta Principal -->
    <div class="bg-gradient-to-r from-blue-50 to-indigo-50 rounded-xl border border-blue-200 p-4 sm:p-6 lg:p-8 shadow-sm shadow-bottom-xl">
      <div class="flex items-center mb-4 sm:mb-6">
        <div class="w-8 h-8 sm:w-10 sm:h-10 bg-blue-100 rounded-lg flex items-center justify-center mr-3 sm:mr-4">
          <svg class="w-5 h-5 sm:w-6 sm:h-6 text-blue-600" fill="none" viewBox="0 0 24 24" stroke="currentColor">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9.663 17h4.673M12 3v1m6.364 1.636l-.707.707M21 12h-1M4 12H3m3.343-5.657l-.707-.707m2.828 9.9a5 5 0 117.072 0l-.548.547A3.374 3.374 0 0014 18.469V19a2 2 0 11-4 0v-.531c0-.895-.356-1.754-.988-2.386l-.548-.547z" />
          </svg>
        </div>
        <h3 class="text-xl sm:text-2xl font-bold text-gray-900">Informações do Núcleo</h3>
      </div>
      
      <div class="grid grid-cols-1 md:grid-cols-2 gap-4 sm:gap-6 lg:gap-8">
        <div class="bg-white rounded-lg p-4 sm:p-6 shadow-sm border border-gray-100">
          <label class="block text-sm font-semibold text-gray-800 mb-3 flex items-center">
            <svg class="w-4 h-4 mr-2 text-blue-600" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z" />
            </svg>
            Faz núcleo?
          </label>
          <p class="text-lg font-medium text-gray-900">
            {#if dadosNucleo.faz_nucleo === true}
              <span class="inline-flex items-center px-3 py-1 rounded-full text-sm font-medium bg-green-100 text-green-800">
                <svg class="w-4 h-4 mr-1" fill="currentColor" viewBox="0 0 20 20">
                  <path fill-rule="evenodd" d="M16.707 5.293a1 1 0 010 1.414l-8 8a1 1 0 01-1.414 0l-4-4a1 1 0 011.414-1.414L8 12.586l7.293-7.293a1 1 0 011.414 0z" clip-rule="evenodd" />
                </svg>
                Sim
              </span>
            {:else if dadosNucleo.faz_nucleo === false}
              <span class="inline-flex items-center px-3 py-1 rounded-full text-sm font-medium bg-red-100 text-red-800">
                <svg class="w-4 h-4 mr-1" fill="currentColor" viewBox="0 0 20 20">
                  <path fill-rule="evenodd" d="M4.293 4.293a1 1 0 011.414 0L10 8.586l4.293-4.293a1 1 0 111.414 1.414L11.414 10l4.293 4.293a1 1 0 01-1.414 1.414L10 11.414l-4.293 4.293a1 1 0 01-1.414-1.414L8.586 10 4.293 5.707a1 1 0 010-1.414z" clip-rule="evenodd" />
                </svg>
                Não
              </span>
            {:else}
              <span class="text-gray-500">Não informado</span>
            {/if}
          </p>
        </div>
        
        {#if dadosNucleo.faz_nucleo === false}
          <div class="bg-white rounded-lg p-6 shadow-sm border border-gray-100">
            <label class="block text-sm font-semibold text-gray-800 mb-3 flex items-center">
              <svg class="w-4 h-4 mr-2 text-blue-600" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z" />
              </svg>
              Já fez núcleo?
            </label>
            <p class="text-lg font-medium text-gray-900">
              {#if dadosNucleo.ja_fez_nucleo === true}
                <span class="inline-flex items-center px-3 py-1 rounded-full text-sm font-medium bg-green-100 text-green-800">
                  <svg class="w-4 h-4 mr-1" fill="currentColor" viewBox="0 0 20 20">
                    <path fill-rule="evenodd" d="M16.707 5.293a1 1 0 010 1.414l-8 8a1 1 0 01-1.414 0l-4-4a1 1 0 011.414-1.414L8 12.586l7.293-7.293a1 1 0 011.414 0z" clip-rule="evenodd" />
                  </svg>
                  Sim
                </span>
              {:else if dadosNucleo.ja_fez_nucleo === false}
                <span class="inline-flex items-center px-3 py-1 rounded-full text-sm font-medium bg-red-100 text-red-800">
                  <svg class="w-4 h-4 mr-1" fill="currentColor" viewBox="0 0 20 20">
                    <path fill-rule="evenodd" d="M4.293 4.293a1 1 0 011.414 0L10 8.586l4.293-4.293a1 1 0 111.414 1.414L11.414 10l4.293 4.293a1 1 0 01-1.414 1.414L10 11.414l-4.293 4.293a1 1 0 01-1.414-1.414L8.586 10 4.293 5.707a1 1 0 010-1.414z" clip-rule="evenodd" />
                  </svg>
                  Não
                </span>
              {:else}
                <span class="text-gray-500">Não informado</span>
              {/if}
            </p>
          </div>
        {/if}
      </div>
    </div>

    {#if dadosNucleo.faz_nucleo === true}
      <!-- Dados do Núcleo Atual -->
      <div class="bg-gradient-to-br from-purple-50 via-white to-blue-50 rounded-2xl shadow-xl border border-purple-100 p-4 sm:p-6 lg:p-8 relative overflow-hidden">
        <!-- Decorative background elements -->
        <div class="absolute top-0 right-0 w-32 h-32 bg-gradient-to-br from-purple-200 to-blue-200 rounded-full -translate-y-16 translate-x-16 opacity-20"></div>
        <div class="absolute bottom-0 left-0 w-24 h-24 bg-gradient-to-tr from-blue-200 to-purple-200 rounded-full translate-y-12 -translate-x-12 opacity-20"></div>
        
        <div class="relative z-10">
          <div class="flex items-center mb-4 sm:mb-6">
            <div class="flex items-center justify-center w-10 h-10 sm:w-12 sm:h-12 bg-gradient-to-br from-purple-500 to-blue-500 rounded-xl shadow-lg mr-3 sm:mr-4">
              <svg class="w-6 h-6 sm:w-7 sm:h-7 text-white" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4.318 6.318a4.5 4.5 0 000 6.364L12 20.364l7.682-7.682a4.5 4.5 0 00-6.364-6.364L12 7.636l-1.318-1.318a4.5 4.5 0 00-6.364 0z" />
              </svg>
            </div>
            <div>
              <h3 class="text-xl sm:text-2xl font-bold bg-gradient-to-r from-purple-600 to-blue-600 bg-clip-text text-transparent">
                Dados do Núcleo Atual
              </h3>
              <p class="text-gray-600 text-xs sm:text-sm mt-1">Informações sobre seu núcleo de oração</p>
            </div>
          </div>
          
          <div class="grid grid-cols-1 md:grid-cols-2 gap-4 sm:gap-6 lg:gap-8">
            <!-- Dias da semana -->
            <div class="bg-white/70 backdrop-blur-sm rounded-xl p-4 sm:p-6 border border-white/50 shadow-lg">
              <div class="flex items-center mb-4">
                <div class="w-8 h-8 bg-gradient-to-br from-purple-400 to-purple-500 rounded-lg flex items-center justify-center mr-3">
                  <svg class="w-4 h-4 text-white" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M8 7V3m8 4V3m-9 8h10M5 21h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v12a2 2 0 002 2z" />
                  </svg>
                </div>
                <h4 class="text-lg font-semibold text-gray-800">Dias da semana</h4>
              </div>
              <div class="flex flex-wrap gap-2">
                {#each (dadosNucleo.dias_semana || []).map(dia => dia.toLowerCase()) as dia}
                  <span class="inline-flex items-center px-4 py-2 rounded-full text-sm font-medium bg-gradient-to-r from-purple-100 to-purple-200 text-purple-800 border border-purple-200 shadow-sm hover:shadow-md transition-all duration-200 hover:scale-105">
                    {dia}
                  </span>
                {/each}
              </div>
            </div>
            
            <!-- Há quanto tempo -->
            <div class="bg-white/70 backdrop-blur-sm rounded-xl p-6 border border-white/50 shadow-lg">
              <div class="flex items-center mb-4">
                <div class="w-8 h-8 bg-gradient-to-br from-blue-400 to-blue-500 rounded-lg flex items-center justify-center mr-3">
                  <svg class="w-4 h-4 text-white" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z" />
                  </svg>
                </div>
                <h4 class="text-lg font-semibold text-gray-800">Há quanto tempo</h4>
              </div>
              <p class="text-2xl font-bold bg-gradient-to-r from-blue-600 to-purple-600 bg-clip-text text-transparent">
                {dadosNucleo.ha_quanto_tempo || 'Não informado'}
              </p>
            </div>
            
            <!-- Foi você que iniciou -->
            <div class="bg-white/70 backdrop-blur-sm rounded-xl p-6 border border-white/50 shadow-lg">
              <div class="flex items-center mb-4">
                <div class="w-8 h-8 bg-gradient-to-br from-green-400 to-green-500 rounded-lg flex items-center justify-center mr-3">
                  <svg class="w-4 h-4 text-white" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z" />
                  </svg>
                </div>
                <h4 class="text-lg font-semibold text-gray-800">Foi você que iniciou?</h4>
              </div>
              <div class="flex items-center">
                {#if dadosNucleo.foi_voce_que_iniciou === true}
                  <div class="flex items-center px-4 py-2 bg-gradient-to-r from-green-100 to-green-200 rounded-full border border-green-300">
                    <svg class="w-5 h-5 text-green-600 mr-2" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7" />
                    </svg>
                    <span class="text-green-800 font-semibold">Sim</span>
                  </div>
                {:else if dadosNucleo.foi_voce_que_iniciou === false}
                  <div class="flex items-center px-4 py-2 bg-gradient-to-r from-gray-100 to-gray-200 rounded-full border border-gray-300">
                    <svg class="w-5 h-5 text-gray-600 mr-2" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12" />
                    </svg>
                    <span class="text-gray-800 font-semibold">Não</span>
                  </div>
                {:else}
                  <div class="flex items-center px-4 py-2 bg-gradient-to-r from-gray-100 to-gray-200 rounded-full border border-gray-300">
                    <span class="text-gray-600 font-semibold">Não informado</span>
                  </div>
                {/if}
              </div>
            </div>
            
            <!-- Média de pessoas -->
            <div class="bg-white/70 backdrop-blur-sm rounded-xl p-6 border border-white/50 shadow-lg">
              <div class="flex items-center mb-4">
                <div class="w-8 h-8 bg-gradient-to-br from-orange-400 to-orange-500 rounded-lg flex items-center justify-center mr-3">
                  <svg class="w-4 h-4 text-white" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M17 20h5v-2a3 3 0 00-5.356-1.857M17 20H7m10 0v-2c0-.656-.126-1.283-.356-1.857M7 20H2v-2a3 3 0 015.356-1.857M7 20v-2c0-.656.126-1.283.356-1.857m0 0a5.002 5.002 0 019.288 0M15 7a3 3 0 11-6 0 3 3 0 016 0zm6 3a2 2 0 11-4 0 2 2 0 014 0zM7 10a2 2 0 11-4 0 2 2 0 014 0z" />
                  </svg>
                </div>
                <h4 class="text-lg font-semibold text-gray-800">Média de pessoas</h4>
              </div>
              <div class="flex items-center">
                <span class="text-3xl font-bold bg-gradient-to-r from-orange-600 to-red-600 bg-clip-text text-transparent mr-2">
                  {dadosNucleo.media_pessoas || 'N/A'}
                </span>
                <span class="text-gray-600 text-sm">pessoas</span>
              </div>
            </div>
          </div>
        </div>
      </div>

      <!-- Fotos do Núcleo - Carrossel -->
      {#if photos.length > 0}
        <div class="bg-gradient-to-r from-purple-50 to-pink-50 rounded-xl border border-purple-200 p-4 sm:p-6 lg:p-8 shadow-sm shadow-bottom-xl">
          <div class="flex items-center justify-between mb-4 sm:mb-6">
            <div class="flex items-center">
              <div class="w-8 h-8 sm:w-10 sm:h-10 bg-purple-100 rounded-lg flex items-center justify-center mr-3 sm:mr-4">
                <svg class="w-5 h-5 sm:w-6 sm:h-6 text-purple-600" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 16l4.586-4.586a2 2 0 012.828 0L16 16m-2-2l1.586-1.586a2 2 0 012.828 0L20 14m-6-6h.01M6 20h12a2 2 0 002-2V6a2 2 0 00-2-2H6a2 2 0 00-2 2v12a2 2 0 002 2z" />
                </svg>
              </div>
              <h3 class="text-xl sm:text-2xl font-bold text-gray-900">Fotos do Núcleo</h3>
            </div>
            
            {#if photos.length > 1}
              <div class="flex items-center space-x-2">
                <span class="text-sm text-gray-600">
                  {currentPhotoIndex + 1} de {photos.length}
                </span>
              </div>
            {/if}
          </div>
          
          <!-- Carrossel Principal -->
          <div class="relative">
            <div class="relative overflow-hidden rounded-xl bg-white shadow-lg">
              <!-- Foto Atual com Transição -->
              <div class="relative">
                <div 
                  class="w-full h-64 sm:h-80 overflow-hidden"
                  style="transition: all 0.6s cubic-bezier(0.4, 0, 0.2, 1);"
                >
                  <img 
                    src={photos[currentPhotoIndex]} 
                    alt="Foto {currentPhotoIndex + 1} do núcleo"
                    class="w-full h-64 sm:h-80 object-cover cursor-pointer transition-all duration-500 ease-in-out hover:scale-105 {isTransitioning ? 'opacity-70' : 'opacity-100'}"
                    on:click={() => openPhotoModal(photos[currentPhotoIndex], currentPhotoIndex)}
                    on:keydown={(e) => e.key === 'Enter' && openPhotoModal(photos[currentPhotoIndex], currentPhotoIndex)}
                    role="button"
                    tabindex="0"
                    style="transition: opacity 0.5s ease-in-out, transform 0.3s ease-in-out;"
                  />
                </div>
                
                <!-- Overlay com ícone de zoom -->
                <div class="absolute inset-0 bg-black bg-opacity-0 hover:bg-opacity-20 transition-all duration-300 flex items-center justify-center">
                  <div class="opacity-0 hover:opacity-100 transition-opacity bg-white bg-opacity-90 rounded-full p-4">
                    <svg class="w-8 h-8 text-gray-800" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0zM10 7v3m0 0v3m0-3h3m-3 0H7" />
                    </svg>
                  </div>
                </div>
                
                <!-- Número da foto -->
                <div class="absolute top-4 right-4 bg-white bg-opacity-90 rounded-full px-3 py-1 text-sm font-medium text-gray-700">
                  {currentPhotoIndex + 1}
                </div>
              </div>
              
              <!-- Botões de navegação -->
              {#if photos.length > 1}
                <button
                  on:click={prevPhoto}
                  disabled={isTransitioning}
                  class="absolute left-2 sm:left-4 top-1/2 transform -translate-y-1/2 bg-white bg-opacity-90 hover:bg-opacity-100 text-gray-800 rounded-full p-2 sm:p-3 shadow-lg transition-all duration-300 hover:scale-110 disabled:opacity-50 disabled:cursor-not-allowed disabled:hover:scale-100"
                  title="Foto anterior"
                >
                  <svg class="w-4 h-4 sm:w-6 sm:h-6 transition-transform duration-200 {isTransitioning ? 'animate-pulse' : ''}" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 19l-7-7 7-7" />
                  </svg>
                </button>
                
                <button
                  on:click={nextPhoto}
                  disabled={isTransitioning}
                  class="absolute right-2 sm:right-4 top-1/2 transform -translate-y-1/2 bg-white bg-opacity-90 hover:bg-opacity-100 text-gray-800 rounded-full p-2 sm:p-3 shadow-lg transition-all duration-300 hover:scale-110 disabled:opacity-50 disabled:cursor-not-allowed disabled:hover:scale-100"
                  title="Próxima foto"
                >
                  <svg class="w-4 h-4 sm:w-6 sm:h-6 transition-transform duration-200 {isTransitioning ? 'animate-pulse' : ''}" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5l7 7-7 7" />
                  </svg>
                </button>
              {/if}
            </div>
            
            <!-- Indicadores (bolinhas) -->
            {#if photos.length > 1}
              <div class="flex justify-center mt-4 sm:mt-6 space-x-2 sm:space-x-3">
                {#each photos as _, index}
                  <button
                    on:click={() => goToPhoto(index)}
                    disabled={isTransitioning}
                    class="w-3 h-3 sm:w-4 sm:h-4 rounded-full transition-all duration-500 ease-in-out transform hover:scale-125 disabled:cursor-not-allowed {index === currentPhotoIndex ? 'bg-purple-600 scale-125 shadow-lg' : 'bg-gray-300 hover:bg-gray-400 hover:scale-110'} {isTransitioning ? 'opacity-70' : 'opacity-100'}"
                    title="Ir para foto {index + 1}"
                  >
                    <div class="w-full h-full rounded-full transition-all duration-300 {index === currentPhotoIndex ? 'bg-white bg-opacity-30' : ''}"></div>
                  </button>
                {/each}
              </div>
            {/if}
          </div>
        </div>
      {/if}

      <!-- Vídeo do Núcleo -->
      {#if dadosNucleo.video_link}
        <div class="bg-gradient-to-br from-red-50 via-white to-pink-50 rounded-2xl shadow-xl border border-red-100 p-4 sm:p-6 lg:p-8 relative overflow-hidden">
          <!-- Decorative background elements -->
          <div class="absolute top-0 right-0 w-32 h-32 bg-gradient-to-br from-red-200 to-pink-200 rounded-full -translate-y-16 translate-x-16 opacity-20"></div>
          <div class="absolute bottom-0 left-0 w-24 h-24 bg-gradient-to-tr from-pink-200 to-red-200 rounded-full translate-y-12 -translate-x-12 opacity-20"></div>
          
          <div class="relative z-10">
            <div class="flex items-center mb-6">
              <div class="flex items-center justify-center w-12 h-12 bg-gradient-to-br from-red-500 to-pink-500 rounded-xl shadow-lg mr-4">
                <svg class="w-7 h-7 text-white" fill="currentColor" viewBox="0 0 24 24">
                  <path d="M23.498 6.186a3.016 3.016 0 0 0-2.122-2.136C19.505 3.545 12 3.545 12 3.545s-7.505 0-9.377.505A3.017 3.017 0 0 0 .502 6.186C0 8.07 0 12 0 12s0 3.93.502 5.814a3.016 3.016 0 0 0 2.122 2.136c1.871.505 9.376.505 9.376.505s7.505 0 9.377-.505a3.015 3.015 0 0 0 2.122-2.136C24 15.93 24 12 24 12s0-3.93-.502-5.814zM9.545 15.568V8.432L15.818 12l-6.273 3.568z"/>
                </svg>
              </div>
              <div>
                <h3 class="text-2xl font-bold bg-gradient-to-r from-red-600 to-pink-600 bg-clip-text text-transparent">
                  Vídeo do Núcleo
                </h3>
                <p class="text-gray-600 text-sm mt-1">Vídeo compartilhado do núcleo de oração</p>
              </div>
            </div>
            
            <div class="bg-white/70 backdrop-blur-sm rounded-xl p-6 border border-white/50 shadow-lg">
              {#if dadosNucleo.video_plataforma === 'youtube'}
                {@const embedUrl = getVideoEmbedUrl(dadosNucleo.video_link, dadosNucleo.video_plataforma)}
                {#if embedUrl}
                  <div class="relative w-full h-0 pb-[56.25%] rounded-xl overflow-hidden shadow-lg">
                    <iframe 
                      src={embedUrl}
                      class="absolute top-0 left-0 w-full h-full rounded-xl"
                      frameborder="0"
                      allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture"
                      allowfullscreen
                    ></iframe>
                  </div>
                {:else}
                  <a href={dadosNucleo.video_link} target="_blank" rel="noopener noreferrer" 
                     class="inline-flex items-center px-6 py-3 bg-gradient-to-r from-red-500 to-red-600 text-white rounded-xl hover:from-red-600 hover:to-red-700 transition-all duration-300 shadow-lg hover:shadow-xl transform hover:scale-105">
                    <svg class="w-6 h-6 mr-3" fill="currentColor" viewBox="0 0 24 24">
                      <path d="M23.498 6.186a3.016 3.016 0 0 0-2.122-2.136C19.505 3.545 12 3.545 12 3.545s-7.505 0-9.377.505A3.017 3.017 0 0 0 .502 6.186C0 8.07 0 12 0 12s0 3.93.502 5.814a3.016 3.016 0 0 0 2.122 2.136c1.871.505 9.376.505 9.376.505s7.505 0 9.377-.505a3.015 3.015 0 0 0 2.122-2.136C24 15.93 24 12 24 12s0-3.93-.502-5.814zM9.545 15.568V8.432L15.818 12l-6.273 3.568z"/>
                    </svg>
                    <span class="font-semibold">Ver no YouTube</span>
                  </a>
                {/if}
              {:else}
                <a href={dadosNucleo.video_link} target="_blank" rel="noopener noreferrer" 
                   class="inline-flex items-center px-6 py-3 bg-gradient-to-r from-blue-500 to-blue-600 text-white rounded-xl hover:from-blue-600 hover:to-blue-700 transition-all duration-300 shadow-lg hover:shadow-xl transform hover:scale-105">
                  <svg class="w-6 h-6 mr-3" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M14.828 14.828a4 4 0 01-5.656 0M9 10h1m4 0h1m-6 4h1m4 0h1m-6-8h8a2 2 0 012 2v8a2 2 0 01-2 2H8a2 2 0 01-2-2V8a2 2 0 012-2z" />
                  </svg>
                  <span class="font-semibold">Ver Vídeo</span>
                </a>
              {/if}
            </div>
          </div>
        </div>
      {/if}

      <!-- Obreiros e Ajuda -->
      <div class="bg-gradient-to-br from-green-50 via-white to-emerald-50 rounded-2xl shadow-xl border border-green-100 p-4 sm:p-6 lg:p-8 relative overflow-hidden">
        <!-- Decorative background elements -->
        <div class="absolute top-0 right-0 w-32 h-32 bg-gradient-to-br from-green-200 to-emerald-200 rounded-full -translate-y-16 translate-x-16 opacity-20"></div>
        <div class="absolute bottom-0 left-0 w-24 h-24 bg-gradient-to-tr from-emerald-200 to-green-200 rounded-full translate-y-12 -translate-x-12 opacity-20"></div>
        
        <div class="relative z-10">
          <div class="flex items-center mb-6">
            <div class="flex items-center justify-center w-12 h-12 bg-gradient-to-br from-green-500 to-emerald-500 rounded-xl shadow-lg mr-4">
              <svg class="w-7 h-7 text-white" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M17 20h5v-2a3 3 0 00-5.356-1.857M17 20H7m10 0v-2c0-.656-.126-1.283-.356-1.857M7 20H2v-2a3 3 0 015.356-1.857M7 20v-2c0-.656.126-1.283.356-1.857m0 0a5.002 5.002 0 019.288 0M15 7a3 3 0 11-6 0 3 3 0 016 0zm6 3a2 2 0 11-4 0 2 2 0 014 0zM7 10a2 2 0 11-4 0 2 2 0 014 0z" />
              </svg>
            </div>
            <div>
              <h3 class="text-2xl font-bold bg-gradient-to-r from-green-600 to-emerald-600 bg-clip-text text-transparent">
                Obreiros e Ajuda
              </h3>
              <p class="text-gray-600 text-sm mt-1">Informações sobre obreiros e colaboradores</p>
            </div>
          </div>
          
          <div class="grid grid-cols-1 md:grid-cols-2 gap-8">
            <!-- Tem obreiros -->
            <div class="bg-white/70 backdrop-blur-sm rounded-xl p-6 border border-white/50 shadow-lg">
              <div class="flex items-center mb-4">
                <div class="w-8 h-8 bg-gradient-to-br from-green-400 to-green-500 rounded-lg flex items-center justify-center mr-3">
                  <svg class="w-4 h-4 text-white" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z" />
                  </svg>
                </div>
                <h4 class="text-lg font-semibold text-gray-800">Tem obreiros?</h4>
              </div>
              <div class="flex items-center">
                {#if dadosNucleo.tem_obreiros === true}
                  <div class="flex items-center px-4 py-2 bg-gradient-to-r from-green-100 to-green-200 rounded-full border border-green-300">
                    <svg class="w-5 h-5 text-green-600 mr-2" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7" />
                    </svg>
                    <span class="text-green-800 font-semibold">Sim</span>
                  </div>
                {:else if dadosNucleo.tem_obreiros === false}
                  <div class="flex items-center px-4 py-2 bg-gradient-to-r from-gray-100 to-gray-200 rounded-full border border-gray-300">
                    <svg class="w-5 h-5 text-gray-600 mr-2" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12" />
                    </svg>
                    <span class="text-gray-800 font-semibold">Não</span>
                  </div>
                {:else}
                  <div class="flex items-center px-4 py-2 bg-gradient-to-r from-gray-100 to-gray-200 rounded-full border border-gray-300">
                    <span class="text-gray-600 font-semibold">Não informado</span>
                  </div>
                {/if}
              </div>
            </div>
            
            <!-- Quantos obreiros -->
            {#if dadosNucleo.tem_obreiros === true}
              <div class="bg-white/70 backdrop-blur-sm rounded-xl p-6 border border-white/50 shadow-lg">
                <div class="flex items-center mb-4">
                  <div class="w-8 h-8 bg-gradient-to-br from-emerald-400 to-emerald-500 rounded-lg flex items-center justify-center mr-3">
                    <svg class="w-4 h-4 text-white" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M7 7h.01M7 3h5c.512 0 1.024.195 1.414.586l7 7a2 2 0 010 2.828l-7 7a2 2 0 01-2.828 0l-7-7A1.994 1.994 0 013 12V7a4 4 0 014-4z" />
                    </svg>
                  </div>
                  <h4 class="text-lg font-semibold text-gray-800">Quantos obreiros?</h4>
                </div>
                <div class="flex items-center">
                  <span class="text-3xl font-bold bg-gradient-to-r from-emerald-600 to-green-600 bg-clip-text text-transparent mr-2">
                    {dadosNucleo.quantos_obreiros || 'N/A'}
                  </span>
                  <span class="text-gray-600 text-sm">obreiros</span>
                </div>
              </div>
            {/if}
            
            <!-- Alguém ajuda -->
            <div class="bg-white/70 backdrop-blur-sm rounded-xl p-6 border border-white/50 shadow-lg">
              <div class="flex items-center mb-4">
                <div class="w-8 h-8 bg-gradient-to-br from-blue-400 to-blue-500 rounded-lg flex items-center justify-center mr-3">
                  <svg class="w-4 h-4 text-white" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4.318 6.318a4.5 4.5 0 000 6.364L12 20.364l7.682-7.682a4.5 4.5 0 00-6.364-6.364L12 7.636l-1.318-1.318a4.5 4.5 0 00-6.364 0z" />
                  </svg>
                </div>
                <h4 class="text-lg font-semibold text-gray-800">Alguém ajuda no núcleo?</h4>
              </div>
              <div class="flex items-center">
                {#if dadosNucleo.alguem_ajuda === true}
                  <div class="flex items-center px-4 py-2 bg-gradient-to-r from-blue-100 to-blue-200 rounded-full border border-blue-300">
                    <svg class="w-5 h-5 text-blue-600 mr-2" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7" />
                    </svg>
                    <span class="text-blue-800 font-semibold">Sim</span>
                  </div>
                {:else if dadosNucleo.alguem_ajuda === false}
                  <div class="flex items-center px-4 py-2 bg-gradient-to-r from-gray-100 to-gray-200 rounded-full border border-gray-300">
                    <svg class="w-5 h-5 text-gray-600 mr-2" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12" />
                    </svg>
                    <span class="text-gray-800 font-semibold">Não</span>
                  </div>
                {:else}
                  <div class="flex items-center px-4 py-2 bg-gradient-to-r from-gray-100 to-gray-200 rounded-full border border-gray-300">
                    <span class="text-gray-600 font-semibold">Não informado</span>
                  </div>
                {/if}
              </div>
            </div>
            
            <!-- Quem ajuda -->
            {#if dadosNucleo.alguem_ajuda === true}
              <div class="bg-white/70 backdrop-blur-sm rounded-xl p-6 border border-white/50 shadow-lg">
                <div class="flex items-center mb-4">
                  <div class="w-8 h-8 bg-gradient-to-br from-purple-400 to-purple-500 rounded-lg flex items-center justify-center mr-3">
                    <svg class="w-4 h-4 text-white" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M16 7a4 4 0 11-8 0 4 4 0 018 0zM12 14a7 7 0 00-7 7h14a7 7 0 00-7-7z" />
                    </svg>
                  </div>
                  <h4 class="text-lg font-semibold text-gray-800">Quem ajuda?</h4>
                </div>
                <p class="text-lg font-medium text-gray-800 bg-gradient-to-r from-purple-50 to-blue-50 p-4 rounded-lg border border-purple-200">
                  {dadosNucleo.quem_ajuda || 'Não informado'}
                </p>
              </div>
            {/if}
          </div>
        </div>
      </div>

      <!-- Frequência na Igreja -->
      <div class="bg-gradient-to-br from-indigo-50 via-white to-blue-50 rounded-2xl shadow-xl border border-indigo-100 p-4 sm:p-6 lg:p-8 relative overflow-hidden">
        <!-- Decorative background elements -->
        <div class="absolute top-0 right-0 w-32 h-32 bg-gradient-to-br from-indigo-200 to-blue-200 rounded-full -translate-y-16 translate-x-16 opacity-20"></div>
        <div class="absolute bottom-0 left-0 w-24 h-24 bg-gradient-to-tr from-blue-200 to-indigo-200 rounded-full translate-y-12 -translate-x-12 opacity-20"></div>
        
        <div class="relative z-10">
          <div class="flex items-center mb-6">
            <div class="flex items-center justify-center w-12 h-12 bg-gradient-to-br from-indigo-500 to-blue-500 rounded-xl shadow-lg mr-4">
              <svg class="w-7 h-7 text-white" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 21V5a2 2 0 00-2-2H7a2 2 0 00-2 2v16m14 0h2m-2 0h-5m-9 0H3m2 0h5M9 7h1m-1 4h1m4-4h1m-1 4h1m-5 10v-5a1 1 0 011-1h2a1 1 0 011 1v5m-4 0h4" />
              </svg>
            </div>
            <div>
              <h3 class="text-2xl font-bold bg-gradient-to-r from-indigo-600 to-blue-600 bg-clip-text text-transparent">
                Frequência na Igreja
              </h3>
              <p class="text-gray-600 text-sm mt-1">Participação do núcleo na igreja</p>
            </div>
          </div>
          
          <div class="bg-white/70 backdrop-blur-sm rounded-xl p-6 border border-white/50 shadow-lg">
            <div class="flex items-center mb-4">
              <div class="w-8 h-8 bg-gradient-to-br from-indigo-400 to-indigo-500 rounded-lg flex items-center justify-center mr-3">
                <svg class="w-4 h-4 text-white" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M17 20h5v-2a3 3 0 00-5.356-1.857M17 20H7m10 0v-2c0-.656-.126-1.283-.356-1.857M7 20H2v-2a3 3 0 015.356-1.857M7 20v-2c0-.656.126-1.283.356-1.857m0 0a5.002 5.002 0 019.288 0M15 7a3 3 0 11-6 0 3 3 0 016 0zm6 3a2 2 0 11-4 0 2 2 0 014 0zM7 10a2 2 0 11-4 0 2 2 0 014 0z" />
                </svg>
              </div>
              <h4 class="text-lg font-semibold text-gray-800">Quantas pessoas do núcleo vão à igreja?</h4>
            </div>
            <div class="flex items-center">
              <span class="text-4xl font-bold bg-gradient-to-r from-indigo-600 to-blue-600 bg-clip-text text-transparent mr-3">
                {dadosNucleo.quantas_pessoas_vao_igreja || 'N/A'}
              </span>
              <span class="text-gray-600 text-lg">pessoas</span>
            </div>
          </div>
        </div>
      </div>

      <!-- Experiência e Observações -->
      <div class="bg-gradient-to-br from-amber-50 via-white to-yellow-50 rounded-2xl shadow-xl border border-amber-100 p-4 sm:p-6 lg:p-8 relative overflow-hidden">
        <!-- Decorative background elements -->
        <div class="absolute top-0 right-0 w-32 h-32 bg-gradient-to-br from-amber-200 to-yellow-200 rounded-full -translate-y-16 translate-x-16 opacity-20"></div>
        <div class="absolute bottom-0 left-0 w-24 h-24 bg-gradient-to-tr from-yellow-200 to-amber-200 rounded-full translate-y-12 -translate-x-12 opacity-20"></div>
        
        <div class="relative z-10">
          <div class="flex items-center mb-6">
            <div class="flex items-center justify-center w-12 h-12 bg-gradient-to-br from-amber-500 to-yellow-500 rounded-xl shadow-lg mr-4">
              <svg class="w-7 h-7 text-white" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9.663 17h4.673M12 3v1m6.364 1.636l-.707.707M21 12h-1M4 12H3m3.343-5.657l-.707-.707m2.828 9.9a5 5 0 117.072 0l-.548.547A3.374 3.374 0 0014 18.469V19a2 2 0 11-4 0v-.531c0-.895-.356-1.754-.988-2.386l-.548-.547z" />
              </svg>
            </div>
            <div>
              <h3 class="text-2xl font-bold bg-gradient-to-r from-amber-600 to-yellow-600 bg-clip-text text-transparent">
                Experiência e Observações
              </h3>
              <p class="text-gray-600 text-sm mt-1">Relatos e experiências do núcleo</p>
            </div>
          </div>
          
          <div class="space-y-6">
            {#if dadosNucleo.maior_experiencia}
              <div class="bg-white/70 backdrop-blur-sm rounded-xl p-6 border border-white/50 shadow-lg">
                <div class="flex items-center mb-4">
                  <div class="w-8 h-8 bg-gradient-to-br from-amber-400 to-amber-500 rounded-lg flex items-center justify-center mr-3">
                    <svg class="w-4 h-4 text-white" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 10V3L4 14h7v7l9-11h-7z" />
                    </svg>
                  </div>
                  <h4 class="text-lg font-semibold text-gray-800">Maior experiência no núcleo</h4>
                </div>
                <div class="bg-gradient-to-r from-amber-50 to-yellow-50 p-4 rounded-lg border border-amber-200">
                  <p class="text-gray-800 leading-relaxed whitespace-pre-wrap">{dadosNucleo.maior_experiencia}</p>
                </div>
              </div>
            {/if}
            
            {#if dadosNucleo.observacao_geral}
              <div class="bg-white/70 backdrop-blur-sm rounded-xl p-6 border border-white/50 shadow-lg">
                <div class="flex items-center mb-4">
                  <div class="w-8 h-8 bg-gradient-to-br from-yellow-400 to-yellow-500 rounded-lg flex items-center justify-center mr-3">
                    <svg class="w-4 h-4 text-white" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M11 5H6a2 2 0 00-2 2v11a2 2 0 002 2h11a2 2 0 002-2v-5m-1.414-9.414a2 2 0 112.828 2.828L11.828 15H9v-2.828l8.586-8.586z" />
                    </svg>
                  </div>
                  <h4 class="text-lg font-semibold text-gray-800">Observação geral</h4>
                </div>
                <div class="bg-gradient-to-r from-yellow-50 to-amber-50 p-4 rounded-lg border border-yellow-200">
                  <p class="text-gray-800 leading-relaxed whitespace-pre-wrap">{dadosNucleo.observacao_geral}</p>
                </div>
              </div>
            {/if}
          </div>
        </div>
      </div>
    {/if}
  </div>
{/if}

<style>
  .shadow-bottom-xl {
    box-shadow: 0 20px 25px -5px rgba(0, 0, 0, 0.1), 0 10px 10px -5px rgba(0, 0, 0, 0.04);
  }
</style>

<!-- Modal para Fotos -->
{#if showPhotoModal}
  <div 
    class="fixed inset-0 bg-black bg-opacity-75 z-50 flex items-center justify-center p-4" 
    on:click={closePhotoModal}
    on:keydown={handleKeydown}
    role="dialog"
    aria-modal="true"
    aria-label="Visualizar foto do núcleo"
    tabindex="-1"
  >
    <div 
      class="relative max-w-6xl max-h-full bg-white rounded-2xl shadow-2xl overflow-hidden" 
      on:click|stopPropagation
      role="presentation"
    >
      <!-- Header do Modal -->
      <div class="flex items-center justify-between p-6 border-b border-gray-200 bg-gradient-to-r from-purple-50 to-pink-50">
        <div class="flex items-center">
          <div class="w-8 h-8 bg-purple-100 rounded-lg flex items-center justify-center mr-3">
            <svg class="w-5 h-5 text-purple-600" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 16l4.586-4.586a2 2 0 012.828 0L16 16m-2-2l1.586-1.586a2 2 0 012.828 0L20 14m-6-6h.01M6 20h12a2 2 0 002-2V6a2 2 0 00-2-2H6a2 2 0 00-2 2v12a2 2 0 002 2z" />
            </svg>
          </div>
          <h3 class="text-xl font-bold text-gray-900">Foto {selectedPhotoIndex + 1} do Núcleo</h3>
        </div>
        
        <button
          on:click={closePhotoModal}
          class="flex items-center justify-center w-10 h-10 bg-white hover:bg-gray-50 text-gray-600 hover:text-gray-800 rounded-full shadow-lg transition-colors"
          title="Fechar visualização"
        >
          <svg class="w-6 h-6" fill="none" viewBox="0 0 24 24" stroke="currentColor">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12" />
          </svg>
        </button>
      </div>
      
      <!-- Imagem em tamanho grande -->
      <div class="p-6">
        <img 
          src={selectedPhoto} 
          alt="Foto {selectedPhotoIndex + 1} do núcleo"
          class="max-w-full max-h-[70vh] object-contain rounded-lg shadow-lg mx-auto"
        />
      </div>
      
      <!-- Footer do Modal -->
      <div class="flex items-center justify-between p-6 border-t border-gray-200 bg-gray-50">
        <div class="flex items-center text-sm text-gray-600">
          <svg class="w-4 h-4 mr-2" fill="none" viewBox="0 0 24 24" stroke="currentColor">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 12a3 3 0 11-6 0 3 3 0 016 0z" />
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M2.458 12C3.732 7.943 7.523 5 12 5c4.478 0 8.268 2.943 9.542 7-1.274 4.057-5.064 7-9.542 7-4.477 0-8.268-2.943-9.542-7z" />
          </svg>
          Clique fora da imagem ou pressione ESC para fechar
        </div>
        
        <button
          on:click={() => window.open(selectedPhoto, '_blank')}
          class="inline-flex items-center px-4 py-2 bg-purple-600 text-white rounded-lg hover:bg-purple-700 transition-colors"
        >
          <svg class="w-4 h-4 mr-2" fill="none" viewBox="0 0 24 24" stroke="currentColor">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M10 6H6a2 2 0 00-2 2v10a2 2 0 002 2h10a2 2 0 002-2v-4M14 4h6m0 0v6m0-6L10 14" />
          </svg>
          Abrir em nova aba
        </button>
      </div>
    </div>
  </div>
{/if}
