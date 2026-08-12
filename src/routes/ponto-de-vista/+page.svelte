<script>
  import { onMount } from 'svelte';
  import { goto } from '$app/navigation';
  import { user, userProfile } from '$lib/stores/auth';
  import { supabase } from '$lib/utils/supabase';
  import CardPontoDeVista from '$lib/components/relatorios/CardPontoDeVista.svelte';
  import Button from '$lib/components/ui/Button.svelte';
  import { slide } from 'svelte/transition';

  const TIPOS_PONTO_VISTA = ['pre_aprovado', 'observar', 'sem_condicao'];
  const statusLabel = {
    pre_aprovado: 'OK',
    observar: 'Observar',
    sem_condicao: 'Sem condição'
  };

  const condicoesMap = {
    auxiliar_pastor: 'Esposa de Pastor',
    curso: 'Curso',
    iburd: 'Candidata do Altar',
    namorada: 'Namorada de Pastor',
    noiva: 'Noiva de Pastor',
    obreiro: 'Obreiro',
    colaborador: 'Colaborador',
    cpo: 'CPO',
    jovem_batizado_es: 'Jovem',
    desertou: 'Desertou'
  };

  let jovens = [];
  let loading = true;
  let error = null;
  let gerandoPdf = false;

  let avaliadoresDisponiveis = [];
  let avaliadoresSelecionados = [];
  let avaliadosDisponiveis = [];
  let avaliadosSelecionados = [];
  let statusDisponiveis = [
    { codigo: 'pre_aprovado', nome: 'OK' },
    { codigo: 'observar', nome: 'Observar' },
    { codigo: 'sem_condicao', nome: 'Sem condição' }
  ];
  let statusSelecionados = [];
  let estadosDisponiveis = [];
  let estadosSelecionados = [];
  let condicoesDisponiveis = [];
  let condicoesSelecionadas = [];
  let edicoesDisponiveis = [];
  let edicoesSelecionadas = [];
  let filtrosCarregados = false;

  let avaliadorAberto = false;
  let avaliadoAberto = false;
  let statusAberto = false;
  let estadoAberto = false;
  let condicaoAberta = false;
  let edicaoAberta = false;

  onMount(async () => {
    if (!$user) {
      goto('/login');
      return;
    }
    if ($userProfile?.nivel === 'jovem') {
      goto('/');
      return;
    }
    await Promise.all([
      carregarOpcoesFiltro(),
      carregarEstadosDisponiveis(),
      carregarCondicoesDisponiveis(),
      carregarEdicoesDisponiveis()
    ]);
    await carregarJovens();
  });

  // Bloqueio reativo: nunca exibir para nível jovem (mesmo via URL direta)
  $: if ($userProfile?.nivel === 'jovem') {
    goto('/');
  }

  $: acessoNegado = $userProfile?.nivel === 'jovem';

  function fecharFiltrosExceto(aberto) {
    avaliadorAberto = aberto === 'avaliador';
    avaliadoAberto = aberto === 'avaliado';
    statusAberto = aberto === 'status';
    estadoAberto = aberto === 'estado';
    condicaoAberta = aberto === 'condicao';
    edicaoAberta = aberto === 'edicao';
  }

  function aplicarEscopo(query) {
    const userLevel = $userProfile?.nivel;
    const userId = $userProfile?.id;

    if (userLevel === 'colaborador' && userId) {
      return query.eq('usuario_id', userId);
    }
    if (userLevel === 'lider_estadual_iurd' || userLevel === 'lider_estadual_fju') {
      if ($userProfile?.estado_id) return query.eq('estado_id', $userProfile.estado_id);
    } else if (userLevel === 'lider_bloco_iurd' || userLevel === 'lider_bloco_fju') {
      if ($userProfile?.bloco_id) return query.eq('bloco_id', $userProfile.bloco_id);
    } else if (userLevel === 'lider_regional_iurd') {
      if ($userProfile?.regiao_id) return query.eq('regiao_id', $userProfile.regiao_id);
    } else if (userLevel === 'lider_igreja_iurd') {
      if ($userProfile?.igreja_id) return query.eq('igreja_id', $userProfile.igreja_id);
    }
    return query;
  }

  async function carregarOpcoesFiltro() {
    if ($userProfile?.nivel === 'jovem') return;
    try {
      const { data: aprovacoesData, error: aprovError } = await supabase
        .from('aprovacoes_jovens')
        .select(`
          jovem_id,
          usuario_id,
          usuario:usuarios!usuario_id(id, nome, foto)
        `)
        .in('tipo_aprovacao', TIPOS_PONTO_VISTA);

      if (aprovError) throw aprovError;

      const mapaAvaliadores = new Map();
      (aprovacoesData || []).forEach((a) => {
        const id = a.usuario_id;
        const nome = a.usuario?.nome;
        if (id && nome) mapaAvaliadores.set(id, nome);
      });
      avaliadoresDisponiveis = [...mapaAvaliadores.entries()]
        .map(([id, nome]) => ({ id, nome }))
        .sort((a, b) => a.nome.localeCompare(b.nome));

      const jovemIds = [...new Set((aprovacoesData || []).map((a) => a.jovem_id).filter(Boolean))];
      if (jovemIds.length > 0) {
        let query = supabase
          .from('jovens')
          .select('id, nome_completo')
          .in('id', jovemIds)
          .order('nome_completo', { ascending: true });
        query = aplicarEscopo(query);
        const { data: jovensFiltro } = await query;
        avaliadosDisponiveis = (jovensFiltro || []).map((j) => ({ id: j.id, nome: j.nome_completo }));
      } else {
        avaliadosDisponiveis = [];
      }
      filtrosCarregados = true;
    } catch (err) {
      console.error('Erro ao carregar opções de filtro:', err);
    }
  }

  async function carregarEstadosDisponiveis() {
    try {
      const userLevel = $userProfile?.nivel;
      const userId = $userProfile?.id;
      let query = supabase
        .from('estados')
        .select('id, nome, sigla')
        .order('nome', { ascending: true });

      if (userLevel === 'colaborador' && userId) {
        const { data: jovensData } = await supabase
          .from('jovens')
          .select('estado_id')
          .eq('usuario_id', userId)
          .not('estado_id', 'is', null);

        if (jovensData?.length) {
          query = query.in('id', [...new Set(jovensData.map((j) => j.estado_id).filter(Boolean))]);
        } else {
          estadosDisponiveis = [];
          return;
        }
      } else if (userLevel === 'lider_estadual_iurd' || userLevel === 'lider_estadual_fju') {
        if ($userProfile?.estado_id) query = query.eq('id', $userProfile.estado_id);
        else {
          estadosDisponiveis = [];
          return;
        }
      } else if (userLevel === 'lider_bloco_iurd' || userLevel === 'lider_bloco_fju') {
        if ($userProfile?.bloco_id) {
          const { data: blocoData } = await supabase
            .from('blocos')
            .select('estado_id')
            .eq('id', $userProfile.bloco_id)
            .single();
          if (blocoData?.estado_id) query = query.eq('id', blocoData.estado_id);
          else {
            estadosDisponiveis = [];
            return;
          }
        } else {
          estadosDisponiveis = [];
          return;
        }
      } else if (userLevel === 'lider_regional_iurd') {
        if ($userProfile?.regiao_id) {
          const { data: regiaoData } = await supabase
            .from('regioes')
            .select('bloco:blocos(estado_id)')
            .eq('id', $userProfile.regiao_id)
            .single();
          if (regiaoData?.bloco?.estado_id) query = query.eq('id', regiaoData.bloco.estado_id);
          else {
            estadosDisponiveis = [];
            return;
          }
        } else {
          estadosDisponiveis = [];
          return;
        }
      } else if (userLevel === 'lider_igreja_iurd') {
        if ($userProfile?.igreja_id) {
          const { data: igrejaData } = await supabase
            .from('igrejas')
            .select('regiao:regioes(bloco:blocos(estado_id))')
            .eq('id', $userProfile.igreja_id)
            .single();
          if (igrejaData?.regiao?.bloco?.estado_id) query = query.eq('id', igrejaData.regiao.bloco.estado_id);
          else {
            estadosDisponiveis = [];
            return;
          }
        } else {
          estadosDisponiveis = [];
          return;
        }
      }

      const { data, error: fetchError } = await query;
      if (fetchError) throw fetchError;
      estadosDisponiveis = data || [];
    } catch (err) {
      console.error('Erro ao carregar estados:', err);
      estadosDisponiveis = [];
    }
  }

  async function carregarCondicoesDisponiveis() {
    try {
      let query = supabase.from('jovens').select('condicao').not('condicao', 'is', null);
      query = aplicarEscopo(query);
      const { data, error: fetchError } = await query;
      if (fetchError) throw fetchError;

      const condicoesUnicas = [...new Set((data || []).map((j) => j.condicao).filter(Boolean))];
      condicoesDisponiveis = condicoesUnicas
        .map((c) => ({ codigo: c, nome: condicoesMap[c] || c }))
        .sort((a, b) => a.nome.localeCompare(b.nome));
    } catch (err) {
      console.error('Erro ao carregar condições:', err);
      condicoesDisponiveis = [];
    }
  }

  async function carregarEdicoesDisponiveis() {
    try {
      const userLevel = $userProfile?.nivel;
      const userId = $userProfile?.id;
      let query = supabase
        .from('edicoes')
        .select('id, nome, numero')
        .order('numero', { ascending: false });

      if (userLevel === 'colaborador' && userId) {
        const { data: jovensData } = await supabase
          .from('jovens')
          .select('edicao_id')
          .eq('usuario_id', userId)
          .not('edicao_id', 'is', null);

        if (jovensData?.length) {
          query = query.in('id', [...new Set(jovensData.map((j) => j.edicao_id).filter(Boolean))]);
        } else {
          edicoesDisponiveis = [];
          return;
        }
      }

      const { data, error: fetchError } = await query;
      if (fetchError) throw fetchError;
      edicoesDisponiveis = data || [];
    } catch (err) {
      console.error('Erro ao carregar edições:', err);
      edicoesDisponiveis = [];
    }
  }

  async function carregarJovens() {
    if ($userProfile?.nivel === 'jovem') {
      jovens = [];
      return;
    }
    loading = true;
    error = null;

    try {
      const { data: aprovacoesData, error: aprovError } = await supabase
        .from('aprovacoes_jovens')
        .select(`
          id,
          jovem_id,
          usuario_id,
          tipo_aprovacao,
          observacao,
          criado_em,
          usuario:usuarios!usuario_id(
            id,
            nome,
            foto
          )
        `)
        .in('tipo_aprovacao', TIPOS_PONTO_VISTA)
        .order('criado_em', { ascending: false });

      if (aprovError) throw aprovError;

      let pontos = (aprovacoesData || []).map((a) => ({
        id: a.id,
        jovem_id: a.jovem_id,
        usuario_id: a.usuario_id,
        usuario_nome: a.usuario?.nome || 'Usuário',
        usuario_foto: a.usuario?.foto || null,
        tipo_aprovacao: a.tipo_aprovacao,
        observacao: a.observacao,
        criado_em: a.criado_em
      }));

      if (avaliadoresSelecionados.length > 0) {
        pontos = pontos.filter((p) => avaliadoresSelecionados.includes(p.usuario_id));
      }
      if (statusSelecionados.length > 0) {
        pontos = pontos.filter((p) => statusSelecionados.includes(p.tipo_aprovacao));
      }

      const jovemIdsFiltrados = [...new Set(pontos.map((p) => p.jovem_id).filter(Boolean))];

      if (jovemIdsFiltrados.length === 0) {
        jovens = [];
        return;
      }

      let query = supabase
        .from('jovens')
        .select(`
          id,
          nome_completo,
          foto,
          condicao,
          condicao_campus,
          descricao_curta,
          estado:estados(
            id,
            nome,
            sigla,
            bandeira
          ),
          bloco:blocos!bloco_id(
            id,
            nome
          ),
          regiao:regioes!regiao_id(
            id,
            nome
          ),
          igreja:igrejas!igreja_id(
            id,
            nome
          )
        `)
        .in('id', jovemIdsFiltrados)
        .order('nome_completo', { ascending: true });

      query = aplicarEscopo(query);

      if (avaliadosSelecionados.length > 0) {
        query = query.in('id', avaliadosSelecionados);
      }
      if (estadosSelecionados.length > 0) {
        query = query.in('estado_id', estadosSelecionados);
      }
      if (condicoesSelecionadas.length > 0) {
        query = query.in('condicao', condicoesSelecionadas);
      }
      if (edicoesSelecionadas.length > 0) {
        query = query.in('edicao_id', edicoesSelecionadas);
      }

      const { data, error: fetchError } = await query;
      if (fetchError) throw fetchError;

      const listaJovens = data || [];
      const jovensIds = listaJovens.map((j) => j.id);

      let namoradosPorJovem = {};
      if (jovensIds.length > 0) {
        const { data: namoradosData } = await supabase
          .from('namorados')
          .select('jovem_id, nome, foto, idade')
          .in('jovem_id', jovensIds);
        (namoradosData || []).forEach((n) => {
          namoradosPorJovem[n.jovem_id] = { nome: n.nome, foto: n.foto, idade: n.idade };
        });
      }

      const pontosPorJovem = {};
      pontos.forEach((p) => {
        if (!jovensIds.includes(p.jovem_id)) return;
        if (!pontosPorJovem[p.jovem_id]) pontosPorJovem[p.jovem_id] = [];
        pontosPorJovem[p.jovem_id].push(p);
      });

      jovens = listaJovens
        .map((j) => ({
          ...j,
          namorado: namoradosPorJovem[j.id] || null,
          pontos_de_vista: pontosPorJovem[j.id] || []
        }))
        .filter((j) => j.pontos_de_vista.length > 0);

      if (!filtrosCarregados) {
        await carregarOpcoesFiltro();
      }
    } catch (err) {
      error = err.message;
      console.error('Erro ao carregar ponto de vista:', err);
      jovens = [];
    } finally {
      loading = false;
    }
  }

  function toggleAvaliador(id) {
    if (avaliadoresSelecionados.includes(id)) {
      avaliadoresSelecionados = avaliadoresSelecionados.filter((x) => x !== id);
    } else {
      avaliadoresSelecionados = [...avaliadoresSelecionados, id];
    }
    carregarJovens();
  }

  function toggleAvaliado(id) {
    if (avaliadosSelecionados.includes(id)) {
      avaliadosSelecionados = avaliadosSelecionados.filter((x) => x !== id);
    } else {
      avaliadosSelecionados = [...avaliadosSelecionados, id];
    }
    carregarJovens();
  }

  function toggleStatus(codigo) {
    if (statusSelecionados.includes(codigo)) {
      statusSelecionados = statusSelecionados.filter((x) => x !== codigo);
    } else {
      statusSelecionados = [...statusSelecionados, codigo];
    }
    carregarJovens();
  }

  function toggleEstado(id) {
    if (estadosSelecionados.includes(id)) {
      estadosSelecionados = estadosSelecionados.filter((x) => x !== id);
    } else {
      estadosSelecionados = [...estadosSelecionados, id];
    }
    carregarJovens();
  }

  function toggleCondicao(codigo) {
    if (condicoesSelecionadas.includes(codigo)) {
      condicoesSelecionadas = condicoesSelecionadas.filter((x) => x !== codigo);
    } else {
      condicoesSelecionadas = [...condicoesSelecionadas, codigo];
    }
    carregarJovens();
  }

  function toggleEdicao(id) {
    if (edicoesSelecionadas.includes(id)) {
      edicoesSelecionadas = edicoesSelecionadas.filter((x) => x !== id);
    } else {
      edicoesSelecionadas = [...edicoesSelecionadas, id];
    }
    carregarJovens();
  }

  function selecionarTodas() {
    avaliadoresSelecionados = avaliadoresDisponiveis.map((a) => a.id);
    avaliadosSelecionados = avaliadosDisponiveis.map((a) => a.id);
    statusSelecionados = statusDisponiveis.map((s) => s.codigo);
    estadosSelecionados = estadosDisponiveis.map((e) => e.id);
    condicoesSelecionadas = condicoesDisponiveis.map((c) => c.codigo);
    edicoesSelecionadas = edicoesDisponiveis.map((e) => e.id);
    carregarJovens();
  }

  function limparFiltros() {
    avaliadoresSelecionados = [];
    avaliadosSelecionados = [];
    statusSelecionados = [];
    estadosSelecionados = [];
    condicoesSelecionadas = [];
    edicoesSelecionadas = [];
    carregarJovens();
  }

  function loadImage(src) {
    return new Promise((resolve, reject) => {
      const img = new Image();
      img.crossOrigin = 'anonymous';
      img.onload = () => {
        const canvas = document.createElement('canvas');
        canvas.width = img.width;
        canvas.height = img.height;
        const ctx = canvas.getContext('2d');
        ctx.drawImage(img, 0, 0);
        resolve(canvas.toDataURL('image/jpeg', 0.8));
      };
      img.onerror = reject;
      img.src = src;
    });
  }

  async function gerarPDF() {
    if (jovens.length === 0) {
      alert('Não há jovens para gerar o PDF');
      return;
    }

    gerandoPdf = true;
    try {
      const { jsPDF } = await import('jspdf');
      const doc = new jsPDF('p', 'mm', 'a4');
      const pageWidth = doc.internal.pageSize.getWidth();
      const pageHeight = doc.internal.pageSize.getHeight();
      const margin = 10;
      const cardHeight = 95;
      const gap = 6;
      let y = margin;

      for (let i = 0; i < jovens.length; i++) {
        const jovem = jovens[i];
        if (y + cardHeight > pageHeight - margin) {
          doc.addPage();
          y = margin;
        }

        const x = margin;
        const cardWidth = pageWidth - margin * 2;
        const fotoW = 42;
        const fotoH = 56;
        const namoradoW = 22;
        const contentX = x + fotoW + namoradoW + 10;

        doc.setFillColor(255, 255, 255);
        doc.setDrawColor(210, 210, 210);
        doc.setLineWidth(0.3);
        doc.roundedRect(x, y, cardWidth, cardHeight, 2, 2, 'FD');

        // Foto jovem
        if (jovem.foto) {
          try {
            const imgData = await loadImage(jovem.foto);
            doc.addImage(imgData, 'JPEG', x + 3, y + 3, fotoW, fotoH);
          } catch {
            doc.setFillColor(200, 200, 200);
            doc.rect(x + 3, y + 3, fotoW, fotoH, 'F');
          }
        } else {
          doc.setFillColor(200, 200, 200);
          doc.rect(x + 3, y + 3, fotoW, fotoH, 'F');
        }

        // Foto namorado
        if (jovem.namorado?.foto) {
          try {
            const imgN = await loadImage(jovem.namorado.foto);
            doc.addImage(imgN, 'JPEG', x + 3 + fotoW + 2, y + 3, namoradoW, 30);
          } catch {
            /* ignore */
          }
        }

        let ty = y + 8;
        doc.setFont('helvetica', 'bold');
        doc.setFontSize(11);
        doc.setTextColor(20, 20, 20);
        const nomeLines = doc.splitTextToSize((jovem.nome_completo || 'N/A').toUpperCase(), cardWidth - contentX + x - 4);
        doc.text(nomeLines, contentX, ty);
        ty += nomeLines.length * 5 + 2;

        doc.setFontSize(8);
        doc.setFont('helvetica', 'normal');
        doc.setTextColor(40, 40, 40);
        const meta = [
          `Estado: ${(jovem.estado?.nome || 'N/A').toUpperCase()}`,
          `Bloco: ${(jovem.bloco?.nome || 'N/A').toUpperCase()}`,
          `Região: ${(jovem.regiao?.nome || 'N/A').toUpperCase()}`,
          `Igreja: ${(jovem.igreja?.nome || 'N/A').toUpperCase()}`
        ];
        meta.forEach((line) => {
          doc.text(line, contentX, ty);
          ty += 4;
        });

        ty += 2;
        const pontos = jovem.pontos_de_vista || [];
        const avaliadoPor = pontos.map((p) => p.usuario_nome).filter(Boolean).join(', ') || '—';
        const pontoTexto = pontos.length
          ? pontos.map((p) => `${p.usuario_nome} - ${statusLabel[p.tipo_aprovacao] || p.tipo_aprovacao}`).join(', ')
          : '—';

        doc.setFont('helvetica', 'bold');
        doc.text('Avaliado por:', contentX, ty);
        doc.setFont('helvetica', 'normal');
        const avLines = doc.splitTextToSize(avaliadoPor, cardWidth - (contentX - x) - 4);
        doc.text(avLines, contentX + 28, ty);
        ty += Math.max(avLines.length, 1) * 3.8 + 1;

        doc.setFont('helvetica', 'bold');
        doc.text('Ponto de Vista:', contentX, ty);
        doc.setFont('helvetica', 'normal');
        const pvLines = doc.splitTextToSize(pontoTexto, cardWidth - (contentX - x) - 4);
        doc.text(pvLines, contentX + 30, ty);
        ty += Math.max(pvLines.length, 1) * 3.8 + 1;

        const obs = pontos.filter((p) => p.observacao);
        doc.setFont('helvetica', 'bold');
        doc.text('Observações:', contentX, ty);
        ty += 4;
        doc.setFont('helvetica', 'normal');
        if (obs.length === 0) {
          doc.text('—', contentX, ty);
        } else {
          obs.forEach((o) => {
            const line = `${o.usuario_nome}: ${o.observacao}`;
            const lines = doc.splitTextToSize(line, cardWidth - (contentX - x) - 4);
            doc.text(lines, contentX, ty);
            ty += lines.length * 3.6 + 0.5;
          });
        }

        y += cardHeight + gap;
      }

      doc.save(`ponto-de-vista-${new Date().toISOString().split('T')[0]}.pdf`);
    } catch (err) {
      console.error('Erro ao gerar PDF:', err);
      alert('Erro ao gerar PDF. Verifique o console para mais detalhes.');
    } finally {
      gerandoPdf = false;
    }
  }
