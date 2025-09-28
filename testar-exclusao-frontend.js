// Script para testar exclusão de regiões no frontend

// Função para testar exclusão de uma região específica
async function testarExclusaoRegiao(regiaoId) {
  console.log('🧪 Testando exclusão da região:', regiaoId);
  
  try {
    // Testar se consegue fazer SELECT primeiro
    const { data: regiao, error: selectError } = await supabase
      .from('regioes')
      .select('*')
      .eq('id', regiaoId)
      .single();
    
    if (selectError) {
      console.error('❌ Erro ao buscar região:', selectError);
      return;
    }
    
    console.log('📊 Região encontrada:', regiao);
    
    // Testar DELETE
    const { data, error } = await supabase
      .from('regioes')
      .delete()
      .eq('id', regiaoId)
      .select();
    
    if (error) {
      console.error('❌ Erro na exclusão:', error);
      console.error('❌ Código do erro:', error.code);
      console.error('❌ Mensagem:', error.message);
      console.error('❌ Detalhes:', error.details);
      return;
    }
    
    console.log('✅ Exclusão bem-sucedida:', data);
    
  } catch (err) {
    console.error('❌ Erro inesperado:', err);
  }
}

// Função para listar todas as regiões "Planalto" e seus IDs
async function listarRegioesPlanalto() {
  console.log('🔍 Listando regiões "Planalto"...');
  
  try {
    const { data, error } = await supabase
      .from('regioes')
      .select('*')
      .eq('nome', 'Planalto')
      .eq('bloco_id', 'c546d361-8ad2-4eaa-b2bd-f2e18e5af12d')
      .order('id');
    
    if (error) {
      console.error('❌ Erro ao listar regiões:', error);
      return;
    }
    
    console.log('📊 Regiões "Planalto" encontradas:', data.length);
    console.log('📊 Dados:', data);
    
    // Retornar IDs para teste
    const ids = data.map(r => r.id);
    console.log('📊 IDs para teste:', ids);
    
    return ids;
    
  } catch (err) {
    console.error('❌ Erro inesperado:', err);
  }
}

// Executar diagnóstico
console.log('🚀 Iniciando diagnóstico de exclusão...');
listarRegioesPlanalto();
