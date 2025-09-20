<script>
  import { onMount } from 'svelte';
  import { page } from '$app/stores';
  import { loadJovemById, updateJovem } from '$lib/stores/jovens-simple';
  import { goto } from '$app/navigation';
  import { userProfile, hasRole } from '$lib/stores/auth';
  import { supabase } from '$lib/utils/supabase';
  import Button from '$lib/components/ui/Button.svelte';
  import Card from '$lib/components/ui/Card.svelte';
  
  
  // @ts-ignore
  let jovem = null;
  let loading = true;
  let saving = false;
  let error = '';
  let success = '';
  
  // Formulário
  let formData = {
    nome_completo: '',
    whatsapp: '',
    data_nasc: '',
    estado_civil: '',
    namora: false,
    tem_filho: false,
    trabalha: false,
    local_trabalho: '',
    escolaridade: '',
    formacao: '',
    tem_dividas: false,
    valor_divida: 0,
    tempo_igreja: '',
    batizado_aguas: false,
    data_batismo_aguas: '',
    batizado_es: false,
    data_batismo_es: '',
    condicao: '',
    condicao_campus: '',
    tempo_condicao: '',
    responsabilidade_igreja: '',
    disposto_servir: false,
    ja_obra_altar: false,
    ja_obreiro: false,
    ja_colaborador: false,
    afastado: false,
    data_afastamento: '',
    motivo_afastamento: '',
    data_retorno: '',
    pais_na_igreja: false,
    observacao_pais: '',
    familiares_igreja: false,
    deseja_altar: false,
    observacao: '',
    testemunho: '',
    instagram: '',
    facebook: '',
    tiktok: '',
    obs_redes: '',
    pastor_que_indicou: '',
    cresceu_na_igreja: false,
    experiencia_altar: false,
    foi_obreiro: false,
    foi_colaborador: false,
    afastou: false,
    quando_afastou: '',
    motivo_afastou: '',
    quando_voltou: '',
    pais_sao_igreja: false,
    obs_pais: '',
    observacao_text: '',
    testemunho_text: '',
    formado_intellimen: false,
    fazendo_desafios: false,
    qual_desafio: '',
    observacao_redes: ''
  };
  
  onMount(async () => {
    await loadJovemData();
  });
  
  async function loadJovemData() {
    loading = true;
    error = '';
    
    try {
      // Verificar se o usuário tem permissão para editar este jovem
      if (hasRole('jovem')($userProfile)) {
        // Se é jovem, só pode editar seu próprio perfil
        const { data: jovemData, error: jovemError } = await supabase
          .from('jovens')
          .select('id')
          .eq('usuario_id', $userProfile.id)
          .single();
        
        if (jovemError || !jovemData) {
          error = 'Acesso negado';
          goto('/profile');
          return;
        }
        
        if (jovemData.id !== $page.params.id) {
          error = 'Você só pode editar seu próprio perfil';
          goto(`/jovens/${jovemData.id}/editar`);
          return;
        }
      }
      
      jovem = await loadJovemById($page.params.id);
      if (!jovem) {
        error = 'Jovem não encontrado';
        return;
      }
      
      // Preencher formulário com dados do jovem
      formData = {
        nome_completo: jovem.nome_completo || '',
        whatsapp: jovem.whatsapp || '',
        data_nasc: jovem.data_nasc ? jovem.data_nasc.split('T')[0] : '', // Formato YYYY-MM-DD para input date
        estado_civil: jovem.estado_civil || '',
        namora: jovem.namora || false,
        tem_filho: jovem.tem_filho || false,
        trabalha: jovem.trabalha || false,
        local_trabalho: jovem.local_trabalho || '',
        escolaridade: jovem.escolaridade || '',
        formacao: jovem.formacao || '',
        tem_dividas: jovem.tem_dividas || false,
        valor_divida: jovem.valor_divida || 0,
        tempo_igreja: jovem.tempo_igreja || '',
        batizado_aguas: jovem.batizado_aguas || false,
        data_batismo_aguas: jovem.data_batismo_aguas ? jovem.data_batismo_aguas.split('T')[0] : '',
        batizado_es: jovem.batizado_es || false,
        data_batismo_es: jovem.data_batismo_es ? jovem.data_batismo_es.split('T')[0] : '',
        condicao: jovem.condicao || '',
        condicao_campus: jovem.condicao_campus || '',
        tempo_condicao: jovem.tempo_condicao || '',
        responsabilidade_igreja: jovem.responsabilidade_igreja || '',
        disposto_servir: jovem.disposto_servir || false,
        ja_obra_altar: jovem.ja_obra_altar || false,
        ja_obreiro: jovem.ja_obreiro || false,
        ja_colaborador: jovem.ja_colaborador || false,
        afastado: jovem.afastado || false,
        data_afastamento: jovem.data_afastamento ? jovem.data_afastamento.split('T')[0] : '',
        motivo_afastamento: jovem.motivo_afastamento || '',
        data_retorno: jovem.data_retorno ? jovem.data_retorno.split('T')[0] : '',
        pais_na_igreja: jovem.pais_na_igreja || false,
        observacao_pais: jovem.observacao_pais || '',
        familiares_igreja: jovem.familiares_igreja || false,
        deseja_altar: jovem.deseja_altar || false,
        observacao: jovem.observacao || '',
        testemunho: jovem.testemunho || '',
        instagram: jovem.instagram || '',
        facebook: jovem.facebook || '',
        tiktok: jovem.tiktok || '',
        obs_redes: jovem.obs_redes || '',
        pastor_que_indicou: jovem.pastor_que_indicou || '',
        cresceu_na_igreja: jovem.cresceu_na_igreja || false,
        experiencia_altar: jovem.experiencia_altar || false,
        foi_obreiro: jovem.foi_obreiro || false,
        foi_colaborador: jovem.foi_colaborador || false,
        afastou: jovem.afastou || false,
        quando_afastou: jovem.quando_afastou ? jovem.quando_afastou.split('T')[0] : '',
        motivo_afastou: jovem.motivo_afastou || '',
        quando_voltou: jovem.quando_voltou ? jovem.quando_voltou.split('T')[0] : '',
        pais_sao_igreja: jovem.pais_sao_igreja || false,
        obs_pais: jovem.obs_pais || '',
        observacao_text: jovem.observacao_text || '',
        testemunho_text: jovem.testemunho_text || '',
        formado_intellimen: jovem.formado_intellimen || false,
        fazendo_desafios: jovem.fazendo_desafios || false,
        qual_desafio: jovem.qual_desafio || '',
        observacao_redes: jovem.observacao_redes || ''
      };
    } catch (err) {
      error = err.message;
    } finally {
      loading = false;
    }
  }
  
  async function handleSave() {
    saving = true;
    error = '';
    success = '';
    
    try {
      // Limpar campos de data vazios para NULL
      const cleanedData = { ...formData };
      
      // Campos de data que devem ser NULL se vazios
      const dateFields = [
        'data_nasc',
        'data_batismo_aguas', 
        'data_batismo_es',
        'data_afastamento',
        'data_retorno',
        'quando_afastou',
        'quando_voltou'
      ];
      
      dateFields.forEach(field => {
        if (cleanedData[field] === '' || cleanedData[field] === null) {
          cleanedData[field] = null;
        }
      });
      
      const result = await updateJovem(jovem.id, cleanedData);
      if (result) {
        success = 'Jovem atualizado com sucesso!';
        setTimeout(() => {
          goto(`/jovens/${jovem.id}`);
        }, 1500);
      } else {
        error = 'Erro ao atualizar jovem';
      }
    } catch (err) {
      error = err.message;
    } finally {
      saving = false;
    }
  }
  
  function handleCancel() {
    goto(`/jovens/${jovem.id}`);
  }
