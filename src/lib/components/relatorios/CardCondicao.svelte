<script>
  export let jovem;

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

  // Mapeamento de condição -> estágio (1 a 7): JOVEM, CPO, COL, OBR, CAND, NAM, ESP
  const condicaoParaEstagioMap = new Map([
    [normalize('jovem_batizado_es'), 1],
    [normalize('cpo'), 2],
    [normalize('colaborador'), 3],
    [normalize('obreiro'), 4],
    [normalize('iburd'), 5],
    [normalize('namorada'), 6],
    [normalize('auxiliar_pastor'), 7],
    [normalize('Batizado com o Espírito Santo'), 1],
    [normalize('CPO'), 2],
    [normalize('Colaborador'), 3],
    [normalize('Obreiro'), 4],
    [normalize('IBURD'), 5],
    [normalize('Candidata do Altar'), 5],
    [normalize('Namorada de Pastor'), 6],
    [normalize('Auxiliar de Pastor'), 7],
    [normalize('Esposa de Pastor'), 7]
  ]);

  // Estágio atual de acordo com a condição
  $: estagioAtual = condicaoParaEstagioMap.get(normalize(jovem.condicao)) || 0;
  
  // Estágio da condição do Campus (se existir)
  $: estagioCampus = jovem.condicao_campus 
    ? condicaoParaEstagioMap.get(normalize(jovem.condicao_campus)) || 0 
    : 0;
  
  // Posições proporcionais dos 7 círculos (0% a 100% distribuídos uniformemente)
  const posicoesCirculos = {
    1: 5,       // JOVEM
    2: 20,      // CPO
    3: 35,      // COL
    4: 50,      // OBR
    5: 65,      // CAND
    6: 80,      // NAM
    7: 100      // ESP
  };
  
  // Se for a última condição (ESP = 7), a barra vai até 100%; senão para no círculo correspondente
  $: larguraBarraProgresso = estagioAtual > 0 
    ? (estagioAtual === 7 ? 100 : posicoesCirculos[estagioAtual] || 0)
    : 0;

  // Etapas da timeline (7 estágios, distribuídos com flex)
  const etapas = [
    { id: 1, label: 'JOVEM', nome: 'Jovem' },
    { id: 2, label: 'CPO', nome: 'CPO' },
    { id: 3, label: 'COL', nome: 'Colaborador' },
    { id: 4, label: 'OBR', nome: 'Obreiro' },
    { id: 5, label: 'CAND', nome: 'Candidata do Altar' },
    { id: 6, label: 'NAM', nome: 'Namorada de Pastor' },
    { id: 7, label: 'ESP', nome: 'Esposa de Pastor' }
  ];

  // Função para determinar a cor de cada ponto
  function getCorPonto(etapaId) {
    // Se é a condição do Campus, destacar em laranja (único caso de laranja)
    if (estagioCampus === etapaId && estagioCampus > 0) {
      return 'orange'; // Laranja apenas para condição do Campus
    }
    // Se já passou por essa etapa (incluindo a atual, se não for Campus)
    else if (estagioAtual >= etapaId && estagioAtual > 0) {
      return 'progress'; // Mesma cor da barra de progresso (#00a8ff)
    }
    // Se ainda não chegou nessa etapa
    else {
      return 'gray'; // Cinza para etapas pendentes
    }
  }
</script>

