<script>
  import { createEventDispatcher } from 'svelte';
  import { upsertDadosViagem } from '$lib/stores/viagem';
  
  export let isOpen = false;
  export let jovemId = '';
  export let edicaoId = '';
  export let dadosViagem = null; // Dados existentes para edição
  
  const dispatch = createEventDispatcher();
  
  // Formulário
  let formData = {
    como_pagou_despesas: '',
    como_pagou_passagens: '',
    como_conseguiu_valor: '',
    alguem_ajudou_pagar: false,
    quem_ajudou_pagar: ''
  };
  
  let loading = false;
  let error = '';
  let dadosCarregados = false; // Flag para controlar carregamento inicial
  
  // Carregar dados apenas quando o modal abrir pela primeira vez
  $: if (isOpen && dadosViagem && !dadosCarregados) {
    formData = {
      como_pagou_despesas: dadosViagem.como_pagou_despesas || '',
      como_pagou_passagens: dadosViagem.como_pagou_passagens || '',
      como_conseguiu_valor: dadosViagem.como_conseguiu_valor || '',
      alguem_ajudou_pagar: dadosViagem.alguem_ajudou_pagar || false,
      quem_ajudou_pagar: dadosViagem.quem_ajudou_pagar || ''
    };
    dadosCarregados = true;
  }
  
  // Resetar quando fechar
  $: if (!isOpen) {
    formData = {
      como_pagou_despesas: '',
      como_pagou_passagens: '',
      como_conseguiu_valor: '',
      alguem_ajudou_pagar: false,
      quem_ajudou_pagar: ''
    };
    dadosCarregados = false;
    error = '';
  }
  
  async function handleSubmit() {
    if (!jovemId || !edicaoId) {
      error = 'ID do jovem ou edição não informado.';
      return;
    }
    
    loading = true;
    error = '';
    
    try {
      await upsertDadosViagem(jovemId, edicaoId, {
        como_pagou_despesas: formData.como_pagou_despesas || null,
        como_pagou_passagens: formData.como_pagou_passagens || null,
        como_conseguiu_valor: formData.como_conseguiu_valor || null,
        alguem_ajudou_pagar: formData.alguem_ajudou_pagar,
        quem_ajudou_pagar: formData.alguem_ajudou_pagar ? (formData.quem_ajudou_pagar || null) : null
      });
      
      dispatch('saved');
      handleClose();
    } catch (err) {
      console.error('Erro ao salvar dados de viagem:', err);
      error = err.message || 'Erro ao salvar os dados. Tente novamente.';
    } finally {
      loading = false;
    }
  }
  
  function handleClose() {
    dispatch('close');
  }
</script>

