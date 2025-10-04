<script>
  import { onMount } from 'svelte';
  import { loadUsuariosAssociadosJovem, desassociarJovemUsuario } from '$lib/stores/estatisticas';
  import { userProfile } from '$lib/stores/auth';
  import { getUserLevelName } from '$lib/stores/niveis-acesso';
  
  export let jovemId;
  export let onDesassociacao = () => {};
  
  let associacoes = [];
  let loading = false;
  let error = null;
  let desassociando = null; // ID do usuário sendo desassociado
  
  onMount(async () => {
    if (jovemId) {
      await carregarAssociacoes();
    }
  });
  
  async function carregarAssociacoes() {
    loading = true;
    error = null;
    
    try {
      associacoes = await loadUsuariosAssociadosJovem(jovemId);
    } catch (err) {
      console.error('Erro ao carregar associações:', err);
      error = err.message || 'Erro ao carregar associações';
    } finally {
      loading = false;
    }
  }
  
  async function handleDesassociar(usuarioId, usuarioNome) {
    if (!confirm(`Tem certeza que deseja desassociar este jovem de ${usuarioNome}?`)) {
      return;
    }
    
    desassociando = usuarioId;
    
    try {
      await desassociarJovemUsuario(jovemId, usuarioId);
      
      // Remover da lista local
      associacoes = associacoes.filter(assoc => assoc.usuario_id !== usuarioId);
      
      // Notificar componente pai
      onDesassociacao();
      
      // Mostrar mensagem de sucesso
      alert('Jovem desassociado com sucesso!');
      
    } catch (err) {
      console.error('Erro ao desassociar:', err);
      alert('Erro ao desassociar jovem: ' + (err.message || 'Erro desconhecido'));
    } finally {
      desassociando = null;
    }
  }
  
  function getNivelNome(nivel) {
    const niveis = {
      'administrador': 'Administrador',
      'lider_nacional_iurd': 'Líder Nacional IURD',
      'lider_nacional_fju': 'Líder Nacional FJU',
      'lider_estadual_iurd': 'Líder Estadual IURD',
      'lider_estadual_fju': 'Líder Estadual FJU',
      'lider_bloco_iurd': 'Líder de Bloco IURD',
      'lider_bloco_fju': 'Líder de Bloco FJU',
      'lider_regional_iurd': 'Líder Regional IURD',
      'lider_igreja_iurd': 'Líder de Igreja IURD',
      'colaborador': 'Colaborador',
      'jovem': 'Jovem'
    };
    return niveis[nivel] || nivel;
  }
  
  function getNivelCor(nivel) {
    const cores = {
      'administrador': 'bg-red-100 text-red-800',
      'lider_nacional_iurd': 'bg-purple-100 text-purple-800',
      'lider_nacional_fju': 'bg-purple-100 text-purple-800',
      'lider_estadual_iurd': 'bg-blue-100 text-blue-800',
      'lider_estadual_fju': 'bg-blue-100 text-blue-800',
      'lider_bloco_iurd': 'bg-green-100 text-green-800',
      'lider_bloco_fju': 'bg-green-100 text-green-800',
      'lider_regional_iurd': 'bg-yellow-100 text-yellow-800',
      'lider_igreja_iurd': 'bg-orange-100 text-orange-800',
      'colaborador': 'bg-teal-100 text-teal-800',
      'jovem': 'bg-pink-100 text-pink-800'
    };
    return cores[nivel] || 'bg-gray-100 text-gray-800';
  }
</script>

