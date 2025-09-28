// Script para testar loadEstadosStats no console do navegador
// Cole este código no console do navegador

console.log('🔍 TESTE - Verificando dados do colaborador...');

// 1. Verificar userProfile
console.log('UserProfile:', window.$userProfile || 'Não encontrado');

// 2. Testar consulta direta de jovens
async function testarJovensColaborador() {
  try {
    const { data: jovens, error } = await supabase
      .from('jovens')
      .select('id, nome_completo, estado_id, usuario_id')
      .eq('usuario_id', 'e745720c-e9f7-4562-978b-72ba32387420'); // Substitua pelo ID real
    
    console.log('🔍 Jovens do colaborador:', jovens);
    console.log('🔍 Total de jovens:', jovens?.length);
    
    if (jovens && jovens.length > 0) {
      // Agrupar por estado
      const porEstado = {};
      jovens.forEach(jovem => {
        if (!porEstado[jovem.estado_id]) {
          porEstado[jovem.estado_id] = 0;
        }
        porEstado[jovem.estado_id]++;
      });
      
      console.log('🔍 Jovens por estado:', porEstado);
    }
    
  } catch (err) {
    console.error('❌ Erro ao buscar jovens:', err);
  }
}

// 3. Testar consulta de estados
async function testarEstados() {
  try {
    const { data: estados, error } = await supabase
      .from('estados')
      .select('id, nome, sigla, bandeira')
      .order('nome', { ascending: true });
    
    console.log('🔍 Estados carregados:', estados?.length);
    console.log('🔍 Primeiros 3 estados:', estados?.slice(0, 3));
    
  } catch (err) {
    console.error('❌ Erro ao buscar estados:', err);
  }
}

// Executar testes
testarJovensColaborador();
testarEstados();
