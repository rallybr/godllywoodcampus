<script>
  // @ts-nocheck
  import { onMount } from 'svelte';
  import { loadInitialData, estados, blocos, loadBlocos, clearHierarchy } from '$lib/stores/geographic';
  import { supabase } from '$lib/utils/supabase';
  import Button from '$lib/components/ui/Button.svelte';
  import Input from '$lib/components/ui/Input.svelte';
  import Select from '$lib/components/ui/Select.svelte';
  import Card from '$lib/components/ui/Card.svelte';

  // Estados do formulário
  let isLoading = false;
  let error = '';
  let success = false;
  
  // Dados do formulário
  let formData = {
    estado_id: '',
    bloco_id: '',
    nome: ''
  };

  // Estados reativos para os selects
  let estadosOptions = [];
  let blocosOptions = [];

  // Carregar dados iniciais
  onMount(async () => {
    await loadInitialData();
    
    // Converter estados para formato do select
    estados.subscribe(estadosData => {
      estadosOptions = estadosData.map(estado => ({
        value: estado.id,
        label: `${estado.nome} (${estado.sigla})`
      }));
    });

    // Converter blocos para formato do select
    blocos.subscribe(blocosData => {
      blocosOptions = blocosData.map(bloco => ({
        value: bloco.id,
        label: bloco.nome
      }));
    });
  });

  // Função para lidar com mudança de estado
  async function handleEstadoChange(event) {
    const estadoId = event.detail.value;
    formData.estado_id = estadoId;
    formData.bloco_id = ''; // Limpar bloco selecionado
    
    if (estadoId) {
      await loadBlocos(estadoId);
    } else {
      clearHierarchy();
    }
  }

  // Função para lidar com mudança de bloco
  function handleBlocoChange(event) {
    formData.bloco_id = event.detail.value;
  }

  // Função para validar formulário
  function validateForm() {
    if (!formData.estado_id) {
      error = 'Por favor, selecione um estado';
      return false;
    }
    if (!formData.bloco_id) {
      error = 'Por favor, selecione um bloco';
      return false;
    }
    if (!formData.nome.trim()) {
      error = 'Por favor, informe o nome da região';
      return false;
    }
    return true;
  }

  // Função para salvar região
  async function handleSubmit() {
    if (!validateForm()) return;

    isLoading = true;
    error = '';
    success = false;

    try {
      const { data, error: insertError } = await supabase
        .from('regioes')
        .insert([{
          bloco_id: formData.bloco_id,
          nome: formData.nome.trim()
        }])
        .select()
        .single();

      if (insertError) {
        throw insertError;
      }

      success = true;
      
      // Limpar formulário
      formData = {
        estado_id: '',
        bloco_id: '',
        nome: ''
      };
      
      // Limpar selects
      clearHierarchy();

      // Mostrar sucesso por 3 segundos
      setTimeout(() => {
        success = false;
      }, 3000);

    } catch (err) {
      console.error('Erro ao salvar região:', err);
      error = err.message || 'Erro ao salvar região';
    } finally {
      isLoading = false;
    }
  }

  // Função para limpar formulário
  function handleClear() {
    formData = {
      estado_id: '',
      bloco_id: '',
      nome: ''
    };
    clearHierarchy();
    error = '';
    success = false;
  }
</script>

<div class="max-w-2xl mx-auto p-6">
  <Card>
    <div class="p-6">
      <div class="mb-6">
        <h1 class="text-2xl font-bold text-gray-900 mb-2">Cadastrar Região</h1>
        <p class="text-gray-600">Preencha os dados para cadastrar uma nova região</p>
      </div>

      {#if success}
        <div class="mb-6 p-4 bg-green-50 border border-green-200 rounded-md">
          <div class="flex">
            <div class="flex-shrink-0">
              <svg class="h-5 w-5 text-green-400" viewBox="0 0 20 20" fill="currentColor">
                <path fill-rule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zm3.707-9.293a1 1 0 00-1.414-1.414L9 10.586 7.707 9.293a1 1 0 00-1.414 1.414l2 2a1 1 0 001.414 0l4-4z" clip-rule="evenodd" />
              </svg>
            </div>
            <div class="ml-3">
              <p class="text-sm font-medium text-green-800">
                Região cadastrada com sucesso!
              </p>
            </div>
          </div>
        </div>
      {/if}

      {#if error}
        <div class="mb-6 p-4 bg-red-50 border border-red-200 rounded-md">
          <div class="flex">
            <div class="flex-shrink-0">
              <svg class="h-5 w-5 text-red-400" viewBox="0 0 20 20" fill="currentColor">
                <path fill-rule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zM8.707 7.293a1 1 0 00-1.414 1.414L8.586 10l-1.293 1.293a1 1 0 101.414 1.414L10 11.414l1.293 1.293a1 1 0 001.414-1.414L11.414 10l1.293-1.293a1 1 0 00-1.414-1.414L10 8.586 8.707 7.293z" clip-rule="evenodd" />
              </svg>
            </div>
            <div class="ml-3">
              <p class="text-sm font-medium text-red-800">
                {error}
              </p>
            </div>
          </div>
        </div>
      {/if}

      <form on:submit|preventDefault={handleSubmit} class="space-y-6">
        <!-- Select de Estados -->
        <div>
          <Select
            label="Estado"
            placeholder="Selecione um estado"
            options={estadosOptions}
            value={formData.estado_id}
            required={true}
            on:change={handleEstadoChange}
          />
        </div>

        <!-- Select de Blocos -->
        <div>
          <Select
            label="Bloco"
            placeholder="Selecione um bloco"
            options={blocosOptions}
            value={formData.bloco_id}
            required={true}
            disabled={!formData.estado_id}
            on:change={handleBlocoChange}
          />
        </div>

        <!-- Campo de Nome da Região -->
        <div>
          <Input
            label="Nome da Região"
            type="text"
            bind:value={formData.nome}
            placeholder="Digite o nome da região"
            required={true}
            disabled={isLoading}
          />
        </div>

        <!-- Botões -->
        <div class="flex gap-4 pt-4">
          <Button
            type="submit"
            variant="primary"
            disabled={isLoading}
            class="flex-1"
          >
            {#if isLoading}
              <svg class="animate-spin -ml-1 mr-3 h-5 w-5 text-white" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24">
                <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle>
                <path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
              </svg>
              Salvando...
            {:else}
              Salvar Região
            {/if}
          </Button>
          
          <Button
            type="button"
            variant="secondary"
            on:click={handleClear}
            disabled={isLoading}
          >
            Limpar
          </Button>
        </div>
      </form>
    </div>
  </Card>
</div>
