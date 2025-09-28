// Script para testar se a sincronização de nível está funcionando
// Execute este código no console do navegador (F12)

console.log('=== TESTE DE SINCRONIZAÇÃO DE NÍVEL ===');

// 1. Verificar se o modal está aberto
const modal = document.querySelector('[role="dialog"]');
console.log('Modal encontrado:', modal);

if (modal) {
  // 2. Verificar campo de nível
  const campoNivel = document.querySelector('select[id="nivel"]');
  if (campoNivel) {
    console.log('Campo de nível encontrado:', campoNivel);
    console.log('Valor atual do nível:', campoNivel.value);
    console.log('Opções disponíveis:', Array.from(campoNivel.options).map(opt => opt.value));
  }
  
  // 3. Verificar papéis atuais
  const papeisAtuais = document.querySelectorAll('[class*="bg-blue-100"]');
  console.log('Papéis atuais encontrados:', papeisAtuais.length);
  papeisAtuais.forEach((papel, index) => {
    console.log(`Papel ${index}:`, papel.textContent);
  });
  
  // 4. Verificar se há inconsistência
  const nivelAtual = campoNivel?.value;
  const papeisTexto = Array.from(papeisAtuais).map(p => p.textContent);
  
  console.log('Nível atual:', nivelAtual);
  console.log('Papéis aplicados:', papeisTexto);
  
  // 5. Verificar se há correspondência
  if (nivelAtual && papeisTexto.length > 0) {
    const nivelCorrespondente = papeisTexto[0].toLowerCase().replace(/\s+/g, '_');
    console.log('Nível correspondente esperado:', nivelCorrespondente);
    console.log('Correspondência:', nivelAtual === nivelCorrespondente);
  }
}

// 6. Verificar se há erros JavaScript
window.addEventListener('error', (e) => {
  console.error('Erro JavaScript:', e.error);
});

// 7. Verificar se há logs de debug
const originalLog = console.log;
console.log = function(...args) {
  originalLog.apply(console, args);
  if (args[0] && args[0].includes && args[0].includes('papel')) {
    console.log('Log de papel detectado:', args);
  }
};
