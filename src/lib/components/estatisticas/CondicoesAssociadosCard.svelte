<script>
  import { onMount } from 'svelte';
  import { condicoesAssociadosStats, loadCondicoesAssociadosStats } from '$lib/stores/estatisticas';
  import { userProfile } from '$lib/stores/auth';
  import { getUserLevelName } from '$lib/stores/niveis-acesso';
  
  let loading = false;
  
  onMount(async () => {
    if ($userProfile?.id) {
      loading = true;
      try {
        await loadCondicoesAssociadosStats($userProfile.id);
      } catch (error) {
        console.error('Erro ao carregar condições dos jovens associados:', error);
      } finally {
        loading = false;
      }
    }
  });
</script>

<!-- Card de Condições dos Jovens Associados (não mostrar para jovens) -->
{#if getUserLevelName($userProfile) !== 'Jovem'}
<div class="space-y-4">
  <!-- Título do Card -->
  <div class="fb-card p-4">
    <div class="flex items-center space-x-3 mb-4">
      <div class="w-10 h-10 bg-indigo-100 rounded-full flex items-center justify-center">
        <svg class="w-5 h-5 text-indigo-600" fill="none" viewBox="0 0 24 24" stroke="currentColor">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M17 20h5v-2a3 3 0 00-5.356-1.857M17 20H7m10 0v-2c0-.656-.126-1.283-.356-1.857M7 20H2v-2a3 3 0 015.356-1.857M7 20v-2c0-.656.126-1.283.356-1.857m0 0a5.002 5.002 0 019.288 0M15 7a3 3 0 11-6 0 3 3 0 016 0zm6 3a2 2 0 11-4 0 2 2 0 014 0zM7 10a2 2 0 11-4 0 2 2 0 014 0z" />
        </svg>
      </div>
      <div>
        <h3 class="text-lg font-semibold text-gray-900">CONDIÇÃO DOS JOVENS ASSOCIADOS</h3>
        <p class="text-sm text-gray-500">Condições dos jovens associados a você</p>
      </div>
    </div>
    
    {#if loading}
      <div class="grid grid-cols-2 sm:grid-cols-3 lg:grid-cols-6 gap-3 sm:gap-4">
        {#each Array(6) as _}
          <div class="text-center">
            <div class="w-12 h-12 bg-gray-200 rounded-full mx-auto mb-2 animate-pulse"></div>
            <div class="h-8 bg-gray-200 rounded w-16 mx-auto mb-2 animate-pulse"></div>
            <div class="h-4 bg-gray-200 rounded w-20 mx-auto animate-pulse"></div>
          </div>
        {/each}
      </div>
    {:else}
      <div class="grid grid-cols-2 sm:grid-cols-3 lg:grid-cols-6 gap-3 sm:gap-4">
        <!-- Aux. de Pastor -->
        <a href="/condicoes?condicao=auxiliar_pastor&associados=true" class="text-center group cursor-pointer hover:bg-gray-50 rounded-lg p-3 sm:p-4 transition-colors">
          <div class="w-10 h-10 sm:w-12 sm:h-12 bg-purple-100 rounded-full flex items-center justify-center mx-auto mb-2 group-hover:bg-purple-200 transition-colors">
            <svg class="w-5 h-5 sm:w-6 sm:h-6 text-purple-600" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 21V5a2 2 0 00-2-2H7a2 2 0 00-2 2v16m14 0h2m-2 0h-5m-9 0H3m2 0h5M9 7h1m-1 4h1m4-4h1m-1 4h1m-5 10v-5a1 1 0 011-1h2a1 1 0 011 1v5m-4 0h4" />
            </svg>
          </div>
          <p class="text-xl sm:text-2xl font-bold text-gray-900 group-hover:text-purple-600 transition-colors">{$condicoesAssociadosStats.auxPastor}</p>
          <p class="text-xs sm:text-sm text-gray-500 group-hover:text-gray-700 transition-colors">Aux. de Pastor</p>
        </a>
        
        <!-- IBURD -->
        <a href="/condicoes?condicao=iburd&associados=true" class="text-center group cursor-pointer hover:bg-gray-50 rounded-lg p-3 sm:p-4 transition-colors">
          <div class="w-10 h-10 sm:w-12 sm:h-12 bg-blue-100 rounded-full flex items-center justify-center mx-auto mb-2 group-hover:bg-blue-200 transition-colors">
            <svg class="w-5 h-5 sm:w-6 sm:h-6 text-blue-600" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4.354a4 4 0 110 5.292M15 21H3v-1a6 6 0 0112 0v1zm0 0h6v-1a6 6 0 00-9-5.197m13.5-9a2.5 2.5 0 11-5 0 2.5 2.5 0 015 0z" />
            </svg>
          </div>
          <p class="text-xl sm:text-2xl font-bold text-gray-900 group-hover:text-blue-600 transition-colors">{$condicoesAssociadosStats.iburd}</p>
          <p class="text-xs sm:text-sm text-gray-500 group-hover:text-gray-700 transition-colors">IBURD</p>
        </a>
        
        <!-- Obreiro -->
        <a href="/condicoes?condicao=obreiro&associados=true" class="text-center group cursor-pointer hover:bg-gray-50 rounded-lg p-3 sm:p-4 transition-colors">
          <div class="w-10 h-10 sm:w-12 sm:h-12 bg-green-100 rounded-full flex items-center justify-center mx-auto mb-2 group-hover:bg-green-200 transition-colors">
            <svg class="w-5 h-5 sm:w-6 sm:h-6 text-green-600" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12l2 2 4-4m5.618-4.016A11.955 11.955 0 0112 2.944a11.955 11.955 0 01-8.618 3.04A12.02 12.02 0 003 9c0 5.591 3.824 10.29 9 11.622 5.176-1.332 9-6.03 9-11.622 0-1.042-.133-2.052-.382-3.016z" />
            </svg>
          </div>
          <p class="text-xl sm:text-2xl font-bold text-gray-900 group-hover:text-green-600 transition-colors">{$condicoesAssociadosStats.obreiro}</p>
          <p class="text-xs sm:text-sm text-gray-500 group-hover:text-gray-700 transition-colors">Obreiro</p>
        </a>
        
        <!-- Colaborador -->
        <a href="/condicoes?condicao=colaborador&associados=true" class="text-center group cursor-pointer hover:bg-gray-50 rounded-lg p-3 sm:p-4 transition-colors">
          <div class="w-10 h-10 sm:w-12 sm:h-12 bg-orange-100 rounded-full flex items-center justify-center mx-auto mb-2 group-hover:bg-orange-200 transition-colors">
            <svg class="w-5 h-5 sm:w-6 sm:h-6 text-orange-600" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M17 20h5v-2a3 3 0 00-5.356-1.857M17 20H7m10 0v-2c0-.656-.126-1.283-.356-1.857M7 20H2v-2a3 3 0 015.356-1.857M7 20v-2c0-.656.126-1.283.356-1.857m0 0a5.002 5.002 0 019.288 0M15 7a3 3 0 11-6 0 3 3 0 016 0zm6 3a2 2 0 11-4 0 2 2 0 014 0zM7 10a2 2 0 11-4 0 2 2 0 014 0z" />
            </svg>
          </div>
          <p class="text-xl sm:text-2xl font-bold text-gray-900 group-hover:text-orange-600 transition-colors">{$condicoesAssociadosStats.colaborador}</p>
          <p class="text-xs sm:text-sm text-gray-500 group-hover:text-gray-700 transition-colors">Colaborador</p>
        </a>
        
        <!-- CPO -->
        <a href="/condicoes?condicao=cpo&associados=true" class="text-center group cursor-pointer hover:bg-gray-50 rounded-lg p-3 sm:p-4 transition-colors">
          <div class="w-10 h-10 sm:w-12 sm:h-12 bg-teal-100 rounded-full flex items-center justify-center mx-auto mb-2 group-hover:bg-teal-200 transition-colors">
            <svg class="w-5 h-5 sm:w-6 sm:h-6 text-teal-600" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z" />
            </svg>
          </div>
          <p class="text-xl sm:text-2xl font-bold text-gray-900 group-hover:text-teal-600 transition-colors">{$condicoesAssociadosStats.cpo}</p>
          <p class="text-xs sm:text-sm text-gray-500 group-hover:text-gray-700 transition-colors">CPO</p>
        </a>
        
        <!-- Jovem -->
        <a href="/condicoes?condicao=jovem_batizado_es&associados=true" class="text-center group cursor-pointer hover:bg-gray-50 rounded-lg p-3 sm:p-4 transition-colors">
          <div class="w-10 h-10 sm:w-12 sm:h-12 bg-pink-100 rounded-full flex items-center justify-center mx-auto mb-2 group-hover:bg-pink-200 transition-colors">
            <svg class="w-5 h-5 sm:w-6 sm:h-6 text-pink-600" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M16 7a4 4 0 11-8 0 4 4 0 018 0zM12 14a7 7 0 00-7 7h14a7 7 0 00-7-7z" />
            </svg>
          </div>
          <p class="text-xl sm:text-2xl font-bold text-gray-900 group-hover:text-pink-600 transition-colors">{$condicoesAssociadosStats.batizadoES}</p>
          <p class="text-xs sm:text-sm text-gray-500 group-hover:text-gray-700 transition-colors">Jovem</p>
        </a>
      </div>
    {/if}
  </div>
</div>
{/if}
