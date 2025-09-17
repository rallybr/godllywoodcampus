<script>
  export const ssr = false;
  export const prerender = false;
  import { onMount } from 'svelte';
  import { supabase } from '$lib/utils/supabase';
  import Card from '$lib/components/ui/Card.svelte';
  import Button from '$lib/components/ui/Button.svelte';
  import Input from '$lib/components/ui/Input.svelte';

  let loading = true;
  let error = '';
  let sessoes = [];
  let usuarios = new Map();

  // filtros
  let filtroUserId = '';
  let filtroAtivo = 'todos'; // 'todos' | 'ativos' | 'revogados'

  async function carregarUsuarios(ids){
    const falt = ids.filter(id=>id && !usuarios.has(id));
    if(!falt.length) return;
    const { data } = await supabase.from('usuarios').select('id,nome').in('id', falt);
    (data||[]).forEach(u=>usuarios.set(u.id,u));
  }

  function nomeUsuario(id){ return usuarios.get(id)?.nome || id; }

  async function loadSessoes() {
    try {
      loading = true; error = '';
      let q = supabase.from('sessoes_usuario').select('*').order('criado_em', { ascending: false });
      if (filtroUserId) q = q.eq('usuario_id', filtroUserId);
      if (filtroAtivo === 'ativos') q = q.eq('ativo', true);
      if (filtroAtivo === 'revogados') q = q.eq('ativo', false);
      const { data, error: e } = await q;
      if (e) throw e;
      sessoes = data || [];
      await carregarUsuarios([...new Set(sessoes.map(s=>s.usuario_id).filter(Boolean))]);
    } catch (e) {
      error = e?.message || 'Falha ao carregar sessões';
    } finally {
      loading = false;
    }
  }

  async function revogarSessao(id) {
    if (!confirm('Revogar esta sessão?')) return;
    try {
      const { error: e } = await supabase
        .from('sessoes_usuario')
        .update({ ativo: false, expira_em: new Date().toISOString() })
        .eq('id', id);
      if (e) throw e;
      await loadSessoes();
      alert('Sessão revogada.');
    } catch (e) {
      alert(e?.message || 'Falha ao revogar sessão');
    }
  }

  function exportarCSV(){
    const header = 'Usuario,IP,UserAgent,Ativo,Criado,Expira\n';
    const rows = (sessoes||[]).map(s=>[
      JSON.stringify(nomeUsuario(s.usuario_id)),
      JSON.stringify(s.ip_address||''),
      JSON.stringify((s.user_agent||'').slice(0,120)),
      s.ativo?'Sim':'Não',
      new Date(s.criado_em).toLocaleString('pt-BR'),
      s.expira_em ? new Date(s.expira_em).toLocaleString('pt-BR') : ''
    ].join(','));
    const blob = new Blob([header+rows.join('\n')],{type:'text/csv;charset=utf-8;'});
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url; a.download = 'sessoes_usuario.csv'; a.click();
    URL.revokeObjectURL(url);
  }

  onMount(loadSessoes);
</script>

<svelte:head>
  <title>Sessões do Usuário - IntelliMen Campus</title>
</svelte:head>

<div class="max-w-6xl mx-auto px-4 py-6 space-y-6">
  <div class="flex items-center justify-between">
    <h1 class="text-2xl font-bold text-gray-900">Sessões de Usuários</h1>
    {#if sessoes.length}
      <Button variant="outline" size="sm" on:click={exportarCSV}>Exportar CSV</Button>
    {/if}
  </div>

  <!-- Filtros -->
  <Card class="p-6">
    <div class="grid grid-cols-1 sm:grid-cols-3 gap-3">
      <Input label="Usuário (ID)" bind:value={filtroUserId} placeholder="Filtrar por ID do usuário" />
      <div>
        <label class="block text-sm font-medium text-gray-700">Status</label>
        <select class="w-full px-3 py-2 border rounded-md" bind:value={filtroAtivo}>
          <option value="todos">Todos</option>
          <option value="ativos">Ativos</option>
          <option value="revogados">Revogados</option>
        </select>
      </div>
      <div class="flex items-end justify-end">
        <Button on:click={loadSessoes}>Aplicar</Button>
      </div>
    </div>
  </Card>

  <Card class="p-6">
    {#if loading}
      <div class="flex items-center justify-center py-12">
        <div class="animate-spin rounded-full h-12 w-12 border-b-2 border-blue-600"></div>
      </div>
    {:else if error}
      <div class="bg-red-50 border border-red-200 rounded-lg p-4 text-red-700">{error}</div>
    {:else if !sessoes.length}
      <p class="text-gray-600">Nenhuma sessão encontrada.</p>
    {:else}
      <div class="space-y-3">
        {#each sessoes as s}
          <div class="p-3 border rounded-lg flex items-center justify-between">
            <div class="text-sm">
              <div><span class="text-gray-500">Usuário:</span> {nomeUsuario(s.usuario_id)}</div>
              <div class="text-gray-500">IP: {s.ip_address} • User Agent: {(s.user_agent||'').substring(0, 80)}...</div>
              <div class="text-gray-500">Ativo: {s.ativo ? 'Sim' : 'Não'} • Criado: {new Date(s.criado_em).toLocaleString('pt-BR')}</div>
              {#if s.expira_em}
                <div class="text-gray-500">Expira: {new Date(s.expira_em).toLocaleString('pt-BR')}</div>
              {/if}
            </div>
            <div>
              {#if s.ativo}
                <Button variant="outline" on:click={() => revogarSessao(s.id)}>Revogar</Button>
              {/if}
            </div>
          </div>
        {/each}
      </div>
    {/if}
  </Card>
</div>
