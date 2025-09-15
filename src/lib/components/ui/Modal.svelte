<script>
  import { createEventDispatcher } from 'svelte';
  import { clickOutside } from '$lib/utils/clickOutside';
  
  export let open = false;
  export let title = '';
  export let size = 'md'; // sm, md, lg, xl
  
  const dispatch = createEventDispatcher();
  
  const sizes = {
    sm: 'max-w-md',
    md: 'max-w-lg',
    lg: 'max-w-2xl',
    xl: 'max-w-4xl'
  };
  
  function handleClose() {
    dispatch('close');
  }
  
  function handleKeydown(event) {
    if (event.key === 'Escape') {
      handleClose();
    }
  }
</script>

<svelte:window on:keydown={handleKeydown} />

{#if open}
  <div class="fixed inset-0 z-50 overflow-y-auto" role="dialog" aria-modal="true">
    <!-- Backdrop -->
    <div class="fixed inset-0 bg-gray-500 bg-opacity-75 transition-opacity" on:click={handleClose}></div>
    
    <!-- Modal -->
    <div class="flex min-h-full items-center justify-center p-4">
      <div 
        class="relative bg-white rounded-lg shadow-xl transform transition-all w-full {sizes[size]}"
        use:clickOutside={handleClose}
      >
        <!-- Header -->
        {#if title}
          <div class="flex items-center justify-between p-6 border-b border-gray-200">
            <h3 class="text-lg font-medium text-gray-900">{title}</h3>
            <button
              type="button"
              class="text-gray-400 hover:text-gray-600 focus:outline-none focus:ring-2 focus:ring-blue-500 rounded-md p-1"
              on:click={handleClose}
            >
              <svg class="h-6 w-6" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12" />
              </svg>
            </button>
          </div>
        {/if}
        
        <!-- Content -->
        <div class="p-6">
          <slot />
        </div>
        
        <!-- Footer -->
        <div class="flex justify-end space-x-3 px-6 py-4 bg-gray-50 rounded-b-lg">
          <slot name="footer" />
        </div>
      </div>
    </div>
  </div>
{/if}
