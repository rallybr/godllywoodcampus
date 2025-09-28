// Script para testar a função get_jovens_por_estado_count corrigida
// Cole este código no console do navegador

console.log('🔍 TESTE - Função get_jovens_por_estado_count CORRIGIDA');

async function testarFuncaoCorrigida() {
  try {
    console.log('=== TESTANDO FUNÇÃO CORRIGIDA ===');
    
    // Teste 1: Sem parâmetros
    console.log('Teste 1 - Sem parâmetros:');
    const { data: rpcData1, error: rpcError1 } = await supabase.rpc('get_jovens_por_estado_count');
    console.log('RPC sem parâmetros - data:', rpcData1);
    console.log('RPC sem parâmetros - error:', rpcError1);
    
    // Teste 2: Com NULL
    console.log('Teste 2 - Com NULL:');
    const { data: rpcData2, error: rpcError2 } = await supabase.rpc('get_jovens_por_estado_count', {
      edicao_id: null
    });
    console.log('RPC com NULL - data:', rpcData2);
    console.log('RPC com NULL - error:', rpcError2);
    
    // Teste 3: Com edição específica
    console.log('Teste 3 - Buscando edição ativa:');
    const { data: edicoes, error: edicoesError } = await supabase
      .from('edicoes')
      .select('id, nome')
      .eq('ativa', true)
      .limit(1);
    
    if (edicoes && edicoes.length > 0) {
      console.log('Edição ativa encontrada:', edicoes[0]);
      const { data: rpcData3, error: rpcError3 } = await supabase.rpc('get_jovens_por_estado_count', {
        edicao_id: edicoes[0].id
      });
      console.log('RPC com edição específica - data:', rpcData3);
      console.log('RPC com edição específica - error:', rpcError3);
    } else {
      console.log('Nenhuma edição ativa encontrada');
    }
    
    // Verificar se há dados
    if (rpcData1 && rpcData1.length > 0) {
      console.log('✅ FUNÇÃO FUNCIONANDO! Dados encontrados:', rpcData1.length);
      console.log('Primeiros 3 resultados:', rpcData1.slice(0, 3));
    } else {
      console.log('⚠️ Função funcionou, mas sem dados');
    }
    
  } catch (err) {
    console.error('❌ Erro ao testar função:', err);
  }
}

// Testar também dados básicos
async function testarDadosBasicos() {
  try {
    console.log('=== TESTANDO DADOS BÁSICOS ===');
    
    // Estados
    const { data: estados, error: estadosError } = await supabase
      .from('estados')
      .select('id, nome, sigla, bandeira')
      .order('nome', { ascending: true });
    
    console.log('Estados carregados:', estados?.length);
    console.log('Primeiros 3 estados:', estados?.slice(0, 3));
    
    // Jovens
    const { data: jovens, error: jovensError } = await supabase
      .from('jovens')
      .select('id, nome_completo, estado_id')
      .not('estado_id', 'is', null)
      .limit(10);
    
    console.log('Jovens carregados:', jovens?.length);
    console.log('Primeiros 3 jovens:', jovens?.slice(0, 3));
    
    // Edições
    const { data: edicoes, error: edicoesError } = await supabase
      .from('edicoes')
      .select('id, nome, ativa')
      .eq('ativa', true);
    
    console.log('Edições ativas:', edicoes?.length);
    console.log('Edições ativas:', edicoes);
    
  } catch (err) {
    console.error('❌ Erro ao testar dados básicos:', err);
  }
}

// Executar testes
testarFuncaoCorrigida();
testarDadosBasicos();
