<script>
  import { createEventDispatcher } from 'svelte';
  
  export let options = [];
  export let value = '';
  export let placeholder = 'Selecione uma opção';
  export let disabled = false;
  export let required = false;
  export let error = '';
  export let label = '';
  export let help = '';
  
  const dispatch = createEventDispatcher();
  
  const baseClasses = 'block w-full px-3 py-2 border rounded-md shadow-sm focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-blue-500 disabled:bg-gray-50 disabled:text-gray-500';
  const errorClasses = 'border-red-300 focus:ring-red-500 focus:border-red-500';
  const normalClasses = 'border-gray-300';
  
  $: classes = `${baseClasses} ${error ? errorClasses : normalClasses}`;
  
  function handleChange(event) {
    const newValue = event.target.value;
    value = newValue;
    dispatch('change', { value: newValue });
  }
</script>

<div class="space-y-1">
  {#if label}
    <label class="block text-sm font-medium text-gray-700">
      {label}
      {#if required}
        <span class="text-red-500">*</span>
      {/if}
    </label>
  {/if}
  
  <select
    {value}
    {disabled}
    {required}
    class={classes}
    on:change={handleChange}
  >
    <option value="" disabled>{placeholder}</option>
    {#each options as option}
      <option value={option.value}>{option.label}</option>
    {/each}
  </select>
  
  {#if error}
    <p class="text-sm text-red-600">{error}</p>
  {/if}
  
  {#if help && !error}
    <p class="text-sm text-gray-500">{help}</p>
  {/if}
</div>
