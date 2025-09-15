<script>
  export let title = '';
  export let subtitle = '';
  export let actions = false;
  export let padding = 'p-6';
  export let hover = false;
</script>

<div class="w-full bg-white rounded-lg shadow-sm border border-gray-200 {hover ? 'hover:shadow-md transition-shadow duration-200' : ''}">
  {#if title || subtitle || actions}
    <div class="px-6 py-4 border-b border-gray-200">
      <div class="flex items-center justify-between">
        <div>
          {#if title}
            <h3 class="text-lg font-medium text-gray-900">{title}</h3>
          {/if}
          {#if subtitle}
            <p class="mt-1 text-sm text-gray-500">{subtitle}</p>
          {/if}
        </div>
        {#if actions}
          <div class="flex space-x-2">
            <slot name="actions" />
          </div>
        {/if}
      </div>
    </div>
  {/if}
  
  <div class={padding}>
    <slot />
  </div>
</div>
