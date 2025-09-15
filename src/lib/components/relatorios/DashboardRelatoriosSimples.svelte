<script>
  import { onMount } from 'svelte';
  import { gerarEstatisticasGerais } from '$lib/stores/relatorios';
  import Card from '$lib/components/ui/Card.svelte';
  import Button from '$lib/components/ui/Button.svelte';
  
  let estatisticas = null;
  let loading = true;
  let error = '';
  
  onMount(async () => {
    await loadData();
  });
  
  async function loadData() {
    loading = true;
    error = '';
    
    try {
      estatisticas = await gerarEstatisticasGerais();
    } catch (err) {
      error = err.message;
      console.error('Erro ao carregar estatísticas:', err);
    } finally {
      loading = false;
    }
  }
  
  // Função para obter cor do status
  function getStatusColor(status) {
    switch (status) {
      case 'aprovados':
        return 'text-green-600 bg-green-100';
      case 'preAprovados':
        return 'text-yellow-600 bg-yellow-100';
      case 'pendentes':
        return 'text-gray-600 bg-gray-100';
      default:
        return 'text-blue-600 bg-blue-100';
    }
  }
  
  // Função para obter cor da nota
  function getNotaColor(nota) {
    if (nota >= 8) return 'text-green-600';
    if (nota >= 6) return 'text-yellow-600';
    if (nota >= 4) return 'text-orange-600';
    return 'text-red-600';
  }
  
  // Função para obter cor da barra de progresso
  function getProgressColor(nota) {
    if (nota >= 8) return 'bg-green-500';
    if (nota >= 6) return 'bg-yellow-500';
    if (nota >= 4) return 'bg-orange-500';
    return 'bg-red-500';
  }
  
  // Função para obter largura da barra de progresso
  function getProgressWidth(nota) {
    return Math.min((nota / 10) * 100, 100);
  }
</script>

