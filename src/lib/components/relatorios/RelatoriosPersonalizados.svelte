<script>
  // @ts-nocheck
  import { onMount } from 'svelte';
  import { userProfile } from '$lib/stores/auth';
  import { gerarRelatorioJovens, gerarRelatorioAvaliacoes, gerarEstatisticasGerais, exportarParaCSV, exportarParaExcel, exportarParaPDF } from '$lib/stores/relatorios';
  import Card from '$lib/components/ui/Card.svelte';
  import Button from '$lib/components/ui/Button.svelte';
  import Input from '$lib/components/ui/Input.svelte';
  import Select from '$lib/components/ui/Select.svelte';
  import GraficoAvaliacoes from '$lib/components/charts/GraficoAvaliacoes.svelte';
  import GraficoLocalizacao from '$lib/components/charts/GraficoLocalizacao.svelte';
  import GraficoEvolucao from '$lib/components/charts/GraficoEvolucao.svelte';
  
  let relatoriosSalvos = [];
  let relatorioAtual = null;
  let loading = false;
  let error = '';
  let sucesso = '';
  
  // Dados do relatório
  let dados = [];
  let estatisticas = null;
  let tipoRelatorio = 'jovens';
  let nomeRelatorio = '';
  let descricaoRelatorio = '';
  
  // Filtros
  let filtros = {
    estado_id: '',
    bloco_id: '',
    regiao_id: '',
    igreja_id: '',
    edicao_id: '',
    aprovado: '',
    sexo: '',
    idade_min: '',
    idade_max: '',
    avaliador_id: '',
    nota_min: '',
    nota_max: '',
    data_inicio: '',
    data_fim: ''
  };
  
  // Configurações de gráfico
  let tipoGrafico = 'bar';
  let periodoGrafico = 'mes';
  let mostrarGraficos = true;
  
  onMount(() => {
    carregarRelatoriosSalvos();
  });
  
  // Carregar relatórios salvos do localStorage
  function carregarRelatoriosSalvos() {
    const salvos = localStorage.getItem('relatorios_personalizados');
    if (salvos) {
      relatoriosSalvos = JSON.parse(salvos);
    }
  }
  
  // Salvar relatórios no localStorage
  function salvarRelatorios() {
    localStorage.setItem('relatorios_personalizados', JSON.stringify(relatoriosSalvos));
  }
  
  // Gerar relatório
  async function gerarRelatorio() {
    if (!nomeRelatorio.trim()) {
      error = 'Nome do relatório é obrigatório';
      return;
    }
    
    loading = true;
    error = '';
    sucesso = '';
    
    try {
      let resultado;
      
      switch (tipoRelatorio) {
        case 'jovens':
          resultado = await gerarRelatorioJovens(filtros);
          break;
        case 'avaliacoes':
          resultado = await gerarRelatorioAvaliacoes(filtros);
          break;
        case 'estatisticas':
          resultado = await gerarEstatisticasGerais(filtros);
          break;
        default:
          throw new Error('Tipo de relatório inválido');
      }
      
      dados = resultado;
      relatorioAtual = {
        id: Date.now().toString(),
        nome: nomeRelatorio,
        descricao: descricaoRelatorio,
        tipo: tipoRelatorio,
        filtros: { ...filtros },
        dados: resultado,
        criadoEm: new Date().toISOString()
      };
      
      sucesso = 'Relatório gerado com sucesso!';
    } catch (err) {
      error = err.message;
    } finally {
      loading = false;
    }
  }
  
  // Salvar relatório
  function salvarRelatorio() {
    if (!relatorioAtual) {
      error = 'Nenhum relatório para salvar';
      return;
    }
    
    relatoriosSalvos.push(relatorioAtual);
    salvarRelatorios();
    sucesso = 'Relatório salvo com sucesso!';
  }
  
  // Carregar relatório salvo
  function carregarRelatorio(relatorio) {
    relatorioAtual = relatorio;
    dados = relatorio.dados;
    filtros = { ...relatorio.filtros };
    tipoRelatorio = relatorio.tipo;
    nomeRelatorio = relatorio.nome;
    descricaoRelatorio = relatorio.descricao;
    sucesso = `Relatório "${relatorio.nome}" carregado com sucesso!`;
  }
  
  // Excluir relatório salvo
  function excluirRelatorio(id) {
    relatoriosSalvos = relatoriosSalvos.filter(r => r.id !== id);
    salvarRelatorios();
    sucesso = 'Relatório excluído com sucesso!';
  }
  
  // Exportar relatório
  async function exportarRelatorio(formato) {
    if (!dados || dados.length === 0) {
      error = 'Nenhum dado para exportar';
      return;
    }
    
    try {
      const nomeArquivo = `relatorio_${nomeRelatorio || 'personalizado'}_${new Date().toISOString().split('T')[0]}`;
      
      switch (formato) {
        case 'csv':
          exportarParaCSV(dados, `${nomeArquivo}.csv`);
          break;
        case 'excel':
          await exportarParaExcel(dados, `${nomeArquivo}.xlsx`);
          break;
        case 'pdf':
          await exportarParaPDF(dados, nomeRelatorio || 'Relatório Personalizado', `${nomeArquivo}.pdf`);
          break;
      }
      
      sucesso = `Relatório exportado em ${formato.toUpperCase()} com sucesso!`;
    } catch (err) {
      error = err.message;
    }
  }
  
  // Limpar relatório atual
  function limparRelatorio() {
    relatorioAtual = null;
    dados = [];
    estatisticas = null;
    nomeRelatorio = '';
    descricaoRelatorio = '';
    filtros = {
      estado_id: '',
      bloco_id: '',
      regiao_id: '',
      igreja_id: '',
      edicao_id: '',
      aprovado: '',
      sexo: '',
      idade_min: '',
      idade_max: '',
      avaliador_id: '',
      nota_min: '',
      nota_max: '',
      data_inicio: '',
      data_fim: ''
    };
    error = '';
    sucesso = '';
  }
