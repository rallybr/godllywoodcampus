<script>
  import { onMount } from 'svelte';
  import { page } from '$app/stores';
  import { loadJovemById, aprovarJovem } from '$lib/stores/jovens';
  import { goto } from '$app/navigation';
  import Button from '$lib/components/ui/Button.svelte';
  import Card from '$lib/components/ui/Card.svelte';
  import AvaliacoesList from './AvaliacoesList.svelte';
  import { userProfile, hasRole } from '$lib/stores/auth';
  import AvaliacaoModal from '$lib/components/modals/AvaliacaoModal.svelte';
  
  export let jovemId;
  
  let jovem = null;
  let loading = true;
  let error = '';
  let activeTab = 'dados-pessoais';
  let isApproving = false;
  let showAvaliacaoModal = false;
  let avaliacoesListComponent = null;
  
  const tabs = [
    { id: 'dados-pessoais', label: 'Dados Pessoais', icon: 'M16 7a4 4 0 11-8 0 4 4 0 018 0zM12 14a7 7 0 00-7 7h14a7 7 0 00-7-7z' },
    { id: 'espirituais', label: 'Espirituais', icon: 'M4.318 6.318a4.5 4.5 0 000 6.364L12 20.364l7.682-7.682a4.5 4.5 0 00-6.364-6.364L12 7.636l-1.318-1.318a4.5 4.5 0 00-6.364 0z' },
    { id: 'profissionais', label: 'Profissionais', icon: 'M21 13.255A23.931 23.931 0 0112 15c-3.183 0-6.22-.62-9-1.745M16 6V4a2 2 0 00-2-2h-4a2 2 0 00-2-2v2m8 0V6a2 2 0 012 2v6a2 2 0 01-2 2H6a2 2 0 01-2-2V8a2 2 0 012-2V6' },
    // Aba de avaliações será exibida apenas se não for papel jovem
    { id: 'avaliacoes', label: 'Avaliações', icon: 'M9 19v-6a2 2 0 00-2-2H5a2 2 0 00-2 2v6a2 2 0 002 2h2a2 2 0 002-2zm0 0V9a2 2 0 012-2h2a2 2 0 012 2v10m-6 0a2 2 0 002 2h2a2 2 0 002-2m0 0V5a2 2 0 012-2h2a2 2 0 012 2v14a2 2 0 01-2 2h-2a2 2 0 01-2-2z' },
    { id: 'historico', label: 'Histórico', icon: 'M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z' }
  ];
  
  onMount(async () => {
    await loadJovemData();
    
    // Verificar se há parâmetro tab na URL
    const tabParam = $page.url.searchParams.get('tab');
    if (tabParam && tabs.some(tab => tab.id === tabParam)) {
      activeTab = tabParam;
    }
  });
  
  async function loadJovemData() {
    loading = true;
    error = '';
    
    try {
      jovem = await loadJovemById(jovemId);
      if (!jovem) {
        error = 'Jovem não encontrado';
      } else {
        console.log('Jovem carregado:', jovem);
        console.log('Sexo do jovem:', jovem.sexo);
        console.log('WhatsApp do jovem:', jovem.whatsapp);
        console.log('Edição do jovem:', jovem.edicao);
      }
    } catch (err) {
      error = err.message;
    } finally {
      loading = false;
    }
  }
  
  async function handleAprovar(status) {
    if (!jovem) return;
    
    isApproving = true;
    try {
      await aprovarJovem(jovem.id, status);
      jovem.aprovado = status;
    } catch (err) {
      error = err.message;
    } finally {
      isApproving = false;
    }
  }
  
  function getStatusBadge(status) {
    switch (status) {
      case 'aprovado':
        return 'bg-green-100 text-green-800';
      case 'pre_aprovado':
        return 'bg-yellow-100 text-yellow-800';
      default:
        return 'bg-gray-100 text-gray-800';
    }
  }
  
  function getStatusText(status) {
    switch (status) {
      case 'aprovado':
        return 'Aprovado';
      case 'pre_aprovado':
        return 'Pré-aprovado';
      default:
        return 'Pendente';
    }
  }
  
  function formatDate(dateString) {
    if (!dateString) return 'Não informado';
    return new Date(dateString).toLocaleDateString('pt-BR');
  }
  
  function formatPhone(phone) {
    if (!phone || phone.trim() === '') return 'Não informado';
    // Remove caracteres não numéricos
    const cleanPhone = phone.replace(/\D/g, '');
    if (cleanPhone.length === 11) {
      return cleanPhone.replace(/(\d{2})(\d{5})(\d{4})/, '($1) $2-$3');
    } else if (cleanPhone.length === 10) {
      return cleanPhone.replace(/(\d{2})(\d{4})(\d{4})/, '($1) $2-$3');
    }
    return phone; // Retorna o original se não conseguir formatar
  }
  
  function openAvaliacaoModal() {
    showAvaliacaoModal = true;
  }
  
  function closeAvaliacaoModal() {
    showAvaliacaoModal = false;
  }
  
  async function handleAvaliacaoSuccess(event) {
    console.log('Avaliação criada com sucesso:', event.detail);
    // Recarregar a lista de avaliações se estiver na aba de avaliações
    if (activeTab === 'avaliacoes' && avaliacoesListComponent) {
      await avaliacoesListComponent.reloadAvaliacoes();
    }
  }
