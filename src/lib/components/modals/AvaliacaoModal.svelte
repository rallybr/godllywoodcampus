<script>
  import { createEventDispatcher, onMount } from 'svelte';
  import { createAvaliacao, updateAvaliacao } from '$lib/stores/avaliacoes';
  import { supabase } from '$lib/utils/supabase';
  import Button from '$lib/components/ui/Button.svelte';
  import Input from '$lib/components/ui/Input.svelte';
  import Select from '$lib/components/ui/Select.svelte';
  import RichTextEditor from '$lib/components/ui/RichTextEditor.svelte';
  
  const dispatch = createEventDispatcher();
  
  export let isOpen = false;
  export let jovemId = '';
  export let jovemNome = '';
  export let avaliacaoParaEditar = null;
  
  let isLoading = false;
  let error = '';
  let userId = '';
  
  // Verificar se é modo de edição
  $: isEditMode = avaliacaoParaEditar !== null;
  
  // Dados do formulário
  let formData = {
    espirito: '',
    caractere: '',
    disposicao: '',
    avaliacao_texto: '',
    nota: '',
    data: new Date().toISOString().split('T')[0] // Data atual no formato YYYY-MM-DD
  };
  
  // Opções dos selects
  const opcoesEspirito = [
    { value: 'ruim', label: 'Ruim' },
    { value: 'ser_observar', label: 'Ser Observada' },
    { value: 'bom', label: 'Bom' },
    { value: 'excelente', label: 'Excelente' }
  ];
  
  const opcoesCaractere = [
    { value: 'excelente', label: 'Excelente' },
    { value: 'bom', label: 'Bom' },
    { value: 'ser_observar', label: 'Ser Observada' },
    { value: 'ruim', label: 'Ruim' }
  ];
  
  const opcoesDisposicao = [
    { value: 'muito_disposto', label: 'Disposta' },
    { value: 'normal', label: 'Normal' },
    { value: 'pacato', label: 'Pacata' },
    { value: 'desanimado', label: 'Desanimada' }
  ];
  
  // Validação
  let validationErrors = {};
  
  // Obter user_id quando o modal abrir
  onMount(async () => {
    await getCurrentUserId();
  });
  
  async function getCurrentUserId() {
    try {
      console.log('🔍 Iniciando busca do user_id...');
      
      const { data: { user }, error: authError } = await supabase.auth.getUser();
      console.log('🔍 Auth result:', { user, authError });
      
      if (authError) {
        console.error('❌ Erro na autenticação:', authError);
        error = 'Erro na autenticação: ' + authError.message;
        return;
      }
      
      if (user) {
        console.log('✅ Usuário autenticado:', user.id);
        console.log('🔍 Buscando usuário na tabela usuarios com id_auth:', user.id);
        
        // Buscar diretamente na tabela usuarios
        const { data: usuarioData, error: usuarioError } = await supabase
          .from('usuarios')
          .select('id, nome, id_auth')
          .eq('id_auth', user.id)
          .single();
        
        console.log('🔍 Resultado da busca:', { usuarioData, usuarioError });
        
        if (usuarioError) {
          console.error('❌ Erro ao buscar usuário:', usuarioError);
          console.error('❌ Detalhes do erro:', JSON.stringify(usuarioError, null, 2));
          error = 'Erro ao buscar dados do usuário: ' + usuarioError.message;
          return;
        }
        
        if (usuarioData) {
          userId = usuarioData.id;
          console.log('✅ User ID obtido (auth.uid):', user.id);
          console.log('✅ User ID mapeado (usuarios.id):', userId);
          console.log('✅ Nome do usuário:', usuarioData.nome);
        } else {
          console.error('❌ Usuário não encontrado na tabela usuarios');
          error = 'Usuário não encontrado no sistema';
        }
      } else {
        console.error('❌ Usuário não autenticado');
        error = 'Usuário não autenticado';
      }
    } catch (err) {
      console.error('❌ Erro geral ao obter user ID:', err);
      error = 'Erro ao obter dados do usuário: ' + err.message;
    }
  }
  
  // Função para preencher formulário quando estiver em modo de edição
  function fillFormData() {
    if (isEditMode && avaliacaoParaEditar) {
      console.log('🔄 Preenchendo formulário com dados da avaliação:', avaliacaoParaEditar);
      formData = {
        espirito: avaliacaoParaEditar.espirito || '',
        caractere: avaliacaoParaEditar.caractere || '',
        disposicao: avaliacaoParaEditar.disposicao || '',
        avaliacao_texto: avaliacaoParaEditar.avaliacao_texto || '',
        nota: avaliacaoParaEditar.nota?.toString() || '',
        data: avaliacaoParaEditar.criado_em ? new Date(avaliacaoParaEditar.criado_em).toISOString().split('T')[0] : new Date().toISOString().split('T')[0]
      };
      console.log('✅ Formulário preenchido:', formData);
    }
  }
  
  // Preencher formulário quando o modal abrir em modo de edição
  $: if (isOpen && isEditMode && avaliacaoParaEditar) {
    fillFormData();
  }
  
  function validateForm() {
    validationErrors = {};
    
    if (!formData.espirito) validationErrors.espirito = 'Espírito é obrigatório';
    if (!formData.caractere) validationErrors.caractere = 'Caráter é obrigatório';
    if (!formData.disposicao) validationErrors.disposicao = 'Disposição é obrigatória';
    if (!formData.data) validationErrors.data = 'Data é obrigatória';
    if (formData.nota && (formData.nota < 0 || formData.nota > 10)) {
      validationErrors.nota = 'Nota deve estar entre 0 e 10';
    }
    
    return Object.keys(validationErrors).length === 0;
  }
  
  async function handleSubmit() {
    if (!validateForm()) return;
    
    // Verificar se temos o user_id
    if (!userId) {
      await getCurrentUserId();
      if (!userId) {
        error = 'Erro ao obter dados do usuário. Tente novamente.';
        return;
      }
    }
    
    isLoading = true;
    error = '';
    
    try {
      const avaliacaoData = {
        jovem_id: jovemId,
        user_id: userId,
        espirito: formData.espirito,
        caractere: formData.caractere,
        disposicao: formData.disposicao,
        avaliacao_texto: formData.avaliacao_texto || null,
        nota: formData.nota ? parseFloat(formData.nota) : null,
        data: formData.data
      };
      
      let result;
      
      if (isEditMode) {
        console.log('Atualizando avaliação:', avaliacaoData);
        result = await updateAvaliacao(avaliacaoParaEditar.id, avaliacaoData);
      } else {
        console.log('Criando avaliação:', avaliacaoData);
        result = await createAvaliacao(avaliacaoData);
      }
      
      if (result) {
        // Reset form apenas se não for edição
        if (!isEditMode) {
          formData = {
            espirito: '',
            caractere: '',
            disposicao: '',
            avaliacao_texto: '',
            nota: '',
            data: new Date().toISOString().split('T')[0]
          };
        }
        
        dispatch('success', { avaliacao: result });
        dispatch('close');
      }
    } catch (err) {
      console.error('Erro ao criar avaliação:', err);
      error = err.message || 'Erro ao criar avaliação';
    } finally {
      isLoading = false;
    }
  }
  
  function handleClose() {
    if (!isLoading) {
      userId = '';
      error = '';
      validationErrors = {};
      
      // Reset form
      formData = {
        espirito: '',
        caractere: '',
        disposicao: '',
        avaliacao_texto: '',
        nota: '',
        data: new Date().toISOString().split('T')[0]
      };
      
      dispatch('close');
    }
  }
  
  function handleBackdropClick(event) {
    if (event.target === event.currentTarget) {
      handleClose();
    }
  }
