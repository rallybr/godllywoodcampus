#!/bin/bash

# Script para gerar ícones PWA a partir da logo do IntelliMen Campus
# Requer ImageMagick instalado: https://imagemagick.org/

echo "🎨 Gerando ícones PWA a partir da logo IntelliMen Campus..."

# Verificar se ImageMagick está instalado
if ! command -v magick &> /dev/null; then
    echo "❌ ImageMagick não encontrado. Instale em: https://imagemagick.org/"
    exit 1
fi

# Caminho da logo original
LOGO_PATH="../src/logos/logo.png"

# Verificar se a logo existe
if [ ! -f "$LOGO_PATH" ]; then
    echo "❌ Logo não encontrada em: $LOGO_PATH"
    exit 1
fi

echo "📱 Logo encontrada: $LOGO_PATH"

# Criar diretório de saída
mkdir -p ../static

# Função para gerar ícone normal
generate_icon() {
    local size=$1
    local filename=$2
    local output_path="../static/$filename"
    
    echo "📱 Gerando $filename (${size}x${size})..."
    
    magick "$LOGO_PATH" \
        -resize ${size}x${size} \
        -background transparent \
        -gravity center \
        -extent ${size}x${size} \
        "$output_path"
    
    if [ $? -eq 0 ]; then
        echo "✅ $filename criado com sucesso"
    else
        echo "❌ Erro ao criar $filename"
    fi
}

# Função para gerar ícone maskable
generate_maskable_icon() {
    local size=$1
    local filename=$2
    local output_path="../static/$filename"
    local icon_size=$((size * 80 / 100))  # 80% do tamanho total
    
    echo "🎭 Gerando $filename maskable (${size}x${size})..."
    
    magick "$LOGO_PATH" \
        -resize ${icon_size}x${icon_size} \
        -background white \
        -gravity center \
        -extent ${size}x${size} \
        "$output_path"
    
    if [ $? -eq 0 ]; then
        echo "✅ $filename maskable criado com sucesso"
    else
        echo "❌ Erro ao criar $filename maskable"
    fi
}

# Gerar ícones normais
echo "📱 Gerando ícones normais..."
generate_icon 72 "icon-72.png"
generate_icon 96 "icon-96.png"
generate_icon 128 "icon-128.png"
generate_icon 144 "icon-144.png"
generate_icon 152 "icon-152.png"
generate_icon 192 "icon-192.png"
generate_icon 384 "icon-384.png"
generate_icon 512 "icon-512.png"

# Gerar ícones maskable
echo "🎭 Gerando ícones maskable..."
generate_maskable_icon 192 "icon-192-maskable.png"
generate_maskable_icon 512 "icon-512-maskable.png"

echo "🎉 Ícones PWA gerados com sucesso!"
echo "📁 Arquivos criados em: ../static/"
echo "📱 Agora você pode instalar o PWA com a logo real do IntelliMen Campus!"
