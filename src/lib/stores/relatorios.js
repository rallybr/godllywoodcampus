import { writable } from 'svelte/store';
import { supabase } from '$lib/utils/supabase';

// Stores para relatórios
export const relatorios = writable([]);
export const loading = writable(false);
export const error = writable(null);

// Função para gerar relatório de jovens
export async function gerarRelatorioJovens(filtros = {}) {
  loading.set(true);
  error.set(null);
  
  try {
    let query = supabase
      .from('jovens')
      .select(`
        *,
        estado:estados(nome, sigla),
        bloco:blocos(nome),
        regiao:regioes(nome),
        igreja:igrejas(nome),
        edicao:edicoes(nome, numero)
      `);
    
    // Aplicar filtros
    if (filtros.estado_id) {
      query = query.eq('estado_id', filtros.estado_id);
    }
    if (filtros.bloco_id) {
      query = query.eq('bloco_id', filtros.bloco_id);
    }
    if (filtros.regiao_id) {
      query = query.eq('regiao_id', filtros.regiao_id);
    }
    if (filtros.igreja_id) {
      query = query.eq('igreja_id', filtros.igreja_id);
    }
    if (filtros.edicao_id) {
      query = query.eq('edicao_id', filtros.edicao_id);
    }
    if (filtros.aprovado !== undefined) {
      query = query.eq('aprovado', filtros.aprovado);
    }
    if (filtros.sexo) {
      query = query.eq('sexo', filtros.sexo);
    }
    if (filtros.idade_min) {
      query = query.gte('idade', filtros.idade_min);
    }
    if (filtros.idade_max) {
      query = query.lte('idade', filtros.idade_max);
    }
    if (filtros.data_inicio) {
      query = query.gte('data_cadastro', filtros.data_inicio);
    }
    if (filtros.data_fim) {
      query = query.lte('data_cadastro', filtros.data_fim);
    }
    
    // Ordenar
    query = query.order('nome_completo');
    
    const { data, error: fetchError } = await query;
    
    if (fetchError) throw fetchError;
    
    return data || [];
  } catch (err) {
    error.set(err.message);
    console.error('Error generating relatório jovens:', err);
    return [];
  } finally {
    loading.set(false);
  }
}

// Função para gerar relatório de avaliações
export async function gerarRelatorioAvaliacoes(filtros = {}) {
  loading.set(true);
  error.set(null);
  
  try {
    let query = supabase
      .from('avaliacoes')
      .select(`
        *,
        jovem_id,
        user_id
      `);
    
    // Aplicar filtros simples
    if (filtros.avaliador_id) {
      query = query.eq('user_id', filtros.avaliador_id);
    }
    if (filtros.nota_min) {
      query = query.gte('nota', filtros.nota_min);
    }
    if (filtros.nota_max) {
      query = query.lte('nota', filtros.nota_max);
    }
    if (filtros.data_inicio) {
      query = query.gte('criado_em', filtros.data_inicio);
    }
    if (filtros.data_fim) {
      query = query.lte('criado_em', filtros.data_fim);
    }
    
    // Ordenar
    query = query.order('criado_em', { ascending: false });
    
    const { data, error: fetchError } = await query;
    
    if (fetchError) throw fetchError;
    
    // Processar dados para adicionar informações básicas
    const dadosProcessados = (data || []).map(avaliacao => ({
      ...avaliacao,
      jovem: { nome_completo: 'Jovem ID: ' + avaliacao.jovem_id },
      avaliador: { nome: 'Avaliador ID: ' + avaliacao.user_id, email: '' }
    }));
    
    return dadosProcessados;
  } catch (err) {
    error.set(err.message);
    console.error('Error generating relatório avaliações:', err);
    return [];
  } finally {
    loading.set(false);
  }
}

