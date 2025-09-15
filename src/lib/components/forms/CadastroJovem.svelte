<script>
  import { onMount } from 'svelte';
  import { goto } from '$app/navigation';
  import { createJovem } from '$lib/stores/jovens';
  import { loadInitialData, estados, blocos, regioes, igrejas, edicoes, loadBlocos, loadRegioes, loadIgrejas, clearHierarchy } from '$lib/stores/geographic';
  import { uploadJovemPhoto, compressImage } from '$lib/stores/upload';
  import { generateUUID } from '$lib/utils/uuid';
  import { verificarUsuarioLogado } from '$lib/VERIFICAR_USUARIO_LOGADO.js';
  import Button from '$lib/components/ui/Button.svelte';
  import Input from '$lib/components/ui/Input.svelte';
  import Select from '$lib/components/ui/Select.svelte';
  import Card from '$lib/components/ui/Card.svelte';
  
  // Estados do formulário
  let currentStep = 1;
  let totalSteps = 5;
  let isLoading = false;
  let error = '';
  let success = false;
  
  // Dados do formulário
  let formData = {
    // Dados pessoais
    nome_completo: '',
    data_nasc: '',
    sexo: 'masculino',
    estado_civil: '',
    whatsapp: '',
    
    // Localização
    estado_id: '',
    bloco_id: '',
    regiao_id: '',
    igreja_id: '',
    edicao_id: '',
    
    // Informações profissionais
    trabalha: false,
    local_trabalho: '',
    escolaridade: '',
    formacao: '',
    tem_dividas: false,
    valor_divida: '',
    
    // Informações espirituais
    tempo_igreja: '',
    batizado_aguas: false,
    data_batismo_aguas: '',
    batizado_es: false,
    data_batismo_es: '',
    condicao: '',
    tempo_condicao: '',
    responsabilidade_igreja: '',
    
    // Experiência
    disposto_servir: false,
    ja_obra_altar: false,
    ja_obreiro: false,
    ja_colaborador: false,
    afastado: false,
    data_afastamento: '',
    motivo_afastamento: '',
    data_retorno: '',
    
    // Informações familiares
    pais_na_igreja: false,
    observacao_pais: '',
    familiares_igreja: false,
    
    // Informações adicionais
    deseja_altar: false,
    observacao: '',
    testemunho: '',
    
    // Redes sociais
    instagram: '',
    facebook: '',
    tiktok: '',
    observacao_redes: '',
    
    // IntelliMen
    formado_intellimen: false,
    fazendo_desafios: false,
    qual_desafio: '',
    
    // Foto
    foto: ''
  };
  
  // Foto
  let fotoFile = null;
  let fotoPreview = '';
  let fotoInputRef;
  
  // Cropper state
  let showCropper = false;
  let cropImageSrc = '';
  let cropScale = 1; // 1x to 3x
  let minScale = 1;
  let maxScale = 3;
  let cropOffsetX = 0;
  let cropOffsetY = 0;
  let isDragging = false;
  let dragStartX = 0;
  let dragStartY = 0;
  let imageNaturalWidth = 0;
  let imageNaturalHeight = 0;
  let cropContainerSize = 320; // square viewport in px - will be calculated responsively
  
  // Validação
  let validationErrors = {};
  
  // Função para aplicar máscara do WhatsApp
  function formatWhatsApp(value) {
    // Remove todos os caracteres não numéricos
    const numbers = value.replace(/\D/g, '');
    
    // Limita a 11 dígitos
    const limitedNumbers = numbers.slice(0, 11);
    
    // Aplica a máscara (11) 99999-9999
    if (limitedNumbers.length <= 2) {
      return limitedNumbers;
    } else if (limitedNumbers.length <= 7) {
      return `(${limitedNumbers.slice(0, 2)}) ${limitedNumbers.slice(2)}`;
    } else {
      return `(${limitedNumbers.slice(0, 2)}) ${limitedNumbers.slice(2, 7)}-${limitedNumbers.slice(7)}`;
    }
  }
  
  // Função para lidar com mudanças no WhatsApp
  function handleWhatsAppChange(event) {
    const formatted = formatWhatsApp(event.target.value);
    formData.whatsapp = formatted;
    event.target.value = formatted;
  }
  
  onMount(async () => {
    console.log('=== INICIALIZANDO FORMULÁRIO ===');
    
    // Verificar usuário logado
    const usuarioInfo = await verificarUsuarioLogado();
    console.log('Informações do usuário:', usuarioInfo);
    
    if (!usuarioInfo.logado) {
      error = `Erro de autenticação: ${usuarioInfo.erro}`;
      return;
    }
    
    if (!usuarioInfo.temPermissao) {
      console.warn('⚠️ Usuário não tem permissão, mas continuando para debug...');
      // Temporariamente permitir para debug
      // error = 'Você não tem permissão para cadastrar jovens';
      // return;
    } else {
      console.log('✅ Usuário tem permissão para cadastrar jovens');
    }
    
    // Teste de inserção removido - estava causando inserção de dados de debug
    
    // Carregar dados iniciais
    await loadInitialData();
    console.log('✅ Formulário inicializado com sucesso');
  });
  
  // Função para validar passo atual
  function validateStep(step) {
    validationErrors = {};
    
    switch (step) {
      case 1: // Dados pessoais
        if (!formData.nome_completo) validationErrors.nome_completo = 'Nome completo é obrigatório';
        if (!formData.data_nasc) validationErrors.data_nasc = 'Data de nascimento é obrigatória';
        if (!formData.sexo) validationErrors.sexo = 'Sexo é obrigatório';
        if (!formData.estado_civil) validationErrors.estado_civil = 'Estado civil é obrigatório';
        if (!formData.whatsapp) validationErrors.whatsapp = 'WhatsApp é obrigatório';
        
        // Validação adicional para data
        if (formData.data_nasc && typeof formData.data_nasc === 'string') {
          // Converter data do formato DD/MM/YYYY para YYYY-MM-DD se necessário
          const dateStr = formData.data_nasc;
          if (dateStr.includes('/')) {
            const [day, month, year] = dateStr.split('/');
            formData.data_nasc = `${year}-${month.padStart(2, '0')}-${day.padStart(2, '0')}`;
          }
          
          // Verificar se a data é válida
          const date = new Date(formData.data_nasc);
          if (isNaN(date.getTime())) {
            validationErrors.data_nasc = 'Data de nascimento inválida';
          }
        }
        break;
        
      case 2: // Localização
        if (!formData.estado_id) validationErrors.estado_id = 'Estado é obrigatório';
        if (!formData.bloco_id) validationErrors.bloco_id = 'Bloco é obrigatório';
        if (!formData.regiao_id) validationErrors.regiao_id = 'Região é obrigatória';
        if (!formData.igreja_id) validationErrors.igreja_id = 'Igreja é obrigatória';
        if (!formData.edicao_id) validationErrors.edicao_id = 'Edição é obrigatória';
        break;
        
      case 3: // Informações profissionais
        // Validações opcionais para este passo
        break;
        
      case 4: // Informações espirituais
        if (!formData.tempo_igreja) validationErrors.tempo_igreja = 'Tempo na igreja é obrigatório';
        if (!formData.condicao) validationErrors.condicao = 'Condição é obrigatória';
        break;
        
      case 5: // Informações adicionais
        // Validações opcionais para este passo
        break;
    }
    
    return Object.keys(validationErrors).length === 0;
  }
  
  // Função para avançar para o próximo passo
  function nextStep() {
    if (validateStep(currentStep)) {
      if (currentStep < totalSteps) {
        currentStep++;
      }
    }
  }
  
  // Função para voltar ao passo anterior
  function prevStep() {
    if (currentStep > 1) {
      currentStep--;
    }
  }
  
  // Variável para controlar mudanças
  let lastEstadoId = '';
  
  // Reatividade para mudança de estado
  $: if (formData.estado_id && formData.estado_id !== lastEstadoId) {
    lastEstadoId = formData.estado_id;
    handleEstadoChange();
  }
  
  // Função para lidar com mudança de estado
  async function handleEstadoChange() {
    const estadoId = formData.estado_id;
    console.log('Estado selecionado:', estadoId);
    
    // Limpar campos dependentes
    formData.bloco_id = '';
    formData.regiao_id = '';
    formData.igreja_id = '';
    clearHierarchy();
    
    if (estadoId) {
      console.log('Carregando blocos para estado:', estadoId);
      await loadBlocos(estadoId);
      console.log('Blocos carregados:', $blocos);
    }
  }
  
  // Variável para controlar mudanças de bloco
  let lastBlocoId = '';
  
  // Reatividade para mudança de bloco
  $: if (formData.bloco_id && formData.bloco_id !== lastBlocoId) {
    lastBlocoId = formData.bloco_id;
    handleBlocoChange();
  }
  
  // Função para lidar com mudança de bloco
  async function handleBlocoChange() {
    const blocoId = formData.bloco_id;
    console.log('Bloco selecionado:', blocoId);
    
    // Limpar campos dependentes
    formData.regiao_id = '';
    formData.igreja_id = '';
    regioes.set([]);
    igrejas.set([]);
    
    if (blocoId) {
      console.log('Carregando regiões para bloco:', blocoId);
      await loadRegioes(blocoId);
      console.log('Regiões carregadas:', $regioes);
    }
  }
  
  // Variável para controlar mudanças de região
  let lastRegiaoId = '';
  
  // Reatividade para mudança de região
  $: if (formData.regiao_id && formData.regiao_id !== lastRegiaoId) {
    lastRegiaoId = formData.regiao_id;
    handleRegiaoChange();
  }
  
  // Função para lidar com mudança de região
  async function handleRegiaoChange() {
    const regiaoId = formData.regiao_id;
    console.log('Região selecionada:', regiaoId);
    
    // Limpar campos dependentes
    formData.igreja_id = '';
    igrejas.set([]);
    
    if (regiaoId) {
      console.log('Carregando igrejas para região:', regiaoId);
      await loadIgrejas(regiaoId);
      console.log('Igrejas carregadas:', $igrejas);
    }
  }
  
  // Função para lidar com upload de foto
  async function handleFotoUpload(event) {
    const target = event.target;
    const file = target.files && target.files[0];
    if (!file) return;
    // abrir cropper com dataURL
    const reader = new FileReader();
    reader.onload = (e) => {
      cropImageSrc = e.target.result;
      // reset controles
      cropScale = 1;
      cropOffsetX = 0;
      cropOffsetY = 0;
      showCropper = true;
      // Block body scroll
      document.body.style.overflow = 'hidden';
      
      // Calculate responsive crop container size
      const screenWidth = window.innerWidth;
      if (screenWidth < 640) { // sm breakpoint
        cropContainerSize = Math.min(280, screenWidth - 80); // 40px margin on each side
      } else if (screenWidth < 768) { // md breakpoint
        cropContainerSize = Math.min(320, screenWidth - 120);
      } else {
        cropContainerSize = 320; // default
      }
      
      // descobrir dimensões naturais
      const img = new Image();
      img.onload = () => {
        imageNaturalWidth = img.naturalWidth;
        imageNaturalHeight = img.naturalHeight;
        // definir escala mínima para que a imagem inteira caiba no quadrado
        const scaleToFitW = cropContainerSize / imageNaturalWidth;
        const scaleToFitH = cropContainerSize / imageNaturalHeight;
        minScale = Math.min(scaleToFitW, scaleToFitH);
        if (!isFinite(minScale) || minScale <= 0) minScale = 1;
        maxScale = minScale * 3;
        cropScale = minScale;
        cropOffsetX = 0;
        cropOffsetY = 0;
      };
      img.src = cropImageSrc;
    };
    reader.readAsDataURL(file);
  }
  
  function onCropMouseDown(event) {
    isDragging = true;
    dragStartX = event.clientX - cropOffsetX;
    dragStartY = event.clientY - cropOffsetY;
  }
  function onCropMouseMove(event) {
    if (!isDragging) return;
    cropOffsetX = event.clientX - dragStartX;
    cropOffsetY = event.clientY - dragStartY;
  }
  function onCropMouseUp() {
    isDragging = false;
  }
  
  async function confirmCrop() {
    try {
      // criar canvas quadrado
      const canvasSize = 600; // saída de boa qualidade
      const canvas = document.createElement('canvas');
      canvas.width = canvasSize;
      canvas.height = canvasSize;
      const ctx = canvas.getContext('2d');

      // carregar imagem
      const img = new Image();
      await new Promise((resolve) => { img.onload = resolve; img.src = cropImageSrc; });

      // tamanho da imagem exibida no viewport
      const scaledW = imageNaturalWidth * cropScale;
      const scaledH = imageNaturalHeight * cropScale;

      // posição do topo/esquerda da imagem dentro do viewport (0,0 no canto sup esquerdo do quadrado)
      const imageLeftInView = (cropContainerSize / 2) - (scaledW / 2) + cropOffsetX;
      const imageTopInView = (cropContainerSize / 2) - (scaledH / 2) + cropOffsetY;

      // área do viewport (quadrado) em coordenadas da imagem de origem
      const srcX = Math.max(0, -imageLeftInView / cropScale);
      const srcY = Math.max(0, -imageTopInView / cropScale);
      const srcSize = Math.min(
        imageNaturalWidth - srcX,
        imageNaturalHeight - srcY,
        cropContainerSize / cropScale
      );

      // desenhar a região recortada no canvas final
      ctx.drawImage(
        img,
        srcX,
        srcY,
        srcSize,
        srcSize,
        0,
        0,
        canvasSize,
        canvasSize
      );
      
      const blob = await new Promise((resolve) => canvas.toBlob(resolve, 'image/jpeg', 0.9));
      // compressão adicional (opcional)
      const processed = await compressImage(new File([blob], 'crop.jpg', { type: 'image/jpeg' }));
      fotoFile = processed;
      fotoPreview = await new Promise((resolve) => {
        const fr = new FileReader();
        fr.onload = (e) => resolve(e.target.result);
        fr.readAsDataURL(processed);
      });
      showCropper = false;
      // Restore body scroll
      document.body.style.overflow = '';
    } catch (e) {
      error = 'Falha ao recortar imagem';
      showCropper = false;
      // Restore body scroll
      document.body.style.overflow = '';
    }
  }
  function cancelCrop() {
    showCropper = false;
    // Restore body scroll
    document.body.style.overflow = '';
  }
  
  
  // Função para submeter o formulário
  async function handleSubmit() {
    if (!validateStep(currentStep)) {
      return;
    }
    
    isLoading = true;
    error = '';
    
    try {
      console.log('=== INÍCIO DO CADASTRO ===');
      console.log('FormData antes do envio:', formData);
      console.log('Campo edicao:', formData.edicao);
      console.log('Campo edicao_id:', formData.edicao_id);
      console.log('Foto file:', fotoFile);
      
      // Upload da foto se houver
      if (fotoFile) {
        console.log('=== UPLOAD DA FOTO ===');
        console.log('Fazendo upload da foto...');
        // Gerar ID temporário para o jovem
        const tempId = generateUUID();
        console.log('ID temporário gerado:', tempId);
        
        try {
          formData.foto = await uploadJovemPhoto(tempId, fotoFile);
          console.log('✅ Foto enviada com sucesso:', formData.foto);
        } catch (uploadError) {
          console.error('❌ Erro no upload da foto:', uploadError);
          throw new Error(`Erro no upload da foto: ${uploadError.message}`);
        }
      } else {
        console.log('Nenhuma foto para upload');
      }
      
      console.log('=== CRIAÇÃO DO JOVEM ===');
      console.log('Criando jovem com dados finais:', formData);
      
      // Criar jovem
      const jovem = await createJovem(formData);
      console.log('✅ Jovem criado com sucesso:', jovem);
      
      success = true;
      
      // Redirecionar após 2 segundos
      setTimeout(() => {
        goto(`/jovens/${jovem.id}`);
      }, 2000);
      
    } catch (err) {
      console.error('❌ ERRO GERAL NO CADASTRO:', err);
      console.error('Stack trace:', err.stack);
      error = err.message;
    } finally {
      isLoading = false;
    }
  }
  
  // Função para calcular progresso
  $: progress = (currentStep / totalSteps) * 100;
