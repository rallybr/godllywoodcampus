// Script para gerar ícones PWA a partir da logo do IntelliMen Campus
// Este script deve ser executado com Node.js

const fs = require('fs');
const path = require('path');

// Tamanhos de ícones necessários para PWA
const ICON_SIZES = [
  { size: 72, name: 'icon-72.png' },
  { size: 96, name: 'icon-96.png' },
  { size: 128, name: 'icon-128.png' },
  { size: 144, name: 'icon-144.png' },
  { size: 152, name: 'icon-152.png' },
  { size: 192, name: 'icon-192.png' },
  { size: 384, name: 'icon-384.png' },
  { size: 512, name: 'icon-512.png' }
];

// Tamanhos para ícones maskable
const MASKABLE_SIZES = [
  { size: 192, name: 'icon-192-maskable.png' },
  { size: 512, name: 'icon-512-maskable.png' }
];

console.log('🎨 Gerando ícones PWA para IntelliMen Campus...');

// Função para criar ícone simples (placeholder)
function createIcon(size, filename) {
  // Criar um ícone simples baseado na logo
  // Em produção, você usaria uma biblioteca como sharp ou jimp
  const canvas = `
    <svg width="${size}" height="${size}" viewBox="0 0 ${size} ${size}" xmlns="http://www.w3.org/2000/svg">
      <defs>
        <linearGradient id="grad" x1="0%" y1="0%" x2="100%" y2="100%">
          <stop offset="0%" style="stop-color:#3b82f6;stop-opacity:1" />
          <stop offset="100%" style="stop-color:#1d4ed8;stop-opacity:1" />
        </linearGradient>
      </defs>
      <rect width="${size}" height="${size}" rx="${size * 0.2}" fill="url(#grad)"/>
      <text x="50%" y="50%" text-anchor="middle" dy="0.35em" 
            font-family="Arial, sans-serif" font-size="${size * 0.3}" 
            font-weight="bold" fill="white">C</text>
    </svg>
  `;
  
  return canvas;
}

// Função para criar ícone maskable
function createMaskableIcon(size, filename) {
  // Ícone maskable com padding para adaptação
  const padding = size * 0.1;
  const iconSize = size - (padding * 2);
  
  const canvas = `
    <svg width="${size}" height="${size}" viewBox="0 0 ${size} ${size}" xmlns="http://www.w3.org/2000/svg">
      <defs>
        <linearGradient id="grad-mask" x1="0%" y1="0%" x2="100%" y2="100%">
          <stop offset="0%" style="stop-color:#3b82f6;stop-opacity:1" />
          <stop offset="100%" style="stop-color:#1d4ed8;stop-opacity:1" />
        </linearGradient>
      </defs>
      <rect width="${size}" height="${size}" fill="url(#grad-mask)"/>
      <rect x="${padding}" y="${padding}" width="${iconSize}" height="${iconSize}" 
            rx="${iconSize * 0.2}" fill="white" opacity="0.9"/>
      <text x="50%" y="50%" text-anchor="middle" dy="0.35em" 
            font-family="Arial, sans-serif" font-size="${iconSize * 0.4}" 
            font-weight="bold" fill="#3b82f6">C</text>
    </svg>
  `;
  
  return canvas;
}

// Criar diretório de ícones se não existir
const iconsDir = path.join(__dirname, '../static');
if (!fs.existsSync(iconsDir)) {
  fs.mkdirSync(iconsDir, { recursive: true });
}

// Gerar ícones normais
console.log('📱 Gerando ícones normais...');
ICON_SIZES.forEach(({ size, name }) => {
  const iconSvg = createIcon(size, name);
  const filePath = path.join(iconsDir, name.replace('.png', '.svg'));
  
  fs.writeFileSync(filePath, iconSvg);
  console.log(`✅ Criado: ${name.replace('.png', '.svg')} (${size}x${size})`);
});

// Gerar ícones maskable
console.log('🎭 Gerando ícones maskable...');
MASKABLE_SIZES.forEach(({ size, name }) => {
  const iconSvg = createMaskableIcon(size, name);
  const filePath = path.join(iconsDir, name.replace('.png', '.svg'));
  
  fs.writeFileSync(filePath, iconSvg);
  console.log(`✅ Criado: ${name.replace('.png', '.svg')} (${size}x${size})`);
});

// Criar favicon.ico
console.log('🌐 Gerando favicon...');
const faviconSvg = createIcon(32, 'favicon.svg');
fs.writeFileSync(path.join(iconsDir, 'favicon.svg'), faviconSvg);
console.log('✅ Criado: favicon.svg');

console.log('🎉 Ícones PWA gerados com sucesso!');
console.log('📝 Nota: Para produção, converta os arquivos SVG para PNG usando uma ferramenta como Inkscape ou online converter.');
console.log('🔗 Recomendado: https://realfavicongenerator.net/ para gerar todos os formatos necessários.');