<div class="card-condicao bg-white rounded-lg shadow-lg overflow-hidden">
  <!-- Foto com bandeira no canto superior direito -->
  <div class="relative mb-3">
    <a href="/jovens/{jovem.id}" class="block w-full h-[550px] relative cursor-pointer">
      {#if jovem.foto}
        <img
          src={jovem.foto}
          alt={jovem.nome_completo}
          class="w-full h-full object-cover"
        />
      {:else}
        <div class="w-full h-full bg-gradient-to-br from-blue-500 to-purple-600 flex items-center justify-center">
          <span class="text-white font-bold text-4xl">
            {jovem.nome_completo?.charAt(0) || 'J'}
          </span>
        </div>
      {/if}
      
      <!-- Bandeira do estado no canto superior direito -->
      {#if jovem.estado?.bandeira}
        <div class="absolute top-2 right-2 w-[84px] h-[60px] rounded overflow-hidden border border-gray-300 shadow-md z-10">
          <img 
            src={jovem.estado.bandeira} 
            alt={jovem.estado?.sigla || 'UF'} 
            class="w-full h-full object-cover"
          />
        </div>
      {/if}

      <!-- Miniatura do pastor (namorado) – abaixo da bandeira, à direita, sobre a foto -->
      {#if jovem.namorado && (jovem.namorado.nome || jovem.namorado.foto || jovem.namorado.idade != null)}
        <div class="absolute right-2 top-[4.5rem] z-10 w-20 rounded-lg overflow-hidden border border-white/90 shadow-lg bg-white/95 backdrop-blur-sm namorado-mini">
          {#if jovem.namorado.foto}
            <img
              src={jovem.namorado.foto}
              alt={jovem.namorado.nome || 'Namorado'}
              class="w-full h-14 object-cover"
            />
          {:else}
            <div class="w-full h-14 bg-gradient-to-br from-rose-300 to-purple-300 flex items-center justify-center">
              <span class="text-white font-bold text-lg">{jovem.namorado.nome?.charAt(0) || 'N'}</span>
            </div>
          {/if}
          <div class="px-1.5 py-1 bg-white/95 backdrop-blur-sm">
            <p class="text-[10px] font-bold text-gray-800 truncate leading-tight" title={jovem.namorado.nome}>{jovem.namorado.nome || '–'}</p>
            {#if jovem.namorado.idade != null}
              <p class="text-[9px] text-gray-600">{jovem.namorado.idade} anos</p>
            {/if}
          </div>
        </div>
      {/if}
    </a>
  </div>
  
  <!-- Conteúdo abaixo da foto -->
  <div class="px-4 pb-4">

  <!-- Nome do jovem -->
  <div class="text-center mb-2">
    <h3 class="text-base font-bold text-gray-900 leading-tight uppercase">
      {jovem.nome_completo}
    </h3>
  </div>

  <!-- Estado -->
  <div class="text-center mb-4">
    <p class="text-xs font-bold text-gray-900 uppercase">
      ESTADO: {jovem.estado?.nome || jovem.estado?.sigla || 'N/A'}
    </p>
  </div>

    <!-- Timeline horizontal -->
    <div class="mt-4">
      <!-- Container da timeline com linha vermelha -->
      <div class="relative px-1">
        <!-- Background cinza escuro semi-transparente (mais alto que a barra) -->
        <div class="absolute top-4 left-1 right-1 h-6 rounded-full" style="background-color: rgba(51, 51, 51, 0.2);"></div>
        <!-- Container da barra de progresso (mesma largura do background) -->
        <div class="absolute top-5 left-1 right-1 h-4 z-10 overflow-hidden rounded-full">
          <!-- Linha de progresso horizontal - para exatamente no círculo da condição atual -->
          <div 
            class="h-full rounded-full" 
            style="background-color: #00a8ff; width: {larguraBarraProgresso}%;"
          ></div>
        </div>
        
        <!-- Pontos da timeline sobre a linha -->
        <div class="flex justify-between items-start relative pr-[10px]">
          {#each etapas as etapa}
            <div class="flex flex-col items-center flex-1 relative">
              <!-- Ponto sobre a linha -->
              <div class="relative z-10" style="margin-top: 16px;">
                <div 
                  class="w-7 h-7 rounded-full transition-all duration-300 border-2 border-white shadow-sm
                    {getCorPonto(etapa.id) === 'orange' ? 'bg-orange-500' :
                     getCorPonto(etapa.id) === 'progress' ? '' :
                     'bg-gray-300'}"
                  style={getCorPonto(etapa.id) === 'progress' ? 'background-color: #00a8ff;' : ''}
                ></div>
              </div>
              
              <!-- Indicador triangular azul acima da label (apontando para cima) -->
              <div 
                class="w-0 h-0 border-l-[5px] border-r-[5px] border-b-[6px] border-transparent border-b-blue-500 mt-0.5"
              ></div>
              
              <!-- Label -->
              <span class="text-[9px] font-bold text-gray-800 uppercase text-center leading-tight mt-0.5">
                {etapa.label}
              </span>
            </div>
          {/each}
        </div>
      </div>
    </div>

    <!-- Descrição curta -->
    {#if jovem.descricao_curta}
      <div class="mt-4 pt-4 border-t border-gray-200">
        <p class="text-base font-bold text-gray-600 leading-relaxed text-left">
          {jovem.descricao_curta}
        </p>
      </div>
    {/if}
  </div>
</div>

<style>
  .card-condicao {
    min-height: 360px;
    max-width: 100%;
  }
  .namorado-mini {
    min-width: 5rem;
  }
</style>

