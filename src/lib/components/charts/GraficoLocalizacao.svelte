<script>
  // @ts-nocheck
  import { onMount } from 'svelte';
  import { Chart, registerables } from 'chart.js';
  import { Chart as SvelteChart } from 'svelte-chartjs';
  import { userProfile } from '$lib/stores/auth';
  import { getUserLevelName } from '$lib/stores/niveis-acesso';
  
  export let dados = [];
  export let tipo = 'bar'; // 'bar', 'line', 'doughnut', 'pie'
  export let titulo = 'Distribuição por Localização';
  export let altura = 400;
  export let nivel = 'estado'; // 'estado', 'bloco', 'regiao', 'igreja'
  
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
    
    // Agrupar dados por nível de localização
    const agrupados = {};
    
    dados.forEach(item => {
      let chave = '';
      let label = '';
      
      switch (nivel) {
        case 'estado':
          chave = item.estado || 'N/A';
          label = item.estado || 'N/A';
          break;
        case 'bloco':
          chave = item.bloco || 'N/A';
          label = item.bloco || 'N/A';
          break;
        case 'regiao':
          chave = item.regiao || 'N/A';
          label = item.regiao || 'N/A';
          break;
        case 'igreja':
          chave = item.igreja || 'N/A';
          label = item.igreja || 'N/A';
          break;
      }
      
      if (!agrupados[chave]) {
        agrupados[chave] = {
          total: 0,
          aprovados: 0,
          preAprovados: 0,
          pendentes: 0
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
    });
    
    // Converter para arrays
    const labels = Object.keys(agrupados);
    const totalData = labels.map(chave => agrupados[chave].total);
    const aprovadosData = labels.map(chave => agrupados[chave].aprovados);
    const preAprovadosData = labels.map(chave => agrupados[chave].preAprovados);
    const pendentesData = labels.map(chave => agrupados[chave].pendentes);
    
    if (tipo === 'bar') {
      return {
        labels,
        datasets: [
          {
            label: 'Total',
            data: totalData,
            backgroundColor: 'rgba(59, 130, 246, 0.8)',
            borderColor: 'rgba(59, 130, 246, 1)',
            borderWidth: 1
          },
          {
            label: 'Aprovados',
            data: aprovadosData,
            backgroundColor: 'rgba(34, 197, 94, 0.8)',
            borderColor: 'rgba(34, 197, 94, 1)',
            borderWidth: 1
          },
          {
            label: 'Pré-aprovados',
            data: preAprovadosData,
            backgroundColor: 'rgba(245, 158, 11, 0.8)',
            borderColor: 'rgba(245, 158, 11, 1)',
            borderWidth: 1
          },
          {
            label: 'Pendentes',
            data: pendentesData,
            backgroundColor: 'rgba(156, 163, 175, 0.8)',
            borderColor: 'rgba(156, 163, 175, 1)',
            borderWidth: 1
          }
        ]
      };
    }
    
    if (tipo === 'pie' || tipo === 'doughnut') {
      return {
        labels,
        datasets: [{
          data: totalData,
          backgroundColor: [
            'rgba(59, 130, 246, 0.8)',
            'rgba(34, 197, 94, 0.8)',
            'rgba(245, 158, 11, 0.8)',
            'rgba(156, 163, 175, 0.8)',
            'rgba(168, 85, 247, 0.8)',
            'rgba(236, 72, 153, 0.8)',
            'rgba(14, 165, 233, 0.8)',
            'rgba(34, 197, 94, 0.8)',
            'rgba(245, 158, 11, 0.8)',
            'rgba(239, 68, 68, 0.8)'
          ],
          borderColor: [
            'rgba(59, 130, 246, 1)',
            'rgba(34, 197, 94, 1)',
            'rgba(245, 158, 11, 1)',
            'rgba(156, 163, 175, 1)',
            'rgba(168, 85, 247, 1)',
            'rgba(236, 72, 153, 1)',
            'rgba(14, 165, 233, 1)',
            'rgba(34, 197, 94, 1)',
            'rgba(245, 158, 11, 1)',
            'rgba(239, 68, 68, 1)'
          ],
          borderWidth: 2
        }]
      };
    }
    
    return {
      labels: [],
      datasets: []
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

<!-- Gráfico de Localização (não mostrar para jovens) -->
{#if getUserLevelName($userProfile) !== 'Jovem'}
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
{/if}
