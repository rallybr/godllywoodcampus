<script>
  import { onMount } from 'svelte';
  import { goto } from '$app/navigation';
  import { user, updateProfile } from '$lib/stores/auth';
  import Button from '$lib/components/ui/Button.svelte';
  import Input from '$lib/components/ui/Input.svelte';
  import Select from '$lib/components/ui/Select.svelte';
  
  let currentStep = 1;
  let isLoading = false;
  let error = '';
  
  // Form data
  let formData = {
    nome: '',
    telefone: '',
    data_nascimento: '',
    sexo: '',
    estado_civil: '',
    escolaridade: '',
    profissao: '',
    igreja: '',
    pastor: '',
    tempo_igreja: '',
    condicao: '',
    batizado_aguas: false,
    batizado_es: false,
    data_batismo_aguas: '',
    data_batismo_es: '',
    responsabilidades: '',
    observacoes: ''
  };
  
  const sexoOptions = [
    { value: '', label: 'Selecione o sexo' },
    { value: 'masculino', label: 'Masculino' },
    { value: 'feminino', label: 'Feminino' }
  ];
  
  const estadoCivilOptions = [
    { value: '', label: 'Selecione o estado civil' },
    { value: 'solteiro', label: 'Solteiro(a)' },
    { value: 'casado', label: 'Casado(a)' },
    { value: 'divorciado', label: 'Divorciado(a)' },
    { value: 'viuvo', label: 'Viúvo(a)' }
  ];
  
  const escolaridadeOptions = [
    { value: '', label: 'Selecione a escolaridade' },
    { value: 'fundamental', label: 'Ensino Fundamental' },
    { value: 'medio', label: 'Ensino Médio' },
    { value: 'superior', label: 'Ensino Superior' },
    { value: 'pos_graduacao', label: 'Pós-graduação' }
  ];
  
  const condicaoOptions = [
    { value: '', label: 'Selecione a condição' },
    { value: 'jovem_batizado_es', label: 'Jovem Batizado(a) ES' },
    { value: 'cpo', label: 'CPO' },
    { value: 'colaborador', label: 'Colaborador(a)' },
    { value: 'obreiro', label: 'Obreiro(a)' },
    { value: 'iburd', label: 'IBURD' },
    { value: 'auxiliar_pastor', label: 'Auxiliar de Pastor' },
    { value: 'namorada', label: 'Namorada' },
    { value: 'noiva', label: 'Noiva' }
  ];
  
  onMount(() => {
    if (!$user) {
      goto('/login');
    }
  });
  
  function nextStep() {
    if (currentStep < 3) {
      currentStep++;
    }
  }
  
  function prevStep() {
    if (currentStep > 1) {
      currentStep--;
    }
  }
  
  async function handleSubmit() {
    isLoading = true;
    error = '';
    
    try {
      await updateProfile(formData);
      goto('/');
    } catch (err) {
      error = err.message || 'Erro ao completar perfil';
    } finally {
      isLoading = false;
    }
  }
  
  function isStepValid(step) {
    switch (step) {
      case 1:
        return formData.nome && formData.telefone && formData.data_nascimento && formData.sexo;
      case 2:
        return formData.igreja && formData.pastor && formData.tempo_igreja && formData.condicao;
      case 3:
        return true; // Optional fields
      default:
        return false;
    }
  }
</script>

<svelte:head>
  <title>Completar Perfil - IntelliMen Campus</title>
</svelte:head>