</script>

<div class="space-y-6">
  <!-- Header -->
  <div class="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-3">
    <div>
      <h1 class="text-2xl font-bold text-gray-900">Relatórios Personalizados</h1>
      <p class="text-gray-600">Crie e gerencie seus próprios relatórios</p>
    </div>
    <Button variant="outline" on:click={limparRelatorio}>
      <svg class="w-4 h-4 mr-2" fill="none" viewBox="0 0 24 24" stroke="currentColor">
        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 6v6m0 0v6m0-6h6m-6 0H6" />
      </svg>
      Novo Relatório
    </Button>
  </div>
  
  <!-- Mensagens -->
  {#if error}
    <div class="bg-red-50 border border-red-200 rounded-lg p-4">
      <div class="flex items-center space-x-2">
        <svg class="w-5 h-5 text-red-500" fill="none" viewBox="0 0 24 24" stroke="currentColor">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8v4m0 4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
        </svg>
        <p class="text-sm text-red-600 font-medium">{error}</p>
      </div>
    </div>
  {/if}
  
  {#if sucesso}
    <div class="bg-green-50 border border-green-200 rounded-lg p-4">
      <div class="flex items-center space-x-2">
        <svg class="w-5 h-5 text-green-500" fill="none" viewBox="0 0 24 24" stroke="currentColor">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7" />
        </svg>
        <p class="text-sm text-green-600 font-medium">{sucesso}</p>
      </div>
    </div>
  {/if}
  
  <div class="grid grid-cols-1 lg:grid-cols-3 gap-4 sm:gap-6">
    <!-- Painel de Criação -->
    <div class="lg:col-span-1 space-y-6">
      <!-- Configurações do Relatório -->
      <Card class="p-4 sm:p-6">
        <h3 class="text-lg font-semibold text-gray-900 mb-4">Configurações</h3>
        
        <div class="space-y-4">
          <Input
            label="Nome do Relatório"
            bind:value={nomeRelatorio}
            placeholder="Ex: Relatório de Jovens Aprovados"
          />
          
          <Input
            label="Descrição"
            bind:value={descricaoRelatorio}
            placeholder="Descrição opcional do relatório"
          />
          
          <Select
            label="Tipo de Relatório"
            bind:value={tipoRelatorio}
            options={[
              { value: 'jovens', label: 'Jovens' },
              { value: 'avaliacoes', label: 'Avaliações' },
              { value: 'estatisticas', label: 'Estatísticas' }
            ]}
          />
          
          <div class="flex space-x-2">
            <Button
              variant="primary"
              on:click={gerarRelatorio}
              loading={loading}
              disabled={loading || !nomeRelatorio.trim()}
              class="flex-1"
            >
              Gerar Relatório
            </Button>
            
            {#if relatorioAtual}
              <Button
                variant="outline"
                on:click={salvarRelatorio}
                class="flex-1"
              >
                Salvar
              </Button>
            {/if}
          </div>
        </div>
      </Card>
      
      <!-- Filtros -->
      <Card class="p-4 sm:p-6">
        <h3 class="text-lg font-semibold text-gray-900 mb-4">Filtros</h3>
        
        <div class="space-y-4">
          <div class="grid grid-cols-2 gap-2">
            <Input
              label="Idade Mín"
              type="number"
              bind:value={filtros.idade_min}
              placeholder="18"
            />
            <Input
              label="Idade Máx"
              type="number"
              bind:value={filtros.idade_max}
              placeholder="35"
            />
          </div>
          
          <div class="grid grid-cols-2 gap-2">
            <Input
              label="Nota Mín"
              type="number"
              bind:value={filtros.nota_min}
              placeholder="7"
              min="1"
              max="10"
            />
            <Input
              label="Nota Máx"
              type="number"
              bind:value={filtros.nota_max}
              placeholder="10"
              min="1"
              max="10"
            />
          </div>
          
          <div class="grid grid-cols-2 gap-2">
            <Input
              label="Data Início"
              type="date"
              bind:value={filtros.data_inicio}
            />
            <Input
              label="Data Fim"
              type="date"
              bind:value={filtros.data_fim}
            />
          </div>
          
          <Select
            label="Status de Aprovação"
            bind:value={filtros.aprovado}
            options={[
              { value: '', label: 'Todos' },
              { value: 'aprovado', label: 'Aprovado' },
              { value: 'pre_aprovado', label: 'Pré-aprovado' },
              { value: 'null', label: 'Pendente' }
            ]}
          />
          
          <Select
            label="Sexo"
            bind:value={filtros.sexo}
            options={[
              { value: '', label: 'Todos' },
              { value: 'masculino', label: 'Masculino' },
              { value: 'feminino', label: 'Feminino' }
            ]}
          />
        </div>
      </Card>
      
      <!-- Relatórios Salvos -->
      {#if relatoriosSalvos.length > 0}
        <Card class="p-4 sm:p-6">
          <h3 class="text-lg font-semibold text-gray-900 mb-4">Relatórios Salvos</h3>
          
          <div class="space-y-2">
            {#each relatoriosSalvos as relatorio}
              <div class="flex items-center justify-between p-3 bg-gray-50 rounded-lg">
                <div class="flex-1">
                  <p class="text-sm font-medium text-gray-900">{relatorio.nome}</p>
                  <p class="text-xs text-gray-500">
                    {relatorio.tipo} • {new Date(relatorio.criadoEm).toLocaleDateString('pt-BR')}
                  </p>
                </div>
                <div class="flex space-x-1">
                  <Button
                    variant="outline"
                    size="sm"
                    on:click={() => carregarRelatorio(relatorio)}
                  >
                    <svg class="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 16v1a3 3 0 003 3h10a3 3 0 003-3v-1m-4-8l-4-4m0 0L8 8m4-4v12" />
                    </svg>
                  </Button>
                  <Button
                    variant="outline"
                    size="sm"
                    on:click={() => excluirRelatorio(relatorio.id)}
                  >
                    <svg class="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16" />
                    </svg>
                  </Button>
                </div>
              </div>
            {/each}
          </div>
        </Card>
      {/if}
    </div>
    
    <!-- Painel de Resultados -->
    <div class="lg:col-span-2 space-y-6">
      {#if relatorioAtual}
        <!-- Header do Relatório -->
        <Card class="p-6">
          <div class="flex items-center justify-between mb-4">
            <div>
              <h3 class="text-lg font-semibold text-gray-900">{relatorioAtual.nome}</h3>
              {#if relatorioAtual.descricao}
                <p class="text-sm text-gray-600">{relatorioAtual.descricao}</p>
              {/if}
            </div>
            
            <div class="flex space-x-2">
              <Button
                variant="outline"
                size="sm"
                on:click={() => exportarRelatorio('csv')}
              >
                CSV
              </Button>
              <Button
                variant="outline"
                size="sm"
                on:click={() => exportarRelatorio('excel')}
              >
                Excel
              </Button>
              <Button
                variant="outline"
                size="sm"
                on:click={() => exportarRelatorio('pdf')}
              >
                PDF
              </Button>
            </div>
          </div>
          
          <div class="text-sm text-gray-600">
            <p><strong>Tipo:</strong> {relatorioAtual.tipo}</p>
            <p><strong>Registros:</strong> {dados.length}</p>
            <p><strong>Criado em:</strong> {new Date(relatorioAtual.criadoEm).toLocaleString('pt-BR')}</p>
          </div>
        </Card>
        
        <!-- Gráficos -->
        {#if mostrarGraficos && dados.length > 0}
          <div class="grid grid-cols-1 lg:grid-cols-2 gap-4 sm:gap-6">
            <Card class="p-4 sm:p-6">
              <div class="flex items-center justify-between mb-4">
                <h4 class="text-md font-semibold text-gray-900">Distribuição</h4>
                <select
                  bind:value={tipoGrafico}
                  class="text-sm border border-gray-300 rounded-md px-2 py-1"
                >
                  <option value="bar">Barras</option>
                  <option value="pie">Pizza</option>
                  <option value="doughnut">Rosquinha</option>
                </select>
              </div>
              
              {#if tipoRelatorio === 'avaliacoes'}
                <GraficoAvaliacoes
                  dados={dados}
                  tipo={tipoGrafico}
                  titulo="Avaliações"
                  altura={250}
                />
              {:else}
                <GraficoLocalizacao
                  dados={dados}
                  tipo={tipoGrafico}
                  titulo="Distribuição"
                  nivel="estado"
                  altura={250}
                />
              {/if}
            </Card>
            
            <Card class="p-4 sm:p-6">
              <div class="flex items-center justify-between mb-4">
                <h4 class="text-md font-semibold text-gray-900">Evolução</h4>
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
                titulo="Evolução"
                periodo={periodoGrafico}
                altura={250}
              />
            </Card>
          </div>
        {/if}
        
        <!-- Tabela de Dados -->
        {#if dados.length > 0}
          <Card class="p-4 sm:p-6">
            <h4 class="text-md font-semibold text-gray-900 mb-4">Dados do Relatório</h4>
            
            <div class="overflow-x-auto">
              <table class="min-w-full divide-y divide-gray-200">
                <thead class="bg-gray-50">
                  <tr>
                    {#if tipoRelatorio === 'jovens'}
                      <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Nome</th>
                      <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Idade</th>
                      <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Estado</th>
                      <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Status</th>
                    {:else if tipoRelatorio === 'avaliacoes'}
                      <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Jovem</th>
                      <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Avaliador</th>
                      <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Nota</th>
                      <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Data</th>
                    {/if}
                  </tr>
                </thead>
                <tbody class="bg-white divide-y divide-gray-200">
                  {#each dados.slice(0, 10) as item}
                    <tr class="hover:bg-gray-50">
                      {#if tipoRelatorio === 'jovens'}
                        <td class="px-6 py-4 whitespace-nowrap text-sm font-medium text-gray-900">
                          {item.nome_completo}
                        </td>
                        <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                          {item.idade}
                        </td>
                        <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                          {item.estado?.nome || 'N/A'}
                        </td>
                        <td class="px-6 py-4 whitespace-nowrap">
                          <span class="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium
                            {item.aprovado === 'aprovado' ? 'bg-green-100 text-green-800' : 
                             item.aprovado === 'pre_aprovado' ? 'bg-yellow-100 text-yellow-800' : 
                             'bg-gray-100 text-gray-800'}">
                            {item.aprovado === 'aprovado' ? 'Aprovado' : 
                             item.aprovado === 'pre_aprovado' ? 'Pré-aprovado' : 
                             'Pendente'}
                          </span>
                        </td>
                      {:else if tipoRelatorio === 'avaliacoes'}
                        <td class="px-6 py-4 whitespace-nowrap text-sm font-medium text-gray-900">
                          {item.jovem?.nome_completo || 'N/A'}
                        </td>
                        <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                          {item.avaliador?.nome || 'N/A'}
                        </td>
                        <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                          {item.nota}/10
                        </td>
                        <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                          {new Date(item.criado_em).toLocaleDateString('pt-BR')}
                        </td>
                      {/if}
                    </tr>
                  {/each}
                </tbody>
              </table>
            </div>
            
            {#if dados.length > 10}
              <div class="mt-4 text-center">
                <p class="text-sm text-gray-500">
                  Mostrando 10 de {dados.length} registros
                </p>
              </div>
            {/if}
          </Card>
        {/if}
      {:else}
        <Card class="p-8 sm:p-12">
          <div class="text-center">
            <svg class="w-16 h-16 text-gray-400 mx-auto mb-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 19v-6a2 2 0 00-2-2H5a2 2 0 00-2 2v6a2 2 0 002 2h2a2 2 0 002-2zm0 0V9a2 2 0 012-2h2a2 2 0 012 2v10m-6 0a2 2 0 002 2h2a2 2 0 002-2m0 0V5a2 2 0 012-2h2a2 2 0 012 2v14a2 2 0 01-2 2h-2a2 2 0 01-2-2z" />
            </svg>
            <h3 class="text-lg font-semibold text-gray-900 mb-2">Nenhum relatório gerado</h3>
            <p class="text-gray-600">Configure os filtros e gere seu primeiro relatório personalizado.</p>
          </div>
        </Card>
      {/if}
    </div>
  </div>
</div>
