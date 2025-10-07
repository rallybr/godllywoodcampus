<script>
  import { onMount } from 'svelte';
  import { page } from '$app/stores';
  import { loadJovemById, aprovarJovem, buscarAprovacoesJovem, verificarSeUsuarioJaAprovou, removerAprovacaoAdmin } from '$lib/stores/jovens-simple';
  import { goto } from '$app/navigation';
  import Button from '$lib/components/ui/Button.svelte';
  import Card from '$lib/components/ui/Card.svelte';
  import AvaliacoesList from './AvaliacoesList.svelte';
  import { userProfile, hasRole } from '$lib/stores/auth';
  import AvaliacaoModal from '$lib/components/modals/AvaliacaoModal.svelte';
  import AssociarUsuarioModal from '$lib/components/modals/AssociarUsuarioModal.svelte';
  import AssociacoesJovem from './AssociacoesJovem.svelte';
  import DadosNucleoView from './DadosNucleoView.svelte';
  import { format, parseISO } from 'date-fns';
  import { ptBR } from 'date-fns/locale';
  
  // @ts-ignore
  export let jovemId;
  
  // @ts-ignore
  let jovem = null;
  let loading = true;
  let error = '';
  let activeTab = 'dados-pessoais';
  let isApproving = false;
  let showAvaliacaoModal = false;
  let showAssociarModal = false;
  // @ts-ignore
  let avaliacoesListComponent = null;
  // @ts-ignore
  let aprovacoes = [];
  let usuarioJaAprovouAprovado = false;
  let usuarioJaAprovouPreAprovado = false;
  let aprovacoesTab = 'pre_aprovado';
  let removendoAprovacao = false; // Aba ativa por padrão
  
  const tabs = [
    { id: 'dados-pessoais', label: 'Dados Pessoais', icon: 'M16 7a4 4 0 11-8 0 4 4 0 018 0zM12 14a7 7 0 00-7 7h14a7 7 0 00-7-7z' },
    { id: 'espirituais', label: 'Espirituais', icon: 'M9.663 17h4.673M12 3v1m6.364 1.636l-.707.707M21 12h-1M4 12H3m3.343-5.657l-.707-.707m2.828 9.9a5 5 0 117.072 0l-.548.547A3.374 3.374 0 0014 18.469V19a2 2 0 11-4 0v-.531c0-.895-.356-1.754-.988-2.386l-.548-.547z' },
    { id: 'profissionais', label: 'Profissionais', icon: 'M21 13.255A23.931 23.931 0 0112 15c-3.183 0-6.22-.62-9-1.745M16 6V4a2 2 0 00-2-2h-4a2 2 0 00-2-2v2m8 0V6a2 2 0 012 2v6a2 2 0 01-2 2H6a2 2 0 01-2-2V8a2 2 0 012-2V6' },
    // Aba de avaliações será exibida apenas se não for papel jovem
    { id: 'avaliacoes', label: 'Avaliações', icon: 'M9 19v-6a2 2 0 00-2-2H5a2 2 0 00-2 2v6a2 2 0 002 2h2a2 2 0 002-2zm0 0V9a2 2 0 012-2h2a2 2 0 012 2v10m-6 0a2 2 0 002 2h2a2 2 0 002-2m0 0V5a2 2 0 012-2h2a2 2 0 012 2v14a2 2 0 01-2 2h-2a2 2 0 01-2-2z' },
    { id: 'associacoes', label: 'Associações', icon: 'M17 20h5v-2a3 3 0 00-5.356-1.857M17 20H7m10 0v-2c0-.656-.126-1.283-.356-1.857M7 20H2v-2a3 3 0 015.356-1.857M7 20v-2c0-.656.126-1.283.356-1.857m0 0a5.002 5.002 0 019.288 0M15 7a3 3 0 11-6 0 3 3 0 016 0zm6 3a2 2 0 11-4 0 2 2 0 014 0zM7 10a2 2 0 11-4 0 2 2 0 014 0z' },
    { id: 'nucleo', label: 'Núcleo de Oração', icon: 'M9.663 17h4.673M12 3v1m6.364 1.636l-.707.707M21 12h-1M4 12H3m3.343-5.657l-.707-.707m2.828 9.9a5 5 0 117.072 0l-.548.547A3.374 3.374 0 0014 18.469V19a2 2 0 11-4 0v-.531c0-.895-.356-1.754-.988-2.386l-.548-.547z' },
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
        
        // Debug específico para dados geográficos
        console.log('🔍 DEBUG - Dados geográficos do jovem:', {
          estado: jovem.estados,
          bloco: jovem.blocos,
          regiao: jovem.regioes,
          igreja: jovem.igrejas
        });
        console.log('🔍 DEBUG - Nomes geográficos:', {
          estado_nome: jovem.estados?.nome,
          bloco_nome: jovem.blocos?.nome,
          regiao_nome: jovem.regioes?.nome,
          igreja_nome: jovem.igrejas?.nome
        });
        
        // Carregar aprovações do jovem
        await loadAprovacoes();
      }
    } catch (err) {
      error = err.message;
    } finally {
      loading = false;
    }
  }
  
  async function loadAprovacoes() {
    try {
      // Buscar todas as aprovações do jovem
      aprovacoes = await buscarAprovacoesJovem(jovemId);
      
      // Verificar se o usuário atual já aprovou
      usuarioJaAprovouAprovado = await verificarSeUsuarioJaAprovou(jovemId, 'aprovado');
      usuarioJaAprovouPreAprovado = await verificarSeUsuarioJaAprovou(jovemId, 'pre_aprovado');
    } catch (err) {
      console.error('Erro ao carregar aprovações:', err);
    }
  }

  async function handleRemoverAprovacao(aprovacaoId, usuarioNome, tipoAprovacao) {
    if (!confirm(`Tem certeza que deseja remover a ${tipoAprovacao === 'aprovado' ? 'aprovação' : 'pré-aprovação'} de ${usuarioNome}?`)) {
      return;
    }

    removendoAprovacao = true;
    try {
      await removerAprovacaoAdmin(aprovacaoId);
      // Recarregar aprovações após remoção
      await loadAprovacoes();
      alert('Aprovação removida com sucesso!');
    } catch (err) {
      console.error('Erro ao remover aprovação:', err);
      alert('Erro ao remover aprovação: ' + err.message);
    } finally {
      removendoAprovacao = false;
    }
  }
  
  // @ts-ignore
  async function handleAprovar(status) {
    if (!jovem) return;
    
    isApproving = true;
    try {
      await aprovarJovem(jovem.id, status);
      
      // Recarregar aprovações após aprovar
      await loadAprovacoes();
      
      // Atualizar status do jovem baseado nas aprovações
      if (aprovacoes.some(a => a.tipo_aprovacao === 'aprovado')) {
        jovem.aprovado = 'aprovado';
      } else if (aprovacoes.some(a => a.tipo_aprovacao === 'pre_aprovado')) {
        jovem.aprovado = 'pre_aprovado';
      }
    } catch (err) {
      error = err.message;
    } finally {
      isApproving = false;
    }
  }

  function verFicha() {
    goto(`/jovens/${jovem.id}/ficha`);
  }
  
  // @ts-ignore
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
  
  // @ts-ignore
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
  
  // @ts-ignore
  function formatDate(dateString) {
    if (!dateString) return 'Não informado';
    try {
      return format(parseISO(dateString), 'dd/MM/yyyy', { locale: ptBR });
    } catch {
      return dateString;
    }
  }
  
  // @ts-ignore
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

  function openAssociarModal() {
    showAssociarModal = true;
  }

  function closeAssociarModal() {
    showAssociarModal = false;
  }
  
  // @ts-ignore
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
  <div class="max-w-6xl mx-auto px-2 sm:px-4 lg:px-6 overflow-x-hidden">
    <!-- Header -->
    <div class="bg-white rounded-lg shadow-sm border border-gray-200 overflow-hidden mb-4 sm:mb-6">
      <!-- Header azul com nome e edição -->
      <div class="bg-blue-600 px-3 sm:px-4 lg:px-6 py-3 sm:py-4 lg:py-5 text-center">
        <h1 class="text-lg sm:text-xl lg:text-2xl xl:text-3xl font-bold text-white mb-1 sm:mb-2 break-words">{jovem.nome_completo}</h1>
        <p class="text-white text-xs sm:text-sm lg:text-base font-medium">{jovem.edicao || 'Não informado'}</p>
      </div>
      
      <!-- Conteúdo do header -->
      <div class="p-3 sm:p-4 lg:p-6 xl:p-8">
        <div class="flex flex-col lg:flex-row items-center lg:items-start space-y-3 sm:space-y-4 lg:space-y-0 lg:space-x-4 xl:space-x-6 2xl:space-x-8">
          <!-- Foto -->
          <div class="flex-shrink-0">
            {#if jovem.foto}
              <img class="w-24 h-28 sm:w-28 sm:h-32 lg:w-32 lg:h-36 xl:w-36 xl:h-44 rounded-xl object-cover border-2 sm:border-4 border-blue-500 shadow-lg" src={jovem.foto} alt={jovem.nome_completo} />
            {:else}
              <div class="w-24 h-28 sm:w-28 sm:h-32 lg:w-32 lg:h-36 xl:w-36 xl:h-44 bg-gradient-to-br from-blue-500 to-purple-600 rounded-xl flex items-center justify-center border-2 sm:border-4 border-blue-500 shadow-lg">
                <span class="text-white font-bold text-2xl sm:text-3xl lg:text-4xl">{jovem.nome_completo?.charAt(0) || 'J'}</span>
              </div>
            {/if}
          </div>
          
          <!-- Informações básicas -->
          <div class="flex-1 w-full">
            <div class="flex flex-col lg:flex-row lg:items-start lg:justify-between space-y-4 lg:space-y-0">
              <div class="space-y-2 sm:space-y-3">
                <!-- Lista organizada de dados -->
                <div class="space-y-2 sm:space-y-3">
                  <div class="flex items-center space-x-2 sm:space-x-3">
                    <span class="text-gray-500 text-xs sm:text-sm font-medium w-12 sm:w-16">Estado:</span>
                    <span class="text-gray-700 text-sm sm:text-base font-semibold">{jovem.estados?.nome || 'Não informado'}</span>
                  </div>
                  <div class="flex items-center space-x-2 sm:space-x-3">
                    <span class="text-gray-500 text-xs sm:text-sm font-medium w-12 sm:w-16">Bloco:</span>
                    <span class="text-gray-700 text-sm sm:text-base font-semibold">{jovem.blocos?.nome || 'Não informado'}</span>
                  </div>
                  <div class="flex items-center space-x-2 sm:space-x-3">
                    <span class="text-gray-500 text-xs sm:text-sm font-medium w-12 sm:w-16">Região:</span>
                    <span class="text-gray-700 text-sm sm:text-base font-semibold">{jovem.regioes?.nome || 'Não informado'}</span>
                  </div>
                  <div class="flex items-center space-x-2 sm:space-x-3">
                    <span class="text-gray-500 text-xs sm:text-sm font-medium w-12 sm:w-16">Igreja:</span>
                    <span class="text-gray-700 text-sm sm:text-base font-semibold">{jovem.igrejas?.nome || 'Não informado'}</span>
                  </div>
                  <div class="flex items-center space-x-2 sm:space-x-3">
                    <span class="text-gray-500 text-xs sm:text-sm font-medium w-12 sm:w-16">Idade:</span>
                    <span class="text-gray-700 text-sm sm:text-base font-semibold">{jovem.idade || 'Não informado'} anos</span>
                  </div>
                  <div class="flex items-center space-x-2 sm:space-x-3">
                    <span class="text-gray-500 text-xs sm:text-sm font-medium w-12 sm:w-16">Sexo:</span>
                    <span class="text-gray-700 text-sm sm:text-base font-semibold">{jovem.sexo || 'Não informado'}</span>
                  </div>
                </div>
              </div>
              
            </div>
          </div>
        </div>
      </div>
    </div>
    
    <!-- Botões de Ação - Responsivo para todas as telas -->
    {#if !hasRole('jovem')($userProfile)}
      <div class="mt-4 sm:mt-6 space-y-2 sm:space-y-3">
        <!-- Primeira linha: Pré-aprovar | Aprovar | Associar -->
        <div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-2 sm:gap-3">
          <!-- Botão Pré-aprovar -->
          <button
            on:click={() => handleAprovar('pre_aprovado')}
            disabled={isApproving}
            class="flex items-center justify-center space-x-1 sm:space-x-2 px-2 sm:px-3 py-2 sm:py-3 text-xs sm:text-sm font-medium rounded-lg transition-all duration-200 transform hover:scale-105 focus:outline-none focus:ring-2 focus:ring-offset-2 {usuarioJaAprovouPreAprovado 
              ? 'bg-gradient-to-r from-purple-500 to-purple-600 text-white shadow-lg shadow-purple-200' 
              : 'bg-gradient-to-r from-purple-100 to-purple-200 text-purple-700 hover:from-purple-200 hover:to-purple-300 border border-purple-300'}"
          >
            <svg class="w-3 h-3 sm:w-4 sm:h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z" />
            </svg>
            <span class="hidden xs:inline">{usuarioJaAprovouPreAprovado ? 'Pré-aprovado por você' : 'Pré-aprovar'}</span>
            <span class="xs:hidden">{usuarioJaAprovouPreAprovado ? 'Pré-aprovado' : 'Pré-aprovar'}</span>
          </button>
          
          <!-- Botão Aprovar -->
          <button
            on:click={() => handleAprovar('aprovado')}
            disabled={isApproving}
            class="flex items-center justify-center space-x-1 sm:space-x-2 px-2 sm:px-3 py-2 sm:py-3 text-xs sm:text-sm font-medium rounded-lg transition-all duration-200 transform hover:scale-105 focus:outline-none focus:ring-2 focus:ring-offset-2 {usuarioJaAprovouAprovado 
              ? 'bg-gradient-to-r from-blue-500 to-blue-600 text-white shadow-lg shadow-blue-200' 
              : 'bg-gradient-to-r from-blue-100 to-blue-200 text-blue-700 hover:from-blue-200 hover:to-blue-300 border border-blue-300'}"
          >
            <svg class="w-3 h-3 sm:w-4 sm:h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7" />
            </svg>
            <span class="hidden xs:inline">{usuarioJaAprovouAprovado ? 'Aprovado por você' : 'Aprovar'}</span>
            <span class="xs:hidden">{usuarioJaAprovouAprovado ? 'Aprovado' : 'Aprovar'}</span>
          </button>
          
          <!-- Botão Associar (apenas para administrador) -->
          {#if $userProfile?.nivel === 'administrador'}
            <button
              on:click={openAssociarModal}
              class="flex items-center justify-center space-x-1 sm:space-x-2 px-2 sm:px-3 py-2 sm:py-3 text-xs sm:text-sm font-medium rounded-lg transition-all duration-200 transform hover:scale-105 focus:outline-none focus:ring-2 focus:ring-offset-2 bg-gradient-to-r from-indigo-100 to-indigo-200 text-indigo-700 hover:from-indigo-200 hover:to-indigo-300 border border-indigo-300"
            >
              <svg class="w-3 h-3 sm:w-4 sm:h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4v4m0 0v4m0-4h4m-4 0H8" />
              </svg>
              <span class="hidden xs:inline">Associar</span>
              <span class="xs:hidden">Associar</span>
            </button>
          {:else}
            <div class="hidden lg:block"></div>
          {/if}
        </div>
        
        <!-- Segunda linha: Ver Ficha | Progresso | Editar -->
        <div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-2 sm:gap-3">
          <!-- Botão Ver Ficha -->
          <button
            on:click={() => goto(`/jovens/${jovem.id}/ficha`)}
            class="flex items-center justify-center space-x-1 sm:space-x-2 px-2 sm:px-3 py-2 sm:py-3 text-xs sm:text-sm font-medium rounded-lg transition-all duration-200 transform hover:scale-105 focus:outline-none focus:ring-2 focus:ring-offset-2 bg-gradient-to-r from-gray-100 to-gray-200 text-gray-700 hover:from-gray-200 hover:to-gray-300 border border-gray-300"
          >
            <svg class="w-3 h-3 sm:w-4 sm:h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z" />
            </svg>
            <span class="hidden xs:inline">Ver Ficha</span>
            <span class="xs:hidden">Ficha</span>
          </button>
          
          <!-- Botão Progresso -->
          <button
            on:click={() => goto(`/progresso?jovem=${jovem.id}`)}
            class="flex items-center justify-center space-x-1 sm:space-x-2 px-2 sm:px-3 py-2 sm:py-3 text-xs sm:text-sm font-medium rounded-lg transition-all duration-200 transform hover:scale-105 focus:outline-none focus:ring-2 focus:ring-offset-2 bg-gradient-to-r from-teal-500 to-teal-600 text-white shadow-lg shadow-teal-200 hover:from-teal-600 hover:to-teal-700"
          >
            <svg class="w-3 h-3 sm:w-4 sm:h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3 10h4l3 10 4-18 3 8h4" />
            </svg>
            <span class="hidden xs:inline">Progresso</span>
            <span class="xs:hidden">Progresso</span>
          </button>
          
          <!-- Botão Editar -->
          <button
            on:click={() => goto(`/jovens/${jovem.id}/editar`)}
            class="flex items-center justify-center space-x-1 sm:space-x-2 px-2 sm:px-3 py-2 sm:py-3 text-xs sm:text-sm font-medium rounded-lg transition-all duration-200 transform hover:scale-105 focus:outline-none focus:ring-2 focus:ring-offset-2 bg-gradient-to-r from-orange-100 to-orange-200 text-orange-700 hover:from-orange-200 hover:to-orange-300 border border-orange-300"
          >
            <svg class="w-3 h-3 sm:w-4 sm:h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M11 5H6a2 2 0 00-2 2v11a2 2 0 002 2h11a2 2 0 002-2v-5m-1.414-9.414a2 2 0 112.828 2.828L11.828 15H9v-2.828l8.586-8.586z" />
            </svg>
            <span class="hidden xs:inline">Editar</span>
            <span class="xs:hidden">Editar</span>
          </button>
        </div>
      </div>
    {/if}
    
    <!-- Status e Histórico de Aprovações -->
    {#if !hasRole('jovem')($userProfile) && aprovacoes && aprovacoes.length > 0}
      <div class="mt-4 sm:mt-6 bg-white rounded-lg shadow-sm border border-gray-200 p-3 sm:p-4 lg:p-6">
        <h3 class="text-base sm:text-lg font-semibold text-gray-900 mb-3 sm:mb-4">Histórico de Aprovações</h3>
        
        
        <!-- Abas de Aprovações -->
        <div class="mb-4 sm:mb-6">
          <div class="flex flex-col sm:flex-row space-y-2 sm:space-y-0 sm:space-x-3">
            <button
              class="flex-1 py-2 sm:py-3 px-3 sm:px-4 rounded-lg font-semibold text-xs sm:text-sm transition-all duration-200 transform hover:scale-105 {aprovacoesTab === 'pre_aprovado' 
                ? 'bg-gradient-to-r from-purple-500 to-purple-600 text-white shadow-lg shadow-purple-200' 
                : 'bg-gradient-to-r from-purple-100 to-purple-200 text-purple-700 hover:from-purple-200 hover:to-purple-300 border border-purple-300'}"
              on:click={() => aprovacoesTab = 'pre_aprovado'}
            >
              <div class="flex items-center justify-center space-x-1 sm:space-x-2">
                <svg class="w-3 h-3 sm:w-4 sm:h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z" />
                </svg>
                <span class="hidden xs:inline">Pré-aprovado</span>
                <span class="xs:hidden">Pré-aprovado</span>
                <span class="bg-white bg-opacity-20 px-1 sm:px-2 py-1 rounded-full text-xs font-bold">
                  {aprovacoes.filter(a => a.tipo_aprovacao === 'pre_aprovado').length}
                </span>
              </div>
            </button>
            
            <button
              class="flex-1 py-2 sm:py-3 px-3 sm:px-4 rounded-lg font-semibold text-xs sm:text-sm transition-all duration-200 transform hover:scale-105 {aprovacoesTab === 'aprovado' 
                ? 'bg-gradient-to-r from-blue-500 to-blue-600 text-white shadow-lg shadow-blue-200' 
                : 'bg-gradient-to-r from-blue-100 to-blue-200 text-blue-700 hover:from-blue-200 hover:to-blue-300 border border-blue-300'}"
              on:click={() => aprovacoesTab = 'aprovado'}
            >
              <div class="flex items-center justify-center space-x-1 sm:space-x-2">
                <svg class="w-3 h-3 sm:w-4 sm:h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7" />
                </svg>
                <span class="hidden xs:inline">Aprovado</span>
                <span class="xs:hidden">Aprovado</span>
                <span class="bg-white bg-opacity-20 px-1 sm:px-2 py-1 rounded-full text-xs font-bold">
                  {aprovacoes.filter(a => a.tipo_aprovacao === 'aprovado').length}
                </span>
              </div>
            </button>
          </div>
        </div>
        
        <!-- Conteúdo das Abas -->
        <div class="space-y-2 sm:space-y-3">
          {#if aprovacoesTab === 'pre_aprovado'}
            <div class="space-y-2">
              <h4 class="text-xs sm:text-sm font-medium text-gray-700 mb-2 sm:mb-3">PRÉ-APROVADO POR:</h4>
              {#each aprovacoes.filter(a => a.tipo_aprovacao === 'pre_aprovado') as aprovacao}
                <div class="flex flex-col sm:flex-row sm:items-center sm:justify-between p-2 sm:p-3 bg-yellow-50 rounded-lg border border-yellow-200 space-y-2 sm:space-y-0">
                  <div class="flex items-center space-x-2 sm:space-x-3">
                    {#if aprovacao.usuario_estado_bandeira}
                      <img src={aprovacao.usuario_estado_bandeira} alt="Bandeira" class="w-5 h-3 sm:w-6 sm:h-4 rounded flex-shrink-0" />
                    {/if}
                    <div class="min-w-0 flex-1">
                      <div class="flex flex-col sm:flex-row sm:items-center space-y-1 sm:space-y-0 sm:space-x-2">
                        <span class="font-medium text-gray-900 text-sm sm:text-base truncate">{aprovacao.usuario_nome}</span>
                        <span class="text-xs text-gray-500 bg-gray-200 px-2 py-1 rounded-full inline-block w-fit">
                          {aprovacao.usuario_nivel}
                        </span>
                      </div>
                      <div class="text-xs text-gray-500">
                        {format(parseISO(aprovacao.criado_em), 'dd/MM/yyyy HH:mm', { locale: ptBR })}
                      </div>
                    </div>
                  </div>
                  <div class="flex items-center space-x-2 sm:ml-auto">
                    <span class="px-2 sm:px-3 py-1 rounded-full text-xs font-medium bg-yellow-100 text-yellow-800">
                      Pré-aprovado
                    </span>
                    <!-- Botão de remover (apenas para administradores) -->
                    {#if $userProfile?.nivel === 'administrador'}
                      <button
                        on:click={() => handleRemoverAprovacao(aprovacao.id, aprovacao.usuario_nome, aprovacao.tipo_aprovacao)}
                        disabled={removendoAprovacao}
                        class="flex items-center justify-center p-1 sm:p-2 text-red-600 hover:text-red-800 hover:bg-red-50 rounded-full transition-all duration-200 disabled:opacity-50 disabled:cursor-not-allowed"
                        title="Remover pré-aprovação"
                      >
                        <svg class="w-3 h-3 sm:w-4 sm:h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16" />
                        </svg>
                      </button>
                    {/if}
                  </div>
                </div>
              {/each}
              {#if aprovacoes.filter(a => a.tipo_aprovacao === 'pre_aprovado').length === 0}
                <div class="text-center py-6 sm:py-8 text-gray-500">
                  <div class="text-3xl sm:text-4xl mb-2">📝</div>
                  <p class="text-sm sm:text-base">Nenhuma pré-aprovação registrada</p>
                </div>
              {/if}
            </div>
          {:else if aprovacoesTab === 'aprovado'}
            <div class="space-y-2">
              <h4 class="text-xs sm:text-sm font-medium text-gray-700 mb-2 sm:mb-3">APROVADO POR:</h4>
              {#each aprovacoes.filter(a => a.tipo_aprovacao === 'aprovado') as aprovacao}
                <div class="flex flex-col sm:flex-row sm:items-center sm:justify-between p-2 sm:p-3 bg-green-50 rounded-lg border border-green-200 space-y-2 sm:space-y-0">
                  <div class="flex items-center space-x-2 sm:space-x-3">
                    {#if aprovacao.usuario_estado_bandeira}
                      <img src={aprovacao.usuario_estado_bandeira} alt="Bandeira" class="w-5 h-3 sm:w-6 sm:h-4 rounded flex-shrink-0" />
                    {/if}
                    <div class="min-w-0 flex-1">
                      <div class="flex flex-col sm:flex-row sm:items-center space-y-1 sm:space-y-0 sm:space-x-2">
                        <span class="font-medium text-gray-900 text-sm sm:text-base truncate">{aprovacao.usuario_nome}</span>
                        <span class="text-xs text-gray-500 bg-gray-200 px-2 py-1 rounded-full inline-block w-fit">
                          {aprovacao.usuario_nivel}
                        </span>
                      </div>
                      <div class="text-xs text-gray-500">
                        {format(parseISO(aprovacao.criado_em), 'dd/MM/yyyy HH:mm', { locale: ptBR })}
                      </div>
                    </div>
                  </div>
                  <div class="flex items-center space-x-2 sm:ml-auto">
                    <span class="px-2 sm:px-3 py-1 rounded-full text-xs font-medium bg-green-100 text-green-800">
                      Aprovado
                    </span>
                    <!-- Botão de remover (apenas para administradores) -->
                    {#if $userProfile?.nivel === 'administrador'}
                      <button
                        on:click={() => handleRemoverAprovacao(aprovacao.id, aprovacao.usuario_nome, aprovacao.tipo_aprovacao)}
                        disabled={removendoAprovacao}
                        class="flex items-center justify-center p-1 sm:p-2 text-red-600 hover:text-red-800 hover:bg-red-50 rounded-full transition-all duration-200 disabled:opacity-50 disabled:cursor-not-allowed"
                        title="Remover aprovação"
                      >
                        <svg class="w-3 h-3 sm:w-4 sm:h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16" />
                        </svg>
                      </button>
                    {/if}
                  </div>
                </div>
              {/each}
              {#if aprovacoes.filter(a => a.tipo_aprovacao === 'aprovado').length === 0}
                <div class="text-center py-6 sm:py-8 text-gray-500">
                  <div class="text-3xl sm:text-4xl mb-2">✅</div>
                  <p class="text-sm sm:text-base">Nenhuma aprovação registrada</p>
                </div>
              {/if}
            </div>
          {/if}
        </div>
      </div>
    {/if}
    
    <!-- Tabs -->
    <div class="bg-white rounded-lg shadow-sm border border-gray-200 mb-4 sm:mb-6">
      <div class="border-b border-gray-200">
        <nav class="-mb-px flex flex-wrap space-x-2 sm:space-x-4 lg:space-x-8 px-2 sm:px-4 lg:px-6">
          {#each tabs as tab}
            {#if !(tab.id === 'avaliacoes' && hasRole('jovem')($userProfile))}
            <button
              class="flex items-center space-x-1 sm:space-x-2 py-2 sm:py-3 lg:py-4 px-1 border-b-2 font-medium text-xs sm:text-sm {activeTab === tab.id ? 'border-blue-500 text-blue-600' : 'border-transparent text-gray-500 hover:text-gray-700 hover:border-gray-300'}"
              on:click={() => activeTab = tab.id}
            >
              <svg class="w-4 h-4 sm:w-5 sm:h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d={tab.icon} />
              </svg>
              <span class="hidden sm:inline">{tab.label}</span>
              <span class="sm:hidden">{tab.label.split(' ')[0]}</span>
            </button>
            {/if}
          {/each}
        </nav>
      </div>
    </div>
    
    <!-- Tab Content -->
    <div class="bg-white rounded-lg shadow-sm border border-gray-200 p-4 sm:p-6">
      {#if activeTab === 'dados-pessoais'}
        <!-- Dados Pessoais -->
        <div class="space-y-4 sm:space-y-6">
          <!-- Informações Pessoais -->
          <div class="bg-white rounded-lg shadow-sm border border-blue-200 overflow-hidden">
            <div class="bg-blue-600 px-4 sm:px-6 py-2 sm:py-3 relative">
              <div class="absolute left-0 top-0 bottom-0 w-1 sm:w-2 bg-blue-800 rounded-r"></div>
              <h3 class="text-base sm:text-lg font-semibold text-white ml-2 sm:ml-3">Informações Pessoais</h3>
            </div>
            <div class="p-4 sm:p-6">
              <dl class="space-y-3 sm:space-y-4">
                <div class="flex flex-col sm:flex-row sm:justify-between sm:items-center py-2 border-b border-gray-100 space-y-1 sm:space-y-0">
                  <dt class="text-xs sm:text-sm font-medium text-blue-600 uppercase tracking-wide font-bold">WhatsApp</dt>
                  <dd class="text-xs sm:text-sm font-semibold text-gray-900 bg-blue-50 px-2 sm:px-3 py-1 rounded">{formatPhone(jovem.whatsapp)}</dd>
                </div>
                <div class="flex flex-col sm:flex-row sm:justify-between sm:items-center py-2 border-b border-gray-100 space-y-1 sm:space-y-0">
                  <dt class="text-xs sm:text-sm font-medium text-blue-600 uppercase tracking-wide font-bold">Idade</dt>
                  <dd class="text-xs sm:text-sm font-semibold text-gray-900 bg-blue-50 px-2 sm:px-3 py-1 rounded">{jovem.idade} anos</dd>
                </div>
                <div class="flex flex-col sm:flex-row sm:justify-between sm:items-center py-2 border-b border-gray-100 space-y-1 sm:space-y-0">
                  <dt class="text-xs sm:text-sm font-medium text-blue-600 uppercase tracking-wide font-bold">Data de Nascimento</dt>
                  <dd class="text-xs sm:text-sm font-semibold text-gray-900 bg-blue-50 px-2 sm:px-3 py-1 rounded">{formatDate(jovem.data_nasc)}</dd>
                </div>
                <div class="flex flex-col sm:flex-row sm:justify-between sm:items-center py-2 border-b border-gray-100 space-y-1 sm:space-y-0">
                  <dt class="text-xs sm:text-sm font-medium text-blue-600 uppercase tracking-wide font-bold">Estado Civil</dt>
                  <dd class="text-xs sm:text-sm font-semibold text-gray-900">{jovem.estado_civil || 'Não informado'}</dd>
                </div>
                <div class="flex flex-col sm:flex-row sm:justify-between sm:items-center py-2 border-b border-gray-100 space-y-1 sm:space-y-0">
                  <dt class="text-xs sm:text-sm font-medium text-blue-600 uppercase tracking-wide font-bold">Namora</dt>
                  <dd class="text-xs sm:text-sm font-semibold text-gray-900">{jovem.namora ? 'Sim' : 'Não'}</dd>
                </div>
                <div class="flex flex-col sm:flex-row sm:justify-between sm:items-center py-2 space-y-1 sm:space-y-0">
                  <dt class="text-xs sm:text-sm font-medium text-blue-600 uppercase tracking-wide font-bold">Tem Filho</dt>
                  <dd class="text-xs sm:text-sm font-semibold text-gray-900">{jovem.tem_filho ? 'Sim' : 'Não'}</dd>
                </div>
              </dl>
            </div>
          </div>

          <!-- Localização -->
          <div class="bg-white rounded-lg shadow-sm border border-blue-200 overflow-hidden">
            <div class="bg-blue-600 px-4 sm:px-6 py-2 sm:py-3 relative">
              <div class="absolute left-0 top-0 bottom-0 w-1 sm:w-2 bg-blue-800 rounded-r"></div>
              <h3 class="text-base sm:text-lg font-semibold text-white ml-2 sm:ml-3">Localização</h3>
            </div>
            <div class="p-4 sm:p-6">
              <dl class="space-y-3 sm:space-y-4">
                <div class="flex flex-col sm:flex-row sm:justify-between sm:items-center py-2 border-b border-gray-100 space-y-1 sm:space-y-0">
                  <dt class="text-xs sm:text-sm font-medium text-blue-600 uppercase tracking-wide font-bold">Estado</dt>
                  <dd class="text-xs sm:text-sm font-semibold text-gray-900">{jovem.estados?.nome || 'Não informado'}</dd>
                </div>
                <div class="flex flex-col sm:flex-row sm:justify-between sm:items-center py-2 border-b border-gray-100 space-y-1 sm:space-y-0">
                  <dt class="text-xs sm:text-sm font-medium text-blue-600 uppercase tracking-wide font-bold">Bloco</dt>
                  <dd class="text-xs sm:text-sm font-semibold text-gray-900">{jovem.blocos?.nome || 'Não informado'}</dd>
                </div>
                <div class="flex flex-col sm:flex-row sm:justify-between sm:items-center py-2 border-b border-gray-100 space-y-1 sm:space-y-0">
                  <dt class="text-xs sm:text-sm font-medium text-blue-600 uppercase tracking-wide font-bold">Região</dt>
                  <dd class="text-xs sm:text-sm font-semibold text-gray-900">{jovem.regioes?.nome || 'Não informado'}</dd>
                </div>
                <div class="flex flex-col sm:flex-row sm:justify-between sm:items-center py-2 border-b border-gray-100 space-y-1 sm:space-y-0">
                  <dt class="text-xs sm:text-sm font-medium text-blue-600 uppercase tracking-wide font-bold">Igreja</dt>
                  <dd class="text-xs sm:text-sm font-semibold text-gray-900">{jovem.igrejas?.nome || 'Não informado'}</dd>
                </div>
                <div class="flex flex-col sm:flex-row sm:justify-between sm:items-center py-2 space-y-1 sm:space-y-0">
                  <dt class="text-xs sm:text-sm font-medium text-blue-600 uppercase tracking-wide font-bold">Edição</dt>
                  <dd class="text-xs sm:text-sm font-semibold text-gray-900">{jovem.edicao || 'Não informado'}</dd>
                </div>
              </dl>
            </div>
          </div>

          <!-- Observações e Redes Sociais -->
          <div class="bg-white rounded-lg shadow-sm border border-blue-200 overflow-hidden">
            <div class="bg-blue-600 px-4 sm:px-6 py-2 sm:py-3 relative">
              <div class="absolute left-0 top-0 bottom-0 w-1 sm:w-2 bg-blue-800 rounded-r"></div>
              <h3 class="text-base sm:text-lg font-semibold text-white ml-2 sm:ml-3">Observações e Redes Sociais</h3>
            </div>
            <div class="p-6">
              <dl class="space-y-4">
                <div class="py-2 border-b border-gray-100">
                  <dt class="text-xs sm:text-sm font-medium text-blue-600 uppercase tracking-wide font-bold text-center mb-2">Observação</dt>
                  <dd class="text-xs sm:text-sm font-semibold text-gray-900 text-left w-full break-words">{jovem.observacao || 'Não informado'}</dd>
                </div>
                <div class="py-2 border-b border-gray-100">
                  <dt class="text-xs sm:text-sm font-medium text-blue-600 uppercase tracking-wide font-bold text-center mb-2">Testemunho</dt>
                  <dd class="text-xs sm:text-sm font-semibold text-gray-900 text-left w-full break-words">{jovem.testemunho || 'Não informado'}</dd>
                </div>
                <div class="flex justify-between items-center py-2 border-b border-gray-100">
                  <dt class="text-sm font-medium text-blue-600 uppercase tracking-wide font-bold">Instagram</dt>
                  <dd class="text-xs sm:text-sm font-semibold text-gray-900 break-all">{jovem.instagram || 'Não informado'}</dd>
                </div>
                <div class="flex justify-between items-center py-2 border-b border-gray-100">
                  <dt class="text-sm font-medium text-blue-600 uppercase tracking-wide font-bold">Facebook</dt>
                  <dd class="text-xs sm:text-sm font-semibold text-gray-900 break-all">{jovem.facebook || 'Não informado'}</dd>
                </div>
                <div class="flex justify-between items-center py-2">
                  <dt class="text-sm font-medium text-blue-600 uppercase tracking-wide font-bold">TikTok</dt>
                  <dd class="text-xs sm:text-sm font-semibold text-gray-900 break-all">{jovem.tiktok || 'Não informado'}</dd>
                </div>
              </dl>
            </div>
          </div>
          
          <!-- Seção IntelliMen -->
          <div class="bg-white rounded-lg shadow-sm border border-blue-200 overflow-hidden">
            <div class="bg-blue-600 px-4 sm:px-6 py-2 sm:py-3 relative">
              <div class="absolute left-0 top-0 bottom-0 w-1 sm:w-2 bg-blue-800 rounded-r"></div>
              <h3 class="text-base sm:text-lg font-semibold text-white ml-2 sm:ml-3">Sobre o IntelliMen</h3>
            </div>
            <div class="p-4 sm:p-6">
              <dl class="space-y-3 sm:space-y-4">
                <div class="flex flex-col sm:flex-row sm:justify-between sm:items-center py-2 border-b border-gray-100 space-y-1 sm:space-y-0">
                  <dt class="text-xs sm:text-sm font-medium text-blue-600 uppercase tracking-wide font-bold">Formado no IntelliMen</dt>
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
          <div class="bg-white rounded-lg shadow-sm border border-blue-200 overflow-hidden">
            <div class="bg-blue-600 px-4 sm:px-6 py-2 sm:py-3 relative">
              <div class="absolute left-0 top-0 bottom-0 w-1 sm:w-2 bg-blue-800 rounded-r"></div>
              <h3 class="text-base sm:text-lg font-semibold text-white ml-2 sm:ml-3">Informações Espirituais</h3>
            </div>
            <div class="p-4 sm:p-6">
              <dl class="space-y-3 sm:space-y-4">
                <div class="flex flex-col sm:flex-row sm:justify-between sm:items-center py-2 border-b border-gray-100 space-y-1 sm:space-y-0">
                  <dt class="text-xs sm:text-sm font-medium text-blue-600 uppercase tracking-wide font-bold">Tempo de Igreja</dt>
                  <dd class="text-sm font-semibold text-gray-900 bg-blue-50 px-3 py-1 rounded">{jovem.tempo_igreja || 'Não informado'}</dd>
                </div>
                <div class="flex justify-between items-center py-2 border-b border-gray-100">
                  <dt class="text-sm font-medium text-blue-600 uppercase tracking-wide font-bold">Batizado nas Águas</dt>
                  <dd class="text-sm font-semibold text-gray-900 bg-blue-50 px-3 py-1 rounded">
                    {jovem.batizado_aguas ? 'Sim' : 'Não'}
                    {#if jovem.batizado_aguas && jovem.data_batismo_aguas}
                      <span class="text-gray-500 ml-2">({formatDate(jovem.data_batismo_aguas)})</span>
                    {/if}
                  </dd>
                </div>
                <div class="flex justify-between items-center py-2 border-b border-gray-100">
                  <dt class="text-sm font-medium text-blue-600 uppercase tracking-wide font-bold">Data do Batismo nas Águas</dt>
                  <dd class="text-xs sm:text-sm font-semibold text-gray-900">{jovem.data_batismo_aguas ? formatDate(jovem.data_batismo_aguas) : 'Não informado'}</dd>
                </div>
                <div class="flex justify-between items-center py-2 border-b border-gray-100">
                  <dt class="text-sm font-medium text-blue-600 uppercase tracking-wide font-bold">Batizado com ES</dt>
                  <dd class="text-sm font-semibold text-gray-900 bg-blue-50 px-3 py-1 rounded">
                    {jovem.batizado_es ? 'Sim' : 'Não'}
                    {#if jovem.batizado_es && jovem.data_batismo_es}
                      <span class="text-gray-500 ml-2">({formatDate(jovem.data_batismo_es)})</span>
                    {/if}
                  </dd>
                </div>
                <div class="flex justify-between items-center py-2 border-b border-gray-100">
                  <dt class="text-sm font-medium text-blue-600 uppercase tracking-wide font-bold">Data do Batismo com ES</dt>
                  <dd class="text-xs sm:text-sm font-semibold text-gray-900">{jovem.data_batismo_es ? formatDate(jovem.data_batismo_es) : 'Não informado'}</dd>
                </div>
                <div class="flex justify-between items-center py-2 border-b border-gray-100">
                  <dt class="text-sm font-medium text-blue-600 uppercase tracking-wide font-bold">Condição</dt>
                  <dd class="text-sm font-semibold text-gray-900 bg-blue-50 px-3 py-1 rounded">{jovem.condicao || 'Não informado'}</dd>
                </div>
                <div class="flex justify-between items-center py-2 border-b border-gray-100">
                  <dt class="text-sm font-medium text-blue-600 uppercase tracking-wide font-bold">Tempo de Condição</dt>
                  <dd class="text-xs sm:text-sm font-semibold text-gray-900">{jovem.tempo_condicao || 'Não informado'}</dd>
                </div>
                <div class="flex justify-between items-center py-2">
                  <dt class="text-sm font-medium text-blue-600 uppercase tracking-wide font-bold">Responsabilidade na Igreja</dt>
                  <dd class="text-xs sm:text-sm font-semibold text-gray-900">{jovem.responsabilidade_igreja || 'Não informado'}</dd>
                </div>
              </dl>
            </div>
          </div>

          <!-- Experiência na Igreja -->
          <div class="bg-white rounded-lg shadow-sm border border-blue-200 overflow-hidden">
            <div class="bg-blue-600 px-4 sm:px-6 py-2 sm:py-3 relative">
              <div class="absolute left-0 top-0 bottom-0 w-1 sm:w-2 bg-blue-800 rounded-r"></div>
              <h3 class="text-base sm:text-lg font-semibold text-white ml-2 sm:ml-3">Experiência na Igreja</h3>
            </div>
            <div class="p-4 sm:p-6">
              <dl class="space-y-3 sm:space-y-4">
                <div class="flex flex-col sm:flex-row sm:justify-between sm:items-center py-2 border-b border-gray-100 space-y-1 sm:space-y-0">
                  <dt class="text-xs sm:text-sm font-medium text-blue-600 uppercase tracking-wide font-bold">Já Fez a Obra no Altar</dt>
                  <dd class="text-xs sm:text-sm font-semibold text-gray-900">{jovem.ja_obra_altar ? 'Sim' : 'Não'}</dd>
                </div>
                <div class="flex justify-between items-center py-2 border-b border-gray-100">
                  <dt class="text-sm font-medium text-blue-600 uppercase tracking-wide font-bold">Já Foi Obreiro</dt>
                  <dd class="text-xs sm:text-sm font-semibold text-gray-900">{jovem.ja_obreiro ? 'Sim' : 'Não'}</dd>
                </div>
                <div class="flex justify-between items-center py-2 border-b border-gray-100">
                  <dt class="text-sm font-medium text-blue-600 uppercase tracking-wide font-bold">Já Foi Colaborador</dt>
                  <dd class="text-xs sm:text-sm font-semibold text-gray-900">{jovem.ja_colaborador ? 'Sim' : 'Não'}</dd>
                </div>
                <div class="flex justify-between items-center py-2 border-b border-gray-100">
                  <dt class="text-sm font-medium text-blue-600 uppercase tracking-wide font-bold">Já Se Afastou Alguma Vez</dt>
                  <dd class="text-xs sm:text-sm font-semibold text-gray-900">{jovem.afastado ? 'Sim' : 'Não'}</dd>
                </div>
                <div class="flex justify-between items-center py-2 border-b border-gray-100">
                  <dt class="text-sm font-medium text-blue-600 uppercase tracking-wide font-bold">Os Pais São da Igreja</dt>
                  <dd class="text-xs sm:text-sm font-semibold text-gray-900">{jovem.pais_na_igreja ? 'Sim' : 'Não'}</dd>
                </div>
                <div class="flex justify-between items-center py-2 border-b border-gray-100">
                  <dt class="text-sm font-medium text-blue-600 uppercase tracking-wide font-bold">Observação sobre os Pais</dt>
                  <dd class="text-xs sm:text-sm font-semibold text-gray-900">{jovem.observacao_pais || 'Não informado'}</dd>
                </div>
                <div class="flex justify-between items-center py-2 border-b border-gray-100">
                  <dt class="text-sm font-medium text-blue-600 uppercase tracking-wide font-bold">Tem Familiares na Igreja</dt>
                  <dd class="text-xs sm:text-sm font-semibold text-gray-900">{jovem.familiares_igreja ? 'Sim' : 'Não'}</dd>
                </div>
                <div class="flex justify-between items-center py-2">
                  <dt class="text-sm font-medium text-blue-600 uppercase tracking-wide font-bold">Deseja o Altar</dt>
                  <dd class="text-xs sm:text-sm font-semibold text-gray-900">{jovem.deseja_altar ? 'Sim' : 'Não'}</dd>
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
            <div class="bg-blue-600 px-4 sm:px-6 py-2 sm:py-3 relative">
              <div class="absolute left-0 top-0 bottom-0 w-1 sm:w-2 bg-blue-800 rounded-r"></div>
              <h3 class="text-base sm:text-lg font-semibold text-white ml-2 sm:ml-3">Informações Profissionais</h3>
            </div>
            <div class="p-4 sm:p-6">
              <dl class="space-y-3 sm:space-y-4">
                <div class="flex flex-col sm:flex-row sm:justify-between sm:items-center py-2 border-b border-gray-100 space-y-1 sm:space-y-0">
                  <dt class="text-xs sm:text-sm font-medium text-blue-600 uppercase tracking-wide font-bold">Trabalha</dt>
                  <dd class="text-sm font-semibold text-gray-900 bg-blue-50 px-3 py-1 rounded">{jovem.trabalha ? 'Sim' : 'Não'}</dd>
                </div>
                {#if jovem.trabalha}
                  <div class="flex justify-between items-center py-2 border-b border-gray-100">
                    <dt class="text-sm font-medium text-blue-600 uppercase tracking-wide font-bold">Nome da Empresa</dt>
                    <dd class="text-xs sm:text-sm font-semibold text-gray-900">{jovem.local_trabalho || 'Não informado'}</dd>
                  </div>
                {/if}
                <div class="flex justify-between items-center py-2 border-b border-gray-100">
                  <dt class="text-sm font-medium text-blue-600 uppercase tracking-wide font-bold">Trabalha Com</dt>
                  <dd class="text-xs sm:text-sm font-semibold text-gray-900">{jovem.formacao || 'Não informado'}</dd>
                </div>
                <div class="flex justify-between items-center py-2 border-b border-gray-100">
                  <dt class="text-sm font-medium text-blue-600 uppercase tracking-wide font-bold">Profissão</dt>
                  <dd class="text-xs sm:text-sm font-semibold text-gray-900">{jovem.formacao || 'Não informado'}</dd>
                </div>
                <div class="flex justify-between items-center py-2 border-b border-gray-100">
                  <dt class="text-sm font-medium text-blue-600 uppercase tracking-wide font-bold">Escolaridade</dt>
                  <dd class="text-xs sm:text-sm font-semibold text-gray-900">{jovem.escolaridade || 'Não informado'}</dd>
                </div>
                <div class="flex justify-between items-center py-2 border-b border-gray-100">
                  <dt class="text-sm font-medium text-blue-600 uppercase tracking-wide font-bold">Tem Dívidas</dt>
                  <dd class="text-xs sm:text-sm font-semibold text-gray-900">{jovem.tem_dividas ? 'Sim' : 'Não'}</dd>
                </div>
                {#if jovem.tem_dividas && jovem.valor_divida}
                  <div class="flex justify-between items-center py-2">
                    <dt class="text-sm font-medium text-blue-600 uppercase tracking-wide font-bold">Valor da Dívida</dt>
                    <dd class="text-xs sm:text-sm font-semibold text-gray-900">R$ {jovem.valor_divida.toLocaleString('pt-BR', { minimumFractionDigits: 2 })}</dd>
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
        
      {:else if activeTab === 'associacoes'}
        <!-- Associações -->
        <div class="space-y-6">
          <AssociacoesJovem {jovemId} onDesassociacao={loadJovemData} />
        </div>
        
      {:else if activeTab === 'nucleo'}
        <!-- Núcleo de Oração -->
        <div class="space-y-6">
          <DadosNucleoView {jovemId} />
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

<!-- Modal de Associação -->
<AssociarUsuarioModal
  bind:isOpen={showAssociarModal}
  jovemId={jovemId}
  on:close={closeAssociarModal}
  on:success={async (e) => {
    if (jovem) {
      jovem.usuario_id = e.detail?.usuarioId;
    }
    await loadJovemData();
  }}
/>
