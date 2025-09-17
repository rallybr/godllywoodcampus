<script>
  import { onMount } from 'svelte';
  // Condição atual do jovem (pode vir via prop ou será buscada no banco)
  export let condicao = '';
  // Opcional: quando informado, o componente buscará a condição direto do Supabase
  export let jovemId = null;
  let lastFetchedId = null;
  async function fetchCondicaoById(id) {
    try {
      const { supabase } = await import('$lib/utils/supabase');
      const { data, error } = await supabase
        .from('jovens')
        .select('condicao')
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
  const condicaoParaEstagioMap = new Map([
    // Condições oficiais (tabela)
    [normalize('Batizado com o Espírito Santo'), 1], // Óleo
    [normalize('CPO'), 2], // Sal
    [normalize('Colaborador'), 3], // Luz
    [normalize('Obreiro'), 4], // Fogo
    [normalize('IBURD'), 5], // Ouro
    [normalize('Pastor'), 6], // Diamante
    // Sinônimos/etapas por nome
    [normalize('Óleo'), 1],
    [normalize('Oleo'), 1],
    [normalize('Sal'), 2],
    [normalize('Luz'), 3],
    [normalize('Fogo'), 4],
    [normalize('Ouro'), 5],
    [normalize('Diamante'), 6]
  ]);

  // Estágio atual de acordo com a condição
  $: estagioAtual = condicaoParaEstagioMap.get(normalize(condicao)) || 0;

  // Altura da barra preenchida (0% a 100%), ajustada para alinhar exatamente ao centro de cada círculo
  // Os valores foram calibrados visualmente para que a barra pare no centro do círculo correspondente
  const stageHeightsPct = [0, 15.5, 26, 43, 60, 77, 100]; // índice = estágio (0..6)
  $: alturaPreenchidaPct = stageHeightsPct[estagioAtual] ?? 0;

  // Lista de etapas com cor dinâmica (teal para concluído, cinza para pendente)
  $: etapas = [
    { id: 'diamante', nome: 'DIAMANTE', cor: estagioAtual >= 6 ? 'teal' : 'gray', ordem: 6 },
    { id: 'ouro', nome: 'OURO', cor: estagioAtual >= 5 ? 'teal' : 'gray', ordem: 5 },
    { id: 'fogo', nome: 'FOGO', cor: estagioAtual >= 4 ? 'teal' : 'gray', ordem: 4 },
    { id: 'luz', nome: 'LUZ', cor: estagioAtual >= 3 ? 'teal' : 'gray', ordem: 3 },
    { id: 'sal', nome: 'SAL', cor: estagioAtual >= 2 ? 'teal' : 'gray', ordem: 2 },
    { id: 'oleo', nome: 'ÓLEO', cor: estagioAtual >= 1 ? 'teal' : 'gray', ordem: 1 }
  ];
</script>

<div class="bg-white rounded-xl shadow-lg border border-gray-200 p-8">
  <div class="text-center mb-8">
    <h2 class="text-2xl font-bold text-gray-900 mb-2">Timeline de Progresso</h2>
    <p class="text-gray-600">Acompanhe a jornada espiritual dos jovens</p>
  </div>

  <!-- Timeline central -->
  <div class="flex justify-center">
    <div class="relative">
      <!-- Barra de progresso vertical - 30px de largura, estendendo além dos círculos -->
      <div class="absolute left-1/2 transform -translate-x-1/2 w-8 rounded-full bg-gray-200 z-0 overflow-hidden" style="top: -24px; bottom: -24px; margin-left: -127px;">
        <!-- Barra de progresso preenchida (teal) - de baixo para cima usando bottom:0 -->
        <div 
          class="absolute left-0 bottom-0 w-full bg-teal-500 transition-all duration-700"
          style={`height: ${alturaPreenchidaPct}%`}
        ></div>
      </div>

      <!-- Círculos das etapas -->
      <div class="relative z-30 space-y-16" style="margin-left: -140px;">
        {#each etapas as etapa, index}
          <div class="flex items-center">
            <!-- Círculo da etapa - sólido e opaco -->
            <div 
              class="w-12 h-12 rounded-full border-2 flex items-center justify-center text-sm font-bold transition-all duration-500 relative z-40
                {etapa.cor === 'teal' ? 'bg-teal-500 border-teal-600 text-white' : 'bg-gray-200 border-gray-400 text-gray-600'}"
            >
              {etapa.ordem}
            </div>
            
            <!-- Nome da etapa -->
            <div class="ml-4">
              <div class="text-lg font-bold text-gray-800 uppercase tracking-wide">
                {etapa.nome}
              </div>
            </div>
          </div>
        {/each}
      </div>
    </div>
  </div>

  <!-- Legenda -->
  <div class="mt-12 pt-6 border-t border-gray-200">
    <div class="flex items-center justify-center space-x-8 text-sm">
      <div class="flex items-center">
        <div class="w-4 h-4 bg-teal-500 rounded-full mr-2"></div>
        <span class="text-gray-600">Etapas Concluídas</span>
      </div>
      <div class="flex items-center">
        <div class="w-4 h-4 bg-gray-200 border border-gray-400 rounded-full mr-2"></div>
        <span class="text-gray-600">Etapas Pendentes</span>
      </div>
    </div>
  </div>
</div>