// Função para gerar estatísticas gerais
export async function gerarEstatisticasGerais(filtros = {}) {
  loading.set(true);
  error.set(null);
  
  try {
    // Contar jovens por status
    const { data: jovensStatus, error: jovensError } = await supabase
      .from('jovens')
      .select('aprovado')
      .match(filtros);
    
    if (jovensError) throw jovensError;
    
    // Contar avaliações
    const { data: avaliacoes, error: avaliacoesError } = await supabase
      .from('avaliacoes')
      .select('nota, espirito, caractere, disposicao');
    
    if (avaliacoesError) throw avaliacoesError;
    
    // Calcular estatísticas
    const stats = {
      totalJovens: jovensStatus.length,
      aprovados: jovensStatus.filter(j => j.aprovado === 'aprovado').length,
      preAprovados: jovensStatus.filter(j => j.aprovado === 'pre_aprovado').length,
      pendentes: jovensStatus.filter(j => j.aprovado === null || j.aprovado === 'null').length,
      totalAvaliacoes: avaliacoes.length,
      mediaGeral: 0,
      mediaEspirito: 0,
      mediaCaractere: 0,
      mediaDisposicao: 0
    };
    
    if (avaliacoes.length > 0) {
      // Calcular médias
      const somaNotas = avaliacoes.reduce((acc, av) => acc + (av.nota || 0), 0);
      stats.mediaGeral = somaNotas / avaliacoes.length;
      
      // Calcular médias por categoria (convertendo enums para números)
      const enumToNumber = {
        'ruim': 1,
        'ser_observar': 2,
        'bom': 3,
        'excelente': 4,
        'muito_disposto': 4,
        'normal': 3,
        'pacato': 2,
        'desanimado': 1
      };
      
      const somaEspirito = avaliacoes.reduce((acc, av) => acc + (enumToNumber[av.espirito] || 0), 0);
      const somaCaractere = avaliacoes.reduce((acc, av) => acc + (enumToNumber[av.caractere] || 0), 0);
      const somaDisposicao = avaliacoes.reduce((acc, av) => acc + (enumToNumber[av.disposicao] || 0), 0);
      
      stats.mediaEspirito = somaEspirito / avaliacoes.length;
      stats.mediaCaractere = somaCaractere / avaliacoes.length;
      stats.mediaDisposicao = somaDisposicao / avaliacoes.length;
    }
    
    return stats;
  } catch (err) {
    error.set(err.message);
    console.error('Error generating estatísticas gerais:', err);
    return null;
  } finally {
    loading.set(false);
  }
}

// Função para gerar relatório por localização
export async function gerarRelatorioPorLocalizacao(filtros = {}) {
  loading.set(true);
  error.set(null);
  
  try {
    let query = supabase
      .from('jovens')
      .select(`
        estado_id,
        bloco_id,
        regiao_id,
        igreja_id,
        aprovado,
        idade,
        sexo
      `);
    
    // Aplicar filtros
    if (filtros.estado_id) {
      query = query.eq('estado_id', filtros.estado_id);
    }
    if (filtros.bloco_id) {
      query = query.eq('bloco_id', filtros.bloco_id);
    }
    if (filtros.regiao_id) {
      query = query.eq('regiao_id', filtros.regiao_id);
    }
    if (filtros.igreja_id) {
      query = query.eq('igreja_id', filtros.igreja_id);
    }
    
    const { data, error: fetchError } = await query;
    
    if (fetchError) throw fetchError;
    
    // Agrupar por localização
    const agrupado = {};
    
    data.forEach(jovem => {
      const chave = `${jovem.estado_id || 'N/A'}-${jovem.bloco_id || 'N/A'}-${jovem.regiao_id || 'N/A'}-${jovem.igreja_id || 'N/A'}`;
      
      if (!agrupado[chave]) {
        agrupado[chave] = {
          estado: jovem.estado_id || 'N/A',
          bloco: jovem.bloco_id || 'N/A',
          regiao: jovem.regiao_id || 'N/A',
          igreja: jovem.igreja_id || 'N/A',
          total: 0,
          aprovados: 0,
          preAprovados: 0,
          pendentes: 0,
          masculino: 0,
          feminino: 0,
          idadeMedia: 0,
          idades: []
        };
      }
      
      agrupado[chave].total++;
      agrupado[chave].idades.push(jovem.idade);
      
      if (jovem.aprovado === true) agrupado[chave].aprovados++;
      else if (jovem.aprovado === 'pre_aprovado') agrupado[chave].preAprovados++;
      else agrupado[chave].pendentes++;
      
      if (jovem.sexo === 'masculino') agrupado[chave].masculino++;
      else if (jovem.sexo === 'feminino') agrupado[chave].feminino++;
    });
    
    // Calcular idade média
    Object.values(agrupado).forEach(local => {
      if (local.idades.length > 0) {
        local.idadeMedia = local.idades.reduce((acc, idade) => acc + idade, 0) / local.idades.length;
      }
    });
    
    return Object.values(agrupado);
  } catch (err) {
    error.set(err.message);
    console.error('Error generating relatório por localização:', err);
    return [];
  } finally {
    loading.set(false);
  }
}

