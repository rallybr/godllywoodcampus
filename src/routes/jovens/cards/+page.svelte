<script>
  import { onMount } from 'svelte';
  import { goto } from '$app/navigation';
  import { supabase } from '$lib/utils/supabase';
  import JovemMiniCard from '$lib/components/jovens/JovemMiniCard.svelte';
  import Autocomplete from '$lib/components/ui/Autocomplete.svelte';
  import { userProfile } from '$lib/stores/auth';

  let jovens = [];
  let loading = true;
  let error = '';
  let searchTerm = '';
  let page = 1;
  let pageSize = 24;
  let total = 0;
  let estados = [];
  let selectedEstado = '';
  let edicoes = [];
  let selectedEdicao = '';
  let condicoes = [];
  let selectedCondicao = '';
  let idadeMin = '';
  let idadeMax = '';

  async function fetchJovens() {
    loading = true;
    error = '';
    try {
      console.log('🔍 DEBUG - Iniciando fetchJovens');
      console.log('🔍 DEBUG - userProfile:', $userProfile);
      console.log('🔍 DEBUG - userProfile.nivel:', $userProfile?.nivel);
      console.log('🔍 DEBUG - userProfile.id:', $userProfile?.id);
      
      const from = (page - 1) * pageSize;
      const to = from + pageSize - 1;

      let query = supabase
        .from('jovens')
        .select(`
          id,
          nome_completo,
          foto,
          usuario_id,
          idade,
          aprovado,
          estado:estados!estado_id (
            id,
            nome,
            sigla,
            bandeira
          ),
          bloco:blocos!bloco_id (
            id,
            nome
          ),
          regiao:regioes!regiao_id (
            id,
            nome
          ),
          igreja:igrejas!igreja_id (
            id,
            nome
          ),
          edicao:edicoes!edicao_id (
            id,
            nome,
            numero
          )
        `, { count: 'exact' })
        .order('nome_completo', { ascending: true });

      // Aplicar escopo por nível (alinhado ao can_access_jovem)
      const nivel = $userProfile?.nivel;
      if (!nivel) {
        console.log('🔍 DEBUG - Sem nível definido, sem filtros adicionais');
      } else if (nivel === 'administrador' || nivel === 'lider_nacional_iurd' || nivel === 'lider_nacional_fju') {
        console.log('🔍 DEBUG - Visão nacional (admin/nacional)');
      } else if (nivel === 'lider_estadual_iurd' || nivel === 'lider_estadual_fju') {
        if ($userProfile?.estado_id) {
          console.log('🔍 DEBUG - Filtrando por estado:', $userProfile.estado_id);
          query = query.eq('estado_id', $userProfile.estado_id);
        }
      } else if (nivel === 'lider_bloco_iurd' || nivel === 'lider_bloco_fju') {
        if ($userProfile?.bloco_id) {
          console.log('🔍 DEBUG - Filtrando por bloco:', $userProfile.bloco_id);
          query = query.eq('bloco_id', $userProfile.bloco_id);
        }
      } else if (nivel === 'lider_regional_iurd') {
        if ($userProfile?.regiao_id) {
          console.log('🔍 DEBUG - Filtrando por região:', $userProfile.regiao_id);
          query = query.eq('regiao_id', $userProfile.regiao_id);
        }
      } else if (nivel === 'lider_igreja_iurd') {
        if ($userProfile?.igreja_id) {
          console.log('🔍 DEBUG - Filtrando por igreja:', $userProfile.igreja_id);
          query = query.eq('igreja_id', $userProfile.igreja_id);
        }
      } else if ((nivel === 'colaborador' || nivel === 'jovem') && $userProfile?.id) {
        console.log('🔍 DEBUG - Filtrando por usuário (colaborador/jovem):', $userProfile.id);
        query = query.eq('usuario_id', $userProfile.id);
      }

      if (searchTerm && searchTerm.trim().length > 0) {
        query = query.ilike('nome_completo', `%${searchTerm.trim()}%`);
      }

      // Filtro por estado selecionado
      if (selectedEstado) {
        query = query.eq('estado_id', selectedEstado);
      }

      // Filtro por edição selecionada
      if (selectedEdicao) {
        query = query.eq('edicao_id', selectedEdicao);
      }

      // Filtro por condição selecionada
      if (selectedCondicao) {
        query = query.eq('condicao', selectedCondicao);
      }

      // Filtro por idade mínima e máxima
      if (idadeMin !== '' && !Number.isNaN(Number(idadeMin))) {
        query = query.gte('idade', Number(idadeMin));
      }
      if (idadeMax !== '' && !Number.isNaN(Number(idadeMax))) {
        query = query.lte('idade', Number(idadeMax));
      }

      const { data, error: err, count } = await query.range(from, to);
      if (err) throw err;
      
      console.log('🔍 DEBUG - Dados retornados:', data);
      console.log('🔍 DEBUG - Total de registros:', count);
      console.log('🔍 DEBUG - Jovens encontrados:', data?.length);
      
      // Log detalhado de cada jovem
      if (data && data.length > 0) {
        data.forEach((jovem, index) => {
          console.log(`🔍 DEBUG - Jovem ${index + 1}:`, {
            id: jovem.id,
            nome: jovem.nome_completo,
            usuario_id: jovem.usuario_id,
            estado: jovem.estado
          });
        });
      }
      
      jovens = data || [];
      total = count || 0;
    } catch (e) {
      error = e.message || 'Erro ao carregar jovens';
    } finally {
      loading = false;
    }
  }

  async function loadEstados() {
    try {
      let query = supabase
        .from('estados')
        .select('id,nome,sigla')
        .order('sigla');
      
      // 🔧 APLICAR FILTROS BASEADOS NO NÍVEL DE ACESSO
      const userLevel = $userProfile?.nivel;
      
      if (userLevel === 'lider_estadual_iurd' || userLevel === 'lider_estadual_fju') {
        // Líder estadual: apenas seu estado
        if ($userProfile?.estado_id) {
          console.log('🔍 DEBUG - Filtrando estados para líder estadual:', $userProfile.estado_id);
          query = query.eq('id', $userProfile.estado_id);
        }
      } else if (userLevel === 'lider_bloco_iurd' || userLevel === 'lider_bloco_fju') {
        // Líder de bloco: apenas estados do seu bloco
        if ($userProfile?.bloco_id) {
          console.log('🔍 DEBUG - Filtrando estados para líder de bloco:', $userProfile.bloco_id);
          // Buscar estados que têm blocos com o bloco_id do usuário
          const { data: blocosData } = await supabase
            .from('blocos')
            .select('estado_id')
            .eq('id', $userProfile.bloco_id);
          
          if (blocosData && blocosData.length > 0) {
            query = query.eq('id', blocosData[0].estado_id);
          }
        }
      } else if (userLevel === 'lider_regional_iurd') {
        // Líder regional: apenas estados da sua região
        if ($userProfile?.regiao_id) {
          console.log('🔍 DEBUG - Filtrando estados para líder regional:', $userProfile.regiao_id);
          // Buscar estados que têm regiões com o regiao_id do usuário
          const { data: regioesData } = await supabase
            .from('regioes')
            .select('estado_id')
            .eq('id', $userProfile.regiao_id);
          
          if (regioesData && regioesData.length > 0) {
            query = query.eq('id', regioesData[0].estado_id);
          }
        }
      } else if (userLevel === 'lider_igreja_iurd') {
        // Líder de igreja: apenas estados da sua igreja
        if ($userProfile?.igreja_id) {
          console.log('🔍 DEBUG - Filtrando estados para líder de igreja:', $userProfile.igreja_id);
          // Buscar estados que têm igrejas com o igreja_id do usuário
          const { data: igrejasData } = await supabase
            .from('igrejas')
            .select('estado_id')
            .eq('id', $userProfile.igreja_id);
          
          if (igrejasData && igrejasData.length > 0) {
            query = query.eq('id', igrejasData[0].estado_id);
          }
        }
      }
      // Administrador e líderes nacionais: sem filtros adicionais
      
      const { data, error: err } = await query;
      if (err) throw err;
      estados = data || [];
    } catch (e) {
      console.warn('Falha ao carregar estados:', e?.message || e);
      estados = [];
    }
  }

  async function loadEdicoes() {
    try {
      let query = supabase
        .from('edicoes')
        .select('id,numero,nome,ativa')
        .order('numero', { ascending: false });
      
      // 🔧 APLICAR FILTROS BASEADOS NO NÍVEL DE ACESSO
      const userLevel = $userProfile?.nivel;
      
      if (userLevel === 'colaborador' && $userProfile?.id) {
        // Colaborador: apenas edições dos jovens que ele cadastrou
        console.log('🔍 DEBUG - Filtrando edições para colaborador:', $userProfile.id);
        // Buscar edições dos jovens que o colaborador cadastrou
        const { data: jovensData } = await supabase
          .from('jovens')
          .select('edicao_id')
          .eq('usuario_id', $userProfile.id)
          .not('edicao_id', 'is', null);
        
        if (jovensData && jovensData.length > 0) {
          const edicaoIds = [...new Set(jovensData.map(j => j.edicao_id))];
          query = query.in('id', edicaoIds);
        } else {
          // Se não tem jovens cadastrados, não mostrar nenhuma edição
          query = query.eq('id', -1); // ID que não existe
        }
      }
      // Outros níveis: sem filtros adicionais (podem ver todas as edições)
      
      const { data, error: err } = await query;
      if (err) throw err;
      edicoes = data || [];
    } catch (e) {
      console.warn('Falha ao carregar edições:', e?.message || e);
      edicoes = [];
    }
  }

  async function loadCondicoes() {
    try {
      let query = supabase
        .from('jovens')
        .select('condicao')
        .not('condicao', 'is', null)
        .neq('condicao', '')
        .order('condicao');
      
      // 🔧 APLICAR FILTROS BASEADOS NO NÍVEL DE ACESSO
      const userLevel = $userProfile?.nivel;
      
      if (userLevel === 'colaborador' && $userProfile?.id) {
        // Colaborador: apenas condições dos jovens que ele cadastrou
        console.log('🔍 DEBUG - Filtrando condições para colaborador:', $userProfile.id);
        query = query.eq('usuario_id', $userProfile.id);
      } else if (userLevel === 'lider_estadual_iurd' || userLevel === 'lider_estadual_fju') {
        // Líder estadual: apenas condições dos jovens do seu estado
        if ($userProfile?.estado_id) {
          console.log('🔍 DEBUG - Filtrando condições para líder estadual:', $userProfile.estado_id);
          query = query.eq('estado_id', $userProfile.estado_id);
        }
      } else if (userLevel === 'lider_bloco_iurd' || userLevel === 'lider_bloco_fju') {
        // Líder de bloco: apenas condições dos jovens do seu bloco
        if ($userProfile?.bloco_id) {
          console.log('🔍 DEBUG - Filtrando condições para líder de bloco:', $userProfile.bloco_id);
          query = query.eq('bloco_id', $userProfile.bloco_id);
        }
      } else if (userLevel === 'lider_regional_iurd') {
        // Líder regional: apenas condições dos jovens da sua região
        if ($userProfile?.regiao_id) {
          console.log('🔍 DEBUG - Filtrando condições para líder regional:', $userProfile.regiao_id);
          query = query.eq('regiao_id', $userProfile.regiao_id);
        }
      } else if (userLevel === 'lider_igreja_iurd') {
        // Líder de igreja: apenas condições dos jovens da sua igreja
        if ($userProfile?.igreja_id) {
          console.log('🔍 DEBUG - Filtrando condições para líder de igreja:', $userProfile.igreja_id);
          query = query.eq('igreja_id', $userProfile.igreja_id);
        }
      }
      // Administrador e líderes nacionais: sem filtros adicionais
      
      const { data, error: err } = await query;
      if (err) throw err;
      condicoes = Array.from(new Set((data || []).map(r => r.condicao)));
    } catch (e) {
      console.warn('Falha ao carregar condições:', e?.message || e);
      condicoes = [];
    }
  }

  onMount(async () => {
    await Promise.all([loadEstados(), loadEdicoes(), loadCondicoes()]);
    fetchJovens();
  });

  function handleSearchSubmit(e) {
    e?.preventDefault?.();
    page = 1;
    fetchJovens();
  }

  function prevPage() {
    if (page > 1) {
      page -= 1;
      fetchJovens();
    }
  }

  function nextPage() {
    const totalPages = Math.max(1, Math.ceil(total / pageSize));
    if (page < totalPages) {
      page += 1;
      fetchJovens();
    }
  }
