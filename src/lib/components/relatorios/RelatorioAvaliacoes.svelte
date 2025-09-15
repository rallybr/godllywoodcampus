<script>
  import { onMount } from 'svelte';
  import { gerarRelatorioAvaliacoes, exportarParaCSV, exportarParaExcel, exportarParaPDF } from '$lib/stores/relatorios';
  import Button from '$lib/components/ui/Button.svelte';
  import Card from '$lib/components/ui/Card.svelte';
  import RelatorioFiltros from './RelatorioFiltros.svelte';
  
  let dados = [];
  let loading = false;
  let error = '';
  let filtros = {};
  let totalRegistros = 0;
  let paginaAtual = 1;
  let registrosPorPagina = 50;
  
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
      const resultado = await gerarRelatorioAvaliacoes(filtros);
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
      const nomeArquivo = `relatorio_avaliacoes_${new Date().toISOString().split('T')[0]}`;
      
      // Exportar para CSV
      exportarParaCSV(dados, `${nomeArquivo}.csv`);
      
      // Exportar para Excel
      await exportarParaExcel(dados, `${nomeArquivo}.xlsx`);
      
      // Exportar para PDF
      await exportarParaPDF(dados, 'Relatório de Avaliações', `${nomeArquivo}.pdf`);
      
    } catch (err) {
      error = err.message;
    }
  }
  
  // Função para obter cor da nota
  function getNotaColor(nota) {
    if (nota >= 8) return 'text-green-600 bg-green-100';
    if (nota >= 6) return 'text-yellow-600 bg-yellow-100';
    if (nota >= 4) return 'text-orange-600 bg-orange-100';
    return 'text-red-600 bg-red-100';
  }
  
  // Função para obter cor da avaliação
  function getAvaliacaoColor(valor, tipo) {
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
    
    return colors[tipo]?.[valor] || 'text-gray-600 bg-gray-100';
  }
  
  // Função para obter texto da avaliação
  function getAvaliacaoText(valor, tipo) {
    const texts = {
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
    
    return texts[tipo]?.[valor] || valor;
  }
  
  // Função para formatar data
  function formatDate(dateString) {
    return new Date(dateString).toLocaleDateString('pt-BR', {
      day: '2-digit',
      month: '2-digit',
      year: 'numeric',
      hour: '2-digit',
      minute: '2-digit'
    });
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
</script>

<div class="space-y-6">
  <!-- Filtros -->
  <RelatorioFiltros
    {filtros}
    tipoRelatorio="avaliacoes"
    onFiltrosChange={(novosFiltros) => filtros = novosFiltros}
    onGerarRelatorio={handleGerarRelatorio}
    onExportar={handleExportar}
    {loading}
  />
  
  <!-- Resultados -->
  <Card class="p-6">
    <div class="flex items-center justify-between mb-6">
      <div>
        <h3 class="text-lg font-semibold text-gray-900">Relatório de Avaliações</h3>
        <p class="text-sm text-gray-600">
          {totalRegistros} registro{totalRegistros !== 1 ? 's' : ''} encontrado{totalRegistros !== 1 ? 's' : ''}
        </p>
      </div>
      
      {#if dados.length > 0}
        <div class="flex space-x-2">
          <Button
            variant="outline"
            size="sm"
            on:click={() => exportarParaCSV(dados, 'relatorio_avaliacoes.csv')}
          >
            <svg class="w-4 h-4 mr-1" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 10v6m0 0l-3-3m3 3l3-3m2 8H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z" />
            </svg>
            CSV
          </Button>
          
          <Button
            variant="outline"
            size="sm"
            on:click={() => exportarParaExcel(dados, 'relatorio_avaliacoes.xlsx')}
          >
            <svg class="w-4 h-4 mr-1" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z" />
            </svg>
            Excel
          </Button>
          
          <Button
            variant="outline"
            size="sm"
            on:click={() => exportarParaPDF(dados, 'Relatório de Avaliações', 'relatorio_avaliacoes.pdf')}
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
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 19v-6a2 2 0 00-2-2H5a2 2 0 00-2 2v6a2 2 0 002 2h2a2 2 0 002-2zm0 0V9a2 2 0 012-2h2a2 2 0 012 2v10m-6 0a2 2 0 002 2h2a2 2 0 002-2m0 0V5a2 2 0 012-2h2a2 2 0 012 2v14a2 2 0 01-2 2h-2a2 2 0 01-2-2z" />
          </svg>
        </div>
        <h3 class="text-lg font-semibold text-gray-900 mb-2">Nenhum registro encontrado</h3>
        <p class="text-gray-600">Ajuste os filtros e tente novamente.</p>
      </div>
    {:else}
      <!-- Tabela de dados -->
      <div class="overflow-x-auto">
        <table class="min-w-full divide-y divide-gray-200">
          <thead class="bg-gray-50">
            <tr>
              <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                Jovem
              </th>
              <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                Avaliador
              </th>
              <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                Nota
              </th>
              <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                Espírito
              </th>
              <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                Caráter
              </th>
              <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                Disposição
              </th>
              <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                Data
              </th>
            </tr>
          </thead>
          <tbody class="bg-white divide-y divide-gray-200">
            {#each getDadosPaginados() as avaliacao}
              <tr class="hover:bg-gray-50">
                <td class="px-6 py-4 whitespace-nowrap">
                  <div class="flex items-center">
                    <div class="w-10 h-10 bg-gradient-to-br from-blue-500 to-purple-600 rounded-full flex items-center justify-center mr-3">
                      <span class="text-white font-bold text-sm">
                        {avaliacao.jovem?.nome_completo?.charAt(0) || 'J'}
                      </span>
                    </div>
                    <div>
                      <div class="text-sm font-medium text-gray-900">
                        {avaliacao.jovem?.nome_completo || 'N/A'}
                      </div>
                      <div class="text-sm text-gray-500">
                        {avaliacao.jovem?.estado?.nome || 'N/A'} • {avaliacao.jovem?.bloco?.nome || 'N/A'}
                      </div>
                    </div>
                  </div>
                </td>
                <td class="px-6 py-4 whitespace-nowrap">
                  <div class="text-sm text-gray-900">
                    {avaliacao.avaliador?.nome || 'N/A'}
                  </div>
                  <div class="text-sm text-gray-500">
                    {avaliacao.avaliador?.email || 'N/A'}
                  </div>
                </td>
                <td class="px-6 py-4 whitespace-nowrap">
                  <span class="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium {getNotaColor(avaliacao.nota)}">
                    {avaliacao.nota}/10
                  </span>
                </td>
                <td class="px-6 py-4 whitespace-nowrap">
                  <span class="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium {getAvaliacaoColor(avaliacao.espirito, 'espirito')}">
                    {getAvaliacaoText(avaliacao.espirito, 'espirito')}
                  </span>
                </td>
                <td class="px-6 py-4 whitespace-nowrap">
                  <span class="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium {getAvaliacaoColor(avaliacao.caractere, 'caractere')}">
                    {getAvaliacaoText(avaliacao.caractere, 'caractere')}
                  </span>
                </td>
                <td class="px-6 py-4 whitespace-nowrap">
                  <span class="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium {getAvaliacaoColor(avaliacao.disposicao, 'disposicao')}">
                    {getAvaliacaoText(avaliacao.disposicao, 'disposicao')}
                  </span>
                </td>
                <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                  {formatDate(avaliacao.criado_em)}
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
