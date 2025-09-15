<script>
  import { createEventDispatcher, onMount } from 'svelte';
  import { createAvaliacao } from '$lib/stores/avaliacoes';
  import { supabase } from '$lib/utils/supabase';
  import Button from '$lib/components/ui/Button.svelte';
  import Input from '$lib/components/ui/Input.svelte';
  import Select from '$lib/components/ui/Select.svelte';
  
  const dispatch = createEventDispatcher();
  
  export let isOpen = false;
  export let jovemId = '';
  export let jovemNome = '';
  
  let isLoading = false;
  let error = '';
  let userId = '';
  
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
    { value: 'ser_observar', label: 'Ser Observar' },
    { value: 'bom', label: 'Bom' },
    { value: 'excelente', label: 'Excelente' }
  ];
  
  const opcoesCaractere = [
    { value: 'excelente', label: 'Excelente' },
    { value: 'bom', label: 'Bom' },
    { value: 'ser_observar', label: 'Ser Observar' },
    { value: 'ruim', label: 'Ruim' }
  ];
  
  const opcoesDisposicao = [
    { value: 'muito_disposto', label: 'Muito Disposto' },
    { value: 'normal', label: 'Normal' },
    { value: 'pacato', label: 'Pacato' },
    { value: 'desanimado', label: 'Desanimado' }
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
      
      console.log('Criando avaliação:', avaliacaoData);
      
      const result = await createAvaliacao(avaliacaoData);
      
      if (result) {
        // Reset form
        formData = {
          espirito: '',
          caractere: '',
          disposicao: '',
          avaliacao_texto: '',
          nota: '',
          data: new Date().toISOString().split('T')[0]
        };
        
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
            Nova Avaliação - {jovemNome}
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
            <Select
              label="Espírito *"
              options={opcoesEspirito}
              bind:value={formData.espirito}
              error={validationErrors.espirito}
              placeholder="Selecione o espírito"
            />
          </div>
          
          <!-- Caráter -->
          <div>
            <Select
              label="Caráter *"
              options={opcoesCaractere}
              bind:value={formData.caractere}
              error={validationErrors.caractere}
              placeholder="Selecione o caráter"
            />
          </div>
          
          <!-- Disposição -->
          <div>
            <Select
              label="Disposição *"
              options={opcoesDisposicao}
              bind:value={formData.disposicao}
              error={validationErrors.disposicao}
              placeholder="Selecione a disposição"
            />
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
            <textarea
              bind:value={formData.avaliacao_texto}
              rows="4"
              class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent"
              placeholder="Comentários sobre a avaliação..."
            ></textarea>
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
              {isLoading ? 'Criando...' : 'Criar Avaliação'}
            </Button>
          </div>
        </form>
      </div>
    </div>
  </div>
{/if}
