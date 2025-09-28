// Script de debug para testar carregamento de regiões

// 1. Testar consulta direta no Supabase
async function testarConsultaRegioes() {
  console.log('🧪 Testando consulta direta de regiões...');
  
  try {
    // Consulta direta - todas as regiões
    const { data: todasRegioes, error: errorTodas } = await supabase
      .from('regioes')
      .select('*')
      .order('nome');
    
    console.log('📊 Todas as regiões:', todasRegioes?.length || 0);
    if (errorTodas) {
      console.error('❌ Erro ao carregar todas as regiões:', errorTodas);
    }
    
    // Consulta filtrada - regiões do bloco específico
    const blocoId = 'c546d361-8ad2-4eaa-b2bd-f2e18e5af12d';
    const { data: regioesBloco, error: errorBloco } = await supabase
      .from('regioes')
      .select('*')
      .eq('bloco_id', blocoId)
      .order('nome');
    
    console.log('📊 Regiões do bloco:', regioesBloco?.length || 0);
    console.log('📊 Dados das regiões do bloco:', regioesBloco);
    
    if (errorBloco) {
      console.error('❌ Erro ao carregar regiões do bloco:', errorBloco);
    }
    
    // Verificar se há regiões "Planalto"
    const regioesPlanalto = regioesBloco?.filter(r => r.nome.includes('Planalto')) || [];
    console.log('📊 Regiões "Planalto" encontradas:', regioesPlanalto.length);
    console.log('📊 Dados das regiões "Planalto":', regioesPlanalto);
    
  } catch (err) {
    console.error('❌ Erro inesperado:', err);
  }
}

// 2. Testar se o problema é com o carregamento inicial
async function testarCarregamentoInicial() {
  console.log('🧪 Testando carregamento inicial...');
  
  try {
    // Simular o carregamento inicial
    const { data, error } = await supabase
      .from('regioes')
      .select('*')
      .order('nome');
    
    if (error) {
      console.error('❌ Erro no carregamento inicial:', error);
      return;
    }
    
    console.log('📊 Regiões carregadas:', data?.length || 0);
    
    // Filtrar por bloco específico
    const blocoId = 'c546d361-8ad2-4eaa-b2bd-f2e18e5af12d';
    const regioesFiltradas = data?.filter(r => r.bloco_id === blocoId) || [];
    
    console.log('📊 Regiões filtradas para o bloco:', regioesFiltradas.length);
    console.log('📊 Dados filtrados:', regioesFiltradas);
    
  } catch (err) {
    console.error('❌ Erro inesperado:', err);
  }
}

// 3. Verificar estado atual da interface
function verificarEstadoInterface() {
  console.log('🔍 Estado atual da interface:');
  console.log('- regioes.length:', regioes.length);
  console.log('- blocoId:', blocoId);
  console.log('- regioesDoBloco():', regioesDoBloco());
  console.log('- regioesCache[blocoId]:', regioesCache[blocoId]);
}

// Executar todos os testes
console.log('🚀 Iniciando diagnóstico completo...');
testarConsultaRegioes();
testarCarregamentoInicial();
verificarEstadoInterface();