// Função para exportar dados para CSV
export function exportarParaCSV(dados, nomeArquivo = 'relatorio.csv') {
  if (!dados || dados.length === 0) {
    throw new Error('Nenhum dado para exportar');
  }
  
  // Função para limpar e formatar dados
  function limparDados(objeto) {
    const limpo = {};
    for (const [chave, valor] of Object.entries(objeto)) {
      if (valor === null || valor === undefined) {
        limpo[chave] = '';
      } else if (typeof valor === 'object') {
        // Para objetos aninhados, extrair valores relevantes
        if (valor.nome) {
          limpo[chave] = valor.nome;
        } else if (valor.nome_completo) {
          limpo[chave] = valor.nome_completo;
        } else if (valor.email) {
          limpo[chave] = valor.email;
        } else {
          limpo[chave] = JSON.stringify(valor);
        }
      } else {
        limpo[chave] = valor;
      }
    }
    return limpo;
  }
  
  // Limpar dados
  const dadosLimpos = dados.map(limparDados);
  
  // Obter cabeçalhos
  const cabecalhos = Object.keys(dadosLimpos[0]);
  
  // Mapear cabeçalhos para nomes mais legíveis
  const mapeamentoCabecalhos = {
    'nome_completo': 'Nome Completo',
    'idade': 'Idade',
    'sexo': 'Sexo',
    'estado_civil': 'Estado Civil',
    'whatsapp': 'WhatsApp',
    'data_nasc': 'Data de Nascimento',
    'data_cadastro': 'Data de Cadastro',
    'aprovado': 'Status de Aprovação',
    'estado': 'Estado',
    'bloco': 'Bloco',
    'regiao': 'Região',
    'igreja': 'Igreja',
    'edicao': 'Edição',
    'nota': 'Nota',
    'espirito': 'Espírito',
    'caractere': 'Caráter',
    'disposicao': 'Disposição',
    'criado_em': 'Data de Criação',
    'avaliador': 'Avaliador',
    'jovem': 'Jovem'
  };
  
  const cabecalhosFormatados = cabecalhos.map(cabecalho => 
    mapeamentoCabecalhos[cabecalho] || cabecalho
  );
  
  // Criar CSV com BOM para UTF-8
  let csv = '\uFEFF' + cabecalhosFormatados.join(',') + '\n';
  
  dadosLimpos.forEach(linha => {
    const valores = cabecalhos.map(cabecalho => {
      const valor = linha[cabecalho];
      if (typeof valor === 'string' && valor.includes(',')) {
        return `"${valor.replace(/"/g, '""')}"`;
      }
      return String(valor || '');
    });
    csv += valores.join(',') + '\n';
  });
  
  // Download
  const blob = new Blob([csv], { type: 'text/csv;charset=utf-8;' });
  const link = document.createElement('a');
  const url = URL.createObjectURL(blob);
  link.setAttribute('href', url);
  link.setAttribute('download', nomeArquivo);
  link.style.visibility = 'hidden';
  document.body.appendChild(link);
  link.click();
  document.body.removeChild(link);
  URL.revokeObjectURL(url);
}

