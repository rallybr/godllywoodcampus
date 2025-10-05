<script>
  import { onMount } from 'svelte';
  
  let deferredPrompt = null;
  let showInstallPrompt = false;
  let isInstalled = false;
  
  onMount(() => {
    // Detectar se o PWA pode ser instalado
    window.addEventListener('beforeinstallprompt', (e) => {
      e.preventDefault();
      deferredPrompt = e;
      showInstallPrompt = true;
    });
    
    // Detectar se já está instalado
    window.addEventListener('appinstalled', () => {
      isInstalled = true;
      showInstallPrompt = false;
      deferredPrompt = null;
    });
    
    // Verificar se já está rodando como PWA
    if (window.matchMedia('(display-mode: standalone)').matches || 
        window.navigator.standalone === true) {
      isInstalled = true;
      showInstallPrompt = false;
    }
  });
  
  async function installPWA() {
    if (!deferredPrompt) return;
    
    try {
      // Mostrar prompt de instalação
      deferredPrompt.prompt();
      
      // Aguardar resposta do usuário
      const { outcome } = await deferredPrompt.userChoice;
      
      if (outcome === 'accepted') {
        console.log('✅ PWA instalado pelo usuário');
        showInstallPrompt = false;
      } else {
        console.log('❌ PWA não instalado pelo usuário');
      }
      
      deferredPrompt = null;
    } catch (error) {
      console.error('Erro ao instalar PWA:', error);
    }
  }
  
  function dismissPrompt() {
    showInstallPrompt = false;
    deferredPrompt = null;
  }
</script>

{#if showInstallPrompt && !isInstalled}
  <div class="fixed bottom-4 left-4 right-4 z-50 max-w-sm mx-auto">
    <div class="bg-white rounded-lg shadow-lg border border-gray-200 p-4 animate-slide-up">
      <div class="flex items-start space-x-3">
        <!-- Ícone -->
        <div class="flex-shrink-0">
          <div class="w-10 h-10 bg-gradient-to-r from-blue-500 to-blue-600 rounded-lg flex items-center justify-center">
            <svg class="w-6 h-6 text-white" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 18h.01M8 21h8a2 2 0 002-2V5a2 2 0 00-2-2H8a2 2 0 00-2 2v14a2 2 0 002 2z" />
            </svg>
          </div>
        </div>
        
        <!-- Conteúdo -->
        <div class="flex-1 min-w-0">
          <h3 class="text-sm font-semibold text-gray-900">
            Instalar App
          </h3>
          <p class="text-xs text-gray-600 mt-1">
            Instale o IntelliMen Campus para acesso rápido e melhor experiência.
          </p>
        </div>
        
        <!-- Botão fechar -->
        <button
          on:click={dismissPrompt}
          class="flex-shrink-0 text-gray-400 hover:text-gray-600 transition-colors"
        >
          <svg class="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12" />
          </svg>
        </button>
      </div>
      
      <!-- Botões de ação -->
      <div class="mt-3 flex space-x-2">
        <button
          on:click={installPWA}
          class="flex-1 bg-blue-600 text-white text-xs font-medium py-2 px-3 rounded-md hover:bg-blue-700 transition-colors focus:outline-none focus:ring-2 focus:ring-blue-500 focus:ring-offset-2"
        >
          Instalar
        </button>
        <button
          on:click={dismissPrompt}
          class="flex-1 bg-gray-100 text-gray-700 text-xs font-medium py-2 px-3 rounded-md hover:bg-gray-200 transition-colors focus:outline-none focus:ring-2 focus:ring-gray-500 focus:ring-offset-2"
        >
          Agora não
        </button>
      </div>
    </div>
  </div>
{/if}

<style>
  @keyframes slide-up {
    from {
      transform: translateY(100%);
      opacity: 0;
    }
    to {
      transform: translateY(0);
      opacity: 1;
    }
  }
  
  .animate-slide-up {
    animation: slide-up 0.3s ease-out;
  }
</style>
