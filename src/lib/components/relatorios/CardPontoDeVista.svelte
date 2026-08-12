<script>
  export let jovem;

  const statusLabel = {
    pre_aprovado: 'OK',
    observar: 'Observar',
    sem_condicao: 'Sem condição'
  };

  function truncarNome(nome, max = 19) {
    const texto = (nome || '').toString().trim();
    if (!texto) return 'Namorado';
    if (texto.length <= max) return texto;
    return `${texto.slice(0, max)}…`;
  }

  $: pontos = (jovem.pontos_de_vista || []).filter((p) =>
    ['pre_aprovado', 'observar', 'sem_condicao'].includes(p.tipo_aprovacao)
  );

  $: observacoes = pontos.filter((p) => p.observacao);

  const PALETA_AVALIADORES = [
    'bg-violet-600 hover:bg-violet-700 border-violet-700',
    'bg-rose-600 hover:bg-rose-700 border-rose-700',
    'bg-teal-600 hover:bg-teal-700 border-teal-700',
    'bg-amber-600 hover:bg-amber-700 border-amber-700',
    'bg-indigo-600 hover:bg-indigo-700 border-indigo-700',
    'bg-cyan-600 hover:bg-cyan-700 border-cyan-700',
    'bg-fuchsia-600 hover:bg-fuchsia-700 border-fuchsia-700',
    'bg-emerald-600 hover:bg-emerald-700 border-emerald-700'
  ];

  function corAvaliador(nome, index = 0) {
    const base = (nome || '').toString();
    let hash = 0;
    for (let i = 0; i < base.length; i++) hash = (hash + base.charCodeAt(i) * (i + 1)) % 997;
    return PALETA_AVALIADORES[(hash + index) % PALETA_AVALIADORES.length];
  }

  function estiloStatus(tipo) {
    switch (tipo) {
      case 'pre_aprovado':
        return {
          badge: 'bg-emerald-50 text-emerald-800 border-emerald-200 ring-emerald-100',
          dot: 'bg-emerald-500',
          label: 'OK'
        };
      case 'observar':
        return {
          badge: 'bg-amber-50 text-amber-900 border-amber-200 ring-amber-100',
          dot: 'bg-amber-500',
          label: 'Observar'
        };
      case 'sem_condicao':
        return {
          badge: 'bg-slate-100 text-slate-800 border-slate-300 ring-slate-100',
          dot: 'bg-slate-500',
          label: 'Sem condição'
        };
      default:
        return {
          badge: 'bg-gray-50 text-gray-700 border-gray-200 ring-gray-100',
          dot: 'bg-gray-400',
          label: statusLabel[tipo] || tipo
        };
    }
  }

  let showNamoradoModal = false;
  let observacaoModal = null;
  let fotoAvaliadorHover = null;
  let fotoAvaliadorModal = null;
  let hoverTimeout = null;

  function abrirFotoNamorado() {
    if (jovem.namorado?.foto) showNamoradoModal = true;
  }

  function fecharFotoNamorado() {
    showNamoradoModal = false;
  }

  function abrirObservacao(item) {
    observacaoModal = item;
  }

  function fecharObservacao() {
    observacaoModal = null;
  }

  function mostrarFotoHover(avaliador) {
    if (hoverTimeout) {
      clearTimeout(hoverTimeout);
      hoverTimeout = null;
    }
    if (!avaliador) return;
    fotoAvaliadorHover = {
      nome: avaliador.usuario_nome || avaliador.nome,
      foto: avaliador.usuario_foto || avaliador.foto || null
    };
  }

  function esconderFotoHover() {
    hoverTimeout = setTimeout(() => {
      fotoAvaliadorHover = null;
    }, 120);
  }

  function abrirFotoAvaliador(avaliador, event) {
    if (event) {
      event.preventDefault();
      event.stopPropagation();
    }
    if (!avaliador) return;
    fotoAvaliadorModal = {
      nome: avaliador.usuario_nome || avaliador.nome,
      foto: avaliador.usuario_foto || avaliador.foto || null
    };
    fotoAvaliadorHover = null;
  }

  function fecharFotoAvaliador() {
    fotoAvaliadorModal = null;
  }

  function handleModalKeydown(event) {
    if (event.key === 'Escape') {
      fecharFotoNamorado();
      fecharObservacao();
      fecharFotoAvaliador();
    }
  }