</script>

<svelte:head>
  <title>Ponto de Vista | Godllywood Campus</title>
</svelte:head>

<div class="min-h-screen bg-gray-50">
  {#if acessoNegado}
    <div class="max-w-7xl mx-auto px-4 py-12 text-center text-gray-600">
      <p class="text-lg font-medium">Acesso não permitido</p>
    </div>
  {:else}
  <div class="bg-white shadow-sm border-b border-gray-200">
    <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
      <div class="flex flex-col sm:flex-row sm:items-center sm:justify-between py-4 sm:py-6 space-y-4 sm:space-y-0">
        <div class="flex items-center space-x-3">
          <button
            on:click={() => goto('/')}
            class="p-2 rounded-lg hover:bg-gray-100 transition-colors"
          >
            <svg class="w-5 h-5 text-gray-600" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 19l-7-7 7-7" />
            </svg>
          </button>
          <div>
            <h1 class="text-xl sm:text-2xl font-bold text-gray-900">Ponto de Vista</h1>
            <p class="text-sm text-gray-500">{jovens.length} jovens avaliados</p>
          </div>
        </div>

        <Button on:click={gerarPDF} variant="primary" disabled={jovens.length === 0 || gerandoPdf} class="w-full sm:w-auto">
          <svg class="w-4 h-4 mr-2" fill="none" viewBox="0 0 24 24" stroke="currentColor">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 10v6m0 0l-3-3m3 3l3-3m2 8H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z" />
          </svg>
          {gerandoPdf ? 'Gerando...' : 'Gerar PDF'}
        </Button>
      </div>
    </div>
  </div>

  <div class="bg-white border-b border-gray-200">
    <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-4">
      <div class="flex flex-col sm:flex-row sm:items-center sm:justify-between space-y-3 sm:space-y-0 mb-4">
        <span class="text-sm font-medium text-gray-700">Filtros:</span>
        <div class="flex flex-wrap items-center gap-2">
          <button
            on:click={selecionarTodas}
            class="px-3 py-1.5 text-xs font-medium text-blue-700 bg-blue-50 border border-blue-200 rounded-lg hover:bg-blue-100 transition-colors"
          >
            Selecionar Todas
          </button>
          <button
            on:click={limparFiltros}
            class="px-3 py-1.5 text-xs font-medium text-gray-700 bg-gray-50 border border-gray-200 rounded-lg hover:bg-gray-100 transition-colors"
          >
            Limpar Filtros
          </button>
        </div>
      </div>

      <div class="flex flex-wrap gap-2 mb-4">
        <button
          on:click={() => {
            const abrir = !avaliadorAberto;
            fecharFiltrosExceto(abrir ? 'avaliador' : null);
          }}
          class="px-3 py-1.5 text-xs font-medium rounded-lg border transition-colors
            {avaliadorAberto || avaliadoresSelecionados.length
              ? 'bg-indigo-600 text-white border-indigo-600'
              : 'bg-white text-gray-700 border-gray-300'}"
        >
          Filtro por Avaliador
          {#if avaliadoresSelecionados.length}({avaliadoresSelecionados.length}){/if}
        </button>
        <button
          on:click={() => {
            const abrir = !avaliadoAberto;
            fecharFiltrosExceto(abrir ? 'avaliado' : null);
          }}
          class="px-3 py-1.5 text-xs font-medium rounded-lg border transition-colors
            {avaliadoAberto || avaliadosSelecionados.length
              ? 'bg-rose-600 text-white border-rose-600'
              : 'bg-white text-gray-700 border-gray-300'}"
        >
          Filtro por Avaliado
          {#if avaliadosSelecionados.length}({avaliadosSelecionados.length}){/if}
        </button>
        <button
          on:click={() => {
            const abrir = !statusAberto;
            fecharFiltrosExceto(abrir ? 'status' : null);
          }}
          class="px-3 py-1.5 text-xs font-medium rounded-lg border transition-colors
            {statusAberto || statusSelecionados.length
              ? 'bg-amber-600 text-white border-amber-600'
              : 'bg-white text-gray-700 border-gray-300'}"
        >
          Filtro por Status
          {#if statusSelecionados.length}({statusSelecionados.length}){/if}
        </button>
        <button
          on:click={() => {
            const abrir = !estadoAberto;
            fecharFiltrosExceto(abrir ? 'estado' : null);
          }}
          class="px-3 py-1.5 text-xs font-medium rounded-lg border transition-colors
            {estadoAberto || estadosSelecionados.length
              ? 'bg-emerald-600 text-white border-emerald-600'
              : 'bg-white text-gray-700 border-gray-300'}"
        >
          Filtro por Estado
          {#if estadosSelecionados.length}({estadosSelecionados.length}){/if}
        </button>
        <button
          on:click={() => {
            const abrir = !condicaoAberta;
            fecharFiltrosExceto(abrir ? 'condicao' : null);
          }}
          class="px-3 py-1.5 text-xs font-medium rounded-lg border transition-colors
            {condicaoAberta || condicoesSelecionadas.length
              ? 'bg-cyan-600 text-white border-cyan-600'
              : 'bg-white text-gray-700 border-gray-300'}"
        >
          Filtro por Condição
          {#if condicoesSelecionadas.length}({condicoesSelecionadas.length}){/if}
        </button>
        <button
          on:click={() => {
            const abrir = !edicaoAberta;
            fecharFiltrosExceto(abrir ? 'edicao' : null);
          }}
          class="px-3 py-1.5 text-xs font-medium rounded-lg border transition-colors
            {edicaoAberta || edicoesSelecionadas.length
              ? 'bg-purple-600 text-white border-purple-600'
              : 'bg-white text-gray-700 border-gray-300'}"
        >
          Filtro por Edição
          {#if edicoesSelecionadas.length}({edicoesSelecionadas.length}){/if}
        </button>
      </div>

      {#if avaliadorAberto}
        <div transition:slide={{ duration: 250 }} class="flex flex-wrap gap-2 mb-2">
          {#each avaliadoresDisponiveis as item}
            <button
              on:click={() => toggleAvaliador(item.id)}
              class="px-3 py-1.5 text-sm rounded-lg border-2 transition-colors
                {avaliadoresSelecionados.includes(item.id)
                  ? 'bg-indigo-600 text-white border-indigo-600'
                  : 'bg-white text-gray-700 border-gray-300 hover:border-indigo-400'}"
            >
              {item.nome}
            </button>
          {/each}
          {#if avaliadoresDisponiveis.length === 0}
            <p class="text-sm text-gray-500">Nenhum avaliador encontrado.</p>
          {/if}
        </div>
      {/if}

      {#if avaliadoAberto}
        <div transition:slide={{ duration: 250 }} class="flex flex-wrap gap-2 mb-2">
          {#each avaliadosDisponiveis as item}
            <button
              on:click={() => toggleAvaliado(item.id)}
              class="px-3 py-1.5 text-sm rounded-lg border-2 transition-colors
                {avaliadosSelecionados.includes(item.id)
                  ? 'bg-rose-600 text-white border-rose-600'
                  : 'bg-white text-gray-700 border-gray-300 hover:border-rose-400'}"
            >
              {item.nome}
            </button>
          {/each}
          {#if avaliadosDisponiveis.length === 0}
            <p class="text-sm text-gray-500">Nenhum avaliado encontrado.</p>
          {/if}
        </div>
      {/if}

      {#if statusAberto}
        <div transition:slide={{ duration: 250 }} class="flex flex-wrap gap-2 mb-2">
          {#each statusDisponiveis as item}
            <button
              on:click={() => toggleStatus(item.codigo)}
              class="px-3 py-1.5 text-sm rounded-lg border-2 transition-colors
                {statusSelecionados.includes(item.codigo)
                  ? 'bg-amber-600 text-white border-amber-600'
                  : 'bg-white text-gray-700 border-gray-300 hover:border-amber-400'}"
            >
              {item.nome}
            </button>
          {/each}
        </div>
      {/if}

      {#if estadoAberto}
        <div transition:slide={{ duration: 250 }} class="flex flex-wrap gap-2 mb-2">
          {#each estadosDisponiveis as item}
            <button
              on:click={() => toggleEstado(item.id)}
              class="px-3 py-1.5 text-sm rounded-lg border-2 transition-colors
                {estadosSelecionados.includes(item.id)
                  ? 'bg-emerald-600 text-white border-emerald-600'
                  : 'bg-white text-gray-700 border-gray-300 hover:border-emerald-400'}"
            >
              {item.nome}
            </button>
          {/each}
          {#if estadosDisponiveis.length === 0}
            <p class="text-sm text-gray-500">Nenhum estado encontrado.</p>
          {/if}
        </div>
      {/if}

      {#if condicaoAberta}
        <div transition:slide={{ duration: 250 }} class="flex flex-wrap gap-2 mb-2">
          {#each condicoesDisponiveis as item}
            <button
              on:click={() => toggleCondicao(item.codigo)}
              class="px-3 py-1.5 text-sm rounded-lg border-2 transition-colors
                {condicoesSelecionadas.includes(item.codigo)
                  ? 'bg-cyan-600 text-white border-cyan-600'
                  : 'bg-white text-gray-700 border-gray-300 hover:border-cyan-400'}"
            >
              {item.nome}
            </button>
          {/each}
          {#if condicoesDisponiveis.length === 0}
            <p class="text-sm text-gray-500">Nenhuma condição encontrada.</p>
          {/if}
        </div>
      {/if}

      {#if edicaoAberta}
        <div transition:slide={{ duration: 250 }} class="flex flex-wrap gap-2 mb-2">
          {#each edicoesDisponiveis as item}
            <button
              on:click={() => toggleEdicao(item.id)}
              class="px-3 py-1.5 text-sm rounded-lg border-2 transition-colors
                {edicoesSelecionadas.includes(item.id)
                  ? 'bg-purple-600 text-white border-purple-600'
                  : 'bg-white text-gray-700 border-gray-300 hover:border-purple-400'}"
            >
              {item.nome}
            </button>
          {/each}
          {#if edicoesDisponiveis.length === 0}
            <p class="text-sm text-gray-500">Nenhuma edição encontrada.</p>
          {/if}
        </div>
      {/if}
    </div>
  </div>

  <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-6">
    {#if loading}
      <div class="flex items-center justify-center py-12">
        <div class="animate-spin rounded-full h-12 w-12 border-b-2 border-blue-600"></div>
      </div>
    {:else if error}
      <div class="bg-red-50 border border-red-200 rounded-md p-4">
        <p class="text-sm text-red-600">{error}</p>
      </div>
    {:else if jovens.length === 0}
      <div class="bg-white rounded-lg shadow p-8 text-center text-gray-600">
        <p class="text-lg font-medium mb-2">Nenhum jovem avaliado encontrado</p>
        <p class="text-sm">Use Pré-aprovar, Observar ou Sem condição no perfil do jovem para registrar o ponto de vista.</p>
      </div>
    {:else}
      <div class="grid grid-cols-1 gap-6">
        {#each jovens as jovem (jovem.id)}
          <CardPontoDeVista {jovem} />
        {/each}
      </div>
    {/if}
  </div>
  {/if}
</div>
