// Script para testar o modal no console do navegador
// considerando que as políticas RLS foram desabilitadas

console.log('=== TESTE DO MODAL COM RLS DESABILITADO ===');

// 1. Verificar se o modal está sendo renderizado
const modal = document.querySelector('[role="dialog"]');
console.log('Modal encontrado:', modal);

// 2. Verificar se há erros JavaScript
window.addEventListener('error', (e) => {
  console.error('Erro JavaScript:', e.error);
});

// 3. Verificar se o botão existe
const botoes = document.querySelectorAll('button');
console.log('Total de botões encontrados:', botoes.length);

const botaoEditar = Array.from(botoes).find(btn => 
  btn.textContent.includes('Editar Usuário')
);
console.log('Botão Editar Usuário encontrado:', botaoEditar);

// 4. Testar clique no botão
if (botaoEditar) {
  console.log('Testando clique no botão...');
  botaoEditar.click();
} else {
  console.log('Botão não encontrado');
}

// 5. Verificar se há dados de usuários carregados
const cards = document.querySelectorAll('[class*="card"]');
console.log('Cards de usuários encontrados:', cards.length);

// 6. Verificar se há fotos nos cards
const imagens = document.querySelectorAll('img[alt*="Usuário"]');
console.log('Imagens de usuários encontradas:', imagens.length);

// 7. Verificar se há erros de rede
window.addEventListener('unhandledrejection', (e) => {
  console.error('Erro de rede:', e.reason);
});

// 8. Verificar se há erros de console
const originalError = console.error;
console.error = function(...args) {
  originalError.apply(console, args);
  console.log('Erro capturado:', args);
};
