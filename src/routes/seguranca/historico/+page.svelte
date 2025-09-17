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
  let total = 0;
  let pagina = 1;
  const porPagina = 50;
  let historicos = [];
  let usuarios = new Map();
  let jovens = new Map();

  let filtros = { user_id: '', jovem_id: '', acao: '', de: '', ate: '' };

  function formatDate(d){ return new Date(d).toLocaleString('pt-BR'); }

  async function carregarUsuarios(ids){
    const falt = ids.filter(id=>id && !usuarios.has(id));
    if(!falt.length) return;
    const { data } = await supabase.from('usuarios').select('id,nome').in('id', falt);
    (data||[]).forEach(u=>usuarios.set(u.id,u));
  }
  async function carregarJovens(ids){
    const falt = ids.filter(id=>id && !jovens.has(id));
    if(!falt.length) return;
    const { data } = await supabase.from('jovens').select('id,nome_completo').in('id', falt);
    (data||[]).forEach(j=>jovens.set(j.id,j));
  }

  async function load(){
    try{
      loading=true; error='';
      let q = supabase.from('logs_historico').select('*', {count:'exact'})
        .order('created_at',{ascending:false})
        .range((pagina-1)*porPagina, pagina*porPagina-1);
      if(filtros.user_id) q=q.eq('user_id',filtros.user_id);
      if(filtros.jovem_id) q=q.eq('jovem_id',filtros.jovem_id);
      if(filtros.acao) q=q.ilike('acao',`%${filtros.acao}%`);
      if(filtros.de) q=q.gte('created_at',filtros.de);
      if(filtros.ate) q=q.lte('created_at',filtros.ate);
      const { data, error: e, count } = await q;
      if(e) throw e;
      historicos = data||[];
      total = count||0;
      await carregarUsuarios([...new Set(historicos.map(h=>h.user_id).filter(Boolean))]);
      await carregarJovens([...new Set(historicos.map(h=>h.jovem_id).filter(Boolean))]);
    }catch(e){ error=e?.message||'Falha ao carregar histórico'; }
    finally{ loading=false; }
  }

  function aplicar(){ pagina=1; load(); }
  function limpar(){ filtros={ user_id:'', jovem_id:'', acao:'', de:'', ate:''}; pagina=1; load(); }
  function totalPaginas(){ return Math.ceil(total/porPagina); }

  onMount(load);
</script>

<svelte:head><title>Histórico do Sistema</title></svelte:head>

<div class="max-w-6xl mx-auto px-4 py-6 space-y-6">
  <h1 class="text-2xl font-bold text-gray-900">Histórico do Sistema</h1>

  <Card class="p-6">
    <div class="grid grid-cols-1 md:grid-cols-3 gap-3">
      <Input label="Usuário (ID)" bind:value={filtros.user_id} />
      <Input label="Jovem (ID)" bind:value={filtros.jovem_id} />
      <Input label="Ação" bind:value={filtros.acao} />
      <Input label="De" type="datetime-local" bind:value={filtros.de} />
      <Input label="Até" type="datetime-local" bind:value={filtros.ate} />
    </div>
    <div class="flex justify-end gap-2 mt-4">
      <Button variant="outline" on:click={limpar}>Limpar</Button>
      <Button on:click={aplicar}>Aplicar</Button>
    </div>
  </Card>

  <Card class="p-6">
    {#if loading}
      <div class="py-12 text-center">Carregando…</div>
    {:else if error}
      <div class="bg-red-50 border border-red-200 rounded-lg p-4 text-red-700">{error}</div>
    {:else if !historicos.length}
      <p class="text-gray-600">Nenhum registro encontrado.</p>
    {:else}
      <div class="space-y-3">
        {#each historicos as h}
          <div class="p-3 border rounded-lg">
            <div class="text-sm text-gray-500">{formatDate(h.created_at)}</div>
            <div class="text-sm"><span class="text-gray-500">Usuário:</span> {usuarios.get(h.user_id)?.nome || h.user_id}</div>
            {#if h.jovem_id}
              <div class="text-sm"><span class="text-gray-500">Jovem:</span> {jovens.get(h.jovem_id)?.nome_completo || h.jovem_id}</div>
            {/if}
            <div class="text-sm"><span class="text-gray-500">Ação:</span> {h.acao}</div>
            {#if h.detalhe}
              <div class="text-sm text-gray-700">{h.detalhe}</div>
            {/if}
          </div>
        {/each}
      </div>
      {#if totalPaginas()>1}
        <div class="flex items-center justify-between mt-4">
          <div class="text-sm text-gray-600">Página {pagina} de {totalPaginas()}</div>
          <div class="flex gap-2">
            <Button variant="outline" on:click={() => { if(pagina>1){ pagina--; load(); } }} disabled={pagina===1}>Anterior</Button>
            <Button variant="outline" on:click={() => { if(pagina<totalPaginas()){ pagina++; load(); } }} disabled={pagina===totalPaginas()}>Próxima</Button>
          </div>
        </div>
      {/if}
    {/if}
  </Card>
</div>
