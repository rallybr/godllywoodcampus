<script>
  import { onMount } from 'svelte';
  import { goto } from '$app/navigation';
  import { user, userProfile } from '$lib/stores/auth';
  import { supabase } from '$lib/utils/supabase';
  import CardCondicao from '$lib/components/relatorios/CardCondicao.svelte';
  import Button from '$lib/components/ui/Button.svelte';
  import { slide } from 'svelte/transition';

  let jovens = [];
  let loading = true;
  let error = null;
  
  // Filtros
  let condicoesDisponiveis = [];
  let condicoesSelecionadas = [];
  let estadosDisponiveis = [];
  let estadosSelecionados = [];
  let blocosDisponiveis = [];
  let blocosSelecionados = [];
  let edicoesDisponiveis = [];
  let edicoesSelecionadas = [];
  
  // Estados do accordion
  let condicaoAberta = false;
  let estadoAberto = false;
  let blocoAberto = false;
  let edicaoAberta = false;
  
  // Mapear códigos para nomes
  const condicoesMap = {
    'auxiliar_pastor': 'Auxiliar de Pastor',
    'iburd': 'IBURD',
    'obreiro': 'Obreiro',
    'colaborador': 'Colaborador',
    'cpo': 'CPO',
    'jovem_batizado_es': 'Jovem',
    'desertou': 'Desertou'
  };

  onMount(async () => {
    if (!$user) {
      goto('/login');
    } else if ($userProfile?.nivel === 'jovem') {
      goto('/');
    } else {
      await carregarCondicoesDisponiveis();
      await carregarEstadosDisponiveis();
      await carregarEdicoesDisponiveis();
      await carregarJovens();
    }
  });

  async function carregarCondicoesDisponiveis() {
    try {
      const { data, error: fetchError } = await supabase
        .from('jovens')
        .select('condicao')
        .not('condicao', 'is', null);

      if (fetchError) throw fetchError;

      // Obter condições únicas
      const condicoesUnicas = [...new Set(data.map(j => j.condicao).filter(Boolean))];
      condicoesDisponiveis = condicoesUnicas.map(c => ({
        codigo: c,
        nome: condicoesMap[c] || c
      })).sort((a, b) => a.nome.localeCompare(b.nome));
    } catch (err) {
      console.error('Erro ao carregar condições:', err);
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

      // Aplicar filtros baseados no nível de acesso
      if (userLevel === 'colaborador' && userId) {
        // Colaborador: apenas estados dos jovens que ele cadastrou
        const { data: jovensData } = await supabase
          .from('jovens')
          .select('estado_id')
          .eq('usuario_id', userId)
          .not('estado_id', 'is', null);
        
        if (jovensData && jovensData.length > 0) {
          const estadoIds = [...new Set(jovensData.map(j => j.estado_id).filter(Boolean))];
          query = query.in('id', estadoIds);
        } else {
          // Se não tem jovens cadastrados, não mostra estados
          estadosDisponiveis = [];
          return;
        }
      } else if (userLevel === 'lider_estadual_iurd' || userLevel === 'lider_estadual_fju') {
        // Líder estadual: apenas seu estado
        if ($userProfile?.estado_id) {
          query = query.eq('id', $userProfile.estado_id);
        } else {
          estadosDisponiveis = [];
          return;
        }
      } else if (userLevel === 'lider_bloco_iurd' || userLevel === 'lider_bloco_fju') {
        // Líder de bloco: estado do seu bloco
        if ($userProfile?.bloco_id) {
          const { data: blocoData } = await supabase
            .from('blocos')
            .select('estado_id')
            .eq('id', $userProfile.bloco_id)
            .single();
          
          if (blocoData?.estado_id) {
            query = query.eq('id', blocoData.estado_id);
          } else {
            estadosDisponiveis = [];
            return;
          }
        } else {
          estadosDisponiveis = [];
          return;
        }
      } else if (userLevel === 'lider_regional_iurd') {
        // Líder regional: estado da sua região
        if ($userProfile?.regiao_id) {
          const { data: regiaoData } = await supabase
            .from('regioes')
            .select('bloco:blocos(estado_id)')
            .eq('id', $userProfile.regiao_id)
            .single();
          
          if (regiaoData?.bloco?.estado_id) {
            query = query.eq('id', regiaoData.bloco.estado_id);
          } else {
            estadosDisponiveis = [];
            return;
          }
        } else {
          estadosDisponiveis = [];
          return;
        }
      } else if (userLevel === 'lider_igreja_iurd') {
        // Líder de igreja: estado da sua igreja
        if ($userProfile?.igreja_id) {
          const { data: igrejaData } = await supabase
            .from('igrejas')
            .select('regiao:regioes(bloco:blocos(estado_id))')
            .eq('id', $userProfile.igreja_id)
            .single();
          
          if (igrejaData?.regiao?.bloco?.estado_id) {
            query = query.eq('id', igrejaData.regiao.bloco.estado_id);
          } else {
            estadosDisponiveis = [];
            return;
          }
        } else {
          estadosDisponiveis = [];
          return;
        }
      }
      // Administrador e líderes nacionais: veem todos os estados (sem filtro)

      const { data, error: fetchError } = await query;

      if (fetchError) throw fetchError;

      estadosDisponiveis = data || [];
    } catch (err) {
      console.error('Erro ao carregar estados:', err);
      estadosDisponiveis = [];
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

      // Aplicar filtros baseados no nível de acesso
      if (userLevel === 'colaborador' && userId) {
        // Colaborador: apenas edições dos jovens que ele cadastrou
        const { data: jovensData } = await supabase
          .from('jovens')
          .select('edicao_id')
          .eq('usuario_id', userId)
          .not('edicao_id', 'is', null);
        
        if (jovensData && jovensData.length > 0) {
          const edicaoIds = [...new Set(jovensData.map(j => j.edicao_id).filter(Boolean))];
          query = query.in('id', edicaoIds);
        } else {
          // Se não tem jovens cadastrados, não mostra edições
          edicoesDisponiveis = [];
          return;
        }
      }
      // Outros níveis: veem todas as edições (sem filtro adicional)

      const { data, error: fetchError } = await query;

      if (fetchError) throw fetchError;

      edicoesDisponiveis = data || [];
    } catch (err) {
      console.error('Erro ao carregar edições:', err);
      edicoesDisponiveis = [];
    }
  }

  async function carregarJovens() {
    loading = true;
    error = null;

    try {
      let query = supabase
        .from('jovens')
        .select(`
          id,
          nome_completo,
          foto,
          condicao,
          condicao_campus,
          estado:estados(
            id,
            nome,
            sigla,
            bandeira
          )
        `)
        .order('nome_completo', { ascending: true });

      // Aplicar filtro por condição se houver seleções
      if (condicoesSelecionadas.length > 0) {
        query = query.in('condicao', condicoesSelecionadas);
      }

      // Aplicar filtro por estado se houver seleções
      if (estadosSelecionados.length > 0) {
        query = query.in('estado_id', estadosSelecionados);
      }

      // Aplicar filtro por edição se houver seleções
      if (edicoesSelecionadas.length > 0) {
        query = query.in('edicao_id', edicoesSelecionadas);
      }

      // Aplicar escopo por nível de acesso
      const userLevel = $userProfile?.nivel;
      const userId = $userProfile?.id;

      if (userLevel === 'colaborador' && userId) {
        query = query.eq('usuario_id', userId);
      } else if (userLevel === 'lider_estadual_iurd' || userLevel === 'lider_estadual_fju') {
        if ($userProfile?.estado_id) {
          query = query.eq('estado_id', $userProfile.estado_id);
        }
      } else if (userLevel === 'lider_bloco_iurd' || userLevel === 'lider_bloco_fju') {
        if ($userProfile?.bloco_id) {
          query = query.eq('bloco_id', $userProfile.bloco_id);
        }
      } else if (userLevel === 'lider_regional_iurd') {
        if ($userProfile?.regiao_id) {
          query = query.eq('regiao_id', $userProfile.regiao_id);
        }
      } else if (userLevel === 'lider_igreja_iurd') {
        if ($userProfile?.igreja_id) {
          query = query.eq('igreja_id', $userProfile.igreja_id);
        }
      }

      const { data, error: fetchError } = await query;

      if (fetchError) throw fetchError;

      jovens = data || [];
    } catch (err) {
      error = err.message;
      console.error('Erro ao carregar jovens:', err);
    } finally {
      loading = false;
    }
  }

  function toggleCondicao(codigo) {
    if (condicoesSelecionadas.includes(codigo)) {
      condicoesSelecionadas = condicoesSelecionadas.filter(c => c !== codigo);
    } else {
      condicoesSelecionadas = [...condicoesSelecionadas, codigo];
    }
    carregarJovens();
  }

  function toggleEstado(estadoId) {
    if (estadosSelecionados.includes(estadoId)) {
      estadosSelecionados = estadosSelecionados.filter(e => e !== estadoId);
    } else {
      estadosSelecionados = [...estadosSelecionados, estadoId];
    }
    carregarJovens();
  }

  function toggleEdicao(edicaoId) {
    if (edicoesSelecionadas.includes(edicaoId)) {
      edicoesSelecionadas = edicoesSelecionadas.filter(e => e !== edicaoId);
    } else {
      edicoesSelecionadas = [...edicoesSelecionadas, edicaoId];
    }
    carregarJovens();
  }

  function selecionarTodas() {
    condicoesSelecionadas = condicoesDisponiveis.map(c => c.codigo);
    estadosSelecionados = estadosDisponiveis.map(e => e.id);
    edicoesSelecionadas = edicoesDisponiveis.map(e => e.id);
    carregarJovens();
  }

  function limparFiltros() {
    condicoesSelecionadas = [];
    estadosSelecionados = [];
    edicoesSelecionadas = [];
    carregarJovens();
  }

  async function gerarPDF() {
    if (jovens.length === 0) {
      alert('Não há jovens para gerar o PDF');
      return;
    }

    try {
      // Importar jsPDF dinamicamente
      const { jsPDF } = await import('jspdf');

      // Criar PDF em formato A4 Portrait (4 cards por página: 2x2)
      const doc = new jsPDF('p', 'mm', 'a4');
      const pageWidth = doc.internal.pageSize.getWidth(); // 210mm
      const pageHeight = doc.internal.pageSize.getHeight(); // 297mm
      const margin = 8;
      const spacing = 6;
      const cardWidth = (pageWidth - (margin * 2) - spacing) / 2; // ~97mm
      const cardHeight = (pageHeight - (margin * 2) - spacing) / 2; // ~140mm

      let currentRow = 0;
      let currentCol = 0;
      let cardIndex = 0;

      // Função auxiliar para carregar imagem
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

      // Função para adicionar um card ao PDF
      async function adicionarCard(jovem, x, y) {
        // Fundo branco do card com borda arredondada
        doc.setFillColor(255, 255, 255);
        doc.setDrawColor(200, 200, 200);
        doc.setLineWidth(0.3);
        doc.roundedRect(x, y, cardWidth, cardHeight, 3, 3, 'FD');

        let currentYCard = y;

        // Foto (largura total do card)
        const fotoHeight = 80; // Altura fixa para foto
        const fotoWidth = cardWidth;

        if (jovem.foto) {
          try {
            const imgData = await loadImage(jovem.foto);
            doc.addImage(imgData, 'JPEG', x, currentYCard, fotoWidth, fotoHeight);
            
            // Bandeira no canto superior direito da foto (aumentada em 50%)
            if (jovem.estado?.bandeira) {
              try {
                const flagData = await loadImage(jovem.estado.bandeira);
                const flagWidth = 21; // Aumentado de 14 para 21 (50% maior)
                const flagHeight = 15; // Aumentado de 10 para 15 (50% maior)
                doc.addImage(flagData, 'JPEG', x + fotoWidth - flagWidth - 2, currentYCard + 2, flagWidth, flagHeight);
              } catch (err) {
                console.warn('Erro ao carregar bandeira:', err);
              }
            }
          } catch (err) {
            console.warn('Erro ao carregar foto:', err);
            // Placeholder
            doc.setFillColor(200, 200, 200);
            doc.roundedRect(x, currentYCard, fotoWidth, fotoHeight, 2, 2, 'F');
            doc.setFontSize(24);
            doc.setTextColor(100, 100, 100);
            doc.text(jovem.nome_completo?.charAt(0) || 'J', x + cardWidth / 2, currentYCard + fotoHeight / 2, { align: 'center', baseline: 'middle' });
          }
        } else {
          // Placeholder sem foto
          doc.setFillColor(200, 200, 200);
          doc.roundedRect(x, currentYCard, fotoWidth, fotoHeight, 2, 2, 'F');
          doc.setFontSize(24);
          doc.setTextColor(100, 100, 100);
          doc.text(jovem.nome_completo?.charAt(0) || 'J', x + cardWidth / 2, currentYCard + fotoHeight / 2, { align: 'center', baseline: 'middle' });
        }

        // Adicionar sombra na parte inferior da foto (efeito 3D)
        const shadowHeight = 3; // Altura da sombra
        const shadowY = currentYCard + fotoHeight; // Posição abaixo da foto
        doc.setFillColor(0, 0, 0);
        doc.setGState(doc.GState({opacity: 0.15}));
        doc.rect(x, shadowY, fotoWidth, shadowHeight, 'F');
        doc.setGState(doc.GState({opacity: 1}));
        
        currentYCard += fotoHeight + 10; // Espaçamento de 10px entre foto e nome

        // Nome (fonte maior, caixa alta)
        doc.setFontSize(11); // Aumentado de 9 para 11
        doc.setFont('helvetica', 'bold');
        doc.setTextColor(0, 0, 0);
        const nomeCompleto = (jovem.nome_completo || 'N/A').toUpperCase();
        const nomeLines = doc.splitTextToSize(nomeCompleto, cardWidth - 6);
        doc.text(nomeLines, x + cardWidth / 2, currentYCard, { align: 'center' });
        currentYCard += nomeLines.length * 4 + 2;

        // Estado (fonte maior, caixa alta)
        doc.setFontSize(10); // Aumentado de 9 para 10
        doc.setFont('helvetica', 'bold');
        const estadoNome = (jovem.estado?.nome || jovem.estado?.sigla || 'N/A').toUpperCase();
        const estadoTexto = `ESTADO: ${estadoNome}`;
        doc.text(estadoTexto, x + cardWidth / 2, currentYCard, { align: 'center' });
        currentYCard += 5;

        // Timeline - replicar exatamente como está na tela
        const timelineY = currentYCard;
        const timelineWidth = cardWidth - 4;
        const timelineX = x + 2;
        const marginRight = 10; // 10px de margem para o último círculo
        const timelineBackgroundHeight = 6; // h-6 (mais alto que a barra)
        const timelineBarHeight = 4; // h-4 (altura da barra verde)

        // Background cinza semi-transparente da timeline (mais alto que a barra, arredondado)
        doc.setFillColor(51, 51, 51);
        doc.setGState(doc.GState({opacity: 0.2}));
        doc.roundedRect(timelineX, timelineY - 0.5, timelineWidth, timelineBackgroundHeight, 3, 3, 'F');
        doc.setGState(doc.GState({opacity: 1}));

        // Área útil para posicionar os círculos (largura total menos margem direita)
        const areaUtilCirculos = timelineWidth - marginRight;
        
        // Valores de posição dos círculos (ajustados para considerar a margem de 10px)
        // Os percentuais são calculados sobre a área útil, não sobre a largura total
        const posicoesCirculos = {
          1: 8, 2: 24.5, 3: 41, 4: 57.5, 5: 74, 6: 100
        };

        // Barra de progresso verde (dentro do background, alinhada)
        const estagioAtual = getEstagioAtual(jovem);
        const barraY = timelineY + 0.5; // Alinhada dentro do background
        doc.setFillColor(0, 168, 255); // #00a8ff
        
        // Se for a última condição (AUX = 6), a barra vai até o final do background
        // Caso contrário, para no círculo correspondente usando a área útil
        let larguraBarraFinal;
        if (estagioAtual === 6) {
          // Última condição: barra vai até o final do background (100% da timelineWidth)
          larguraBarraFinal = timelineWidth;
        } else {
          // Outras condições: barra para no círculo correspondente
          const larguraBarra = estagioAtual > 0 ? (posicoesCirculos[estagioAtual] || 0) : 0;
          larguraBarraFinal = (areaUtilCirculos * larguraBarra) / 100;
        }
        
        doc.roundedRect(timelineX, barraY, larguraBarraFinal, timelineBarHeight, 2, 2, 'F');

        // Pontos da timeline - usar os mesmos valores percentuais da tela
        const etapas = ['JOVEM', 'CPO', 'COL', 'OBR', 'IBURD', 'AUX'];
        
        etapas.forEach((etapa, index) => {
          const etapaId = index + 1;
          // Calcular posição do círculo usando os valores percentuais sobre a área útil
          const pointX = timelineX + (areaUtilCirculos * posicoesCirculos[etapaId] / 100);
          
          let cor;
          const estagioCampus = getEstagioCampus(jovem);
          if (estagioCampus === etapaId && estagioCampus > 0) {
            cor = [255, 165, 0]; // Laranja - condição do Campus
          } else if (estagioAtual >= etapaId && estagioAtual > 0) {
            cor = [0, 168, 255]; // Azul #00a8ff - etapas concluídas
          } else {
            cor = [200, 200, 200]; // Cinza - pendentes
          }

          // Ponto (sobre a barra, centralizado verticalmente na barra)
          const pointY = barraY + timelineBarHeight / 2;
          doc.setFillColor(...cor);
          doc.circle(pointX, pointY, 2.5, 'F');
          // Borda branca do círculo (border-2 border-white)
          doc.setDrawColor(255, 255, 255);
          doc.setLineWidth(0.8);
          doc.circle(pointX, pointY, 2.5, 'S');
          
          // Triângulo azul acima da label (apontando para cima, apenas 3px acima da barra)
          const triangleY = pointY + 2.5 + 3; // 3px de espaçamento da barra
          doc.setFillColor(59, 130, 246); // Azul #3b82f6
          // Triângulo apontando para cima (coordenadas invertidas)
          doc.triangle(pointX - 2.5, triangleY + 3, pointX + 2.5, triangleY + 3, pointX, triangleY, 'F');
          
          // Label abaixo do triângulo (apenas 3px de espaçamento)
          const labelY = triangleY + 3 + 3; // 3px de espaçamento após o triângulo
          doc.setFontSize(5.5);
          doc.setFont('helvetica', 'bold');
          doc.setTextColor(0, 0, 0);
          doc.text(etapa, pointX, labelY, { align: 'center' });
        });
      }

      // Funções auxiliares
      function normalize(str) {
        if (!str) return '';
        return str.toString().trim().toLowerCase().normalize('NFD').replace(/\p{Diacritic}/gu, '');
      }

      function getEstagioAtual(jovem) {
        const condicaoParaEstagioMap = {
          'jovem_batizado_es': 1, 'cpo': 2, 'colaborador': 3,
          'obreiro': 4, 'iburd': 5, 'auxiliar_pastor': 6
        };
        return condicaoParaEstagioMap[normalize(jovem.condicao)] || 0;
      }

      function getEstagioCampus(jovem) {
        if (!jovem.condicao_campus) return 0;
        const condicaoParaEstagioMap = {
          'jovem_batizado_es': 1, 'cpo': 2, 'colaborador': 3,
          'obreiro': 4, 'iburd': 5, 'auxiliar_pastor': 6
        };
        return condicaoParaEstagioMap[normalize(jovem.condicao_campus)] || 0;
      }

      // Adicionar cards (4 por página: 2x2)
      for (let i = 0; i < jovens.length; i++) {
        // Calcular posição do card (2x2 grid)
        const x = margin + (currentCol * (cardWidth + spacing));
        const y = margin + (currentRow * (cardHeight + spacing));

        // Nova página se necessário
        if (cardIndex > 0 && cardIndex % 4 === 0) {
          doc.addPage();
          currentRow = 0;
          currentCol = 0;
        }

        await adicionarCard(jovens[i], x, y);

        // Avançar para próximo card
        currentCol++;
        if (currentCol >= 2) {
          currentCol = 0;
          currentRow++;
          if (currentRow >= 2) {
            currentRow = 0;
          }
        }
        cardIndex++;
      }

      // Salvar PDF
      const nomeArquivo = `relatorio-condicao-${new Date().toISOString().split('T')[0]}.pdf`;
      doc.save(nomeArquivo);
    } catch (err) {
      console.error('Erro ao gerar PDF:', err);
      alert('Erro ao gerar PDF. Verifique o console para mais detalhes.');
    }
  }
