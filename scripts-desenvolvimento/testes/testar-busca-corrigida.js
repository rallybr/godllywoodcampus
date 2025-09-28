// Script para testar se a correção da busca funcionou
// Execute este código no console do navegador (F12)

console.log('=== TESTE DE BUSCA CORRIGIDA ===');

// 1. Verificar se há campo de busca
const inputBusca = document.querySelector('input[type="text"]');
console.log('Campo de busca encontrado:', inputBusca);

if (inputBusca) {
  // 2. Testar digitação no campo de busca
  console.log('Testando digitação no campo de busca...');
  inputBusca.focus();
  inputBusca.value = 'teste';
  inputBusca.dispatchEvent(new Event('input', { bubbles: true }));
  
  // 3. Verificar se aparecem resultados
  setTimeout(() => {
    const resultados = document.querySelectorAll('[class*="border-b border-gray-100"]');
    console.log('Resultados de busca encontrados:', resultados.length);
    
    // 4. Verificar z-index dos resultados
    resultados.forEach((resultado, index) => {
      const zIndex = window.getComputedStyle(resultado).zIndex;
      const pointerEvents = window.getComputedStyle(resultado).pointerEvents;
      console.log(`Resultado ${index}: z-index=${zIndex}, pointer-events=${pointerEvents}`);
    });
    
    // 5. Testar clique nos resultados
    resultados.forEach((resultado, index) => {
      console.log(`Testando clique no resultado ${index}...`);
      resultado.click();
    });
  }, 1000);
}

// 6. Verificar se há elementos sobrepostos
const elementosComZIndex = Array.from(document.querySelectorAll('*')).filter(el => {
  const zIndex = window.getComputedStyle(el).zIndex;
  return zIndex !== 'auto' && parseInt(zIndex) > 10;
});
console.log('Elementos com z-index alto:', elementosComZIndex.length);

// 7. Verificar se há elementos com position absolute sobrepostos
const elementosAbsolutos = document.querySelectorAll('[style*="position: absolute"]');
console.log('Elementos com position absolute:', elementosAbsolutos.length);