</script>

<svelte:head>
  <title>Jovens (Cards) - IntelliMen Campus</title>
</svelte:head>

<div class="px-4 sm:px-6 py-6 space-y-6">
  <div>
    <h1 class="text-2xl font-bold text-gray-900">Jovens</h1>
    <p class="text-gray-600">Lista em cartões compactos</p>
  </div>

  {#if $userProfile?.nivel !== 'jovem' && $userProfile?.nivel !== 'colaborador'}
    <!-- Banner de filtros com efeito vidro + bordas neon -->
      <div class="rounded-3xl p-1 bg-gradient-to-br from-[#0c0d11] via-[#12131a] to-[#0a0b0f] mb-6">
      <div class="relative neon-glass rounded-2xl p-4 sm:p-6 overflow-hidden">
        <!-- Texturas/gradientes sutis no fundo para destacar o brilho -->
        <div class="pointer-events-none absolute inset-0 opacity-60"
             style="background:
               radial-gradient(1200px 400px at -10% -10%, rgba(59,130,246,0.08), transparent 60%),
               radial-gradient(800px 300px at 110% 0%, rgba(168,85,247,0.09), transparent 60%),
               radial-gradient(800px 300px at 50% 120%, rgba(99,102,241,0.08), transparent 60%);"></div>

        <Autocomplete
          placeholder="Pesquisar por nome..."
          bind:value={searchTerm}
          on:input={(e) => { searchTerm = e.detail.value; if ((searchTerm || '').trim().length >= 2) { page = 1; fetchJovens(); } }}
          on:select={(e) => { searchTerm = e.detail.suggestion.nome_completo; page = 1; fetchJovens(); }}
          on:search={() => handleSearchSubmit()}
        />

        <div class="mt-3 grid grid-cols-1 sm:grid-cols-2 gap-3">
          <div>
            <label for="estadoSelect" class="block text-sm text-blue-100 mb-1">Filtrar por estado</label>
            <select
              id="estadoSelect"
              class="w-full bg-white/10 text-white placeholder-gray-300 border border-white/20 rounded px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-blue-400/70"
              bind:value={selectedEstado}
              on:change={() => { page = 1; fetchJovens(); }}
            >
              <option value="">Todos os estados</option>
              {#each estados as st}
                <option value={st.id}>{st.sigla} - {st.nome}</option>
              {/each}
            </select>
          </div>
          <div>
            <label for="edicaoSelect" class="block text-sm text-blue-100 mb-1">Filtrar por edição</label>
            <select
              id="edicaoSelect"
              class="w-full bg-white/10 text-white placeholder-gray-300 border border-white/20 rounded px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-fuchsia-400/70"
              bind:value={selectedEdicao}
              on:change={() => { page = 1; fetchJovens(); }}
            >
              <option value="">Todas as edições</option>
              {#each edicoes as ed}
                <option value={ed.id}>Edição {ed.numero} {ed.ativa ? '(Ativa)' : ''}</option>
              {/each}
            </select>
          </div>
        </div>

        <div class="mt-3 grid grid-cols-1 sm:grid-cols-2 gap-3">
          <div>
            <label for="condicaoSelect" class="block text-sm text-blue-100 mb-1">Filtrar por condição</label>
            <select
              id="condicaoSelect"
              class="w-full bg-white/10 text-white placeholder-gray-300 border border-white/20 rounded px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-indigo-400/70"
              bind:value={selectedCondicao}
              on:change={() => { page = 1; fetchJovens(); }}
            >
              <option value="">Todas as condições</option>
              {#each condicoes as c}
                <option value={c}>{c}</option>
              {/each}
            </select>
          </div>
          <div>
            <label class="block text-sm text-blue-100 mb-1" for="idadeMin">Filtrar por idade</label>
            <div class="flex items-center gap-2">
              <input id="idadeMin" type="number" min="0" placeholder="Mín"
                class="w-full bg-white/10 text-white placeholder-gray-300 border border-white/20 rounded px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-blue-400/70"
                bind:value={idadeMin}
                on:change={() => { page = 1; fetchJovens(); }} />
              <span class="text-sm text-blue-200">-</span>
              <input id="idadeMax" type="number" min="0" placeholder="Máx"
                class="w-full bg-white/10 text-white placeholder-gray-300 border border-white/20 rounded px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-purple-400/70"
                bind:value={idadeMax}
                on:change={() => { page = 1; fetchJovens(); }} />
            </div>
          </div>
        </div>
      </div>
    </div>
  {/if}

  {#if loading}
    <div class="flex items-center justify-center py-12">
      <div class="animate-spin rounded-full h-12 w-12 border-b-2 border-blue-600"></div>
    </div>
  {:else if error}
    <div class="bg-red-50 border border-red-200 rounded-md p-4">
      <p class="text-sm text-red-600">{error}</p>
    </div>
  {:else if !jovens || jovens.length === 0}
    <div class="bg-white rounded-lg shadow p-8 text-center text-gray-600">Nenhum jovem encontrado</div>
  {:else}
    <div class="grid grid-cols-1 sm:grid-cols-2 md:grid-cols-3 gap-4">
      {#each jovens as jovem (jovem.id)}
        <JovemMiniCard {jovem} on:deleted={() => fetchJovens()} />
      {/each}
    </div>

    {#if $userProfile?.nivel !== 'jovem' && $userProfile?.nivel !== 'colaborador'}
      <!-- Paginação -->
      <div class="flex items-center justify-center gap-3 mt-6">
        <button on:click={prevPage} disabled={page <= 1} class="px-3 py-2 border rounded disabled:opacity-50">Anterior</button>
        <span class="text-sm text-gray-600">Página {page} de {Math.max(1, Math.ceil(total / pageSize))}</span>
        <button on:click={nextPage} disabled={page >= Math.max(1, Math.ceil(total / pageSize))} class="px-3 py-2 border rounded disabled:opacity-50">Próxima</button>
      </div>
    {/if}
  {/if}
</div>



