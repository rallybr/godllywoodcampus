<script>
  import { onMount } from 'svelte';
  // Condição atual do jovem (pode vir via prop ou será buscada no banco)
  export let condicao = '';
  // Condição do Campus (para destacar em laranja)
  let condicaoCampus = '';
  // Opcional: quando informado, o componente buscará a condição direto do Supabase
  /** @type {string | null} */
  export let jovemId = null;
  /** @type {string | null} */
  let lastFetchedId = null;
  /** @type {boolean} */
  let dadosCarregados = false;
  /** @param {string} id */
  async function fetchCondicaoById(id) {
    dadosCarregados = false;
    try {
      const { supabase } = await import('$lib/utils/supabase');
      const { data, error } = await supabase
        .from('jovens')
        .select('condicao, condicao_campus')
        .eq('id', id)
        .single();
      if (error) {
        console.error('Erro ao buscar condicao do jovem:', error);
        dadosCarregados = true;
        return;
      }
      condicao = data?.condicao ?? '';
      condicaoCampus = data?.condicao_campus ?? '';
      dadosCarregados = true;
    } catch (err) {
      console.error('Falha ao carregar Supabase ou buscar condicao:', err);
      dadosCarregados = true;
    }
  }

  onMount(async () => {
    if (jovemId) {
      lastFetchedId = jovemId;
      await fetchCondicaoById(jovemId);
    }
  });

  $: if (jovemId && jovemId !== lastFetchedId) {
    lastFetchedId = jovemId;
    fetchCondicaoById(jovemId);
  }

  // Normalizador de texto para comparação robusta
  /** @param {string} str */
  function normalize(str) {
    if (!str) return '';
    return str
      .toString()
      .trim()
      .toLowerCase()
      .normalize('NFD')
      .replace(/\p{Diacritic}/gu, '')
      .replace(/\s+/g, ' ');
  }

  // Mapeamento de condição -> estágio (1 a 8): JOVEM, CPO, COL, OBR, CAND, NAM, CURSO, ESP (igual ao relatório de condição)
  /** @type {Map<string, number>} */
  const condicaoParaEstagioMap = new Map([
    [normalize('jovem_batizado_es'), 1],
    [normalize('jovem'), 1],
    [normalize('cpo'), 2],
    [normalize('colaborador'), 3],
    [normalize('obreiro'), 4],
    [normalize('iburd'), 5],
    [normalize('namorada'), 6],
    [normalize('noiva'), 6],
    [normalize('curso'), 7],
    [normalize('auxiliar_pastor'), 8],
    [normalize('Batizado com o Espírito Santo'), 1],
    [normalize('CPO'), 2],
    [normalize('Colaborador'), 3],
    [normalize('Obreiro'), 4],
    [normalize('IBURD'), 5],
    [normalize('Candidata do Altar'), 5],
    [normalize('Namorada de Pastor'), 6],
    [normalize('Noiva de Pastor'), 6],
    [normalize('Curso'), 7],
    [normalize('Auxiliar de Pastor'), 8],
    [normalize('Esposa de Pastor'), 8]
  ]);

  // Estágio atual de acordo com a condição (1 a 8)
  $: estagioAtual = condicaoParaEstagioMap.get(normalize(condicao)) || 0;
  
  // Estágio da condição do Campus (para destacar em laranja)
  $: estagioCampus = condicaoParaEstagioMap.get(normalize(condicaoCampus)) || 0;

  // Altura da barra preenchida (0% a 100%) para 8 estágios – alinhada ao centro de cada círculo
  const stageHeightsPct = [0, 8, 20, 32, 44, 56, 68, 82, 100]; // índice = estágio (0..8)
  $: alturaPreenchidaPct = Math.max(0, stageHeightsPct[estagioAtual] ?? 0);

  // Lista de etapas (mesmas opções do relatório de condição): JOVEM, CPO, COL, OBR, CAND, NAM, CURSO, ESP
  $: etapas = [
    { id: 8, label: 'ESP', nome: 'Esposa de Pastor', cor: estagioCampus === 8 ? 'orange' : (estagioAtual >= 8 ? 'teal' : 'gray'), ordem: 8 },
    { id: 7, label: 'CURSO', nome: 'Curso', cor: estagioCampus === 7 ? 'orange' : (estagioAtual >= 7 ? 'teal' : 'gray'), ordem: 7 },
    { id: 6, label: 'NAM', nome: 'Namorada de Pastor', cor: estagioCampus === 6 ? 'orange' : (estagioAtual >= 6 ? 'teal' : 'gray'), ordem: 6 },
    { id: 5, label: 'CAND', nome: 'Candidata do Altar', cor: estagioCampus === 5 ? 'orange' : (estagioAtual >= 5 ? 'teal' : 'gray'), ordem: 5 },
    { id: 4, label: 'OBR', nome: 'Obreiro', cor: estagioCampus === 4 ? 'orange' : (estagioAtual >= 4 ? 'teal' : 'gray'), ordem: 4 },
    { id: 3, label: 'COL', nome: 'Colaborador', cor: estagioCampus === 3 ? 'orange' : (estagioAtual >= 3 ? 'teal' : 'gray'), ordem: 3 },
    { id: 2, label: 'CPO', nome: 'CPO', cor: estagioCampus === 2 ? 'orange' : (estagioAtual >= 2 ? 'teal' : 'gray'), ordem: 2 },
    { id: 1, label: 'JOVEM', nome: 'Jovem', cor: estagioCampus === 1 ? 'orange' : (estagioAtual >= 1 ? 'teal' : 'gray'), ordem: 1 }
  ];
</script>

