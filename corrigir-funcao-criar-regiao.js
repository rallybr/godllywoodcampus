// Versão melhorada da função criarRegiao() com debug e tratamento de erros

async function criarRegiao() {
  // Debug: Verificar estado antes da inserção
  console.log('🔍 Debug criarRegiao():');
  console.log('- blocoId:', blocoId);
  console.log('- novaRegiao:', novaRegiao);
  console.log('- novaRegiao.nome:', novaRegiao.nome);
  console.log('- novaRegiao.nome.length:', novaRegiao.nome?.length);
  
  // Validação mais robusta
  if (!blocoId) {
    console.error('❌ blocoId não definido');
    alert('Selecione um bloco primeiro');
    return;
  }
  
  if (!novaRegiao.nome || novaRegiao.nome.trim() === '') {
    console.error('❌ Nome da região vazio');
    alert('Digite o nome da região');
    return;
  }
  
  // Limpar espaços em branco
  const nomeLimpo = novaRegiao.nome.trim();
  
  try {
    console.log('🚀 Tentando inserir região:', { nome: nomeLimpo, bloco_id: blocoId });
    
    const { data, error } = await supabase
      .from('regioes')
      .insert([{ nome: nomeLimpo, bloco_id: blocoId }])
      .select();
    
    if (error) {
      console.error('❌ Erro na inserção:', error);
      alert(`Erro ao inserir região: ${error.message}`);
      return;
    }
    
    console.log('✅ Região inserida com sucesso:', data);
    
    // Limpar campo
    novaRegiao = { nome: '' };
    
    // Recarregar dados de forma mais eficiente
    await recarregarRegioesDoBloco(blocoId);
    
  } catch (err) {
    console.error('❌ Erro inesperado:', err);
    alert(`Erro inesperado: ${err.message}`);
  }
}

// Função auxiliar para recarregar apenas as regiões do bloco
async function recarregarRegioesDoBloco(blocoId) {
  try {
    console.log('🔄 Recarregando regiões do bloco:', blocoId);
    
    const { data, error } = await supabase
      .from('regioes')
      .select('*')
      .eq('bloco_id', blocoId)
      .order('nome');
    
    if (error) {
      console.error('❌ Erro ao recarregar regiões:', error);
      return;
    }
    
    const normalizadas = (data || []).map(r => ({ 
      ...r, 
      id: String(r.id), 
      bloco_id: String(r.bloco_id) 
    }));
    
    // Atualizar cache
    regioesCache[blocoId] = normalizadas;
    
    // Atualizar lista global de regiões
    const outrasRegioes = regioes.filter(r => String(r.bloco_id) !== String(blocoId));
    regioes = [...outrasRegioes, ...normalizadas];
    
    console.log('✅ Regiões recarregadas:', normalizadas.length);
    
  } catch (err) {
    console.error('❌ Erro ao recarregar regiões:', err);
  }
}

// Função para verificar se há problemas de permissão
async function verificarPermissoesRegioes() {
  try {
    console.log('🔍 Verificando permissões para regiões...');
    
    const { data, error } = await supabase
      .from('regioes')
      .select('count')
      .limit(1);
    
    if (error) {
      console.error('❌ Erro de permissão:', error);
      return false;
    }
    
    console.log('✅ Permissões OK');
    return true;
    
  } catch (err) {
    console.error('❌ Erro ao verificar permissões:', err);
    return false;
  }
}

// Função para testar inserção manual
async function testarInsercaoRegiao(nomeTeste = 'Região Teste') {
  try {
    console.log('🧪 Testando inserção manual...');
    
    const { data, error } = await supabase
      .from('regioes')
      .insert([{ nome: nomeTeste, bloco_id: blocoId }])
      .select();
    
    if (error) {
      console.error('❌ Teste falhou:', error);
      return false;
    }
    
    console.log('✅ Teste bem-sucedido:', data);
    
    // Remover o registro de teste
    if (data && data[0]) {
      await supabase.from('regioes').delete().eq('id', data[0].id);
      console.log('🧹 Registro de teste removido');
    }
    
    return true;
    
  } catch (err) {
    console.error('❌ Erro no teste:', err);
    return false;
  }
}
