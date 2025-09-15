<script>
  import { createEventDispatcher } from 'svelte';
  import { validateInput, sanitizeInput } from '$lib/stores/security';
  
  const dispatch = createEventDispatcher();
  
  export let data = {};
  export let rules = {};
  export let sanitize = true;
  export let showErrors = true;
  
  let errors = {};
  let isValid = false;
  
  // Função para validar dados
  function validate() {
    const validation = validateInput(data, rules);
    errors = validation.errors;
    isValid = validation.isValid;
    
    dispatch('validation', { isValid, errors });
    
    return validation;
  }
  
  // Função para sanitizar dados
  function sanitizeData() {
    if (sanitize) {
      return sanitizeInput(data);
    }
    return data;
  }
  
  // Função para obter erro de um campo
  function getFieldError(field) {
    return errors[field] || '';
  }
  
  // Função para verificar se um campo tem erro
  function hasFieldError(field) {
    return !!errors[field];
  }
  
  // Função para limpar erros
  function clearErrors() {
    errors = {};
    isValid = false;
    dispatch('validation', { isValid, errors });
  }
  
  // Função para definir erro manualmente
  function setError(field, message) {
    errors[field] = message;
    isValid = false;
    dispatch('validation', { isValid, errors });
  }
  
  // Função para remover erro de um campo
  function clearFieldError(field) {
    if (errors[field]) {
      delete errors[field];
      isValid = Object.keys(errors).length === 0;
      dispatch('validation', { isValid, errors });
    }
  }
  
  // Reagir a mudanças nos dados
  $: if (data && rules) {
    validate();
  }
  
  // Expor funções para o componente pai
  export { validate, sanitizeData, getFieldError, hasFieldError, clearErrors, setError, clearFieldError };
</script>

<!-- Slot para o formulário -->
<slot {errors} {isValid} {getFieldError} {hasFieldError} {clearErrors} {setError} {clearFieldError} />

<!-- Exibir erros gerais se habilitado -->
{#if showErrors && Object.keys(errors).length > 0}
  <div class="bg-red-50 border border-red-200 rounded-lg p-4 mt-4">
    <div class="flex items-start space-x-2">
      <svg class="w-5 h-5 text-red-500 mt-0.5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8v4m0 4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
      </svg>
      <div>
        <h4 class="text-sm font-medium text-red-800">Corrija os seguintes erros:</h4>
        <ul class="mt-2 text-sm text-red-700 list-disc list-inside">
          {#each Object.entries(errors) as [field, error]}
            <li>{error}</li>
          {/each}
        </ul>
      </div>
    </div>
  </div>
{/if}
