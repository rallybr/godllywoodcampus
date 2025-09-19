<script>
  // @ts-nocheck
  import { onMount } from 'svelte';
  import { Chart, registerables } from 'chart.js';
  import { Chart as SvelteChart } from 'svelte-chartjs';
  
  export let dados = [];
  export let tipo = 'line'; // 'line', 'bar'
  export let titulo = 'Evolução Temporal';
  export let altura = 400;
  export let periodo = 'mes'; // 'dia', 'semana', 'mes', 'ano'
  
  let canvas;
  let chartInstance;
  
  // Registrar todos os componentes do Chart.js
  Chart.register(...registerables);
  
  // Preparar dados para o gráfico
  $: chartData = prepararDados();
  
  function prepararDados() {
    if (!dados || dados.length === 0) {
      return {
        labels: [],
        datasets: []
      };
    }
    
    // Agrupar dados por período
    const agrupados = {};
    
    dados.forEach(item => {
      const data = new Date(item.criado_em || item.data_cadastro);
      let chave = '';
      
      switch (periodo) {
        case 'dia':
          chave = data.toISOString().split('T')[0];
          break;
        case 'semana':
          const inicioSemana = new Date(data);
          inicioSemana.setDate(data.getDate() - data.getDay());
          chave = inicioSemana.toISOString().split('T')[0];
          break;
        case 'mes':
          chave = `${data.getFullYear()}-${String(data.getMonth() + 1).padStart(2, '0')}`;
          break;
        case 'ano':
          chave = data.getFullYear().toString();
          break;
      }
      
      if (!agrupados[chave]) {
        agrupados[chave] = {
          total: 0,
          aprovados: 0,
          preAprovados: 0,
          pendentes: 0,
          avaliacoes: 0,
          mediaNota: 0,
          somaNota: 0,
          countNota: 0
        };
      }
      
      agrupados[chave].total++;
      
      if (item.aprovado === 'aprovado') {
        agrupados[chave].aprovados++;
      } else if (item.aprovado === 'pre_aprovado') {
        agrupados[chave].preAprovados++;
      } else {
        agrupados[chave].pendentes++;
      }
      
      // Para avaliações
      if (item.nota) {
        agrupados[chave].avaliacoes++;
        agrupados[chave].somaNota += item.nota;
        agrupados[chave].countNota++;
        agrupados[chave].mediaNota = agrupados[chave].somaNota / agrupados[chave].countNota;
      }
    });
    
    // Ordenar por data
    const labels = Object.keys(agrupados).sort();
    const totalData = labels.map(chave => agrupados[chave].total);
    const aprovadosData = labels.map(chave => agrupados[chave].aprovados);
    const preAprovadosData = labels.map(chave => agrupados[chave].preAprovados);
    const pendentesData = labels.map(chave => agrupados[chave].pendentes);
    const avaliacoesData = labels.map(chave => agrupados[chave].avaliacoes);
    const mediaNotaData = labels.map(chave => agrupados[chave].mediaNota);
    
    // Formatar labels
    const labelsFormatados = labels.map(chave => {
      const data = new Date(chave);
      switch (periodo) {
        case 'dia':
          return data.toLocaleDateString('pt-BR', { day: '2-digit', month: '2-digit' });
        case 'semana':
          return `Sem ${data.getDate()}`;
        case 'mes':
          return data.toLocaleDateString('pt-BR', { month: 'short', year: 'numeric' });
        case 'ano':
          return chave;
        default:
          return chave;
      }
    });
    
    return {
      labels: labelsFormatados,
      datasets: [
        {
          label: 'Total de Jovens',
          data: totalData,
          borderColor: 'rgba(59, 130, 246, 1)',
          backgroundColor: 'rgba(59, 130, 246, 0.1)',
          borderWidth: 2,
          fill: tipo === 'line',
          tension: 0.4
        },
        {
          label: 'Aprovados',
          data: aprovadosData,
          borderColor: 'rgba(34, 197, 94, 1)',
          backgroundColor: 'rgba(34, 197, 94, 0.1)',
          borderWidth: 2,
          fill: false,
          tension: 0.4
        },
        {
          label: 'Pré-aprovados',
          data: preAprovadosData,
          borderColor: 'rgba(245, 158, 11, 1)',
          backgroundColor: 'rgba(245, 158, 11, 0.1)',
          borderWidth: 2,
          fill: false,
          tension: 0.4
        },
        {
          label: 'Pendentes',
          data: pendentesData,
          borderColor: 'rgba(156, 163, 175, 1)',
          backgroundColor: 'rgba(156, 163, 175, 0.1)',
          borderWidth: 2,
          fill: false,
          tension: 0.4
        },
        {
          label: 'Avaliações',
          data: avaliacoesData,
          borderColor: 'rgba(168, 85, 247, 1)',
          backgroundColor: 'rgba(168, 85, 247, 0.1)',
          borderWidth: 2,
          fill: false,
          tension: 0.4
        },
        {
          label: 'Média de Notas',
          data: mediaNotaData,
          borderColor: 'rgba(236, 72, 153, 1)',
          backgroundColor: 'rgba(236, 72, 153, 0.1)',
          borderWidth: 2,
          fill: false,
          tension: 0.4,
          yAxisID: 'y1'
        }
      ]
    };
  }
  
  const options = {
    responsive: true,
    maintainAspectRatio: false,
    plugins: {
      title: {
        display: true,
        text: titulo,
        font: {
          size: 16,
          weight: 'bold'
        }
      },
      legend: {
        position: 'bottom',
        labels: {
          padding: 20,
          usePointStyle: true
        }
      }
    },
    scales: {
      y: {
        type: 'linear',
        display: true,
        position: 'left',
        beginAtZero: true,
        ticks: {
          stepSize: 1
        }
      },
      y1: {
        type: 'linear',
        display: true,
        position: 'right',
        beginAtZero: true,
        max: 10,
        grid: {
          drawOnChartArea: false,
        },
        ticks: {
          stepSize: 1
        }
      }
    }
  };
</script>

<div class="w-full max-w-full overflow-x-auto">
  <div class="min-w-[360px]" style="height: {altura}px;">
    {#if chartData.labels.length > 0}
      <SvelteChart
        {chartData}
        {options}
        type={tipo}
      />
    {:else}
      <div class="flex items-center justify-center h-full bg-gray-50 rounded-lg">
        <div class="text-center">
          <svg class="w-12 h-12 text-gray-400 mx-auto mb-2" fill="none" viewBox="0 0 24 24" stroke="currentColor">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 19v-6a2 2 0 00-2-2H5a2 2 0 00-2 2v6a2 2 0 002 2h2a2 2 0 002-2zm0 0V9a2 2 0 012-2h2a2 2 0 012 2v10m-6 0a2 2 0 002 2h2a2 2 0 002-2m0 0V5a2 2 0 012-2h2a2 2 0 012 2v14a2 2 0 01-2 2h-2a2 2 0 01-2-2z" />
          </svg>
          <p class="text-gray-500 text-sm">Nenhum dado disponível para o gráfico</p>
        </div>
      </div>
    {/if}
  </div>
</div>