// Função para exportar dados para Excel (usando SheetJS)
export async function exportarParaExcel(dados, nomeArquivo = 'relatorio.xlsx') {
  if (!dados || dados.length === 0) {
    throw new Error('Nenhum dado para exportar');
  }
  
  // Importar SheetJS dinamicamente
  const XLSX = await import('xlsx');
  
  // Função para limpar e formatar dados
  function limparDados(objeto) {
    const limpo = {};
    for (const [chave, valor] of Object.entries(objeto)) {
      if (valor === null || valor === undefined) {
        limpo[chave] = '';
      } else if (typeof valor === 'object') {
        // Para objetos aninhados, extrair valores relevantes
        if (valor.nome) {
          limpo[chave] = valor.nome;
        } else if (valor.nome_completo) {
          limpo[chave] = valor.nome_completo;
        } else if (valor.email) {
          limpo[chave] = valor.email;
        } else if (valor.sigla) {
          limpo[chave] = valor.sigla;
        } else {
          limpo[chave] = JSON.stringify(valor);
        }
      } else {
        limpo[chave] = valor;
      }
    }
    return limpo;
  }
  
  // Limpar dados
  const dadosLimpos = dados.map(limparDados);
  
  // Criar workbook
  const wb = XLSX.utils.book_new();
  
  // Converter dados para worksheet
  const ws = XLSX.utils.json_to_sheet(dadosLimpos);
  
  // Configurar largura das colunas
  const colWidths = [];
  const cabecalhos = Object.keys(dadosLimpos[0]);
  
  cabecalhos.forEach((cabecalho, index) => {
    const maxLength = Math.max(
      cabecalho.length,
      ...dadosLimpos.map(linha => String(linha[cabecalho] || '').length)
    );
    colWidths[index] = { wch: Math.min(maxLength + 2, 50) };
  });
  
  ws['!cols'] = colWidths;
  
  // Adicionar worksheet ao workbook
  XLSX.utils.book_append_sheet(wb, ws, 'Relatório');
  
  // Adicionar informações do relatório
  const infoWs = XLSX.utils.aoa_to_sheet([
    ['Relatório Gerado em:', new Date().toLocaleString('pt-BR')],
    ['Total de Registros:', dados.length],
    ['Gerado por:', 'Sistema IntelliMen Campus']
  ]);
  
  XLSX.utils.book_append_sheet(wb, infoWs, 'Informações');
  
  // Download
  XLSX.writeFile(wb, nomeArquivo);
}