<div class="space-y-6">
  <!-- Header -->
  <div class="flex items-center justify-between">
    <div>
      <h1 class="text-2xl font-bold text-gray-900">Dashboard de Relatórios</h1>
      <p class="text-gray-600">Visão geral das estatísticas do sistema</p>
    </div>
    <Button variant="outline" on:click={loadData}>
      <svg class="w-4 h-4 mr-2" fill="none" viewBox="0 0 24 24" stroke="currentColor">
        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 4v5h.582m15.356 2A8.001 8.001 0 004.582 9m0 0H9m11 11v-5h-.581m0 0a8.003 8.003 0 01-15.357-2m15.357 2H15" />
      </svg>
      Atualizar
    </Button>
  </div>
  
  {#if loading}
    <div class="flex items-center justify-center py-12">
      <div class="animate-spin rounded-full h-12 w-12 border-b-2 border-blue-600"></div>
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
  {:else if estatisticas}
    <!-- Estatísticas Principais -->
    <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
      <!-- Card Total de Jovens -->
      <Card class="p-6 bg-gradient-to-br from-blue-50 to-blue-100 border-blue-200 hover:shadow-lg transition-all duration-300">
        <div class="flex items-center justify-between">
          <div class="flex-1">
            <div class="flex items-center space-x-3 mb-4">
              <div class="w-12 h-12 bg-gradient-to-br from-blue-500 to-blue-600 rounded-xl flex items-center justify-center shadow-lg">
                <svg class="w-6 h-6 text-white" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4.354a4 4 0 110 5.292M15 21H3v-1a6 6 0 0112 0v1zm0 0h6v-1a6 6 0 00-9-5.197m13.5-9a2.5 2.5 0 11-5 0 2.5 2.5 0 015 0z" />
                </svg>
              </div>
              <div>
                <p class="text-sm font-semibold text-blue-700 uppercase tracking-wide">Total de Jovens</p>
                <p class="text-xs text-blue-600">Cadastrados no sistema</p>
              </div>
            </div>
            <div class="text-center">
              <p class="text-4xl font-bold text-blue-900">{estatisticas.totalJovens}</p>
              <p class="text-sm text-blue-600 font-medium">jovens cadastrados</p>
            </div>
          </div>
        </div>
      </Card>
      
      <!-- Card Aprovados -->
      <Card class="p-6 bg-gradient-to-br from-green-50 to-green-100 border-green-200 hover:shadow-lg transition-all duration-300">
        <div class="flex items-center justify-between">
          <div class="flex-1">
            <div class="flex items-center space-x-3 mb-4">
              <div class="w-12 h-12 bg-gradient-to-br from-green-500 to-green-600 rounded-xl flex items-center justify-center shadow-lg">
                <svg class="w-6 h-6 text-white" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z" />
                </svg>
              </div>
              <div>
                <p class="text-sm font-semibold text-green-700 uppercase tracking-wide">Aprovados</p>
                <p class="text-xs text-green-600">Jovens aprovados</p>
              </div>
            </div>
            <div class="text-center mb-3">
              <p class="text-4xl font-bold text-green-900">{estatisticas.aprovados}</p>
              <p class="text-sm text-green-600 font-medium">jovens aprovados</p>
            </div>
            <div class="flex items-center space-x-2">
              <div class="flex-1 bg-green-200 rounded-full h-2">
                <div 
                  class="bg-gradient-to-r from-green-500 to-green-600 h-2 rounded-full transition-all duration-500"
                  style="width: {estatisticas.totalJovens > 0 ? (estatisticas.aprovados / estatisticas.totalJovens) * 100 : 0}%"
                ></div>
              </div>
              <span class="text-xs font-semibold text-green-700">
                {estatisticas.totalJovens > 0 ? ((estatisticas.aprovados / estatisticas.totalJovens) * 100).toFixed(1) : '0'}%
              </span>
            </div>
          </div>
        </div>
      </Card>
      
      <!-- Card Pré-aprovados -->
      <Card class="p-6 bg-gradient-to-br from-yellow-50 to-yellow-100 border-yellow-200 hover:shadow-lg transition-all duration-300">
        <div class="flex items-center justify-between">
          <div class="flex-1">
            <div class="flex items-center space-x-3 mb-4">
              <div class="w-12 h-12 bg-gradient-to-br from-yellow-500 to-yellow-600 rounded-xl flex items-center justify-center shadow-lg">
                <svg class="w-6 h-6 text-white" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z" />
                </svg>
              </div>
              <div>
                <p class="text-sm font-semibold text-yellow-700 uppercase tracking-wide">Pré-aprovados</p>
                <p class="text-xs text-yellow-600">Aguardando aprovação</p>
              </div>
            </div>
            <div class="text-center mb-3">
              <p class="text-4xl font-bold text-yellow-900">{estatisticas.preAprovados}</p>
              <p class="text-sm text-yellow-600 font-medium">jovens pré-aprovados</p>
            </div>
            <div class="flex items-center space-x-2">
              <div class="flex-1 bg-yellow-200 rounded-full h-2">
                <div 
                  class="bg-gradient-to-r from-yellow-500 to-yellow-600 h-2 rounded-full transition-all duration-500"
                  style="width: {estatisticas.totalJovens > 0 ? (estatisticas.preAprovados / estatisticas.totalJovens) * 100 : 0}%"
                ></div>
              </div>
              <span class="text-xs font-semibold text-yellow-700">
                {estatisticas.totalJovens > 0 ? ((estatisticas.preAprovados / estatisticas.totalJovens) * 100).toFixed(1) : '0'}%
              </span>
            </div>
          </div>
        </div>
      </Card>
      
      <!-- Card Pendentes -->
      <Card class="p-6 bg-gradient-to-br from-gray-50 to-gray-100 border-gray-200 hover:shadow-lg transition-all duration-300">
        <div class="flex items-center justify-between">
          <div class="flex-1">
            <div class="flex items-center space-x-3 mb-4">
              <div class="w-12 h-12 bg-gradient-to-br from-gray-500 to-gray-600 rounded-xl flex items-center justify-center shadow-lg">
                <svg class="w-6 h-6 text-white" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5H7a2 2 0 00-2 2v10a2 2 0 002 2h8a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2m-3 7h3m-3 4h3m-6-4h.01M9 16h.01" />
                </svg>
              </div>
              <div>
                <p class="text-sm font-semibold text-gray-700 uppercase tracking-wide">Pendentes</p>
                <p class="text-xs text-gray-600">Aguardando avaliação</p>
              </div>
            </div>
            <div class="text-center mb-3">
              <p class="text-4xl font-bold text-gray-900">{estatisticas.pendentes}</p>
              <p class="text-sm text-gray-600 font-medium">jovens pendentes</p>
            </div>
            <div class="flex items-center space-x-2">
              <div class="flex-1 bg-gray-200 rounded-full h-2">
                <div 
                  class="bg-gradient-to-r from-gray-500 to-gray-600 h-2 rounded-full transition-all duration-500"
                  style="width: {estatisticas.totalJovens > 0 ? (estatisticas.pendentes / estatisticas.totalJovens) * 100 : 0}%"
                ></div>
              </div>
              <span class="text-xs font-semibold text-gray-700">
                {estatisticas.totalJovens > 0 ? ((estatisticas.pendentes / estatisticas.totalJovens) * 100).toFixed(1) : '0'}%
              </span>
            </div>
          </div>
        </div>
      </Card>
    </div>
    
    <!-- Estatísticas de Avaliações -->
    <div class="grid grid-cols-1 lg:grid-cols-2 gap-6">
      <!-- Card Médias de Avaliações -->
      <Card class="p-6 bg-gradient-to-br from-purple-50 to-purple-100 border-purple-200 hover:shadow-lg transition-all duration-300">
        <div class="flex items-center space-x-3 mb-6">
          <div class="w-10 h-10 bg-gradient-to-br from-purple-500 to-purple-600 rounded-xl flex items-center justify-center shadow-lg">
            <svg class="w-5 h-5 text-white" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 19v-6a2 2 0 00-2-2H5a2 2 0 00-2 2v6a2 2 0 002 2h2a2 2 0 002-2zm0 0V9a2 2 0 012-2h2a2 2 0 012 2v10m-6 0a2 2 0 002 2h2a2 2 0 002-2m0 0V5a2 2 0 012-2h2a2 2 0 012 2v14a2 2 0 01-2 2h-2a2 2 0 01-2-2z" />
            </svg>
          </div>
          <div>
            <h3 class="text-lg font-bold text-purple-900">Médias de Avaliações</h3>
            <p class="text-sm text-purple-600">Performance geral dos jovens</p>
          </div>
        </div>
        
        <div class="space-y-6">
          <!-- Média Geral -->
          <div class="bg-white/60 rounded-xl p-4 border border-purple-200">
            <div class="flex items-center justify-between mb-3">
              <div class="flex items-center space-x-2">
                <div class="w-8 h-8 bg-gradient-to-br from-indigo-500 to-indigo-600 rounded-lg flex items-center justify-center">
                  <svg class="w-4 h-4 text-white" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 7h8m0 0v8m0-8l-8 8-4-4-6 6" />
                  </svg>
                </div>
                <span class="font-semibold text-gray-800">Média Geral</span>
              </div>
              <span class="text-2xl font-bold {getNotaColor(estatisticas.mediaGeral)}">
                {estatisticas.mediaGeral.toFixed(1)}
              </span>
            </div>
            <div class="w-full bg-gray-200 rounded-full h-3">
              <div 
                class="h-3 rounded-full bg-gradient-to-r from-indigo-500 to-indigo-600 transition-all duration-700"
                style="width: {getProgressWidth(estatisticas.mediaGeral)}%"
              ></div>
            </div>
          </div>
          
          <!-- Média Espírito -->
          <div class="bg-white/60 rounded-xl p-4 border border-green-200">
            <div class="flex items-center justify-between mb-3">
              <div class="flex items-center space-x-2">
                <div class="w-8 h-8 bg-gradient-to-br from-green-500 to-green-600 rounded-lg flex items-center justify-center">
                  <svg class="w-4 h-4 text-white" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4.318 6.318a4.5 4.5 0 000 6.364L12 20.364l7.682-7.682a4.5 4.5 0 00-6.364-6.364L12 7.636l-1.318-1.318a4.5 4.5 0 00-6.364 0z" />
                  </svg>
                </div>
                <span class="font-semibold text-gray-800">Média Espírito</span>
              </div>
              <span class="text-2xl font-bold {getNotaColor(estatisticas.mediaEspirito)}">
                {estatisticas.mediaEspirito.toFixed(1)}
              </span>
            </div>
            <div class="w-full bg-gray-200 rounded-full h-3">
              <div 
                class="h-3 rounded-full bg-gradient-to-r from-green-500 to-green-600 transition-all duration-700"
                style="width: {getProgressWidth(estatisticas.mediaEspirito)}%"
              ></div>
            </div>
          </div>
          
          <!-- Média Caráter -->
          <div class="bg-white/60 rounded-xl p-4 border border-purple-200">
            <div class="flex items-center justify-between mb-3">
              <div class="flex items-center space-x-2">
                <div class="w-8 h-8 bg-gradient-to-br from-purple-500 to-purple-600 rounded-lg flex items-center justify-center">
                  <svg class="w-4 h-4 text-white" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M16 7a4 4 0 11-8 0 4 4 0 018 0zM12 14a7 7 0 00-7 7h14a7 7 0 00-7-7z" />
                  </svg>
                </div>
                <span class="font-semibold text-gray-800">Média Caráter</span>
              </div>
              <span class="text-2xl font-bold {getNotaColor(estatisticas.mediaCaractere)}">
                {estatisticas.mediaCaractere.toFixed(1)}
              </span>
            </div>
            <div class="w-full bg-gray-200 rounded-full h-3">
              <div 
                class="h-3 rounded-full bg-gradient-to-r from-purple-500 to-purple-600 transition-all duration-700"
                style="width: {getProgressWidth(estatisticas.mediaCaractere)}%"
              ></div>
            </div>
          </div>
          
          <!-- Média Disposição -->
          <div class="bg-white/60 rounded-xl p-4 border border-blue-200">
            <div class="flex items-center justify-between mb-3">
              <div class="flex items-center space-x-2">
                <div class="w-8 h-8 bg-gradient-to-br from-blue-500 to-blue-600 rounded-lg flex items-center justify-center">
                  <svg class="w-4 h-4 text-white" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 10V3L4 14h7v7l9-11h-7z" />
                  </svg>
                </div>
                <span class="font-semibold text-gray-800">Média Disposição</span>
              </div>
              <span class="text-2xl font-bold {getNotaColor(estatisticas.mediaDisposicao)}">
                {estatisticas.mediaDisposicao.toFixed(1)}
              </span>
            </div>
            <div class="w-full bg-gray-200 rounded-full h-3">
              <div 
                class="h-3 rounded-full bg-gradient-to-r from-blue-500 to-blue-600 transition-all duration-700"
                style="width: {getProgressWidth(estatisticas.mediaDisposicao)}%"
              ></div>
            </div>
          </div>
        </div>
      </Card>
      
      <!-- Card Resumo de Avaliações -->
      <Card class="p-6 bg-gradient-to-br from-orange-50 to-orange-100 border-orange-200 hover:shadow-lg transition-all duration-300">
        <div class="flex items-center space-x-3 mb-6">
          <div class="w-10 h-10 bg-gradient-to-br from-orange-500 to-orange-600 rounded-xl flex items-center justify-center shadow-lg">
            <svg class="w-5 h-5 text-white" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5H7a2 2 0 00-2 2v10a2 2 0 002 2h8a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2m-3 7h3m-3 4h3m-6-4h.01M9 16h.01" />
            </svg>
          </div>
          <div>
            <h3 class="text-lg font-bold text-orange-900">Resumo de Avaliações</h3>
            <p class="text-sm text-orange-600">Estatísticas gerais do sistema</p>
          </div>
        </div>
        
        <div class="space-y-6">
          <!-- Total de Avaliações -->
          <div class="bg-white/60 rounded-xl p-4 border border-orange-200">
            <div class="flex items-center justify-between">
              <div class="flex items-center space-x-3">
                <div class="w-12 h-12 bg-gradient-to-br from-orange-500 to-orange-600 rounded-xl flex items-center justify-center">
                  <svg class="w-6 h-6 text-white" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z" />
                  </svg>
                </div>
                <div>
                  <p class="font-semibold text-gray-800">Total de Avaliações</p>
                  <p class="text-sm text-gray-600">Realizadas no sistema</p>
                </div>
              </div>
              <div class="text-right">
                <p class="text-3xl font-bold text-orange-900">{estatisticas.totalAvaliacoes}</p>
                <p class="text-sm text-orange-600">avaliações</p>
              </div>
            </div>
          </div>
          
          <!-- Avaliações por Jovem -->
          <div class="bg-white/60 rounded-xl p-4 border border-orange-200">
            <div class="flex items-center justify-between">
              <div class="flex items-center space-x-3">
                <div class="w-12 h-12 bg-gradient-to-br from-blue-500 to-blue-600 rounded-xl flex items-center justify-center">
                  <svg class="w-6 h-6 text-white" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4.354a4 4 0 110 5.292M15 21H3v-1a6 6 0 0112 0v1zm0 0h6v-1a6 6 0 00-9-5.197m13.5-9a2.5 2.5 0 11-5 0 2.5 2.5 0 015 0z" />
                  </svg>
                </div>
                <div>
                  <p class="font-semibold text-gray-800">Avaliações por Jovem</p>
                  <p class="text-sm text-gray-600">Média de avaliações</p>
                </div>
              </div>
              <div class="text-right">
                <p class="text-3xl font-bold text-blue-900">
                  {estatisticas.totalJovens > 0 ? (estatisticas.totalAvaliacoes / estatisticas.totalJovens).toFixed(1) : '0'}
                </p>
                <p class="text-sm text-blue-600">por jovem</p>
              </div>
            </div>
          </div>
          
          <!-- Taxa de Aprovação -->
          <div class="bg-white/60 rounded-xl p-4 border border-orange-200">
            <div class="flex items-center justify-between">
              <div class="flex items-center space-x-3">
                <div class="w-12 h-12 bg-gradient-to-br from-green-500 to-green-600 rounded-xl flex items-center justify-center">
                  <svg class="w-6 h-6 text-white" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z" />
                  </svg>
                </div>
                <div>
                  <p class="font-semibold text-gray-800">Taxa de Aprovação</p>
                  <p class="text-sm text-gray-600">Percentual de aprovação</p>
                </div>
              </div>
              <div class="text-right">
                <p class="text-3xl font-bold text-green-900">
                  {estatisticas.totalJovens > 0 ? ((estatisticas.aprovados / estatisticas.totalJovens) * 100).toFixed(1) : '0'}%
                </p>
                <p class="text-sm text-green-600">de aprovação</p>
              </div>
            </div>
          </div>
        </div>
      </Card>
    </div>
    
    <!-- Links para Relatórios -->
    <Card class="p-6 bg-gradient-to-br from-slate-50 to-slate-100 border-slate-200">
      <div class="flex items-center space-x-3 mb-6">
        <div class="w-10 h-10 bg-gradient-to-br from-slate-500 to-slate-600 rounded-xl flex items-center justify-center shadow-lg">
          <svg class="w-5 h-5 text-white" fill="none" viewBox="0 0 24 24" stroke="currentColor">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 19v-6a2 2 0 00-2-2H5a2 2 0 00-2 2v6a2 2 0 002 2h2a2 2 0 002-2zm0 0V9a2 2 0 012-2h2a2 2 0 012 2v10m-6 0a2 2 0 002 2h2a2 2 0 002-2m0 0V5a2 2 0 012-2h2a2 2 0 012 2v14a2 2 0 01-2 2h-2a2 2 0 01-2-2z" />
          </svg>
        </div>
        <div>
          <h3 class="text-lg font-bold text-slate-900">Acessar Relatórios</h3>
          <p class="text-sm text-slate-600">Explore análises detalhadas do sistema</p>
        </div>
      </div>
      
      <div class="grid grid-cols-1 md:grid-cols-3 gap-6">
        <!-- Relatório de Jovens -->
        <a href="/relatorios/jovens" class="group block p-6 bg-white rounded-xl border border-blue-200 hover:border-blue-300 hover:shadow-lg transition-all duration-300 transform hover:-translate-y-1 h-full">
          <div class="flex flex-col h-full text-center">
            <!-- Ícone no topo -->
            <div class="flex justify-center mb-4">
              <div class="w-16 h-16 bg-gradient-to-br from-blue-500 to-blue-600 rounded-xl flex items-center justify-center shadow-lg group-hover:scale-110 transition-transform duration-300">
                <svg class="w-8 h-8 text-white" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4.354a4 4 0 110 5.292M15 21H3v-1a6 6 0 0112 0v1zm0 0h6v-1a6 6 0 00-9-5.197m13.5-9a2.5 2.5 0 11-5 0 2.5 2.5 0 015 0z" />
                </svg>
              </div>
            </div>
            
            <!-- Conteúdo centralizado -->
            <div class="flex-1 flex flex-col justify-center">
              <h4 class="font-bold text-gray-900 group-hover:text-blue-600 transition-colors text-lg mb-3">Relatório de Jovens</h4>
              <p class="text-sm text-gray-600 leading-relaxed mb-4">Análise detalhada dos jovens cadastrados no sistema</p>
            </div>
            
            <!-- Badge na parte inferior -->
            <div class="mt-auto">
              <div class="flex items-center justify-center">
                <span class="text-xs font-semibold text-blue-600 bg-blue-100 px-3 py-2 rounded-full inline-flex items-center">
                  Análise Completa
                  <svg class="w-3 h-3 ml-1" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5l7 7-7 7" />
                  </svg>
                </span>
              </div>
            </div>
          </div>
        </a>
        
        <!-- Relatório de Avaliações -->
        <a href="/relatorios/avaliacoes" class="group block p-6 bg-white rounded-xl border border-purple-200 hover:border-purple-300 hover:shadow-lg transition-all duration-300 transform hover:-translate-y-1 h-full">
          <div class="flex flex-col h-full text-center">
            <!-- Ícone no topo -->
            <div class="flex justify-center mb-4">
              <div class="w-16 h-16 bg-gradient-to-br from-purple-500 to-purple-600 rounded-xl flex items-center justify-center shadow-lg group-hover:scale-110 transition-transform duration-300">
                <svg class="w-8 h-8 text-white" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5H7a2 2 0 00-2 2v10a2 2 0 002 2h8a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2m-3 7h3m-3 4h3m-6-4h.01M9 16h.01" />
                </svg>
              </div>
            </div>
            
            <!-- Conteúdo centralizado -->
            <div class="flex-1 flex flex-col justify-center">
              <h4 class="font-bold text-gray-900 group-hover:text-purple-600 transition-colors text-lg mb-3">Relatório de Avaliações</h4>
              <p class="text-sm text-gray-600 leading-relaxed mb-4">Análise das avaliações realizadas pelos jovens</p>
            </div>
            
            <!-- Badge na parte inferior -->
            <div class="mt-auto">
              <div class="flex items-center justify-center">
                <span class="text-xs font-semibold text-purple-600 bg-purple-100 px-3 py-2 rounded-full inline-flex items-center">
                  Performance
                  <svg class="w-3 h-3 ml-1" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5l7 7-7 7" />
                  </svg>
                </span>
              </div>
            </div>
          </div>
        </a>
        
        <!-- Relatórios Personalizados -->
        <a href="/relatorios/personalizados" class="group block p-6 bg-white rounded-xl border border-orange-200 hover:border-orange-300 hover:shadow-lg transition-all duration-300 transform hover:-translate-y-1 h-full">
          <div class="flex flex-col h-full text-center">
            <!-- Ícone no topo -->
            <div class="flex justify-center mb-4">
              <div class="w-16 h-16 bg-gradient-to-br from-orange-500 to-orange-600 rounded-xl flex items-center justify-center shadow-lg group-hover:scale-110 transition-transform duration-300">
                <svg class="w-8 h-8 text-white" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 6V4m0 2a2 2 0 100 4m0-4a2 2 0 110 4m-6 8a2 2 0 100-4m0 4a2 2 0 100 4m0-4v2m0-6V4m6 6v10m6-2a2 2 0 100-4m0 4a2 2 0 100 4m0-4v2m0-6V4" />
                </svg>
              </div>
            </div>
            
            <!-- Conteúdo centralizado -->
            <div class="flex-1 flex flex-col justify-center">
              <h4 class="font-bold text-gray-900 group-hover:text-orange-600 transition-colors text-lg mb-3">Relatórios Personalizados</h4>
              <p class="text-sm text-gray-600 leading-relaxed mb-4">Crie seus próprios relatórios personalizados</p>
            </div>
            
            <!-- Badge na parte inferior -->
            <div class="mt-auto">
              <div class="flex items-center justify-center">
                <span class="text-xs font-semibold text-orange-600 bg-orange-100 px-3 py-2 rounded-full inline-flex items-center">
                  Customizável
                  <svg class="w-3 h-3 ml-1" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5l7 7-7 7" />
                  </svg>
                </span>
              </div>
            </div>
          </div>
        </a>
      </div>
    </Card>
  {/if}
</div>
