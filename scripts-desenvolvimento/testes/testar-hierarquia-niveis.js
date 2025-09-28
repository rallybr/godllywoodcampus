// Script para testar se a hierarquia de níveis está funcionando corretamente
// Execute este código no console do navegador (F12)

console.log('=== TESTE DE HIERARQUIA DE NÍVEIS ===');

// 1. Verificar se o modal está aberto
const modal = document.querySelector('[role="dialog"]');
console.log('Modal encontrado:', modal);

if (modal) {
  // 2. Verificar campo de nível
  const campoNivel = document.querySelector('select[id="nivel"]');
  if (campoNivel) {
    console.log('Campo de nível encontrado:', campoNivel);
    console.log('Valor atual do nível:', campoNivel.value);
    
    // 3. Verificar opções disponíveis
    const opcoes = Array.from(campoNivel.options).map(opt => ({
      value: opt.value,
      text: opt.textContent
    }));
    console.log('Opções de nível disponíveis:', opcoes);
  }
  
  // 4. Verificar papéis atuais
  const papeisAtuais = document.querySelectorAll('[class*="bg-blue-100"]');
  console.log('Papéis atuais encontrados:', papeisAtuais.length);
  papeisAtuais.forEach((papel, index) => {
    console.log(`Papel ${index}:`, papel.textContent);
  });
  
  // 5. Verificar hierarquia esperada
  const hierarquiaEsperada = [
    'administrador',
    'lider_nacional_iurd',
    'lider_nacional_fju',
    'lider_estadual_iurd',
    'lider_estadual_fju',
    'lider_bloco_iurd',
    'lider_bloco_fju',
    'lider_regional_iurd',
    'lider_igreja_iurd',
    'colaborador',
    'jovem'
  ];
  
  console.log('Hierarquia esperada:', hierarquiaEsperada);
  
  // 6. Verificar se há inconsistência
  const nivelAtual = campoNivel?.value;
  const papeisTexto = Array.from(papeisAtuais).map(p => p.textContent);
  
  console.log('Nível atual:', nivelAtual);
  console.log('Papéis aplicados:', papeisTexto);
  
  // 7. Verificar correspondência
  if (nivelAtual && papeisTexto.length > 0) {
    const nivelCorrespondente = papeisTexto[0].toLowerCase().replace(/\s+/g, '_');
    console.log('Nível correspondente esperado:', nivelCorrespondente);
    console.log('Correspondência:', nivelAtual === nivelCorrespondente);
    
    // 8. Verificar se está na hierarquia
    const posicaoNivel = hierarquiaEsperada.indexOf(nivelAtual);
    const posicaoPapel = hierarquiaEsperada.indexOf(nivelCorrespondente);
    
    console.log('Posição do nível na hierarquia:', posicaoNivel);
    console.log('Posição do papel na hierarquia:', posicaoPapel);
    console.log('Hierarquia correta:', posicaoNivel === posicaoPapel);
  }
}

// 9. Verificar se há erros JavaScript
window.addEventListener('error', (e) => {
  console.error('Erro JavaScript:', e.error);
});

// 10. Verificar se há logs de debug
const originalLog = console.log;
console.log = function(...args) {
  originalLog.apply(console, args);
  if (args[0] && args[0].includes && args[0].includes('papel')) {
    console.log('Log de papel detectado:', args);
  }
};
