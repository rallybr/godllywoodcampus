<script>
  import { supabase } from '$lib/utils/supabase';
  import { onMount } from 'svelte';
  import { userProfile } from '$lib/stores/auth';

  let estados = [];
  let blocos = [];
  let regioes = [];
  let igrejas = [];
  let regioesCache = {};

  let loading = true;
  let error = '';

  // Seleções
  let estadoId = '';
  let blocoId = '';
  let regiaoId = '';

  // Formulários
  let novoEstado = { nome: '', sigla: '', bandeira: '' };
  let novoBloco = { nome: '' };
  let novaRegiao = { nome: '' };
  let novaIgreja = { nome: '', endereco: '' };

  // Utils
  const uniquifyById = (list) => {
    const seen = new Set();
    return (list || []).filter(item => {
      const key = String(item.id);
      if (seen.has(key)) return false;
      seen.add(key);
      return true;
    });
  };

  async function carregarListas() {
    loading = true;
    error = '';
    try {
      const isAdmin = $userProfile?.nivel === 'administrador';
      const isLiderEstadualFju = $userProfile?.nivel === 'lider_estadual_fju';
      const estadoUsuario = $userProfile?.estado_id ? String($userProfile.estado_id) : '';

      if (isAdmin || !isLiderEstadualFju) {
        // Admin (ou outros níveis sem escopo definido aqui): carrega tudo
        const [e, b, r, i] = await Promise.all([
          supabase.from('estados').select('*').order('nome'),
          supabase.from('blocos').select('*').order('nome'),
          supabase.from('regioes').select('*').order('nome'),
          supabase.from('igrejas').select('*').order('nome')
        ]);
        if (e.error) throw e.error;
        if (b.error) throw b.error;
        if (r.error) throw r.error;
        if (i.error) throw i.error;
        estados = e.data || [];
        blocos = b.data || [];
        regioes = r.data || [];
        igrejas = uniquifyById(i.data || []);
      } else {
        // líder estadual FJU: restringe ao próprio estado
        // 1) Estados e Blocos
        const [e, b] = await Promise.all([
          supabase.from('estados').select('*').eq('id', estadoUsuario).order('nome'),
          supabase.from('blocos').select('*').eq('estado_id', estadoUsuario).order('nome')
        ]);
        if (e.error) throw e.error;
        if (b.error) throw b.error;
        estados = e.data || [];
        blocos = b.data || [];

        const blocoIds = (blocos || []).map(x => x.id);

        // 2) Regiões filtradas pelos blocos do estado
        let r = { data: [], error: null };
        if (blocoIds.length > 0) {
          r = await supabase.from('regioes').select('*').in('bloco_id', blocoIds).order('nome');
          if (r.error) throw r.error;
        }
        regioes = r.data || [];

        const regiaoIds = (regioes || []).map(x => x.id);

        // 3) Igrejas filtradas pelas regiões dos blocos do estado
        let i = { data: [], error: null };
        if (regiaoIds.length > 0) {
          i = await supabase.from('igrejas').select('*').in('regiao_id', regiaoIds).order('nome');
          if (i.error) throw i.error;
        }
        igrejas = uniquifyById(i.data || []);
      }
    } catch (err) {
      error = err.message || 'Erro ao carregar dados';
    } finally {
      loading = false;
    }
  }

  onMount(() => {
    carregarListas().then(() => {
      // normaliza tipos ao carregar
      estados = (estados || []).map(e => ({ ...e, id: String(e.id) }));
      blocos = (blocos || []).map(b => ({ ...b, id: String(b.id), estado_id: String(b.estado_id) }));
      regioes = (regioes || []).map(r => ({ ...r, id: String(r.id), bloco_id: String(r.bloco_id) }));
      igrejas = (igrejas || []).map(i => ({ ...i, id: String(i.id), regiao_id: String(i.regiao_id) }));
    });
  });

  // Helpers
  const blocosDoEstado = () => blocos.filter(b => String(b.estado_id) === String(estadoId));
  const regioesDoBloco = () => regioes.filter(r => String(r.bloco_id) === String(blocoId));
  const igrejasDaRegiao = () => igrejas.filter(i => String(i.regiao_id) === String(regiaoId));

  // Carregamento defensivo se algum conjunto não veio no lote inicial
  $: if (blocoId) {
    const existeParaBloco = regioes.some(r => String(r.bloco_id) === String(blocoId));
    if (!existeParaBloco) {
      supabase
        .from('regioes')
        .select('*')
        .eq('bloco_id', blocoId)
        .order('nome')
        .then(({ data, error }) => {
          if (!error && Array.isArray(data) && data.length > 0) {
            const normalizadas = data.map(r => ({ ...r, id: String(r.id), bloco_id: String(r.bloco_id) }));
            const existentes = new Set(regioes.map(r => r.id));
            regioes = [...regioes, ...normalizadas.filter(r => !existentes.has(r.id))];
            regioesCache[blocoId] = normalizadas;
          }
        });
    }
    // sempre tenta preencher cache do bloco selecionado
    if (!regioesCache[blocoId]) {
      supabase
        .from('regioes')
        .select('*')
        .eq('bloco_id', blocoId)
        .order('nome')
        .then(({ data, error }) => {
          if (!error) {
            const normalizadas = (data || []).map(r => ({ ...r, id: String(r.id), bloco_id: String(r.bloco_id) }));
            regioesCache[blocoId] = normalizadas;
          }
        });
    }
  }

  $: if (regiaoId) {
    // Sempre recarrega todas as igrejas da região selecionada, garantindo unicidade
    supabase
      .from('igrejas')
      .select('*')
      .eq('regiao_id', regiaoId)
      .order('nome')
      .then(({ data, error }) => {
        if (!error) {
          const normalizadas = (data || []).map(i => ({ ...i, id: String(i.id), regiao_id: String(i.regiao_id) }));
          // Remove igrejas da região atual e substitui pelo resultado completo único
          const outrasRegioes = igrejas.filter(i => String(i.regiao_id) !== String(regiaoId));
          igrejas = [...outrasRegioes, ...normalizadas];
          igrejas = uniquifyById(igrejas);
        }
      });
  }

  // CRUD básico (create/update/delete)
  async function criarEstado() {
    if (!novoEstado.nome || !novoEstado.sigla) return;
    const { error } = await supabase.from('estados').insert([novoEstado]);
    if (error) { alert(error.message); return; }
    novoEstado = { nome: '', sigla: '', bandeira: '' };
    await carregarListas();
  }

  async function criarBloco() {
    if (!estadoId || !novoBloco.nome) return;
    const { error } = await supabase.from('blocos').insert([{ nome: novoBloco.nome, estado_id: estadoId }]);
    if (error) { alert(error.message); return; }
    novoBloco = { nome: '' };
    await carregarListas();
  }

  async function criarRegiao() {
    if (!blocoId || !novaRegiao.nome) return;
    const { error } = await supabase.from('regioes').insert([{ nome: novaRegiao.nome, bloco_id: blocoId }]);
    if (error) { alert(error.message); return; }
    novaRegiao = { nome: '' };
    await carregarListas();
  }

  async function criarIgreja() {
    if (!regiaoId || !novaIgreja.nome) return;
    const { error } = await supabase.from('igrejas').insert([{ nome: novaIgreja.nome, endereco: novaIgreja.endereco, regiao_id: regiaoId }]);
    if (error) { alert(error.message); return; }
    novaIgreja = { nome: '', endereco: '' };
    await carregarListas();
  }

  async function atualizar(table, id, updates) {
    const { error } = await supabase.from(table).update(updates).eq('id', id);
    if (error) { alert(error.message); return; }
    await carregarListas();
  }

  async function excluir(table, id) {
    if (!confirm('Tem certeza que deseja excluir?')) return;
    const { error } = await supabase.from(table).delete().eq('id', id);
    if (error) { alert(error.message); return; }
    await carregarListas();
  }
