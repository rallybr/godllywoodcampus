<script>
  import { onMount } from 'svelte';
  import { supabase } from '$lib/utils/supabase';
  
  let estados = [];
  let blocos = [];
  let loading = false;
  let error = '';
  
  onMount(async () => {
    await testConnection();
  });
  
  async function testConnection() {
    loading = true;
    error = '';
    
    try {
      // Testar conexão com estados
      const { data: estadosData, error: estadosError } = await supabase
        .from('estados')
        .select('*')
        .order('nome');
      
      if (estadosError) throw estadosError;
      estados = estadosData || [];
      
      // Testar conexão com blocos
      const { data: blocosData, error: blocosError } = await supabase
        .from('blocos')
        .select('*')
        .order('nome');
      
      if (blocosError) throw blocosError;
      blocos = blocosData || [];
      
    } catch (err) {
      error = err.message;
      console.error('Erro na conexão:', err);
    } finally {
      loading = false;
    }
  }
  
  async function testLoadBlocos(estadoId) {
    if (!estadoId) return;
    
    loading = true;
    try {
      const { data, error } = await supabase
        .from('blocos')
        .select('*')
        .eq('estado_id', estadoId)
        .order('nome');
      
      if (error) throw error;
      blocos = data || [];
      console.log('Blocos carregados:', data);
    } catch (err) {
      error = err.message;
      console.error('Erro ao carregar blocos:', err);
    } finally {
      loading = false;
    }
  }
</script>

<div class="max-w-4xl mx-auto p-6">
  <h1 class="text-2xl font-bold mb-6">Teste de Conexão Supabase</h1>
  
  {#if loading}
    <div class="text-center py-8">
      <div class="animate-spin rounded-full h-8 w-8 border-b-2 border-blue-600 mx-auto"></div>
      <p class="mt-2">Carregando...</p>
    </div>
  {/if}
  
  {#if error}
    <div class="bg-red-50 border border-red-200 rounded-lg p-4 mb-6">
      <p class="text-red-600 font-medium">Erro: {error}</p>
    </div>
  {/if}
  
  <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
    <!-- Estados -->
    <div class="bg-white rounded-lg shadow p-6">
      <h2 class="text-lg font-semibold mb-4">Estados ({estados.length})</h2>
      <div class="space-y-2">
        {#each estados as estado}
          <div class="flex items-center justify-between p-2 bg-gray-50 rounded">
            <span>{estado.nome}</span>
            <button 
              class="px-3 py-1 bg-blue-600 text-white rounded text-sm"
              on:click={() => testLoadBlocos(estado.id)}
            >
              Carregar Blocos
            </button>
          </div>
        {/each}
      </div>
    </div>
    
    <!-- Blocos -->
    <div class="bg-white rounded-lg shadow p-6">
      <h2 class="text-lg font-semibold mb-4">Blocos ({blocos.length})</h2>
      <div class="space-y-2">
        {#each blocos as bloco}
          <div class="p-2 bg-gray-50 rounded">
            <span>{bloco.nome}</span>
            <span class="text-sm text-gray-500 ml-2">(Estado ID: {bloco.estado_id})</span>
          </div>
        {/each}
      </div>
    </div>
  </div>
</div>
