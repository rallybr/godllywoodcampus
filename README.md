# IntelliMen Campus

Sistema de avaliação de jovens para acampamentos IntelliMen Campus.

## 🚀 Tecnologias

- **Frontend**: Svelte + TypeScript + Tailwind CSS
- **Backend**: Supabase (Auth + Database + Storage)
- **Deploy**: Vercel
- **Banco de Dados**: PostgreSQL (via Supabase)

## 📋 Funcionalidades

### ✅ Implementadas
- [x] Estrutura de banco de dados completa
- [x] Sistema de autenticação
- [x] Interface base com componentes UI
- [x] Dashboard principal
- [x] Lista de jovens com filtros
- [x] Sistema de permissões (RBAC)
- [x] Layout responsivo

### 🚧 Em Desenvolvimento
- [ ] Cadastro de jovens
- [ ] Sistema de avaliações
- [ ] Relatórios e exportação
- [ ] Gerenciamento de usuários
- [ ] Configurações do sistema

### ✈️ Módulo de Viagens (novo)
Controle por edição do acampamento. Nova tabela `public.dados_viagem` armazena pagamento de despesas e passagens (ida/volta) por jovem/edição, com URLs de comprovantes no storage. UI em `routes/viagem` lista cards por jovem incluindo foto, nome e hierarquia (igreja/região/bloco/estado) e permite upload independente dos três comprovantes.

## 🛠️ Instalação

1. **Clone o repositório**
   ```bash
   git clone <repository-url>
   cd intellimen-campus
   ```

2. **Instale as dependências**
   ```bash
   npm install
   ```

3. **Configure as variáveis de ambiente**
   ```bash
   cp env.example .env
   ```
   
   Edite o arquivo `.env` com suas credenciais do Supabase:
   ```
   VITE_SUPABASE_URL=https://your-project.supabase.co
   VITE_SUPABASE_ANON_KEY=your_supabase_anon_key
   ```

4. **Execute o banco de dados**
   - Execute o script `MIGRACAO_FINAL_INTELLIMEN_CAMPUS.sql` no Supabase
   - Execute o script `CORRECAO_CAMPO_IDADE.sql` se necessário

5. **Inicie o servidor de desenvolvimento**
   ```bash
   npm run dev
   ```

6. **Acesse a aplicação**
   - Abra [http://localhost:5173](http://localhost:5173)

## 📁 Estrutura do Projeto

```
src/
├── lib/
│   ├── components/
│   │   ├── ui/           # Componentes base (Button, Input, Modal, etc.)
│   │   ├── layout/       # Header, Sidebar, etc.
│   │   └── jovens/       # Componentes específicos de jovens
│   ├── stores/           # Stores Svelte (auth, jovens, etc.)
│   ├── types/            # Definições TypeScript
│   └── utils/            # Utilitários (Supabase, helpers)
├── routes/               # Páginas da aplicação
│   ├── +layout.svelte   # Layout principal
│   ├── +page.svelte     # Dashboard
│   ├── login/           # Página de login
│   └── jovens/          # Páginas de jovens
└── app.html             # Template HTML base
```

## 🗄️ Banco de Dados

O sistema utiliza PostgreSQL via Supabase com as seguintes tabelas principais:

- **usuarios**: Usuários do sistema
- **jovens**: Dados dos jovens cadastrados
- **avaliacoes**: Avaliações dos jovens
- **edicoes**: Edições do acampamento
- **roles**: Papéis/permissões
- **user_roles**: Associação usuário-papel
- **logs_historico**: Logs de auditoria

## 🔐 Sistema de Permissões

O sistema implementa RBAC (Role-Based Access Control) com os seguintes níveis:

- **administrador**: Acesso total ao sistema
- **colaborador**: Pode ver e avaliar todos os jovens
- **lider_estadual_***: Acesso a jovens do estado
- **lider_bloco_***: Acesso a jovens do bloco
- **lider_regional_***: Acesso a jovens da região
- **lider_igreja_***: Acesso a jovens da igreja

## 🚀 Deploy

### Vercel

1. **Conecte o repositório ao Vercel**
2. **Configure as variáveis de ambiente**
3. **Deploy automático**

### Supabase

1. **Execute os scripts de migração**
2. **Configure as políticas RLS**
3. **Configure o Storage para fotos**

## 📝 Scripts Disponíveis

- `npm run dev` - Servidor de desenvolvimento
- `npm run build` - Build para produção
- `npm run preview` - Preview do build
- `npm run check` - Verificação de tipos
- `npm run lint` - Linting do código
- `npm run format` - Formatação do código

## 🤝 Contribuição

1. Fork o projeto
2. Crie uma branch para sua feature
3. Commit suas mudanças
4. Push para a branch
5. Abra um Pull Request

## 📄 Licença

Este projeto é privado e pertence ao IntelliMen Campus.

## 📞 Suporte

Para suporte, entre em contato com a equipe de desenvolvimento.