<!-- Só mostrar para administradores -->
{#if getUserLevelName($userProfile) === 'Administrador'}
  <div class="bg-white rounded-lg shadow-sm border border-gray-200 p-6">
    <div class="flex items-center justify-between mb-4">
      <div>
        <h3 class="text-lg font-semibold text-gray-900">Associações do Jovem</h3>
        <p class="text-sm text-gray-500">Usuários aos quais este jovem está associado</p>
      </div>
      <button
        on:click={carregarAssociacoes}
        class="p-2 text-gray-400 hover:text-gray-600 transition-colors"
        disabled={loading}
      >
        <svg class="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor" class:animate-spin={loading}>
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 4v5h.582m15.356 2A8.001 8.001 0 004.582 9m0 0H9m11 11v-5h-.581m0 0a8.003 8.003 0 01-15.357-2m15.357 2H15" />
        </svg>
      </button>
    </div>
    
    {#if loading}
      <div class="space-y-3">
        {#each Array(2) as _}
          <div class="flex items-center space-x-3 p-4 bg-gray-50 rounded-lg animate-pulse">
            <div class="w-10 h-10 bg-gray-200 rounded-full"></div>
            <div class="flex-1">
              <div class="h-4 bg-gray-200 rounded w-3/4 mb-2"></div>
              <div class="h-3 bg-gray-200 rounded w-1/2"></div>
            </div>
            <div class="w-20 h-8 bg-gray-200 rounded"></div>
          </div>
        {/each}
      </div>
    {:else if error}
      <div class="text-center py-8">
        <div class="text-red-500 mb-2">
          <svg class="w-8 h-8 mx-auto" fill="none" viewBox="0 0 24 24" stroke="currentColor">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-2.5L13.732 4c-.77-.833-1.964-.833-2.732 0L3.732 16.5c-.77.833.192 2.5 1.732 2.5z" />
          </svg>
        </div>
        <p class="text-red-600 font-medium">Erro ao carregar associações</p>
        <p class="text-gray-500 text-sm">{error}</p>
        <button
          on:click={carregarAssociacoes}
          class="mt-3 px-4 py-2 bg-red-100 text-red-700 rounded-lg hover:bg-red-200 transition-colors"
        >
          Tentar novamente
        </button>
      </div>
    {:else if associacoes.length === 0}
      <div class="text-center py-8">
        <div class="text-gray-400 mb-2">
          <svg class="w-8 h-8 mx-auto" fill="none" viewBox="0 0 24 24" stroke="currentColor">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M17 20h5v-2a3 3 0 00-5.356-1.857M17 20H7m10 0v-2c0-.656-.126-1.283-.356-1.857M7 20H2v-2a3 3 0 015.356-1.857M7 20v-2c0-.656.126-1.283.356-1.857m0 0a5.002 5.002 0 019.288 0M15 7a3 3 0 11-6 0 3 3 0 016 0zm6 3a2 2 0 11-4 0 2 2 0 014 0zM7 10a2 2 0 11-4 0 2 2 0 014 0z" />
          </svg>
        </div>
        <p class="text-gray-600 font-medium">Nenhuma associação encontrada</p>
        <p class="text-gray-500 text-sm">Este jovem não está associado a nenhum usuário</p>
      </div>
    {:else}
      <div class="space-y-3">
        {#each associacoes as associacao}
          <div class="flex items-center justify-between p-4 bg-gray-50 rounded-lg hover:bg-gray-100 transition-colors">
            <div class="flex items-center space-x-3">
              <!-- Avatar -->
              <div class="w-10 h-10 bg-blue-100 rounded-full flex items-center justify-center">
                <svg class="w-5 h-5 text-blue-600" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M16 7a4 4 0 11-8 0 4 4 0 018 0zM12 14a7 7 0 00-7 7h14a7 7 0 00-7-7z" />
                </svg>
              </div>
              
              <!-- Informações do usuário -->
              <div class="flex-1 min-w-0">
                <div class="flex items-center space-x-2 mb-1">
                  <h4 class="font-medium text-gray-900 truncate">{associacao.usuario.nome}</h4>
                  <span class="px-2 py-1 text-xs font-medium rounded-full {getNivelCor(associacao.usuario.nivel)}">
                    {getNivelNome(associacao.usuario.nivel)}
                  </span>
                </div>
                <div class="text-sm text-gray-500">
                  <p class="truncate">{associacao.usuario.email}</p>
                  {#if associacao.usuario.estado}
                    <p class="truncate">
                      {associacao.usuario.estado.nome}
                      {#if associacao.usuario.bloco} • {associacao.usuario.bloco.nome}{/if}
                      {#if associacao.usuario.regiao} • {associacao.usuario.regiao.nome}{/if}
                      {#if associacao.usuario.igreja} • {associacao.usuario.igreja.nome}{/if}
                    </p>
                  {/if}
                </div>
              </div>
            </div>
            
            <!-- Botão desassociar -->
            <button
              on:click={() => handleDesassociar(associacao.usuario_id, associacao.usuario.nome)}
              disabled={desassociando === associacao.usuario_id}
              class="px-3 py-2 text-sm font-medium text-red-700 bg-red-100 rounded-lg hover:bg-red-200 disabled:opacity-50 disabled:cursor-not-allowed transition-colors"
            >
              {#if desassociando === associacao.usuario_id}
                <svg class="w-4 h-4 animate-spin" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 4v5h.582m15.356 2A8.001 8.001 0 004.582 9m0 0H9m11 11v-5h-.581m0 0a8.003 8.003 0 01-15.357-2m15.357 2H15" />
                </svg>
              {:else}
                <svg class="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12" />
                </svg>
              {/if}
              <span class="ml-1">Desassociar</span>
            </button>
          </div>
        {/each}
      </div>
    {/if}
  </div>
{/if}
