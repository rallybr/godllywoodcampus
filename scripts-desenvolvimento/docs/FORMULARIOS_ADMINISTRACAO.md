# Formulários de Administração - Campus

## Visão Geral

Foram implementados dois formulários para administração do sistema hierárquico:

1. **Formulário de Cadastro de Região**
2. **Formulário de Cadastro de Igreja**

## Estrutura Hierárquica

O sistema segue a seguinte hierarquia:
```
Estados → Blocos → Regiões → Igrejas
```

### Tabelas do Banco de Dados

- **estados**: `id`, `nome`, `sigla`, `bandeira`
- **blocos**: `id`, `estado_id`, `nome`
- **regioes**: `id`, `bloco_id`, `nome`
- **igrejas**: `id`, `regiao_id`, `nome`, `endereco`

## Formulário de Cadastro de Região

### Localização
- **Rota**: `/regioes/cadastrar`
- **Componente**: `src/lib/components/forms/CadastroRegiao.svelte`

### Funcionalidades
1. **Select de Estados**: Carrega todos os estados disponíveis
2. **Select de Blocos**: Carrega blocos baseado no estado selecionado
3. **Campo de Texto**: Para inserir o nome da região
4. **Validação**: Verifica se todos os campos obrigatórios foram preenchidos
5. **Inserção**: Salva a região com o `bloco_id` correto

### Fluxo de Uso
1. Selecionar um estado
2. Selecionar um bloco (carregado automaticamente)
3. Digitar o nome da região
4. Clicar em "Salvar Região"

## Formulário de Cadastro de Igreja

### Localização
- **Rota**: `/igrejas/cadastrar`
- **Componente**: `src/lib/components/forms/CadastroIgreja.svelte`

### Funcionalidades
1. **Select de Estados**: Carrega todos os estados disponíveis
2. **Select de Blocos**: Carrega blocos baseado no estado selecionado
3. **Select de Regiões**: Carrega regiões baseado no bloco selecionado
4. **Campo de Texto**: Para inserir o nome da igreja
5. **Campo de Texto**: Para inserir o endereço da igreja
6. **Validação**: Verifica se todos os campos obrigatórios foram preenchidos
7. **Inserção**: Salva a igreja com o `regiao_id` correto

### Fluxo de Uso
1. Selecionar um estado
2. Selecionar um bloco (carregado automaticamente)
3. Selecionar uma região (carregada automaticamente)
4. Digitar o nome da igreja
5. Digitar o endereço da igreja
6. Clicar em "Salvar Igreja"

## Página de Administração

### Localização
- **Rota**: `/administracao`
- **Componente**: `src/routes/administracao/+page.svelte`

### Funcionalidades
- Interface centralizada para acessar os formulários
- Explicação visual da hierarquia do sistema
- Cards com descrições dos formulários
- Links diretos para cada formulário

## Acesso

### Permissões
- Apenas usuários com nível **administrador** podem acessar
- Item "Administração" adicionado ao menu lateral para administradores

### Navegação
1. Fazer login como administrador
2. Clicar em "Administração" no menu lateral
3. Escolher entre "Cadastrar Região" ou "Cadastrar Igreja"

## Características Técnicas

### Validações
- Campos obrigatórios são validados antes do envio
- Mensagens de erro são exibidas de forma clara
- Formulários são limpos após sucesso

### Estados de Loading
- Indicadores visuais durante o carregamento
- Botões desabilitados durante operações
- Feedback visual de sucesso/erro

### Responsividade
- Formulários adaptados para diferentes tamanhos de tela
- Interface mobile-friendly

### Integração
- Utiliza o store `geographic.js` existente
- Mantém compatibilidade com o sistema atual
- Não interfere no funcionamento existente

## Arquivos Criados

```
src/lib/components/forms/
├── CadastroRegiao.svelte
└── CadastroIgreja.svelte

src/routes/
├── administracao/
│   └── +page.svelte
├── regioes/
│   └── cadastrar/
│       └── +page.svelte
└── igrejas/
    └── cadastrar/
        └── +page.svelte
```

## Modificações

- **Sidebar.svelte**: Adicionado item "Administração" para administradores

## Testes Recomendados

1. **Teste de Cadastro de Região**:
   - Selecionar estado
   - Verificar se blocos carregam
   - Inserir nome da região
   - Verificar se salva corretamente

2. **Teste de Cadastro de Igreja**:
   - Selecionar estado
   - Verificar se blocos carregam
   - Selecionar bloco
   - Verificar se regiões carregam
   - Inserir dados da igreja
   - Verificar se salva corretamente

3. **Teste de Validações**:
   - Tentar salvar sem preencher campos obrigatórios
   - Verificar mensagens de erro
   - Testar limpeza de formulário

4. **Teste de Permissões**:
   - Verificar se apenas administradores veem o menu
   - Testar acesso direto às rotas
