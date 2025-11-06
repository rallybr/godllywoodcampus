<script>
  import { onMount } from 'svelte';
  import { browser } from '$app/environment';
  import { loadAvaliacoesByJovem, calculateAvaliacaoStats, updateAvaliacao } from '$lib/stores/avaliacoes';
  import { user, userProfile } from '$lib/stores/auth';
  import Button from '$lib/components/ui/Button.svelte';
  import Card from '$lib/components/ui/Card.svelte';
  import AvaliacaoModal from '$lib/components/modals/AvaliacaoModal.svelte';
  
  let DOMPurify = null;
  let isDOMPurifyReady = false;
  
  // Carregar DOMPurify assim que o componente for montado
  onMount(async () => {
    if (browser) {
      try {
        const module = await import('dompurify');
        DOMPurify = module.default;
        isDOMPurifyReady = true;
      } catch (err) {
        console.error('Erro ao carregar DOMPurify:', err);
        isDOMPurifyReady = true; // Permite renderizar mesmo sem DOMPurify
      }
    } else {
      isDOMPurifyReady = true; // SSR não precisa de DOMPurify
    }
  });
  
  function sanitizeHtml(html) {
    if (!html || html.trim() === '') return '';
    
    // Se não estiver no browser, retorna o HTML sem sanitização
    // (o SSR não precisa sanitizar, pois não executa código)
    if (!browser) {
      return html;
    }
    
    // Se DOMPurify estiver disponível, usa para sanitizar
    if (DOMPurify) {
      try {
        const sanitized = DOMPurify.sanitize(html, {
          ALLOWED_TAGS: ['p', 'br', 'strong', 'b', 'em', 'i', 'u', 'ul', 'ol', 'li', 'span', 'div', 'h1', 'h2', 'h3', 'h4', 'h5', 'h6', 'font'],
          ALLOWED_ATTR: ['style', 'class', 'align', 'color', 'size'],
          ALLOWED_STYLES: {
            '*': {
              // Cores em vários formatos: hex, rgb, rgba, nomes de cores
              'color': /^(#[0-9a-fA-F]{3,6}|rgb\([^)]+\)|rgba\([^)]+\)|[a-zA-Z]+)$/,
              'background-color': /^(#[0-9a-fA-F]{3,6}|rgb\([^)]+\)|rgba\([^)]+\)|[a-zA-Z]+)$/,
              'text-align': /^(left|right|center|justify)$/,
              // Tamanho de fonte em vários formatos: px, em, rem, pt, %, ou valores absolutos
              'font-size': /^[\d.]+(px|em|rem|pt|%)?$/,
              'font-weight': /^(normal|bold|bolder|lighter|100|200|300|400|500|600|700|800|900)$/,
              'font-style': /^(normal|italic|oblique)$/,
              'text-decoration': /^(none|underline|line-through|overline)$/,
              'font-family': /^[a-zA-Z0-9\s,"-]+$/
            }
          }
        });
        return sanitized || html; // Fallback para HTML original se sanitização retornar vazio
      } catch (err) {
        console.error('Erro ao sanitizar HTML:', err);
        return html; // Retorna HTML original em caso de erro
      }
    }
    
    // Fallback básico: remove apenas scripts e eventos inline perigosos
    // Isso permite que o HTML seja exibido mesmo se DOMPurify não estiver carregado ainda
    return html
      .replace(/<script\b[^<]*(?:(?!<\/script>)<[^<]*)*<\/script>/gi, '')
      .replace(/on\w+="[^"]*"/gi, '')
      .replace(/on\w+='[^']*'/gi, '')
      .replace(/javascript:/gi, '');
  }
  
  export let jovemId;
  export let jovem = null;
  
  let avaliacoes = [];
  let loading = true;
  let error = '';
  let stats = null;
  let showEditModal = false;
  let avaliacaoParaEditar = null;
  
  onMount(async () => {
    await loadAvaliacoes();
  });
  
  // Expor função para recarregar avaliações
  export async function reloadAvaliacoes() {
    await loadAvaliacoes();
  }
  
  // Função para verificar se o usuário pode editar a avaliação
  function canEditAvaliacao(avaliacao) {
    // Verificar se o usuário logado é o criador da avaliação
    return ($user && avaliacao.user_id === $user.id) || 
           ($userProfile && avaliacao.user_id === $userProfile.id);
  }
  
  // Função para abrir modal de edição
  function openEditModal(avaliacao) {
    avaliacaoParaEditar = avaliacao;
    showEditModal = true;
  }
  
  // Função para fechar modal de edição
  function closeEditModal() {
    showEditModal = false;
    avaliacaoParaEditar = null;
  }
  
  // Função para lidar com sucesso da edição
  async function handleEditSuccess() {
    await loadAvaliacoes(); // Recarregar lista
    closeEditModal();
  }
  
  async function loadAvaliacoes() {
    loading = true;
    error = '';
    
    try {
      const data = await loadAvaliacoesByJovem(jovemId);
      avaliacoes = data || [];
      stats = calculateAvaliacaoStats(avaliacoes);
    } catch (err) {
      error = err.message;
    } finally {
      loading = false;
    }
  }
  
  
  function getEnumLabel(value, type) {
    const labels = {
      espirito: {
        'ruim': 'Ruim',
        'ser_observar': 'Ser Observado',
        'bom': 'Bom',
        'excelente': 'Excelente'
      },
      caractere: {
        'excelente': 'Excelente',
        'bom': 'Bom',
        'ser_observar': 'Ser Observado',
        'ruim': 'Ruim'
      },
      disposicao: {
        'muito_disposto': 'Muito Disposto',
        'normal': 'Normal',
        'pacato': 'Pacato',
        'desanimado': 'Desanimado'
      }
    };
    
    return labels[type]?.[value] || value;
  }
  
  function getEnumColor(value, type) {
    const colors = {
      espirito: {
        'ruim': 'text-red-600 bg-red-100',
        'ser_observar': 'text-yellow-600 bg-yellow-100',
        'bom': 'text-green-600 bg-green-100',
        'excelente': 'text-blue-600 bg-blue-100'
      },
      caractere: {
        'excelente': 'text-blue-600 bg-blue-100',
        'bom': 'text-green-600 bg-green-100',
        'ser_observar': 'text-yellow-600 bg-yellow-100',
        'ruim': 'text-red-600 bg-red-100'
      },
      disposicao: {
        'muito_disposto': 'text-green-600 bg-green-100',
        'normal': 'text-blue-600 bg-blue-100',
        'pacato': 'text-yellow-600 bg-yellow-100',
        'desanimado': 'text-red-600 bg-red-100'
      }
    };
    
    return colors[type]?.[value] || 'text-gray-600 bg-gray-100';
  }
  
  function getNotaColor(nota) {
    if (nota >= 8) return 'text-green-600 bg-green-100';
    if (nota >= 6) return 'text-yellow-600 bg-yellow-100';
    if (nota >= 4) return 'text-orange-600 bg-orange-100';
    return 'text-red-600 bg-red-100';
  }
  
  function formatDate(dateString) {
    if (!dateString) return 'Não informado';
    try {
      return new Date(dateString).toLocaleDateString('pt-BR', {
        day: '2-digit',
        month: '2-digit',
        year: 'numeric',
        hour: '2-digit',
        minute: '2-digit'
      });
    } catch {
      return dateString;
    }
  }
</script>

<div class="space-y-6">
  <!-- Header com Estatísticas -->
  {#if stats && stats.total > 0}
    <Card class="p-6">
      <div class="flex items-center justify-between mb-4">
        <h3 class="text-lg font-semibold text-gray-900">Estatísticas das Avaliações</h3>
      </div>
      
      <!-- Total e Média Geral -->
      <div class="grid grid-cols-2 gap-4 mb-6">
        <div class="text-center bg-gray-50 rounded-lg p-4">
          <div class="text-2xl font-bold text-gray-900">{stats.total}</div>
          <div class="text-sm text-gray-500">Total de Avaliações</div>
        </div>
        
        <div class="text-center bg-blue-50 rounded-lg p-4">
          <div class="text-2xl font-bold text-blue-600">{stats.mediaGeral}</div>
          <div class="text-sm text-gray-500">Média Geral</div>
        </div>
      </div>
      
      <!-- Distribuição por Categoria -->
      <div class="grid grid-cols-1 md:grid-cols-3 gap-6">
        <!-- Espírito -->
        <div class="bg-gradient-to-br from-green-50 to-green-100 rounded-xl p-4 border border-green-200">
          <h4 class="text-lg font-semibold text-green-800 mb-3 flex items-center">
            <svg class="w-5 h-5 mr-2" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9.663 17h4.673M12 3v1m6.364 1.636l-.707.707M21 12h-1M4 12H3m3.343-5.657l-.707-.707m2.828 9.9a5 5 0 117.072 0l-.548.547A3.374 3.374 0 0014 18.469V19a2 2 0 11-4 0v-.531c0-.895-.356-1.754-.988-2.386l-.548-.547z" />
            </svg>
            Espírito
          </h4>
          <div class="space-y-2">
            {#each Object.entries(stats.distribuicaoEspirito || {}) as [label, quantidade]}
              <div class="flex justify-between items-center text-sm">
                <span class="text-gray-700">{label}</span>
                <span class="font-semibold text-green-700">{quantidade}</span>
              </div>
            {/each}
          </div>
        </div>
        
        <!-- Caráter -->
        <div class="bg-gradient-to-br from-purple-50 to-purple-100 rounded-xl p-4 border border-purple-200">
          <h4 class="text-lg font-semibold text-purple-800 mb-3 flex items-center">
            <svg class="w-5 h-5 mr-2" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z" />
            </svg>
            Caráter
          </h4>
          <div class="space-y-2">
            {#each Object.entries(stats.distribuicaoCaractere || {}) as [label, quantidade]}
              <div class="flex justify-between items-center text-sm">
                <span class="text-gray-700">{label}</span>
                <span class="font-semibold text-purple-700">{quantidade}</span>
              </div>
            {/each}
          </div>
        </div>
        
        <!-- Disposição -->
        <div class="bg-gradient-to-br from-orange-50 to-orange-100 rounded-xl p-4 border border-orange-200">
          <h4 class="text-lg font-semibold text-orange-800 mb-3 flex items-center">
            <svg class="w-5 h-5 mr-2" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 10V3L4 14h7v7l9-11h-7z" />
            </svg>
            Disposição
          </h4>
          <div class="space-y-2">
            {#each Object.entries(stats.distribuicaoDisposicao || {}) as [label, quantidade]}
              <div class="flex justify-between items-center text-sm">
                <span class="text-gray-700">{label}</span>
                <span class="font-semibold text-orange-700">{quantidade}</span>
              </div>
            {/each}
          </div>
        </div>
      </div>
    </Card>
  {/if}
  
  <!-- Lista de Avaliações -->
  <div class="space-y-4">
    {#if loading}
      <div class="flex items-center justify-center py-8">
        <div class="animate-spin rounded-full h-8 w-8 border-b-2 border-blue-600"></div>
      </div>
    {:else if error}
      <div class="bg-red-50 border border-red-200 rounded-lg p-4">
        <div class="flex items-center space-x-2">
          <svg class="w-5 h-5 text-red-500" fill="none" viewBox="0 0 24 24" stroke="currentColor">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8v4m0 4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
          </svg>
          <p class="text-sm text-red-600 font-medium">{error}</p>
        </div>
      </div>
    {:else if avaliacoes.length === 0}
      <Card class="p-8">
        <div class="text-center">
          <div class="w-16 h-16 bg-gray-100 rounded-full flex items-center justify-center mx-auto mb-4">
            <svg class="w-8 h-8 text-gray-400" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5H7a2 2 0 00-2 2v10a2 2 0 002 2h8a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2m-3 7h3m-3 4h3m-6-4h.01M9 16h.01" />
            </svg>
          </div>
          <h3 class="text-lg font-semibold text-gray-900 mb-2">Nenhuma avaliação encontrada</h3>
          <p class="text-gray-600 mb-4">Este jovem ainda não possui avaliações registradas.</p>
          <Button variant="primary" on:click={() => showEditModal = true}>
            <svg class="w-4 h-4 mr-2" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 6v6m0 0v6m0-6h6m-6 0H6" />
            </svg>
            Primeira Avaliação
          </Button>
        </div>
      </Card>
    {:else}
      <!-- Botão para nova avaliação -->
      
      <!-- Lista de avaliações -->
      <div class="space-y-4">
        {#each avaliacoes as avaliacao}
          <Card class="p-6">
            <div class="flex items-start justify-between">
              <div class="flex-1">
                <!-- Header da avaliação -->
                <div class="bg-gradient-to-r from-gray-50 to-gray-100 rounded-xl p-5 mb-6 border border-gray-200">
                  <div class="flex items-center justify-between">
                    <div class="flex items-center space-x-4">
                      {#if avaliacao.avaliador?.foto}
                        <img 
                          class="w-12 h-12 rounded-full object-cover border-2 border-white shadow-md" 
                          src={avaliacao.avaliador.foto} 
                          alt={avaliacao.avaliador.nome}
                        />
                      {:else}
                        <div class="w-12 h-12 bg-gradient-to-br from-purple-500 to-purple-600 rounded-full flex items-center justify-center border-2 border-white shadow-md">
                          <span class="text-white font-semibold text-lg">
                            {avaliacao.avaliador?.nome?.charAt(0) || 'A'}
                          </span>
                        </div>
                      {/if}
                      
                      <div>
                        <h4 class="text-lg font-semibold text-gray-900">
                          Avaliado por: {avaliacao.avaliador?.nome || avaliacao.avaliador?.email || 'Usuário'}
                        </h4>
                        <p class="text-sm text-gray-600 flex items-center">
                          <svg class="w-4 h-4 mr-1" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M8 7V3m8 4V3m-9 8h10M5 21h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v12a2 2 0 002 2z" />
                          </svg>
                          {formatDate(avaliacao.criado_em)}
                        </p>
                      </div>
                    </div>
                    
                    <!-- Nota e Botão Editar -->
                    <div class="flex items-center space-x-3">
                      <!-- Nota -->
                      <div class="bg-white rounded-xl px-4 py-3 border border-gray-200 shadow-sm">
                        <div class="text-center">
                          <div class="text-2xl font-bold text-gray-900">
                            {avaliacao.nota}/10
                          </div>
                          <div class="text-xs text-gray-500 uppercase tracking-wide">
                            Nota Geral
                          </div>
                        </div>
                      </div>
                      
                      <!-- Botão Editar (apenas para quem criou a avaliação) -->
                      {#if canEditAvaliacao(avaliacao)}
                        <Button
                          variant="outline"
                          size="sm"
                          on:click={() => openEditModal(avaliacao)}
                          class="flex items-center space-x-2"
                        >
                          <svg class="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M11 5H6a2 2 0 00-2 2v11a2 2 0 002 2h11a2 2 0 002-2v-5m-1.414-9.414a2 2 0 112.828 2.828L11.828 15H9v-2.828l8.586-8.586z" />
                          </svg>
                          <span>Editar</span>
                        </Button>
                      {/if}
                    </div>
                  </div>
                </div>
                
                <!-- Avaliações por categoria -->
                <div class="grid grid-cols-1 md:grid-cols-3 gap-4 mb-6">
                  <!-- Espírito -->
                  <div class="bg-gradient-to-br from-blue-50 to-blue-100 rounded-xl p-4 border border-blue-200 shadow-sm hover:shadow-md transition-shadow">
                    <div class="flex items-center space-x-3 mb-3">
                      <div class="w-10 h-10 bg-blue-500 rounded-full flex items-center justify-center">
                        <svg class="w-5 h-5 text-white" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9.663 17h4.673M12 3v1m6.364 1.636l-.707.707M21 12h-1M4 12H3m3.343-5.657l-.707-.707m2.828 9.9a5 5 0 117.072 0l-.548.547A3.374 3.374 0 0014 18.469V19a2 2 0 11-4 0v-.531c0-.895-.356-1.754-.988-2.386l-.548-.547z" />
                        </svg>
                      </div>
                      <div>
                        <h4 class="text-sm font-semibold text-gray-800">Espírito</h4>
                        <p class="text-xs text-gray-600">Avaliação espiritual</p>
                      </div>
                    </div>
                    <div class="mt-2">
                      <span class="inline-flex items-center px-3 py-2 rounded-lg text-sm font-medium {getEnumColor(avaliacao.espirito, 'espirito')}">
                        {getEnumLabel(avaliacao.espirito, 'espirito')}
                      </span>
                    </div>
                  </div>
                  
                  <!-- Caráter -->
                  <div class="bg-gradient-to-br from-purple-50 to-purple-100 rounded-xl p-4 border border-purple-200 shadow-sm hover:shadow-md transition-shadow">
                    <div class="flex items-center space-x-3 mb-3">
                      <div class="w-10 h-10 bg-purple-500 rounded-full flex items-center justify-center">
                        <svg class="w-5 h-5 text-white" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z" />
                        </svg>
                      </div>
                      <div>
                        <h4 class="text-sm font-semibold text-gray-800">Caráter</h4>
                        <p class="text-xs text-gray-600">Avaliação de caráter</p>
                      </div>
                    </div>
                    <div class="mt-2">
                      <span class="inline-flex items-center px-3 py-2 rounded-lg text-sm font-medium {getEnumColor(avaliacao.caractere, 'caractere')}">
                        {getEnumLabel(avaliacao.caractere, 'caractere')}
                      </span>
                    </div>
                  </div>
                  
                  <!-- Disposição -->
                  <div class="bg-gradient-to-br from-green-50 to-green-100 rounded-xl p-4 border border-green-200 shadow-sm hover:shadow-md transition-shadow">
                    <div class="flex items-center space-x-3 mb-3">
                      <div class="w-10 h-10 bg-green-500 rounded-full flex items-center justify-center">
                        <svg class="w-5 h-5 text-white" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 10V3L4 14h7v7l9-11h-7z" />
                        </svg>
                      </div>
                      <div>
                        <h4 class="text-sm font-semibold text-gray-800">Disposição</h4>
                        <p class="text-xs text-gray-600">Avaliação de disposição</p>
                      </div>
                    </div>
                    <div class="mt-2">
                      <span class="inline-flex items-center px-3 py-2 rounded-lg text-sm font-medium {getEnumColor(avaliacao.disposicao, 'disposicao')}">
                        {getEnumLabel(avaliacao.disposicao, 'disposicao')}
                      </span>
                    </div>
                  </div>
                </div>
                
                <!-- Observações -->
                {#if avaliacao.avaliacao_texto && String(avaliacao.avaliacao_texto).trim() !== ''}
                  <div class="mt-6">
                    <div class="bg-gradient-to-r from-amber-50 to-orange-50 rounded-xl p-5 border border-amber-200 shadow-sm">
                      <div class="flex items-center space-x-3 mb-4">
                        <div class="w-8 h-8 bg-amber-500 rounded-full flex items-center justify-center">
                          <svg class="w-4 h-4 text-white" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M11 5H6a2 2 0 00-2 2v11a2 2 0 002 2h11a2 2 0 002-2v-5m-1.414-9.414a2 2 0 112.828 2.828L11.828 15H9v-2.828l8.586-8.586z" />
                          </svg>
                        </div>
                        <h4 class="text-lg font-semibold text-gray-800">Observações</h4>
                      </div>
                      <div class="bg-white rounded-lg p-4 border border-amber-100">
                        <div class="text-base text-gray-700 leading-relaxed prose prose-sm max-w-none rich-text-content">
                          {@html sanitizeHtml(avaliacao.avaliacao_texto)}
                        </div>
                      </div>
                    </div>
                  </div>
                {/if}
              </div>
            </div>
          </Card>
        {/each}
      </div>
    {/if}
  </div>
</div>

<!-- Modal de Edição de Avaliação -->
{#if showEditModal && avaliacaoParaEditar}
  <AvaliacaoModal
    bind:isOpen={showEditModal}
    jovemId={jovemId}
    jovemNome={jovem?.nome_completo || ''}
    avaliacaoParaEditar={avaliacaoParaEditar}
    on:close={closeEditModal}
    on:success={handleEditSuccess}
  />
{/if}

<style>
  :global(.rich-text-content) {
    line-height: 1.6;
  }
  
  :global(.rich-text-content p) {
    margin-bottom: 0.75rem;
  }
  
  :global(.rich-text-content p:last-child) {
    margin-bottom: 0;
  }
  
  :global(.rich-text-content ul),
  :global(.rich-text-content ol) {
    margin-left: 1.5rem;
    margin-bottom: 0.75rem;
    margin-top: 0.5rem;
  }
  
  :global(.rich-text-content li) {
    margin-bottom: 0.25rem;
  }
  
  :global(.rich-text-content strong),
  :global(.rich-text-content b) {
    font-weight: 600;
  }
  
  :global(.rich-text-content em),
  :global(.rich-text-content i) {
    font-style: italic;
  }
  
  :global(.rich-text-content u) {
    text-decoration: underline;
  }
  
  /* Converter tags font[size] para tamanhos reais */
  :global(.rich-text-content font[size="1"]) {
    font-size: 0.625rem; /* 10px */
  }
  :global(.rich-text-content font[size="2"]) {
    font-size: 0.75rem; /* 12px */
  }
  :global(.rich-text-content font[size="3"]) {
    font-size: 0.875rem; /* 14px */
  }
  :global(.rich-text-content font[size="4"]) {
    font-size: 1rem; /* 16px */
  }
  :global(.rich-text-content font[size="5"]) {
    font-size: 1.125rem; /* 18px */
  }
  :global(.rich-text-content font[size="6"]) {
    font-size: 1.25rem; /* 20px */
  }
  :global(.rich-text-content font[size="7"]) {
    font-size: 1.5rem; /* 24px */
  }
</style>

