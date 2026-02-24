<script>
  import { onMount } from 'svelte';
  import { page } from '$app/stores';
  import { supabase } from '$lib/utils/supabase';
  import { get } from 'svelte/store';

  let jovemId;
  let jovem = null;
  let namorado = null;
  let estado = null;
  let avaliacoes = [];
  let logsAprovacao = [];
  let preAprovadores = [];
  let aprovadores = [];
  let loading = true;
  let hasAccess = false;

  async function loadData() {
    loading = true;
    try {
      jovemId = get(page).params.id;

      const { data: jovemData } = await supabase
        .from('jovens')
        .select('*')
        .eq('id', jovemId)
        .single();
      jovem = jovemData;

      // Carregar dados do namorado (pastor) se existir
      if (jovem) {
        const { data: namoradoData } = await supabase
          .from('namorados')
          .select('*')
          .eq('jovem_id', jovemId)
          .maybeSingle();
        namorado = namoradoData;
      }

      // Carregar bandeira do estado do jovem
      if (jovem?.estado_id) {
        const { data: est } = await supabase
          .from('estados')
          .select('id, nome, sigla, bandeira')
          .eq('id', jovem.estado_id)
          .single();
        estado = est;
      }

      // Se o registro do jovem foi carregado com sucesso,
      // consideramos que o RLS do Supabase já validou o acesso.
      // Evitamos uma checagem extra no frontend que não considera associações.
      hasAccess = !!jovem;

      // Avaliações com informações do usuário (nome, nivel, estado_bandeira)
      const { data: avData } = await supabase
        .from('avaliacoes')
        .select('id, nota, avaliacao_texto, criado_em, user_id, usuarios:usuarios!inner(id, nome, nivel, estado_bandeira)')
        .eq('jovem_id', jovemId)
        .order('criado_em', { ascending: false });
      avaliacoes = (avData || []).map(a => ({
        id: a.id,
        nota: a.nota,
        texto: a.avaliacao_texto,
        criado_em: a.criado_em,
        usuario: a.usuarios
      }));

      // Logs de histórico de aprovação / pré-aprovação
      const { data: logs } = await supabase
        .from('logs_historico')
        .select('id, acao, detalhe, created_at, user_id, usuarios:usuarios!inner(id, nome, nivel, estado_bandeira)')
        .eq('jovem_id', jovemId)
        .order('created_at', { ascending: true });
      const toLower = (s) => (s || '').toLowerCase();
      logsAprovacao = (logs || []).filter(l => {
        const acao = toLower(l.acao);
        const det = toLower(l.detalhe);
        return acao === 'aprovacao' || det.includes('pré-aprov') || det.includes('pre-aprov') || det.includes('aprovado');
      });

      // Separar por tipo com base no detalhe/status
      preAprovadores = logsAprovacao.filter(l => {
        const det = toLower(l.detalhe);
        return det.includes('pré-aprov') || det.includes('pre-aprov');
      })
        .map(l => ({ usuario: l.usuarios, quando: l.created_at }));
      aprovadores = logsAprovacao.filter(l => {
        const det = toLower(l.detalhe);
        return det.includes('aprovado') && !det.includes('pré-aprov') && !det.includes('pre-aprov');
      })
        .map(l => ({ usuario: l.usuarios, quando: l.created_at }));
    } finally {
      loading = false;
    }
  }

  onMount(loadData);

  function notaLabel(nota) {
    if (nota >= 9) return 'Ótimo';
    if (nota >= 8) return 'Bom';
    if (nota >= 7) return 'Regular';
    if (nota >= 6) return 'Observar';
    return 'Ruim';
  }

  function printPDF() {
    window.print();
  }
</script>