</script>

<div class="card-ponto-vista bg-white rounded-lg shadow-lg overflow-hidden border border-gray-100">
  <div class="flex flex-col md:flex-row md:items-stretch">
    <!-- Foto do jovem: altura total do card -->
    <a
      href="/jovens/{jovem.id}"
      class="relative block w-full md:w-48 lg:w-56 xl:w-64 flex-shrink-0 self-stretch min-h-[320px] md:min-h-full overflow-hidden bg-gray-200"
    >
      {#if jovem.foto}
        <img
          src={jovem.foto}
          alt={jovem.nome_completo}
          class="absolute inset-0 w-full h-full object-cover object-top"
        />
      {:else}
        <div class="absolute inset-0 bg-gradient-to-br from-blue-500 to-purple-600 flex items-center justify-center">
          <span class="text-white font-bold text-5xl">{jovem.nome_completo?.charAt(0) || 'J'}</span>
        </div>
      {/if}
      {#if jovem.estado?.bandeira}
        <div class="absolute top-3 right-3 w-11 h-8 rounded overflow-hidden border border-white shadow z-10">
          <img src={jovem.estado.bandeira} alt={jovem.estado?.sigla || 'UF'} class="w-full h-full object-cover" />
        </div>
      {/if}
    </a>

    <!-- Namorado (coluna intermediária) -->
    {#if jovem.namorado && (jovem.namorado.nome || jovem.namorado.foto)}
      <div class="flex-shrink-0 bg-gray-50 px-3 py-4 md:py-5 flex md:flex-col items-start gap-3 md:w-36 lg:w-40 border-b md:border-b-0 md:border-r border-gray-100">
        {#if jovem.namorado.foto}
          <button
            type="button"
            class="relative block w-28 sm:w-32 md:w-full aspect-[3/4] rounded-lg overflow-hidden border border-white shadow-md bg-white cursor-zoom-in"
            on:click={abrirFotoNamorado}
            title="Ampliar foto"
          >
            <img src={jovem.namorado.foto} alt={jovem.namorado.nome || 'Namorado'} class="absolute inset-0 w-full h-full object-cover object-top" />
          </button>
        {:else}
          <div class="w-28 sm:w-32 md:w-full aspect-[3/4] rounded-lg bg-gray-200 flex items-center justify-center text-gray-500 font-bold text-xl">
            {(jovem.namorado.nome || 'N').charAt(0)}
          </div>
        {/if}
        <div class="min-w-0">
          <p class="text-sm sm:text-base font-semibold text-gray-800 leading-tight" title={jovem.namorado.nome}>
            {truncarNome(jovem.namorado.nome, 19)}
          </p>
          {#if jovem.namorado.idade != null}
            <p class="text-xs sm:text-sm text-gray-500">{jovem.namorado.idade} anos</p>
          {/if}
        </div>
      </div>
    {/if}

    <!-- Dados à direita -->
    <div class="flex-1 p-4 sm:p-5 flex flex-col min-w-0">
      <a href="/jovens/{jovem.id}" class="block mb-3">
        <h3 class="text-lg sm:text-xl font-bold text-gray-900 uppercase tracking-wide leading-tight">
          {jovem.nome_completo || 'N/A'}
        </h3>
      </a>

      <div class="flex flex-wrap items-baseline gap-x-5 gap-y-1 text-sm mb-4">
        <div class="min-w-0">
          <span class="font-bold text-gray-700">Estado</span>
          <span class="text-gray-900 ml-1.5">{jovem.estado?.nome || 'N/A'}</span>
        </div>
        <div class="min-w-0">
          <span class="font-bold text-gray-700">Bloco</span>
          <span class="text-gray-900 ml-1.5">{jovem.bloco?.nome || 'N/A'}</span>
        </div>
        <div class="min-w-0">
          <span class="font-bold text-gray-700">Região</span>
          <span class="text-gray-900 ml-1.5">{jovem.regiao?.nome || 'N/A'}</span>
        </div>
        <div class="min-w-0">
          <span class="font-bold text-gray-700">Igreja</span>
          <span class="text-gray-900 ml-1.5">{jovem.igreja?.nome || 'N/A'}</span>
        </div>
      </div>

      <div class="space-y-3 text-sm border-t border-gray-100 pt-4 mt-auto">
        <div>
          <p class="text-xs font-semibold uppercase tracking-wide text-gray-500 mb-1.5">Avaliado por</p>
          {#if pontos.length === 0}
            <span class="text-gray-400">—</span>
          {:else}
            <div class="flex flex-wrap gap-2">
              {#each pontos as p}
                <button
                  type="button"
                  class="inline-flex items-center gap-2 rounded-lg border px-2.5 py-1.5 shadow-sm ring-1 bg-gray-100 text-gray-800 border-gray-300 ring-gray-200 hover:bg-gray-200 hover:brightness-[0.98] transition cursor-pointer"
                  on:mouseenter={() => mostrarFotoHover(p)}
                  on:mouseleave={esconderFotoHover}
                  on:focus={() => mostrarFotoHover(p)}
                  on:blur={esconderFotoHover}
                  on:click={(e) => abrirFotoAvaliador(p, e)}
                  title="Ver foto de {p.usuario_nome}"
                >
                  {#if p.usuario_foto}
                    <img src={p.usuario_foto} alt="" class="w-6 h-6 rounded-full object-cover border border-white shadow-sm" />
                  {:else}
                    <span class="w-6 h-6 rounded-full bg-gray-300 text-[10px] font-bold text-gray-700 flex items-center justify-center border border-white shadow-sm">
                      {(p.usuario_nome || '?').charAt(0).toUpperCase()}
                    </span>
                  {/if}
                  <span class="text-xs font-semibold text-gray-800 truncate max-w-[140px]">{p.usuario_nome}</span>
                </button>
              {/each}
            </div>
          {/if}
        </div>

        <div>
          <p class="text-xs font-semibold uppercase tracking-wide text-gray-500 mb-1.5">Ponto de Vista</p>
          {#if pontos.length === 0}
            <span class="text-gray-400">—</span>
          {:else}
            <div class="flex flex-wrap gap-2">
              {#each pontos as p}
                {@const st = estiloStatus(p.tipo_aprovacao)}
                <button
                  type="button"
                  class="inline-flex items-center gap-2 rounded-lg border px-2.5 py-1.5 shadow-sm ring-1 {st.badge} hover:brightness-[0.98] transition cursor-pointer"
                  title="Ver foto de {p.usuario_nome}"
                  on:mouseenter={() => mostrarFotoHover(p)}
                  on:mouseleave={esconderFotoHover}
                  on:focus={() => mostrarFotoHover(p)}
                  on:blur={esconderFotoHover}
                  on:click={(e) => abrirFotoAvaliador(p, e)}
                >
                  {#if p.usuario_foto}
                    <img src={p.usuario_foto} alt="" class="w-6 h-6 rounded-full object-cover border border-white shadow-sm" />
                  {:else}
                    <span class="w-2 h-2 rounded-full flex-shrink-0 {st.dot}"></span>
                  {/if}
                  <span class="text-xs font-semibold text-gray-800 truncate max-w-[140px]">{p.usuario_nome}</span>
                  <span class="text-[10px] font-bold uppercase tracking-wide px-1.5 py-0.5 rounded bg-white/70 border border-black/5">
                    {st.label}
                  </span>
                </button>
              {/each}
            </div>
          {/if}
        </div>

        <div>
          <p class="text-xs font-semibold uppercase tracking-wide text-gray-500 mb-1.5">Observações</p>
          {#if observacoes.length === 0}
            <span class="text-gray-400">—</span>
          {:else}
            <div class="flex flex-wrap gap-2">
              {#each observacoes as item, i}
                <button
                  type="button"
                  on:mouseenter={() => mostrarFotoHover(item)}
                  on:mouseleave={esconderFotoHover}
                  on:click={() => abrirObservacao(item)}
                  class="inline-flex items-center gap-1.5 px-3 py-1.5 rounded-lg text-xs sm:text-sm font-semibold text-white border shadow-sm transition-all hover:scale-[1.02] focus:outline-none focus:ring-2 focus:ring-offset-1 focus:ring-gray-400 {corAvaliador(item.usuario_nome, i)}"
                  title="Ver observação de {item.usuario_nome}"
                >
                  {#if item.usuario_foto}
                    <img src={item.usuario_foto} alt="" class="w-5 h-5 rounded-full object-cover border border-white/40" />
                  {:else}
                    <svg class="w-3.5 h-3.5 opacity-90" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M8 10h.01M12 10h.01M16 10h.01M9 16H5a2 2 0 01-2-2V6a2 2 0 012-2h14a2 2 0 012 2v8a2 2 0 01-2 2h-5l-5 5v-5z" />
                    </svg>
                  {/if}
                  <span class="truncate max-w-[160px]">{item.usuario_nome}</span>
                </button>
              {/each}
            </div>
          {/if}
        </div>
      </div>
    </div>
  </div>
</div>

{#if showNamoradoModal && jovem.namorado?.foto}
  <div
    class="fixed inset-0 bg-black/75 z-50 flex items-center justify-center p-4"
    on:click={fecharFotoNamorado}
    on:keydown={handleModalKeydown}
    role="dialog"
    aria-modal="true"
    aria-label="Foto ampliada do namorado"
    tabindex="-1"
  >
    <div class="relative max-w-lg w-full bg-white rounded-2xl shadow-2xl overflow-hidden" on:click|stopPropagation role="presentation">
      <div class="flex items-center justify-between p-4 border-b border-gray-200">
        <h3 class="text-lg font-bold text-gray-900 truncate">{jovem.namorado.nome || 'Namorado'}</h3>
        <button type="button" on:click={fecharFotoNamorado} class="w-10 h-10 rounded-full hover:bg-gray-100" aria-label="Fechar">✕</button>
      </div>
      <div class="p-4">
        <img src={jovem.namorado.foto} alt={jovem.namorado.nome || 'Namorado'} class="max-w-full max-h-[70vh] object-contain mx-auto rounded-lg" />
      </div>
    </div>
  </div>
{/if}

{#if fotoAvaliadorHover}
  <div
    class="fixed z-[60] pointer-events-none bottom-6 right-6 sm:bottom-8 sm:right-8"
    role="tooltip"
  >
    <div class="bg-white rounded-2xl shadow-2xl border border-gray-200 overflow-hidden w-44 sm:w-52">
      <div class="px-3 py-2 border-b border-gray-100 bg-gray-50">
        <p class="text-xs font-semibold text-gray-800 truncate">{fotoAvaliadorHover.nome}</p>
      </div>
      <div class="aspect-square bg-gray-100 flex items-center justify-center">
        {#if fotoAvaliadorHover.foto}
          <img src={fotoAvaliadorHover.foto} alt={fotoAvaliadorHover.nome} class="w-full h-full object-cover" />
        {:else}
          <div class="w-full h-full bg-gradient-to-br from-slate-400 to-slate-600 flex items-center justify-center">
            <span class="text-white text-4xl font-bold">{(fotoAvaliadorHover.nome || '?').charAt(0).toUpperCase()}</span>
          </div>
        {/if}
      </div>
    </div>
  </div>
{/if}

{#if fotoAvaliadorModal}
  <div
    class="fixed inset-0 bg-black/60 z-50 flex items-center justify-center p-4"
    on:click={fecharFotoAvaliador}
    on:keydown={handleModalKeydown}
    role="dialog"
    aria-modal="true"
    aria-label="Foto do avaliador"
    tabindex="-1"
  >
    <div
      class="relative w-full max-w-sm bg-white rounded-2xl shadow-2xl overflow-hidden border border-gray-100"
      on:click|stopPropagation
      role="presentation"
    >
      <div class="px-5 py-4 border-b border-gray-100 flex items-center justify-between gap-3">
        <h3 class="text-lg font-bold text-gray-900 truncate">{fotoAvaliadorModal.nome}</h3>
        <button type="button" on:click={fecharFotoAvaliador} class="w-10 h-10 rounded-full hover:bg-gray-100 flex-shrink-0" aria-label="Fechar">✕</button>
      </div>
      <div class="p-4">
        {#if fotoAvaliadorModal.foto}
          <img src={fotoAvaliadorModal.foto} alt={fotoAvaliadorModal.nome} class="w-full aspect-square object-cover rounded-xl shadow" />
        {:else}
          <div class="w-full aspect-square rounded-xl bg-gradient-to-br from-slate-400 to-slate-600 flex items-center justify-center">
            <span class="text-white text-6xl font-bold">{(fotoAvaliadorModal.nome || '?').charAt(0).toUpperCase()}</span>
          </div>
          <p class="text-center text-sm text-gray-500 mt-3">Este avaliador ainda não possui foto cadastrada.</p>
        {/if}
      </div>
    </div>
  </div>
{/if}

{#if observacaoModal}
  <div
    class="fixed inset-0 bg-black/60 z-50 flex items-center justify-center p-4"
    on:click={fecharObservacao}
    on:keydown={handleModalKeydown}
    role="dialog"
    aria-modal="true"
    aria-labelledby="obs-modal-title"
    tabindex="-1"
  >
    <div
      class="relative w-full max-w-md bg-white rounded-2xl shadow-2xl overflow-hidden border border-gray-100"
      on:click|stopPropagation
      role="presentation"
    >
      <div class="px-5 py-4 border-b border-gray-100 bg-gradient-to-r from-slate-50 to-gray-50">
        <div class="flex items-center gap-3">
          {#if observacaoModal.usuario_foto}
            <button
              type="button"
              class="flex-shrink-0"
              on:click={(e) => abrirFotoAvaliador(observacaoModal, e)}
              title="Ampliar foto"
            >
              <img src={observacaoModal.usuario_foto} alt={observacaoModal.usuario_nome} class="w-12 h-12 rounded-full object-cover border-2 border-white shadow" />
            </button>
          {/if}
          <div class="min-w-0">
            <p class="text-[11px] font-semibold uppercase tracking-wide text-gray-500">Observação</p>
            <h3 id="obs-modal-title" class="text-lg font-bold text-gray-900 mt-0.5 truncate">{observacaoModal.usuario_nome}</h3>
          </div>
        </div>
        {#if observacaoModal.tipo_aprovacao}
          {@const st = estiloStatus(observacaoModal.tipo_aprovacao)}
          <span class="inline-flex items-center gap-1.5 mt-2 text-[11px] font-bold uppercase tracking-wide px-2 py-0.5 rounded-md border {st.badge}">
            <span class="w-1.5 h-1.5 rounded-full {st.dot}"></span>
            {st.label}
          </span>
        {/if}
      </div>
      <div class="px-5 py-5">
        <p class="text-sm sm:text-base text-gray-800 leading-relaxed whitespace-pre-wrap">
          {observacaoModal.observacao}
        </p>
      </div>
      <div class="px-5 py-3 bg-gray-50 border-t border-gray-100 flex justify-end">
        <button
          type="button"
          on:click={fecharObservacao}
          class="px-4 py-2 text-sm font-medium rounded-lg bg-white border border-gray-300 text-gray-700 hover:bg-gray-100 transition-colors"
        >
          Fechar
        </button>
      </div>
    </div>
  </div>
{/if}
