<script>
  import { onMount } from 'svelte';
  import { Chart, registerables } from 'chart.js';
  import { Chart as SvelteChart } from 'svelte-chartjs';
  
  export let dados = [];
  export let tipo = 'bar'; // 'bar', 'line', 'doughnut', 'pie'
  export let titulo = 'Gráfico de Avaliações';
  export let altura = 400;
  
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
    
    // Agrupar dados por categoria
    const categorias = {
      espirito: {},
      caractere: {},
      disposicao: {},
      notas: { '1-3': 0, '4-6': 0, '7-8': 0, '9-10': 0 }
    };
    
    dados.forEach(avaliacao => {
      // Contar avaliações por categoria
      if (avaliacao.espirito) {
        categorias.espirito[avaliacao.espirito] = (categorias.espirito[avaliacao.espirito] || 0) + 1;
      }
      if (avaliacao.caractere) {
        categorias.caractere[avaliacao.caractere] = (categorias.caractere[avaliacao.caractere] || 0) + 1;
      }
      if (avaliacao.disposicao) {
        categorias.disposicao[avaliacao.disposicao] = (categorias.disposicao[avaliacao.disposicao] || 0) + 1;
      }
      
      // Contar notas por faixa
      if (avaliacao.nota) {
        if (avaliacao.nota >= 1 && avaliacao.nota <= 3) {
          categorias.notas['1-3']++;
        } else if (avaliacao.nota >= 4 && avaliacao.nota <= 6) {
          categorias.notas['4-6']++;
        } else if (avaliacao.nota >= 7 && avaliacao.nota <= 8) {
          categorias.notas['7-8']++;
        } else if (avaliacao.nota >= 9 && avaliacao.nota <= 10) {
          categorias.notas['9-10']++;
        }
      }
    });
    
    // Preparar dados para gráfico de barras
    if (tipo === 'bar') {
      return {
        labels: ['Espírito', 'Caráter', 'Disposição', 'Notas'],
        datasets: [
          {
            label: 'Excelente',
            data: [
              categorias.espirito.excelente || 0,
              categorias.caractere.excelente || 0,
              categorias.disposicao.muito_disposto || 0,
              categorias.notas['9-10']
            ],
            backgroundColor: 'rgba(34, 197, 94, 0.8)',
            borderColor: 'rgba(34, 197, 94, 1)',
            borderWidth: 1
          },
          {
            label: 'Bom',
            data: [
              categorias.espirito.bom || 0,
              categorias.caractere.bom || 0,
              categorias.disposicao.normal || 0,
              categorias.notas['7-8']
            ],
            backgroundColor: 'rgba(59, 130, 246, 0.8)',
            borderColor: 'rgba(59, 130, 246, 1)',
            borderWidth: 1
          },
          {
            label: 'Observar',
            data: [
              categorias.espirito.ser_observar || 0,
              categorias.caractere.ser_observar || 0,
              categorias.disposicao.pacato || 0,
              categorias.notas['4-6']
            ],
            backgroundColor: 'rgba(245, 158, 11, 0.8)',
            borderColor: 'rgba(245, 158, 11, 1)',
            borderWidth: 1
          },
          {
            label: 'Ruim',
            data: [
              categorias.espirito.ruim || 0,
              categorias.caractere.ruim || 0,
              categorias.disposicao.desanimado || 0,
              categorias.notas['1-3']
            ],
            backgroundColor: 'rgba(239, 68, 68, 0.8)',
            borderColor: 'rgba(239, 68, 68, 1)',
            borderWidth: 1
          }
        ]
      };
    }
    
    // Preparar dados para gráfico de pizza
    if (tipo === 'pie' || tipo === 'doughnut') {
      const labels = [];
      const data = [];
      const colors = [];
      
      // Adicionar dados de espírito
      Object.entries(categorias.espirito).forEach(([key, value]) => {
        if (value > 0) {
          labels.push(`Espírito: ${key}`);
          data.push(value);
          colors.push(getCorPorCategoria('espirito', key));
        }
      });
      
      // Adicionar dados de caráter
      Object.entries(categorias.caractere).forEach(([key, value]) => {
        if (value > 0) {
          labels.push(`Caráter: ${key}`);
          data.push(value);
          colors.push(getCorPorCategoria('caractere', key));
        }
      });
      
      // Adicionar dados de disposição
      Object.entries(categorias.disposicao).forEach(([key, value]) => {
        if (value > 0) {
          labels.push(`Disposição: ${key}`);
          data.push(value);
          colors.push(getCorPorCategoria('disposicao', key));
        }
      });
      
      return {
        labels,
        datasets: [{
          data,
          backgroundColor: colors,
          borderColor: colors.map(cor => cor.replace('0.8', '1')),
          borderWidth: 2
        }]
      };
    }
    
    return {
      labels: [],
      datasets: []
    };
  }
  
  function getCorPorCategoria(categoria, valor) {
    const cores = {
      espirito: {
        'excelente': 'rgba(34, 197, 94, 0.8)',
        'bom': 'rgba(59, 130, 246, 0.8)',
        'ser_observar': 'rgba(245, 158, 11, 0.8)',
        'ruim': 'rgba(239, 68, 68, 0.8)'
      },
      caractere: {
        'excelente': 'rgba(34, 197, 94, 0.8)',
        'bom': 'rgba(59, 130, 246, 0.8)',
        'ser_observar': 'rgba(245, 158, 11, 0.8)',
        'ruim': 'rgba(239, 68, 68, 0.8)'
      },
      disposicao: {
        'muito_disposto': 'rgba(34, 197, 94, 0.8)',
        'normal': 'rgba(59, 130, 246, 0.8)',
        'pacato': 'rgba(245, 158, 11, 0.8)',
        'desanimado': 'rgba(239, 68, 68, 0.8)'
      }
    };
    
    return cores[categoria]?.[valor] || 'rgba(156, 163, 175, 0.8)';
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
    scales: tipo === 'bar' ? {
      y: {
        beginAtZero: true,
        ticks: {
          stepSize: 1
        }
      }
    } : {}
  };
</script>

<div class="w-full" style="height: {altura}px;">
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
