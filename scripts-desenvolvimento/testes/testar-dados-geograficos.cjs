const { createClient } = require('@supabase/supabase-js');

const supabase = createClient(
  'http://10.144.58.15:8000', 
  'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6IjEwLjE0NC41OC4xNSIsInJvbGUiOiJhbm9uIiwiaWF0IjoxNzM0NzI5MjAwLCJleHAiOjIwNTAzMDUyMDB9.8Q7Q7Q7Q7Q7Q7Q7Q7Q7Q7Q7Q7Q7Q7Q7Q7Q7Q7Q7Q'
);

async function verificarDados() {
  console.log('🔍 Verificando dados geográficos...');
  
  try {
    // 1. Verificar se as tabelas existem e têm dados
    console.log('\n=== VERIFICANDO TABELAS ===');
    
    const { data: estados, error: estadosError } = await supabase.from('estados').select('*');
    if (estadosError) console.error('Erro estados:', estadosError);
    else console.log('Estados:', estados?.length || 0, 'registros');
    
    const { data: blocos, error: blocosError } = await supabase.from('blocos').select('*');
    if (blocosError) console.error('Erro blocos:', blocosError);
    else console.log('Blocos:', blocos?.length || 0, 'registros');
    
    const { data: regioes, error: regioesError } = await supabase.from('regioes').select('*');
    if (regioesError) console.error('Erro regiões:', regioesError);
    else console.log('Regiões:', regioes?.length || 0, 'registros');
    
    const { data: igrejas, error: igrejasError } = await supabase.from('igrejas').select('*');
    if (igrejasError) console.error('Erro igrejas:', igrejasError);
    else console.log('Igrejas:', igrejas?.length || 0, 'registros');
    
    // 2. Verificar jovens com dados geográficos
    console.log('\n=== VERIFICANDO JOVENS ===');
    const { data: jovens, error: jovensError } = await supabase
      .from('jovens')
      .select('id, nome_completo, estado_id, bloco_id, regiao_id, igreja_id')
      .limit(5);
      
    if (jovensError) {
      console.error('Erro jovens:', jovensError);
    } else {
      console.log('Jovens encontrados:', jovens?.length || 0);
      if (jovens) {
        jovens.forEach(jovem => {
          console.log(`- ${jovem.nome_completo}: estado=${jovem.estado_id}, bloco=${jovem.bloco_id}, regiao=${jovem.regiao_id}, igreja=${jovem.igreja_id}`);
        });
      }
    }
    
    // 3. Verificar um jovem específico com relacionamentos
    if (jovens && jovens.length > 0) {
      const jovemId = jovens[0].id;
      console.log(`\n=== TESTANDO FUNÇÃO get_jovem_completo ===`);
      console.log(`Testando para jovem ${jovemId}...`);
      
      const { data: jovemCompleto, error: jovemError } = await supabase
        .rpc('get_jovem_completo', { p_jovem_id: jovemId });
        
      if (jovemError) {
        console.error('Erro na função:', jovemError);
      } else {
        console.log('Dados retornados:');
        console.log('- Estado:', jovemCompleto?.estado);
        console.log('- Bloco:', jovemCompleto?.bloco);
        console.log('- Região:', jovemCompleto?.regiao);
        console.log('- Igreja:', jovemCompleto?.igreja);
      }
    }
    
    // 4. Verificar se há dados nas tabelas relacionadas
    console.log('\n=== VERIFICANDO DADOS ESPECÍFICOS ===');
    if (blocos && blocos.length > 0) {
      console.log('Primeiro bloco:', blocos[0]);
    }
    if (regioes && regioes.length > 0) {
      console.log('Primeira região:', regioes[0]);
    }
    if (igrejas && igrejas.length > 0) {
      console.log('Primeira igreja:', igrejas[0]);
    }
    
  } catch (error) {
    console.error('Erro geral:', error);
  }
}

verificarDados();
