# Script PowerShell para gerar ícones PWA a partir da logo do IntelliMen Campus
# Requer ImageMagick instalado: https://imagemagick.org/

Write-Host "Gerando icones PWA a partir da logo IntelliMen Campus..." -ForegroundColor Blue

# Verificar se ImageMagick está instalado
try {
    $magickVersion = magick -version 2>$null
    if ($LASTEXITCODE -ne 0) {
        throw "ImageMagick não encontrado"
    }
} catch {
    Write-Host "ImageMagick não encontrado. Instale em: https://imagemagick.org/" -ForegroundColor Red
    exit 1
}

# Caminho da logo original
$LOGO_PATH = "../src/logos/logo.png"

# Verificar se a logo existe
if (-not (Test-Path $LOGO_PATH)) {
    Write-Host "Logo não encontrada em: $LOGO_PATH" -ForegroundColor Red
    exit 1
}

Write-Host "Logo encontrada: $LOGO_PATH" -ForegroundColor Green

# Criar diretório de saída
$outputDir = "../static"
if (-not (Test-Path $outputDir)) {
    New-Item -ItemType Directory -Path $outputDir -Force | Out-Null
}

# Função para gerar ícone normal
function Generate-Icon {
    param(
        [int]$size,
        [string]$filename
    )
    
    $outputPath = "../static/$filename"
    
    Write-Host "Gerando $filename (${size}x${size})..." -ForegroundColor Yellow
    
    try {
        magick $LOGO_PATH -resize "${size}x${size}" -background transparent -gravity center -extent "${size}x${size}" $outputPath
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host "$filename criado com sucesso" -ForegroundColor Green
        } else {
            Write-Host "Erro ao criar $filename" -ForegroundColor Red
        }
    } catch {
        Write-Host "Erro ao criar $filename : $_" -ForegroundColor Red
    }
}

# Função para gerar ícone maskable
function Generate-MaskableIcon {
    param(
        [int]$size,
        [string]$filename
    )
    
    $outputPath = "../static/$filename"
    $iconSize = [math]::Floor($size * 0.8)  # 80% do tamanho total
    
    Write-Host "Gerando $filename maskable (${size}x${size})..." -ForegroundColor Yellow
    
    try {
        magick $LOGO_PATH -resize "${iconSize}x${iconSize}" -background white -gravity center -extent "${size}x${size}" $outputPath
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host "$filename maskable criado com sucesso" -ForegroundColor Green
        } else {
            Write-Host "Erro ao criar $filename maskable" -ForegroundColor Red
        }
    } catch {
        Write-Host "Erro ao criar $filename maskable : $_" -ForegroundColor Red
    }
}

# Gerar ícones normais
Write-Host "Gerando icones normais..." -ForegroundColor Blue
Generate-Icon 72 "icon-72.png"
Generate-Icon 96 "icon-96.png"
Generate-Icon 128 "icon-128.png"
Generate-Icon 144 "icon-144.png"
Generate-Icon 152 "icon-152.png"
Generate-Icon 192 "icon-192.png"
Generate-Icon 384 "icon-384.png"
Generate-Icon 512 "icon-512.png"

# Gerar ícones maskable
Write-Host "Gerando icones maskable..." -ForegroundColor Blue
Generate-MaskableIcon 192 "icon-192-maskable.png"
Generate-MaskableIcon 512 "icon-512-maskable.png"

Write-Host "Icones PWA gerados com sucesso!" -ForegroundColor Green
Write-Host "Arquivos criados em: ../static/" -ForegroundColor Cyan
Write-Host "Agora você pode instalar o PWA com a logo real do IntelliMen Campus!" -ForegroundColor Magenta