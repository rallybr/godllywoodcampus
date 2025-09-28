<!-- Correção para o problema de clique nos dois primeiros cards -->
<!-- Substitua a seção do botão no arquivo src/routes/usuarios/+page.svelte -->

<!-- Botão de Ação -->
<div class="flex justify-center relative z-10">
  <button
    on:click={() => {
      console.log('Botão clicado para usuário:', usuario);
      abrirEditarModal(usuario);
    }}
    class="bg-gradient-to-r from-blue-600 to-indigo-600 hover:from-blue-700 hover:to-indigo-700 text-white font-semibold px-6 py-2.5 rounded-lg shadow-lg hover:shadow-xl transition-all duration-300 transform hover:scale-105 border-0 text-sm flex items-center justify-center relative z-20 cursor-pointer"
    style="pointer-events: auto; z-index: 20;"
  >
    <svg class="w-4 h-4 mr-2" fill="none" viewBox="0 0 24 24" stroke="currentColor">
      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M11 5H6a2 2 0 00-2 2v11a2 2 0 002 2h11a2 2 0 002-2v-5m-1.414-9.414a2 2 0 112.828 2.828L11.828 15H9v-2.828l8.586-8.586z" />
    </svg>
    Editar Usuário
  </button>
</div>
