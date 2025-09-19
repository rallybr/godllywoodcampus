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
  /** @param {string} id */
  async function fetchCondicaoById(id) {
    try {
      const { supabase } = await import('$lib/utils/supabase');
      const { data, error } = await supabase
        .from('jovens')
        .select('condicao, condicao_campus')
        .eq('id', id)
        .single();
      if (error) {
        console.error('Erro ao buscar condicao do jovem:', error);
        return;
      }
      if (data?.condicao) {
        condicao = data.condicao;
        // console.log('Condição carregada:', condicao);
      }
      if (data?.condicao_campus) {
        condicaoCampus = data.condicao_campus;
        console.log('Condição Campus carregada:', condicaoCampus);
        console.log('Estágio Campus mapeado:', condicaoParaEstagioMap.get(normalize(condicaoCampus)));
      }
    } catch (err) {
      console.error('Falha ao carregar Supabase ou buscar condicao:', err);
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

  // Mapeamento de condição -> estágio (1 a 6), com chaves normalizadas
  /** @type {Map<string, number>} */
  const condicaoParaEstagioMap = new Map([
    // Valores do formulário (como são salvos no banco)
    [normalize('jovem_batizado_es'), 1],
    [normalize('cpo'), 2],
    [normalize('colaborador'), 3],
    [normalize('obreiro'), 4],
    [normalize('iburd'), 5],
    [normalize('auxiliar_pastor'), 6],
    // Condições oficiais (nomes completos)
    [normalize('Batizado com o Espírito Santo'), 1],
    [normalize('CPO'), 2],
    [normalize('Colaborador'), 3],
    [normalize('Obreiro'), 4],
    [normalize('IBURD'), 5],
    [normalize('Auxiliar de Pastor'), 6],
    // Sinônimos/etapas por nome
    [normalize('Oleo'), 1],
    [normalize('Sal'), 2],
    [normalize('Luz'), 3],
    [normalize('Fogo'), 4],
    [normalize('Ouro'), 5],
    [normalize('Diamante'), 6]
  ]);

  // Estágio atual de acordo com a condição
  $: estagioAtual = condicaoParaEstagioMap.get(normalize(condicao)) || 0;
  
  // Estágio da condição do Campus (para destacar em laranja)
  $: estagioCampus = condicaoParaEstagioMap.get(normalize(condicaoCampus)) || 0;

  // Altura da barra preenchida (0% a 100%), ajustada para alinhar exatamente ao centro de cada círculo
  // Os valores foram calibrados visualmente para que a barra pare no centro do círculo correspondente
  const stageHeightsPct = [0, 15.5, 26, 43, 60, 77, 100]; // índice = estágio (0..6)
  $: alturaPreenchidaPct = stageHeightsPct[estagioAtual] ?? 0;

  // Lista de etapas com cor dinâmica (teal para concluído, laranja para condição do Campus, cinza para pendente)
  $: etapas = [
    { 
      id: 'diamante', 
      nome: 'Auxiliar de Pastor', 
      cor: estagioCampus === 6 ? 'orange' : (estagioAtual >= 6 ? 'teal' : 'gray'), 
      ordem: 6 
    },
    { 
      id: 'ouro', 
      nome: 'IBURD', 
      cor: estagioCampus === 5 ? 'orange' : (estagioAtual >= 5 ? 'teal' : 'gray'), 
      ordem: 5 
    },
    { 
      id: 'fogo', 
      nome: 'Obreiro', 
      cor: estagioCampus === 4 ? 'orange' : (estagioAtual >= 4 ? 'teal' : 'gray'), 
      ordem: 4 
    },
    { 
      id: 'luz', 
      nome: 'Colaborador', 
      cor: estagioCampus === 3 ? 'orange' : (estagioAtual >= 3 ? 'teal' : 'gray'), 
      ordem: 3 
    },
    { 
      id: 'sal', 
      nome: 'CPO', 
      cor: estagioCampus === 2 ? 'orange' : (estagioAtual >= 2 ? 'teal' : 'gray'), 
      ordem: 2 
    },
    { 
      id: 'oleo', 
      nome: 'Batizado com o E.S.', 
      cor: estagioCampus === 1 ? 'orange' : (estagioAtual >= 1 ? 'teal' : 'gray'), 
      ordem: 1 
    }
  ];
</script>

<div class="bg-gradient-to-r from-blue-600 via-purple-600 to-indigo-600 rounded-2xl shadow-2xl border border-white/10 p-8 sm:p-10 relative overflow-hidden min-h-[1000px] flex flex-col">
  <!-- Elementos decorativos de fundo -->
  <div class="absolute top-0 right-0 w-32 h-32 bg-white/5 rounded-full -translate-y-16 translate-x-16"></div>
  <div class="absolute bottom-0 left-0 w-24 h-24 bg-white/5 rounded-full translate-y-12 -translate-x-12"></div>
  
  <!-- Conteúdo do cabeçalho -->
  <div class="relative z-10">
    <div class="text-center mb-10">
      <div class="flex items-center justify-center space-x-4 mb-4">
        <!-- Ícone de progresso -->
        <div class="w-12 h-12 sm:w-16 sm:h-16 bg-white/20 rounded-2xl flex items-center justify-center backdrop-blur-sm">
          <svg class="w-6 h-6 sm:w-8 sm:h-8 text-white" fill="none" viewBox="0 0 24 24" stroke="currentColor">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 10V3L4 14h7v7l9-11h-7z" />
          </svg>
        </div>
        
        <!-- Título e descrição -->
        <div class="text-center">
          <h2 class="text-2xl sm:text-3xl font-bold text-white mb-2">Timeline de Progresso</h2>
        </div>
      </div>
    </div>
  </div>

  <!-- Timeline central -->
  <div class="w-full max-w-full overflow-x-auto relative z-10 flex-1 flex items-center justify-center">
    <div class="flex justify-center min-w-[320px]">
      <div class="relative">
      <!-- Barra de progresso vertical - 30px de largura, estendendo além dos círculos -->
      <div class="absolute left-1/2 transform -translate-x-1/2 w-6 sm:w-8 rounded-full bg-white/20 z-0 overflow-hidden backdrop-blur-sm" style="top: -24px; bottom: -24px; margin-left: -127px;">
        <!-- Barra de progresso preenchida (gradiente) - de baixo para cima usando bottom:0 -->
        <div 
          class="absolute left-0 bottom-0 w-full bg-gradient-to-t from-emerald-400 to-cyan-400 transition-all duration-700"
          style={`height: ${alturaPreenchidaPct}%`}
        ></div>
      </div>

      <!-- Círculos das etapas -->
      <div class="relative z-30 space-y-12 sm:space-y-16" style="margin-left: -36px;">
        {#each etapas as etapa, index}
          <div class="flex items-center">
            <!-- Círculo da etapa - sólido e opaco -->
            <div 
              class="w-10 h-10 sm:w-12 sm:h-12 rounded-full border-2 flex items-center justify-center text-xs sm:text-sm font-bold transition-all duration-500 relative z-40
                {etapa.cor === 'teal' ? 'bg-gradient-to-br from-emerald-400 to-cyan-400 border-emerald-300 text-white shadow-lg' : 
                 etapa.cor === 'orange' ? 'bg-gradient-to-br from-orange-400 to-orange-500 border-orange-300 text-white shadow-lg' : 
                 'bg-white/20 border-white/30 text-white/70 backdrop-blur-sm'}"
            >
              {etapa.ordem}
            </div>
            
            <!-- Nome da etapa -->
            <div class="ml-3 sm:ml-4">
              <div class="text-base sm:text-lg font-bold text-white uppercase tracking-wide">
                {etapa.nome}
              </div>
            </div>
          </div>
        {/each}
      </div>
      </div>
    </div>
  </div>

  <!-- Legenda -->
  <div class="mt-12 pt-6 border-t border-white/20 relative z-10">
    <div class="flex items-center justify-center space-x-6 text-sm flex-wrap">
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
