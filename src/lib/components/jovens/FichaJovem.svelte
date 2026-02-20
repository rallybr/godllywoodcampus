<script>
  import { onMount } from 'svelte';
  import { loadAvaliacoesByJovem } from '$lib/stores/avaliacoes';
  import { format, parseISO } from 'date-fns';
  import { ptBR } from 'date-fns/locale';

  // Tipos removidos dos exports para compatibilidade no build SSR
  // (mantemos o restante em TS normalmente)
  export let jovem;
  export let showAvaliacoes = true;
  export let compact = false;

  let avaliacoes = [];
  let loadingAvaliacoes = false;

  const condicoesMap = {
    auxiliar_pastor: 'Esposa de Pastor',
    iburd: 'Candidata do Altar',
    namorada: 'Namorada de Pastor',
    noiva: 'Noiva de Pastor',
    obreiro: 'Obreiro',
    colaborador: 'Colaborador',
    cpo: 'CPO',
    jovem_batizado_es: 'Jovem'
  };

  // Função para formatar data
  function formatarData(data) {
    if (!data) return 'Não informado';
    try {
      return format(parseISO(data), 'dd/MM/yyyy', { locale: ptBR });
    } catch {
      return data;
    }
  }

  // Função para formatar data de cadastro
  function formatarDataCadastro(data) {
    if (!data) return 'Não informado';
    try {
      return format(parseISO(data), "dd/MM/yyyy 'às' HH:mm", { locale: ptBR });
    } catch {
      return data;
    }
  }

  // Função para formatar telefone
  function formatarTelefone(telefone) {
    if (!telefone) return 'Não informado';
    // Remove caracteres não numéricos
    const numeros = telefone.replace(/\D/g, '');
    // Formata como (XX) XXXXX-XXXX ou (XX) XXXX-XXXX
    if (numeros.length === 11) {
      return `(${numeros.slice(0, 2)}) ${numeros.slice(2, 7)}-${numeros.slice(7)}`;
    } else if (numeros.length === 10) {
      return `(${numeros.slice(0, 2)}) ${numeros.slice(2, 6)}-${numeros.slice(6)}`;
    }
    return telefone;
  }

  // Função para obter status de aprovação
  function getStatusAprovacao(aprovado) {
    switch (aprovado) {
      case 'aprovado':
        return { text: 'Aprovado', class: 'bg-green-100 text-green-800 border-green-200' };
      case 'pre_aprovado':
        return { text: 'Pré-aprovado', class: 'bg-yellow-100 text-yellow-800 border-yellow-200' };
      case 'reprovado':
        return { text: 'Reprovado', class: 'bg-red-100 text-red-800 border-red-200' };
      default:
        return { text: 'Pendente', class: 'bg-gray-100 text-gray-800 border-gray-200' };
    }
  }

  // Função para obter média das avaliações
  function getMediaAvaliacoes() {
    if (!avaliacoes || avaliacoes.length === 0) return null;
    const soma = avaliacoes.reduce((acc, av) => acc + (av.nota || 0), 0);
    return (soma / avaliacoes.length).toFixed(1);
  }

  // Carregar avaliações se necessário
  onMount(async () => {
    if (showAvaliacoes && jovem?.id) {
      loadingAvaliacoes = true;
      try {
        const data = await loadAvaliacoesByJovem(jovem.id);
        avaliacoes = data || [];
      } catch (error) {
        console.error('Erro ao carregar avaliações:', error);
      } finally {
        loadingAvaliacoes = false;
      }
    }
  });

  // Reagir a mudanças no jovem
  $: if (jovem?.id && showAvaliacoes) {
    loadAvaliacoesByJovem(jovem.id).then(data => {
      avaliacoes = data || [];
    });
  }
</script>