// Função para gerar PDF (usando jsPDF)
export async function exportarParaPDF(dados, titulo = 'Relatório', nomeArquivo = 'relatorio.pdf') {
  if (!dados || dados.length === 0) {
    throw new Error('Nenhum dado para exportar');
  }
  
  // Importar jsPDF dinamicamente
  const { jsPDF } = await import('jspdf');
  const { autoTable } = await import('jspdf-autotable');
  
  // Função para limpar e formatar dados
  function limparDados(objeto) {
    const limpo = {};
    for (const [chave, valor] of Object.entries(objeto)) {
      if (valor === null || valor === undefined) {
        limpo[chave] = '';
      } else if (typeof valor === 'object') {
        // Para objetos aninhados, extrair valores relevantes
        if (valor.nome) {
          limpo[chave] = valor.nome;
        } else if (valor.nome_completo) {
          limpo[chave] = valor.nome_completo;
        } else if (valor.email) {
          limpo[chave] = valor.email;
        } else if (valor.sigla) {
          limpo[chave] = valor.sigla;
        } else {
          limpo[chave] = JSON.stringify(valor);
        }
      } else {
        limpo[chave] = valor;
      }
    }
    return limpo;
  }
  
  // Limpar dados
  const dadosLimpos = dados.map(limparDados);
  
  // Criar PDF
  const doc = new jsPDF('l', 'mm', 'a4'); // Orientação landscape para mais colunas
  
  // Adicionar cabeçalho
  doc.setFillColor(59, 130, 246);
  doc.rect(0, 0, 297, 30, 'F');
  
  // Título
  doc.setTextColor(255, 255, 255);
  doc.setFontSize(20);
  doc.setFont('helvetica', 'bold');
  doc.text(titulo, 14, 20);
  
  // Informações do relatório
  doc.setFontSize(10);
  doc.setFont('helvetica', 'normal');
  doc.text(`Gerado em: ${new Date().toLocaleString('pt-BR')}`, 14, 35);
  doc.text(`Total de registros: ${dados.length}`, 14, 42);
  doc.text(`Sistema IntelliMen Campus`, 200, 35);
  
  // Resetar cor do texto
  doc.setTextColor(0, 0, 0);
  
  // Mapear cabeçalhos para nomes mais legíveis
  const mapeamentoCabecalhos = {
    'nome_completo': 'Nome Completo',
    'idade': 'Idade',
    'sexo': 'Sexo',
    'estado_civil': 'Estado Civil',
    'whatsapp': 'WhatsApp',
    'data_nasc': 'Data de Nascimento',
    'data_cadastro': 'Data de Cadastro',
    'aprovado': 'Status',
    'estado': 'Estado',
    'bloco': 'Bloco',
    'regiao': 'Região',
    'igreja': 'Igreja',
    'edicao': 'Edição',
    'nota': 'Nota',
    'espirito': 'Espírito',
    'caractere': 'Caráter',
    'disposicao': 'Disposição',
    'criado_em': 'Data',
    'avaliador': 'Avaliador',
    'jovem': 'Jovem'
  };
  
  // Preparar dados para tabela
  const cabecalhos = Object.keys(dadosLimpos[0]);
  const cabecalhosFormatados = cabecalhos.map(cabecalho => 
    mapeamentoCabecalhos[cabecalho] || cabecalho
  );
  
  const linhas = dadosLimpos.map(linha => 
    cabecalhos.map(cabecalho => {
      const valor = linha[cabecalho];
      if (typeof valor === 'string' && valor.length > 30) {
        return valor.substring(0, 30) + '...';
      }
      return String(valor || '');
    })
  );
  
  // Adicionar tabela
  autoTable(doc, {
    head: [cabecalhosFormatados],
    body: linhas,
    startY: 50,
    styles: { 
      fontSize: 8,
      cellPadding: 2
    },
    headStyles: { 
      fillColor: [66, 139, 202],
      textColor: [255, 255, 255],
      fontStyle: 'bold'
    },
    alternateRowStyles: {
      fillColor: [248, 250, 252]
    },
    columnStyles: {
      // Ajustar largura de colunas específicas
      0: { cellWidth: 40 }, // Nome
      1: { cellWidth: 15 }, // Idade
      2: { cellWidth: 20 }, // Sexo
      3: { cellWidth: 25 }, // Estado Civil
      4: { cellWidth: 30 }, // WhatsApp
      5: { cellWidth: 25 }, // Data Nascimento
      6: { cellWidth: 25 }, // Data Cadastro
      7: { cellWidth: 20 }, // Status
      8: { cellWidth: 25 }, // Estado
      9: { cellWidth: 25 }, // Bloco
      10: { cellWidth: 25 }, // Região
      11: { cellWidth: 30 }, // Igreja
      12: { cellWidth: 20 }, // Edição
      13: { cellWidth: 15 }, // Nota
      14: { cellWidth: 20 }, // Espírito
      15: { cellWidth: 20 }, // Caráter
      16: { cellWidth: 20 }, // Disposição
      17: { cellWidth: 25 }, // Data
      18: { cellWidth: 30 }, // Avaliador
      19: { cellWidth: 30 }  // Jovem
    },
    margin: { top: 50, right: 14, bottom: 20, left: 14 },
    pageBreak: 'auto',
    showHead: 'everyPage'
  });
  
  // Adicionar rodapé
  const pageCount = doc.internal.getNumberOfPages();
  for (let i = 1; i <= pageCount; i++) {
    doc.setPage(i);
    doc.setFontSize(8);
    doc.setTextColor(128, 128, 128);
    doc.text(`Página ${i} de ${pageCount}`, 14, doc.internal.pageSize.height - 10);
    doc.text('Sistema IntelliMen Campus', doc.internal.pageSize.width - 60, doc.internal.pageSize.height - 10);
  }
  
  // Download
  doc.save(nomeArquivo);
}
