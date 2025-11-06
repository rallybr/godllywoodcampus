<script>
  import { createEventDispatcher } from 'svelte';
  import { formatDataViagem } from '$lib/stores/viagem';
  import ModalComprovante from './ModalComprovante.svelte';
  import ModalDadosViagem from './ModalDadosViagem.svelte';
  
  export let jovem;
  export let viagem = null;
  export let edicaoId = null;
  
  const dispatch = createEventDispatcher();
  
  // Estado do modal
  let modalOpen = false;
  let modalUrl = '';
  let modalTipo = '';
  let modalDadosViagemOpen = false;
  
  // Dados do jovem
  $: nome = jovem?.nome_completo || '';
  $: foto = jovem?.foto || '';
  $: estado = jovem?.estado?.sigla || '';
  $: bloco = jovem?.bloco?.nome || '';
  $: regiao = jovem?.regiao?.nome || '';
  $: igreja = jovem?.igreja?.nome || '';
  
  // Dados da viagem
  $: pagouDespesas = viagem?.pagou_despesas || false;
  $: comprovantePagamento = viagem?.comprovante_pagamento;
  $: dataIda = viagem?.data_passagem_ida;
  $: comprovanteIda = viagem?.comprovante_passagem_ida;
  $: dataVolta = viagem?.data_passagem_volta;
  $: comprovanteVolta = viagem?.comprovante_passagem_volta;
  
  // Novos campos
  $: comoPagouDespesas = viagem?.como_pagou_despesas || '';
  $: comoPagouPassagens = viagem?.como_pagou_passagens || '';
  $: comoConseguiuValor = viagem?.como_conseguiu_valor || '';
  $: alguemAjudou = viagem?.alguem_ajudou_pagar || false;
  $: quemAjudou = viagem?.quem_ajudou_pagar || '';
  
  // Formatação das datas
  $: dataIdaFormatada = formatDataViagem(dataIda);
  $: dataVoltaFormatada = formatDataViagem(dataVolta);
  
  // Verificar se há dados de pagamento preenchidos
  $: temDadosPagamento = comoPagouDespesas || comoPagouPassagens || comoConseguiuValor || quemAjudou;
  
  function handleUploadPagamento() {
    dispatch('upload', { tipo: 'pagamento', jovemId: jovem.id, edicaoId });
  }
  
  function handleUploadIda() {
    dispatch('upload', { tipo: 'ida', jovemId: jovem.id, edicaoId });
  }
  
  function handleUploadVolta() {
    dispatch('upload', { tipo: 'volta', jovemId: jovem.id, edicaoId });
  }
  
  function handleRemoveComprovante(tipo) {
    dispatch('remove', { tipo, jovemId: jovem.id, edicaoId });
  }
  
  function handleViewComprovante(url, tipo) {
    modalUrl = url;
    modalTipo = tipo;
    modalOpen = true;
  }
  
  function closeModal() {
    modalOpen = false;
    modalUrl = '';
    modalTipo = '';
  }
  
  function handleEditDadosViagem() {
    modalDadosViagemOpen = true;
  }
  
  function handleCloseDadosViagem() {
    modalDadosViagemOpen = false;
  }
  
  function handleDadosViagemSaved() {
    dispatch('refresh');
    handleCloseDadosViagem();
  }
</script>