</script>

<svelte:head>
  <title>Editar Jovem - IntelliMen Campus</title>
</svelte:head>

{#if loading}
  <div class="flex items-center justify-center py-12">
    <div class="animate-spin rounded-full h-12 w-12 border-b-2 border-blue-600"></div>
  </div>
{:else if error && !jovem}
  <div class="text-center py-12">
    <div class="w-16 h-16 bg-red-100 rounded-full flex items-center justify-center mx-auto mb-4">
      <svg class="w-8 h-8 text-red-600" fill="none" viewBox="0 0 24 24" stroke="currentColor">
        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8v4m0 4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
      </svg>
    </div>
    <h3 class="text-lg font-semibold text-gray-900 mb-2">Erro ao carregar jovem</h3>
    <p class="text-gray-600 mb-4">{error}</p>
    <Button on:click={loadJovemData} variant="outline">
      Tentar Novamente
    </Button>
  </div>
{:else if jovem}
  <div class="max-w-4xl mx-auto">
    <!-- Header -->
    <div class="bg-white rounded-lg shadow-sm border border-gray-200 overflow-hidden mb-6">
      <div class="bg-blue-600 px-6 py-4">
        <h1 class="text-2xl font-bold text-white">Editar Jovem</h1>
        <p class="text-blue-100">{jovem.nome_completo}</p>
      </div>
    </div>
    
    <!-- Mensagens -->
    {#if error}
      <div class="bg-red-50 border border-red-200 rounded-md p-4 mb-6">
        <div class="flex">
          <svg class="w-5 h-5 text-red-400" fill="none" viewBox="0 0 24 24" stroke="currentColor">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8v4m0 4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
          </svg>
          <div class="ml-3">
            <p class="text-sm text-red-800">{error}</p>
          </div>
        </div>
      </div>
    {/if}
    
    {#if success}
      <div class="bg-green-50 border border-green-200 rounded-md p-4 mb-6">
        <div class="flex">
          <svg class="w-5 h-5 text-green-400" fill="none" viewBox="0 0 24 24" stroke="currentColor">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7" />
          </svg>
          <div class="ml-3">
            <p class="text-sm text-green-800">{success}</p>
          </div>
        </div>
      </div>
    {/if}
    
    <!-- Formulário -->
    <form on:submit|preventDefault={handleSave}>
      <div class="space-y-6">
        <!-- Dados Pessoais -->
        <Card>
          <div class="px-6 py-4 border-b border-gray-200">
            <h3 class="text-lg font-medium text-gray-900">Dados Pessoais</h3>
          </div>
          <div class="p-6 space-y-4">
            <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
              <div>
                <label for="nome_completo" class="block text-sm font-medium text-gray-700 mb-1">
                  Nome Completo *
                </label>
                <input
                  type="text"
                  id="nome_completo"
                  bind:value={formData.nome_completo}
                  required
                  class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                />
              </div>
              <div>
                <label for="whatsapp" class="block text-sm font-medium text-gray-700 mb-1">
                  WhatsApp
                </label>
                <input
                  type="text"
                  id="whatsapp"
                  bind:value={formData.whatsapp}
                  class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                />
              </div>
              <div>
                <label for="data_nasc" class="block text-sm font-medium text-gray-700 mb-1">
                  Data de Nascimento
                </label>
                <input
                  type="date"
                  id="data_nasc"
                  bind:value={formData.data_nasc}
                  class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                />
              </div>
              <div>
                <label for="estado_civil" class="block text-sm font-medium text-gray-700 mb-1">
                  Estado Civil
                </label>
                <select
                  id="estado_civil"
                  bind:value={formData.estado_civil}
                  class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                >
                  <option value="">Selecione</option>
                  <option value="solteiro">Solteiro</option>
                  <option value="casado">Casado</option>
                  <option value="divorciado">Divorciado</option>
                  <option value="viuvo">Viúvo</option>
                </select>
              </div>
            </div>
            
            <div class="grid grid-cols-1 md:grid-cols-3 gap-4">
              <div class="flex items-center">
                <input
                  type="checkbox"
                  id="namora"
                  bind:checked={formData.namora}
                  class="h-4 w-4 text-blue-600 focus:ring-blue-500 border-gray-300 rounded"
                />
                <label for="namora" class="ml-2 text-sm text-gray-700">Namora</label>
              </div>
              <div class="flex items-center">
                <input
                  type="checkbox"
                  id="tem_filho"
                  bind:checked={formData.tem_filho}
                  class="h-4 w-4 text-blue-600 focus:ring-blue-500 border-gray-300 rounded"
                />
                <label for="tem_filho" class="ml-2 text-sm text-gray-700">Tem Filho</label>
              </div>
              <div class="flex items-center">
                <input
                  type="checkbox"
                  id="trabalha"
                  bind:checked={formData.trabalha}
                  class="h-4 w-4 text-blue-600 focus:ring-blue-500 border-gray-300 rounded"
                />
                <label for="trabalha" class="ml-2 text-sm text-gray-700">Trabalha</label>
              </div>
            </div>
            
            {#if formData.trabalha}
              <div>
                <label for="local_trabalho" class="block text-sm font-medium text-gray-700 mb-1">
                  Local de Trabalho
                </label>
                <input
                  type="text"
                  id="local_trabalho"
                  bind:value={formData.local_trabalho}
                  class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                />
              </div>
            {/if}
            
            <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
              <div>
                <label for="escolaridade" class="block text-sm font-medium text-gray-700 mb-1">
                  Escolaridade
                </label>
                <select
                  id="escolaridade"
                  bind:value={formData.escolaridade}
                  class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                >
                  <option value="">Selecione</option>
                  <option value="fundamental_incompleto">Fundamental Incompleto</option>
                  <option value="fundamental_completo">Fundamental Completo</option>
                  <option value="medio_incompleto">Médio Incompleto</option>
                  <option value="medio_completo">Médio Completo</option>
                  <option value="superior_incompleto">Superior Incompleto</option>
                  <option value="superior_completo">Superior Completo</option>
                  <option value="pos_graduacao">Pós-graduação</option>
                </select>
              </div>
              <div>
                <label for="formacao" class="block text-sm font-medium text-gray-700 mb-1">
                  Formação/Profissão
                </label>
                <input
                  type="text"
                  id="formacao"
                  bind:value={formData.formacao}
                  class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                />
              </div>
            </div>
            
            <div class="flex items-center">
              <input
                type="checkbox"
                id="tem_dividas"
                bind:checked={formData.tem_dividas}
                class="h-4 w-4 text-blue-600 focus:ring-blue-500 border-gray-300 rounded"
              />
              <label for="tem_dividas" class="ml-2 text-sm text-gray-700">Tem Dívidas</label>
            </div>
            
            {#if formData.tem_dividas}
              <div>
                <label for="valor_divida" class="block text-sm font-medium text-gray-700 mb-1">
                  Valor da Dívida (R$)
                </label>
                <input
                  type="number"
                  id="valor_divida"
                  bind:value={formData.valor_divida}
                  step="0.01"
                  min="0"
                  class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                />
              </div>
            {/if}
          </div>
        </Card>
        
        <!-- Dados Espirituais -->
        <Card>
          <div class="px-6 py-4 border-b border-gray-200">
            <h3 class="text-lg font-medium text-gray-900">Dados Espirituais</h3>
          </div>
          <div class="p-6 space-y-4">
            <div>
              <label for="tempo_igreja" class="block text-sm font-medium text-gray-700 mb-1">
                Tempo de Igreja
              </label>
              <input
                type="text"
                id="tempo_igreja"
                bind:value={formData.tempo_igreja}
                class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent"
              />
            </div>
            
            <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
              <div class="flex items-center">
                <input
                  type="checkbox"
                  id="batizado_aguas"
                  bind:checked={formData.batizado_aguas}
                  class="h-4 w-4 text-blue-600 focus:ring-blue-500 border-gray-300 rounded"
                />
                <label for="batizado_aguas" class="ml-2 text-sm text-gray-700">Batizado nas Águas</label>
              </div>
              <div class="flex items-center">
                <input
                  type="checkbox"
                  id="batizado_es"
                  bind:checked={formData.batizado_es}
                  class="h-4 w-4 text-blue-600 focus:ring-blue-500 border-gray-300 rounded"
                />
                <label for="batizado_es" class="ml-2 text-sm text-gray-700">Batizado com ES</label>
              </div>
            </div>
            
            {#if formData.batizado_aguas}
              <div>
                <label for="data_batismo_aguas" class="block text-sm font-medium text-gray-700 mb-1">
                  Data do Batismo nas Águas
                </label>
                <input
                  type="date"
                  id="data_batismo_aguas"
                  bind:value={formData.data_batismo_aguas}
                  class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                />
              </div>
            {/if}
            
            {#if formData.batizado_es}
              <div>
                <label for="data_batismo_es" class="block text-sm font-medium text-gray-700 mb-1">
                  Data do Batismo com ES
                </label>
                <input
                  type="date"
                  id="data_batismo_es"
                  bind:value={formData.data_batismo_es}
                  class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                />
              </div>
            {/if}
            
            <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
              <div>
                <label for="condicao" class="block text-sm font-medium text-gray-700 mb-1">
                  Condição
                </label>
                <div class="relative">
                  <select
                    id="condicao"
                    bind:value={formData.condicao}
                    class="w-full px-3 py-2 pr-10 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent appearance-none bg-white cursor-pointer"
                  >
                    <option value="">Selecione a condição</option>
                    <option value="jovem_batizado_es">Jovem Batizado(a) ES</option>
                    <option value="cpo">CPO</option>
                    <option value="colaborador">Colaborador(a)</option>
                    <option value="obreiro">Obreiro(a)</option>
                    <option value="iburd">IBURD</option>
                    <option value="auxiliar_pastor">Auxiliar de Pastor</option>
                    <option value="namorada">Namorada</option>
                    <option value="noiva">Noiva</option>
                  </select>
                  <!-- Ícone de dropdown customizado -->
                  <div class="absolute inset-y-0 right-0 flex items-center pr-3 pointer-events-none">
                    <svg class="w-5 h-5 text-gray-400" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 9l-7 7-7-7" />
                    </svg>
                  </div>
                </div>
              </div>
              <div>
                <label for="condicao_campus" class="block text-sm font-medium text-gray-700 mb-1">
                  Chegou no Campus Como?
                </label>
                <div class="relative">
                  <select
                    id="condicao_campus"
                    bind:value={formData.condicao_campus}
                    class="w-full px-3 py-2 pr-10 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent appearance-none bg-white cursor-pointer"
                  >
                    <option value="">Selecione a condição no Campus</option>
                    <option value="jovem_batizado_es">Jovem Batizado(a) ES</option>
                    <option value="cpo">CPO</option>
                    <option value="colaborador">Colaborador(a)</option>
                    <option value="obreiro">Obreiro(a)</option>
                    <option value="iburd">IBURD</option>
                    <option value="auxiliar_pastor">Auxiliar de Pastor</option>
                    <option value="namorada">Namorada</option>
                    <option value="noiva">Noiva</option>
                  </select>
                  <!-- Ícone de dropdown customizado -->
                  <div class="absolute inset-y-0 right-0 flex items-center pr-3 pointer-events-none">
                    <svg class="w-5 h-5 text-gray-400" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 9l-7 7-7-7" />
                    </svg>
                  </div>
                </div>
              </div>
            </div>
            
            <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
              <div>
                <label for="tempo_condicao" class="block text-sm font-medium text-gray-700 mb-1">
                  Tempo de Condição
                </label>
                <input
                  type="text"
                  id="tempo_condicao"
                  bind:value={formData.tempo_condicao}
                  class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                />
              </div>
            </div>
            
            <div>
              <label for="responsabilidade_igreja" class="block text-sm font-medium text-gray-700 mb-1">
                Responsabilidade na Igreja
              </label>
              <input
                type="text"
                id="responsabilidade_igreja"
                bind:value={formData.responsabilidade_igreja}
                class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent"
              />
            </div>
            
            <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
              <div class="flex items-center">
                <input
                  type="checkbox"
                  id="disposto_servir"
                  bind:checked={formData.disposto_servir}
                  class="h-4 w-4 text-blue-600 focus:ring-blue-500 border-gray-300 rounded"
                />
                <label for="disposto_servir" class="ml-2 text-sm text-gray-700">Disposto a Servir</label>
              </div>
              <div class="flex items-center">
                <input
                  type="checkbox"
                  id="ja_obra_altar"
                  bind:checked={formData.ja_obra_altar}
                  class="h-4 w-4 text-blue-600 focus:ring-blue-500 border-gray-300 rounded"
                />
                <label for="ja_obra_altar" class="ml-2 text-sm text-gray-700">Já Fez a Obra no Altar</label>
              </div>
              <div class="flex items-center">
                <input
                  type="checkbox"
                  id="ja_obreiro"
                  bind:checked={formData.ja_obreiro}
                  class="h-4 w-4 text-blue-600 focus:ring-blue-500 border-gray-300 rounded"
                />
                <label for="ja_obreiro" class="ml-2 text-sm text-gray-700">Já Foi Obreiro</label>
              </div>
              <div class="flex items-center">
                <input
                  type="checkbox"
                  id="ja_colaborador"
                  bind:checked={formData.ja_colaborador}
                  class="h-4 w-4 text-blue-600 focus:ring-blue-500 border-gray-300 rounded"
                />
                <label for="ja_colaborador" class="ml-2 text-sm text-gray-700">Já Foi Colaborador</label>
              </div>
            </div>
            
            <div class="flex items-center">
              <input
                type="checkbox"
                id="afastado"
                bind:checked={formData.afastado}
                class="h-4 w-4 text-blue-600 focus:ring-blue-500 border-gray-300 rounded"
              />
              <label for="afastado" class="ml-2 text-sm text-gray-700">Já Se Afastou</label>
            </div>
            
            {#if formData.afastado}
              <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
                <div>
                  <label for="data_afastamento" class="block text-sm font-medium text-gray-700 mb-1">
                    Data do Afastamento
                  </label>
                  <input
                    type="date"
                    id="data_afastamento"
                    bind:value={formData.data_afastamento}
                    class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                  />
                </div>
                <div>
                  <label for="data_retorno" class="block text-sm font-medium text-gray-700 mb-1">
                    Data do Retorno
                  </label>
                  <input
                    type="date"
                    id="data_retorno"
                    bind:value={formData.data_retorno}
                    class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                  />
                </div>
              </div>
              <div>
                <label for="motivo_afastamento" class="block text-sm font-medium text-gray-700 mb-1">
                  Motivo do Afastamento
                </label>
                <textarea
                  id="motivo_afastamento"
                  bind:value={formData.motivo_afastamento}
                  rows="3"
                  class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                ></textarea>
              </div>
            {/if}
            
            <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
              <div class="flex items-center">
                <input
                  type="checkbox"
                  id="pais_na_igreja"
                  bind:checked={formData.pais_na_igreja}
                  class="h-4 w-4 text-blue-600 focus:ring-blue-500 border-gray-300 rounded"
                />
                <label for="pais_na_igreja" class="ml-2 text-sm text-gray-700">Pais São da Igreja</label>
              </div>
              <div class="flex items-center">
                <input
                  type="checkbox"
                  id="familiares_igreja"
                  bind:checked={formData.familiares_igreja}
                  class="h-4 w-4 text-blue-600 focus:ring-blue-500 border-gray-300 rounded"
                />
                <label for="familiares_igreja" class="ml-2 text-sm text-gray-700">Tem Familiares na Igreja</label>
              </div>
            </div>
            
            {#if formData.pais_na_igreja}
              <div>
                <label for="observacao_pais" class="block text-sm font-medium text-gray-700 mb-1">
                  Observação sobre os Pais
                </label>
                <textarea
                  id="observacao_pais"
                  bind:value={formData.observacao_pais}
                  rows="2"
                  class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                ></textarea>
              </div>
            {/if}
            
            <div class="flex items-center">
              <input
                type="checkbox"
                id="deseja_altar"
                bind:checked={formData.deseja_altar}
                class="h-4 w-4 text-blue-600 focus:ring-blue-500 border-gray-300 rounded"
              />
              <label for="deseja_altar" class="ml-2 text-sm text-gray-700">Deseja o Altar</label>
            </div>
          </div>
        </Card>
        
        <!-- Observações e Redes Sociais -->
        <Card>
          <div class="px-6 py-4 border-b border-gray-200">
            <h3 class="text-lg font-medium text-gray-900">Observações e Redes Sociais</h3>
          </div>
          <div class="p-6 space-y-4">
            <div>
              <label for="observacao" class="block text-sm font-medium text-gray-700 mb-1">
                Observação
              </label>
              <textarea
                id="observacao"
                bind:value={formData.observacao}
                rows="3"
                class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent"
              ></textarea>
            </div>
            
            <div>
              <label for="testemunho" class="block text-sm font-medium text-gray-700 mb-1">
                Testemunho
              </label>
              <textarea
                id="testemunho"
                bind:value={formData.testemunho}
                rows="3"
                class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent"
              ></textarea>
            </div>
            
            <div class="grid grid-cols-1 md:grid-cols-3 gap-4">
              <div>
                <label for="instagram" class="block text-sm font-medium text-gray-700 mb-1">
                  Instagram
                </label>
                <input
                  type="text"
                  id="instagram"
                  bind:value={formData.instagram}
                  class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                />
              </div>
              <div>
                <label for="facebook" class="block text-sm font-medium text-gray-700 mb-1">
                  Facebook
                </label>
                <input
                  type="text"
                  id="facebook"
                  bind:value={formData.facebook}
                  class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                />
              </div>
              <div>
                <label for="tiktok" class="block text-sm font-medium text-gray-700 mb-1">
                  TikTok
                </label>
                <input
                  type="text"
                  id="tiktok"
                  bind:value={formData.tiktok}
                  class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                />
              </div>
            </div>
            
            <div>
              <label for="obs_redes" class="block text-sm font-medium text-gray-700 mb-1">
                Observação sobre Redes Sociais
              </label>
              <textarea
                id="obs_redes"
                bind:value={formData.obs_redes}
                rows="2"
                class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent"
              ></textarea>
            </div>
          </div>
        </Card>
        
        <!-- IntelliMen -->
        <Card>
          <div class="px-6 py-4 border-b border-gray-200">
            <h3 class="text-lg font-medium text-gray-900">IntelliMen</h3>
          </div>
          <div class="p-6 space-y-4">
            <div>
              <label for="pastor_que_indicou" class="block text-sm font-medium text-gray-700 mb-1">
                Pastor que Indicou
              </label>
              <input
                type="text"
                id="pastor_que_indicou"
                bind:value={formData.pastor_que_indicou}
                class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent"
              />
            </div>
            
            <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
              <div class="flex items-center">
                <input
                  type="checkbox"
                  id="cresceu_na_igreja"
                  bind:checked={formData.cresceu_na_igreja}
                  class="h-4 w-4 text-blue-600 focus:ring-blue-500 border-gray-300 rounded"
                />
                <label for="cresceu_na_igreja" class="ml-2 text-sm text-gray-700">Cresceu na Igreja</label>
              </div>
              <div class="flex items-center">
                <input
                  type="checkbox"
                  id="formado_intellimen"
                  bind:checked={formData.formado_intellimen}
                  class="h-4 w-4 text-blue-600 focus:ring-blue-500 border-gray-300 rounded"
                />
                <label for="formado_intellimen" class="ml-2 text-sm text-gray-700">Formado no IntelliMen</label>
              </div>
            </div>
            
            <div class="flex items-center">
              <input
                type="checkbox"
                id="fazendo_desafios"
                bind:checked={formData.fazendo_desafios}
                class="h-4 w-4 text-blue-600 focus:ring-blue-500 border-gray-300 rounded"
              />
              <label for="fazendo_desafios" class="ml-2 text-sm text-gray-700">Fazendo os Desafios</label>
            </div>
            
            {#if formData.fazendo_desafios}
              <div>
                <label for="qual_desafio" class="block text-sm font-medium text-gray-700 mb-1">
                  Qual Desafio
                </label>
                <input
                  type="text"
                  id="qual_desafio"
                  bind:value={formData.qual_desafio}
                  class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                />
              </div>
            {/if}
          </div>
        </Card>
      </div>
      
      <!-- Botões de Ação -->
      <div class="flex justify-end space-x-4 mt-8">
        <Button
          type="button"
          variant="outline"
          on:click={handleCancel}
          disabled={saving}
        >
          Cancelar
        </Button>
        <Button
          type="submit"
          variant="primary"
          loading={saving}
          disabled={saving}
        >
          {saving ? 'Salvando...' : 'Salvar Alterações'}
        </Button>
      </div>
    </form>
  </div>
{/if}
