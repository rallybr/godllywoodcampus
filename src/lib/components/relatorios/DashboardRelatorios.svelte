<script>
  import { onMount } from 'svelte';
  import { gerarEstatisticasGerais, gerarRelatorioPorLocalizacao, gerarRelatorioAvaliacoes } from '$lib/stores/relatorios';
  import Card from '$lib/components/ui/Card.svelte';
  import Button from '$lib/components/ui/Button.svelte';
  import GraficoAvaliacoes from '$lib/components/charts/GraficoAvaliacoes.svelte';
  import GraficoLocalizacao from '$lib/components/charts/GraficoLocalizacao.svelte';
  import GraficoEvolucao from '$lib/components/charts/GraficoEvolucao.svelte';
  
  let estatisticas = null;
  let relatorioLocalizacao = [];
  let avaliacoes = [];
  let loading = true;
  let error = '';
  let tipoGrafico = 'bar';
  let periodoGrafico = 'mes';
  
  onMount(async () => {
    await loadData();
  });
  
  async function loadData() {
    loading = true;
    error = '';
    
    try {
      // Carregar estatísticas gerais primeiro
      estatisticas = await gerarEstatisticasGerais();
      
      // Carregar dados de localização (mais simples)
      try {
        relatorioLocalizacao = await gerarRelatorioPorLocalizacao();
      } catch (err) {
        console.warn('Erro ao carregar relatório de localização:', err);
        relatorioLocalizacao = [];
      }
      
      // Carregar avaliações (mais simples)
      try {
        avaliacoes = await gerarRelatorioAvaliacoes();
      } catch (err) {
        console.warn('Erro ao carregar avaliações:', err);
        avaliacoes = [];
      }
      
    } catch (err) {
      error = err.message;
      console.error('Erro ao carregar dados do dashboard:', err);
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
    <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
      <Card class="p-6">
        <div class="flex items-center">
          <div class="w-12 h-12 bg-blue-100 rounded-full flex items-center justify-center mr-4">
            <svg class="w-6 h-6 text-blue-600" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4.354a4 4 0 110 5.292M15 21H3v-1a6 6 0 0112 0v1zm0 0h6v-1a6 6 0 00-9-5.197m13.5-9a2.5 2.5 0 11-5 0 2.5 2.5 0 015 0z" />
            </svg>
          </div>
          <div>
            <p class="text-sm font-medium text-gray-500">Total de Jovens</p>
            <p class="text-2xl font-bold text-gray-900">{estatisticas.totalJovens}</p>
          </div>
        </div>
      </Card>
      
      <Card class="p-6">
        <div class="flex items-center">
          <div class="w-12 h-12 bg-green-100 rounded-full flex items-center justify-center mr-4">
            <svg class="w-6 h-6 text-green-600" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z" />
            </svg>
          </div>
          <div>
            <p class="text-sm font-medium text-gray-500">Aprovados</p>
            <p class="text-2xl font-bold text-gray-900">{estatisticas.aprovados}</p>
          </div>
        </div>
      </Card>
      
      <Card class="p-6">
        <div class="flex items-center">
          <div class="w-12 h-12 bg-yellow-100 rounded-full flex items-center justify-center mr-4">
            <svg class="w-6 h-6 text-yellow-600" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z" />
            </svg>
          </div>
          <div>
            <p class="text-sm font-medium text-gray-500">Pré-aprovados</p>
            <p class="text-2xl font-bold text-gray-900">{estatisticas.preAprovados}</p>
          </div>
        </div>
      </Card>
      
      <Card class="p-6">
        <div class="flex items-center">
          <div class="w-12 h-12 bg-gray-100 rounded-full flex items-center justify-center mr-4">
            <svg class="w-6 h-6 text-gray-600" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5H7a2 2 0 00-2 2v10a2 2 0 002 2h8a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2m-3 7h3m-3 4h3m-6-4h.01M9 16h.01" />
            </svg>
          </div>
          <div>
            <p class="text-sm font-medium text-gray-500">Pendentes</p>
            <p class="text-2xl font-bold text-gray-900">{estatisticas.pendentes}</p>
          </div>
        </div>
      </Card>
    </div>
    
    <!-- Estatísticas de Avaliações -->
    <div class="grid grid-cols-1 lg:grid-cols-2 gap-6">
      <Card class="p-6">
        <h3 class="text-lg font-semibold text-gray-900 mb-4">Médias de Avaliações</h3>
        <div class="space-y-4">
          <div>
            <div class="flex items-center justify-between mb-2">
              <span class="text-sm font-medium text-gray-700">Média Geral</span>
              <span class="text-lg font-bold {getNotaColor(estatisticas.mediaGeral)}">
                {estatisticas.mediaGeral.toFixed(1)}
              </span>
            </div>
            <div class="w-full bg-gray-200 rounded-full h-2">
              <div 
                class="h-2 rounded-full {getProgressColor(estatisticas.mediaGeral)}"
                style="width: {getProgressWidth(estatisticas.mediaGeral)}%"
              ></div>
            </div>
          </div>
          
          <div>
            <div class="flex items-center justify-between mb-2">
              <span class="text-sm font-medium text-gray-700">Média Espírito</span>
              <span class="text-lg font-bold {getNotaColor(estatisticas.mediaEspirito)}">
                {estatisticas.mediaEspirito.toFixed(1)}
              </span>
            </div>
            <div class="w-full bg-gray-200 rounded-full h-2">
              <div 
                class="h-2 rounded-full bg-green-500"
                style="width: {getProgressWidth(estatisticas.mediaEspirito)}%"
              ></div>
            </div>
          </div>
          
          <div>
            <div class="flex items-center justify-between mb-2">
              <span class="text-sm font-medium text-gray-700">Média Caráter</span>
              <span class="text-lg font-bold {getNotaColor(estatisticas.mediaCaractere)}">
                {estatisticas.mediaCaractere.toFixed(1)}
              </span>
            </div>
            <div class="w-full bg-gray-200 rounded-full h-2">
              <div 
                class="h-2 rounded-full bg-purple-500"
                style="width: {getProgressWidth(estatisticas.mediaCaractere)}%"
              ></div>
            </div>
          </div>
          
          <div>
            <div class="flex items-center justify-between mb-2">
              <span class="text-sm font-medium text-gray-700">Média Disposição</span>
              <span class="text-lg font-bold {getNotaColor(estatisticas.mediaDisposicao)}">
                {estatisticas.mediaDisposicao.toFixed(1)}
              </span>
            </div>
            <div class="w-full bg-gray-200 rounded-full h-2">
              <div 
                class="h-2 rounded-full bg-blue-500"
                style="width: {getProgressWidth(estatisticas.mediaDisposicao)}%"
              ></div>
            </div>
          </div>
        </div>
      </Card>
      
      <Card class="p-6">
        <h3 class="text-lg font-semibold text-gray-900 mb-4">Resumo de Avaliações</h3>
        <div class="space-y-4">
          <div class="flex items-center justify-between">
            <span class="text-sm font-medium text-gray-700">Total de Avaliações</span>
            <span class="text-lg font-bold text-gray-900">{estatisticas.totalAvaliacoes}</span>
          </div>
          
          <div class="flex items-center justify-between">
            <span class="text-sm font-medium text-gray-700">Avaliações por Jovem</span>
            <span class="text-lg font-bold text-gray-900">
              {estatisticas.totalJovens > 0 ? (estatisticas.totalAvaliacoes / estatisticas.totalJovens).toFixed(1) : '0'}
            </span>
          </div>
          
          <div class="flex items-center justify-between">
            <span class="text-sm font-medium text-gray-700">Taxa de Aprovação</span>
            <span class="text-lg font-bold text-gray-900">
              {estatisticas.totalJovens > 0 ? ((estatisticas.aprovados / estatisticas.totalJovens) * 100).toFixed(1) : '0'}%
            </span>
          </div>
        </div>
      </Card>
    </div>
    
    <!-- Relatório por Localização -->
    {#if relatorioLocalizacao.length > 0}
      <Card class="p-6">
        <h3 class="text-lg font-semibold text-gray-900 mb-4">Distribuição por Localização</h3>
        <div class="overflow-x-auto">
          <table class="min-w-full divide-y divide-gray-200">
            <thead class="bg-gray-50">
              <tr>
                <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Localização
                </th>
                <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Total
                </th>
                <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Aprovados
                </th>
                <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Pré-aprovados
                </th>
                <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Pendentes
                </th>
                <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Idade Média
                </th>
              </tr>
            </thead>
            <tbody class="bg-white divide-y divide-gray-200">
              {#each relatorioLocalizacao as local}
                <tr class="hover:bg-gray-50">
                  <td class="px-6 py-4 whitespace-nowrap">
                    <div>
                      <div class="text-sm font-medium text-gray-900">{local.estado}</div>
                      <div class="text-sm text-gray-500">
                        {local.bloco} • {local.regiao} • {local.igreja}
                      </div>
                    </div>
                  </td>
                  <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-900">
                    {local.total}
                  </td>
                  <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-900">
                    {local.aprovados}
                  </td>
                  <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-900">
                    {local.preAprovados}
                  </td>
                  <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-900">
                    {local.pendentes}
                  </td>
                  <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-900">
                    {local.idadeMedia.toFixed(1)} anos
                  </td>
                </tr>
              {/each}
            </tbody>
          </table>
        </div>
      </Card>
    {/if}
    
    <!-- Gráficos Analíticos -->
    {#if avaliacoes.length > 0}
      <div class="grid grid-cols-1 lg:grid-cols-2 gap-6">
        <!-- Gráfico de Avaliações -->
        <Card class="p-6">
          <div class="flex items-center justify-between mb-4">
            <h3 class="text-lg font-semibold text-gray-900">Distribuição de Avaliações</h3>
            <div class="flex space-x-2">
              <select
                bind:value={tipoGrafico}
                class="text-sm border border-gray-300 rounded-md px-3 py-1 focus:outline-none focus:ring-2 focus:ring-blue-500"
              >
                <option value="bar">Barras</option>
                <option value="pie">Pizza</option>
                <option value="doughnut">Rosquinha</option>
              </select>
            </div>
          </div>
          <GraficoAvaliacoes
            dados={avaliacoes}
            tipo={tipoGrafico}
            titulo="Avaliações por Categoria"
            altura={300}
          />
        </Card>
        
        <!-- Gráfico de Localização -->
        <Card class="p-6">
          <div class="flex items-center justify-between mb-4">
            <h3 class="text-lg font-semibold text-gray-900">Distribuição por Estado</h3>
            <div class="flex space-x-2">
              <select
                bind:value={tipoGrafico}
                class="text-sm border border-gray-300 rounded-md px-3 py-1 focus:outline-none focus:ring-2 focus:ring-blue-500"
              >
                <option value="bar">Barras</option>
                <option value="pie">Pizza</option>
                <option value="doughnut">Rosquinha</option>
              </select>
            </div>
          </div>
          <GraficoLocalizacao
            dados={relatorioLocalizacao}
            tipo={tipoGrafico}
            titulo="Jovens por Estado"
            nivel="estado"
            altura={300}
          />
        </Card>
      </div>
      
      <!-- Gráfico de Evolução -->
      <Card class="p-6">
        <div class="flex items-center justify-between mb-4">
          <h3 class="text-lg font-semibold text-gray-900">Evolução Temporal</h3>
          <div class="flex space-x-2">
            <select
              bind:value={periodoGrafico}
              class="text-sm border border-gray-300 rounded-md px-3 py-1 focus:outline-none focus:ring-2 focus:ring-blue-500"
            >
              <option value="dia">Diário</option>
              <option value="semana">Semanal</option>
              <option value="mes">Mensal</option>
              <option value="ano">Anual</option>
            </select>
            <select
              bind:value={tipoGrafico}
              class="text-sm border border-gray-300 rounded-md px-3 py-1 focus:outline-none focus:ring-2 focus:ring-blue-500"
            >
              <option value="line">Linha</option>
              <option value="bar">Barras</option>
            </select>
          </div>
        </div>
        <GraficoEvolucao
          dados={avaliacoes}
          tipo={tipoGrafico}
          titulo="Evolução das Avaliações"
          periodo={periodoGrafico}
          altura={400}
        />
      </Card>
    {/if}
  {/if}
</div>
