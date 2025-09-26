<script>
  import { onMount } from 'svelte';
  import { supabase } from '$lib/utils/supabase';
  import Card from '$lib/components/ui/Card.svelte';
  import Button from '$lib/components/ui/Button.svelte';
  import ProgressoTimeline from '$lib/components/progresso/ProgressoTimeline.svelte';

  export let targetUser;

  let loading = true;
  let error = '';
  let jovem = null;
  let totalAval = 0;
  let mediaNota = null;
  let ultimaData = null;
  let avaliacoes = [];
  let page = 1;
  const pageSize = 10;
  let hasMore = false;
  let loadingMore = false;

  // Função para formatar data
  function formatDate(dateString) {
    if (!dateString) return 'N/A';
    return new Date(dateString).toLocaleDateString('pt-BR');
  }

  async function loadKpis(jovemId) {
    try {
      // Total de avaliações
      const { count: totalCount, error: cErr } = await supabase
        .from('avaliacoes')
        .select('id', { count: 'exact', head: true })
        .eq('jovem_id', jovemId);
      if (cErr) throw cErr;
      totalAval = totalCount || 0;

      // Média e última data
      const { data: ult, error: uErr } = await supabase
        .from('avaliacoes')
        .select('criado_em, nota')
        .eq('jovem_id', jovemId)
        .order('criado_em', { ascending: false })
        .limit(1);
      if (uErr) throw uErr;
      ultimaData = ult?.[0]?.criado_em ? new Date(ult[0].criado_em) : null;

      const { data: notas, error: nErr } = await supabase
        .from('avaliacoes')
        .select('nota')
        .eq('jovem_id', jovemId);
      if (nErr) throw nErr;
      if (notas && notas.length) {
        const valid = notas.map(n => Number(n.nota)).filter(n => !Number.isNaN(n));
        mediaNota = valid.length ? (valid.reduce((a,b)=>a+b,0) / valid.length) : null;
      } else mediaNota = null;
    } catch (e) {
      console.error('Erro ao carregar KPIs:', e);
    }
  }

  async function loadTimeline(jovemId, reset = false) {
    try {
      const from = (page - 1) * pageSize;
      const to = from + pageSize - 1;
      const { data, error: e, count } = await supabase
        .from('avaliacoes')
        .select('id, espirito, caractere, disposicao, nota, criado_em, user_id', { count: 'exact' })
        .eq('jovem_id', jovemId)
        .order('criado_em', { ascending: false })
        .range(from, to);
      if (e) throw e;
      if (reset) avaliacoes = [];
      avaliacoes = [...avaliacoes, ...(data || [])];
      hasMore = count != null ? to + 1 < count : (data?.length === pageSize);
    } catch (e) {
      console.error('Erro ao carregar timeline:', e);
    }
  }

  async function loadData() {
    try {
      loading = true;
      error = '';

      console.log('=== CARREGANDO PERFIL IMPERSONADO ===');
      console.log('Usuário alvo:', targetUser);

      if (!targetUser?.id) return;

      // Buscar o jovem vinculado ao usuário alvo
      const { data: jovemData, error: jErr } = await supabase
        .from('jovens')
        .select('*')
        .eq('usuario_id', targetUser.id)
        .limit(1)
        .maybeSingle();
      if (jErr) throw jErr;
      jovem = jovemData;

      console.log('Jovem encontrado:', jovem);

      if (jovem?.id) {
        await loadKpis(jovem.id);
        page = 1;
        await loadTimeline(jovem.id, true);
      }
    } catch (e) {
      error = e?.message || 'Falha ao carregar dados do perfil';
      console.error('Perfil impersonado - erro:', e);
    } finally {
      loading = false;
    }
  }

  async function loadMore() {
    if (!jovem?.id || loadingMore || !hasMore) return;
    try {
      loadingMore = true;
      page += 1;
      await loadTimeline(jovem.id);
    } finally {
      loadingMore = false;
    }
  }

  onMount(loadData);
</script>

