// Script completo para testar o card JOVENS POR ESTADO
// Cole este código no console do navegador

console.log('🔍 TESTE COMPLETO - Card JOVENS POR ESTADO');

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

// 3. Verificar se estadosStats existe
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
      .select('id, estado_id, usuario_id')
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
    const { data: rpcData, error: rpcError } = await supabase.rpc('get_jovens_por_estado_count', {
      edicao_id: null
    });
    
    console.log('RPC data:', rpcData);
    console.log('RPC error:', rpcError);
    
  } catch (err) {
    console.error('Erro na RPC:', err);
  }
}

// Executar todos os testes
testarEstados();
testarJovens();
testarRPC();
