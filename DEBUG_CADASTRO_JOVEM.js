// Script de debug para verificar o problema do menu "Cadastro" não aparecer para jovens

// 1. Verificar se o usuário é jovem
console.log('=== DEBUG CADASTRO JOVEM ===');
console.log('UserProfile:', $userProfile);
console.log('Nível do usuário:', $userProfile?.nivel);
console.log('É jovem?', getUserLevelName($userProfile) === 'Jovem');

// 2. Verificar se o jovem já se cadastrou
console.log('Jovem já cadastrado?', $jovemJaCadastrado);

// 3. Verificar se a função de verificação está sendo chamada
console.log('Chamando verificarCadastroJovem...');
verificarCadastroJovem().then(resultado => {
  console.log('Resultado da verificação:', resultado);
  console.log('Jovem já cadastrado após verificação:', $jovemJaCadastrado);
});

// 4. Verificar se o menu está sendo filtrado corretamente
console.log('Menu filtrado para jovem:', filteredMenuItems);
console.log('Itens do menu:', filteredMenuItems.map(item => item.name));
