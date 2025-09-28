// Script para testar se o problema de clique foi resolvido
// Execute este código no console do navegador (F12)

console.log('=== TESTE DE CLIQUE CORRIGIDO ===');

// 1. Verificar se há elementos sobrepostos
const cards = document.querySelectorAll('[class*="card"]');
console.log('Cards encontrados:', cards.length);

// 2. Verificar z-index dos botões
const botoes = document.querySelectorAll('button');
console.log('Botões encontrados:', botoes.length);

botoes.forEach((botao, index) => {
  const zIndex = window.getComputedStyle(botao).zIndex;
  const pointerEvents = window.getComputedStyle(botao).pointerEvents;
  console.log(`Botão ${index}: z-index=${zIndex}, pointer-events=${pointerEvents}`);
});

// 3. Verificar campo de busca
const inputBusca = document.querySelector('input[type="text"]');
if (inputBusca) {
  const zIndex = window.getComputedStyle(inputBusca).zIndex;
  const pointerEvents = window.getComputedStyle(inputBusca).pointerEvents;
  console.log('Campo de busca: z-index=' + zIndex + ', pointer-events=' + pointerEvents);
}

// 4. Testar clique nos botões
const botoesEditar = Array.from(botoes).filter(btn => 
  btn.textContent.includes('Editar Usuário')
);
console.log('Botões Editar Usuário encontrados:', botoesEditar.length);

botoesEditar.forEach((botao, index) => {
  console.log(`Testando clique no botão ${index}...`);
  botao.click();
});

// 5. Verificar se há elementos com position absolute sobrepostos
const elementosAbsolutos = document.querySelectorAll('[style*="position: absolute"]');
console.log('Elementos com position absolute:', elementosAbsolutos.length);

// 6. Verificar se há elementos com z-index alto
const elementosComZIndex = Array.from(document.querySelectorAll('*')).filter(el => {
  const zIndex = window.getComputedStyle(el).zIndex;
  return zIndex !== 'auto' && parseInt(zIndex) > 10;
});
console.log('Elementos com z-index alto:', elementosComZIndex.length);