</script>

{#if loading}
  <div class="flex items-center justify-center py-12">
    <div class="animate-spin rounded-full h-12 w-12 border-b-2 border-blue-600"></div>
  </div>
{:else if error}
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
  <div class="max-w-6xl mx-auto">
    <!-- Header -->
    <div class="bg-white rounded-lg shadow-sm border border-gray-200 overflow-hidden mb-6">
      <!-- Header azul com nome e edição -->
      <div class="bg-blue-600 px-6 py-5 text-center">
        <h1 class="text-3xl font-bold text-white mb-2">{jovem.nome_completo}</h1>
        <p class="text-white text-base font-medium">{jovem.edicao || 'Não informado'}</p>
      </div>
      
      <!-- Conteúdo do header -->
      <div class="p-8">
        <div class="flex items-start space-x-8">
          <!-- Foto -->
          <div class="flex-shrink-0">
            {#if jovem.foto}
              <img class="w-36 h-44 rounded-xl object-cover border-4 border-blue-500 shadow-lg" src={jovem.foto} alt={jovem.nome_completo} />
            {:else}
              <div class="w-36 h-44 bg-gradient-to-br from-blue-500 to-purple-600 rounded-xl flex items-center justify-center border-4 border-blue-500 shadow-lg">
                <span class="text-white font-bold text-4xl">{jovem.nome_completo?.charAt(0) || 'J'}</span>
              </div>
            {/if}
          </div>
          
          <!-- Informações básicas -->
          <div class="flex-1">
            <div class="flex items-start justify-between">
              <div class="space-y-4">
                <!-- Lista organizada de dados -->
                <div class="space-y-2">
                  <div class="flex items-center space-x-3">
                    <span class="text-gray-500 text-sm font-medium w-16">Estado:</span>
                    <span class="text-gray-700 text-base font-semibold">{jovem.estado?.nome || 'Não informado'}</span>
                  </div>
                  <div class="flex items-center space-x-3">
                    <span class="text-gray-500 text-sm font-medium w-16">Bloco:</span>
                    <span class="text-gray-700 text-base font-semibold">{jovem.bloco?.nome || 'Não informado'}</span>
                  </div>
                  <div class="flex items-center space-x-3">
                    <span class="text-gray-500 text-sm font-medium w-16">Região:</span>
                    <span class="text-gray-700 text-base font-semibold">{jovem.regiao?.nome || 'Não informado'}</span>
                  </div>
                  <div class="flex items-center space-x-3">
                    <span class="text-gray-500 text-sm font-medium w-16">Igreja:</span>
                    <span class="text-gray-700 text-base font-semibold">{jovem.igreja?.nome || 'Não informado'}</span>
                  </div>
                  <div class="flex items-center space-x-3">
                    <span class="text-gray-500 text-sm font-medium w-16">Idade:</span>
                    <span class="text-gray-700 text-base font-semibold">{jovem.idade || 'Não informado'} anos</span>
                  </div>
                  <div class="flex items-center space-x-3">
                    <span class="text-gray-500 text-sm font-medium w-16">Sexo:</span>
                    <span class="text-gray-700 text-base font-semibold">{jovem.sexo || 'Não informado'}</span>
                  </div>
                </div>
              </div>
              
              <!-- Status e ações -->
              <div class="flex flex-col items-end space-y-4">
                {#if !hasRole('jovem')($userProfile)}
                  <span class="inline-flex items-center px-4 py-2 rounded-full text-base font-semibold {getStatusBadge(jovem.aprovado)}">
                    {getStatusText(jovem.aprovado)}
                  </span>
                  <div class="flex flex-col space-y-2 w-full max-w-xs">
                    {#if jovem.aprovado !== 'aprovado'}
                      <Button
                        size="sm"
                        variant="primary"
                        on:click={() => handleAprovar('aprovado')}
                        loading={isApproving}
                        disabled={isApproving}
                      >
                        Aprovar
                      </Button>
                    {/if}
                    {#if jovem.aprovado !== 'pre_aprovado'}
                      <Button
                        size="sm"
                        variant="outline"
                        on:click={() => handleAprovar('pre_aprovado')}
                        loading={isApproving}
                        disabled={isApproving}
                      >
                        Pré-aprovar
                      </Button>
                    {/if}
                    <Button
                      size="sm"
                      variant="outline"
                      on:click={() => goto(`/jovens/${jovem.id}/editar`)}
                    >
                      Editar
                    </Button>
                  </div>
                {/if}
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
    
    <!-- Tabs -->
    <div class="bg-white rounded-lg shadow-sm border border-gray-200 mb-6">
      <div class="border-b border-gray-200">
        <nav class="-mb-px flex space-x-8 px-6">
          {#each tabs as tab}
            {#if !(tab.id === 'avaliacoes' && hasRole('jovem')($userProfile))}
            <button
              class="flex items-center space-x-2 py-4 px-1 border-b-2 font-medium text-sm {activeTab === tab.id ? 'border-blue-500 text-blue-600' : 'border-transparent text-gray-500 hover:text-gray-700 hover:border-gray-300'}"
              on:click={() => activeTab = tab.id}
            >
              <svg class="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d={tab.icon} />
              </svg>
              <span>{tab.label}</span>
            </button>
            {/if}
          {/each}
        </nav>
      </div>
    </div>
    
    <!-- Tab Content -->
    <div class="bg-white rounded-lg shadow-sm border border-gray-200 p-6">
      {#if activeTab === 'dados-pessoais'}
        <!-- Dados Pessoais -->
        <div class="space-y-6">
          <!-- Informações Pessoais -->
          <div class="bg-white rounded-lg shadow-sm border border-blue-200 overflow-hidden">
            <div class="bg-blue-600 px-6 py-3 relative">
              <div class="absolute left-0 top-0 bottom-0 w-2 bg-blue-800 rounded-r"></div>
              <h3 class="text-lg font-semibold text-white ml-3">Informações Pessoais</h3>
            </div>
            <div class="p-6">
              <dl class="space-y-4">
                <div class="flex justify-between items-center py-2 border-b border-gray-100">
                  <dt class="text-sm font-medium text-blue-600 uppercase tracking-wide font-bold">WhatsApp</dt>
                  <dd class="text-sm font-semibold text-gray-900 bg-blue-50 px-3 py-1 rounded">{formatPhone(jovem.whatsapp)}</dd>
                </div>
                <div class="flex justify-between items-center py-2 border-b border-gray-100">
                  <dt class="text-sm font-medium text-blue-600 uppercase tracking-wide font-bold">Idade</dt>
                  <dd class="text-sm font-semibold text-gray-900 bg-blue-50 px-3 py-1 rounded">{jovem.idade} anos</dd>
                </div>
                <div class="flex justify-between items-center py-2 border-b border-gray-100">
                  <dt class="text-sm font-medium text-blue-600 uppercase tracking-wide font-bold">Data de Nascimento</dt>
                  <dd class="text-sm font-semibold text-gray-900 bg-blue-50 px-3 py-1 rounded">{formatDate(jovem.data_nasc)}</dd>
                </div>
                <div class="flex justify-between items-center py-2 border-b border-gray-100">
                  <dt class="text-sm font-medium text-gray-500 uppercase tracking-wide">Estado Civil</dt>
                  <dd class="text-sm font-semibold text-gray-900">{jovem.estado_civil || 'Não informado'}</dd>
                </div>
                <div class="flex justify-between items-center py-2 border-b border-gray-100">
                  <dt class="text-sm font-medium text-gray-500 uppercase tracking-wide">Namora</dt>
                  <dd class="text-sm font-semibold text-gray-900">{jovem.namora ? 'Sim' : 'Não'}</dd>
                </div>
                <div class="flex justify-between items-center py-2">
                  <dt class="text-sm font-medium text-gray-500 uppercase tracking-wide">Tem Filho</dt>
                  <dd class="text-sm font-semibold text-gray-900">{jovem.tem_filho ? 'Sim' : 'Não'}</dd>
                </div>
              </dl>
            </div>
          </div>

          <!-- Localização -->
          <div class="bg-white rounded-lg shadow-sm border border-blue-200 overflow-hidden">
            <div class="bg-blue-600 px-6 py-3 relative">
              <div class="absolute left-0 top-0 bottom-0 w-2 bg-blue-800 rounded-r"></div>
              <h3 class="text-lg font-semibold text-white ml-3">Localização</h3>
            </div>
            <div class="p-6">
              <dl class="space-y-4">
                <div class="flex justify-between items-center py-2 border-b border-gray-100">
                  <dt class="text-sm font-medium text-gray-500 uppercase tracking-wide">Estado</dt>
                  <dd class="text-sm font-semibold text-gray-900">{jovem.estado?.nome || 'Não informado'}</dd>
                </div>
                <div class="flex justify-between items-center py-2 border-b border-gray-100">
                  <dt class="text-sm font-medium text-gray-500 uppercase tracking-wide">Bloco</dt>
                  <dd class="text-sm font-semibold text-gray-900">{jovem.bloco?.nome || 'Não informado'}</dd>
                </div>
                <div class="flex justify-between items-center py-2 border-b border-gray-100">
                  <dt class="text-sm font-medium text-gray-500 uppercase tracking-wide">Região</dt>
                  <dd class="text-sm font-semibold text-gray-900">{jovem.regiao?.nome || 'Não informado'}</dd>
                </div>
                <div class="flex justify-between items-center py-2 border-b border-gray-100">
                  <dt class="text-sm font-medium text-gray-500 uppercase tracking-wide">Igreja</dt>
                  <dd class="text-sm font-semibold text-gray-900">{jovem.igreja?.nome || 'Não informado'}</dd>
                </div>
                <div class="flex justify-between items-center py-2">
                  <dt class="text-sm font-medium text-gray-500 uppercase tracking-wide">Edição</dt>
                  <dd class="text-sm font-semibold text-gray-900">{jovem.edicao || 'Não informado'}</dd>
                </div>
              </dl>
            </div>
          </div>

          <!-- Observações e Redes Sociais -->
          <div class="bg-white rounded-lg shadow-sm border border-blue-200 overflow-hidden">
            <div class="bg-blue-600 px-6 py-3 relative">
              <div class="absolute left-0 top-0 bottom-0 w-2 bg-blue-800 rounded-r"></div>
              <h3 class="text-lg font-semibold text-white ml-3">Observações e Redes Sociais</h3>
            </div>
            <div class="p-6">
              <dl class="space-y-4">
                <div class="flex justify-between items-start py-2 border-b border-gray-100">
                  <dt class="text-sm font-medium text-gray-500 uppercase tracking-wide">Observação</dt>
                  <dd class="text-sm font-semibold text-gray-900 text-right max-w-md">{jovem.observacao || 'Não informado'}</dd>
                </div>
                <div class="flex justify-between items-start py-2 border-b border-gray-100">
                  <dt class="text-sm font-medium text-gray-500 uppercase tracking-wide">Testemunho</dt>
                  <dd class="text-sm font-semibold text-gray-900 text-right max-w-md">{jovem.testemunho || 'Não informado'}</dd>
                </div>
                <div class="flex justify-between items-center py-2 border-b border-gray-100">
                  <dt class="text-sm font-medium text-gray-500 uppercase tracking-wide">Instagram</dt>
                  <dd class="text-sm font-semibold text-gray-900">{jovem.instagram || 'Não informado'}</dd>
                </div>
                <div class="flex justify-between items-center py-2 border-b border-gray-100">
                  <dt class="text-sm font-medium text-gray-500 uppercase tracking-wide">Facebook</dt>
                  <dd class="text-sm font-semibold text-gray-900">{jovem.facebook || 'Não informado'}</dd>
                </div>
                <div class="flex justify-between items-center py-2">
                  <dt class="text-sm font-medium text-gray-500 uppercase tracking-wide">TikTok</dt>
                  <dd class="text-sm font-semibold text-gray-900">{jovem.tiktok || 'Não informado'}</dd>
                </div>
              </dl>
            </div>
          </div>
          
          <!-- Seção IntelliMen -->
          <div class="bg-white rounded-lg shadow-sm border border-blue-200 overflow-hidden">
            <div class="bg-blue-600 px-6 py-3 relative">
              <div class="absolute left-0 top-0 bottom-0 w-2 bg-blue-800 rounded-r"></div>
              <h3 class="text-lg font-semibold text-white ml-3">Sobre o IntelliMen</h3>
            </div>
            <div class="p-6">
              <dl class="space-y-4">
                <div class="flex justify-between items-center py-2 border-b border-gray-100">
                  <dt class="text-sm font-medium text-blue-600 uppercase tracking-wide font-bold">Formado no IntelliMen</dt>
                  <dd class="text-sm font-semibold text-gray-900 bg-blue-50 px-3 py-1 rounded">
                    {jovem.formado_intellimen ? 'Sim' : 'Não'}
                  </dd>
                </div>
                <div class="flex justify-between items-center py-2 border-b border-gray-100">
                  <dt class="text-sm font-medium text-blue-600 uppercase tracking-wide font-bold">Fazendo os Desafios</dt>
                  <dd class="text-sm font-semibold text-gray-900 bg-blue-50 px-3 py-1 rounded">
                    {jovem.fazendo_desafios ? 'Sim' : 'Não'}
                  </dd>
                </div>
                {#if jovem.fazendo_desafios && jovem.qual_desafio}
                  <div class="flex justify-between items-center py-2">
                    <dt class="text-sm font-medium text-blue-600 uppercase tracking-wide font-bold">Qual Desafio</dt>
                    <dd class="text-sm font-semibold text-gray-900 bg-blue-50 px-3 py-1 rounded">{jovem.qual_desafio}</dd>
                  </div>
                {/if}
              </dl>
            </div>
          </div>
        </div>
        
      {:else if activeTab === 'espirituais'}
        <!-- Dados Espirituais -->
        <div class="space-y-6">
          <!-- Informações Espirituais -->
          <div class="bg-white rounded-lg shadow-sm border border-red-200 overflow-hidden">
            <div class="bg-red-600 px-6 py-3 relative">
              <div class="absolute left-0 top-0 bottom-0 w-2 bg-red-800 rounded-r"></div>
              <h3 class="text-lg font-semibold text-white ml-3">Informações Espirituais</h3>
            </div>
            <div class="p-6">
              <dl class="space-y-4">
                <div class="flex justify-between items-center py-2 border-b border-gray-100">
                  <dt class="text-sm font-medium text-red-600 uppercase tracking-wide font-bold">Tempo de Igreja</dt>
                  <dd class="text-sm font-semibold text-gray-900 bg-red-50 px-3 py-1 rounded">{jovem.tempo_igreja || 'Não informado'}</dd>
                </div>
                <div class="flex justify-between items-center py-2 border-b border-gray-100">
                  <dt class="text-sm font-medium text-red-600 uppercase tracking-wide font-bold">Batizado nas Águas</dt>
                  <dd class="text-sm font-semibold text-gray-900 bg-red-50 px-3 py-1 rounded">
                    {jovem.batizado_aguas ? 'Sim' : 'Não'}
                    {#if jovem.batizado_aguas && jovem.data_batismo_aguas}
                      <span class="text-gray-500 ml-2">({formatDate(jovem.data_batismo_aguas)})</span>
                    {/if}
                  </dd>
                </div>
                <div class="flex justify-between items-center py-2 border-b border-gray-100">
                  <dt class="text-sm font-medium text-gray-500 uppercase tracking-wide">Data do Batismo nas Águas</dt>
                  <dd class="text-sm font-semibold text-gray-900">{jovem.data_batismo_aguas ? formatDate(jovem.data_batismo_aguas) : 'Não informado'}</dd>
                </div>
                <div class="flex justify-between items-center py-2 border-b border-gray-100">
                  <dt class="text-sm font-medium text-red-600 uppercase tracking-wide font-bold">Batizado com ES</dt>
                  <dd class="text-sm font-semibold text-gray-900 bg-red-50 px-3 py-1 rounded">
                    {jovem.batizado_es ? 'Sim' : 'Não'}
                    {#if jovem.batizado_es && jovem.data_batismo_es}
                      <span class="text-gray-500 ml-2">({formatDate(jovem.data_batismo_es)})</span>
                    {/if}
                  </dd>
                </div>
                <div class="flex justify-between items-center py-2 border-b border-gray-100">
                  <dt class="text-sm font-medium text-gray-500 uppercase tracking-wide">Data do Batismo com ES</dt>
                  <dd class="text-sm font-semibold text-gray-900">{jovem.data_batismo_es ? formatDate(jovem.data_batismo_es) : 'Não informado'}</dd>
                </div>
                <div class="flex justify-between items-center py-2 border-b border-gray-100">
                  <dt class="text-sm font-medium text-red-600 uppercase tracking-wide font-bold">Condição</dt>
                  <dd class="text-sm font-semibold text-gray-900 bg-red-50 px-3 py-1 rounded">{jovem.condicao || 'Não informado'}</dd>
                </div>
                <div class="flex justify-between items-center py-2 border-b border-gray-100">
                  <dt class="text-sm font-medium text-gray-500 uppercase tracking-wide">Tempo de Condição</dt>
                  <dd class="text-sm font-semibold text-gray-900">{jovem.tempo_condicao || 'Não informado'}</dd>
                </div>
                <div class="flex justify-between items-center py-2">
                  <dt class="text-sm font-medium text-gray-500 uppercase tracking-wide">Responsabilidade na Igreja</dt>
                  <dd class="text-sm font-semibold text-gray-900">{jovem.responsabilidade_igreja || 'Não informado'}</dd>
                </div>
              </dl>
            </div>
          </div>

          <!-- Experiência na Igreja -->
          <div class="bg-white rounded-lg shadow-sm border border-red-200 overflow-hidden">
            <div class="bg-red-600 px-6 py-3 relative">
              <div class="absolute left-0 top-0 bottom-0 w-2 bg-red-800 rounded-r"></div>
              <h3 class="text-lg font-semibold text-white ml-3">Experiência na Igreja</h3>
            </div>
            <div class="p-6">
              <dl class="space-y-4">
                <div class="flex justify-between items-center py-2 border-b border-gray-100">
                  <dt class="text-sm font-medium text-gray-500 uppercase tracking-wide">Já Fez a Obra no Altar</dt>
                  <dd class="text-sm font-semibold text-gray-900">{jovem.ja_obra_altar ? 'Sim' : 'Não'}</dd>
                </div>
                <div class="flex justify-between items-center py-2 border-b border-gray-100">
                  <dt class="text-sm font-medium text-gray-500 uppercase tracking-wide">Já Foi Obreiro</dt>
                  <dd class="text-sm font-semibold text-gray-900">{jovem.ja_obreiro ? 'Sim' : 'Não'}</dd>
                </div>
                <div class="flex justify-between items-center py-2 border-b border-gray-100">
                  <dt class="text-sm font-medium text-gray-500 uppercase tracking-wide">Já Foi Colaborador</dt>
                  <dd class="text-sm font-semibold text-gray-900">{jovem.ja_colaborador ? 'Sim' : 'Não'}</dd>
                </div>
                <div class="flex justify-between items-center py-2 border-b border-gray-100">
                  <dt class="text-sm font-medium text-gray-500 uppercase tracking-wide">Já Se Afastou Alguma Vez</dt>
                  <dd class="text-sm font-semibold text-gray-900">{jovem.afastado ? 'Sim' : 'Não'}</dd>
                </div>
                <div class="flex justify-between items-center py-2 border-b border-gray-100">
                  <dt class="text-sm font-medium text-gray-500 uppercase tracking-wide">Os Pais São da Igreja</dt>
                  <dd class="text-sm font-semibold text-gray-900">{jovem.pais_na_igreja ? 'Sim' : 'Não'}</dd>
                </div>
                <div class="flex justify-between items-center py-2 border-b border-gray-100">
                  <dt class="text-sm font-medium text-gray-500 uppercase tracking-wide">Observação sobre os Pais</dt>
                  <dd class="text-sm font-semibold text-gray-900">{jovem.observacao_pais || 'Não informado'}</dd>
                </div>
                <div class="flex justify-between items-center py-2 border-b border-gray-100">
                  <dt class="text-sm font-medium text-gray-500 uppercase tracking-wide">Tem Familiares na Igreja</dt>
                  <dd class="text-sm font-semibold text-gray-900">{jovem.familiares_igreja ? 'Sim' : 'Não'}</dd>
                </div>
                <div class="flex justify-between items-center py-2">
                  <dt class="text-sm font-medium text-gray-500 uppercase tracking-wide">Deseja o Altar</dt>
                  <dd class="text-sm font-semibold text-gray-900">{jovem.deseja_altar ? 'Sim' : 'Não'}</dd>
                </div>
              </dl>
            </div>
          </div>

        </div>
        
      {:else if activeTab === 'profissionais'}
        <!-- Dados Profissionais -->
        <div class="space-y-6">
          <!-- Informações Profissionais -->
          <div class="bg-white rounded-lg shadow-sm border border-blue-200 overflow-hidden">
            <div class="bg-blue-600 px-6 py-3 relative">
              <div class="absolute left-0 top-0 bottom-0 w-2 bg-blue-800 rounded-r"></div>
              <h3 class="text-lg font-semibold text-white ml-3">Informações Profissionais</h3>
            </div>
            <div class="p-6">
              <dl class="space-y-4">
                <div class="flex justify-between items-center py-2 border-b border-gray-100">
                  <dt class="text-sm font-medium text-blue-600 uppercase tracking-wide font-bold">Trabalha</dt>
                  <dd class="text-sm font-semibold text-gray-900 bg-blue-50 px-3 py-1 rounded">{jovem.trabalha ? 'Sim' : 'Não'}</dd>
                </div>
                {#if jovem.trabalha}
                  <div class="flex justify-between items-center py-2 border-b border-gray-100">
                    <dt class="text-sm font-medium text-gray-500 uppercase tracking-wide">Nome da Empresa</dt>
                    <dd class="text-sm font-semibold text-gray-900">{jovem.local_trabalho || 'Não informado'}</dd>
                  </div>
                {/if}
                <div class="flex justify-between items-center py-2 border-b border-gray-100">
                  <dt class="text-sm font-medium text-gray-500 uppercase tracking-wide">Trabalha Com</dt>
                  <dd class="text-sm font-semibold text-gray-900">{jovem.formacao || 'Não informado'}</dd>
                </div>
                <div class="flex justify-between items-center py-2 border-b border-gray-100">
                  <dt class="text-sm font-medium text-gray-500 uppercase tracking-wide">Profissão</dt>
                  <dd class="text-sm font-semibold text-gray-900">{jovem.formacao || 'Não informado'}</dd>
                </div>
                <div class="flex justify-between items-center py-2 border-b border-gray-100">
                  <dt class="text-sm font-medium text-gray-500 uppercase tracking-wide">Escolaridade</dt>
                  <dd class="text-sm font-semibold text-gray-900">{jovem.escolaridade || 'Não informado'}</dd>
                </div>
                <div class="flex justify-between items-center py-2 border-b border-gray-100">
                  <dt class="text-sm font-medium text-gray-500 uppercase tracking-wide">Tem Dívidas</dt>
                  <dd class="text-sm font-semibold text-gray-900">{jovem.tem_dividas ? 'Sim' : 'Não'}</dd>
                </div>
                {#if jovem.tem_dividas && jovem.valor_divida}
                  <div class="flex justify-between items-center py-2">
                    <dt class="text-sm font-medium text-gray-500 uppercase tracking-wide">Valor da Dívida</dt>
                    <dd class="text-sm font-semibold text-gray-900">R$ {jovem.valor_divida.toLocaleString('pt-BR', { minimumFractionDigits: 2 })}</dd>
                  </div>
                {/if}
              </dl>
            </div>
          </div>
        </div>
        
      {:else if activeTab === 'avaliacoes' && !hasRole('jovem')($userProfile)}
        <!-- Avaliações -->
        <div class="space-y-6">
          <!-- Botão para nova avaliação -->
          <div class="flex justify-end">
            <Button
              variant="primary"
              on:click={openAvaliacaoModal}
            >
              <svg class="w-5 h-5 mr-2" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 6v6m0 0v6m0-6h6m-6 0H6" />
              </svg>
              Nova Avaliação
            </Button>
          </div>
          
          <!-- Lista de avaliações -->
          <AvaliacoesList bind:this={avaliacoesListComponent} {jovemId} {jovem} />
        </div>
        
      {:else if activeTab === 'historico'}
        <!-- Histórico -->
        <div class="text-center py-12">
          <div class="w-16 h-16 bg-gray-100 rounded-full flex items-center justify-center mx-auto mb-4">
            <svg class="w-8 h-8 text-gray-600" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z" />
            </svg>
          </div>
          <h3 class="text-lg font-semibold text-gray-900 mb-2">Histórico de Alterações</h3>
          <p class="text-gray-600">Esta funcionalidade será implementada em breve.</p>
        </div>
      {/if}
    </div>
  </div>
{/if}

<!-- Modal de Avaliação -->
<AvaliacaoModal
  bind:isOpen={showAvaliacaoModal}
  jovemId={jovemId}
  jovemNome={jovem?.nome_completo || ''}
  on:close={closeAvaliacaoModal}
  on:success={handleAvaliacaoSuccess}
/>
