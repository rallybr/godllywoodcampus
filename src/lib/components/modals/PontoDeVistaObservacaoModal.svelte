<script>
  import { createEventDispatcher } from 'svelte';
  import Button from '$lib/components/ui/Button.svelte';

  export let isOpen = false;
  export let titulo = 'Ponto de Vista';
  export let statusLabel = '';
  export let observacaoInicial = '';
  export let loading = false;

  const MAX = 144;
  const dispatch = createEventDispatcher();

  let observacao = '';
  let error = '';

  $: if (isOpen) {
    observacao = (observacaoInicial || '').slice(0, MAX);
    error = '';
  }

  $: restante = MAX - (observacao?.length || 0);

  function fechar() {
    if (loading) return;
    dispatch('close');
  }

  function confirmar() {
    const texto = (observacao || '').trim();
    if (texto.length > MAX) {
      error = `Observação deve ter no máximo ${MAX} caracteres`;
      return;
    }
    error = '';
    dispatch('confirm', { observacao: texto });
  }

  function onKeydown(event) {
    if (event.key === 'Escape') fechar();
  }
</script>

{#if isOpen}
  <div
    class="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/50"
    role="dialog"
    aria-modal="true"
    aria-labelledby="ponto-vista-modal-title"
    tabindex="-1"
    on:keydown={onKeydown}
  >
    <button
      type="button"
      class="absolute inset-0 cursor-default"
      aria-label="Fechar"
      on:click={fechar}
    ></button>

    <div class="relative w-full max-w-md bg-white rounded-xl shadow-xl border border-gray-200 overflow-hidden">
      <div class="px-5 py-4 border-b border-gray-100 bg-gradient-to-r from-rose-50 to-purple-50">
        <h3 id="ponto-vista-modal-title" class="text-lg font-semibold text-gray-900">{titulo}</h3>
        {#if statusLabel}
          <p class="text-sm text-gray-600 mt-1">Status: <span class="font-medium">{statusLabel}</span></p>
        {/if}
      </div>

      <div class="px-5 py-4 space-y-3">
        <label for="observacao-ponto-vista" class="block text-sm font-medium text-gray-700">
          Observação
        </label>
        <textarea
          id="observacao-ponto-vista"
          bind:value={observacao}
          maxlength={MAX}
          rows="4"
          disabled={loading}
          placeholder="Escreva uma observação (opcional, até 144 caracteres)"
          class="w-full rounded-lg border border-gray-300 px-3 py-2 text-sm text-gray-900 focus:outline-none focus:ring-2 focus:ring-rose-400 focus:border-rose-400 disabled:bg-gray-50"
        ></textarea>
        <div class="flex items-center justify-between text-xs">
          <span class="{restante <= 20 ? 'text-amber-600' : 'text-gray-500'}">{restante} caracteres restantes</span>
          {#if error}
            <span class="text-red-600">{error}</span>
          {/if}
        </div>
      </div>

      <div class="px-5 py-4 bg-gray-50 border-t border-gray-100 flex items-center justify-end gap-2">
        <Button variant="outline" size="sm" on:click={fechar} disabled={loading}>Cancelar</Button>
        <Button variant="primary" size="sm" on:click={confirmar} disabled={loading}>
          {loading ? 'Salvando...' : 'Confirmar'}
        </Button>
      </div>
    </div>
  </div>
{/if}
