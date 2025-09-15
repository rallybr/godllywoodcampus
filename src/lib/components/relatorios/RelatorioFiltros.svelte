<script>
  import { onMount } from 'svelte';
  import { loadInitialData, estados, blocos, regioes, igrejas, edicoes, loadBlocos, loadRegioes, loadIgrejas, clearHierarchy } from '$lib/stores/geographic';
  import { loadUsuarios } from '$lib/stores/usuarios';
  import Input from '$lib/components/ui/Input.svelte';
  import Select from '$lib/components/ui/Select.svelte';
  import Button from '$lib/components/ui/Button.svelte';
  import Card from '$lib/components/ui/Card.svelte';
  
  export let filtros = {};
  export let onFiltrosChange = () => {};
  export let onGerarRelatorio = () => {};
  export let onExportar = () => {};
  export let loading = false;
  export let tipoRelatorio = 'jovens'; // 'jovens', 'avaliacoes', 'estatisticas'
  
  let localFiltros = {
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
  
  onMount(async () => {
    await loadInitialData();
    await loadUsuarios();
  });
  
  // Função para lidar com mudança de estado
  async function handleEstadoChange(event) {
    const estadoId = event.target.value;
    localFiltros.estado_id = estadoId;
    localFiltros.bloco_id = '';
    localFiltros.regiao_id = '';
    localFiltros.igreja_id = '';
    clearHierarchy();
    
    if (estadoId) {
      await loadBlocos(estadoId);
    }
    
    onFiltrosChange(localFiltros);
  }
  
  // Função para lidar com mudança de bloco
  async function handleBlocoChange(event) {
    const blocoId = event.target.value;
    localFiltros.bloco_id = blocoId;
    localFiltros.regiao_id = '';
    localFiltros.igreja_id = '';
    regioes.set([]);
    igrejas.set([]);
    
    if (blocoId) {
      await loadRegioes(blocoId);
    }
    
    onFiltrosChange(localFiltros);
  }
  
  // Função para lidar com mudança de região
  async function handleRegiaoChange(event) {
    const regiaoId = event.target.value;
    localFiltros.regiao_id = regiaoId;
    localFiltros.igreja_id = '';
    igrejas.set([]);
    
    if (regiaoId) {
      await loadIgrejas(regiaoId);
    }
    
    onFiltrosChange(localFiltros);
  }
  
  // Função para lidar com mudança de igreja
  function handleIgrejaChange(event) {
    localFiltros.igreja_id = event.target.value;
    onFiltrosChange(localFiltros);
  }
  
  // Função para lidar com mudança de edição
  function handleEdicaoChange(event) {
    localFiltros.edicao_id = event.target.value;
    onFiltrosChange(localFiltros);
  }
  
  // Função para lidar com mudança de outros filtros
  function handleFiltroChange(campo, valor) {
    localFiltros[campo] = valor;
    onFiltrosChange(localFiltros);
  }
  
  // Função para limpar filtros
  function limparFiltros() {
    localFiltros = {
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
    clearHierarchy();
    onFiltrosChange(localFiltros);
  }
  
  // Função para gerar relatório
  function handleGerarRelatorio() {
    onGerarRelatorio(localFiltros);
  }
  
  // Função para exportar
  function handleExportar() {
    onExportar(localFiltros);
  }
</script>

<Card class="p-6">
  <div class="flex items-center justify-between mb-6">
    <h3 class="text-lg font-semibold text-gray-900">Filtros do Relatório</h3>
    <div class="flex space-x-2">
      <Button variant="outline" size="sm" on:click={limparFiltros}>
        <svg class="w-4 h-4 mr-1" fill="none" viewBox="0 0 24 24" stroke="currentColor">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 4v5h.582m15.356 2A8.001 8.001 0 004.582 9m0 0H9m11 11v-5h-.581m0 0a8.003 8.003 0 01-15.357-2m15.357 2H15" />
        </svg>
        Limpar
      </Button>
    </div>
  </div>
  
  <div class="space-y-6">
    <!-- Localização -->
    <div class="space-y-4">
      <h4 class="text-sm font-medium text-gray-700">Localização</h4>
      <div class="grid grid-cols-1 md:grid-cols-4 gap-4">
        <Select
          label="Estado"
          bind:value={localFiltros.estado_id}
          on:change={handleEstadoChange}
          options={[
            { value: '', label: 'Todos os estados' },
            ...$estados.map(estado => ({
              value: estado.id,
              label: estado.nome
            }))
          ]}
        />
        
        <Select
          label="Bloco"
          bind:value={localFiltros.bloco_id}
          on:change={handleBlocoChange}
          disabled={!localFiltros.estado_id}
          options={[
            { value: '', label: 'Todos os blocos' },
            ...$blocos.map(bloco => ({
              value: bloco.id,
              label: bloco.nome
            }))
          ]}
        />
        
        <Select
          label="Região"
          bind:value={localFiltros.regiao_id}
          on:change={handleRegiaoChange}
          disabled={!localFiltros.bloco_id}
          options={[
            { value: '', label: 'Todas as regiões' },
            ...$regioes.map(regiao => ({
              value: regiao.id,
              label: regiao.nome
            }))
          ]}
        />
        
        <Select
          label="Igreja"
          bind:value={localFiltros.igreja_id}
          on:change={handleIgrejaChange}
          disabled={!localFiltros.regiao_id}
          options={[
            { value: '', label: 'Todas as igrejas' },
            ...$igrejas.map(igreja => ({
              value: igreja.id,
              label: igreja.nome
            }))
          ]}
        />
      </div>
    </div>
    
    <!-- Filtros específicos por tipo de relatório -->
    {#if tipoRelatorio === 'jovens'}
      <div class="space-y-4">
        <h4 class="text-sm font-medium text-gray-700">Filtros de Jovens</h4>
        <div class="grid grid-cols-1 md:grid-cols-3 gap-4">
          <Select
            label="Edição"
            bind:value={localFiltros.edicao_id}
            on:change={handleEdicaoChange}
            options={[
              { value: '', label: 'Todas as edições' },
              ...$edicoes.map(edicao => ({
                value: edicao.id,
                label: edicao.nome
              }))
            ]}
          />
          
          <Select
            label="Status de Aprovação"
            bind:value={localFiltros.aprovado}
            on:change={(e) => handleFiltroChange('aprovado', e.target.value)}
            options={[
              { value: '', label: 'Todos os status' },
              { value: 'true', label: 'Aprovado' },
              { value: 'pre_aprovado', label: 'Pré-aprovado' },
              { value: 'null', label: 'Pendente' }
            ]}
          />
          
          <Select
            label="Sexo"
            bind:value={localFiltros.sexo}
            on:change={(e) => handleFiltroChange('sexo', e.target.value)}
            options={[
              { value: '', label: 'Todos os sexos' },
              { value: 'masculino', label: 'Masculino' },
              { value: 'feminino', label: 'Feminino' }
            ]}
          />
        </div>
        
        <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
          <Input
            label="Idade Mínima"
            type="number"
            bind:value={localFiltros.idade_min}
            on:input={(e) => handleFiltroChange('idade_min', e.target.value)}
            placeholder="Ex: 18"
          />
          
          <Input
            label="Idade Máxima"
            type="number"
            bind:value={localFiltros.idade_max}
            on:input={(e) => handleFiltroChange('idade_max', e.target.value)}
            placeholder="Ex: 35"
          />
        </div>
      </div>
    {/if}
    
    {#if tipoRelatorio === 'avaliacoes'}
      <div class="space-y-4">
        <h4 class="text-sm font-medium text-gray-700">Filtros de Avaliações</h4>
        <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
          <Select
            label="Avaliador"
            bind:value={localFiltros.avaliador_id}
            on:change={(e) => handleFiltroChange('avaliador_id', e.target.value)}
            options={[
              { value: '', label: 'Todos os avaliadores' },
              ...$usuarios.map(usuario => ({
                value: usuario.id,
                label: usuario.nome
              }))
            ]}
          />
          
          <Select
            label="Edição"
            bind:value={localFiltros.edicao_id}
            on:change={handleEdicaoChange}
            options={[
              { value: '', label: 'Todas as edições' },
              ...$edicoes.map(edicao => ({
                value: edicao.id,
                label: edicao.nome
              }))
            ]}
          />
        </div>
        
        <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
          <Input
            label="Nota Mínima"
            type="number"
            bind:value={localFiltros.nota_min}
            on:input={(e) => handleFiltroChange('nota_min', e.target.value)}
            placeholder="Ex: 7"
            min="1"
            max="10"
          />
          
          <Input
            label="Nota Máxima"
            type="number"
            bind:value={localFiltros.nota_max}
            on:input={(e) => handleFiltroChange('nota_max', e.target.value)}
            placeholder="Ex: 10"
            min="1"
            max="10"
          />
        </div>
      </div>
    {/if}
    
    <!-- Período -->
    <div class="space-y-4">
      <h4 class="text-sm font-medium text-gray-700">Período</h4>
      <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
        <Input
          label="Data Início"
          type="date"
          bind:value={localFiltros.data_inicio}
          on:input={(e) => handleFiltroChange('data_inicio', e.target.value)}
        />
        
        <Input
          label="Data Fim"
          type="date"
          bind:value={localFiltros.data_fim}
          on:input={(e) => handleFiltroChange('data_fim', e.target.value)}
        />
      </div>
    </div>
    
    <!-- Ações -->
    <div class="flex justify-end space-x-3 pt-4 border-t border-gray-200">
      <Button
        variant="outline"
        on:click={handleGerarRelatorio}
        loading={loading}
        disabled={loading}
      >
        <svg class="w-4 h-4 mr-2" fill="none" viewBox="0 0 24 24" stroke="currentColor">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 19v-6a2 2 0 00-2-2H5a2 2 0 00-2 2v6a2 2 0 002 2h2a2 2 0 002-2zm0 0V9a2 2 0 012-2h2a2 2 0 012 2v10m-6 0a2 2 0 002 2h2a2 2 0 002-2m0 0V5a2 2 0 012-2h2a2 2 0 012 2v14a2 2 0 01-2 2h-2a2 2 0 01-2-2z" />
        </svg>
        Gerar Relatório
      </Button>
      
      <Button
        variant="primary"
        on:click={handleExportar}
        loading={loading}
        disabled={loading}
      >
        <svg class="w-4 h-4 mr-2" fill="none" viewBox="0 0 24 24" stroke="currentColor">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 10v6m0 0l-3-3m3 3l3-3m2 8H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z" />
        </svg>
        Exportar
      </Button>
    </div>
  </div>
</Card>
