# 📋 Ficha do Jovem - IntelliMen Campus

## 🎯 Visão Geral

A **Ficha do Jovem** é um componente visual moderno e bem formatado que exibe todas as informações de um jovem cadastrado no sistema IntelliMen Campus. Foi criada baseada no layout de exemplo fornecido e integrada com a estrutura completa do banco de dados.

## ✨ Características

### 🎨 Design
- **Layout responsivo** com 3 colunas em telas grandes
- **Gradientes coloridos** para diferentes seções
- **Ícones SVG** para melhor identificação visual
- **Cards organizados** por categoria de informação
- **Status visual** com cores diferenciadas
- **Foto do jovem** com fallback para inicial

### 📊 Seções da Ficha

#### 1. **Header Principal**
- Nome completo do jovem
- Localização (Estado • Igreja)
- Data de cadastro
- Status de aprovação com cores
- Média das avaliações (se disponível)

#### 2. **Dados Pessoais**
- Foto do jovem
- WhatsApp formatado
- Idade calculada
- Data de nascimento
- Estado civil
- Status de relacionamento
- Filhos

#### 3. **Informações Profissionais**
- Status de trabalho
- Profissão/ocupação
- Escolaridade
- Formação
- Dívidas e valores

#### 4. **Informações Espirituais**
- Tempo de igreja
- Batismo nas águas e data
- Batismo como ES e data
- Condição atual
- Tempo na condição
- Responsabilidades na igreja

#### 5. **Experiência na Igreja**
- Obra no altar
- Histórico de obreiro/colaborador
- Afastamentos e motivos
- Família na igreja
- Desejo pelo altar

#### 6. **IntelliMen**
- Formação IntelliMen
- Desafios em andamento
- Edição participada

#### 7. **Redes Sociais**
- Instagram, Facebook, TikTok
- Observações sobre redes

#### 8. **Observações e Testemunho**
- Observações gerais
- Testemunho pessoal

#### 9. **Avaliações** (opcional)
- Lista de avaliações recebidas
- Notas e comentários
- Data das avaliações
- Média geral

## 🚀 Como Usar

### 1. **Componente Básico**
```svelte
<script>
  import FichaJovem from '$lib/components/jovens/FichaJovem.svelte';
  
  let jovem = {
    // dados do jovem...
  };
</script>

<FichaJovem {jovem} />
```

### 2. **Com Opções**
```svelte
<FichaJovem 
  {jovem} 
  showAvaliacoes={true} 
  compact={false} 
/>
```

### 3. **Página Dedicada**
Acesse: `/jovens/[id]/ficha`

### 4. **Exemplo de Demonstração**
Acesse: `/test-ficha`

## 📁 Arquivos Criados

### Componentes
- `src/lib/components/jovens/FichaJovem.svelte` - Componente principal da ficha

### Páginas
- `src/routes/jovens/[id]/ficha/+page.svelte` - Página da ficha do jovem
- `src/routes/test-ficha/+page.svelte` - Página de demonstração

### Modificações
- `src/lib/components/jovens/JovemProfile.svelte` - Adicionado botão "Ver Ficha"

## 🔧 Propriedades do Componente

| Propriedade | Tipo | Padrão | Descrição |
|-------------|------|--------|-----------|
| `jovem` | `object` | - | **Obrigatório** - Dados do jovem |
| `showAvaliacoes` | `boolean` | `true` | Exibir seção de avaliações |
| `compact` | `boolean` | `false` | Modo compacto (oculta avaliações) |

## 🎨 Personalização

### Cores dos Status
- **Aprovado**: Verde (`bg-green-100 text-green-800`)
- **Pré-aprovado**: Amarelo (`bg-yellow-100 text-yellow-800`)
- **Reprovado**: Vermelho (`bg-red-100 text-red-800`)
- **Pendente**: Cinza (`bg-gray-100 text-gray-800`)

### Seções com Gradientes
- **Espirituais**: Roxo para Índigo
- **Profissionais**: Verde
- **Experiência**: Laranja para Vermelho
- **IntelliMen**: Azul para Ciano
- **Redes Sociais**: Rosa para Roxo
- **Observações**: Amarelo para Laranja

## 📱 Responsividade

- **Desktop**: 3 colunas (dados pessoais, espirituais, IntelliMen/redes)
- **Tablet**: 2 colunas
- **Mobile**: 1 coluna

## 🖨️ Impressão

A ficha é otimizada para impressão com:
- Estilos específicos para `@media print`
- Remoção de elementos desnecessários
- Layout otimizado para papel A4

## 🔗 Integração

### Banco de Dados
A ficha utiliza todos os campos da tabela `jovens` conforme documentado em:
- `ESTRUTURA_TABELAS_BANCO.md`
- `DOCUMENTACAO_FUNCOES_BANCO.md`
- `POLITICAS_RLS_COMPLETAS.md`

### Stores
- `loadJovemById()` - Carregar dados do jovem
- `loadAvaliacoesByJovem()` - Carregar avaliações

### Navegação
- Botão "Ver Ficha" na página de perfil do jovem
- Rota: `/jovens/[id]/ficha`

## 🎯 Próximos Passos

1. **Testes**: Implementar testes unitários
2. **Exportação**: Adicionar exportação para PDF
3. **Compartilhamento**: Funcionalidade de compartilhamento
4. **Histórico**: Versões anteriores da ficha
5. **Templates**: Diferentes layouts de ficha

## 📝 Notas Técnicas

- **TypeScript**: Totalmente tipado
- **Svelte 5**: Compatível com a versão mais recente
- **Tailwind CSS**: Estilização com utility classes
- **date-fns**: Formatação de datas
- **Responsivo**: Mobile-first design
- **Acessível**: Semântica HTML adequada

---

**Desenvolvido para o Sistema IntelliMen Campus** 🚀
