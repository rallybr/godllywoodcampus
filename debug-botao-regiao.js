// Script de debug para o botão de adicionar região

// 1. Verificar se a função está sendo chamada
console.log('🔍 Verificando função criarRegiao...');

// 2. Adicionar debug à função original
async function criarRegiao() {
  console.log('🚀 Função criarRegiao() chamada!');
  console.log('📊 Estado atual:');
  console.log('- blocoId:', blocoId);
  console.log('- novaRegiao:', novaRegiao);
  console.log('- novaRegiao.nome:', novaRegiao.nome);
  
  // Verificar se blocoId está definido
  if (!blocoId) {
    console.error('❌ blocoId não está definido');
    alert('Selecione um bloco primeiro');
    return;
  }
  
  // Verificar se nome está definido
  if (!novaRegiao.nome || novaRegiao.nome.trim() === '') {
    console.error('❌ Nome da região não está definido');
    alert('Digite o nome da região');
    return;
  }
  
  console.log('✅ Validações passaram, tentando inserir...');
  
  try {
    const { data, error } = await supabase.from('regioes').insert([{ nome: novaRegiao.nome, bloco_id: blocoId }]);
    
    if (error) {
      console.error('❌ Erro na inserção:', error);
      alert(`Erro: ${error.message}`);
      return;
    }
    
    console.log('✅ Região inserida com sucesso:', data);
    novaRegiao = { nome: '' };
    await carregarListas();
    
  } catch (err) {
    console.error('❌ Erro inesperado:', err);
    alert(`Erro inesperado: ${err.message}`);
  }
}

// 3. Verificar se o botão está funcionando
console.log('🔍 Verificando botão...');

// 4. Testar se o evento está sendo disparado
document.addEventListener('DOMContentLoaded', function() {
  const botao = document.querySelector('button[on\\:click]');
  if (botao) {
    console.log('✅ Botão encontrado:', botao);
    botao.addEventListener('click', function(e) {
      console.log('🖱️ Clique no botão detectado!');
    });
  } else {
    console.log('❌ Botão não encontrado');
  }
});
