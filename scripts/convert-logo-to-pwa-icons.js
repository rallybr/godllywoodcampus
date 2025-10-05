// Script para converter a logo do IntelliMen Campus em ícones PWA
// Este script usa a logo original em /src/logos/logo.png

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

console.log('🎨 Convertendo logo IntelliMen Campus para ícones PWA...');

// Função para criar ícone PNG a partir da logo
function createIconFromLogo(size, filename, isMaskable = false) {
  // Em um ambiente real, você usaria uma biblioteca como sharp ou jimp
  // Para este exemplo, vou criar um placeholder que você pode substituir
  
  const logoPath = path.join(__dirname, '../src/logos/logo.png');
  const outputPath = path.join(__dirname, '../static', filename);
  
  console.log(`📱 Criando ícone ${filename} (${size}x${size}) a partir de: ${logoPath}`);
  
  // Verificar se a logo existe
  if (!fs.existsSync(logoPath)) {
    console.error(`❌ Logo não encontrada em: ${logoPath}`);
    return false;
  }
  
  // Em produção, você usaria:
  // const sharp = require('sharp');
  // await sharp(logoPath)
  //   .resize(size, size)
  //   .png()
  //   .toFile(outputPath);
  
  // Por enquanto, vou criar um arquivo de instruções
  const instructions = `
# Instruções para gerar ícones PWA

## Logo Original: ${logoPath}
## Tamanho: ${size}x${size}
## Arquivo: ${filename}
## Maskable: ${isMaskable}

## Comandos para gerar (usando ImageMagick):

### Ícone normal:
magick "${logoPath}" -resize ${size}x${size} -background transparent -gravity center -extent ${size}x${size} "${outputPath}"

### Ícone maskable (com padding):
magick "${logoPath}" -resize ${Math.floor(size * 0.8)}x${Math.floor(size * 0.8)} -background white -gravity center -extent ${size}x${size} "${outputPath}"

## Comandos para gerar (usando Sharp - Node.js):
const sharp = require('sharp');
await sharp('${logoPath}')
  .resize(${size}, ${size})
  .png()
  .toFile('${outputPath}');
`;

  fs.writeFileSync(outputPath.replace('.png', '.txt'), instructions);
  console.log(`✅ Instruções criadas para: ${filename}`);
  
  return true;
}

// Criar diretório de ícones se não existir
const iconsDir = path.join(__dirname, '../static');
if (!fs.existsSync(iconsDir)) {
  fs.mkdirSync(iconsDir, { recursive: true });
}

// Gerar ícones normais
console.log('📱 Gerando ícones normais...');
ICON_SIZES.forEach(({ size, name }) => {
  createIconFromLogo(size, name, false);
});

// Gerar ícones maskable
console.log('🎭 Gerando ícones maskable...');
MASKABLE_SIZES.forEach(({ size, name }) => {
  createIconFromLogo(size, name, true);
});

console.log('🎉 Instruções para gerar ícones PWA criadas!');
console.log('📝 Execute os comandos ImageMagick ou use Sharp para gerar os ícones PNG.');
console.log('🔗 Recomendado: https://realfavicongenerator.net/ para gerar todos os formatos necessários.');