<div class="min-h-screen bg-gray-100 py-8">
  <div class="max-w-4xl mx-auto px-4">
    <!-- Header -->
    <div class="text-center mb-8">
      <h1 class="text-3xl font-bold text-gray-900">Completar Perfil</h1>
      <p class="text-gray-600 mt-2">Complete suas informações para acessar o sistema</p>
    </div>
    
    <!-- Progress bar -->
    <div class="mb-8">
      <div class="flex items-center justify-between mb-2">
        <span class="text-sm font-medium text-gray-700">Etapa {currentStep} de 3</span>
        <span class="text-sm text-gray-500">{Math.round((currentStep / 3) * 100)}% concluído</span>
      </div>
      <div class="w-full bg-gray-200 rounded-full h-2">
        <div 
          class="bg-blue-600 h-2 rounded-full transition-all duration-300"
          style="width: {(currentStep / 3) * 100}%"
        ></div>
      </div>
    </div>
    
    <!-- Error message -->
    {#if error}
      <div class="mb-6 bg-red-50 border border-red-200 rounded-lg p-4">
        <div class="flex items-center space-x-2">
          <svg class="w-5 h-5 text-red-500" fill="none" viewBox="0 0 24 24" stroke="currentColor">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8v4m0 4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
          </svg>
          <p class="text-sm text-red-600 font-medium">{error}</p>
        </div>
      </div>
    {/if}
    
    <!-- Form steps -->
    <div class="bg-white rounded-lg shadow-sm p-8">
      {#if currentStep === 1}
        <!-- Step 1: Dados Pessoais -->
        <div class="space-y-6">
          <h2 class="text-xl font-semibold text-gray-900 mb-4">Dados Pessoais</h2>
          
          <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
            <div>
              <Input
                label="Nome Completo"
                placeholder="Digite seu nome completo"
                value={formData.nome}
                required
                on:input={(e) => formData.nome = e.detail.value}
              />
            </div>
            
            <div>
              <Input
                label="Telefone/WhatsApp"
                placeholder="(11) 99999-9999"
                value={formData.telefone}
                required
                on:input={(e) => formData.telefone = e.detail.value}
              />
            </div>
            
            <div>
              <Input
                type="date"
                label="Data de Nascimento"
                value={formData.data_nascimento}
                required
                on:input={(e) => formData.data_nascimento = e.detail.value}
              />
            </div>
            
            <div>
              <Select
                label="Sexo"
                options={sexoOptions}
                value={formData.sexo}
                required
                on:change={(e) => formData.sexo = e.detail.value}
              />
            </div>
            
            <div>
              <Select
                label="Estado Civil"
                options={estadoCivilOptions}
                value={formData.estado_civil}
                on:change={(e) => formData.estado_civil = e.detail.value}
              />
            </div>
            
            <div>
              <Select
                label="Escolaridade"
                options={escolaridadeOptions}
                value={formData.escolaridade}
                on:change={(e) => formData.escolaridade = e.detail.value}
              />
            </div>
            
            <div class="md:col-span-2">
              <Input
                label="Profissão"
                placeholder="Sua profissão ou área de atuação"
                value={formData.profissao}
                on:input={(e) => formData.profissao = e.detail.value}
              />
            </div>
          </div>
        </div>
        
      {:else if currentStep === 2}
        <!-- Step 2: Dados Espirituais -->
        <div class="space-y-6">
          <h2 class="text-xl font-semibold text-gray-900 mb-4">Dados Espirituais</h2>
          
          <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
            <div>
              <Input
                label="Igreja"
                placeholder="Nome da sua igreja"
                value={formData.igreja}
                required
                on:input={(e) => formData.igreja = e.detail.value}
              />
            </div>
            
            <div>
              <Input
                label="Pastor"
                placeholder="Nome do seu pastor"
                value={formData.pastor}
                required
                on:input={(e) => formData.pastor = e.detail.value}
              />
            </div>
            
            <div>
              <Input
                label="Tempo na Igreja"
                placeholder="Ex: 2 anos, 6 meses"
                value={formData.tempo_igreja}
                required
                on:input={(e) => formData.tempo_igreja = e.detail.value}
              />
            </div>
            
            <div>
              <Select
                label="Condição"
                options={condicaoOptions}
                value={formData.condicao}
                required
                on:change={(e) => formData.condicao = e.detail.value}
              />
            </div>
            
            <div>
              <Input
                type="date"
                label="Data do Batismo nas Águas"
                value={formData.data_batismo_aguas}
                on:input={(e) => formData.data_batismo_aguas = e.detail.value}
              />
            </div>
            
            <div>
              <Input
                type="date"
                label="Data do Batismo com ES"
                value={formData.data_batismo_es}
                on:input={(e) => formData.data_batismo_es = e.detail.value}
              />
            </div>
            
            <div class="md:col-span-2">
              <Input
                label="Responsabilidades na Igreja"
                placeholder="Ex: Louvor, Obreiro, Diácono, etc."
                value={formData.responsabilidades}
                on:input={(e) => formData.responsabilidades = e.detail.value}
              />
            </div>
          </div>
          
          <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
            <label class="flex items-center space-x-2">
              <input
                type="checkbox"
                bind:checked={formData.batizado_aguas}
                class="rounded border-gray-300 text-blue-600 focus:ring-blue-500"
              />
              <span class="text-sm text-gray-700">Batizado nas águas</span>
            </label>
            
            <label class="flex items-center space-x-2">
              <input
                type="checkbox"
                bind:checked={formData.batizado_es}
                class="rounded border-gray-300 text-blue-600 focus:ring-blue-500"
              />
              <span class="text-sm text-gray-700">Batizado com o Espírito Santo</span>
            </label>
          </div>
        </div>
        
      {:else if currentStep === 3}
        <!-- Step 3: Observações -->
        <div class="space-y-6">
          <h2 class="text-xl font-semibold text-gray-900 mb-4">Informações Adicionais</h2>
          
          <div>
            <label class="block text-sm font-medium text-gray-700 mb-2">
              Observações
            </label>
            <textarea
              placeholder="Alguma informação adicional que gostaria de compartilhar..."
              value={formData.observacoes}
              on:input={(e) => formData.observacoes = e.target.value}
              class="w-full px-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent transition-colors"
              rows="4"
            ></textarea>
          </div>
        </div>
      {/if}
      
      <!-- Navigation buttons -->
      <div class="flex justify-between pt-6 border-t border-gray-200">
        <Button
          variant="outline"
          on:click={prevStep}
          disabled={currentStep === 1}
        >
          Anterior
        </Button>
        
        {#if currentStep < 3}
          <Button
            variant="primary"
            on:click={nextStep}
            disabled={!isStepValid(currentStep)}
          >
            Próximo
          </Button>
        {:else}
          <Button
            variant="primary"
            on:click={handleSubmit}
            loading={isLoading}
            disabled={isLoading}
          >
            {isLoading ? 'Completando...' : 'Completar Perfil'}
          </Button>
        {/if}
      </div>
    </div>
  </div>
</div>
