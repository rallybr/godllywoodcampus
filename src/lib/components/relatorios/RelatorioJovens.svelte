<script>
  import { onMount } from 'svelte';
  import { gerarRelatorioJovens, exportarParaCSV, exportarParaExcel, exportarParaPDF } from '$lib/stores/relatorios';
  import Button from '$lib/components/ui/Button.svelte';
  import Card from '$lib/components/ui/Card.svelte';
  import RelatorioFiltros from './RelatorioFiltros.svelte';
  import GraficoLocalizacao from '$lib/components/charts/GraficoLocalizacao.svelte';
  import GraficoEvolucao from '$lib/components/charts/GraficoEvolucao.svelte';
  
  let dados = [];
  let loading = false;
  let error = '';
  let filtros = {};
  let totalRegistros = 0;
  let paginaAtual = 1;
  let registrosPorPagina = 50;
  let tipoGrafico = 'bar';
  let periodoGrafico = 'mes';
  let mostrarGraficos = true;
  
  onMount(() => {
    // Carregar dados iniciais
    handleGerarRelatorio({});
  });
  
  // Função para gerar relatório
  async function handleGerarRelatorio(novosFiltros) {
    filtros = novosFiltros;
    loading = true;
    error = '';
    
    try {
      const resultado = await gerarRelatorioJovens(filtros);
      dados = resultado;
      totalRegistros = resultado.length;
      paginaAtual = 1;
    } catch (err) {
      error = err.message;
    } finally {
      loading = false;
    }
  }
  
  // Função para exportar
  async function handleExportar(novosFiltros) {
    if (dados.length === 0) {
      error = 'Nenhum dado para exportar. Gere o relatório primeiro.';
      return;
    }
    
    try {
      const nomeArquivo = `relatorio_jovens_${new Date().toISOString().split('T')[0]}`;
      
      // Exportar para CSV
      exportarParaCSV(dados, `${nomeArquivo}.csv`);
      
      // Exportar para Excel
      await exportarParaExcel(dados, `${nomeArquivo}.xlsx`);
      
      // Exportar para PDF
      await exportarParaPDF(dados, 'Relatório de Jovens', `${nomeArquivo}.pdf`);
      
    } catch (err) {
      error = err.message;
    }
  }
  
  // Função para obter cor do status
  function getStatusColor(status) {
    switch (status) {
      case 'aprovado':
        return 'text-green-600 bg-green-100';
      case 'pre_aprovado':
        return 'text-yellow-600 bg-yellow-100';
      case null:
      case undefined:
        return 'text-gray-600 bg-gray-100';
      default:
        return 'text-blue-600 bg-blue-100';
    }
  }
  
  // Função para obter texto do status
  function getStatusText(status) {
    switch (status) {
      case 'aprovado':
        return 'Aprovado';
      case 'pre_aprovado':
        return 'Pré-aprovado';
      case null:
      case undefined:
        return 'Pendente';
      default:
        return 'Desconhecido';
    }
  }
  
  // Função para obter dados paginados
  function getDadosPaginados() {
    const inicio = (paginaAtual - 1) * registrosPorPagina;
    const fim = inicio + registrosPorPagina;
    return dados.slice(inicio, fim);
  }
  
  // Função para obter total de páginas
  function getTotalPaginas() {
    return Math.ceil(totalRegistros / registrosPorPagina);
  }
  
  // Função para mudar página
  function mudarPagina(novaPagina) {
    if (novaPagina >= 1 && novaPagina <= getTotalPaginas()) {
      paginaAtual = novaPagina;
    }
  }
  
  // Função para formatar data
  function formatDate(dateString) {
    if (!dateString) return 'Não informado';
    try {
      return new Date(dateString + 'T00:00:00').toLocaleDateString('pt-BR', {
        day: '2-digit',
        month: '2-digit',
        year: 'numeric'
      });
    } catch {
      return dateString;
    }
  }
</script>