{#if loading}
  <div class="flex items-center justify-center py-12">
    <div class="animate-spin rounded-full h-8 w-8 border-b-2 border-blue-600"></div>
  </div>
{:else if error}
  <Card class="p-6">
    <div class="text-center text-red-600">
      <p>{error}</p>
    </div>
  </Card>
{:else}
  <div class="space-y-6">
    <!-- Banner de Impersonação -->
    <Card class="p-4 bg-blue-50 border-blue-200">
      <div class="flex items-center space-x-3">
        <div class="text-blue-600">
          <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 12a3 3 0 11-6 0 3 3 0 016 0z" />
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M2.458 12C3.732 7.943 7.523 5 12 5c4.478 0 8.268 2.943 9.542 7-1.274 4.057-5.064 7-9.542 7-4.477 0-8.268-2.943-9.542-7z" />
          </svg>
        </div>
        <div>
          <p class="text-sm font-medium text-blue-900">
            Visualizando como: <strong>{targetUser.nome}</strong>
          </p>
          <p class="text-xs text-blue-700">
            Você está vendo o perfil exatamente como este usuário o vê
          </p>
        </div>
      </div>
    </Card>

    <!-- Perfil do Usuário (igual ao perfil próprio) -->
    <Card class="p-6">
      <div class="flex items-start space-x-6">
        <!-- Avatar -->
        <div class="flex-shrink-0">
          {#if targetUser.foto}
            <img
              class="w-20 h-20 rounded-full object-cover"
              src={targetUser.foto}
              alt={targetUser.nome}
            />
          {:else}
            <div class="w-20 h-20 rounded-full bg-gradient-to-br from-blue-500 to-purple-600 flex items-center justify-center">
              <span class="text-white font-bold text-2xl">
                {targetUser.nome?.charAt(0) || 'U'}
              </span>
            </div>
          {/if}
        </div>

        <!-- Informações -->
        <div class="flex-1 min-w-0">
          <h1 class="text-2xl font-bold text-gray-900 truncate">
            {targetUser.nome || 'Usuário'}
          </h1>
          
          <div class="space-y-1 text-sm text-gray-600 mt-2">
            <p><strong>Email:</strong> {targetUser.email}</p>
            <p><strong>Cadastrado em:</strong> {formatDate(targetUser.criado_em)}</p>
            {#if targetUser.ultimo_acesso}
              <p><strong>Último acesso:</strong> {formatDate(targetUser.ultimo_acesso)}</p>
            {/if}
          </div>
        </div>
      </div>
    </Card>

    <!-- Informações do Jovem (se existir) -->
    {#if jovem}
      <Card class="p-6">
        <h2 class="text-lg font-semibold text-gray-900 mb-4">Meu Perfil de Jovem</h2>
        
        <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
          <div>
            <p class="text-sm text-gray-600"><strong>Nome Completo:</strong></p>
            <p class="text-gray-900">{jovem.nome_completo}</p>
          </div>
          
          {#if jovem.whatsapp}
            <div>
              <p class="text-sm text-gray-600"><strong>WhatsApp:</strong></p>
              <p class="text-gray-900">{jovem.whatsapp}</p>
            </div>
          {/if}
          
          {#if jovem.estado}
            <div>
              <p class="text-sm text-gray-600"><strong>Estado:</strong></p>
              <p class="text-gray-900">{jovem.estado}</p>
            </div>
          {/if}
          
          {#if jovem.cidade}
            <div>
              <p class="text-sm text-gray-600"><strong>Cidade:</strong></p>
              <p class="text-gray-900">{jovem.cidade}</p>
            </div>
          {/if}
        </div>
      </Card>

      <!-- KPIs de Avaliação -->
      <div class="grid grid-cols-1 md:grid-cols-3 gap-6">
        <Card class="p-6 text-center">
          <div class="text-3xl font-bold text-blue-600 mb-2">{totalAval}</div>
          <div class="text-sm text-gray-600">Total de Avaliações</div>
        </Card>
        
        <Card class="p-6 text-center">
          <div class="text-3xl font-bold text-green-600 mb-2">
            {mediaNota ? mediaNota.toFixed(1) : 'N/A'}
          </div>
          <div class="text-sm text-gray-600">Média das Notas</div>
        </Card>
        
        <Card class="p-6 text-center">
          <div class="text-3xl font-bold text-purple-600 mb-2">
            {ultimaData ? ultimaData.toLocaleDateString('pt-BR') : 'N/A'}
          </div>
          <div class="text-sm text-gray-600">Última Avaliação</div>
        </Card>
      </div>

      <!-- Timeline de Avaliações -->
      {#if avaliacoes.length > 0}
        <Card class="p-6">
          <h2 class="text-lg font-semibold text-gray-900 mb-4">Meu Histórico de Avaliações</h2>
          <ProgressoTimeline {avaliacoes} />
          
          {#if hasMore}
            <div class="text-center mt-4">
              <Button 
                variant="outline" 
                on:click={loadMore}
                disabled={loadingMore}
              >
                {loadingMore ? 'Carregando...' : 'Carregar Mais'}
              </Button>
            </div>
          {/if}
        </Card>
      {/if}
    {:else}
      <Card class="p-6">
        <div class="text-center text-gray-500">
          <svg class="w-12 h-12 mx-auto mb-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M16 7a4 4 0 11-8 0 4 4 0 018 0zM12 14a7 7 0 00-7 7h14a7 7 0 00-7-7z" />
          </svg>
          <p>Este usuário ainda não possui perfil de jovem cadastrado.</p>
        </div>
      </Card>
    {/if}
  </div>
{/if}
