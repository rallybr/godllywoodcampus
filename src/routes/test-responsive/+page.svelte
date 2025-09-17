<script>
  import { onMount } from 'svelte';
  
  let screenSize = '';
  let isMobile = false;
  let isTablet = false;
  let isDesktop = false;
  
  onMount(() => {
    const updateScreenSize = () => {
      const width = window.innerWidth;
      screenSize = `${width}px`;
      
      isMobile = width < 768;
      isTablet = width >= 768 && width < 1024;
      isDesktop = width >= 1024;
    };
    
    updateScreenSize();
    window.addEventListener('resize', updateScreenSize);
    
    return () => {
      window.removeEventListener('resize', updateScreenSize);
    };
  });
</script>

<svelte:head>
  <title>Teste de Responsividade - IntelliMen Campus</title>
</svelte:head>

<div class="min-h-screen bg-gray-100 p-4">
  <div class="max-w-4xl mx-auto">
    <h1 class="text-3xl font-bold text-gray-900 mb-8">Teste de Responsividade</h1>
    
    <!-- Informações da tela -->
    <div class="bg-white rounded-lg shadow p-6 mb-8">
      <h2 class="text-xl font-semibold mb-4">Informações da Tela</h2>
      <div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
        <div class="text-center p-4 bg-blue-100 rounded-lg">
          <div class="text-2xl font-bold text-blue-600">{screenSize}</div>
          <div class="text-sm text-blue-800">Largura Atual</div>
        </div>
        <div class="text-center p-4 bg-green-100 rounded-lg">
          <div class="text-2xl font-bold text-green-600">{isMobile ? '✓' : '✗'}</div>
          <div class="text-sm text-green-800">Mobile (&lt; 768px)</div>
        </div>
        <div class="text-center p-4 bg-yellow-100 rounded-lg">
          <div class="text-2xl font-bold text-yellow-600">{isTablet ? '✓' : '✗'}</div>
          <div class="text-sm text-yellow-800">Tablet (768px - 1023px)</div>
        </div>
        <div class="text-center p-4 bg-purple-100 rounded-lg">
          <div class="text-2xl font-bold text-purple-600">{isDesktop ? '✓' : '✗'}</div>
          <div class="text-sm text-purple-800">Desktop (≥ 1024px)</div>
        </div>
      </div>
    </div>
    
    <!-- Teste de Grids -->
    <div class="bg-white rounded-lg shadow p-6 mb-8">
      <h2 class="text-xl font-semibold mb-4">Teste de Grids Responsivos</h2>
      
      <!-- Grid 1: Stats Cards -->
      <div class="mb-6">
        <h3 class="text-lg font-medium mb-3">Stats Cards (grid-cols-1 xs:grid-cols-2 lg:grid-cols-4)</h3>
        <div class="grid grid-cols-1 xs:grid-cols-2 lg:grid-cols-4 gap-4">
          {#each Array(4) as _, i}
            <div class="bg-blue-100 p-4 rounded-lg text-center">
              <div class="text-2xl font-bold text-blue-600">{i + 1}</div>
              <div class="text-sm text-blue-800">Card {i + 1}</div>
            </div>
          {/each}
        </div>
      </div>
      
      <!-- Grid 2: Formulário -->
      <div class="mb-6">
        <h3 class="text-lg font-medium mb-3">Formulário (grid-cols-1 sm:grid-cols-2)</h3>
        <div class="grid grid-cols-1 sm:grid-cols-2 gap-4">
          {#each Array(4) as _, i}
            <div class="bg-green-100 p-4 rounded-lg">
              <label class="block text-sm font-medium text-green-800 mb-2">Campo {i + 1}</label>
              <input type="text" class="w-full p-2 border border-green-300 rounded" placeholder="Digite algo...">
            </div>
          {/each}
        </div>
      </div>
      
      <!-- Grid 3: Cards de Produto -->
      <div class="mb-6">
        <h3 class="text-lg font-medium mb-3">Cards de Produto (grid-cols-1 sm:grid-cols-2 lg:grid-cols-3)</h3>
        <div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-4">
          {#each Array(6) as _, i}
            <div class="bg-purple-100 p-4 rounded-lg">
              <div class="w-full h-32 bg-purple-200 rounded mb-3"></div>
              <div class="text-lg font-semibold text-purple-800">Produto {i + 1}</div>
              <div class="text-sm text-purple-600">Descrição do produto</div>
            </div>
          {/each}
        </div>
      </div>
    </div>
    
    <!-- Teste de Breakpoints -->
    <div class="bg-white rounded-lg shadow p-6">
      <h2 class="text-xl font-semibold mb-4">Teste de Breakpoints</h2>
      
      <div class="space-y-4">
        <div class="p-4 bg-red-100 rounded-lg">
          <div class="text-sm font-medium text-red-800">xs (475px+):</div>
          <div class="text-red-600">Este texto aparece apenas em telas xs e maiores</div>
        </div>
        
        <div class="p-4 bg-orange-100 rounded-lg sm:block hidden">
          <div class="text-sm font-medium text-orange-800">sm (640px+):</div>
          <div class="text-orange-600">Este texto aparece apenas em telas sm e maiores</div>
        </div>
        
        <div class="p-4 bg-yellow-100 rounded-lg md:block hidden">
          <div class="text-sm font-medium text-yellow-800">md (768px+):</div>
          <div class="text-yellow-600">Este texto aparece apenas em telas md e maiores</div>
        </div>
        
        <div class="p-4 bg-green-100 rounded-lg lg:block hidden">
          <div class="text-sm font-medium text-green-800">lg (1024px+):</div>
          <div class="text-green-600">Este texto aparece apenas em telas lg e maiores</div>
        </div>
        
        <div class="p-4 bg-blue-100 rounded-lg xl:block hidden">
          <div class="text-sm font-medium text-blue-800">xl (1280px+):</div>
          <div class="text-blue-600">Este texto aparece apenas em telas xl e maiores</div>
        </div>
      </div>
    </div>
  </div>
</div>