</script>

<div class="max-w-4xl mx-auto">
  <!-- Header -->
  <div class="mb-8">
    <h1 class="text-3xl font-bold text-gray-900 mb-2">Cadastro de Jovem</h1>
    <p class="text-gray-600">Preencha as informações em etapas</p>
  </div>
  
  <!-- Progress Bar -->
  <div class="mb-8">
    <div class="flex items-center justify-between mb-2">
      <span class="text-sm font-medium text-gray-700">Etapa {currentStep} de {totalSteps}</span>
      <span class="text-sm text-gray-500">{Math.round(progress)}% concluído</span>
    </div>
    <div class="w-full bg-gray-200 rounded-full h-2">
      <div class="bg-blue-600 h-2 rounded-full transition-all duration-300" style="width: {progress}%"></div>
    </div>
  </div>
  
  <!-- Form -->
  <Card padding="p-8">
    {#if success}
      <!-- Success Message -->
      <div class="text-center py-12">
        <div class="w-16 h-16 bg-green-100 rounded-full flex items-center justify-center mx-auto mb-4">
          <svg class="w-8 h-8 text-green-600" fill="none" viewBox="0 0 24 24" stroke="currentColor">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7" />
          </svg>
        </div>
        <h3 class="text-xl font-semibold text-gray-900 mb-2">Jovem cadastrado com sucesso!</h3>
        <p class="text-gray-600">Redirecionando para a ficha do jovem...</p>
      </div>
    {:else}
      <!-- Step 1: Dados Pessoais -->
      {#if currentStep === 1}
        <div class="space-y-8">
          <div class="text-center">
            <h2 class="text-2xl font-bold text-gray-900 mb-2">Dados Pessoais</h2>
            <p class="text-gray-600">Preencha as informações básicas do jovem</p>
          </div>
          
          <!-- Foto -->
          <div class="flex items-start space-x-6 p-6 bg-gradient-to-br from-blue-50 to-indigo-50 rounded-xl border border-blue-100">
            <div class="flex-shrink-0">
              <!-- Input file oculto para clique no ícone -->
              <input
                type="file"
                accept="image/*"
                on:change={handleFotoUpload}
                bind:this={fotoInputRef}
                class="hidden"
              />
              
              {#if fotoPreview}
                <div class="relative cursor-pointer" on:click={() => fotoInputRef?.click()}>
                  <img class="w-28 h-28 rounded-full object-cover border-4 border-white shadow-lg hover:shadow-xl transition-shadow" src={fotoPreview} alt="Preview" />
                  <div class="absolute -bottom-1 -right-1 w-8 h-8 bg-green-500 rounded-full flex items-center justify-center border-2 border-white">
                    <svg class="w-4 h-4 text-white" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7" />
                    </svg>
                  </div>
                  <!-- Overlay para indicar que é clicável -->
                  <div class="absolute inset-0 bg-black bg-opacity-0 hover:bg-opacity-10 rounded-full transition-all duration-200 flex items-center justify-center">
                    <div class="opacity-0 hover:opacity-100 transition-opacity duration-200">
                      <svg class="w-6 h-6 text-white" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 16l4.586-4.586a2 2 0 012.828 0L16 16m-2-2l1.586-1.586a2 2 0 012.828 0L20 14m-6-6h.01M6 20h12a2 2 0 002-2V6a2 2 0 00-2-2H6a2 2 0 00-2 2v12a2 2 0 002 2z" />
                      </svg>
                    </div>
                  </div>
                </div>
              {:else}
                <div 
                  class="w-28 h-28 bg-gradient-to-br from-blue-100 to-indigo-200 rounded-full flex items-center justify-center border-4 border-white shadow-lg cursor-pointer hover:shadow-xl hover:from-blue-200 hover:to-indigo-300 transition-all duration-200" 
                  on:click={() => fotoInputRef?.click()}
                >
                  <div class="text-center">
                    <svg class="w-10 h-10 text-blue-500 mx-auto mb-1" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="1.5" d="M16 7a4 4 0 11-8 0 4 4 0 018 0zM12 14a7 7 0 00-7 7h14a7 7 0 00-7-7z" />
                    </svg>
                    <div class="text-xs text-blue-600 font-medium">Adicionar Foto</div>
                  </div>
                </div>
              {/if}
            </div>
            <div class="flex-1">
              <label class="block text-sm font-semibold text-gray-800 mb-3">Foto do Jovem</label>
              <div class="space-y-3">
                <input
                  type="file"
                  accept="image/*"
                  on:change={handleFotoUpload}
                  class="block w-full text-sm text-gray-600 file:mr-4 file:py-2.5 file:px-6 file:rounded-lg file:border-0 file:text-sm file:font-semibold file:bg-blue-600 file:text-white hover:file:bg-blue-700 transition-colors cursor-pointer"
                />
                <div class="flex items-center space-x-2 text-xs text-gray-500">
                  <svg class="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 16h-1v-4h-1m1-4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
                  </svg>
                  <span>JPG, PNG ou WEBP. Máximo 5MB</span>
                </div>
              </div>
            </div>
          </div>

          {#if showCropper}
            <!-- Modal Cropper responsivo -->
            <div class="fixed inset-0 bg-black bg-opacity-50 z-50 flex items-center justify-center p-2 sm:p-4" on:mouseup={onCropMouseUp} on:mouseleave={onCropMouseUp}>
              <div class="bg-white rounded-2xl p-4 sm:p-6 shadow-2xl w-full max-w-sm sm:max-w-md md:max-w-2xl max-h-[95vh] overflow-y-auto">
                <h3 class="text-lg font-semibold text-gray-900 mb-4">Ajustar foto</h3>
                <div class="flex flex-col space-y-4 sm:space-y-6">
                  <!-- Viewport quadrado -->
                  <div class="flex justify-center">
                    <div class="relative rounded-xl border-2 border-blue-200 bg-gray-100 overflow-hidden" style={`width:${cropContainerSize}px;height:${cropContainerSize}px`}>
                      {#if cropImageSrc}
                        <img src={cropImageSrc}
                             alt="crop"
                             class="absolute top-1/2 left-1/2 select-none cursor-move max-w-none"
                             style={`transform: translate(calc(-50% + ${cropOffsetX}px), calc(-50% + ${cropOffsetY}px)) scale(${cropScale});`}
                             draggable={false}
                             on:mousedown={onCropMouseDown}
                             on:mousemove={onCropMouseMove}
                        />
                      {/if}
                    </div>
                  </div>
                  <!-- Controles -->
                  <div class="space-y-3 sm:space-y-4">
                    <label class="block text-sm font-medium text-gray-700">Zoom: {Math.round(cropScale * 100)}%</label>
                    <input type="range" {minScale} {maxScale} min={minScale} max={maxScale} step="0.01" bind:value={cropScale} class="w-full h-2 bg-gray-200 rounded-lg appearance-none cursor-pointer" />
                    <div class="text-xs text-gray-500">Arraste a imagem para posicionar</div>
                  </div>
                </div>
                <div class="flex flex-col sm:flex-row gap-2 sm:gap-3 mt-4 sm:mt-6">
                  <button class="flex-1 px-4 py-2 rounded-lg border border-gray-300 text-gray-700 hover:bg-gray-50 transition-colors" on:click={cancelCrop}>Cancelar</button>
                  <button class="flex-1 px-4 py-2 rounded-lg bg-blue-600 text-white hover:bg-blue-700 transition-colors" on:click={confirmCrop}>Confirmar</button>
                </div>
              </div>
            </div>
          {/if}
          
          <div class="bg-white rounded-xl border border-gray-200 p-6 shadow-sm">
            <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
              <div>
                <label class="block text-sm font-semibold text-gray-700 mb-2">Nome Completo *</label>
                <input
                  type="text"
                  bind:value={formData.nome_completo}
                  placeholder="Digite o nome completo"
                  class="w-full px-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent transition-colors {validationErrors.nome_completo ? 'border-red-300 focus:ring-red-500' : ''}"
                />
                {#if validationErrors.nome_completo}
                  <p class="mt-1 text-sm text-red-600">{validationErrors.nome_completo}</p>
                {/if}
              </div>
              
              <div>
                <label class="block text-sm font-semibold text-gray-700 mb-2">Data de Nascimento *</label>
                <input
                  type="date"
                  bind:value={formData.data_nasc}
                  class="w-full px-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent transition-colors {validationErrors.data_nasc ? 'border-red-300 focus:ring-red-500' : ''}"
                />
                {#if validationErrors.data_nasc}
                  <p class="mt-1 text-sm text-red-600">{validationErrors.data_nasc}</p>
                {/if}
              </div>
              
              <div>
                <label class="block text-sm font-semibold text-gray-700 mb-2">Sexo *</label>
                <select
                  bind:value={formData.sexo}
                  class="w-full px-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent transition-colors {validationErrors.sexo ? 'border-red-300 focus:ring-red-500' : ''}"
                >
                  <option value="">Selecione o sexo</option>
                  <option value="masculino">Masculino</option>
                  <option value="feminino">Feminino</option>
                </select>
                {#if validationErrors.sexo}
                  <p class="mt-1 text-sm text-red-600">{validationErrors.sexo}</p>
                {/if}
              </div>
              
              <div>
                <label class="block text-sm font-semibold text-gray-700 mb-2">Estado Civil *</label>
                <select
                  bind:value={formData.estado_civil}
                  class="w-full px-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent transition-colors {validationErrors.estado_civil ? 'border-red-300 focus:ring-red-500' : ''}"
                >
                  <option value="">Selecione o estado civil</option>
                  <option value="solteiro">Solteiro(a)</option>
                  <option value="casado">Casado(a)</option>
                  <option value="divorciado">Divorciado(a)</option>
                  <option value="viuvo">Viúvo(a)</option>
                </select>
                {#if validationErrors.estado_civil}
                  <p class="mt-1 text-sm text-red-600">{validationErrors.estado_civil}</p>
                {/if}
              </div>
              
              <div>
                <label class="block text-sm font-semibold text-gray-700 mb-2">WhatsApp *</label>
                <input
                  type="tel"
                  value={formData.whatsapp}
                  on:input={handleWhatsAppChange}
                  placeholder="(11) 99999-9999"
                  maxlength="15"
                  class="w-full px-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent transition-colors {validationErrors.whatsapp ? 'border-red-300 focus:ring-red-500' : ''}"
                />
                {#if validationErrors.whatsapp}
                  <p class="mt-1 text-sm text-red-600">{validationErrors.whatsapp}</p>
                {/if}
              </div>
            </div>
          </div>
        </div>
      {/if}
      
      <!-- Step 2: Localização -->
      {#if currentStep === 2}
        <div class="space-y-8">
          <div class="text-center">
            <h2 class="text-2xl font-bold text-gray-900 mb-2">Localização</h2>
            <p class="text-gray-600">Informe a localização e edição do jovem</p>
          </div>
          
          <!-- Seção de Localização Geográfica -->
          <div class="bg-gradient-to-br from-blue-50 to-indigo-50 rounded-xl border border-blue-100 p-6">
            <h3 class="text-lg font-semibold text-gray-800 mb-4 flex items-center">
              <svg class="w-5 h-5 text-blue-600 mr-2" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M17.657 16.657L13.414 20.9a1.998 1.998 0 01-2.827 0l-4.244-4.243a8 8 0 1111.314 0z" />
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 11a3 3 0 11-6 0 3 3 0 016 0z" />
              </svg>
              Localização Geográfica
            </h3>
            
            <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
              <div>
                <label class="block text-sm font-semibold text-gray-700 mb-2">Estado *</label>
                <select
                  bind:value={formData.estado_id}
                  class="w-full px-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent transition-colors {validationErrors.estado_id ? 'border-red-300 focus:ring-red-500' : ''}"
                >
                  <option value="">Selecione o estado</option>
                  {#each $estados as estado}
                    <option value={estado.id}>{estado.nome}</option>
                  {/each}
                </select>
                {#if validationErrors.estado_id}
                  <p class="mt-1 text-sm text-red-600">{validationErrors.estado_id}</p>
                {/if}
              </div>
              
              <div>
                <label class="block text-sm font-semibold text-gray-700 mb-2">Bloco *</label>
                <select
                  bind:value={formData.bloco_id}
                  disabled={!formData.estado_id}
                  class="w-full px-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent transition-colors disabled:bg-gray-100 disabled:cursor-not-allowed {validationErrors.bloco_id ? 'border-red-300 focus:ring-red-500' : ''}"
                >
                  <option value="">Selecione o bloco</option>
                  {#each $blocos as bloco}
                    <option value={bloco.id}>{bloco.nome}</option>
                  {/each}
                </select>
                {#if validationErrors.bloco_id}
                  <p class="mt-1 text-sm text-red-600">{validationErrors.bloco_id}</p>
                {/if}
              </div>
              
              <div>
                <label class="block text-sm font-semibold text-gray-700 mb-2">Região *</label>
                <select
                  bind:value={formData.regiao_id}
                  disabled={!formData.bloco_id}
                  class="w-full px-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent transition-colors disabled:bg-gray-100 disabled:cursor-not-allowed {validationErrors.regiao_id ? 'border-red-300 focus:ring-red-500' : ''}"
                >
                  <option value="">Selecione a região</option>
                  {#each $regioes as regiao}
                    <option value={regiao.id}>{regiao.nome}</option>
                  {/each}
                </select>
                {#if validationErrors.regiao_id}
                  <p class="mt-1 text-sm text-red-600">{validationErrors.regiao_id}</p>
                {/if}
              </div>
              
              <div>
                <label class="block text-sm font-semibold text-gray-700 mb-2">Igreja *</label>
                <select
                  bind:value={formData.igreja_id}
                  disabled={!formData.regiao_id}
                  class="w-full px-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent transition-colors disabled:bg-gray-100 disabled:cursor-not-allowed {validationErrors.igreja_id ? 'border-red-300 focus:ring-red-500' : ''}"
                >
                  <option value="">Selecione a igreja</option>
                  {#each $igrejas as igreja}
                    <option value={igreja.id}>{igreja.nome}</option>
                  {/each}
                </select>
                {#if validationErrors.igreja_id}
                  <p class="mt-1 text-sm text-red-600">{validationErrors.igreja_id}</p>
                {/if}
              </div>
            </div>
          </div>
          
          <!-- Seção de Edição -->
          <div class="bg-gradient-to-br from-purple-50 to-pink-50 rounded-xl border border-purple-100 p-6">
            <h3 class="text-lg font-semibold text-gray-800 mb-4 flex items-center">
              <svg class="w-5 h-5 text-purple-600 mr-2" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 6.253v13m0-13C10.832 5.477 9.246 5 7.5 5S4.168 5.477 3 6.253v13C4.168 18.477 5.754 18 7.5 18s3.332.477 4.5 1.253m0-13C13.168 5.477 14.754 5 16.5 5c1.746 0 3.332.477 4.5 1.253v13C19.832 18.477 18.246 18 16.5 18c-1.746 0-3.332.477-4.5 1.253" />
              </svg>
              Edição do Evento
            </h3>
            
            <div class="max-w-md">
              <label class="block text-sm font-semibold text-gray-700 mb-2">Edição *</label>
              <select
                bind:value={formData.edicao_id}
                class="w-full px-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent transition-colors {validationErrors.edicao_id ? 'border-red-300 focus:ring-red-500' : ''}"
              >
                <option value="">Selecione a edição</option>
                {#each $edicoes as edicao}
                  <option value={edicao.id}>{edicao.nome}</option>
                {/each}
              </select>
              {#if validationErrors.edicao_id}
                <p class="mt-1 text-sm text-red-600">{validationErrors.edicao_id}</p>
              {/if}
            </div>
          </div>
        </div>
      {/if}
      
      <!-- Step 3: Informações Profissionais -->
      {#if currentStep === 3}
        <div class="space-y-8">
          <div class="text-center">
            <h2 class="text-2xl font-bold text-gray-900 mb-2">Informações Profissionais</h2>
            <p class="text-gray-600">Conte-nos sobre a situação profissional e educacional</p>
          </div>
          
          <!-- Seção de Trabalho -->
          <div class="bg-gradient-to-br from-green-50 to-emerald-50 rounded-xl border border-green-100 p-6">
            <h3 class="text-lg font-semibold text-gray-800 mb-4 flex items-center">
              <svg class="w-5 h-5 text-green-600 mr-2" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M21 13.255A23.931 23.931 0 0112 15c-3.183 0-6.22-.62-9-1.745M16 6V4a2 2 0 00-2-2h-4a2 2 0 00-2-2v2m8 0V6a2 2 0 012 2v6a2 2 0 01-2 2H6a2 2 0 01-2-2V8a2 2 0 012-2V6" />
              </svg>
              Situação Profissional
            </h3>
            
            <div class="space-y-4">
              <div class="flex items-center space-x-3 p-4 bg-white rounded-lg border border-green-200">
                <input
                  type="checkbox"
                  bind:checked={formData.trabalha}
                  class="w-5 h-5 text-green-600 border-gray-300 rounded focus:ring-green-500"
                />
                <label class="text-sm font-semibold text-gray-700 cursor-pointer">Trabalha atualmente</label>
              </div>
              
              {#if formData.trabalha}
                <div class="mt-4">
                  <label class="block text-sm font-semibold text-gray-700 mb-2">Local de Trabalho</label>
                  <input
                    type="text"
                    bind:value={formData.local_trabalho}
                    placeholder="Nome da empresa ou local"
                    class="w-full px-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-green-500 focus:border-transparent transition-colors"
                  />
                </div>
              {/if}
            </div>
          </div>
          
          <!-- Seção de Educação -->
          <div class="bg-gradient-to-br from-blue-50 to-indigo-50 rounded-xl border border-blue-100 p-6">
            <h3 class="text-lg font-semibold text-gray-800 mb-4 flex items-center">
              <svg class="w-5 h-5 text-blue-600 mr-2" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 14l9-5-9-5-9 5 9 5z" />
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 14l6.16-3.422a12.083 12.083 0 01.665 6.479A11.952 11.952 0 0012 20.055a11.952 11.952 0 00-6.824-2.998 12.083 12.083 0 01.665-6.479L12 14z" />
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 14l9-5-9-5-9 5 9 5zm0 0l6.16-3.422a12.083 12.083 0 01.665 6.479A11.952 11.952 0 0012 20.055a11.952 11.952 0 00-6.824-2.998 12.083 12.083 0 01.665-6.479L12 14z" />
              </svg>
              Formação Educacional
            </h3>
            
            <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
              <div>
                <label class="block text-sm font-semibold text-gray-700 mb-2">Escolaridade</label>
                <select
                  bind:value={formData.escolaridade}
                  class="w-full px-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent transition-colors"
                >
                  <option value="">Selecione a escolaridade</option>
                  <option value="fundamental_incompleto">Fundamental Incompleto</option>
                  <option value="fundamental_completo">Fundamental Completo</option>
                  <option value="medio_incompleto">Médio Incompleto</option>
                  <option value="medio_completo">Médio Completo</option>
                  <option value="superior_incompleto">Superior Incompleto</option>
                  <option value="superior_completo">Superior Completo</option>
                  <option value="pos_graduacao">Pós-graduação</option>
                </select>
              </div>
              
              <div>
                <label class="block text-sm font-semibold text-gray-700 mb-2">Formação</label>
                <input
                  type="text"
                  bind:value={formData.formacao}
                  placeholder="Curso ou área de formação"
                  class="w-full px-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent transition-colors"
                />
              </div>
            </div>
          </div>
          
          <!-- Seção de Dívidas -->
          <div class="bg-gradient-to-br from-yellow-50 to-orange-50 rounded-xl border border-yellow-100 p-6">
            <h3 class="text-lg font-semibold text-gray-800 mb-4 flex items-center">
              <svg class="w-5 h-5 text-yellow-600 mr-2" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8c-1.657 0-3 .895-3 2s1.343 2 3 2 3 .895 3 2-1.343 2-3 2m0-8c1.11 0 2.08.402 2.599 1M12 8V7m0 1v8m0 0v1m0-1c-1.11 0-2.08-.402-2.599-1" />
              </svg>
              Situação Financeira
            </h3>
            
            <div class="space-y-4">
              <div>
                <label class="block text-sm font-semibold text-gray-700 mb-3">Possui dívidas</label>
                <div class="flex space-x-6">
                  <label class="flex items-center p-3 bg-white rounded-lg border border-yellow-200 cursor-pointer hover:bg-yellow-50 transition-colors">
                    <input
                      type="radio"
                      bind:group={formData.tem_dividas}
                      value={true}
                      class="w-4 h-4 text-yellow-600 focus:ring-yellow-500 border-gray-300"
                    />
                    <span class="ml-2 text-sm font-medium text-gray-700">Sim</span>
                  </label>
                  <label class="flex items-center p-3 bg-white rounded-lg border border-yellow-200 cursor-pointer hover:bg-yellow-50 transition-colors">
                    <input
                      type="radio"
                      bind:group={formData.tem_dividas}
                      value={false}
                      class="w-4 h-4 text-yellow-600 focus:ring-yellow-500 border-gray-300"
                    />
                    <span class="ml-2 text-sm font-medium text-gray-700">Não</span>
                  </label>
                </div>
              </div>
              
              {#if formData.tem_dividas}
                <div class="mt-4">
                  <label class="block text-sm font-semibold text-gray-700 mb-2">Valor da Dívida (R$)</label>
                  <input
                    type="number"
                    bind:value={formData.valor_divida}
                    placeholder="Ex: 1500.00"
                    step="0.01"
                    class="w-full px-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-yellow-500 focus:border-transparent transition-colors"
                  />
                </div>
              {/if}
            </div>
          </div>
        </div>
      {/if}
      
      <!-- Step 4: Informações Espirituais -->
      {#if currentStep === 4}
        <div class="space-y-8">
          <div class="text-center">
            <h2 class="text-2xl font-bold text-gray-900 mb-2">Informações Espirituais</h2>
            <p class="text-gray-600">Conte-nos sobre a jornada espiritual do jovem</p>
          </div>
          
          <div class="bg-white rounded-xl border border-gray-200 p-6 shadow-sm">
            <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
              <div>
                <label class="block text-sm font-semibold text-gray-700 mb-2">Tempo na Igreja *</label>
                <input
                  type="text"
                  bind:value={formData.tempo_igreja}
                  placeholder="Ex: 5 anos, 2 meses"
                  class="w-full px-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent transition-colors {validationErrors.tempo_igreja ? 'border-red-300 focus:ring-red-500' : ''}"
                />
                {#if validationErrors.tempo_igreja}
                  <p class="mt-1 text-sm text-red-600">{validationErrors.tempo_igreja}</p>
                {/if}
              </div>
              
              <div>
                <label class="block text-sm font-semibold text-gray-700 mb-2">Condição *</label>
                <select
                  bind:value={formData.condicao}
                  class="w-full px-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent transition-colors {validationErrors.condicao ? 'border-red-300 focus:ring-red-500' : ''}"
                >
                  <option value="">Selecione a condição</option>
                  <option value="jovem_batizado_es">Jovem Batizado(a) ES</option>
                  <option value="cpo">CPO</option>
                  <option value="colaborador">Colaborador(a)</option>
                  <option value="obreiro">Obreiro(a)</option>
                  <option value="iburd">IBURD</option>
                  <option value="namorada">Namorada</option>
                  <option value="noiva">Noiva</option>
                </select>
                {#if validationErrors.condicao}
                  <p class="mt-1 text-sm text-red-600">{validationErrors.condicao}</p>
                {/if}
              </div>
            </div>
          </div>
          
          <!-- Seção de Batismos -->
          <div class="bg-gradient-to-br from-purple-50 to-pink-50 rounded-xl border border-purple-100 p-6">
            <h3 class="text-lg font-semibold text-gray-800 mb-4 flex items-center">
              <svg class="w-5 h-5 text-purple-600 mr-2" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4.318 6.318a4.5 4.5 0 000 6.364L12 20.364l7.682-7.682a4.5 4.5 0 00-6.364-6.364L12 7.636l-1.318-1.318a4.5 4.5 0 00-6.364 0z" />
              </svg>
              Batismos
            </h3>
            
            <div class="space-y-6">
              <!-- Batismo nas Águas -->
              <div class="bg-white rounded-lg p-4 border border-purple-100">
                <label class="flex items-center space-x-3 cursor-pointer">
                  <input
                    type="checkbox"
                    bind:checked={formData.batizado_aguas}
                    class="w-5 h-5 text-blue-600 bg-gray-100 border-gray-300 rounded focus:ring-blue-500 focus:ring-2"
                  />
                  <div class="flex items-center space-x-2">
                    <svg class="w-5 h-5 text-blue-600" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19.428 15.428a2 2 0 00-1.022-.547l-2.387-.477a6 6 0 00-3.86.517l-.318.158a6 6 0 01-3.86.517L6.05 15.21a2 2 0 00-1.806.547M8 4h8l-1 1v5.172a2 2 0 00.586 1.414l5 5c1.26 1.26.367 3.414-1.415 3.414H4.828c-1.782 0-2.674-2.154-1.414-3.414l5-5A2 2 0 009 10.172V5L8 4z" />
                    </svg>
                    <span class="text-sm font-semibold text-gray-700">Foi batizado nas águas</span>
                  </div>
                </label>
                
                {#if formData.batizado_aguas}
                  <div class="mt-4">
                    <label class="block text-sm font-medium text-gray-700 mb-2">Data do Batismo nas Águas</label>
                    <input
                      type="date"
                      bind:value={formData.data_batismo_aguas}
                      class="w-full px-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent transition-colors"
                    />
                  </div>
                {/if}
              </div>
              
              <!-- Batismo com Espírito Santo -->
              <div class="bg-white rounded-lg p-4 border border-purple-100">
                <label class="flex items-center space-x-3 cursor-pointer">
                  <input
                    type="checkbox"
                    bind:checked={formData.batizado_es}
                    class="w-5 h-5 text-blue-600 bg-gray-100 border-gray-300 rounded focus:ring-blue-500 focus:ring-2"
                  />
                  <div class="flex items-center space-x-2">
                    <svg class="w-5 h-5 text-purple-600" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 10V3L4 14h7v7l9-11h-7z" />
                    </svg>
                    <span class="text-sm font-semibold text-gray-700">Foi batizado com o Espírito Santo</span>
                  </div>
                </label>
                
                {#if formData.batizado_es}
                  <div class="mt-4">
                    <label class="block text-sm font-medium text-gray-700 mb-2">Data do Batismo com o Espírito Santo</label>
                    <input
                      type="date"
                      bind:value={formData.data_batismo_es}
                      class="w-full px-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent transition-colors"
                    />
                  </div>
                {/if}
              </div>
            </div>
          </div>
          
          <!-- Informações Adicionais -->
          <div class="bg-white rounded-xl border border-gray-200 p-6 shadow-sm">
            <h3 class="text-lg font-semibold text-gray-800 mb-4 flex items-center">
              <svg class="w-5 h-5 text-green-600 mr-2" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z" />
              </svg>
              Informações Adicionais
            </h3>
            
            <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
              <div>
                <label class="block text-sm font-semibold text-gray-700 mb-2">Tempo na Condição</label>
                <input
                  type="text"
                  bind:value={formData.tempo_condicao}
                  placeholder="Ex: 2 anos"
                  class="w-full px-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent transition-colors"
                />
              </div>
              
              <div>
                <label class="block text-sm font-semibold text-gray-700 mb-2">Responsabilidade na Igreja</label>
                <input
                  type="text"
                  bind:value={formData.responsabilidade_igreja}
                  placeholder="Ex: Obreiro, Colaborador, etc."
                  class="w-full px-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent transition-colors"
                />
              </div>
            </div>
          </div>
        </div>
      {/if}
      
      <!-- Step 5: Informações Adicionais -->
      {#if currentStep === 5}
        <div class="space-y-8">
          <div class="text-center">
            <h2 class="text-2xl font-bold text-gray-900 mb-2">Informações Adicionais</h2>
            <p class="text-gray-600">Complete as informações finais</p>
          </div>
          
          <!-- Seção de Experiência Ministerial -->
          <div class="bg-gradient-to-br from-blue-50 to-indigo-50 rounded-xl border border-blue-100 p-6">
            <h3 class="text-lg font-semibold text-gray-800 mb-4 flex items-center">
              <svg class="w-5 h-5 text-blue-600 mr-2" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M21 13.255A23.931 23.931 0 0112 15c-3.183 0-6.22-.62-9-1.745M16 6V4a2 2 0 00-2-2h-4a2 2 0 00-2-2v2m8 0V6a2 2 0 012 2v6a2 2 0 01-2 2H6a2 2 0 01-2-2V8a2 2 0 012-2V6" />
              </svg>
              Dados Relacionado a Obra de Deus
            </h3>
            
            <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
              <div class="bg-white rounded-lg p-4 border border-blue-100 min-w-0">
                <label class="flex items-center space-x-3 cursor-pointer">
                  <input
                    type="checkbox"
                    bind:checked={formData.disposto_servir}
                    class="w-5 h-5 text-blue-600 bg-gray-100 border-gray-300 rounded focus:ring-blue-500 focus:ring-2 flex-shrink-0"
                  />
                  <div class="flex items-center space-x-2 min-w-0 flex-1">
                    <svg class="w-5 h-5 text-green-600 flex-shrink-0" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z" />
                    </svg>
                    <span class="text-sm font-semibold text-gray-700 break-words">Disposto a servir em qualquer lugar?</span>
                  </div>
                </label>
              </div>
              
              <div class="bg-white rounded-lg p-4 border border-blue-100 min-w-0">
                <label class="flex items-center space-x-3 cursor-pointer">
                  <input
                    type="checkbox"
                    bind:checked={formData.ja_obra_altar}
                    class="w-5 h-5 text-blue-600 bg-gray-100 border-gray-300 rounded focus:ring-blue-500 focus:ring-2 flex-shrink-0"
                  />
                  <div class="flex items-center space-x-2 min-w-0 flex-1">
                    <svg class="w-5 h-5 text-purple-600 flex-shrink-0" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 21V5a2 2 0 00-2-2H7a2 2 0 00-2 2v16m14 0h2m-2 0h-5m-9 0H3m2 0h5M9 7h1m-1 4h1m4-4h1m-1 4h1m-5 10v-5a1 1 0 011-1h2a1 1 0 011 1v5m-4 0h4" />
                    </svg>
                    <span class="text-sm font-semibold text-gray-700 break-words">Já serviu no altar</span>
                  </div>
                </label>
              </div>
              
              <div class="bg-white rounded-lg p-4 border border-blue-100 min-w-0">
                <label class="flex items-center space-x-3 cursor-pointer">
                  <input
                    type="checkbox"
                    bind:checked={formData.ja_obreiro}
                    class="w-5 h-5 text-blue-600 bg-gray-100 border-gray-300 rounded focus:ring-blue-500 focus:ring-2 flex-shrink-0"
                  />
                  <div class="flex items-center space-x-2 min-w-0 flex-1">
                    <svg class="w-5 h-5 text-orange-600 flex-shrink-0" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M16 7a4 4 0 11-8 0 4 4 0 018 0zM12 14a7 7 0 00-7 7h14a7 7 0 00-7-7z" />
                    </svg>
                    <span class="text-sm font-semibold text-gray-700 break-words">Já foi obreiro antes?</span>
                  </div>
                </label>
              </div>
              
              <div class="bg-white rounded-lg p-4 border border-blue-100 min-w-0">
                <label class="flex items-center space-x-3 cursor-pointer">
                  <input
                    type="checkbox"
                    bind:checked={formData.ja_colaborador}
                    class="w-5 h-5 text-blue-600 bg-gray-100 border-gray-300 rounded focus:ring-blue-500 focus:ring-2 flex-shrink-0"
                  />
                  <div class="flex items-center space-x-2 min-w-0 flex-1">
                    <svg class="w-5 h-5 text-indigo-600 flex-shrink-0" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M17 20h5v-2a3 3 0 00-5.356-1.857M17 20H7m10 0v-2c0-.656-.126-1.283-.356-1.857M7 20H2v-2a3 3 0 015.356-1.857M7 20v-2c0-.656.126-1.283.356-1.857m0 0a5.002 5.002 0 019.288 0M15 7a3 3 0 11-6 0 3 3 0 016 0zm6 3a2 2 0 11-4 0 2 2 0 014 0zM7 10a2 2 0 11-4 0 2 2 0 014 0z" />
                    </svg>
                    <span class="text-sm font-semibold text-gray-700 break-words">Já foi colaborador antes?</span>
                  </div>
                </label>
              </div>
            </div>
          </div>
          
          <!-- Seção de Situação Atual -->
          <div class="bg-gradient-to-br from-yellow-50 to-orange-50 rounded-xl border border-yellow-100 p-6">
            <h3 class="text-lg font-semibold text-gray-800 mb-4 flex items-center">
              <svg class="w-5 h-5 text-yellow-600 mr-2" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z" />
              </svg>
              Situação Atual
            </h3>
            
            <div class="space-y-4">
              <div class="bg-white rounded-lg p-4 border border-yellow-100">
                <label class="flex items-center space-x-3 cursor-pointer">
                  <input
                    type="checkbox"
                    bind:checked={formData.afastado}
                    class="w-5 h-5 text-blue-600 bg-gray-100 border-gray-300 rounded focus:ring-blue-500 focus:ring-2"
                  />
                  <div class="flex items-center space-x-2">
                    <svg class="w-5 h-5 text-red-600" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-2.5L13.732 4c-.77-.833-1.964-.833-2.732 0L3.732 16.5c-.77.833.192 2.5 1.732 2.5z" />
                    </svg>
                    <span class="text-sm font-semibold text-gray-700">Já esteve afastado(a)?</span>
                  </div>
                </label>
                
                {#if formData.afastado}
                  <div class="mt-4 space-y-4">
                    <!-- Linha com as duas datas -->
                    <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
                      <div>
                        <label class="block text-sm font-medium text-gray-700 mb-2">Data do Afastamento</label>
                        <input
                          type="date"
                          bind:value={formData.data_afastamento}
                          class="w-full px-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent transition-colors"
                        />
                      </div>
                      
                      <div>
                        <label class="block text-sm font-medium text-gray-700 mb-2">Data de Retorno</label>
                        <input
                          type="date"
                          bind:value={formData.data_retorno}
                          class="w-full px-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent transition-colors"
                        />
                      </div>
                    </div>
                    
                    <!-- Campo de motivo em linha separada -->
                    <div>
                      <label class="block text-sm font-medium text-gray-700 mb-2">Motivo do Afastamento</label>
                      <input
                        type="text"
                        bind:value={formData.motivo_afastamento}
                        placeholder="Motivo do afastamento"
                        class="w-full px-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent transition-colors"
                      />
                    </div>
                  </div>
                {/if}
              </div>
            </div>
          </div>
          
          <!-- Seção de Família -->
          <div class="bg-gradient-to-br from-green-50 to-emerald-50 rounded-xl border border-green-100 p-6">
            <h3 class="text-lg font-semibold text-gray-800 mb-4 flex items-center">
              <svg class="w-5 h-5 text-green-600 mr-2" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4.318 6.318a4.5 4.5 0 000 6.364L12 20.364l7.682-7.682a4.5 4.5 0 00-6.364-6.364L12 7.636l-1.318-1.318a4.5 4.5 0 00-6.364 0z" />
              </svg>
              Família
            </h3>
            
            <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
              <div class="bg-white rounded-lg p-4 border border-green-100 min-w-0">
                <label class="flex items-center space-x-3 cursor-pointer">
                  <input
                    type="checkbox"
                    bind:checked={formData.pais_na_igreja}
                    class="w-5 h-5 text-blue-600 bg-gray-100 border-gray-300 rounded focus:ring-blue-500 focus:ring-2 flex-shrink-0"
                  />
                  <div class="flex items-center space-x-2 min-w-0 flex-1">
                    <svg class="w-5 h-5 text-green-600 flex-shrink-0" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M17 20h5v-2a3 3 0 00-5.356-1.857M17 20H7m10 0v-2c0-.656-.126-1.283-.356-1.857M7 20H2v-2a3 3 0 015.356-1.857M7 20v-2c0-.656.126-1.283.356-1.857m0 0a5.002 5.002 0 019.288 0M15 7a3 3 0 11-6 0 3 3 0 016 0zm6 3a2 2 0 11-4 0 2 2 0 014 0zM7 10a2 2 0 11-4 0 2 2 0 014 0z" />
                    </svg>
                    <span class="text-sm font-semibold text-gray-700 break-words">Pais estão na igreja?</span>
                  </div>
                </label>
              </div>
              
              <div class="bg-white rounded-lg p-4 border border-green-100 min-w-0">
                <label class="flex items-center space-x-3 cursor-pointer">
                  <input
                    type="checkbox"
                    bind:checked={formData.familiares_igreja}
                    class="w-5 h-5 text-blue-600 bg-gray-100 border-gray-300 rounded focus:ring-blue-500 focus:ring-2 flex-shrink-0"
                  />
                  <div class="flex items-center space-x-2 min-w-0 flex-1">
                    <svg class="w-5 h-5 text-green-600 flex-shrink-0" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4.318 6.318a4.5 4.5 0 000 6.364L12 20.364l7.682-7.682a4.5 4.5 0 00-6.364-6.364L12 7.636l-1.318-1.318a4.5 4.5 0 00-6.364 0z" />
                    </svg>
                    <span class="text-sm font-semibold text-gray-700 break-words">Tem familiares na igreja?</span>
                  </div>
                </label>
              </div>
            </div>
          </div>
          
          <!-- Seção de Aspirações -->
          <div class="bg-gradient-to-br from-purple-50 to-pink-50 rounded-xl border border-purple-100 p-6">
            <h3 class="text-lg font-semibold text-gray-800 mb-4 flex items-center">
              <svg class="w-5 h-5 text-purple-600 mr-2" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 10V3L4 14h7v7l9-11h-7z" />
              </svg>
              Vocação
            </h3>
            
            <div class="bg-white rounded-lg p-4 border border-purple-100">
              <label class="flex items-center space-x-3 cursor-pointer">
                <input
                  type="checkbox"
                  bind:checked={formData.deseja_altar}
                  class="w-5 h-5 text-blue-600 bg-gray-100 border-gray-300 rounded focus:ring-blue-500 focus:ring-2"
                />
                <div class="flex items-center space-x-2">
                  <svg class="w-5 h-5 text-purple-600" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 21V5a2 2 0 00-2-2H7a2 2 0 00-2 2v16m14 0h2m-2 0h-5m-9 0H3m2 0h5M9 7h1m-1 4h1m4-4h1m-1 4h1m-5 10v-5a1 1 0 011-1h2a1 1 0 011 1v5m-4 0h4" />
                  </svg>
                  <span class="text-sm font-semibold text-gray-700">Tem disposição para o Altar?</span>
                </div>
              </label>
            </div>
          </div>
          
          <!-- Seção de Observações e Testemunho -->
          <div class="bg-white rounded-xl border border-gray-200 p-6 shadow-sm">
            <h3 class="text-lg font-semibold text-gray-800 mb-4 flex items-center">
              <svg class="w-5 h-5 text-gray-600 mr-2" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M11 5H6a2 2 0 00-2 2v11a2 2 0 002 2h11a2 2 0 002-2v-5m-1.414-9.414a2 2 0 112.828 2.828L11.828 15H9v-2.828l8.586-8.586z" />
              </svg>
              Observações e Testemunho
            </h3>
            
            <div class="space-y-6">
              <div>
                <label class="block text-sm font-semibold text-gray-700 mb-2">Observações Geral</label>
                <textarea
                  bind:value={formData.observacao}
                  rows="4"
                  class="w-full px-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent transition-colors resize-none"
                  placeholder="Observações gerais sobre o jovem"
                ></textarea>
              </div>
              
              <div>
                <label class="block text-sm font-semibold text-gray-700 mb-2">Testemunho</label>
                <textarea
                  bind:value={formData.testemunho}
                  rows="5"
                  class="w-full px-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent transition-colors resize-none"
                  placeholder="Testemunho pessoal do jovem"
                ></textarea>
              </div>
            </div>
          </div>
        </div>
        
        <!-- Seção IntelliMen -->
        <div class="bg-white rounded-lg shadow-sm border border-gray-200 p-6">
          <h3 class="text-lg font-semibold text-gray-900 mb-6 flex items-center">
            <svg class="w-6 h-6 text-blue-600 mr-2" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9.663 17h4.673M12 3v1m6.364 1.636l-.707.707M21 12h-1M4 12H3m3.343-5.657l-.707-.707m2.828 9.9a5 5 0 117.072 0l-.548.547A3.374 3.374 0 0014 18.469V19a2 2 0 11-4 0v-.531c0-.895-.356-1.754-.988-2.386l-.548-.547z" />
            </svg>
            Projeto IntelliMen
          </h3>
          
          <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
            <!-- Formado no IntelliMen -->
            <div>
              <label class="block text-sm font-medium text-gray-700 mb-3">Formado no IntelliMen</label>
              <div class="flex space-x-4">
                <label class="flex items-center">
                  <input
                    type="radio"
                    bind:group={formData.formado_intellimen}
                    value={true}
                    class="h-4 w-4 text-blue-600 focus:ring-blue-500 border-gray-300"
                  />
                  <span class="ml-2 text-sm text-gray-700">Sim</span>
                </label>
                <label class="flex items-center">
                  <input
                    type="radio"
                    bind:group={formData.formado_intellimen}
                    value={false}
                    class="h-4 w-4 text-blue-600 focus:ring-blue-500 border-gray-300"
                  />
                  <span class="ml-2 text-sm text-gray-700">Não</span>
                </label>
              </div>
            </div>
            
            <!-- Fazendo os Desafios -->
            <div>
              <label class="block text-sm font-medium text-gray-700 mb-3">Está Fazendo os Desafios</label>
              <div class="flex space-x-4">
                <label class="flex items-center">
                  <input
                    type="radio"
                    bind:group={formData.fazendo_desafios}
                    value={true}
                    class="h-4 w-4 text-blue-600 focus:ring-blue-500 border-gray-300"
                  />
                  <span class="ml-2 text-sm text-gray-700">Sim</span>
                </label>
                <label class="flex items-center">
                  <input
                    type="radio"
                    bind:group={formData.fazendo_desafios}
                    value={false}
                    class="h-4 w-4 text-blue-600 focus:ring-blue-500 border-gray-300"
                  />
                  <span class="ml-2 text-sm text-gray-700">Não</span>
                </label>
              </div>
            </div>
            
            <!-- Qual Desafio (condicional) -->
            {#if formData.fazendo_desafios}
              <div class="md:col-span-2">
                <Input
                  label="Qual Desafio?"
                  type="text"
                  bind:value={formData.qual_desafio}
                  placeholder="Ex: Desafio #12"
                />
              </div>
            {/if}
          </div>
        </div>
      {/if}
      
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
      
      <!-- Navigation Buttons -->
      <div class="flex justify-between pt-6 border-t border-gray-200">
        <Button
          variant="outline"
          on:click={prevStep}
          disabled={currentStep === 1}
        >
          <svg class="w-5 h-5 mr-2" fill="none" viewBox="0 0 24 24" stroke="currentColor">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M10 19l-7-7m0 0l7-7m-7 7h18" />
          </svg>
          Anterior
        </Button>
        
        {#if currentStep < totalSteps}
          <Button
            variant="primary"
            on:click={nextStep}
          >
            Próximo
            <svg class="w-5 h-5 ml-2" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M14 5l7 7m0 0l-7 7m7-7H3" />
            </svg>
          </Button>
        {:else}
          <Button
            variant="primary"
            on:click={handleSubmit}
            loading={isLoading}
            disabled={isLoading}
          >
            {isLoading ? 'Salvando...' : 'Finalizar Cadastro'}
          </Button>
        {/if}
      </div>
    {/if}
  </Card>
</div>
