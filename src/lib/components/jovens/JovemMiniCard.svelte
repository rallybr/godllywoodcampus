<script>
  import { createEventDispatcher } from 'svelte';
  import { supabase } from '$lib/utils/supabase';
  import { createLogHistorico } from '$lib/stores/logs-historico';
  import { userProfile } from '$lib/stores/auth';
  export let jovem;

  const dispatch = createEventDispatcher();

  function getFirstTwoNames(fullName) {
    if (!fullName || typeof fullName !== 'string') return '';
    const parts = fullName.trim().split(/\s+/);
    if (parts.length === 0) return '';

    const preps = new Set(['de', 'da', 'do', 'das', 'dos', 'e', "d'", 'd’', 'del']);

    const first = parts[0];
    let result = first;

    // Walk forward after the first token, keep prepositions but pick the next non-preposition as second name
    let i = 1;
    let secondPicked = false;
    while (i < parts.length && !secondPicked) {
      const token = parts[i];
      const normalized = token.toLowerCase();
      if (preps.has(normalized)) {
        result += ` ${token}`; // keep prepositions
      } else {
        result += ` ${token}`; // second name
        secondPicked = true;
      }
      i += 1;
    }

    return result;
  }

  async function handleDelete(event) {
    event?.preventDefault?.();
    event?.stopPropagation?.();

    if (!$userProfile || $userProfile?.nivel !== 'administrador') return;
    const confirmed = confirm('Tem certeza que deseja excluir este jovem? Esta ação não pode ser desfeita.');
    if (!confirmed) return;

    // pegar dados anteriores para log (opcional)
    const dadosAnteriores = { id: jovem.id, nome_completo: jovem.nome_completo };

    const { error } = await supabase.from('jovens').delete().eq('id', jovem.id);
    if (error) {
      alert('Erro ao excluir: ' + (error.message || 'tente novamente.'));
      return;
    }

    // registrar log
    try {
      await createLogHistorico(jovem.id, 'exclusao', 'Exclusão de jovem via lista de cards', dadosAnteriores, null);
    } catch (e) {
      console.error('Falha ao registrar log de exclusão:', e);
    }
    dispatch('deleted', { id: jovem.id });
  }
</script>

<a href={`/jovens/${jovem.id}`} class="block focus:outline-none focus:ring-2 focus:ring-blue-500 rounded-xl">
<div class="bg-white border border-gray-200 rounded-xl p-3 shadow-sm hover:shadow-md transition-all cursor-pointer relative">
  {#if $userProfile?.nivel === 'administrador'}
    <button
      type="button"
      title="Excluir jovem"
      aria-label="Excluir jovem"
      class="absolute top-2 right-2 p-1.5 rounded-md bg-red-50 text-red-600 border border-red-200 hover:bg-red-100"
      on:click|stopPropagation|preventDefault={handleDelete}
    >
      <svg class="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6M9 7h6m-7 0a2 2 0 002-2h2a2 2 0 002 2m-8 0h10" />
      </svg>
    </button>
  {/if}
  <!-- Linha 1: Foto -->
  <div class="w-full">
    <div class="w-full aspect-[4/3] rounded-lg overflow-hidden bg-gray-100">
      {#if jovem.foto}
        <img src={jovem.foto} alt={jovem.nome_completo} class="w-full h-full object-cover" />
      {:else}
        <div class="w-full h-full flex items-center justify-center bg-gradient-to-br from-blue-500 to-purple-600">
          <span class="text-white font-semibold text-lg">{jovem.nome_completo?.charAt(0) || 'J'}</span>
        </div>
      {/if}
    </div>
  </div>

  <!-- Linha 2: Nome (primeiro e segundo) -->
  <div class="mt-2">
    <p class="font-semibold text-gray-900 truncate text-sm text-center">{getFirstTwoNames(jovem.nome_completo)}</p>
  </div>

  <!-- Linha 3: Bandeira do estado -->
  <div class="mt-2 flex items-center justify-center">
    {#if jovem.estado?.bandeira}
      <img src={jovem.estado.bandeira} alt={jovem.estado?.sigla || 'UF'} class="w-12 h-8 rounded-sm border border-gray-200" />
    {:else if jovem.estado?.sigla}
      <span class="text-[10px] leading-4 font-medium px-1.5 py-0.5 rounded bg-gray-100 text-gray-700 border border-gray-200">{jovem.estado.sigla}</span>
    {/if}
  </div>
</div>
</a>


