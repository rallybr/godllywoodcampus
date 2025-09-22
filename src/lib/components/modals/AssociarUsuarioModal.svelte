<script>
  import { createEventDispatcher } from 'svelte';
  import { supabase } from '$lib/utils/supabase';
  import { fade } from 'svelte/transition';
  
  export let isOpen = false;
  export let jovemId = '';
  
  const dispatch = createEventDispatcher();
  
  let search = '';
  let resultados = [];
  let loading = false;
  let selecionado = null;
  let error = '';
  
  const niveisPermitidos = ['lider_estadual_fju', 'lider_bloco_fju', 'colaborador'];
  
  async function buscarUsuarios() {
    error = '';
    resultados = [];
    selecionado = null;
    if (!search || search.trim().length < 2) return;
    loading = true;
    try {
      const { data, error: err } = await supabase
        .from('usuarios')
        .select('id, nome, foto, nivel, estado_id, bloco_id, regiao_id, igreja_id')
        .ilike('nome', `%${search}%`)
        .in('nivel', niveisPermitidos)
        .limit(20);
      if (err) throw err;
      resultados = data || [];
    } catch (e) {
      error = e.message || 'Falha ao buscar usuários';
    } finally {
      loading = false;
    }
  }
  
  async function associar() {
    if (!selecionado || !selecionado.id || !jovemId) return;
    loading = true;
    error = '';
    try {
      const { error: err } = await supabase
        .from('jovens')
        .update({ usuario_id: selecionado.id })
        .eq('id', jovemId);
      if (err) throw err;
      dispatch('success', { usuarioId: selecionado.id });
      fechar();
    } catch (e) {
      error = e.message || 'Falha ao associar jovem';
    } finally {
      loading = false;
    }
  }
  
  function fechar() {
    isOpen = false;
    dispatch('close');
    search = '';
    resultados = [];
    selecionado = null;
    error = '';
  }
</script>

{#if isOpen}
  <div class="fixed inset-0 z-50 flex items-center justify-center" transition:fade>
    <button class="absolute inset-0 bg-black bg-opacity-40" on:click={fechar} aria-label="Fechar sobreposição"></button>
    <div class="relative bg-white rounded-lg shadow-xl w-full max-w-lg mx-4 p-4">
      <div class="flex items-center justify-between mb-3">
        <h3 class="text-lg font-semibold">Associar usuário ao jovem</h3>
        <button class="text-gray-500 hover:text-gray-700" on:click={fechar} aria-label="Fechar">✕</button>
      </div>
      <div class="space-y-3">
        <input
          class="w-full border rounded px-3 py-2"
          placeholder="Buscar por nome (mín. 2 letras)"
          bind:value={search}
          on:input={buscarUsuarios}
        />
        {#if error}
          <div class="text-sm text-red-600">{error}</div>
        {/if}
        {#if loading}
          <div class="text-sm text-gray-600">Carregando...</div>
        {:else}
          <div class="max-h-64 overflow-auto divide-y border rounded">
            {#each resultados as u}
              <label class="flex items-center gap-3 p-2 cursor-pointer hover:bg-gray-50">
                <input type="radio" name="usuario" value={u.id} on:change={() => selecionado = u} />
                {#if u.foto}
                  <img src={u.foto} alt={u.nome} class="w-8 h-8 rounded-full object-cover" />
                {:else}
                  <div class="w-8 h-8 rounded-full bg-gray-200 flex items-center justify-center text-gray-600">{u.nome?.charAt(0) || 'U'}</div>
                {/if}
                <div class="flex-1">
                  <div class="font-medium">{u.nome}</div>
                  <div class="text-xs text-gray-500">{u.nivel}</div>
                </div>
              </label>
            {/each}
            {#if resultados.length === 0 && search.trim().length >= 2}
              <div class="p-3 text-sm text-gray-500">Nenhum usuário encontrado.</div>
            {/if}
          </div>
        {/if}
        <div class="flex justify-end gap-2 pt-2">
          <button class="px-4 py-2 border rounded" on:click={fechar} disabled={loading}>Cancelar</button>
          <button class="px-4 py-2 bg-blue-600 text-white rounded disabled:opacity-50" on:click={associar} disabled={!selecionado || loading}>Associar</button>
        </div>
      </div>
    </div>
  </div>
{/if}

<style>
</style>
