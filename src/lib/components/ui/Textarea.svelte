<script>
  export let value = '';
  export let placeholder = '';
  export let rows = 3;
  export let disabled = false;
  export let className = '';
  export let id = '';
  export let name = '';
  
  let classes = `w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm focus:ring-2 focus:ring-blue-500 focus:border-transparent transition-colors resize-vertical ${className}`;
  
  if (disabled) {
    classes += ' bg-gray-100 cursor-not-allowed';
  }
</script>

<textarea
  {id}
  {name}
  {placeholder}
  {rows}
  {disabled}
  bind:value
  class={classes}
  on:input
  on:change
  on:focus
  on:blur
  on:keydown
  on:keyup
></textarea>
