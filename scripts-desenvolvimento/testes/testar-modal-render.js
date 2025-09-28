// Script para testar o modal no frontend
// Execute este código no console do navegador

// 1. Verificar se o modal está sendo renderizado
console.log('Verificando modal...');
const modal = document.querySelector('[role="dialog"]');
console.log('Modal encontrado:', modal);

// 2. Verificar se há erros JavaScript
console.log('Verificando erros...');
window.addEventListener('error', (e) => {
  console.error('Erro JavaScript:', e.error);
});

// 3. Testar clique no botão
const botao = document.querySelector('button[onclick*="abrirEditarModal"]');
if (botao) {
  console.log('Botão encontrado:', botao);
  botao.click();
} else {
  console.log('Botão não encontrado');
}