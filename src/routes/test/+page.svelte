<script>
  import { goto } from '$app/navigation';
</script>

<svelte:head>
  <title>Teste - IntelliMen Campus</title>
</svelte:head>

<div class="min-h-screen bg-gray-100 flex items-center justify-center">
  <div class="bg-white p-8 rounded-lg shadow-md">
    <h1 class="text-2xl font-bold text-gray-900 mb-4">Página de Teste</h1>
    <p class="text-gray-600 mb-4">Esta é uma página de teste para verificar se as rotas estão funcionando.</p>
    
    <div class="space-y-2">
      <a href="/jovens/cadastrar" class="block text-blue-600 hover:text-blue-800">
        → Ir para Cadastro de Jovens
      </a>
      <a href="/jovens" class="block text-blue-600 hover:text-blue-800">
        → Ir para Lista de Jovens
      </a>
      <a href="/" class="block text-blue-600 hover:text-blue-800">
        → Ir para Dashboard
      </a>
    </div>
  </div>
</div>
