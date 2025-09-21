<script>
  import { createEventDispatcher } from 'svelte';
  import { supabase } from '$lib/utils/supabase';
  import { uploadUserPhoto, compressImage } from '$lib/stores/upload';
  import Button from '$lib/components/ui/Button.svelte';
  import Input from '$lib/components/ui/Input.svelte';
  import Card from '$lib/components/ui/Card.svelte';

  const dispatch = createEventDispatcher();

  export let isOpen = false;
  export let userProfile = null;

  // Estados do modal
  let loading = false;
  let error = '';
  let success = '';

  // Dados do formulário
  let formData = {
    nome: '',
    foto: ''
  };

  // Foto
  let fotoFile = null;
  let fotoPreview = '';
  let fotoInputRef;

  // Validação
  let validationErrors = {};

  // Função para abrir o modal
  function openModal() {
    if (userProfile) {
      formData.nome = userProfile.nome || '';
      formData.foto = userProfile.foto || '';
      fotoPreview = userProfile.foto || '';
    }
    error = '';
    success = '';
    validationErrors = {};
    fotoFile = null; // Reset do arquivo de foto
  }

  // Função para fechar o modal
  function closeModal() {
    isOpen = false;
    // Reset do input de arquivo
    if (fotoInputRef) {
      fotoInputRef.value = '';
    }
    dispatch('close');
  }

  // Função para validar o formulário
  function validateForm() {
    validationErrors = {};
    
    if (!formData.nome.trim()) {
      validationErrors.nome = 'Nome é obrigatório';
    }
    
    return Object.keys(validationErrors).length === 0;
  }

  // Função para lidar com upload de foto
  async function handleFotoUpload(event) {
    const file = event.target.files[0];
    if (!file) return;
    
    try {
      // Limpar erros anteriores
      error = '';
      
      // Comprimir imagem
      const compressedFile = await compressImage(file);
      fotoFile = compressedFile;
      
      // Criar preview
      const reader = new FileReader();
      reader.onload = (e) => {
        fotoPreview = e.target.result;
      };
      reader.readAsDataURL(compressedFile);
      
      console.log('Foto carregada com sucesso:', file.name);
    } catch (err) {
      console.error('Erro ao processar imagem:', err);
      error = 'Erro ao processar imagem: ' + err.message;
      // Reset do input em caso de erro
      if (fotoInputRef) {
        fotoInputRef.value = '';
      }
    }
  }

  // Função para remover foto
  function removeFoto() {
    fotoFile = null;
    fotoPreview = '';
    formData.foto = '';
    if (fotoInputRef) {
      fotoInputRef.value = '';
    }
    console.log('Foto removida');
  }

  // Função para submeter o formulário
  async function handleSubmit() {
    if (!validateForm()) {
      return;
    }

    loading = true;
    error = '';
    success = '';

    try {
      let fotoUrl = formData.foto;

      // Upload da foto se houver nova foto
      if (fotoFile) {
        console.log('Iniciando upload da foto...');
        fotoUrl = await uploadUserPhoto(userProfile.id, fotoFile);
        console.log('Upload concluído, URL:', fotoUrl);
      }

      console.log('Atualizando perfil no banco...');
      // Atualizar usuário no banco
      const { error: updateError } = await supabase
        .from('usuarios')
        .update({
          nome: formData.nome.trim(),
          foto: fotoUrl
        })
        .eq('id', userProfile.id);

      if (updateError) {
        throw updateError;
      }

      console.log('Perfil atualizado com sucesso!');
      success = 'Perfil atualizado com sucesso!';
      
      // Emitir evento de sucesso
      dispatch('success', {
        nome: formData.nome.trim(),
        foto: fotoUrl
      });

      // Fechar modal após 1.5 segundos
      setTimeout(() => {
        closeModal();
      }, 1500);

    } catch (err) {
      console.error('Erro ao atualizar perfil:', err);
      error = 'Erro ao atualizar perfil: ' + err.message;
    } finally {
      loading = false;
    }
  }

  // Função para abrir seletor de arquivo
  function openFileSelector() {
    if (fotoInputRef) {
      fotoInputRef.click();
    }
  }

  // Script para abrir modal quando isOpen mudar
  $: if (isOpen) {
    openModal();
  }
</script>