<div class="space-y-6">
  <!-- Filtros -->
  <RelatorioFiltros
    {filtros}
    tipoRelatorio="jovens"
    onFiltrosChange={(novosFiltros) => filtros = novosFiltros}
    onGerarRelatorio={handleGerarRelatorio}
    onExportar={handleExportar}
    {loading}
  />
  
  <!-- Resultados -->
  <Card class="p-4 sm:p-6">
    <div class="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-3 sm:gap-0 mb-4 sm:mb-6">
      <div>
        <h3 class="text-lg font-semibold text-gray-900">Relatório de Jovens</h3>
        <p class="text-sm text-gray-600">
          {totalRegistros} registro{totalRegistros !== 1 ? 's' : ''} encontrado{totalRegistros !== 1 ? 's' : ''}
        </p>
      </div>
      
      {#if dados.length > 0}
        <div class="flex flex-wrap gap-2">
          <Button
            variant="outline"
            size="sm"
            on:click={() => exportarParaCSV(dados, 'relatorio_jovens.csv')}
          >
            <svg class="w-4 h-4 mr-1" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 10v6m0 0l-3-3m3 3l3-3m2 8H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z" />
            </svg>
            CSV
          </Button>
          
          <Button
            variant="outline"
            size="sm"
            on:click={() => exportarParaExcel(dados, 'relatorio_jovens.xlsx')}
          >
            <svg class="w-4 h-4 mr-1" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z" />
            </svg>
            Excel
          </Button>
          
          <Button
            variant="outline"
            size="sm"
            on:click={() => exportarParaPDF(dados, 'Relatório de Jovens', 'relatorio_jovens.pdf')}
          >
            <svg class="w-4 h-4 mr-1" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M7 21h10a2 2 0 002-2V9.414a1 1 0 00-.293-.707l-5.414-5.414A1 1 0 0012.586 3H7a2 2 0 00-2 2v14a2 2 0 002 2z" />
            </svg>
            PDF
          </Button>
        </div>
      {/if}
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
    {:else if dados.length === 0}
      <div class="text-center py-12">
        <div class="w-16 h-16 bg-gray-100 rounded-full flex items-center justify-center mx-auto mb-4">
          <svg class="w-8 h-8 text-gray-400" fill="none" viewBox="0 0 24 24" stroke="currentColor">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4.354a4 4 0 110 5.292M15 21H3v-1a6 6 0 0112 0v1zm0 0h6v-1a6 6 0 00-9-5.197m13.5-9a2.5 2.5 0 11-5 0 2.5 2.5 0 015 0z" />
          </svg>
        </div>
        <h3 class="text-lg font-semibold text-gray-900 mb-2">Nenhum jovem encontrado</h3>
        <p class="text-gray-600">Ajuste os filtros e tente novamente.</p>
      </div>
    {:else}
      <!-- Gráficos -->
      {#if mostrarGraficos}
        <div class="grid grid-cols-1 lg:grid-cols-2 gap-6 mb-6 sm:mb-8">
          <Card class="p-4 sm:p-6">
            <div class="flex items-center justify-between mb-4">
              <h4 class="text-md font-semibold text-gray-900">Distribuição por Estado</h4>
              <select
                bind:value={tipoGrafico}
                class="text-sm border border-gray-300 rounded-md px-2 py-1"
              >
                <option value="bar">Barras</option>
                <option value="pie">Pizza</option>
                <option value="doughnut">Rosquinha</option>
              </select>
            </div>
            <GraficoLocalizacao
              dados={dados}
              tipo={tipoGrafico}
              titulo="Jovens por Estado"
              nivel="estado"
              altura={250}
            />
          </Card>
          
          <Card class="p-4 sm:p-6">
            <div class="flex items-center justify-between mb-4">
              <h4 class="text-md font-semibold text-gray-900">Evolução Temporal</h4>
              <select
                bind:value={periodoGrafico}
                class="text-sm border border-gray-300 rounded-md px-2 py-1"
              >
                <option value="dia">Diário</option>
                <option value="semana">Semanal</option>
                <option value="mes">Mensal</option>
              </select>
            </div>
            <GraficoEvolucao
              dados={dados}
              tipo="line"
              titulo="Evolução dos Cadastros"
              periodo={periodoGrafico}
              altura={250}
            />
          </Card>
        </div>
      {/if}
      
      <!-- Tabela de dados -->
      <div class="overflow-x-auto -mx-4 sm:mx-0">
        <table class="min-w-full divide-y divide-gray-200">
          <thead class="bg-gray-50">
            <tr>
              <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                Jovem
              </th>
              <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                Idade
              </th>
              <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                Sexo
              </th>
              <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                Estado Civil
              </th>
              <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                Localização
              </th>
              <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                Status
              </th>
              <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                Data Cadastro
              </th>
            </tr>
          </thead>
          <tbody class="bg-white divide-y divide-gray-200">
            {#each getDadosPaginados() as jovem}
              <tr class="hover:bg-gray-50">
                <td class="px-4 sm:px-6 py-4 whitespace-nowrap">
                  <div class="flex items-center">
                    <div class="w-10 h-10 bg-gradient-to-br from-blue-500 to-purple-600 rounded-full flex items-center justify-center mr-3">
                      <span class="text-white font-bold text-sm">
                        {jovem.nome_completo?.charAt(0) || 'J'}
                      </span>
                    </div>
                    <div>
                      <div class="text-sm font-medium text-gray-900">
                        {jovem.nome_completo}
                      </div>
                      <div class="text-sm text-gray-500">
                        {jovem.whatsapp || 'N/A'}
                      </div>
                    </div>
                  </div>
                </td>
                <td class="px-4 sm:px-6 py-4 whitespace-nowrap text-sm text-gray-900">
                  {jovem.idade} anos
                </td>
                <td class="px-4 sm:px-6 py-4 whitespace-nowrap text-sm text-gray-900">
                  {jovem.sexo === 'masculino' ? 'Masculino' : 'Feminino'}
                </td>
                <td class="px-4 sm:px-6 py-4 whitespace-nowrap text-sm text-gray-900">
                  {jovem.estado_civil || 'N/A'}
                </td>
                <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-900">
                  <div>
                    <div class="font-medium">{jovem.estado?.nome || 'N/A'}</div>
                    <div class="text-gray-500">
                      {jovem.bloco?.nome || 'N/A'} • {jovem.regiao?.nome || 'N/A'}
                    </div>
                  </div>
                </td>
                <td class="px-4 sm:px-6 py-4 whitespace-nowrap">
                  <span class="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium {getStatusColor(jovem.aprovado)}">
                    {getStatusText(jovem.aprovado)}
                  </span>
                </td>
                <td class="px-4 sm:px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                  {formatDate(jovem.data_cadastro)}
                </td>
              </tr>
            {/each}
          </tbody>
        </table>
      </div>
      
      <!-- Paginação -->
      {#if getTotalPaginas() > 1}
        <div class="flex items-center justify-between mt-6">
          <div class="text-sm text-gray-700">
            Mostrando {((paginaAtual - 1) * registrosPorPagina) + 1} a {Math.min(paginaAtual * registrosPorPagina, totalRegistros)} de {totalRegistros} registros
          </div>
          
          <div class="flex space-x-2">
            <Button
              variant="outline"
              size="sm"
              on:click={() => mudarPagina(paginaAtual - 1)}
              disabled={paginaAtual === 1}
            >
              Anterior
            </Button>
            
            <span class="px-3 py-2 text-sm text-gray-700">
              Página {paginaAtual} de {getTotalPaginas()}
            </span>
            
            <Button
              variant="outline"
              size="sm"
              on:click={() => mudarPagina(paginaAtual + 1)}
              disabled={paginaAtual === getTotalPaginas()}
            >
              Próxima
            </Button>
          </div>
        </div>
      {/if}
    {/if}
  </Card>
</div>