<div class="ficha-wrapper">
  {#if loading}
    <div class="loading">Carregando ficha...</div>
  {:else if !jovem}
    <div class="loading">Jovem não encontrado.</div>
  {:else if !hasAccess}
    <div class="loading">Você não tem permissão para acessar esta ficha.</div>
  {:else}
    <div class="ficha-a4">
      <!-- Cabeçalho -->
      <div class="header">
        {#if estado?.bandeira}
          <img class="flag" src={estado.bandeira} alt={`Bandeira de ${estado?.sigla || ''}`} />
        {/if}
        <div class="titulo">
          <h1>{jovem.nome_completo}</h1>
          {#if jovem.data_cadastro}
            <p>Cadastrado em {new Date(jovem.data_cadastro).toLocaleDateString()}</p>
          {/if}
        </div>
        <div class="fotos-header">
          <div class="foto">
            <span class="foto-label">Jovem</span>
            {#if jovem.foto}
              <img src={jovem.foto} alt="Foto do jovem" />
            {:else}
              <div class="placeholder"></div>
            {/if}
          </div>
          {#if namorado}
            <div class="foto foto-namorado">
              <span class="foto-label">Namorado (pastor)</span>
              {#if namorado.foto}
                <img src={namorado.foto} alt={namorado.nome || 'Namorado'} />
              {:else}
                <div class="placeholder placeholder-namorado"></div>
              {/if}
            </div>
          {/if}
        </div>
      </div>

      <!-- Informações principais -->
      <div class="secao bloco">
        <h2>Informações Pessoais</h2>
        <div class="grid">
          <div class="campo"><span>WHATSAPP</span><strong>{jovem.whatsapp || '-'}</strong></div>
          <div class="campo"><span>IDADE</span><strong>{jovem.idade || '-'}</strong></div>
          <div class="campo"><span>DATA DE NASCIMENTO</span><strong>{jovem.data_nasc ? new Date(jovem.data_nasc).toLocaleDateString() : '-'}</strong></div>
          <div class="campo"><span>ESTADO CIVIL</span><strong>{jovem.estado_civil || '-'}</strong></div>
          <div class="campo"><span>NAMORA</span><strong>{jovem.namora ? 'Sim' : 'Não'}</strong></div>
          <div class="campo"><span>TEMPO DE NAMORO</span><strong>{namorado?.tempo_namoro || jovem.tempo_condicao || '-'}</strong></div>
          <div class="campo"><span>TEM FILHO</span><strong>{jovem.tem_filho ? 'Sim' : 'Não'}</strong></div>
        </div>
      </div>

      <!-- Dados do Namorado (quando existir) -->
      {#if namorado}
        <div class="secao bloco">
          <h2>Dados do Namorado (pastor)</h2>
          <div class="grid">
            <div class="campo"><span>NOME</span><strong>{namorado.nome || '-'}</strong></div>
            <div class="campo"><span>IDADE</span><strong>{namorado.idade != null ? namorado.idade + ' anos' : '-'}</strong></div>
            <div class="campo"><span>TEMPO DE OBRA</span><strong>{namorado.tempo_obra || '-'}</strong></div>
            <div class="campo"><span>TEMPO DE NAMORO</span><strong>{namorado.tempo_namoro || '-'}</strong></div>
            <div class="campo"><span>COMO SE CONHECERAM</span><strong>{namorado.como_se_conheceram || '-'}</strong></div>
            <div class="campo"><span>HÁ QUANTO TEMPO SE CONHECEM</span><strong>{namorado.quanto_tempo_se_conhece || '-'}</strong></div>
            <div class="campo"><span>ONDE ESTÁ ATUALMENTE</span><strong>{namorado.onde_esta_atualmente || '-'}</strong></div>
            <div class="campo"><span>ATRIBUIÇÃO ATUAL</span><strong>{namorado.atribuicao_atual || '-'}</strong></div>
            {#if namorado.observacao_namoro}
              <div class="campo col-span-3"><span>OBSERVAÇÃO SOBRE O NAMORO</span><strong>{namorado.observacao_namoro}</strong></div>
            {/if}
          </div>
        </div>
      {/if}

      <!-- Informações espirituais -->
      <div class="secao bloco">
        <h2>Informações Espirituais</h2>
        <div class="grid">
          <div class="campo"><span>TEMPO DE IGREJA</span><strong>{jovem.tempo_igreja || '-'}</strong></div>
          <div class="campo"><span>BATIZADO NAS ÁGUAS</span><strong>{jovem.batizado_aguas ? 'Sim' : 'Não'}</strong></div>
          <div class="campo"><span>DATA DO BATISMO NAS ÁGUAS</span><strong>{jovem.data_batismo_aguas ? new Date(jovem.data_batismo_aguas).toLocaleDateString() : '-'}</strong></div>
          <div class="campo"><span>BATIZADO COM O ES</span><strong>{jovem.batizado_es ? 'Sim' : 'Não'}</strong></div>
          <div class="campo"><span>DATA DO BATISMO COM O ES</span><strong>{jovem.data_batismo_es ? new Date(jovem.data_batismo_es).toLocaleDateString() : '-'}</strong></div>
          <div class="campo"><span>CONDIÇÃO</span><strong>{jovem.condicao || '-'}</strong></div>
          <div class="campo"><span>TEMPO NESTA CONDIÇÃO</span><strong>{jovem.tempo_condicao || '-'}</strong></div>
          <div class="campo"><span>RESPONSABILIDADE NA IGREJA</span><strong>{jovem.responsabilidade_igreja || '-'}</strong></div>
        </div>
      </div>

      <!-- Experiência na Igreja -->
      <div class="secao bloco">
        <h2>Experiência na Igreja</h2>
        <div class="grid">
          <div class="campo"><span>JÁ FEZ A OBRA NO ALTAR</span><strong>{jovem.ja_obra_altar ? 'Sim' : 'Não'}</strong></div>
          <div class="campo"><span>JÁ FOI OBREIRO</span><strong>{jovem.ja_obreiro ? 'Sim' : 'Não'}</strong></div>
          <div class="campo"><span>JÁ FOI COLABORADOR</span><strong>{jovem.ja_colaborador ? 'Sim' : 'Não'}</strong></div>
          <div class="campo"><span>JÁ SE AFASTOU ALGUMA VEZ</span><strong>{jovem.afastado ? 'Sim' : 'Não'}</strong></div>
          <div class="campo"><span>OS PAIS SÃO DA IGREJA</span><strong>{jovem.pais_na_igreja ? 'Sim' : 'Não'}</strong></div>
          <div class="campo"><span>OBSERVAÇÃO SOBRE OS PAIS</span><strong>{jovem.observacao_pais || jovem.obs_pais || '-'}</strong></div>
          <div class="campo"><span>TEM FAMILIARES NA IGREJA</span><strong>{jovem.familiares_igreja ? 'Sim' : 'Não'}</strong></div>
          <div class="campo"><span>DESEJA O ALTAR</span><strong>{jovem.deseja_altar ? 'Sim' : 'Não'}</strong></div>
        </div>
      </div>

      <!-- Informações Profissionais -->
      <div class="secao bloco">
        <h2>Informações Profissionais</h2>
        <div class="grid">
          <div class="campo"><span>TRABALHA</span><strong>{jovem.trabalha ? 'Sim' : 'Não'}</strong></div>
          <div class="campo"><span>NOME DA EMPRESA</span><strong>{jovem.local_trabalho || '-'}</strong></div>
          <div class="campo"><span>TRABALHA DE QUÊ</span><strong>{jovem.formacao || '-'}</strong></div>
          <div class="campo"><span>PROFISSÃO</span><strong>{jovem.observacao_redes || jovem.observacao || '-'}</strong></div>
          <div class="campo"><span>ESCOLARIDADE</span><strong>{jovem.escolaridade || '-'}</strong></div>
          <div class="campo"><span>TEM DÍVIDAS</span><strong>{jovem.tem_dividas ? 'Sim' : 'Não'}</strong></div>
        </div>
      </div>

      <!-- Redes Sociais e Testemunho -->
      <div class="secao bloco">
        <h2>Redes Sociais e Testemunho</h2>
        <div class="grid redes">
          <div class="campo col-span-3"><span>TESTEMUNHO</span><strong>{jovem.testemunho_text || jovem.testemunho || '-'}</strong></div>
          <div class="campo"><span>INSTAGRAM</span><strong>{jovem.instagram || '-'}</strong></div>
          <div class="campo"><span>FACEBOOK</span><strong>{jovem.facebook || '-'}</strong></div>
          <div class="campo"><span>TIKTOK</span><strong>{jovem.tiktok || '-'}</strong></div>
        </div>
      </div>

      <!-- Avaliações -->
      <div class="secao bloco">
        <h2>Avaliações</h2>
        {#if avaliacoes.length === 0}
          <p class="muted">Nenhuma avaliação registrada.</p>
        {:else}
          <ul class="avaliacoes">
            {#each avaliacoes as a}
              <li class="avaliacao">
                <div class="avaliador">
                  {#if a.usuario?.estado_bandeira}
                    <img class="bandeira" src={a.usuario.estado_bandeira} alt="Bandeira" />
                  {/if}
                  <div>
                    <strong>{a.usuario?.nome || 'Usuário'}</strong>
                    <span class="nivel">{a.usuario?.nivel ?? ''}</span>
                  </div>
                </div>
                <div class="nota">
                  <span class="valor">{a.nota}</span>
                  <span class="label">{notaLabel(a.nota)}</span>
                </div>
                {#if a.texto}
                  <p class="texto">{a.texto}</p>
                {/if}
              </li>
            {/each}
          </ul>
        {/if}
      </div>

      <!-- Pré-aprovação / Aprovação -->
      <div class="secao bloco">
        <h2>Pré-aprovações e Aprovações</h2>
        <div class="aprovacoes-grid">
          <div>
            <h3 class="titulo-secundario">Pré-aprovado por</h3>
            {#if preAprovadores.length === 0}
              <p class="muted">Nenhum registro.</p>
            {:else}
              <ul class="lista-aprovadores">
                {#each preAprovadores as item}
                  <li class="aprovador">
                    {#if item.usuario?.estado_bandeira}
                      <img class="bandeira" src={item.usuario.estado_bandeira} alt="Bandeira" />
                    {/if}
                    <div>
                      <strong>{item.usuario?.nome || 'Usuário'}</strong>
                      <span class="nivel">{item.usuario?.nivel ?? ''}</span>
                    </div>
                  </li>
                {/each}
              </ul>
            {/if}
          </div>
          <div>
            <h3 class="titulo-secundario">Aprovado por</h3>
            {#if aprovadores.length === 0}
              <p class="muted">Nenhum registro.</p>
            {:else}
              <ul class="lista-aprovadores">
                {#each aprovadores as item}
                  <li class="aprovador">
                    {#if item.usuario?.estado_bandeira}
                      <img class="bandeira" src={item.usuario.estado_bandeira} alt="Bandeira" />
                    {/if}
                    <div>
                      <strong>{item.usuario?.nome || 'Usuário'}</strong>
                      <span class="nivel">{item.usuario?.nivel ?? ''}</span>
                    </div>
                  </li>
                {/each}
              </ul>
            {/if}
          </div>
        </div>
      </div>

      <div class="acoes">
        <button class="btn btn-secondary" on:click={() => goto('/jovens')}>Voltar</button>
        <button class="btn" on:click={printPDF}>Gerar PDF</button>
      </div>
    </div>
  {/if}
</div>

<style>
  .ficha-wrapper { display: flex; justify-content: center; padding: 1rem; }
  .ficha-a4 { background: #fff; width: 210mm; max-width: 100%; box-shadow: 0 2px 12px rgba(0,0,0,0.08); border-radius: 8px; overflow: hidden; }
  .header { background: linear-gradient(90deg, #1e3a8a, #2563eb); color: #fff; padding: 16px 20px; display: flex; align-items: center; justify-content: space-between; }
  .titulo { flex: 1; text-align: center; display: flex; flex-direction: column; align-items: center; justify-content: center; }
  .titulo h1 { margin: 0; font-size: 28px; font-weight: 700; }
  .titulo p { margin: 6px 0 0 0; opacity: .95; font-size: 13px; }
  .flag { width: 112px; height: 80px; object-fit: cover; border: 1px solid rgba(255,255,255,.6); border-radius: 2px; box-shadow: 0 2px 4px rgba(0,0,0,0.1); }
  .fotos-header { display: flex; flex-wrap: wrap; align-items: flex-start; justify-content: center; gap: 16px; }
  .foto { width: 110px; height: 140px; background: rgba(255,255,255,.1); border-radius: 6px; display: flex; flex-direction: column; align-items: center; justify-content: flex-start; overflow: hidden; }
  .foto .foto-label { font-size: 10px; font-weight: 600; color: rgba(255,255,255,.95); text-transform: uppercase; letter-spacing: .04em; padding: 4px 0; }
  .foto img { width: 100%; flex: 1; object-fit: cover; }
  .placeholder { width: 100%; flex: 1; background: #e5e7eb; min-height: 80px; }
  .placeholder-namorado { background: #fce7f3; }

  .grid { display: grid; grid-template-columns: repeat(3, 1fr); gap: 10px; padding: 0; }
  .grid .campo.col-span-3 { grid-column: span 3; }
  .redes { grid-template-columns: repeat(3, 1fr); }
  .campo { background: #f8fafc; border: 1px solid #e5e7eb; border-radius: 6px; padding: 10px 10px 10px 20px; position: relative; }
  .campo::before { content: ''; position: absolute; left: 8px; top: 10px; bottom: 10px; width: 3px; background: #1d4ed8; border-radius: 2px; opacity: .9; }
  .bloco { border-left: 4px solid #ef4444; border-right: 4px solid #ef4444; border-radius: 8px; padding: 16px 20px; }
  .secao h2 { color: #1f2937; margin: 0 0 12px 0; font-size: 16px; font-weight: 600; }
  .campo span { display: block; color: #1f3b8a; font-weight: 600; font-size: 11px; letter-spacing: .02em; }
  .campo strong { display: block; color: #111827; font-size: 13px; margin-top: 2px; }

  .muted { color: #6b7280; font-size: 13px; }

  .avaliacoes { list-style: none; padding: 0; margin: 0; display: grid; grid-template-columns: 1fr; gap: 10px; }
  .avaliacao { border: 1px solid #e5e7eb; border-radius: 8px; padding: 10px; background: #fff; }
  .avaliador { display: flex; align-items: center; gap: 10px; }
  .bandeira { width: 20px; height: 14px; object-fit: cover; border: 1px solid #e5e7eb; border-radius: 2px; }
  .nivel { display: block; color: #6b7280; font-size: 12px; }
  .nota { margin-top: 6px; display: flex; align-items: baseline; gap: 8px; }
  .nota .valor { font-size: 18px; font-weight: 700; color: #111827; }
  .nota .label { font-size: 12px; color: #374151; }
  .texto { margin-top: 6px; color: #1f2937; font-size: 13px; }

  .aprovacoes-grid { display: grid; grid-template-columns: repeat(2, 1fr); gap: 16px; }
  .titulo-secundario { font-size: 14px; margin: 6px 0 10px; color: #111827; }
  .lista-aprovadores { list-style: none; padding: 0; margin: 0; display: grid; grid-template-columns: 1fr; gap: 8px; }
  .aprovador { display: flex; align-items: center; gap: 10px; border: 1px solid #e5e7eb; border-radius: 8px; padding: 8px; background: #fff; }

  .acoes { padding: 16px 20px 24px; display: flex; justify-content: space-between; gap: 12px; }
  .btn { background: #2563eb; color: #fff; border: none; padding: 10px 14px; border-radius: 6px; cursor: pointer; }
  .btn:hover { background: #1d4ed8; }
  .btn-secondary { background: #6b7280; color: #fff; }
  .btn-secondary:hover { background: #4b5563; }

  @media print {
    .ficha-wrapper { padding: 0; }
    .ficha-a4 { box-shadow: none; width: 210mm; }
    .acoes { display: none; }
    .grid { grid-template-columns: repeat(3, 1fr) !important; }
    .redes { grid-template-columns: repeat(3, 1fr) !important; }
    .aprovacoes-grid { grid-template-columns: repeat(2, 1fr) !important; }
    .header { background: linear-gradient(90deg, #1e3a8a, #2563eb) !important; -webkit-print-color-adjust: exact; print-color-adjust: exact; }
    .flag { box-shadow: 0 2px 4px rgba(0,0,0,0.1) !important; -webkit-print-color-adjust: exact; print-color-adjust: exact; }
  }

  @media (max-width: 768px) {
    .grid { grid-template-columns: 1fr; }
    .aprovacoes-grid { grid-template-columns: 1fr; }
    .header { flex-direction: row; gap: 12px; }
    .foto { width: 88px; height: 112px; }
  }
</style>