{#if isOpen}
  <!-- Overlay -->
  <div class="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50 p-4" on:click={closeModal} on:keydown={(e) => e.key === 'Escape' && closeModal()} role="dialog" aria-modal="true" aria-labelledby="modal-title" tabindex="-1">
    <div class="bg-white rounded-xl shadow-2xl max-w-md w-full max-h-[90vh] overflow-y-auto" on:click|stopPropagation role="document">
      <Card>
        <!-- Header -->
        <div class="px-6 py-4 border-b border-gray-200">
          <div class="flex items-center justify-between">
            <h3 id="modal-title" class="text-lg font-semibold text-gray-900">Editar Perfil</h3>
            <button
              on:click={closeModal}
              class="text-gray-400 hover:text-gray-600 transition-colors"
            >
              <svg class="w-6 h-6" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12" />
              </svg>
            </button>
          </div>
        </div>

        <!-- Content -->
        <div class="p-6 space-y-6">
          <!-- Mensagens -->
          {#if error}
            <div class="bg-red-50 border border-red-200 rounded-md p-4">
              <div class="flex">
                <svg class="w-5 h-5 text-red-400" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8v4m0 4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
                </svg>
                <div class="ml-3">
                  <p class="text-sm text-red-800">{error}</p>
                </div>
              </div>
            </div>
          {/if}

          {#if success}
            <div class="bg-green-50 border border-green-200 rounded-md p-4">
              <div class="flex">
                <svg class="w-5 h-5 text-green-400" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7" />
                </svg>
                <div class="ml-3">
                  <p class="text-sm text-green-800">{success}</p>
                </div>
              </div>
            </div>
          {/if}

          <!-- Foto -->
          <div class="space-y-3">
            <label for="foto-input" class="block text-sm font-medium text-gray-700">Foto do Perfil</label>
            
            <div class="flex flex-col items-center space-y-4">
              <!-- Preview da foto -->
              <div class="relative">
                {#if fotoPreview}
                  <img 
                    src={fotoPreview} 
                    alt="Preview da foto" 
                    class="w-24 h-24 rounded-full object-cover border-4 border-gray-200"
                  />
                {:else}
                  <div class="w-24 h-24 rounded-full bg-gradient-to-br from-gray-100 to-gray-200 flex items-center justify-center border-4 border-gray-200">
                    <svg class="w-8 h-8 text-gray-400" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M16 7a4 4 0 11-8 0 4 4 0 018 0zM12 14a7 7 0 00-7 7h14a7 7 0 00-7-7z" />
                    </svg>
                  </div>
                {/if}
              </div>

              <!-- Botões de ação -->
              <div class="flex space-x-3">
                <Button
                  type="button"
                  variant="outline"
                  size="sm"
                  on:click={openFileSelector}
                  disabled={loading}
                >
                  <svg class="w-4 h-4 mr-2" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 16l4.586-4.586a2 2 0 012.828 0L16 16m-2-2l1.586-1.586a2 2 0 012.828 0L20 14m-6-6h.01M6 20h12a2 2 0 002-2V6a2 2 0 00-2-2H6a2 2 0 00-2 2v12a2 2 0 002 2z" />
                  </svg>
                  Escolher Foto
                </Button>

                {#if fotoPreview}
                  <Button
                    type="button"
                    variant="outline"
                    size="sm"
                    on:click={removeFoto}
                    disabled={loading}
                  >
                    <svg class="w-4 h-4 mr-2" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16" />
                    </svg>
                    Remover
                  </Button>
                {/if}
              </div>

              <!-- Input de arquivo oculto -->
              <input
                id="foto-input"
                bind:this={fotoInputRef}
                type="file"
                accept="image/*"
                on:change={handleFotoUpload}
                class="hidden"
              />

              <!-- Informações sobre o arquivo -->
              <p class="text-xs text-gray-500 text-center">
                JPG, PNG ou WEBP • Máximo 5MB
              </p>
            </div>
          </div>

          <!-- Nome -->
          <div class="space-y-2">
            <label for="nome" class="block text-sm font-medium text-gray-700">
              Nome Completo *
            </label>
            <Input
              id="nome"
              type="text"
              bind:value={formData.nome}
              placeholder="Digite seu nome completo"
              error={validationErrors.nome}
              disabled={loading}
            />
          </div>
        </div>

        <!-- Footer -->
        <div class="px-6 py-4 border-t border-gray-200 flex justify-end space-x-3">
          <Button
            variant="outline"
            on:click={closeModal}
            disabled={loading}
          >
            Cancelar
          </Button>
          <Button
            on:click={handleSubmit}
            loading={loading}
            disabled={loading}
          >
            {loading ? 'Salvando...' : 'Salvar Alterações'}
          </Button>
        </div>
      </Card>
    </div>
  </div>
{/if}
