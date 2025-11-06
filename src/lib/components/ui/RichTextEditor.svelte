<script>
  import { onMount, createEventDispatcher, onDestroy } from 'svelte';
  import { browser } from '$app/environment';
  
  const dispatch = createEventDispatcher();
  
  export let value = '';
  export let placeholder = 'Digite seu texto aqui...';
  export let rows = 6;
  
  let editorElement;
  let toolbarElement;
  let colorInputElement;
  let isInitialized = false;
  let lastValue = '';
  let DOMPurify = null;
  
  // Carregar DOMPurify apenas no browser
  if (browser) {
    import('dompurify').then(module => {
      DOMPurify = module.default;
      if (value && editorElement && !isInitialized) {
        initializeValue();
      }
    });
  }
  
  onMount(() => {
    if (editorElement && value) {
      initializeValue();
    }
  });
  
  function initializeValue() {
    if (!editorElement) return;
    if (DOMPurify && browser) {
      editorElement.innerHTML = DOMPurify.sanitize(value || '');
    } else {
      editorElement.innerHTML = value || '';
    }
    isInitialized = true;
    lastValue = value;
  }
  
  // Funções de formatação
  function formatCommand(command, val = null) {
    if (!browser || !editorElement) return;
    document.execCommand(command, false, val);
    editorElement.focus();
    updateValue();
  }
  
  function updateValue() {
    if (!browser || !editorElement) return;
    const content = editorElement.innerHTML;
    if (content !== lastValue) {
      lastValue = content;
      value = content;
      dispatch('change', content);
    }
  }
  
  function handleInput() {
    updateValue();
  }
  
  function handlePaste(event) {
    if (!browser) return;
    event.preventDefault();
    const text = event.clipboardData.getData('text/plain');
    document.execCommand('insertText', false, text);
    updateValue();
  }
  
  // Verificar se um comando está ativo
  function queryCommandState(command) {
    if (!browser) return false;
    try {
      return document.queryCommandState(command);
    } catch {
      return false;
    }
  }
  
  // Obter cor de texto atual
  function getCurrentColor() {
    if (!browser) return '#000000';
    try {
      const color = document.queryCommandValue('foreColor');
      return color === 'rgb(0, 0, 0)' || color === '' ? '#000000' : color;
    } catch {
      return '#000000';
    }
  }
  
  // Aplicar tamanho de fonte usando style inline (mais compatível)
  function applyFontSize(size) {
    if (!browser || !editorElement) return;
    
    const sizeMap = {
      'small': '0.875rem',    // 14px
      'normal': '1rem',       // 16px
      'large': '1.25rem',     // 20px
      'xlarge': '1.5rem'      // 24px
    };
    
    const fontSize = sizeMap[size] || '1rem';
    
    // Ativar uso de CSS em vez de tags HTML
    document.execCommand('styleWithCSS', false, true);
    
    // Usar insertHTML para aplicar estilo inline diretamente
    const selection = window.getSelection();
    if (selection.rangeCount > 0 && !selection.isCollapsed) {
      // Texto selecionado: aplicar estilo
      const range = selection.getRangeAt(0);
      const selectedText = range.toString();
      
      if (selectedText) {
        const span = document.createElement('span');
        span.style.fontSize = fontSize;
        span.textContent = selectedText;
        
        range.deleteContents();
        range.insertNode(span);
        
        // Selecionar o novo span
        const newRange = document.createRange();
        newRange.selectNodeContents(span);
        selection.removeAllRanges();
        selection.addRange(newRange);
      }
    } else {
      // Nenhum texto selecionado: usar execCommand com insertHTML
      const html = `<span style="font-size: ${fontSize}">${selection.toString() || ''}</span>`;
      document.execCommand('insertHTML', false, html);
    }
    
    // Converter qualquer tag font criada para span com style
    setTimeout(() => {
      const fontTags = editorElement.querySelectorAll('font[size]');
      fontTags.forEach(font => {
        const span = document.createElement('span');
        const size = font.getAttribute('size');
        const sizeMap = {
          '1': '0.625rem', '2': '0.75rem', '3': '0.875rem',
          '4': '1rem', '5': '1.125rem', '6': '1.25rem', '7': '1.5rem'
        };
        span.style.fontSize = sizeMap[size] || '1rem';
        span.innerHTML = font.innerHTML;
        if (font.parentNode) {
          font.parentNode.replaceChild(span, font);
        }
      });
      updateValue();
    }, 10);
    
    editorElement.focus();
    updateValue();
  }
  
  // Sincronizar valor externo (quando mudado de fora do componente)
  $: if (value !== lastValue && isInitialized && editorElement && browser) {
    const sanitized = DOMPurify ? DOMPurify.sanitize(value || '') : (value || '');
    if (editorElement.innerHTML !== sanitized) {
      // Atualizar apenas se o valor mudou externamente
      const currentContent = editorElement.innerHTML.trim();
      const sanitizedValue = sanitized.trim();
      if (currentContent !== sanitizedValue) {
        editorElement.innerHTML = sanitized;
        lastValue = value;
      }
    }
  }
  
  // Inicializar quando o elemento estiver disponível
  $: if (editorElement && value && !isInitialized && browser) {
    initializeValue();
  }
  
  // Limpar quando value for vazio
  $: if (value === '' && editorElement && isInitialized && browser && editorElement.innerHTML.trim() !== '') {
    editorElement.innerHTML = '';
    lastValue = '';
  }