</script>

<svelte:head>
  <title>Gestão de Localizações</title>
</svelte:head>

<div class="max-w-7xl mx-auto p-6 space-y-8">
  <div>
    <h1 class="text-2xl font-bold text-gray-900">Gestão de Localizações</h1>
    <p class="text-gray-600">Estados, Blocos, Regiões e Igrejas</p>
  </div>

  {#if loading}
    <div class="flex items-center justify-center py-12">
      <div class="animate-spin rounded-full h-12 w-12 border-b-2 border-blue-600"></div>
    </div>
  {:else if error}
    <div class="bg-red-50 border border-red-200 rounded-md p-4">
      <p class="text-sm text-red-600">{error}</p>
    </div>
  {:else}
    <!-- ESTADOS -->
    <div class="bg-white rounded-lg shadow p-4 space-y-3">
      <h2 class="text-lg font-semibold">Estados</h2>
      <div class="grid grid-cols-1 md:grid-cols-4 gap-3">
        <input class="border rounded px-3 py-2" placeholder="Nome" bind:value={novoEstado.nome} />
        <input class="border rounded px-3 py-2" placeholder="Sigla" bind:value={novoEstado.sigla} />
        <input class="border rounded px-3 py-2" placeholder="URL da bandeira" bind:value={novoEstado.bandeira} />
        <button class="bg-blue-600 text-white rounded px-4" on:click={criarEstado}>Adicionar</button>
      </div>
      <div class="grid grid-cols-1 gap-2">
        {#each estados as e}
          <div class="border rounded p-3 flex items-center justify-between">
            <div class="flex items-center gap-2">
              {#if e.bandeira}<img src={e.bandeira} alt={e.sigla} class="w-6 h-4 border rounded" />{/if}
              <span class="font-medium">{e.nome} ({e.sigla})</span>
            </div>
            <div class="flex items-center gap-2">
              <button class="px-3 py-1 border rounded" on:click={() => atualizar('estados', e.id, { nome: prompt('Novo nome', e.nome) || e.nome })}>Renomear</button>
              <button class="px-3 py-1 border rounded" on:click={() => atualizar('estados', e.id, { sigla: prompt('Nova sigla', e.sigla) || e.sigla })}>Sigla</button>
              <button class="px-3 py-1 border rounded" on:click={() => atualizar('estados', e.id, { bandeira: prompt('URL bandeira', e.bandeira || '') || e.bandeira })}>Bandeira</button>
              <button class="px-3 py-1 border rounded text-red-600" on:click={() => excluir('estados', e.id)}>Excluir</button>
            </div>
          </div>
        {/each}
      </div>
    </div>

    <!-- SELEÇÃO PARA BLOCO/REGIÃO/IGREJA -->
    <div class="bg-white rounded-lg shadow p-4 grid grid-cols-1 md:grid-cols-3 gap-3">
      <select class="border rounded px-3 py-2" bind:value={estadoId} on:change={() => { estadoId = String(estadoId); blocoId=''; regiaoId=''; }}>
        <option value="">Selecione um estado</option>
        {#each estados as e}
          <option value={String(e.id)}>{e.nome}</option>
        {/each}
      </select>
      {#key estadoId}
        <select class="border rounded px-3 py-2" bind:value={blocoId} disabled={!estadoId} on:change={() => { blocoId = String(blocoId); regiaoId=''; }}>
          <option value="">Selecione um bloco</option>
          {#each blocosDoEstado() as b}
            <option value={String(b.id)}>{b.nome}</option>
          {/each}
        </select>
      {/key}
      {#key blocoId}
        <select class="border rounded px-3 py-2" bind:value={regiaoId} disabled={!blocoId} on:change={() => { regiaoId = String(regiaoId); }}>
          <option value="">Selecione uma região</option>
          {#each regioesDoBloco().length ? regioesDoBloco() : (regioesCache[blocoId] || []) as r}
            <option value={String(r.id)}>{r.nome}</option>
          {/each}
        </select>
      {/key}
    </div>

    <!-- BLOCOS -->
    <div class="bg-white rounded-lg shadow p-4 space-y-3">
      <h2 class="text-lg font-semibold">Blocos do Estado</h2>
      <div class="grid grid-cols-1 md:grid-cols-4 gap-3">
        <input class="border rounded px-3 py-2" placeholder="Nome do bloco" bind:value={novoBloco.nome} />
        <button class="bg-blue-600 text-white rounded px-4" on:click={criarBloco} disabled={!estadoId}>Adicionar</button>
      </div>
      <div class="grid grid-cols-1 gap-2">
        {#each blocosDoEstado() as b}
          <div class="border rounded p-3 flex items-center justify-between">
            <span class="font-medium">{b.nome}</span>
            <div class="flex items-center gap-2">
              <button class="px-3 py-1 border rounded" on:click={() => atualizar('blocos', b.id, { nome: prompt('Novo nome', b.nome) || b.nome })}>Renomear</button>
              <button class="px-3 py-1 border rounded" on:click={async () => { const novo = prompt('Mover para estado (ID)?', estadoId); if (novo) await atualizar('blocos', b.id, { estado_id: novo }); }}>Mover estado</button>
              <button class="px-3 py-1 border rounded text-red-600" on:click={() => excluir('blocos', b.id)}>Excluir</button>
            </div>
          </div>
        {/each}
      </div>
    </div>

    <!-- REGIÕES -->
    <div class="bg-white rounded-lg shadow p-4 space-y-3">
      <h2 class="text-lg font-semibold">Regiões do Bloco</h2>
      <div class="grid grid-cols-1 md:grid-cols-4 gap-3">
        <input class="border rounded px-3 py-2" placeholder="Nome da região" bind:value={novaRegiao.nome} />
        <button class="bg-blue-600 text-white rounded px-4" on:click={criarRegiao} disabled={!blocoId}>Adicionar</button>
      </div>
      <div class="grid grid-cols-1 gap-2">
        {#each regioesDoBloco() as r}
          <div class="border rounded p-3 flex items-center justify-between">
            <span class="font-medium">{r.nome}</span>
            <div class="flex items-center gap-2">
              <button class="px-3 py-1 border rounded" on:click={() => atualizar('regioes', r.id, { nome: prompt('Novo nome', r.nome) || r.nome })}>Renomear</button>
              <button class="px-3 py-1 border rounded" on:click={async () => { const novo = prompt('Mover para bloco (ID)?', blocoId); if (novo) await atualizar('regioes', r.id, { bloco_id: novo }); }}>Mover bloco</button>
              <button class="px-3 py-1 border rounded text-red-600" on:click={() => excluir('regioes', r.id)}>Excluir</button>
            </div>
          </div>
        {/each}
      </div>
    </div>

    <!-- IGREJAS -->
    <div class="bg-white rounded-lg shadow p-4 space-y-3">
      <h2 class="text-lg font-semibold">Igrejas da Região</h2>
      <div class="grid grid-cols-1 md:grid-cols-5 gap-3">
        <input class="border rounded px-3 py-2" placeholder="Nome da igreja" bind:value={novaIgreja.nome} />
        <input class="border rounded px-3 py-2 md:col-span-3" placeholder="Endereço" bind:value={novaIgreja.endereco} />
        <button class="bg-blue-600 text-white rounded px-4" on:click={criarIgreja} disabled={!regiaoId}>Adicionar</button>
      </div>
      <div class="grid grid-cols-1 gap-2">
        {#each igrejasDaRegiao() as i}
          <div class="border rounded p-3 flex items-center justify-between">
            <div>
              <div class="font-medium">{i.nome}</div>
              <div class="text-sm text-gray-500">{i.endereco}</div>
            </div>
            <div class="flex items-center gap-2">
              <button class="px-3 py-1 border rounded" on:click={() => atualizar('igrejas', i.id, { nome: prompt('Novo nome', i.nome) || i.nome })}>Renomear</button>
              <button class="px-3 py-1 border rounded" on:click={() => atualizar('igrejas', i.id, { endereco: prompt('Novo endereço', i.endereco || '') || i.endereco })}>Endereço</button>
              <button class="px-3 py-1 border rounded" on:click={async () => { const nova = prompt('Mover para região (ID)?', regiaoId); if (nova) await atualizar('igrejas', i.id, { regiao_id: nova }); }}>Mover região</button>
              <button class="px-3 py-1 border rounded text-red-600" on:click={() => excluir('igrejas', i.id)}>Excluir</button>
            </div>
          </div>
        {/each}
      </div>
    </div>
  {/if}
</div>



