<script>
  import { createEventDispatcher } from 'svelte';
  
  export let type = 'text';
  export let placeholder = '';
  export let value = '';
  export let disabled = false;
  export let required = false;
  export let error = '';
  export let label = '';
  export let help = '';
  
  const dispatch = createEventDispatcher();
  
  const baseClasses = 'block w-full px-3 py-2 border rounded-md shadow-sm placeholder-gray-400 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-blue-500 disabled:bg-gray-50 disabled:text-gray-500';
  const errorClasses = 'border-red-300 focus:ring-red-500 focus:border-red-500';
  const normalClasses = 'border-gray-300';
  
  $: classes = `${baseClasses} ${error ? errorClasses : normalClasses}`;
  
  function handleInput(event) {
    value = event.target.value;
    dispatch('input', { value });
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
  
  <input
    {type}
    {placeholder}
    {value}
    {disabled}
    {required}
    class={classes}
    on:input={handleInput}
  />
  
  {#if error}
    <p class="text-sm text-red-600">{error}</p>
  {/if}
  
  {#if help && !error}
    <p class="text-sm text-gray-500">{help}</p>
  {/if}
</div>