<div class="bg-gradient-to-b from-gray-800 to-gray-900 rounded-2xl shadow-xl border border-gray-700 p-4 sm:p-6 relative ring-1 ring-white/5 w-full">
  <!-- Botão de remoção (ícone vermelho no canto superior direito) -->
  <button
    class="absolute top-4 right-4 w-8 h-8 bg-red-600 hover:bg-red-700 rounded-full flex items-center justify-center transition-colors"
    on:click={() => dispatch('delete', { jovemId: jovem.id, edicaoId })}
    title="Remover jovem"
  >
    <svg class="w-4 h-4 text-white" fill="none" viewBox="0 0 24 24" stroke="currentColor">
      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16" />
    </svg>
  </button>
  
  <!-- Foto do jovem -->
  <div class="flex justify-center mb-4 sm:mb-5">
    {#if foto}
      <img
        src={foto}
        alt={nome}
        class="w-20 h-20 sm:w-24 sm:h-24 rounded-full object-cover border-4 border-gray-600 shadow-inner"
      />
    {:else}
      <div class="w-20 h-20 sm:w-24 sm:h-24 rounded-full bg-gradient-to-br from-blue-500 to-purple-600 flex items-center justify-center border-4 border-gray-600 shadow-inner">
        <span class="text-white font-bold text-xl sm:text-2xl">
          {nome.charAt(0) || 'J'}
        </span>
      </div>
    {/if}
  </div>
  
  <!-- Nome do jovem -->
  <div class="text-center mb-4 sm:mb-6">
    <div class="flex items-center justify-center space-x-2 sm:space-x-3">
      <svg class="w-5 h-5 sm:w-6 sm:h-6 text-emerald-400" fill="none" viewBox="0 0 24 24" stroke="currentColor">
        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M16 7a4 4 0 11-8 0 4 4 0 018 0zM12 14a7 7 0 00-7 7h14a7 7 0 00-7-7z" />
      </svg>
      <h3 class="text-white font-semibold text-lg sm:text-2xl tracking-wide break-words">{nome}</h3>
    </div>
  </div>
  
  <!-- Bandeira do estado (se disponível) -->
  {#if estado}
    <div class="flex justify-center mb-4">
      <div class="w-20 h-14 sm:w-24 sm:h-16 bg-gradient-to-r from-green-500 to-yellow-500 rounded border border-gray-600 flex items-center justify-center">
        <span class="text-white text-2xl sm:text-3xl font-bold">{estado}</span>
      </div>
    </div>
  {/if}
  
  <!-- Informações de localização -->
  <div class="space-y-2 sm:space-y-3 mb-4 sm:mb-6">
    <!-- Primeira linha: Estado e Bloco -->
    <div class="grid grid-cols-1 sm:grid-cols-2 gap-2 sm:gap-4">
      <div class="flex items-center space-x-2 sm:space-x-3">
        <svg class="w-4 h-4 sm:w-5 sm:h-5 text-blue-400 flex-shrink-0" fill="none" viewBox="0 0 24 24" stroke="currentColor">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M17.657 16.657L13.414 20.9a1.998 1.998 0 01-2.827 0l-4.244-4.243a8 8 0 1111.314 0z" />
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 11a3 3 0 11-6 0 3 3 0 016 0z" />
        </svg>
        <div class="flex-1 min-w-0">
          <span class="text-white text-xs sm:text-sm">Estado: </span>
          <span class="text-orange-400 font-medium text-xs sm:text-sm truncate">{jovem?.estado?.nome || 'N/A'}</span>
        </div>
      </div>
      
      <div class="flex items-center space-x-2 sm:space-x-3">
        <svg class="w-4 h-4 sm:w-5 sm:h-5 text-purple-400 flex-shrink-0" fill="none" viewBox="0 0 24 24" stroke="currentColor">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 21V5a2 2 0 00-2-2H7a2 2 0 00-2 2v16m14 0h2m-2 0h-5m-9 0H3m2 0h5M9 7h1m-1 4h1m4-4h1m-1 4h1m-5 10v-5a1 1 0 011-1h2a1 1 0 011 1v5m-4 0h4" />
        </svg>
        <div class="flex-1 min-w-0">
          <span class="text-white text-xs sm:text-sm">Bloco: </span>
          <span class="text-orange-400 font-medium text-xs sm:text-sm truncate">{bloco || 'N/A'}</span>
        </div>
      </div>
    </div>
    
    <!-- Segunda linha: Região e Igreja -->
    <div class="grid grid-cols-1 sm:grid-cols-2 gap-2 sm:gap-4">
      <div class="flex items-center space-x-2 sm:space-x-3">
        <svg class="w-4 h-4 sm:w-5 sm:h-5 text-green-400 flex-shrink-0" fill="none" viewBox="0 0 24 24" stroke="currentColor">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3 12l2-2m0 0l7-7 7 7M5 10v10a1 1 0 001 1h3m10-11l2 2m-2-2v10a1 1 0 01-1 1h-3m-6 0a1 1 0 001-1v-4a1 1 0 011-1h2a1 1 0 011 1v4a1 1 0 001 1m-6 0h6" />
        </svg>
        <div class="flex-1 min-w-0">
          <span class="text-white text-xs sm:text-sm">Região: </span>
          <span class="text-orange-400 font-medium text-xs sm:text-sm truncate">{regiao || 'N/A'}</span>
        </div>
      </div>
      
      <div class="flex items-center space-x-2 sm:space-x-3">
        <svg class="w-4 h-4 sm:w-5 sm:h-5 text-orange-400 flex-shrink-0" fill="none" viewBox="0 0 24 24" stroke="currentColor">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M17 20h5v-2a3 3 0 00-5.356-1.857M17 20H7m10 0v-2c0-.656-.126-1.283-.356-1.857M7 20H2v-2a3 3 0 015.356-1.857M7 20v-2c0-.656.126-1.283.356-1.857m0 0a5.002 5.002 0 019.288 0M15 7a3 3 0 11-6 0 3 3 0 016 0zm6 3a2 2 0 11-4 0 2 2 0 014 0zM7 10a2 2 0 11-4 0 2 2 0 014 0z" />
        </svg>
        <div class="flex-1 min-w-0">
          <span class="text-white text-xs sm:text-sm">Igreja: </span>
          <span class="text-orange-400 font-medium text-xs sm:text-sm truncate">{igreja || 'N/A'}</span>
        </div>
      </div>
    </div>
  </div>
  
  
  <!-- Botão de editar dados de pagamento -->
  <div class="mt-4 mb-3">
    <button
      class="w-full inline-flex items-center justify-center gap-2.5 text-sm sm:text-base font-semibold text-white bg-gradient-to-r from-purple-600 to-indigo-600 hover:from-purple-700 hover:to-indigo-700 border border-purple-400/50 px-4 py-3 rounded-xl shadow-lg shadow-purple-500/20 hover:shadow-purple-500/30 transition-all duration-200 transform hover:scale-[1.02] active:scale-[0.98]"
      on:click={handleEditDadosViagem}
    >
      <svg class="w-5 h-5 sm:w-6 sm:h-6" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2.5">
        <path stroke-linecap="round" stroke-linejoin="round" d="M11 5H6a2 2 0 00-2 2v11a2 2 0 002 2h11a2 2 0 002-2v-5m-1.414-9.414a2 2 0 112.828 2.828L11.828 15H9v-2.828l8.586-8.586z" />
      </svg>
      <span>Editar Dados de Pagamento</span>
    </button>
  </div>
  
    <!-- Informações de pagamento (se preenchidas) -->
    {#if temDadosPagamento}
      <div class="mt-4 mb-4 bg-gradient-to-br from-white/8 to-white/5 rounded-xl border border-white/20 shadow-lg p-4 sm:p-5">
        <h4 class="text-white text-base sm:text-lg font-bold mb-4 flex items-center gap-2">
          <div class="w-8 h-8 sm:w-10 sm:h-10 bg-gradient-to-br from-green-500 to-emerald-600 rounded-lg flex items-center justify-center shadow-md">
            <svg class="w-5 h-5 sm:w-6 sm:h-6 text-white" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8c-1.657 0-3 .895-3 2s1.343 2 3 2 3 .895 3 2-1.343 2-3 2m0-8c1.11 0 2.08.402 2.599 1M12 8V7m0 1v8m0 0v1m0-1c-1.11 0-2.08-.402-2.599-1M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
            </svg>
          </div>
          <span>Informações de Pagamento</span>
        </h4>
        <div class="space-y-3 sm:space-y-4">
          {#if comoPagouDespesas}
            <div class="bg-white/5 rounded-lg border border-white/10 p-3 sm:p-4 hover:bg-white/10 transition-colors">
              <div class="flex items-start gap-3">
                <div class="w-8 h-8 bg-blue-500/20 rounded-lg flex items-center justify-center flex-shrink-0 mt-0.5">
                  <svg class="w-5 h-5 text-blue-400" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8c-1.657 0-3 1.343-3 3 0 1.306.835 2.418 2 2.83V18m0 0h2m-2 0H9m5-6c1.657 0 3-1.343 3-3 0-1.306-.835-2.418-2-2.83V6m0 0h-2m2 0h3" />
                  </svg>
                </div>
                <div class="flex-1 min-w-0">
                  <div class="text-sm sm:text-base font-semibold text-orange-400 mb-1">COMO CONSEGUIU O VALOR DAS DESPESAS?</div>
                  <div class="text-sm sm:text-base text-gray-200 leading-relaxed">{comoPagouDespesas}</div>
                </div>
              </div>
            </div>
          {/if}
          {#if comoPagouPassagens}
            <div class="bg-white/5 rounded-lg border border-white/10 p-3 sm:p-4 hover:bg-white/10 transition-colors">
              <div class="flex items-start gap-3">
                <div class="w-8 h-8 bg-orange-500/20 rounded-lg flex items-center justify-center flex-shrink-0 mt-0.5">
                  <svg class="w-5 h-5 text-orange-400" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3 7v10a2 2 0 002 2h14a2 2 0 002-2V9a2 2 0 00-2-2H5a2 2 0 00-2-2z" />
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M8 5a2 2 0 012-2h4a2 2 0 012 2v2H8V5z" />
                  </svg>
                </div>
                <div class="flex-1 min-w-0">
                  <div class="text-sm sm:text-base font-semibold text-orange-400 mb-1">COMO CONSEGUIU O VALOR DAS PASSAGENS?</div>
                  <div class="text-sm sm:text-base text-gray-200 leading-relaxed">{comoPagouPassagens}</div>
                </div>
              </div>
            </div>
          {/if}
          {#if comoConseguiuValor}
            <div class="bg-white/5 rounded-lg border border-white/10 p-3 sm:p-4 hover:bg-white/10 transition-colors">
              <div class="flex items-start gap-3">
                <div class="w-8 h-8 bg-green-500/20 rounded-lg flex items-center justify-center flex-shrink-0 mt-0.5">
                  <svg class="w-5 h-5 text-green-400" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 10V3L4 14h7v7l9-11h-7z" />
                  </svg>
                </div>
                <div class="flex-1 min-w-0">
                  <div class="text-sm sm:text-base font-semibold text-orange-400 mb-1">OBSERVAÇÃO DE PAGAMENTO</div>
                  <div class="text-sm sm:text-base text-gray-200 leading-relaxed">{comoConseguiuValor}</div>
                </div>
              </div>
            </div>
          {/if}
          {#if alguemAjudou}
            <div class="bg-white/5 rounded-lg border border-white/10 p-3 sm:p-4 hover:bg-white/10 transition-colors">
              <div class="flex items-start gap-3">
                <div class="w-8 h-8 bg-emerald-500/20 rounded-lg flex items-center justify-center flex-shrink-0 mt-0.5">
                  <svg class="w-5 h-5 text-emerald-400" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M17 20h5v-2a3 3 0 00-5.356-1.857M17 20H7m10 0v-2c0-.656-.126-1.283-.356-1.857M7 20H2v-2a3 3 0 015.356-1.857M7 20v-2c0-.656.126-1.283.356-1.857m0 0a5.002 5.002 0 019.288 0M15 7a3 3 0 11-6 0 3 3 0 016 0zm6 3a2 2 0 11-4 0 2 2 0 014 0zM7 10a2 2 0 11-4 0 2 2 0 014 0z" />
                  </svg>
                </div>
                <div class="flex-1 min-w-0">
                  <div class="text-sm sm:text-base font-semibold text-orange-400 mb-1">QUEM TE AJUDOU A PAGAR?</div>
                  <div class="text-sm sm:text-base text-gray-200 leading-relaxed">
                    <span class="inline-flex items-center px-2 py-1 rounded-md bg-emerald-500/20 text-emerald-300 font-medium mr-2">Sim</span>
                    {#if quemAjudou}
                      <span class="text-gray-300">{quemAjudou}</span>
                    {:else}
                      <span class="text-gray-400 italic">Não especificado</span>
                    {/if}
                  </div>
                </div>
              </div>
            </div>
          {/if}
        </div>
      </div>
    {/if}
  
  <!-- Informações e comprovantes -->
  <div class="mt-4">
    <div class="grid grid-cols-1 sm:grid-cols-3 gap-3 sm:gap-4">
      <!-- Coluna: Despesas -->
      <div class="bg-white/5 rounded-xl border border-white/10 p-2 sm:p-3">
        <div class="flex items-center gap-1.5 sm:gap-2 mb-2">
          <svg class="w-4 h-4 sm:w-5 sm:h-5 text-blue-400 flex-shrink-0" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8c-1.657 0-3 1.343-3 3 0 1.306.835 2.418 2 2.83V18m0 0h2m-2 0H9m5-6c1.657 0 3-1.343 3-3 0-1.306-.835-2.418-2-2.83V6m0 0h-2m2 0h3"/></svg>
          <span class="text-white text-xs sm:text-sm font-medium">Despesas</span>
        </div>
        {#if comprovantePagamento}
          <button
            class="w-full inline-flex items-center justify-center gap-1 sm:gap-1.5 text-xs font-medium text-emerald-300 bg-emerald-500/10 hover:bg-emerald-500/20 border border-emerald-400/30 px-2 sm:px-3 py-1.5 sm:py-2 rounded-lg transition-colors"
            on:click={() => handleViewComprovante(comprovantePagamento, 'pagamento')}
          >
            <svg class="w-3 h-3 sm:w-3.5 sm:h-3.5 flex-shrink-0" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 12a3 3 0 11-6 0 3 3 0 016 0z"/><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M2.458 12C3.732 7.943 7.523 5 12 5c4.477 0 8.268 2.943 9.542 7-1.274 4.057-5.065 7-9.542 7-4.477 0-8.268-2.943-9.542-7z"/></svg>
            <span class="hidden sm:inline">Ver comprovante</span>
            <span class="sm:hidden">Ver</span>
          </button>
          <div class="mt-1.5 sm:mt-2 text-center text-green-400 text-xs">Pago</div>
        {:else}
          <button
            class="w-full inline-flex items-center justify-center gap-1 sm:gap-1.5 text-xs font-medium text-sky-300 bg-sky-500/10 hover:bg-sky-500/20 border border-sky-400/30 px-2 sm:px-3 py-1.5 sm:py-2 rounded-lg transition-colors"
            on:click={handleUploadPagamento}
          >
            <svg class="w-3 h-3 sm:w-3.5 sm:h-3.5 flex-shrink-0" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 6v12m6-6H6"/></svg>
            <span class="hidden sm:inline">Enviar comprovante</span>
            <span class="sm:hidden">Enviar</span>
          </button>
          <div class="mt-1.5 sm:mt-2 text-center text-gray-400 text-xs">Não pago</div>
        {/if}
      </div>

      <!-- Coluna: Ida -->
      <div class="bg-white/5 rounded-xl border border-white/10 p-2 sm:p-3">
        <div class="flex items-center gap-1.5 sm:gap-2 mb-2">
          <svg class="w-4 h-4 sm:w-5 sm:h-5 text-orange-400 flex-shrink-0" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3 7v10a2 2 0 002 2h14a2 2 0 002-2V9a2 2 0 00-2-2H5a2 2 0 00-2-2z"/><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M8 5a2 2 0 012-2h4a2 2 0 012 2v2H8V5z"/></svg>
          <span class="text-white text-xs sm:text-sm font-medium">Ida</span>
        </div>
        {#if comprovanteIda}
          <button
            class="w-full inline-flex items-center justify-center gap-1 sm:gap-1.5 text-xs font-medium text-emerald-300 bg-emerald-500/10 hover:bg-emerald-500/20 border border-emerald-400/30 px-2 sm:px-3 py-1.5 sm:py-2 rounded-lg transition-colors"
            on:click={() => handleViewComprovante(comprovanteIda, 'ida')}
          >
            <svg class="w-3 h-3 sm:w-3.5 sm:h-3.5 flex-shrink-0" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 12a3 3 0 11-6 0 3 3 0 016 0z"/><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M2.458 12C3.732 7.943 7.523 5 12 5c4.477 0 8.268 2.943 9.542 7-1.274 4.057-5.065 7-9.542 7-4.477 0-8.268-2.943-9.542-7z"/></svg>
            <span class="hidden sm:inline">Ver comprovante</span>
            <span class="sm:hidden">Ver</span>
          </button>
          <div class="mt-1.5 sm:mt-2 text-center text-white text-xs">{dataIda ? dataIdaFormatada : 'Informado'}</div>
        {:else}
          <button
            class="w-full inline-flex items-center justify-center gap-1 sm:gap-1.5 text-xs font-medium text-sky-300 bg-sky-500/10 hover:bg-sky-500/20 border border-sky-400/30 px-2 sm:px-3 py-1.5 sm:py-2 rounded-lg transition-colors"
            on:click={handleUploadIda}
          >
            <svg class="w-3 h-3 sm:w-3.5 sm:h-3.5 flex-shrink-0" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 6v12m6-6H6"/></svg>
            <span class="hidden sm:inline">Enviar comprovante</span>
            <span class="sm:hidden">Enviar</span>
          </button>
          <div class="mt-1.5 sm:mt-2 text-center text-gray-400 text-xs">Não informado</div>
        {/if}
      </div>

      <!-- Coluna: Volta -->
      <div class="bg-white/5 rounded-xl border border-white/10 p-2 sm:p-3">
        <div class="flex items-center gap-1.5 sm:gap-2 mb-2">
          <svg class="w-4 h-4 sm:w-5 sm:h-5 text-orange-400 flex-shrink-0" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3 7v10a2 2 0 002 2h14a2 2 0 002-2V9a2 2 0 00-2-2H5a2 2 0 00-2-2z"/><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M8 5a2 2 0 012-2h4a2 2 0 012 2v2H8V5z"/></svg>
          <span class="text-white text-xs sm:text-sm font-medium">Volta</span>
        </div>
        {#if comprovanteVolta}
          <button
            class="w-full inline-flex items-center justify-center gap-1 sm:gap-1.5 text-xs font-medium text-emerald-300 bg-emerald-500/10 hover:bg-emerald-500/20 border border-emerald-400/30 px-2 sm:px-3 py-1.5 sm:py-2 rounded-lg transition-colors"
            on:click={() => handleViewComprovante(comprovanteVolta, 'volta')}
          >
            <svg class="w-3 h-3 sm:w-3.5 sm:h-3.5 flex-shrink-0" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 12a3 3 0 11-6 0 3 3 0 016 0z"/><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M2.458 12C3.732 7.943 7.523 5 12 5c4.477 0 8.268 2.943 9.542 7-1.274 4.057-5.065 7-9.542 7-4.477 0-8.268-2.943-9.542-7z"/></svg>
            <span class="hidden sm:inline">Ver comprovante</span>
            <span class="sm:hidden">Ver</span>
          </button>
          <div class="mt-1.5 sm:mt-2 text-center text-white text-xs">{dataVolta ? dataVoltaFormatada : 'Informado'}</div>
        {:else}
          <button
            class="w-full inline-flex items-center justify-center gap-1 sm:gap-1.5 text-xs font-medium text-sky-300 bg-sky-500/10 hover:bg-sky-500/20 border border-sky-400/30 px-2 sm:px-3 py-1.5 sm:py-2 rounded-lg transition-colors"
            on:click={handleUploadVolta}
          >
            <svg class="w-3 h-3 sm:w-3.5 sm:h-3.5 flex-shrink-0" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 6v12m6-6H6"/></svg>
            <span class="hidden sm:inline">Enviar comprovante</span>
            <span class="sm:hidden">Enviar</span>
          </button>
          <div class="mt-1.5 sm:mt-2 text-center text-gray-400 text-xs">Não informado</div>
        {/if}
      </div>
    </div>
  </div>
</div>

<!-- Modal de Comprovante -->
<ModalComprovante
  bind:isOpen={modalOpen}
  comprovanteUrl={modalUrl}
  tipo={modalTipo}
  nomeJovem={nome}
  on:close={closeModal}
/>

<!-- Modal de Dados de Viagem -->
<ModalDadosViagem
  bind:isOpen={modalDadosViagemOpen}
  jovemId={jovem.id}
  edicaoId={edicaoId}
  dadosViagem={viagem}
  on:close={handleCloseDadosViagem}
  on:saved={handleDadosViagemSaved}
/>
