<script>
  import { goto } from '$app/navigation';
  import Card from '$lib/components/ui/Card.svelte';
  import Button from '$lib/components/ui/Button.svelte';
</script>

<svelte:head>
  <title>Administração - Campus</title>
</svelte:head>

<div class="max-w-4xl mx-auto p-6">
  <div class="mb-8">
    <h1 class="text-3xl font-bold text-gray-900 mb-2">Administração</h1>
    <p class="text-gray-600">Gerencie regiões e igrejas do sistema</p>
  </div>

  <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
    <!-- Card para Regiões -->
    <Card>
      <div class="p-6">
        <div class="flex items-center mb-4">
          <div class="flex-shrink-0">
            <svg class="h-8 w-8 text-blue-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M17.657 16.657L13.414 20.9a1.998 1.998 0 01-2.827 0l-4.244-4.243a8 8 0 1111.314 0z"></path>
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 11a3 3 0 11-6 0 3 3 0 016 0z"></path>
            </svg>
          </div>
          <div class="ml-4">
            <h2 class="text-xl font-semibold text-gray-900">Regiões</h2>
            <p class="text-gray-600">Cadastrar novas regiões</p>
          </div>
        </div>
        
        <p class="text-gray-700 mb-6">
          Cadastre novas regiões organizando-as por estado e bloco. 
          Selecione o estado, depois o bloco e informe o nome da região.
        </p>
        
        <Button
          variant="primary"
          on:click={() => goto('/regioes/cadastrar')}
          class="w-full"
        >
          Cadastrar Região
        </Button>
      </div>
    </Card>

    <!-- Card para Igrejas -->
    <Card>
      <div class="p-6">
        <div class="flex items-center mb-4">
          <div class="flex-shrink-0">
            <svg class="h-8 w-8 text-green-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 21V5a2 2 0 00-2-2H7a2 2 0 00-2 2v16m14 0h2m-2 0h-5m-9 0H3m2 0h5M9 7h1m-1 4h1m4-4h1m-1 4h1m-5 10v-5a1 1 0 011-1h2a1 1 0 011 1v5m-4 0h4"></path>
            </svg>
          </div>
          <div class="ml-4">
            <h2 class="text-xl font-semibold text-gray-900">Igrejas</h2>
            <p class="text-gray-600">Cadastrar novas igrejas</p>
          </div>
        </div>
        
        <p class="text-gray-700 mb-6">
          Cadastre novas igrejas organizando-as por estado, bloco e região. 
          Selecione a localização hierárquica e informe o nome e endereço da igreja.
        </p>
        
        <Button
          variant="primary"
          on:click={() => goto('/igrejas/cadastrar')}
          class="w-full"
        >
          Cadastrar Igreja
        </Button>
      </div>
    </Card>
  </div>

  <!-- Informações sobre o fluxo -->
  <Card class="mt-8">
    <div class="p-6">
      <h3 class="text-lg font-semibold text-gray-900 mb-4">Como funciona o sistema hierárquico</h3>
      
      <div class="grid grid-cols-1 md:grid-cols-4 gap-4">
        <div class="text-center">
          <div class="bg-blue-100 rounded-full w-12 h-12 flex items-center justify-center mx-auto mb-2">
            <span class="text-blue-600 font-bold">1</span>
          </div>
          <h4 class="font-medium text-gray-900">Estados</h4>
          <p class="text-sm text-gray-600">Unidades federativas</p>
        </div>
        
        <div class="text-center">
          <div class="bg-blue-100 rounded-full w-12 h-12 flex items-center justify-center mx-auto mb-2">
            <span class="text-blue-600 font-bold">2</span>
          </div>
          <h4 class="font-medium text-gray-900">Blocos</h4>
          <p class="text-sm text-gray-600">Agrupamentos por estado</p>
        </div>
        
        <div class="text-center">
          <div class="bg-blue-100 rounded-full w-12 h-12 flex items-center justify-center mx-auto mb-2">
            <span class="text-blue-600 font-bold">3</span>
          </div>
          <h4 class="font-medium text-gray-900">Regiões</h4>
          <p class="text-sm text-gray-600">Divisões por bloco</p>
        </div>
        
        <div class="text-center">
          <div class="bg-blue-100 rounded-full w-12 h-12 flex items-center justify-center mx-auto mb-2">
            <span class="text-blue-600 font-bold">4</span>
          </div>
          <h4 class="font-medium text-gray-900">Igrejas</h4>
          <p class="text-sm text-gray-600">Localizadas por região</p>
        </div>
      </div>
      
      <div class="mt-6 p-4 bg-gray-50 rounded-lg">
        <p class="text-sm text-gray-700">
          <strong>Fluxo de cadastro:</strong> Para cadastrar uma região, selecione o estado e o bloco. 
          Para cadastrar uma igreja, selecione o estado, bloco, região e informe os dados da igreja.
        </p>
      </div>
    </div>
  </Card>
</div>