</script>

<div class="rich-text-editor border border-gray-300 rounded-lg overflow-hidden bg-white">
  <!-- Toolbar -->
  {#if browser}
  <div 
    bind:this={toolbarElement}
    class="toolbar bg-gray-50 border-b border-gray-200 p-2 flex flex-wrap items-center gap-2"
  >
    <!-- Negrito -->
    <button
      type="button"
      on:click={() => formatCommand('bold')}
      class="toolbar-btn {queryCommandState('bold') ? 'active' : ''}"
      title="Negrito (Ctrl+B)"
    >
      <svg class="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 4h8a4 4 0 014 4 4 4 0 01-4 4H6zM6 12h9a4 4 0 014 4 4 4 0 01-4 4H6z" />
      </svg>
    </button>
    
    <!-- Itálico -->
    <button
      type="button"
      on:click={() => formatCommand('italic')}
      class="toolbar-btn {queryCommandState('italic') ? 'active' : ''}"
      title="Itálico (Ctrl+I)"
    >
      <svg class="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M10 20l4-16m4 4l4 4-4 4M6 16l-4-4 4-4" />
      </svg>
    </button>
    
    <!-- Sublinhado -->
    <button
      type="button"
      on:click={() => formatCommand('underline')}
      class="toolbar-btn {queryCommandState('underline') ? 'active' : ''}"
      title="Sublinhado (Ctrl+U)"
    >
      <svg class="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
        <path d="M6 4v8a6 6 0 0 0 6 6h0a6 6 0 0 0 6-6V4M4 20h16" />
      </svg>
    </button>
    
    <div class="w-px h-6 bg-gray-300"></div>
    
    <!-- Tamanho da fonte -->
    <select
      on:change={(e) => applyFontSize(e.target.value)}
      class="toolbar-select text-xs"
      title="Tamanho da fonte"
    >
      <option value="small">Pequeno</option>
      <option value="normal" selected>Normal</option>
      <option value="large">Grande</option>
      <option value="xlarge">Muito Grande</option>
    </select>
    
    <!-- Cor do texto -->
    <div class="relative w-8 h-8">
      <input
        bind:this={colorInputElement}
        type="color"
        value={getCurrentColor()}
        on:input={(e) => formatCommand('foreColor', e.target.value)}
        class="toolbar-color-input"
        title="Cor do texto"
      />
      <button
        type="button"
        class="toolbar-color-btn"
        title="Cor do texto"
        on:click={() => colorInputElement?.click()}
      >
        <svg class="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M7 21a4 4 0 01-4-4V5a2 2 0 012-2h4a2 2 0 012 2v12a4 4 0 01-4 4zm0 0h12a2 2 0 002-2v-4a2 2 0 00-2-2h-2.343M11 7.343l1.657-1.657a2 2 0 012.828 0l2.829 2.829a2 2 0 010 2.828l-8.486 8.485M7 17h.01" />
        </svg>
      </button>
    </div>
    
    <div class="w-px h-6 bg-gray-300"></div>
    
    <!-- Lista não ordenada -->
    <button
      type="button"
      on:click={() => formatCommand('insertUnorderedList')}
      class="toolbar-btn"
      title="Lista com marcadores"
    >
      <svg class="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 6h16M4 12h16M4 18h16" />
      </svg>
    </button>
    
    <!-- Lista ordenada -->
    <button
      type="button"
      on:click={() => formatCommand('insertOrderedList')}
      class="toolbar-btn"
      title="Lista numerada"
    >
      <svg class="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M7 20l4-16m2 16l4-16M6 9h14M4 15h14" />
      </svg>
    </button>
    
    <div class="w-px h-6 bg-gray-300"></div>
    
    <!-- Alinhamento -->
    <button
      type="button"
      on:click={() => formatCommand('justifyLeft')}
      class="toolbar-btn"
      title="Alinhar à esquerda"
    >
      <svg class="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3 10h18M3 14h18M3 6h18M3 18h18" />
      </svg>
    </button>
    
    <button
      type="button"
      on:click={() => formatCommand('justifyCenter')}
      class="toolbar-btn"
      title="Centralizar"
    >
      <svg class="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3 10h18M3 14h18M3 6h18M3 18h18" />
      </svg>
    </button>
    
    <button
      type="button"
      on:click={() => formatCommand('justifyRight')}
      class="toolbar-btn"
      title="Alinhar à direita"
    >
      <svg class="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3 10h18M3 14h18M3 6h18M3 18h18" />
      </svg>
    </button>
    
    <div class="w-px h-6 bg-gray-300"></div>
    
    <!-- Remover formatação -->
    <button
      type="button"
      on:click={() => formatCommand('removeFormat')}
      class="toolbar-btn"
      title="Remover formatação"
    >
      <svg class="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12" />
      </svg>
    </button>
  </div>
  {/if}
  
  <!-- Editor -->
  {#if browser}
    <div
      bind:this={editorElement}
      contenteditable="true"
      on:input={handleInput}
      on:paste={handlePaste}
      class="editor-content p-3 min-h-[{rows * 1.5}rem] focus:outline-none focus:ring-2 focus:ring-blue-500"
      style="white-space: pre-wrap; word-wrap: break-word;"
      data-placeholder={placeholder}
    ></div>
  {:else}
    <div class="editor-content p-3 min-h-[{rows * 1.5}rem] bg-gray-50 border border-gray-200 rounded">
      <p class="text-gray-400 text-sm">Carregando editor...</p>
    </div>
  {/if}
</div>

<style>
  .toolbar-btn {
    padding: 0.25rem 0.5rem;
    border-radius: 0.25rem;
    transition: background-color 0.2s, border-color 0.2s;
    display: flex;
    align-items: center;
    justify-content: center;
    border: 1px solid transparent;
  }
  
  .toolbar-btn:hover {
    background-color: rgb(229 231 235);
    border-color: rgb(209 213 219);
  }
  
  .toolbar-btn.active {
    background-color: rgb(219 234 254);
    border-color: rgb(147 197 253);
    color: rgb(29 78 216);
  }
  
  .toolbar-select {
    padding: 0.25rem 0.5rem;
    border-radius: 0.25rem;
    border: 1px solid rgb(209 213 219);
    background-color: white;
    font-size: 0.75rem;
  }
  
  .toolbar-select:hover {
    background-color: rgb(249 250 251);
  }
  
  .toolbar-select:focus {
    outline: none;
    box-shadow: 0 0 0 2px rgb(59 130 246 / 0.5);
    border-color: rgb(59 130 246);
  }
  
  .toolbar-color-input {
    width: 100%;
    height: 100%;
    position: absolute;
    inset: 0;
    opacity: 0;
    cursor: pointer;
  }
  
  .toolbar-color-btn {
    width: 100%;
    height: 100%;
    display: flex;
    align-items: center;
    justify-content: center;
    border-radius: 0.25rem;
    border: 1px solid transparent;
  }
  
  .toolbar-color-btn:hover {
    background-color: rgb(229 231 235);
    border-color: rgb(209 213 219);
  }
  
  .editor-content[contenteditable="true"]:empty:before {
    content: attr(data-placeholder);
    color: rgb(156 163 175);
  }
  
  .editor-content {
    color: rgb(55 65 81);
  }
  
  .editor-content :global(p) {
    margin-bottom: 0.5rem;
  }
  
  .editor-content :global(ul),
  .editor-content :global(ol) {
    margin-left: 1.5rem;
    margin-bottom: 0.5rem;
  }
  
  .editor-content :global(li) {
    margin-bottom: 0.25rem;
  }
</style>