</script>

{#if isOpen}
  <div 
    class="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50 p-4"
    on:click={handleBackdropClick}
    role="dialog"
    aria-modal="true"
  >
    <div class="bg-white rounded-lg shadow-xl max-w-2xl w-full max-h-[90vh] overflow-y-auto">
      <!-- Header -->
      <div class="bg-blue-600 px-6 py-4 rounded-t-lg">
        <div class="flex items-center justify-between">
          <h2 class="text-xl font-bold text-white">
            {isEditMode ? 'Editar Avaliação' : 'Nova Avaliação'} - {jovemNome}
          </h2>
          <button
            on:click={handleClose}
            disabled={isLoading}
            class="text-white hover:text-gray-200 disabled:opacity-50"
          >
            <svg class="w-6 h-6" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12" />
            </svg>
          </button>
        </div>
      </div>
      
      <!-- Content -->
      <div class="p-6">
        <form on:submit|preventDefault={handleSubmit} class="space-y-6">
          <!-- Espírito -->
          <div>
            <label for="espirito" class="block text-sm font-medium text-gray-700 mb-1">
              Espírito *
            </label>
            <select
              id="espirito"
              bind:value={formData.espirito}
              class="block w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-blue-500"
            >
              <option value="">Selecione o espírito</option>
              {#each opcoesEspirito as opcao}
                <option value={opcao.value}>{opcao.label}</option>
              {/each}
            </select>
            {#if validationErrors.espirito}
              <p class="mt-1 text-sm text-red-600">{validationErrors.espirito}</p>
            {/if}
          </div>
          
          <!-- Caráter -->
          <div>
            <label for="caractere" class="block text-sm font-medium text-gray-700 mb-1">
              Caráter *
            </label>
            <select
              id="caractere"
              bind:value={formData.caractere}
              class="block w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-blue-500"
            >
              <option value="">Selecione o caráter</option>
              {#each opcoesCaractere as opcao}
                <option value={opcao.value}>{opcao.label}</option>
              {/each}
            </select>
            {#if validationErrors.caractere}
              <p class="mt-1 text-sm text-red-600">{validationErrors.caractere}</p>
            {/if}
          </div>
          
          <!-- Disposição -->
          <div>
            <label for="disposicao" class="block text-sm font-medium text-gray-700 mb-1">
              Disposição *
            </label>
            <select
              id="disposicao"
              bind:value={formData.disposicao}
              class="block w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-blue-500"
            >
              <option value="">Selecione a disposição</option>
              {#each opcoesDisposicao as opcao}
                <option value={opcao.value}>{opcao.label}</option>
              {/each}
            </select>
            {#if validationErrors.disposicao}
              <p class="mt-1 text-sm text-red-600">{validationErrors.disposicao}</p>
            {/if}
          </div>
          
          <!-- Data -->
          <div>
            <Input
              label="Data da Avaliação *"
              type="date"
              bind:value={formData.data}
              error={validationErrors.data}
            />
          </div>
          
          <!-- Nota -->
          <div>
            <Input
              label="Nota (0-10)"
              type="number"
              min="0"
              max="10"
              step="0.1"
              bind:value={formData.nota}
              error={validationErrors.nota}
              placeholder="Ex: 8.5"
            />
          </div>
          
          <!-- Comentários -->
          <div>
            <label class="block text-sm font-medium text-gray-700 mb-2">
              Comentários
            </label>
            <RichTextEditor
              bind:value={formData.avaliacao_texto}
              placeholder="Digite seus comentários sobre a avaliação..."
              rows={6}
            />
          </div>
          
          <!-- Error Message -->
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
          
          <!-- Actions -->
          <div class="flex justify-end space-x-3 pt-4 border-t border-gray-200">
            <Button
              type="button"
              variant="outline"
              on:click={handleClose}
              disabled={isLoading}
            >
              Cancelar
            </Button>
            <Button
              type="submit"
              variant="primary"
              loading={isLoading}
              disabled={isLoading}
            >
              {isLoading ? (isEditMode ? 'Atualizando...' : 'Criando...') : (isEditMode ? 'Atualizar Avaliação' : 'Criar Avaliação')}
            </Button>
          </div>
        </form>
      </div>
    </div>
  </div>
{/if}
