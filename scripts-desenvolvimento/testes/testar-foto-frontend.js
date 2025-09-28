// Script para testar a exibição da foto no frontend
// Execute este código no console do navegador (F12)

console.log('=== TESTE DA FOTO NO FRONTEND ===');

// 1. Verificar se há dados de usuários carregados
const cards = document.querySelectorAll('[class*="card"]');
console.log('Cards de usuários encontrados:', cards.length);

// 2. Verificar se há imagens nos cards
const imagens = document.querySelectorAll('img[alt*="Usuário"]');
console.log('Imagens de usuários encontradas:', imagens.length);

// 3. Verificar se há avatares padrão
const avatares = document.querySelectorAll('[class*="bg-gradient-to-br"]');
console.log('Avatares padrão encontrados:', avatares.length);

// 4. Verificar se há dados de usuários no JavaScript
console.log('Verificando dados de usuários...');
if (window.usuarios) {
  console.log('Dados de usuários:', window.usuarios);
} else {
  console.log('Dados de usuários não encontrados');
}

// 5. Verificar se há erros de carregamento de imagem
const imagensComErro = document.querySelectorAll('img[onerror]');
console.log('Imagens com erro:', imagensComErro.length);

// 6. Verificar se há URLs de foto válidas
const imagensComSrc = document.querySelectorAll('img[src]');
console.log('Imagens com src:', imagensComSrc.length);
imagensComSrc.forEach((img, index) => {
  console.log(`Imagem ${index}:`, img.src);
});

// 7. Verificar se há erros de rede
window.addEventListener('error', (e) => {
  if (e.target.tagName === 'IMG') {
    console.error('Erro ao carregar imagem:', e.target.src);
  }
});

// 8. Verificar se há erros de console
const originalError = console.error;
console.error = function(...args) {
  originalError.apply(console, args);
  console.log('Erro capturado:', args);
};
