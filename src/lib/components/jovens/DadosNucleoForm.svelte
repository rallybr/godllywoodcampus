<script>
  import { onMount, createEventDispatcher } from 'svelte';
  import { loadDadosNucleo, saveDadosNucleo, detectVideoPlatform, getEmbedUrl } from '$lib/stores/dados-nucleo';
  import { userProfile } from '$lib/stores/auth';
  import { getUserLevelName } from '$lib/stores/niveis-acesso';
  import { supabase } from '$lib/utils/supabase';
  import Button from '$lib/components/ui/Button.svelte';
  import Card from '$lib/components/ui/Card.svelte';
  
  const dispatch = createEventDispatcher();
  
  export let jovemId;
  export let usuarioId;
  export let onSave = () => {};
  
  let dados = {
    faz_nucleo: null,
    ja_fez_nucleo: null,
    dias_semana: [],
    ha_quanto_tempo: '',
    foi_voce_que_iniciou: null,
    media_pessoas: null,
    foto_1: '',
    foto_2: '',
    foto_3: '',
    foto_4: '',
    foto_5: '',
    video_link: '',
    video_plataforma: '',
    tem_obreiros: null,
    quantos_obreiros: null,
    alguem_ajuda: null,
    quem_ajuda: '',
    quantas_pessoas_vao_igreja: null,
    maior_experiencia: '',
    observacao_geral: ''
  };
  
  // Estados para upload de fotos
  let uploadingPhotos = Array(5).fill(false);
  let photoFiles = Array(5).fill(null);
  
  // Estado para URL de incorporação
  let embedUrl = null;
  
  // Estados para preview de foto
  let showPhotoPreview = false;
  let previewPhotoUrl = '';
  let previewPhotoIndex = 0;
  
  let loading = false;
  let saving = false;
  let error = null;
  let success = null;
  
  const diasSemana = [
    { id: 'segunda', label: 'Segunda-feira' },
    { id: 'terca', label: 'Terça-feira' },
    { id: 'quarta', label: 'Quarta-feira' },
    { id: 'quinta', label: 'Quinta-feira' },
    { id: 'sexta', label: 'Sexta-feira' },
    { id: 'sabado', label: 'Sábado' },
    { id: 'domingo', label: 'Domingo' }
  ];
  
  onMount(async () => {
    await carregarDados();
  });
  
  async function carregarDados() {
    loading = true;
    error = null;
    
    try {
      const dadosExistentes = await loadDadosNucleo(jovemId);
      if (dadosExistentes) {
        dados = {
          ...dados,
          ...dadosExistentes,
          dias_semana: dadosExistentes.dias_semana || []
        };
      }
    } catch (err) {
      console.error('Erro ao carregar dados do núcleo:', err);
      error = err.message || 'Erro ao carregar dados do núcleo';
    } finally {
      loading = false;
    }
  }
  
  async function salvarDados() {
    saving = true;
    error = null;
    success = null;
    
    try {
      console.log('🔍 DEBUG - salvarDados iniciado');
      console.log('🔍 DEBUG - jovemId:', jovemId);
      console.log('🔍 DEBUG - dados antes de salvar:', dados);
      
      // Detectar plataforma do vídeo se houver link
      if (dados.video_link) {
        dados.video_plataforma = detectVideoPlatform(dados.video_link);
        console.log('🔍 DEBUG - Plataforma do vídeo detectada:', dados.video_plataforma);
      }
      
      console.log('🔍 DEBUG - Chamando saveDadosNucleo...');
      const result = await saveDadosNucleo(jovemId, dados);
      console.log('🔍 DEBUG - saveDadosNucleo retornou:', result);
      
      success = 'Dados do núcleo salvos com sucesso!';
      
      // Notificar componente pai
      onSave();
      dispatch('save', dados);
      
    } catch (err) {
      console.error('Erro ao salvar dados do núcleo:', err);
      error = err.message || 'Erro ao salvar dados do núcleo';
    } finally {
      saving = false;
    }
  }
  
  function toggleDiaSemana(dia) {
    if (dados.dias_semana.includes(dia)) {
      dados.dias_semana = dados.dias_semana.filter(d => d !== dia);
    } else {
      dados.dias_semana = [...dados.dias_semana, dia];
    }
  }
  
  function handleFazNucleoChange(value) {
    dados.faz_nucleo = value;
    if (value === false) {
      // Se não faz núcleo, limpar campos relacionados
      dados.dias_semana = [];
      dados.ha_quanto_tempo = '';
      dados.foi_voce_que_iniciou = null;
      dados.media_pessoas = null;
      dados.foto_1 = '';
      dados.foto_2 = '';
      dados.foto_3 = '';
      dados.foto_4 = '';
      dados.foto_5 = '';
      dados.video_link = '';
      dados.video_plataforma = '';
      dados.tem_obreiros = null;
      dados.quantos_obreiros = null;
      dados.alguem_ajuda = null;
      dados.quem_ajuda = '';
      dados.quantas_pessoas_vao_igreja = null;
      dados.maior_experiencia = '';
    }
  }
  
  function handleTemObreirosChange(value) {
    dados.tem_obreiros = value;
    if (value === false) {
      dados.quantos_obreiros = null;
    }
  }
  
  function handleAlguemAjudaChange(value) {
    dados.alguem_ajuda = value;
    if (value === false) {
      dados.quem_ajuda = '';
    }
  }
  
  // Função simplificada para obter URL de incorporação do vídeo
  function getVideoEmbedUrl() {
    if (!dados.video_link || !dados.video_plataforma) {
      return null;
    }
    
    // Abordagem simplificada para YouTube
    if (dados.video_plataforma === 'youtube') {
      let videoId = null;
      
      // Extrair ID do vídeo com regex mais robusta
      const patterns = [
        /(?:youtube\.com\/watch\?v=)([^&\n?#]+)/,
        /(?:youtu\.be\/)([^&\n?#]+)/,
        /(?:youtube\.com\/embed\/)([^&\n?#]+)/,
        /(?:youtube\.com\/v\/)([^&\n?#]+)/
      ];
      
      for (const pattern of patterns) {
        const match = dados.video_link.match(pattern);
        if (match) {
          videoId = match[1];
          break;
        }
      }
      
      if (videoId) {
        return `https://www.youtube.com/embed/${videoId}`;
      }
    }
    
    // Para outras plataformas, usar a função original
    return getEmbedUrl(dados.video_link, dados.video_plataforma);
  }
  
  
  // Função para detectar plataforma do vídeo automaticamente
  function detectVideoPlatformAuto(link) {
    if (!link) return null;
    return detectVideoPlatform(link);
  }
  
  // Função para upload de foto
  async function uploadPhoto(file, index) {
    if (!file) return;
    
    uploadingPhotos[index] = true;
    try {
      // Criar preview local da imagem
      const reader = new FileReader();
      
      // Aguardar o FileReader terminar e manter o preview
      await new Promise((resolve) => {
        reader.onload = (e) => {
          dados[`foto_${index + 1}`] = e.target.result;
          resolve();
        };
        reader.readAsDataURL(file);
      });
      
      // Upload real para Supabase Storage
      const fileName = `nucleo_${$userProfile.id}_${index + 1}_${Date.now()}.${file.name.split('.').pop()}`;
      const filePath = `fotos_nucleos/${fileName}`;
      
      const { data: uploadData, error: uploadError } = await supabase.storage
        .from('fotos_nucleos')
        .upload(filePath, file, {
          cacheControl: '3600',
          upsert: false
        });
      
      if (uploadError) {
        console.error('Erro no upload para Supabase:', uploadError);
        throw uploadError;
      }
      
      // Obter URL pública da imagem
      const { data: { publicUrl } } = supabase.storage
        .from('fotos_nucleos')
        .getPublicUrl(filePath);
      
      // Atualizar com a URL real do Supabase
      dados[`foto_${index + 1}`] = publicUrl;
      photoFiles[index] = file;
      
      console.log('✅ Foto enviada com sucesso:', publicUrl);
      
    } catch (err) {
      console.error('Erro ao fazer upload da foto:', err);
      error = 'Erro ao fazer upload da foto: ' + (err.message || 'Erro desconhecido');
    } finally {
      uploadingPhotos[index] = false;
    }
  }
  
  // Função para remover foto
  function removePhoto(index) {
    dados[`foto_${index + 1}`] = '';
    photoFiles[index] = null;
  }
  
  // Função para abrir preview da foto
  function openPhotoPreview(photoUrl, index) {
    previewPhotoUrl = photoUrl;
    previewPhotoIndex = index;
    showPhotoPreview = true;
  }
  
  // Função para fechar preview da foto
  function closePhotoPreview() {
    showPhotoPreview = false;
    previewPhotoUrl = '';
    previewPhotoIndex = 0;
  }
</script>

<!-- Renderizar para usuário autenticado (a página já restringe acesso) -->
{#if $userProfile}
  <div class="space-y-6">
    <!-- Mensagens -->
    {#if error}
      <div class="bg-gradient-to-r from-red-50 to-pink-50 border border-red-200 rounded-xl p-4 sm:p-6 shadow-lg">
        <div class="flex items-center">
          <div class="w-10 h-10 bg-red-100 rounded-full flex items-center justify-center mr-4">
            <svg class="w-6 h-6 text-red-600" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8v4m0 4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
            </svg>
          </div>
          <div>
            <h3 class="text-lg font-semibold text-red-800 mb-1">Erro</h3>
            <p class="text-red-700">{error}</p>
          </div>
        </div>
      </div>
    {/if}
    
    {#if success}
      <div class="bg-gradient-to-r from-green-50 to-emerald-50 border border-green-200 rounded-xl p-4 sm:p-6 shadow-lg">
        <div class="flex items-center">
          <div class="w-10 h-10 bg-green-100 rounded-full flex items-center justify-center mr-4">
            <svg class="w-6 h-6 text-green-600" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z" />
            </svg>
          </div>
          <div>
            <h3 class="text-lg font-semibold text-green-800 mb-1">Sucesso</h3>
            <p class="text-green-700">{success}</p>
          </div>
        </div>
      </div>
    {/if}
    
    {#if loading}
      <div class="bg-gradient-to-br from-blue-50 via-white to-indigo-50 rounded-2xl shadow-xl border border-blue-100 p-8 text-center">
        <div class="w-16 h-16 bg-gradient-to-br from-blue-500 to-indigo-500 rounded-full flex items-center justify-center mx-auto mb-6">
          <div class="w-8 h-8 border-4 border-white border-t-transparent rounded-full animate-spin"></div>
        </div>
        <h3 class="text-xl font-bold text-gray-900 mb-2">Carregando dados do núcleo</h3>
        <p class="text-gray-600">Aguarde enquanto carregamos suas informações...</p>
      </div>
    {:else}
      <form on:submit|preventDefault={salvarDados} class="space-y-6">
        <!-- Pergunta Principal -->
        <div class="bg-gradient-to-br from-blue-50 via-white to-indigo-50 rounded-2xl shadow-xl border border-blue-100 p-4 sm:p-6 lg:p-8 relative overflow-hidden">
          <!-- Decorative background elements -->
          <div class="absolute top-0 right-0 w-32 h-32 bg-gradient-to-br from-blue-200 to-indigo-200 rounded-full -translate-y-16 translate-x-16 opacity-20"></div>
          <div class="absolute bottom-0 left-0 w-24 h-24 bg-gradient-to-tr from-indigo-200 to-blue-200 rounded-full translate-y-12 -translate-x-12 opacity-20"></div>
          
          <div class="relative z-10">
            <div class="flex items-center mb-6">
              <div class="w-10 h-10 sm:w-12 sm:h-12 bg-gradient-to-br from-blue-500 to-indigo-500 rounded-xl shadow-lg mr-4">
                <svg class="w-6 h-6 sm:w-7 sm:h-7 text-white mx-auto mt-1.5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9.663 17h4.673M12 3v1m6.364 1.636l-.707.707M21 12h-1M4 12H3m3.343-5.657l-.707-.707m2.828 9.9a5 5 0 117.072 0l-.548.547A3.374 3.374 0 0014 18.469V19a2 2 0 11-4 0v-.531c0-.895-.356-1.754-.988-2.386l-.548-.547z" />
                </svg>
              </div>
              <h3 class="text-xl sm:text-2xl font-bold bg-gradient-to-r from-blue-600 to-indigo-600 bg-clip-text text-transparent">
                Faz núcleo de oração?
              </h3>
            </div>
            
            <div class="grid grid-cols-1 sm:grid-cols-2 gap-4">
              <label class="flex items-center p-4 bg-white/70 backdrop-blur-sm rounded-xl border border-white/50 shadow-lg hover:shadow-xl transition-all duration-300 cursor-pointer group">
                <input
                  type="radio"
                  bind:group={dados.faz_nucleo}
                  value={true}
                  on:change={() => handleFazNucleoChange(true)}
                  class="w-5 h-5 text-blue-600 border-gray-300 focus:ring-blue-500 focus:ring-2"
                />
                <div class="ml-4">
                  <div class="flex items-center">
                    <svg class="w-6 h-6 text-green-600 mr-2" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7" />
                    </svg>
                    <span class="text-lg font-semibold text-gray-800 group-hover:text-blue-600 transition-colors">Sim</span>
                  </div>
                  <p class="text-sm text-gray-600 mt-1">Atualmente participo de um núcleo</p>
                </div>
              </label>
              
              <label class="flex items-center p-4 bg-white/70 backdrop-blur-sm rounded-xl border border-white/50 shadow-lg hover:shadow-xl transition-all duration-300 cursor-pointer group">
                <input
                  type="radio"
                  bind:group={dados.faz_nucleo}
                  value={false}
                  on:change={() => handleFazNucleoChange(false)}
                  class="w-5 h-5 text-blue-600 border-gray-300 focus:ring-blue-500 focus:ring-2"
                />
                <div class="ml-4">
                  <div class="flex items-center">
                    <svg class="w-6 h-6 text-red-600 mr-2" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12" />
                    </svg>
                    <span class="text-lg font-semibold text-gray-800 group-hover:text-red-600 transition-colors">Não</span>
                  </div>
                  <p class="text-sm text-gray-600 mt-1">Não participo de um núcleo atualmente</p>
                </div>
              </label>
            </div>
          </div>
        </div>
        
        <!-- Se não faz núcleo, perguntar se já fez -->
        {#if dados.faz_nucleo === false}
          <div class="bg-gradient-to-br from-amber-50 via-white to-yellow-50 rounded-2xl shadow-xl border border-amber-100 p-4 sm:p-6 lg:p-8 relative overflow-hidden">
            <!-- Decorative background elements -->
            <div class="absolute top-0 right-0 w-32 h-32 bg-gradient-to-br from-amber-200 to-yellow-200 rounded-full -translate-y-16 translate-x-16 opacity-20"></div>
            <div class="absolute bottom-0 left-0 w-24 h-24 bg-gradient-to-tr from-yellow-200 to-amber-200 rounded-full translate-y-12 -translate-x-12 opacity-20"></div>
            
            <div class="relative z-10">
              <div class="flex items-center mb-6">
                <div class="w-10 h-10 sm:w-12 sm:h-12 bg-gradient-to-br from-amber-500 to-yellow-500 rounded-xl shadow-lg mr-4">
                  <svg class="w-6 h-6 sm:w-7 sm:h-7 text-white mx-auto mt-1.5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z" />
                  </svg>
                </div>
                <h3 class="text-xl sm:text-2xl font-bold bg-gradient-to-r from-amber-600 to-yellow-600 bg-clip-text text-transparent">
                  Já fez núcleo de oração?
                </h3>
              </div>
              
              <div class="grid grid-cols-1 sm:grid-cols-2 gap-4">
                <label class="flex items-center p-4 bg-white/70 backdrop-blur-sm rounded-xl border border-white/50 shadow-lg hover:shadow-xl transition-all duration-300 cursor-pointer group">
                  <input
                    type="radio"
                    bind:group={dados.ja_fez_nucleo}
                    value={true}
                    class="w-5 h-5 text-amber-600 border-gray-300 focus:ring-amber-500 focus:ring-2"
                  />
                  <div class="ml-4">
                    <div class="flex items-center">
                      <svg class="w-6 h-6 text-green-600 mr-2" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7" />
                      </svg>
                      <span class="text-lg font-semibold text-gray-800 group-hover:text-amber-600 transition-colors">Sim</span>
                    </div>
                    <p class="text-sm text-gray-600 mt-1">Já participei de um núcleo anteriormente</p>
                  </div>
                </label>
                
                <label class="flex items-center p-4 bg-white/70 backdrop-blur-sm rounded-xl border border-white/50 shadow-lg hover:shadow-xl transition-all duration-300 cursor-pointer group">
                  <input
                    type="radio"
                    bind:group={dados.ja_fez_nucleo}
                    value={false}
                    class="w-5 h-5 text-amber-600 border-gray-300 focus:ring-amber-500 focus:ring-2"
                  />
                  <div class="ml-4">
                    <div class="flex items-center">
                      <svg class="w-6 h-6 text-red-600 mr-2" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12" />
                      </svg>
                      <span class="text-lg font-semibold text-gray-800 group-hover:text-red-600 transition-colors">Não</span>
                    </div>
                    <p class="text-sm text-gray-600 mt-1">Nunca participei de um núcleo</p>
                  </div>
                </label>
              </div>
            </div>
          </div>
        {/if}
        
        <!-- Campos quando faz núcleo -->
        {#if dados.faz_nucleo === true}
          <!-- Dias da Semana -->
          <div class="bg-gradient-to-br from-purple-50 via-white to-pink-50 rounded-2xl shadow-xl border border-purple-100 p-4 sm:p-6 lg:p-8 relative overflow-hidden">
            <!-- Decorative background elements -->
            <div class="absolute top-0 right-0 w-32 h-32 bg-gradient-to-br from-purple-200 to-pink-200 rounded-full -translate-y-16 translate-x-16 opacity-20"></div>
            <div class="absolute bottom-0 left-0 w-24 h-24 bg-gradient-to-tr from-pink-200 to-purple-200 rounded-full translate-y-12 -translate-x-12 opacity-20"></div>
            
            <div class="relative z-10">
              <div class="flex items-center mb-6">
                <div class="w-10 h-10 sm:w-12 sm:h-12 bg-gradient-to-br from-purple-500 to-pink-500 rounded-xl shadow-lg mr-4">
                  <svg class="w-6 h-6 sm:w-7 sm:h-7 text-white mx-auto mt-1.5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M8 7V3m8 4V3m-9 8h10M5 21h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v12a2 2 0 002 2z" />
                  </svg>
                </div>
                <h3 class="text-xl sm:text-2xl font-bold bg-gradient-to-r from-purple-600 to-pink-600 bg-clip-text text-transparent">
                  Quais dias da semana?
                </h3>
              </div>
              
              <div class="grid grid-cols-2 sm:grid-cols-3 lg:grid-cols-4 gap-3 sm:gap-4">
                {#each diasSemana as dia}
                  <label class="flex items-center p-3 sm:p-4 bg-white/70 backdrop-blur-sm rounded-xl border border-white/50 shadow-lg hover:shadow-xl transition-all duration-300 cursor-pointer group">
                    <input
                      type="checkbox"
                      checked={dados.dias_semana.includes(dia.id)}
                      on:change={() => toggleDiaSemana(dia.id)}
                      class="w-5 h-5 text-purple-600 border-gray-300 rounded focus:ring-purple-500 focus:ring-2"
                    />
                    <div class="ml-3">
                      <span class="text-sm sm:text-base font-semibold text-gray-800 group-hover:text-purple-600 transition-colors">{dia.label}</span>
                    </div>
                  </label>
                {/each}
              </div>
            </div>
          </div>
          
          <!-- Há quanto tempo -->
          <div class="bg-gradient-to-br from-blue-50 via-white to-cyan-50 rounded-2xl shadow-xl border border-blue-100 p-4 sm:p-6 lg:p-8 relative overflow-hidden">
            <!-- Decorative background elements -->
            <div class="absolute top-0 right-0 w-32 h-32 bg-gradient-to-br from-blue-200 to-cyan-200 rounded-full -translate-y-16 translate-x-16 opacity-20"></div>
            <div class="absolute bottom-0 left-0 w-24 h-24 bg-gradient-to-tr from-cyan-200 to-blue-200 rounded-full translate-y-12 -translate-x-12 opacity-20"></div>
            
            <div class="relative z-10">
              <div class="flex items-center mb-6">
                <div class="w-10 h-10 sm:w-12 sm:h-12 bg-gradient-to-br from-blue-500 to-cyan-500 rounded-xl shadow-lg mr-4">
                  <svg class="w-6 h-6 sm:w-7 sm:h-7 text-white mx-auto mt-1.5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z" />
                  </svg>
                </div>
                <h3 class="text-xl sm:text-2xl font-bold bg-gradient-to-r from-blue-600 to-cyan-600 bg-clip-text text-transparent">
                  Há quanto tempo faz núcleo?
                </h3>
              </div>
              
              <div class="bg-white/70 backdrop-blur-sm rounded-xl p-4 sm:p-6 border border-white/50 shadow-lg">
                <label for="ha_quanto_tempo" class="block text-sm font-semibold text-gray-800 mb-3">
                  Tempo de participação no núcleo
                </label>
                <input
                  type="text"
                  id="ha_quanto_tempo"
                  bind:value={dados.ha_quanto_tempo}
                  placeholder="Ex: 2 anos, 6 meses, etc."
                  class="w-full px-4 py-3 border border-gray-300 rounded-xl focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-blue-500 transition-all duration-300 text-gray-800 placeholder-gray-500"
                />
              </div>
            </div>
          </div>
          
          <!-- Foi você que iniciou -->
          <div class="bg-gradient-to-br from-green-50 via-white to-emerald-50 rounded-2xl shadow-xl border border-green-100 p-4 sm:p-6 lg:p-8 relative overflow-hidden">
            <!-- Decorative background elements -->
            <div class="absolute top-0 right-0 w-32 h-32 bg-gradient-to-br from-green-200 to-emerald-200 rounded-full -translate-y-16 translate-x-16 opacity-20"></div>
            <div class="absolute bottom-0 left-0 w-24 h-24 bg-gradient-to-tr from-emerald-200 to-green-200 rounded-full translate-y-12 -translate-x-12 opacity-20"></div>
            
            <div class="relative z-10">
              <div class="flex items-center mb-6">
                <div class="w-10 h-10 sm:w-12 sm:h-12 bg-gradient-to-br from-green-500 to-emerald-500 rounded-xl shadow-lg mr-4">
                  <svg class="w-6 h-6 sm:w-7 sm:h-7 text-white mx-auto mt-1.5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 10V3L4 14h7v7l9-11h-7z" />
                  </svg>
                </div>
                <h3 class="text-xl sm:text-2xl font-bold bg-gradient-to-r from-green-600 to-emerald-600 bg-clip-text text-transparent">
                  Foi você que iniciou o trabalho?
                </h3>
              </div>
              
              <div class="grid grid-cols-1 sm:grid-cols-2 gap-4">
                <label class="flex items-center p-4 bg-white/70 backdrop-blur-sm rounded-xl border border-white/50 shadow-lg hover:shadow-xl transition-all duration-300 cursor-pointer group">
                  <input
                    type="radio"
                    bind:group={dados.foi_voce_que_iniciou}
                    value={true}
                    class="w-5 h-5 text-green-600 border-gray-300 focus:ring-green-500 focus:ring-2"
                  />
                  <div class="ml-4">
                    <div class="flex items-center">
                      <svg class="w-6 h-6 text-green-600 mr-2" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7" />
                      </svg>
                      <span class="text-lg font-semibold text-gray-800 group-hover:text-green-600 transition-colors">Sim</span>
                    </div>
                    <p class="text-sm text-gray-600 mt-1">Eu iniciei este núcleo</p>
                  </div>
                </label>
                
                <label class="flex items-center p-4 bg-white/70 backdrop-blur-sm rounded-xl border border-white/50 shadow-lg hover:shadow-xl transition-all duration-300 cursor-pointer group">
                  <input
                    type="radio"
                    bind:group={dados.foi_voce_que_iniciou}
                    value={false}
                    class="w-5 h-5 text-green-600 border-gray-300 focus:ring-green-500 focus:ring-2"
                  />
                  <div class="ml-4">
                    <div class="flex items-center">
                      <svg class="w-6 h-6 text-red-600 mr-2" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12" />
                      </svg>
                      <span class="text-lg font-semibold text-gray-800 group-hover:text-red-600 transition-colors">Não</span>
                    </div>
                    <p class="text-sm text-gray-600 mt-1">Alguém mais iniciou este núcleo</p>
                  </div>
                </label>
              </div>
            </div>
          </div>
          
          <!-- Média de pessoas -->
          <div class="bg-gradient-to-br from-orange-50 via-white to-red-50 rounded-2xl shadow-xl border border-orange-100 p-4 sm:p-6 lg:p-8 relative overflow-hidden">
            <!-- Decorative background elements -->
            <div class="absolute top-0 right-0 w-32 h-32 bg-gradient-to-br from-orange-200 to-red-200 rounded-full -translate-y-16 translate-x-16 opacity-20"></div>
            <div class="absolute bottom-0 left-0 w-24 h-24 bg-gradient-to-tr from-red-200 to-orange-200 rounded-full translate-y-12 -translate-x-12 opacity-20"></div>
            
            <div class="relative z-10">
              <div class="flex items-center mb-6">
                <div class="w-10 h-10 sm:w-12 sm:h-12 bg-gradient-to-br from-orange-500 to-red-500 rounded-xl shadow-lg mr-4">
                  <svg class="w-6 h-6 sm:w-7 sm:h-7 text-white mx-auto mt-1.5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M17 20h5v-2a3 3 0 00-5.356-1.857M17 20H7m10 0v-2c0-.656-.126-1.283-.356-1.857M7 20H2v-2a3 3 0 015.356-1.857M7 20v-2c0-.656.126-1.283.356-1.857m0 0a5.002 5.002 0 019.288 0M15 7a3 3 0 11-6 0 3 3 0 016 0zm6 3a2 2 0 11-4 0 2 2 0 014 0zM7 10a2 2 0 11-4 0 2 2 0 014 0z" />
                  </svg>
                </div>
                <h3 class="text-xl sm:text-2xl font-bold bg-gradient-to-r from-orange-600 to-red-600 bg-clip-text text-transparent">
                  Média de quantas pessoas?
                </h3>
              </div>
              
              <div class="bg-white/70 backdrop-blur-sm rounded-xl p-4 sm:p-6 border border-white/50 shadow-lg">
                <label for="media_pessoas" class="block text-sm font-semibold text-gray-800 mb-3">
                  Número médio de participantes
                </label>
                <input
                  type="number"
                  id="media_pessoas"
                  bind:value={dados.media_pessoas}
                  min="1"
                  placeholder="Ex: 10"
                  class="w-full px-4 py-3 border border-gray-300 rounded-xl focus:outline-none focus:ring-2 focus:ring-orange-500 focus:border-orange-500 transition-all duration-300 text-gray-800 placeholder-gray-500"
                />
              </div>
            </div>
          </div>
          
          <!-- Fotos do núcleo -->
          <div class="bg-gradient-to-br from-purple-50 via-white to-pink-50 rounded-2xl shadow-xl border border-purple-100 p-4 sm:p-6 lg:p-8 relative overflow-hidden">
            <!-- Decorative background elements -->
            <div class="absolute top-0 right-0 w-32 h-32 bg-gradient-to-br from-purple-200 to-pink-200 rounded-full -translate-y-16 translate-x-16 opacity-20"></div>
            <div class="absolute bottom-0 left-0 w-24 h-24 bg-gradient-to-tr from-pink-200 to-purple-200 rounded-full translate-y-12 -translate-x-12 opacity-20"></div>
            
            <div class="relative z-10">
              <div class="flex items-center mb-6">
                <div class="w-10 h-10 sm:w-12 sm:h-12 bg-gradient-to-br from-purple-500 to-pink-500 rounded-xl shadow-lg mr-4">
                  <svg class="w-6 h-6 sm:w-7 sm:h-7 text-white mx-auto mt-1.5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 16l4.586-4.586a2 2 0 012.828 0L16 16m-2-2l1.586-1.586a2 2 0 012.828 0L20 14m-6-6h.01M6 20h12a2 2 0 002-2V6a2 2 0 00-2-2H6a2 2 0 00-2 2v12a2 2 0 002 2z" />
                  </svg>
                </div>
                <h3 class="text-xl sm:text-2xl font-bold bg-gradient-to-r from-purple-600 to-pink-600 bg-clip-text text-transparent">
                  Fotos do núcleo (máximo 5)
                </h3>
              </div>
              <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
                {#each Array(5) as _, index}
                  {@const fotoIndex = index + 1}
                  <div class="bg-white/70 backdrop-blur-sm border-2 border-dashed border-purple-300 rounded-xl p-4 hover:border-purple-400 hover:shadow-lg transition-all duration-300">
                    <div class="text-center">
                      {#if dados[`foto_${fotoIndex}`]}
                        <!-- Foto carregada com preview -->
                        <div class="mb-3 relative group">
                          <button
                            type="button"
                            class="w-full h-32 p-0 border-0 bg-transparent cursor-pointer focus:outline-none focus:ring-2 focus:ring-blue-500 rounded-lg overflow-hidden"
                            on:click={() => openPhotoPreview(dados[`foto_${fotoIndex}`], index)}
                            title="Clique para ver em tamanho maior"
                          >
                            <img 
                              src={dados[`foto_${fotoIndex}`]} 
                              alt="Foto {fotoIndex}"
                              class="w-full h-full object-cover hover:shadow-md transition-shadow duration-200"
                            />
                          </button>
                          <!-- Overlay com botão de remover -->
                          <div class="absolute inset-0 bg-black bg-opacity-0 group-hover:bg-opacity-30 transition-all duration-200 rounded-lg flex items-center justify-center">
                            <button
                              type="button"
                              on:click={() => removePhoto(index)}
                              class="opacity-0 group-hover:opacity-100 bg-red-500 text-white p-2 rounded-full hover:bg-red-600 transition-all duration-200 transform scale-75 group-hover:scale-100"
                              title="Remover foto"
                            >
                              <svg class="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12" />
                              </svg>
                            </button>
                          </div>
                        </div>
                        <div class="text-xs text-gray-500 mb-2">
                          Foto {fotoIndex} carregada
                        </div>
                      {:else}
                        <!-- Upload de foto -->
                        <div class="mb-3">
                          <svg class="mx-auto h-12 w-12 text-gray-400" stroke="currentColor" fill="none" viewBox="0 0 48 48">
                            <path d="M28 8H12a4 4 0 00-4 4v20m32-12v8m0 0v8a4 4 0 01-4 4H12a4 4 0 01-4-4v-4m32-4l-3.172-3.172a4 4 0 00-5.656 0L28 28M8 32l9.172-9.172a4 4 0 015.656 0L28 28m0 0l4 4m4-24h8m-4-4v8m-12 4h.02" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" />
                          </svg>
                        </div>
                        <div class="text-sm text-gray-600 mb-3">
                          Foto {fotoIndex}
                        </div>
                        <input
                          type="file"
                          id="foto_{fotoIndex}"
                          accept="image/*"
                          on:change={(e) => {
                            const file = e.target.files[0];
                            if (file) uploadPhoto(file, index);
                          }}
                          class="hidden"
                        />
                        <label
                          for="foto_{fotoIndex}"
                          class="cursor-pointer inline-flex items-center px-4 py-2 border border-purple-300 shadow-sm text-sm leading-4 font-medium rounded-xl text-purple-700 bg-white hover:bg-purple-50 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-purple-500 disabled:opacity-50 transition-all duration-300 hover:shadow-lg"
                          class:opacity-50={uploadingPhotos[index]}
                        >
                          {#if uploadingPhotos[index]}
                            <svg class="animate-spin -ml-1 mr-2 h-4 w-4 text-gray-500" fill="none" viewBox="0 0 24 24">
                              <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle>
                              <path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
                            </svg>
                            Enviando...
                          {:else}
                            Escolher Foto
                          {/if}
                        </label>
                      {/if}
                    </div>
                  </div>
                {/each}
              </div>
            </div>
          </div>
          
          <!-- Vídeo do núcleo -->
          <div class="bg-gradient-to-br from-red-50 via-white to-pink-50 rounded-2xl shadow-xl border border-red-100 p-4 sm:p-6 lg:p-8 relative overflow-hidden">
            <!-- Decorative background elements -->
            <div class="absolute top-0 right-0 w-32 h-32 bg-gradient-to-br from-red-200 to-pink-200 rounded-full -translate-y-16 translate-x-16 opacity-20"></div>
            <div class="absolute bottom-0 left-0 w-24 h-24 bg-gradient-to-tr from-pink-200 to-red-200 rounded-full translate-y-12 -translate-x-12 opacity-20"></div>
            
            <div class="relative z-10">
              <div class="flex items-center mb-6">
                <div class="w-10 h-10 sm:w-12 sm:h-12 bg-gradient-to-br from-red-500 to-pink-500 rounded-xl shadow-lg mr-4">
                  <svg class="w-6 h-6 sm:w-7 sm:h-7 text-white mx-auto mt-1.5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 10l4.553-2.276A1 1 0 0121 8.618v6.764a1 1 0 01-1.447.894L15 14M5 18h8a2 2 0 002-2V8a2 2 0 00-2-2H5a2 2 0 00-2 2v8a2 2 0 002 2z" />
                  </svg>
                </div>
                <h3 class="text-xl sm:text-2xl font-bold bg-gradient-to-r from-red-600 to-pink-600 bg-clip-text text-transparent">
                  Vídeo do núcleo
                </h3>
              </div>
              <div class="space-y-4">
                <div class="bg-white/70 backdrop-blur-sm rounded-xl p-4 sm:p-6 border border-white/50 shadow-lg">
                  <label for="video_link" class="block text-sm font-semibold text-gray-800 mb-3">
                    Link do vídeo (YouTube, Google Drive, Instagram, Facebook)
                  </label>
                  <input
                    type="url"
                    id="video_link"
                    bind:value={dados.video_link}
                    on:input={(e) => {
                      const newValue = e.target.value;
                      dados.video_link = newValue;
                      
                      // Detectar plataforma automaticamente quando o link mudar
                      if (newValue && newValue.trim()) {
                        const platform = detectVideoPlatformAuto(newValue);
                        dados.video_plataforma = platform;
                        
                        // Atualizar URL de incorporação diretamente
                        embedUrl = getVideoEmbedUrl();
                      } else {
                        dados.video_plataforma = '';
                        embedUrl = null;
                      }
                    }}
                    placeholder="https://www.youtube.com/watch?v=..."
                    class="w-full px-4 py-3 border border-gray-300 rounded-xl focus:outline-none focus:ring-2 focus:ring-red-500 focus:border-red-500 transition-all duration-300 text-gray-800 placeholder-gray-500"
                  />
                </div>
                
                
                <!-- Player de vídeo incorporado -->
                {#if embedUrl}
                  <div class="mt-6 bg-white/70 backdrop-blur-sm rounded-xl p-4 sm:p-6 border border-white/50 shadow-lg">
                    <h4 class="text-sm font-semibold text-gray-800 mb-3 flex items-center">
                      <svg class="w-4 h-4 mr-2 text-red-600" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 10l4.553-2.276A1 1 0 0121 8.618v6.764a1 1 0 01-1.447.894L15 14M5 18h8a2 2 0 002-2V8a2 2 0 00-2-2H5a2 2 0 00-2 2v8a2 2 0 002 2z" />
                      </svg>
                      Vídeo incorporado:
                    </h4>
                    <div class="aspect-video bg-gray-100 rounded-xl overflow-hidden shadow-lg">
                      {#if dados.video_plataforma === 'youtube'}
                        <iframe
                          src={embedUrl}
                          title="Vídeo do núcleo"
                          class="w-full h-full"
                          frameborder="0"
                          allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture"
                          allowfullscreen
                        ></iframe>
                      {:else if dados.video_plataforma === 'google_drive'}
                        <iframe
                          src={embedUrl}
                          title="Vídeo do núcleo"
                          class="w-full h-full"
                          frameborder="0"
                        ></iframe>
                      {:else}
                        <div class="flex items-center justify-center h-full">
                          <a
                            href={dados.video_link}
                            target="_blank"
                            rel="noopener noreferrer"
                            class="text-blue-600 hover:text-blue-800 underline"
                          >
                            Abrir vídeo em nova aba
                          </a>
                        </div>
                      {/if}
                    </div>
                  </div>
                {/if}
              </div>
            </div>
          </div>
          
          <!-- Tem obreiros -->
          <div class="bg-gradient-to-br from-green-50 via-white to-emerald-50 rounded-2xl shadow-xl border border-green-100 p-4 sm:p-6 lg:p-8 relative overflow-hidden">
            <!-- Decorative background elements -->
            <div class="absolute top-0 right-0 w-32 h-32 bg-gradient-to-br from-green-200 to-emerald-200 rounded-full -translate-y-16 translate-x-16 opacity-20"></div>
            <div class="absolute bottom-0 left-0 w-24 h-24 bg-gradient-to-tr from-emerald-200 to-green-200 rounded-full translate-y-12 -translate-x-12 opacity-20"></div>
            
            <div class="relative z-10">
              <div class="flex items-center mb-6">
                <div class="w-10 h-10 sm:w-12 sm:h-12 bg-gradient-to-br from-green-500 to-emerald-500 rounded-xl shadow-lg mr-4">
                  <svg class="w-6 h-6 sm:w-7 sm:h-7 text-white mx-auto mt-1.5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4.354a4 4 0 110 5.292M15 21H3v-1a6 6 0 0112 0v1zm0 0h6v-1a6 6 0 00-9-5.197m13.5-9a2.5 2.5 0 11-5 0 2.5 2.5 0 015 0z" />
                  </svg>
                </div>
                <h3 class="text-xl sm:text-2xl font-bold bg-gradient-to-r from-green-600 to-emerald-600 bg-clip-text text-transparent">
                  Tem obreiros(as)?
                </h3>
              </div>
              
              <div class="grid grid-cols-1 sm:grid-cols-2 gap-4 mb-6">
                <label class="flex items-center p-4 bg-white/70 backdrop-blur-sm rounded-xl border border-white/50 shadow-lg hover:shadow-xl transition-all duration-300 cursor-pointer group">
                  <input
                    type="radio"
                    bind:group={dados.tem_obreiros}
                    value={true}
                    on:change={() => handleTemObreirosChange(true)}
                    class="w-5 h-5 text-green-600 border-gray-300 focus:ring-green-500 focus:ring-2"
                  />
                  <div class="ml-4">
                    <div class="flex items-center">
                      <svg class="w-6 h-6 text-green-600 mr-2" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7" />
                      </svg>
                      <span class="text-lg font-semibold text-gray-800 group-hover:text-green-600 transition-colors">Sim</span>
                    </div>
                    <p class="text-sm text-gray-600 mt-1">Temos obreiros no núcleo</p>
                  </div>
                </label>
                
                <label class="flex items-center p-4 bg-white/70 backdrop-blur-sm rounded-xl border border-white/50 shadow-lg hover:shadow-xl transition-all duration-300 cursor-pointer group">
                  <input
                    type="radio"
                    bind:group={dados.tem_obreiros}
                    value={false}
                    on:change={() => handleTemObreirosChange(false)}
                    class="w-5 h-5 text-green-600 border-gray-300 focus:ring-green-500 focus:ring-2"
                  />
                  <div class="ml-4">
                    <div class="flex items-center">
                      <svg class="w-6 h-6 text-red-600 mr-2" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12" />
                      </svg>
                      <span class="text-lg font-semibold text-gray-800 group-hover:text-red-600 transition-colors">Não</span>
                    </div>
                    <p class="text-sm text-gray-600 mt-1">Não temos obreiros no núcleo</p>
                  </div>
                </label>
              </div>
              
              {#if dados.tem_obreiros === true}
                <div class="bg-white/70 backdrop-blur-sm rounded-xl p-4 sm:p-6 border border-white/50 shadow-lg">
                  <label for="quantos_obreiros" class="block text-sm font-semibold text-gray-800 mb-3">
                    Quantos obreiros(as)?
                  </label>
                  <input
                    type="number"
                    id="quantos_obreiros"
                    bind:value={dados.quantos_obreiros}
                    min="1"
                    placeholder="Ex: 3"
                    class="w-full px-4 py-3 border border-gray-300 rounded-xl focus:outline-none focus:ring-2 focus:ring-green-500 focus:border-green-500 transition-all duration-300 text-gray-800 placeholder-gray-500"
                  />
                </div>
              {/if}
            </div>
          </div>
          
          <!-- Alguém ajuda -->
          <div class="bg-gradient-to-br from-indigo-50 via-white to-blue-50 rounded-2xl shadow-xl border border-indigo-100 p-4 sm:p-6 lg:p-8 relative overflow-hidden">
            <!-- Decorative background elements -->
            <div class="absolute top-0 right-0 w-32 h-32 bg-gradient-to-br from-indigo-200 to-blue-200 rounded-full -translate-y-16 translate-x-16 opacity-20"></div>
            <div class="absolute bottom-0 left-0 w-24 h-24 bg-gradient-to-tr from-blue-200 to-indigo-200 rounded-full translate-y-12 -translate-x-12 opacity-20"></div>
            
            <div class="relative z-10">
              <div class="flex items-center mb-6">
                <div class="w-10 h-10 sm:w-12 sm:h-12 bg-gradient-to-br from-indigo-500 to-blue-500 rounded-xl shadow-lg mr-4">
                  <svg class="w-6 h-6 sm:w-7 sm:h-7 text-white mx-auto mt-1.5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4.318 6.318a4.5 4.5 0 000 6.364L12 20.364l7.682-7.682a4.5 4.5 0 00-6.364-6.364L12 7.636l-1.318-1.318a4.5 4.5 0 00-6.364 0z" />
                  </svg>
                </div>
                <h3 class="text-xl sm:text-2xl font-bold bg-gradient-to-r from-indigo-600 to-blue-600 bg-clip-text text-transparent">
                  Alguém ajuda no núcleo?
                </h3>
              </div>
              
              <div class="grid grid-cols-1 sm:grid-cols-2 gap-4 mb-6">
                <label class="flex items-center p-4 bg-white/70 backdrop-blur-sm rounded-xl border border-white/50 shadow-lg hover:shadow-xl transition-all duration-300 cursor-pointer group">
                  <input
                    type="radio"
                    bind:group={dados.alguem_ajuda}
                    value={true}
                    on:change={() => handleAlguemAjudaChange(true)}
                    class="w-5 h-5 text-indigo-600 border-gray-300 focus:ring-indigo-500 focus:ring-2"
                  />
                  <div class="ml-4">
                    <div class="flex items-center">
                      <svg class="w-6 h-6 text-green-600 mr-2" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7" />
                      </svg>
                      <span class="text-lg font-semibold text-gray-800 group-hover:text-indigo-600 transition-colors">Sim</span>
                    </div>
                    <p class="text-sm text-gray-600 mt-1">Alguém ajuda no núcleo</p>
                  </div>
                </label>
                
                <label class="flex items-center p-4 bg-white/70 backdrop-blur-sm rounded-xl border border-white/50 shadow-lg hover:shadow-xl transition-all duration-300 cursor-pointer group">
                  <input
                    type="radio"
                    bind:group={dados.alguem_ajuda}
                    value={false}
                    on:change={() => handleAlguemAjudaChange(false)}
                    class="w-5 h-5 text-indigo-600 border-gray-300 focus:ring-indigo-500 focus:ring-2"
                  />
                  <div class="ml-4">
                    <div class="flex items-center">
                      <svg class="w-6 h-6 text-red-600 mr-2" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12" />
                      </svg>
                      <span class="text-lg font-semibold text-gray-800 group-hover:text-red-600 transition-colors">Não</span>
                    </div>
                    <p class="text-sm text-gray-600 mt-1">Ninguém ajuda no núcleo</p>
                  </div>
                </label>
              </div>
              
              {#if dados.alguem_ajuda === true}
                <div class="bg-white/70 backdrop-blur-sm rounded-xl p-4 sm:p-6 border border-white/50 shadow-lg">
                  <label for="quem_ajuda" class="block text-sm font-semibold text-gray-800 mb-3">
                    Quem ajuda?
                  </label>
                  <input
                    type="text"
                    id="quem_ajuda"
                    bind:value={dados.quem_ajuda}
                    placeholder="Ex: Pastor João, Diácono Maria, etc."
                    class="w-full px-4 py-3 border border-gray-300 rounded-xl focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500 transition-all duration-300 text-gray-800 placeholder-gray-500"
                  />
                </div>
              {/if}
            </div>
          </div>
          
          <!-- Quantas pessoas vão à igreja -->
          <div class="bg-gradient-to-br from-cyan-50 via-white to-teal-50 rounded-2xl shadow-xl border border-cyan-100 p-4 sm:p-6 lg:p-8 relative overflow-hidden">
            <!-- Decorative background elements -->
            <div class="absolute top-0 right-0 w-32 h-32 bg-gradient-to-br from-cyan-200 to-teal-200 rounded-full -translate-y-16 translate-x-16 opacity-20"></div>
            <div class="absolute bottom-0 left-0 w-24 h-24 bg-gradient-to-tr from-teal-200 to-cyan-200 rounded-full translate-y-12 -translate-x-12 opacity-20"></div>
            
            <div class="relative z-10">
              <div class="flex items-center mb-6">
                <div class="w-10 h-10 sm:w-12 sm:h-12 bg-gradient-to-br from-cyan-500 to-teal-500 rounded-xl shadow-lg mr-4">
                  <svg class="w-6 h-6 sm:w-7 sm:h-7 text-white mx-auto mt-1.5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 21V5a2 2 0 00-2-2H7a2 2 0 00-2 2v16m14 0h2m-2 0h-5m-9 0H3m2 0h5M9 7h1m-1 4h1m4-4h1m-1 4h1m-5 10v-5a1 1 0 011-1h2a1 1 0 011 1v5m-4 0h4" />
                  </svg>
                </div>
                <h3 class="text-xl sm:text-2xl font-bold bg-gradient-to-r from-cyan-600 to-teal-600 bg-clip-text text-transparent">
                  Quantas pessoas do núcleo vão à igreja?
                </h3>
              </div>
              
              <div class="bg-white/70 backdrop-blur-sm rounded-xl p-4 sm:p-6 border border-white/50 shadow-lg">
                <label for="quantas_pessoas_vao_igreja" class="block text-sm font-semibold text-gray-800 mb-3">
                  Número de pessoas que frequentam a igreja
                </label>
                <input
                  type="number"
                  id="quantas_pessoas_vao_igreja"
                  bind:value={dados.quantas_pessoas_vao_igreja}
                  min="0"
                  placeholder="Ex: 8"
                  class="w-full px-4 py-3 border border-gray-300 rounded-xl focus:outline-none focus:ring-2 focus:ring-cyan-500 focus:border-cyan-500 transition-all duration-300 text-gray-800 placeholder-gray-500"
                />
              </div>
            </div>
          </div>
          
          <!-- Maior experiência -->
          <div class="bg-gradient-to-br from-amber-50 via-white to-yellow-50 rounded-2xl shadow-xl border border-amber-100 p-4 sm:p-6 lg:p-8 relative overflow-hidden">
            <!-- Decorative background elements -->
            <div class="absolute top-0 right-0 w-32 h-32 bg-gradient-to-br from-amber-200 to-yellow-200 rounded-full -translate-y-16 translate-x-16 opacity-20"></div>
            <div class="absolute bottom-0 left-0 w-24 h-24 bg-gradient-to-tr from-yellow-200 to-amber-200 rounded-full translate-y-12 -translate-x-12 opacity-20"></div>
            
            <div class="relative z-10">
              <div class="flex items-center mb-6">
                <div class="w-10 h-10 sm:w-12 sm:h-12 bg-gradient-to-br from-amber-500 to-yellow-500 rounded-xl shadow-lg mr-4">
                  <svg class="w-6 h-6 sm:w-7 sm:h-7 text-white mx-auto mt-1.5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9.663 17h4.673M12 3v1m6.364 1.636l-.707.707M21 12h-1M4 12H3m3.343-5.657l-.707-.707m2.828 9.9a5 5 0 117.072 0l-.548.547A3.374 3.374 0 0014 18.469V19a2 2 0 11-4 0v-.531c0-.895-.356-1.754-.988-2.386l-.548-.547z" />
                  </svg>
                </div>
                <h3 class="text-xl sm:text-2xl font-bold bg-gradient-to-r from-amber-600 to-yellow-600 bg-clip-text text-transparent">
                  Qual sua maior experiência no núcleo?
                </h3>
              </div>
              
              <div class="bg-white/70 backdrop-blur-sm rounded-xl p-4 sm:p-6 border border-white/50 shadow-lg">
                <label for="maior_experiencia" class="block text-sm font-semibold text-gray-800 mb-3">
                  Compartilhe sua maior experiência
                </label>
                <textarea
                  id="maior_experiencia"
                  bind:value={dados.maior_experiencia}
                  rows="4"
                  placeholder="Conte sobre sua maior experiência no núcleo..."
                  class="w-full px-4 py-3 border border-gray-300 rounded-xl focus:outline-none focus:ring-2 focus:ring-amber-500 focus:border-amber-500 transition-all duration-300 text-gray-800 placeholder-gray-500 resize-none"
                ></textarea>
              </div>
            </div>
          </div>
        {/if}
        
        <!-- Observação Geral -->
        <div class="bg-gradient-to-br from-slate-50 via-white to-gray-50 rounded-2xl shadow-xl border border-slate-100 p-4 sm:p-6 lg:p-8 relative overflow-hidden">
          <!-- Decorative background elements -->
          <div class="absolute top-0 right-0 w-32 h-32 bg-gradient-to-br from-slate-200 to-gray-200 rounded-full -translate-y-16 translate-x-16 opacity-20"></div>
          <div class="absolute bottom-0 left-0 w-24 h-24 bg-gradient-to-tr from-gray-200 to-slate-200 rounded-full translate-y-12 -translate-x-12 opacity-20"></div>
          
          <div class="relative z-10">
            <div class="flex items-center mb-6">
              <div class="w-10 h-10 sm:w-12 sm:h-12 bg-gradient-to-br from-slate-500 to-gray-500 rounded-xl shadow-lg mr-4">
                <svg class="w-6 h-6 sm:w-7 sm:h-7 text-white mx-auto mt-1.5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M11 5H6a2 2 0 00-2 2v11a2 2 0 002 2h11a2 2 0 002-2v-5m-1.414-9.414a2 2 0 112.828 2.828L11.828 15H9v-2.828l8.586-8.586z" />
                </svg>
              </div>
              <h3 class="text-xl sm:text-2xl font-bold bg-gradient-to-r from-slate-600 to-gray-600 bg-clip-text text-transparent">
                Observação Geral
              </h3>
            </div>
            
            <div class="bg-white/70 backdrop-blur-sm rounded-xl p-4 sm:p-6 border border-white/50 shadow-lg">
              <label for="observacao_geral" class="block text-sm font-semibold text-gray-800 mb-3">
                Observações adicionais sobre o núcleo
              </label>
              <textarea
                id="observacao_geral"
                bind:value={dados.observacao_geral}
                rows="4"
                placeholder="Observações gerais sobre o núcleo..."
                class="w-full px-4 py-3 border border-gray-300 rounded-xl focus:outline-none focus:ring-2 focus:ring-slate-500 focus:border-slate-500 transition-all duration-300 text-gray-800 placeholder-gray-500 resize-none"
              ></textarea>
            </div>
          </div>
        </div>
        
        <!-- Botões -->
        <div class="bg-gradient-to-br from-gray-50 via-white to-slate-50 rounded-2xl shadow-xl border border-gray-100 p-6 sm:p-8">
          <div class="flex flex-col sm:flex-row justify-end space-y-3 sm:space-y-0 sm:space-x-4">
            <button
              type="button"
              on:click={carregarDados}
              disabled={saving}
              class="px-6 py-3 border-2 border-gray-300 text-gray-700 bg-white rounded-xl font-semibold hover:bg-gray-50 hover:border-gray-400 focus:outline-none focus:ring-2 focus:ring-gray-500 focus:ring-offset-2 transition-all duration-300 disabled:opacity-50 disabled:cursor-not-allowed"
            >
              Cancelar
            </button>
            <button
              type="submit"
              disabled={saving}
              class="px-8 py-3 bg-gradient-to-r from-blue-600 to-indigo-600 text-white rounded-xl font-semibold hover:from-blue-700 hover:to-indigo-700 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:ring-offset-2 transition-all duration-300 disabled:opacity-50 disabled:cursor-not-allowed shadow-lg hover:shadow-xl transform hover:scale-105 disabled:transform-none"
            >
              {#if saving}
                <svg class="w-5 h-5 mr-2 animate-spin inline" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 4v5h.582m15.356 2A8.001 8.001 0 004.582 9m0 0H9m11 11v-5h-.581m0 0a8.003 8.003 0 01-15.357-2m15.357 2H15" />
                </svg>
                Salvando...
              {:else}
                <svg class="w-5 h-5 mr-2 inline" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7" />
                </svg>
                Salvar Dados
              {/if}
            </button>
          </div>
        </div>
      </form>
    {/if}
  </div>
{/if}

<!-- Modal de preview da foto -->
{#if showPhotoPreview}
  <div 
    class="fixed inset-0 bg-black bg-opacity-75 z-50 flex items-center justify-center p-4" 
    on:click={closePhotoPreview}
    on:keydown={(e) => e.key === 'Escape' && closePhotoPreview()}
    role="dialog"
    aria-modal="true"
    aria-label="Preview da foto"
    tabindex="0"
  >
    <div 
      class="relative max-w-4xl max-h-full" 
      on:click|stopPropagation
      role="presentation"
    >
      <!-- Botão de fechar -->
      <button
        on:click={closePhotoPreview}
        class="absolute -top-4 -right-4 bg-white text-gray-600 hover:text-gray-800 rounded-full p-2 shadow-lg z-10"
        title="Fechar preview"
      >
        <svg class="w-6 h-6" fill="none" viewBox="0 0 24 24" stroke="currentColor">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12" />
        </svg>
      </button>
      
      <!-- Imagem em tamanho grande -->
      <img 
        src={previewPhotoUrl} 
        alt="Preview da foto {previewPhotoIndex + 1}"
        class="max-w-full max-h-full object-contain rounded-lg shadow-2xl"
      />
      
      <!-- Informações da foto -->
      <div class="absolute bottom-0 left-0 right-0 bg-black bg-opacity-50 text-white p-4 rounded-b-lg">
        <p class="text-center text-sm">
          Foto {previewPhotoIndex + 1} do núcleo
        </p>
      </div>
    </div>
  </div>
{/if}
