<script>
  import { goto } from '$app/navigation';
  import Button from '$lib/components/ui/Button.svelte';
</script>

<svelte:head>
  <title>Cadastrar Jovem - IntelliMen Campus</title>
</svelte:head>

<div class="min-h-screen bg-gray-100 flex items-center justify-center p-4">
  <div class="bg-white rounded-lg shadow-md p-8 w-full max-w-md">
    <div class="text-center mb-6">
      <h1 class="text-2xl font-bold text-gray-900">Cadastrar Jovem</h1>
      <p class="text-gray-600">Formulário de cadastro simplificado</p>
    </div>
    
    <form class="space-y-4">
      <div>
        <label class="block text-sm font-medium text-gray-700 mb-1">Nome Completo</label>
        <input
          type="text"
          placeholder="Digite o nome completo"
          class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
        />
      </div>
      
      <div>
        <label class="block text-sm font-medium text-gray-700 mb-1">E-mail</label>
        <input
          type="email"
          placeholder="seu@email.com"
          class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
        />
      </div>
      
      <div>
        <label class="block text-sm font-medium text-gray-700 mb-1">WhatsApp</label>
        <input
          type="tel"
          placeholder="(11) 99999-9999"
          class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
        />
      </div>
      
      <div class="flex space-x-3 pt-4">
        <Button
          type="button"
          variant="outline"
          class="flex-1"
          on:click={() => goto('/jovens')}
        >
          Cancelar
        </Button>
        
        <Button
          type="submit"
          variant="primary"
          class="flex-1"
        >
          Cadastrar
        </Button>
      </div>
    </form>
    
    <div class="mt-6 text-center">
      <a href="/jovens" class="text-blue-600 hover:text-blue-800 text-sm">
        ← Voltar para lista de jovens
      </a>
    </div>
  </div>
</div>
