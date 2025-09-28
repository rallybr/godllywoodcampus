// Script final para testar o card JOVENS POR ESTADO
// Baseado na estrutura real das tabelas
// Cole este código no console do navegador

console.log('🔍 TESTE FINAL - Card JOVENS POR ESTADO');

// 1. Verificar dados básicos
console.log('=== DADOS BÁSICOS ===');
console.log('UserProfile:', window.$userProfile);
console.log('getUserLevelName result:', getUserLevelName(window.$userProfile));

// 2. Verificar condição do card
console.log('=== CONDIÇÃO DO CARD ===');
const userLevel = getUserLevelName(window.$userProfile);
const isNotJovem = userLevel !== 'Jovem';
const hasSpecialLevel = userLevel.includes('Nacional') || 
                       userLevel.includes('Estadual') || 
                       userLevel.includes('Bloco') || 
                       userLevel.includes('Regional') || 
                       userLevel.includes('Igreja') || 
                       userLevel === 'Administrador' || 
                       userLevel === 'Instrutor';
const shouldShow = isNotJovem || hasSpecialLevel;

console.log('userLevel:', userLevel);
console.log('isNotJovem:', isNotJovem);
console.log('hasSpecialLevel:', hasSpecialLevel);
console.log('shouldShow:', shouldShow);

// 3. Verificar estadosStats
console.log('=== ESTADOS STATS ===');
console.log('estadosStats:', window.estadosStats || 'Não encontrado');
console.log('estadosStats length:', window.estadosStats?.length || 0);

// 4. Testar consulta de estados
async function testarEstados() {
  try {
    console.log('=== TESTANDO CONSULTA DE ESTADOS ===');
    const { data: estados, error: estadosError } = await supabase
      .from('estados')
      .select('id, nome, sigla, bandeira')
      .order('nome', { ascending: true });
    
    console.log('Estados carregados:', estados?.length);
    console.log('Primeiros 3 estados:', estados?.slice(0, 3));
    
    if (estadosError) {
      console.error('Erro ao carregar estados:', estadosError);
    }
    
  } catch (err) {
    console.error('Erro na consulta de estados:', err);
  }
}

// 5. Testar consulta de jovens
async function testarJovens() {
  try {
    console.log('=== TESTANDO CONSULTA DE JOVENS ===');
    let query = supabase
      .from('jovens')
      .select('id, estado_id, usuario_id, edicao_id')
      .not('estado_id', 'is', null);
    
    // Aplicar filtro se for colaborador
    if (window.$userProfile?.nivel === 'colaborador' && window.$userProfile?.id) {
      console.log('Aplicando filtro para colaborador:', window.$userProfile.id);
      query = query.eq('usuario_id', window.$userProfile.id);
    }
    
    const { data: jovens, error: jovensError } = await query;
    
    console.log('Jovens encontrados:', jovens?.length);
    console.log('Primeiros 3 jovens:', jovens?.slice(0, 3));
    
    if (jovens && jovens.length > 0) {
      const contagemPorEstado = {};
      jovens.forEach(jovem => {
        contagemPorEstado[jovem.estado_id] = (contagemPorEstado[jovem.estado_id] || 0) + 1;
      });
      console.log('Contagem por estado:', contagemPorEstado);
      
      // Mostrar estados com jovens
      const estadosComJovens = Object.keys(contagemPorEstado);
      console.log('Estados com jovens:', estadosComJovens);
    }
    
    if (jovensError) {
      console.error('Erro ao carregar jovens:', jovensError);
    }
    
  } catch (err) {
    console.error('Erro na consulta de jovens:', err);
  }
}

// 6. Testar função RPC
async function testarRPC() {
  try {
    console.log('=== TESTANDO RPC get_jovens_por_estado_count ===');
    
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
    
    // Teste 3: Com edição específica (se houver)
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
    
  } catch (err) {
    console.error('Erro na RPC:', err);
  }
}

// 7. Simular o processo completo do card
async function simularProcessoCompleto() {
  try {
    console.log('=== SIMULANDO PROCESSO COMPLETO ===');
    
    // 1. Carregar estados
    const { data: estados, error: estadosError } = await supabase
      .from('estados')
      .select('id, nome, sigla, bandeira')
      .order('nome', { ascending: true });
    
    if (estadosError) throw estadosError;
    console.log('Estados carregados:', estados?.length);
    
    // 2. Carregar jovens (com filtro se necessário)
    let query = supabase
      .from('jovens')
      .select('id, estado_id, usuario_id')
      .not('estado_id', 'is', null);
    
    if (window.$userProfile?.nivel === 'colaborador' && window.$userProfile?.id) {
      query = query.eq('usuario_id', window.$userProfile.id);
    }
    
    const { data: jovens, error: jovensError } = await query;
    if (jovensError) throw jovensError;
    console.log('Jovens carregados:', jovens?.length);
    
    // 3. Contar por estado
    const contagemPorEstado = {};
    jovens.forEach(jovem => {
      contagemPorEstado[jovem.estado_id] = (contagemPorEstado[jovem.estado_id] || 0) + 1;
    });
    console.log('Contagem por estado:', contagemPorEstado);
    
    // 4. Processar resultado final
    const estadosStats = estados.map(estado => ({
      id: estado.id,
      nome: estado.nome,
      sigla: estado.sigla,
      bandeira: estado.bandeira,
      totalJovens: contagemPorEstado[estado.id] || 0
    })).sort((a, b) => b.totalJovens - a.totalJovens);
    
    console.log('EstadosStats final:', estadosStats);
    console.log('Estados com jovens:', estadosStats.filter(e => e.totalJovens > 0));
    
  } catch (err) {
    console.error('Erro no processo completo:', err);
  }
}

// Executar todos os testes
testarEstados();
testarJovens();
testarRPC();
simularProcessoCompleto();