{#if isOpen}
  <div 
    class="fixed inset-0 bg-gray-900/80 flex items-center justify-center z-50 p-4"
    on:click={(e) => e.target === e.currentTarget && handleClose()}
    role="dialog"
    aria-modal="true"
  >
    <div 
      class="relative bg-gradient-to-b from-gray-800 to-gray-900 rounded-2xl shadow-xl border border-gray-700 ring-1 ring-white/5 transform transition-all w-full max-w-2xl max-h-[90vh] overflow-y-auto"
      on:click|stopPropagation
      on:mousedown|stopPropagation
      style="pointer-events: auto; position: relative; z-index: 51;"
    >
      <!-- Header -->
      <div class="flex items-center justify-between p-6 border-b border-gray-700 bg-gradient-to-b from-gray-800 to-gray-900 sticky top-0 z-10">
        <div class="flex items-center gap-3">
          <svg class="w-6 h-6 text-purple-400" fill="none" viewBox="0 0 24 24" stroke="currentColor">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8c-1.657 0-3 .895-3 2s1.343 2 3 2 3 .895 3 2-1.343 2-3 2m0-8c1.11 0 2.08.402 2.599 1M12 8V7m0 1v8m0 0v1m0-1c-1.11 0-2.08-.402-2.599-1M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
          </svg>
          <h3 class="text-lg font-semibold text-white">Dados de Pagamento</h3>
        </div>
        <button
          type="button"
          class="text-gray-400 hover:text-white focus:outline-none focus:ring-2 focus:ring-purple-500 rounded-md p-1 transition-colors"
          on:click={handleClose}
          disabled={loading}
        >
          <svg class="h-6 w-6" fill="none" viewBox="0 0 24 24" stroke="currentColor">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12" />
          </svg>
        </button>
      </div>
      
      <!-- Content -->
      <div class="p-6" style="pointer-events: auto;">
        <form 
          on:submit|preventDefault={handleSubmit} 
          class="space-y-6" 
          on:click|stopPropagation
        >
          <!-- Como pagou as despesas -->
          <div>
            <label for="como_pagou_despesas" class="block text-sm font-medium text-white mb-2 flex items-center gap-2">
              <svg class="w-4 h-4 text-blue-400" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8c-1.657 0-3 1.343-3 3 0 1.306.835 2.418 2 2.83V18m0 0h2m-2 0H9m5-6c1.657 0 3-1.343 3-3 0-1.306-.835-2.418-2-2.83V6m0 0h-2m2 0h3" />
              </svg>
              Como você pagou as despesas?
            </label>
            <textarea
              id="como_pagou_despesas"
              bind:value={formData.como_pagou_despesas}
              rows="3"
              class="w-full px-3 py-2 bg-white/10 border border-white/20 rounded-lg text-white placeholder-gray-400 focus:outline-none focus:ring-2 focus:ring-purple-500 focus:border-purple-500 transition-colors resize-none"
              placeholder="Ex: PIX, cartão de crédito, dinheiro, etc..."
              disabled={loading}
              style="pointer-events: auto;"
            ></textarea>
          </div>
          
          <!-- Como pagou as passagens -->
          <div>
            <label for="como_pagou_passagens" class="block text-sm font-medium text-white mb-2 flex items-center gap-2">
              <svg class="w-4 h-4 text-orange-400" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3 7v10a2 2 0 002 2h14a2 2 0 002-2V9a2 2 0 00-2-2H5a2 2 0 00-2-2z" />
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M8 5a2 2 0 012-2h4a2 2 0 012 2v2H8V5z" />
              </svg>
              Como você pagou as passagens?
            </label>
            <textarea
              id="como_pagou_passagens"
              bind:value={formData.como_pagou_passagens}
              rows="3"
              class="w-full px-3 py-2 bg-white/10 border border-white/20 rounded-lg text-white placeholder-gray-400 focus:outline-none focus:ring-2 focus:ring-purple-500 focus:border-purple-500 transition-colors resize-none"
              placeholder="Ex: PIX, cartão de crédito, dinheiro, etc..."
              disabled={loading}
              style="pointer-events: auto;"
            ></textarea>
          </div>
          
          <!-- Como conseguiu o valor -->
          <div>
            <label for="como_conseguiu_valor" class="block text-sm font-medium text-white mb-2 flex items-center gap-2">
              <svg class="w-4 h-4 text-green-400" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 10V3L4 14h7v7l9-11h-7z" />
              </svg>
              Como você conseguiu o valor para pagar?
            </label>
            <textarea
              id="como_conseguiu_valor"
              bind:value={formData.como_conseguiu_valor}
              rows="3"
              class="w-full px-3 py-2 bg-white/10 border border-white/20 rounded-lg text-white placeholder-gray-400 focus:outline-none focus:ring-2 focus:ring-purple-500 focus:border-purple-500 transition-colors resize-none"
              placeholder="Ex: Trabalho, ajuda da família, etc..."
              disabled={loading}
              style="pointer-events: auto;"
            ></textarea>
          </div>
          
          <!-- Alguém ajudou a pagar? -->
          <div>
            <label class="block text-sm font-medium text-white mb-3 flex items-center gap-2">
              <svg class="w-4 h-4 text-emerald-400" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M17 20h5v-2a3 3 0 00-5.356-1.857M17 20H7m10 0v-2c0-.656-.126-1.283-.356-1.857M7 20H2v-2a3 3 0 015.356-1.857M7 20v-2c0-.656.126-1.283.356-1.857m0 0a5.002 5.002 0 019.288 0M15 7a3 3 0 11-6 0 3 3 0 016 0zm6 3a2 2 0 11-4 0 2 2 0 014 0zM7 10a2 2 0 11-4 0 2 2 0 014 0z" />
              </svg>
              Alguém te ajudou a pagar?
            </label>
            <div class="flex space-x-4">
              <label class="flex items-center p-3 bg-white/5 rounded-lg border border-white/10 cursor-pointer hover:bg-white/10 transition-colors">
                <input
                  type="radio"
                  bind:group={formData.alguem_ajudou_pagar}
                  value={true}
                  class="w-4 h-4 text-purple-600 focus:ring-purple-500 border-gray-400 bg-gray-700"
                  disabled={loading}
                />
                <span class="ml-2 text-sm font-medium text-white">Sim</span>
              </label>
              <label class="flex items-center p-3 bg-white/5 rounded-lg border border-white/10 cursor-pointer hover:bg-white/10 transition-colors">
                <input
                  type="radio"
                  bind:group={formData.alguem_ajudou_pagar}
                  value={false}
                  class="w-4 h-4 text-purple-600 focus:ring-purple-500 border-gray-400 bg-gray-700"
                  disabled={loading}
                />
                <span class="ml-2 text-sm font-medium text-white">Não</span>
              </label>
            </div>
          </div>
          
          <!-- Quem ajudou a pagar (só aparece se Sim) -->
          {#if formData.alguem_ajudou_pagar}
            <div>
              <label for="quem_ajudou_pagar" class="block text-sm font-medium text-white mb-2 flex items-center gap-2">
                <svg class="w-4 h-4 text-yellow-400" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M16 7a4 4 0 11-8 0 4 4 0 018 0zM12 14a7 7 0 00-7 7h14a7 7 0 00-7-7z" />
                </svg>
                Se sim, quem te ajudou a pagar?
              </label>
              <input
                type="text"
                id="quem_ajudou_pagar"
                bind:value={formData.quem_ajudou_pagar}
                class="w-full px-3 py-2 bg-white/10 border border-white/20 rounded-lg text-white placeholder-gray-400 focus:outline-none focus:ring-2 focus:ring-purple-500 focus:border-purple-500 transition-colors"
                placeholder="Nome da pessoa que ajudou"
                disabled={loading}
                style="pointer-events: auto;"
              />
            </div>
          {/if}
          
          <!-- Erro -->
          {#if error}
            <div class="bg-red-500/10 border border-red-500/30 rounded-lg p-3">
              <div class="flex items-center space-x-2">
                <svg class="w-5 h-5 text-red-400" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8v4m0 4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
                </svg>
                <p class="text-sm text-red-300">{error}</p>
              </div>
            </div>
          {/if}
          
          <!-- Botões -->
          <div class="flex justify-end space-x-3 pt-4 border-t border-gray-700">
            <button
              type="button"
              class="px-4 py-2 border border-gray-600 rounded-lg text-gray-300 bg-white/5 hover:bg-white/10 focus:outline-none focus:ring-2 focus:ring-purple-500 transition-colors"
              on:click={handleClose}
              disabled={loading}
            >
              Cancelar
            </button>
            <button
              type="submit"
              class="px-4 py-2 bg-purple-600 text-white rounded-lg hover:bg-purple-700 focus:outline-none focus:ring-2 focus:ring-purple-500 disabled:opacity-50 disabled:cursor-not-allowed transition-colors inline-flex items-center"
              disabled={loading}
            >
              {#if loading}
                <svg class="animate-spin -ml-1 mr-2 h-4 w-4 inline" fill="none" viewBox="0 0 24 24">
                  <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle>
                  <path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
                </svg>
              {/if}
              {loading ? 'Salvando...' : 'Salvar'}
            </button>
          </div>
        </form>
      </div>
    </div>
  </div>
{/if}

