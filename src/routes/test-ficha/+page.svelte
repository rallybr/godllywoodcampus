<script>
  import FichaJovem from '$lib/components/jovens/FichaJovem.svelte';
  import { goto } from '$app/navigation';

  // Dados de exemplo para demonstração
  const jovemExemplo = {
    id: '123e4567-e89b-12d3-a456-426614174000',
    nome_completo: 'Mateus Bastos Lopes de Jesus',
    whatsapp: '77968458862',
    data_nasc: '2000-07-03',
    idade: 24,
    sexo: 'Masculino',
    estado_civil: 'Solteiro',
    namora: false,
    tem_filho: false,
    trabalha: true,
    local_trabalho: 'Pintor, trator agrícola e outras',
    escolaridade: 'Médio Completo',
    formacao: 'Autônomo',
    tem_dividas: false,
    valor_divida: null,
    tempo_igreja: '6 Anos e 1 mês',
    batizado_aguas: true,
    data_batismo_aguas: '2018-09-23',
    batizado_es: true,
    data_batismo_es: '2019-01-09',
    condicao: 'Obreiro',
    tempo_condicao: '3 Anos 7 meses',
    responsabilidade_igreja: 'Coordenador da Mídia Da igreja',
    ja_obra_altar: false,
    ja_obreiro: false,
    ja_colaborador: false,
    afastado: false,
    data_afastamento: null,
    motivo_afastamento: null,
    data_retorno: null,
    pais_na_igreja: false,
    familiares_igreja: true,
    deseja_altar: false,
    formado_intellimen: false,
    fazendo_desafios: false,
    qual_desafio: null,
    edicao: '2024',
    instagram: null,
    facebook: null,
    tiktok: null,
    obs_redes: 'Instagram não estou usando\nTiktok não tenha',
    observacao: 'Observações sobre o jovem...',
    testemunho: 'Testemunho pessoal do jovem...',
    aprovado: 'pre_aprovado',
    data_cadastro: '2025-08-25T10:30:00Z',
    estado: {
      nome: 'Bahia'
    },
    igreja: {
      nome: 'Igreja Central'
    }
  };

  function voltar() {
    goto('/jovens');
  }
</script>

<svelte:head>
  <title>Exemplo de Ficha do Jovem - IntelliMen Campus</title>
</svelte:head>

<div class="min-h-screen bg-gray-50 py-8">
  <div class="max-w-6xl mx-auto px-4">
    <!-- Header -->
    <div class="mb-6">
      <div class="flex items-center justify-between">
        <div class="flex items-center space-x-4">
          <button
            on:click={voltar}
            class="flex items-center space-x-2 px-4 py-2 text-gray-600 hover:text-gray-900 transition-colors"
          >
            <svg class="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 19l-7-7 7-7" />
            </svg>
            <span>Voltar</span>
          </button>
          <h1 class="text-2xl font-bold text-gray-900">Exemplo de Ficha do Jovem</h1>
        </div>
        
        <div class="text-sm text-gray-500">
          Esta é uma demonstração da ficha formatada
        </div>
      </div>
    </div>

    <!-- Ficha do Jovem -->
    <FichaJovem jovem={jovemExemplo} showAvaliacoes={true} />
  </div>
</div>
