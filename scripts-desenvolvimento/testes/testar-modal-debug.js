// Script para testar o modal no console do navegador
// Execute este código no console do navegador (F12)

console.log('=== TESTE DO MODAL ===');

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

// 5. Verificar variáveis do Svelte (se acessíveis)
console.log('Verificando variáveis do Svelte...');
console.log('showEditarModal:', window.showEditarModal);
console.log('usuarioSelecionado:', window.usuarioSelecionado);