</script>

<svelte:head>
  <title>Relatório por Condição | IntelliMen Campus</title>
</svelte:head>

<div class="min-h-screen bg-gray-50">
  <!-- Header -->
  <div class="bg-white shadow-sm border-b border-gray-200">
    <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
      <div class="flex flex-col sm:flex-row sm:items-center sm:justify-between py-4 sm:py-6 space-y-4 sm:space-y-0">
        <!-- Título -->
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
            <h1 class="text-xl sm:text-2xl font-bold text-gray-900">
              Relatório por Condição
            </h1>
            <p class="text-sm text-gray-500">
              {jovens.length} jovens encontrados
            </p>
          </div>
        </div>

        <!-- Botão Gerar PDF -->
        <Button
          on:click={gerarPDF}
          variant="primary"
          disabled={jovens.length === 0}
          class="w-full sm:w-auto"
        >
          <svg class="w-4 h-4 mr-2" fill="none" viewBox="0 0 24 24" stroke="currentColor">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 10v6m0 0l-3-3m3 3l3-3m2 8H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z" />
          </svg>
          Gerar PDF
        </Button>
      </div>
    </div>
  </div>

  <!-- Filtros -->
  <div class="bg-white border-b border-gray-200">
    <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-4">
      <div class="flex flex-col sm:flex-row sm:items-center sm:justify-between space-y-3 sm:space-y-0 mb-4">
        <div class="flex items-center space-x-2">
          <span class="text-sm font-medium text-gray-700">Filtros:</span>
        </div>
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

      <!-- Tabs de Filtros -->
      <div class="mb-4">
        <!-- Tabs Header -->
        <div class="flex flex-wrap gap-2">
          <button
            on:click={() => {
              condicaoAberta = !condicaoAberta;
              if (condicaoAberta) {
                estadoAberto = false;
                edicaoAberta = false;
              }
            }}
            class="px-6 py-3 text-sm font-semibold rounded-lg border-2 transition-all duration-200 shadow-sm
              {condicaoAberta
                ? 'bg-blue-600 text-white border-blue-600 shadow-md transform scale-105'
                : 'bg-white text-gray-700 border-gray-300 hover:bg-blue-50 hover:border-blue-400 hover:text-blue-700 hover:shadow-md'}"
          >
            <span class="flex items-center gap-2">
              <svg class="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z" />
              </svg>
              Filtro por Condição
            </span>
          </button>
          <button
            on:click={() => {
              estadoAberto = !estadoAberto;
              if (estadoAberto) {
                condicaoAberta = false;
                edicaoAberta = false;
              }
            }}
            class="px-6 py-3 text-sm font-semibold rounded-lg border-2 transition-all duration-200 shadow-sm
              {estadoAberto
                ? 'bg-green-600 text-white border-green-600 shadow-md transform scale-105'
                : 'bg-white text-gray-700 border-gray-300 hover:bg-green-50 hover:border-green-400 hover:text-green-700 hover:shadow-md'}"
          >
            <span class="flex items-center gap-2">
              <svg class="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3.055 11H5a2 2 0 012 2v1a2 2 0 002 2 2 2 0 012 2v2.945M8 3.935V5.5A2.5 2.5 0 0010.5 8h.5a2 2 0 012 2 2 2 0 104 0 2 2 0 012-2h1.064M15 20.488V18a2 2 0 012-2h3.064M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
              </svg>
              Filtro por Estado
            </span>
          </button>
          <button
            on:click={() => {
              edicaoAberta = !edicaoAberta;
              if (edicaoAberta) {
                condicaoAberta = false;
                estadoAberto = false;
              }
            }}
            class="px-6 py-3 text-sm font-semibold rounded-lg border-2 transition-all duration-200 shadow-sm
              {edicaoAberta
                ? 'bg-purple-600 text-white border-purple-600 shadow-md transform scale-105'
                : 'bg-white text-gray-700 border-gray-300 hover:bg-purple-50 hover:border-purple-400 hover:text-purple-700 hover:shadow-md'}"
          >
            <span class="flex items-center gap-2">
              <svg class="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 6.253v13m0-13C10.832 5.477 9.246 5 7.5 5S4.168 5.477 3 6.253v13C4.168 18.477 5.754 18 7.5 18s3.332.477 4.5 1.253m0-13C13.168 5.477 14.754 5 16.5 5c1.747 0 3.332.477 4.5 1.253v13C19.832 18.477 18.247 18 16.5 18c-1.746 0-3.332.477-4.5 1.253" />
              </svg>
              Filtro por Edição
            </span>
          </button>
        </div>
      </div>

      <!-- Conteúdo dos Filtros (Accordion) -->
      <div class="mt-4">
        <!-- Filtro por Condição -->
        {#if condicaoAberta}
          <div transition:slide={{ duration: 300 }}>
            <div class="flex flex-wrap gap-2">
              {#each condicoesDisponiveis as condicao}
                <button
                  on:click={() => toggleCondicao(condicao.codigo)}
                  class="px-4 py-2 text-sm font-medium rounded-lg border-2 transition-colors
                    {condicoesSelecionadas.includes(condicao.codigo)
                      ? 'bg-blue-600 text-white border-blue-600'
                      : 'bg-white text-gray-700 border-gray-300 hover:border-blue-400 hover:bg-blue-50'}"
                >
                  {condicao.nome}
                </button>
              {/each}
            </div>
          </div>
        {/if}

        <!-- Filtro por Estado -->
        {#if estadoAberto}
          <div transition:slide={{ duration: 300 }}>
            <div class="flex flex-wrap gap-2">
              {#each estadosDisponiveis as estado}
                <button
                  on:click={() => toggleEstado(estado.id)}
                  class="px-4 py-2 text-sm font-medium rounded-lg border-2 transition-colors
                    {estadosSelecionados.includes(estado.id)
                      ? 'bg-green-600 text-white border-green-600'
                      : 'bg-white text-gray-700 border-gray-300 hover:border-green-400 hover:bg-green-50'}"
                >
                  {estado.nome} ({estado.sigla})
                </button>
              {/each}
            </div>
          </div>
        {/if}

        <!-- Filtro por Edição -->
        {#if edicaoAberta}
          <div transition:slide={{ duration: 300 }}>
            <div class="flex flex-wrap gap-2">
              {#each edicoesDisponiveis as edicao}
                <button
                  on:click={() => toggleEdicao(edicao.id)}
                  class="px-4 py-2 text-sm font-medium rounded-lg border-2 transition-colors
                    {edicoesSelecionadas.includes(edicao.id)
                      ? 'bg-purple-600 text-white border-purple-600'
                      : 'bg-white text-gray-700 border-gray-300 hover:border-purple-400 hover:bg-purple-50'}"
                >
                  {edicao.nome}
                </button>
              {/each}
            </div>
          </div>
        {/if}
      </div>
    </div>
  </div>

  <!-- Content -->
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
        <p class="text-lg font-medium mb-2">Nenhum jovem encontrado</p>
        <p class="text-sm">Selecione uma ou mais condições no filtro acima para visualizar os jovens.</p>
      </div>
    {:else}
      <!-- Grid de 2 colunas -->
      <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
        {#each jovens as jovem (jovem.id)}
          <CardCondicao {jovem} />
        {/each}
      </div>
    {/if}
  </div>
</div>