<div class="max-w-4xl mx-auto bg-white rounded-2xl shadow-2xl overflow-hidden">
  <!-- Header com nome e informações básicas -->
  <div class="bg-gradient-to-r from-blue-600 via-blue-700 to-indigo-800 text-white p-8">
    <div class="flex items-start justify-between">
      <div class="flex-1">
        <h1 class="text-3xl font-bold mb-2">{jovem.nome_completo}</h1>
        <div class="flex items-center space-x-4 text-blue-100">
          <div class="flex items-center space-x-2">
            <svg class="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M17.657 16.657L13.414 20.9a1.998 1.998 0 01-2.827 0l-4.244-4.243a8 8 0 1111.314 0z" />
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 11a3 3 0 11-6 0 3 3 0 016 0z" />
            </svg>
            <span class="font-semibold">{jovem.estado?.nome || 'N/A'} • {jovem.igreja?.nome || 'N/A'}</span>
          </div>
          <div class="flex items-center space-x-2">
            <svg class="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M8 7V3m8 4V3m-9 8h10M5 21h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v12a2 2 0 002 2z" />
            </svg>
            <span class="font-semibold">Cadastrado em {formatarDataCadastro(jovem.data_cadastro)}</span>
          </div>
        </div>
      </div>
      
      <!-- Status de aprovação -->
      <div class="text-right">
        <span class="inline-flex items-center px-4 py-2 rounded-full text-sm font-semibold border-2 border-white/20 {getStatusAprovacao(jovem.aprovado).class}">
          {getStatusAprovacao(jovem.aprovado).text}
        </span>
        {#if avaliacoes.length > 0}
          <div class="mt-2 text-blue-100">
            <span class="text-sm">Média: {getMediaAvaliacoes()}</span>
          </div>
        {/if}
      </div>
    </div>
  </div>

  <div class="p-8">
    <div class="grid grid-cols-1 lg:grid-cols-3 gap-8">
      <!-- Coluna esquerda - Foto e dados pessoais -->
      <div class="space-y-6">
        <!-- Foto do jovem -->
        <div class="text-center">
          <div class="w-32 h-32 mx-auto rounded-2xl overflow-hidden border-4 border-gray-200 shadow-lg">
            {#if jovem.foto}
              <img
                class="w-full h-full object-cover"
                src={jovem.foto}
                alt={jovem.nome_completo}
              />
            {:else}
              <div class="w-full h-full bg-gradient-to-br from-blue-500 to-purple-600 flex items-center justify-center">
                <span class="text-white font-bold text-4xl">
                  {jovem.nome_completo?.charAt(0) || 'J'}
                </span>
              </div>
            {/if}
          </div>
        </div>

        <!-- Dados Pessoais -->
        <div class="bg-gray-50 rounded-xl p-6">
          <h3 class="text-lg font-bold text-gray-900 mb-4 flex items-center">
            <svg class="w-5 h-5 mr-2 text-blue-600" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M16 7a4 4 0 11-8 0 4 4 0 018 0zM12 14a7 7 0 00-7 7h14a7 7 0 00-7-7z" />
            </svg>
            Dados Pessoais
          </h3>
          <div class="space-y-3">
            <div class="flex justify-between">
              <span class="text-sm font-medium text-gray-600">WhatsApp:</span>
              <span class="text-sm font-semibold text-gray-900">{formatarTelefone(jovem.whatsapp)}</span>
            </div>
            <div class="flex justify-between">
              <span class="text-sm font-medium text-gray-600">Idade:</span>
              <span class="text-sm font-semibold text-gray-900">{jovem.idade || 0} anos</span>
            </div>
            <div class="flex justify-between">
              <span class="text-sm font-medium text-gray-600">Data de Nascimento:</span>
              <span class="text-sm font-semibold text-gray-900">{formatarData(jovem.data_nasc)}</span>
            </div>
            <div class="flex justify-between">
              <span class="text-sm font-medium text-gray-600">Estado Civil:</span>
              <span class="text-sm font-semibold text-gray-900">{jovem.estado_civil || 'Não informado'}</span>
            </div>
            <div class="flex justify-between">
              <span class="text-sm font-medium text-gray-600">Namora:</span>
              <span class="text-sm font-semibold text-gray-900">{jovem.namora ? 'Sim' : 'Não'}</span>
            </div>
            <div class="flex justify-between">
              <span class="text-sm font-medium text-gray-600">Tem Filho:</span>
              <span class="text-sm font-semibold text-gray-900">{jovem.tem_filho ? 'Sim' : 'Não'}</span>
            </div>
          </div>
        </div>

        <!-- Informações Profissionais -->
        <div class="bg-gray-50 rounded-xl p-6">
          <h3 class="text-lg font-bold text-gray-900 mb-4 flex items-center">
            <svg class="w-5 h-5 mr-2 text-green-600" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M21 13.255A23.931 23.931 0 0112 15c-3.183 0-6.22-.62-9-1.745M16 6V4a2 2 0 00-2-2h-4a2 2 0 00-2-2v2m8 0V6a2 2 0 012 2v6a2 2 0 01-2 2H6a2 2 0 01-2-2V8a2 2 0 012-2V6" />
            </svg>
            Informações Profissionais
          </h3>
          <div class="space-y-3">
            <div class="flex justify-between">
              <span class="text-sm font-medium text-gray-600">Trabalha:</span>
              <span class="text-sm font-semibold text-gray-900">{jovem.trabalha ? 'Sim' : 'Não'}</span>
            </div>
            {#if jovem.trabalha}
              <div class="flex justify-between">
                <span class="text-sm font-medium text-gray-600">Profissão:</span>
                <span class="text-sm font-semibold text-gray-900">{jovem.local_trabalho || 'Não informado'}</span>
              </div>
            {/if}
            <div class="flex justify-between">
              <span class="text-sm font-medium text-gray-600">Escolaridade:</span>
              <span class="text-sm font-semibold text-gray-900">{jovem.escolaridade || 'Não informado'}</span>
            </div>
            <div class="flex justify-between">
              <span class="text-sm font-medium text-gray-600">Formação:</span>
              <span class="text-sm font-semibold text-gray-900">{jovem.formacao || 'Não informado'}</span>
            </div>
            <div class="flex justify-between">
              <span class="text-sm font-medium text-gray-600">Tem Dívidas:</span>
              <span class="text-sm font-semibold text-gray-900">{jovem.tem_dividas ? 'Sim' : 'Não'}</span>
            </div>
            {#if jovem.tem_dividas && jovem.valor_divida}
              <div class="flex justify-between">
                <span class="text-sm font-medium text-gray-600">Valor da Dívida:</span>
                <span class="text-sm font-semibold text-gray-900">R$ {jovem.valor_divida}</span>
              </div>
            {/if}
          </div>
        </div>
      </div>

      <!-- Coluna central - Informações Espirituais -->
      <div class="space-y-6">
        <!-- Informações Espirituais -->
        <div class="bg-gradient-to-br from-purple-50 to-indigo-50 rounded-xl p-6 border border-purple-200">
          <h3 class="text-lg font-bold text-gray-900 mb-4 flex items-center">
            <svg class="w-5 h-5 mr-2 text-purple-600" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 21V5a2 2 0 00-2-2H7a2 2 0 00-2 2v16m14 0h2m-2 0h-5m-9 0H3m2 0h5M9 7h1m-1 4h1m4-4h1m-1 4h1m-5 10v-5a1 1 0 011-1h2a1 1 0 011 1v5m-4 0h4" />
            </svg>
            Informações Espirituais
          </h3>
          <div class="space-y-3">
            <div class="flex justify-between">
              <span class="text-sm font-medium text-gray-600">Tempo de Igreja:</span>
              <span class="text-sm font-semibold text-gray-900">{jovem.tempo_igreja || 'Não informado'}</span>
            </div>
            <div class="flex justify-between">
              <span class="text-sm font-medium text-gray-600">Batizado nas Águas:</span>
              <span class="text-sm font-semibold text-gray-900">{jovem.batizado_aguas ? 'Sim' : 'Não'}</span>
            </div>
            {#if jovem.batizado_aguas && jovem.data_batismo_aguas}
              <div class="flex justify-between">
                <span class="text-sm font-medium text-gray-600">Data do Batismo:</span>
                <span class="text-sm font-semibold text-gray-900">{formatarData(jovem.data_batismo_aguas)}</span>
              </div>
            {/if}
            <div class="flex justify-between">
              <span class="text-sm font-medium text-gray-600">Batizado como ES:</span>
              <span class="text-sm font-semibold text-gray-900">{jovem.batizado_es ? 'Sim' : 'Não'}</span>
            </div>
            {#if jovem.batizado_es && jovem.data_batismo_es}
              <div class="flex justify-between">
                <span class="text-sm font-medium text-gray-600">Data Batismo ES:</span>
                <span class="text-sm font-semibold text-gray-900">{formatarData(jovem.data_batismo_es)}</span>
              </div>
            {/if}
            <div class="flex justify-between">
              <span class="text-sm font-medium text-gray-600">Condição:</span>
              <span class="text-sm font-semibold text-gray-900">{condicoesMap[jovem.condicao] || jovem.condicao || 'Não informado'}</span>
            </div>
            {#if jovem.tempo_condicao}
              <div class="flex justify-between">
                <span class="text-sm font-medium text-gray-600">Tempo nesta Condição:</span>
                <span class="text-sm font-semibold text-gray-900">{jovem.tempo_condicao}</span>
              </div>
            {/if}
            <div class="flex justify-between">
              <span class="text-sm font-medium text-gray-600">Responsabilidade:</span>
              <span class="text-sm font-semibold text-gray-900">{jovem.responsabilidade_igreja || 'Não informado'}</span>
            </div>
          </div>
        </div>

        <!-- Experiência na Igreja -->
        <div class="bg-gradient-to-br from-orange-50 to-red-50 rounded-xl p-6 border border-orange-200">
          <h3 class="text-lg font-bold text-gray-900 mb-4 flex items-center">
            <svg class="w-5 h-5 mr-2 text-orange-600" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z" />
            </svg>
            Experiência na Igreja
          </h3>
          <div class="space-y-3">
            <div class="flex justify-between">
              <span class="text-sm font-medium text-gray-600">Já fez obra no altar:</span>
              <span class="text-sm font-semibold text-gray-900">{jovem.ja_obra_altar ? 'Sim' : 'Não'}</span>
            </div>
            <div class="flex justify-between">
              <span class="text-sm font-medium text-gray-600">Já foi obreiro:</span>
              <span class="text-sm font-semibold text-gray-900">{jovem.ja_obreiro ? 'Sim' : 'Não'}</span>
            </div>
            <div class="flex justify-between">
              <span class="text-sm font-medium text-gray-600">Já foi colaborador:</span>
              <span class="text-sm font-semibold text-gray-900">{jovem.ja_colaborador ? 'Sim' : 'Não'}</span>
            </div>
            <div class="flex justify-between">
              <span class="text-sm font-medium text-gray-600">Já se afastou:</span>
              <span class="text-sm font-semibold text-gray-900">{jovem.afastado ? 'Sim' : 'Não'}</span>
            </div>
            {#if jovem.afastado}
              <div class="flex justify-between">
                <span class="text-sm font-medium text-gray-600">Data do afastamento:</span>
                <span class="text-sm font-semibold text-gray-900">{formatarData(jovem.data_afastamento)}</span>
              </div>
              {#if jovem.motivo_afastamento}
                <div class="flex justify-between">
                  <span class="text-sm font-medium text-gray-600">Motivo:</span>
                  <span class="text-sm font-semibold text-gray-900">{jovem.motivo_afastamento}</span>
                </div>
              {/if}
              {#if jovem.data_retorno}
                <div class="flex justify-between">
                  <span class="text-sm font-medium text-gray-600">Data do retorno:</span>
                  <span class="text-sm font-semibold text-gray-900">{formatarData(jovem.data_retorno)}</span>
                </div>
              {/if}
            {/if}
            <div class="flex justify-between">
              <span class="text-sm font-medium text-gray-600">Pais são da igreja:</span>
              <span class="text-sm font-semibold text-gray-900">{jovem.pais_na_igreja ? 'Sim' : 'Não'}</span>
            </div>
            <div class="flex justify-between">
              <span class="text-sm font-medium text-gray-600">Tem familiares na igreja:</span>
              <span class="text-sm font-semibold text-gray-900">{jovem.familiares_igreja ? 'Sim' : 'Não'}</span>
            </div>
            <div class="flex justify-between">
              <span class="text-sm font-medium text-gray-600">Deseja o altar:</span>
              <span class="text-sm font-semibold text-gray-900">{jovem.deseja_altar ? 'Sim' : 'Não'}</span>
            </div>
          </div>
        </div>
      </div>

      <!-- Coluna direita - Godllywood e Redes Sociais -->
      <div class="space-y-6">
        <!-- Godllywood -->
        <div class="bg-gradient-to-br from-blue-50 to-cyan-50 rounded-xl p-6 border border-blue-200">
          <h3 class="text-lg font-bold text-gray-900 mb-4 flex items-center">
            <svg class="w-5 h-5 mr-2 text-blue-600" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 6.253v13m0-13C10.832 5.477 9.246 5 7.5 5S4.168 5.477 3 6.253v13C4.168 18.477 5.754 18 7.5 18s3.332.477 4.5 1.253m0-13C13.168 5.477 14.754 5 16.5 5c1.746 0 3.332.477 4.5 1.253v13C19.832 18.477 18.246 18 16.5 18c-1.746 0-3.332.477-4.5 1.253" />
            </svg>
            IntelliMen
          </h3>
          <div class="space-y-3">
            <div class="flex justify-between">
              <span class="text-sm font-medium text-gray-600">Formado IntelliMen:</span>
              <span class="text-sm font-semibold text-gray-900">{jovem.formado_intellimen ? 'Sim' : 'Não'}</span>
            </div>
            <div class="flex justify-between">
              <span class="text-sm font-medium text-gray-600">Fazendo desafios:</span>
              <span class="text-sm font-semibold text-gray-900">{jovem.fazendo_desafios ? 'Sim' : 'Não'}</span>
            </div>
            {#if jovem.fazendo_desafios && jovem.qual_desafio}
              <div class="flex justify-between">
                <span class="text-sm font-medium text-gray-600">Qual desafio:</span>
                <span class="text-sm font-semibold text-gray-900">{jovem.qual_desafio}</span>
              </div>
            {/if}
            <div class="flex justify-between">
              <span class="text-sm font-medium text-gray-600">Edição:</span>
              <span class="text-sm font-semibold text-gray-900">{jovem.edicao || 'Não informado'}</span>
            </div>
          </div>
        </div>

        <!-- Redes Sociais -->
        <div class="bg-gradient-to-br from-pink-50 to-purple-50 rounded-xl p-6 border border-pink-200">
          <h3 class="text-lg font-bold text-gray-900 mb-4 flex items-center">
            <svg class="w-5 h-5 mr-2 text-pink-600" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M7 4V2a1 1 0 011-1h8a1 1 0 011 1v2m0 0V1a1 1 0 011-1h2a1 1 0 011 1v18a1 1 0 01-1 1H4a1 1 0 01-1-1V1a1 1 0 011-1h2a1 1 0 011 1v3m0 0h8M7 4h8" />
            </svg>
            Redes Sociais
          </h3>
          <div class="space-y-3">
            {#if jovem.instagram}
              <div class="flex justify-between">
                <span class="text-sm font-medium text-gray-600">Instagram:</span>
                <span class="text-sm font-semibold text-gray-900">@{jovem.instagram}</span>
              </div>
            {/if}
            {#if jovem.facebook}
              <div class="flex justify-between">
                <span class="text-sm font-medium text-gray-600">Facebook:</span>
                <span class="text-sm font-semibold text-gray-900">{jovem.facebook}</span>
              </div>
            {/if}
            {#if jovem.tiktok}
              <div class="flex justify-between">
                <span class="text-sm font-medium text-gray-600">TikTok:</span>
                <span class="text-sm font-semibold text-gray-900">@{jovem.tiktok}</span>
              </div>
            {/if}
            {#if jovem.obs_redes}
              <div class="mt-3 p-3 bg-gray-100 rounded-lg">
                <span class="text-sm font-medium text-gray-600">Observações:</span>
                <p class="text-sm text-gray-700 mt-1">{jovem.obs_redes}</p>
              </div>
            {/if}
          </div>
        </div>

        <!-- Observações e Testemunho -->
        {#if jovem.observacao || jovem.testemunho}
          <div class="bg-gradient-to-br from-yellow-50 to-orange-50 rounded-xl p-6 border border-yellow-200">
            <h3 class="text-lg font-bold text-gray-900 mb-4 flex items-center">
              <svg class="w-5 h-5 mr-2 text-yellow-600" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M11 5H6a2 2 0 00-2 2v11a2 2 0 002 2h11a2 2 0 002-2v-5m-1.414-9.414a2 2 0 112.828 2.828L11.828 15H9v-2.828l8.586-8.586z" />
              </svg>
              Observações
            </h3>
            <div class="space-y-4">
              {#if jovem.observacao}
                <div>
                  <span class="text-sm font-medium text-gray-600">Observação:</span>
                  <p class="text-sm text-gray-700 mt-1">{jovem.observacao}</p>
                </div>
              {/if}
              {#if jovem.testemunho}
                <div>
                  <span class="text-sm font-medium text-gray-600">Testemunho:</span>
                  <p class="text-sm text-gray-700 mt-1">{jovem.testemunho}</p>
                </div>
              {/if}
            </div>
          </div>
        {/if}
      </div>
    </div>

    <!-- Seção de Avaliações (se habilitada) -->
    {#if showAvaliacoes && !compact}
      <div class="mt-8 border-t border-gray-200 pt-8">
        <h3 class="text-xl font-bold text-gray-900 mb-6 flex items-center">
          <svg class="w-6 h-6 mr-2 text-indigo-600" fill="none" viewBox="0 0 24 24" stroke="currentColor">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5H7a2 2 0 00-2 2v10a2 2 0 002 2h8a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2m-3 7h3m-3 4h3m-6-4h.01M9 16h.01" />
          </svg>
          Avaliações ({avaliacoes.length})
        </h3>
        
        {#if loadingAvaliacoes}
          <div class="text-center py-8">
            <div class="animate-spin rounded-full h-8 w-8 border-b-2 border-indigo-600 mx-auto"></div>
            <p class="text-gray-500 mt-2">Carregando avaliações...</p>
          </div>
        {:else if avaliacoes.length === 0}
          <div class="text-center py-8 text-gray-500">
            <svg class="w-12 h-12 mx-auto mb-4 text-gray-300" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5H7a2 2 0 00-2 2v10a2 2 0 002 2h8a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2m-3 7h3m-3 4h3m-6-4h.01M9 16h.01" />
            </svg>
            <p>Nenhuma avaliação encontrada</p>
          </div>
        {:else}
          <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
            {#each avaliacoes as avaliacao}
              <div class="bg-white border border-gray-200 rounded-lg p-4 shadow-sm">
                <div class="flex items-center justify-between mb-2">
                  <span class="text-sm font-medium text-gray-600">
                    {avaliacao.avaliador?.nome || 'Avaliador'}
                  </span>
                  <span class="text-lg font-bold text-indigo-600">
                    {avaliacao.nota || 0}
                  </span>
                </div>
                <div class="text-xs text-gray-500 mb-2">
                  {formatarData(avaliacao.criado_em)}
                </div>
                {#if avaliacao.avaliacao_texto}
                  <p class="text-sm text-gray-700">{avaliacao.avaliacao_texto}</p>
                {/if}
              </div>
            {/each}
          </div>
        {/if}
      </div>
    {/if}
  </div>
</div>

<style>
  /* Estilos adicionais se necessário */
</style>