<div class="bg-gradient-to-r from-blue-600 via-purple-600 to-indigo-600 rounded-2xl shadow-2xl border border-white/10 p-4 sm:p-6 md:p-8 lg:p-10 relative overflow-hidden min-h-[800px] sm:min-h-[900px] md:min-h-[1000px] flex flex-col">
  <!-- Elementos decorativos de fundo -->
  <div class="absolute top-0 right-0 w-32 h-32 bg-white/5 rounded-full -translate-y-16 translate-x-16"></div>
  <div class="absolute bottom-0 left-0 w-24 h-24 bg-white/5 rounded-full translate-y-12 -translate-x-12"></div>
  
  <!-- Aviso quando não há condição cadastrada -->
  {#if jovemId && dadosCarregados && !condicao}
    <div class="relative z-10 mb-4 mx-auto max-w-md rounded-lg bg-amber-500/20 border border-amber-400/50 px-4 py-3 text-center">
      <p class="text-sm text-amber-100">Nenhuma condição cadastrada para este jovem. Cadastre a condição na ficha do jovem para a barra de progresso aparecer.</p>
    </div>
  {/if}

  <!-- Conteúdo do cabeçalho -->
  <div class="relative z-10">
    <div class="text-center mb-6 sm:mb-8 md:mb-10">
      <div class="flex items-center justify-center space-x-2 sm:space-x-3 md:space-x-4 mb-3 sm:mb-4">
        <!-- Ícone de progresso -->
        <div class="w-10 h-10 sm:w-12 sm:h-12 md:w-14 md:h-14 lg:w-16 lg:h-16 bg-white/20 rounded-2xl flex items-center justify-center backdrop-blur-sm">
          <svg class="w-5 h-5 sm:w-6 sm:h-6 md:w-7 md:h-7 lg:w-8 lg:h-8 text-white" fill="none" viewBox="0 0 24 24" stroke="currentColor">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 10V3L4 14h7v7l9-11h-7z" />
          </svg>
        </div>
        
        <!-- Título e descrição -->
        <div class="text-center">
          <h2 class="text-lg sm:text-xl md:text-2xl lg:text-3xl font-bold text-white mb-2">Timeline de Progresso</h2>
        </div>
      </div>
    </div>
  </div>

  <!-- Timeline central -->
  <div class="w-full max-w-full overflow-x-auto relative z-10 flex-1 flex items-center justify-center px-2 sm:px-4">
    <div class="flex justify-center min-w-[280px] sm:min-w-[320px]">
      <div class="relative">
      <!-- Barra de progresso vertical - alinhada à esquerda para que os círculos fiquem sobrepostos -->
      <div class="absolute w-6 sm:w-8 rounded-full bg-white/20 z-0 overflow-hidden backdrop-blur-sm" style="left: -38px; top: -24px; bottom: -24px;">
        <!-- Barra de progresso preenchida (gradiente) - de baixo para cima usando bottom:0 -->
        <div 
          class="absolute left-0 bottom-0 w-full bg-gradient-to-t from-emerald-400 to-cyan-400 transition-all duration-700"
          style={`height: ${alturaPreenchidaPct}%`}
        ></div>
      </div>

      <!-- Círculos das etapas -->
      <div class="relative z-30 space-y-12 sm:space-y-16" style="margin-left: -45px;">
        {#each etapas as etapa, index}
          <div class="flex flex-col sm:flex-row items-start sm:items-center">
            <!-- Círculo da etapa - sólido e opaco, alinhado à esquerda -->
            <div 
              class="w-10 h-10 sm:w-12 sm:h-12 rounded-full border-2 flex items-center justify-center text-xs sm:text-sm font-bold transition-all duration-500 relative z-40
                {etapa.cor === 'teal' ? 'bg-gradient-to-br from-emerald-400 to-cyan-400 border-emerald-300 text-white shadow-lg' : 
                 etapa.cor === 'orange' ? 'bg-gradient-to-br from-orange-400 to-orange-500 border-orange-300 text-white shadow-lg' : 
                 'bg-white/20 border-white/30 text-white/70 backdrop-blur-sm'}"
            >
              {etapa.ordem}
            </div>
            
            <!-- Label da etapa (mesmo padrão do relatório de condição: JOVEM, CPO, COL, OBR, CAND, NAM, CURSO, ESP) -->
            <div class="sm:ml-3 sm:ml-4 ml-16 flex items-center" style="margin-top: -30px;">
              <div class="text-sm sm:text-base lg:text-lg font-bold text-white uppercase tracking-wide text-left">
                {etapa.label}
              </div>
            </div>
          </div>
        {/each}
      </div>
      </div>
    </div>
  </div>

  <!-- Legenda -->
  <div class="mt-8 sm:mt-10 md:mt-12 pt-4 sm:pt-5 md:pt-6 border-t border-white/20 relative z-10">
    <div class="flex items-center justify-center space-x-3 sm:space-x-4 md:space-x-6 text-xs sm:text-sm flex-wrap">
      <div class="flex items-center">
        <div class="w-4 h-4 bg-gradient-to-br from-emerald-400 to-cyan-400 rounded-full mr-2 shadow-sm"></div>
        <span class="text-blue-100 font-medium">Etapas Concluídas</span>
      </div>
      <div class="flex items-center">
        <div class="w-4 h-4 bg-gradient-to-br from-orange-400 to-orange-500 rounded-full mr-2 shadow-sm"></div>
        <span class="text-blue-100 font-medium">Condição no Campus</span>
      </div>
      <div class="flex items-center">
        <div class="w-4 h-4 bg-white/20 border border-white/30 rounded-full mr-2 backdrop-blur-sm"></div>
        <span class="text-blue-100 font-medium">Etapas Pendentes</span>
      </div>
    </div>
  </div>
</div>
