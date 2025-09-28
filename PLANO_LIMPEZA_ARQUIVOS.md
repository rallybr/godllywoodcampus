# Plano de Limpeza de Arquivos - Campus IntelliMen

## 📊 Análise dos Arquivos

### **Arquivos Identificados:**
- **SQL Scripts**: ~200 arquivos
- **JavaScript**: ~66 arquivos
- **Arquivos de Configuração**: ~10 arquivos
- **Documentação**: ~15 arquivos

## 🗂️ Categorização para Limpeza

### **1. ARQUIVOS PARA MANTER (Essenciais)**

#### **Configuração do Projeto**
- `package.json`
- `package-lock.json`
- `svelte.config.js`
- `tailwind.config.js`
- `postcss.config.js`
- `eslint.config.js`
- `tsconfig.json`
- `env.example`

#### **Código Fonte (src/)**
- `src/` - **MANTER TUDO** (código principal do sistema)

#### **Documentação Importante**
- `README.md`
- `RELATORIO_COMPATIBILIDADE_SISTEMA.md`
- `GUIA_ESTRUTURA_SISTEMA_COMPLETO.md`

### **2. ARQUIVOS PARA ARQUIVAR (Scripts de Desenvolvimento)**

#### **Scripts de Correção (Arquivo em pasta separada)**
```
scripts-desenvolvimento/
├── correcoes/
│   ├── corrigir-*.sql
│   ├── fix-*.sql
│   └── ajuste-*.sql
├── testes/
│   ├── testar-*.sql
│   ├── testar-*.js
│   └── teste-*.sql
├── diagnosticos/
│   ├── diagnosticar-*.sql
│   ├── verificar-*.sql
│   └── analisar-*.sql
└── migracoes/
    ├── migrar-*.sql
    └── popular-*.sql
```

### **3. ARQUIVOS PARA DELETAR (Desnecessários)**

#### **Scripts de Teste Temporários**
- `testar-*.sql` (todos os arquivos de teste)
- `teste-*.sql` (todos os arquivos de teste)
- `testar-*.js` (scripts de teste JavaScript)

#### **Scripts de Correção Específicos (já aplicados)**
- `corrigir-*.sql` (correções já aplicadas)
- `fix-*.sql` (correções já aplicadas)
- `ajuste-*.sql` (ajustes já aplicados)

#### **Scripts de Diagnóstico (já executados)**
- `diagnosticar-*.sql`
- `verificar-*.sql`
- `analisar-*.sql`

#### **Scripts de Migração (já executados)**
- `migrar-*.sql`
- `popular-*.sql`

## 🚀 Plano de Execução

### **Fase 1: Criar Estrutura de Arquivo**
1. Criar pasta `scripts-desenvolvimento/`
2. Criar subpastas organizadas
3. Mover arquivos importantes para arquivo

### **Fase 2: Deletar Arquivos Desnecessários**
1. Deletar scripts de teste
2. Deletar correções já aplicadas
3. Deletar diagnósticos já executados

### **Fase 3: Organizar Documentação**
1. Manter documentação essencial
2. Mover documentação de desenvolvimento para pasta separada

## 📋 Lista de Arquivos para Deletar

### **Scripts SQL para Deletar (~150 arquivos)**
- Todos os `testar-*.sql`
- Todos os `teste-*.sql`
- Todos os `corrigir-*.sql`
- Todos os `fix-*.sql`
- Todos os `diagnosticar-*.sql`
- Todos os `verificar-*.sql`
- Todos os `analisar-*.sql`
- Todos os `migrar-*.sql`
- Todos os `popular-*.sql`

### **Scripts JavaScript para Deletar (~30 arquivos)**
- Todos os `testar-*.js`
- Todos os `teste-*.js`
- Todos os `corrigir-*.js`
- Todos os `diagnosticar-*.js`
- Todos os `verificar-*.js`
- Todos os `analisar-*.js`

### **Documentação de Desenvolvimento para Mover**
- `ANALISE_*.md`
- `CORRECAO_*.md`
- `SOLUCAO_*.md`
- `PROBLEMA_*.md`
- `IMPLEMENTACAO_*.md`

## 🎯 Resultado Final

### **Estrutura Limpa:**
```
campus/
├── src/                    # Código fonte (manter)
├── static/                 # Arquivos estáticos (manter)
├── node_modules/           # Dependências (manter)
├── scripts-desenvolvimento/ # Scripts arquivados
│   ├── correcoes/
│   ├── testes/
│   ├── diagnosticos/
│   └── migracoes/
├── docs/                   # Documentação
│   ├── RELATORIO_COMPATIBILIDADE_SISTEMA.md
│   ├── GUIA_ESTRUTURA_SISTEMA_COMPLETO.md
│   └── README.md
├── package.json
├── svelte.config.js
├── tailwind.config.js
└── outros arquivos de config
```

### **Benefícios:**
- ✅ Código limpo e organizado
- ✅ Fácil navegação
- ✅ Manutenção simplificada
- ✅ Onboarding mais fácil
- ✅ Foco no código essencial
