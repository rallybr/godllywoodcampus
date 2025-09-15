# ROTEIRO DE DESENVOLVIMENTO - SISTEMA INTELLIMEN CAMPUS

## 📋 VISÃO GERAL DO PROJETO

**Sistema para cadastrar e acompanhar jovens por edição do acampamento, com avaliação multi-avaliador (pastores/líderes), permissões hierárquicas por região/bloco/estado e relatórios para acompanhamento do desenvolvimento.**

- **Tecnologias:** Svelte + TypeScript + Supabase + Vercel + Tailwind CSS
- **Objetivo:** Cadastro completo e avaliação de jovens em acampamentos bimestrais
- **Público:** 48 jovens por edição de diversos estados do Brasil

### 🎯 OBJETIVOS PRINCIPAIS
- Cadastro completo do jovem (dados pessoais, espirituais, profissionais, redes)
- Hierarquia geográfica: Estado → Bloco → Região → Igreja
- Avaliações por múltiplos avaliadores (pastores), com notas, categorias e observações
- Controle de acessos com papéis (roles) que limitam visibilidade/ações por alcance geográfico e função
- Filtros / relatórios / export (CSV/PDF) e interface limpa, rápida e responsiva

---

## 🎯 PRINCIPAIS TELAS / FLUXOS (UX)

### 1. **Login / Autenticação (Supabase Auth)**
- Login por e-mail + senha
- Recuperação de senha
- Perfil do usuário com foto, nome, estado e papel

### 2. **Dashboard (home) — baseado no papel do usuário**
- Resumo: número de jovens no alcance, avaliações pendentes, média geral, últimos cadastros
- Acesso rápido: "Cadastrar Jovem", "Avaliar", "Relatórios"

### 3. **Lista de Jovens**
- Cards / tabela com foto, nome, idade, estado, bloco, região, igreja, edição selecionada
- Filtros no topo: edição, sexo, condição, idade, estado, bloco, região, igreja, aprovado / pré-aprovado
- Pesquisa por nome + ordenação

### 4. **Ficha do Jovem (detalhe)**
- Topo: foto + info básica (nome, idade, edição, igreja)
- Aba 1: Dados Pessoais (formulário com cascata Estado→Bloco→Região→Igreja)
- Aba 2: Profissional / Espiritual / Experiência
- Aba 3: Avaliações → lista de avaliações de pastores + botão "Adicionar avaliação"
- Aba 4: Histórico (trocas de líder, alterações de condição, logs)
- Botões: Editar, Exportar ficha, Marcar (Aprovado / Pré-Aprovado)

### 5. **Modal de Avaliação**
- Campos: avaliador (auto-preenchido), categoria1 (espírito: 4 opções), caráter (4 opções), disposição (4 opções), textarea observação, nota geral (1–10, radio buttons), salvar
- Possibilidade de "Adicionar outro avaliador" (sempre cria outra avaliação vinculada)

### 6. **Gerenciamento de Usuários / Papéis**
- Formulário de cadastro de usuários com seleção de papel e localidade atribuída (estado/bloco/região/igreja)
- Formulário para transferência de liderança (trocar lider de localidade)

### 7. **Relatórios / Export**
- Filtros aplicáveis, export CSV/PDF, gráficos simples (média por edição, por região etc)

### 8. **Config / Admin**
- CRUD para Estado/Bloco/Região/Igreja, Edições (1..10), cargos e permissões
- Config de buckets de fotos (Supabase Storage), políticas, backups

---

## 🏗️ ESTRUTURA DO PROJETO

```
src/
├── lib/
│   ├── components/
│   │   ├── forms/
│   │   │   ├── CadastroJovem.svelte
│   │   │   ├── CadastroUsuario.svelte
│   │   │   └── AvaliacaoJovem.svelte
│   │   ├── ui/
│   │   │   ├── Button.svelte
│   │   │   ├── Input.svelte
│   │   │   ├── Select.svelte
│   │   │   ├── Modal.svelte
│   │   │   └── Card.svelte
│   │   ├── layout/
│   │   │   ├── Header.svelte
│   │   │   ├── Sidebar.svelte
│   │   │   └── Footer.svelte
│   │   └── charts/
│   │       └── GraficoAvaliacoes.svelte
│   ├── stores/
│   │   ├── auth.js
│   │   ├── jovens.js
│   │   └── avaliacoes.js
│   ├── utils/
│   │   ├── supabase.js
│   │   ├── validators.js
│   │   └── helpers.js
│   └── types/
│       └── index.ts
├── routes/
│   ├── +layout.svelte
│   ├── +page.svelte
│   ├── login/
│   │   └── +page.svelte
│   ├── dashboard/
│   │   └── +page.svelte
│   ├── jovens/
│   │   ├── +page.svelte
│   │   ├── [id]/
│   │   │   └── +page.svelte
│   │   └── cadastrar/
│   │       └── +page.svelte
│   ├── avaliacoes/
│   │   ├── +page.svelte
│   │   └── [jovemId]/
│   │       └── +page.svelte
│   ├── usuarios/
│   │   ├── +page.svelte
│   │   └── cadastrar/
│   │       └── +page.svelte
│   └── relatorios/
│       └── +page.svelte
└── app.html
```

---

## 🗄️ MODELAGEM DE DADOS (TABELAS PRINCIPAIS)

### Tabelas Geográficas
```sql
-- Estados do Brasil
estados (id uuid PK, nome text, sigla text)

-- Blocos por estado
blocos (id uuid PK, estado_id uuid FK, nome text)

-- Regiões por bloco
regioes (id uuid PK, bloco_id uuid FK, nome text)

-- Igrejas por região
igrejas (id uuid PK, regiao_id uuid FK, nome text, endereco text)
```

### Tabelas de Sistema
```sql
-- Edições do acampamento
edicoes (id uuid PK, numero int, nome text, data_inicio date, data_fim date)

-- Usuários do sistema
usuarios (id uuid PK, email text, nome text, foto_path text, sexo text, estado_bandeira text, created_at timestamp)

-- Papéis/Roles do sistema
roles (id uuid PK, slug text, descricao text)

-- Relacionamento usuário-papel-localização
user_roles (id uuid PK, user_id uuid FK, role_id uuid FK, estado_id uuid FK nullable, bloco_id uuid FK nullable, regiao_id uuid FK nullable, igreja_id uuid FK nullable)
```

### Tabelas de Negócio
```sql
-- Jovens cadastrados
jovens (
  id uuid PK,
  foto_path text,
  nome_completo text,
  whatsapp text,
  data_nasc date,
  idade int,
  data_cadastro timestamp,
  estado_civil text,
  namora boolean,
  tem_filho boolean,
  trabalha boolean,
  local_trabalho text,
  escolaridade text,
  formacao text,
  tem_dividas boolean,
  tempo_igreja text,
  batizado_aguas boolean,
  data_batismo_aguas date,
  batizado_es boolean,
  data_batismo_es date,
  condicao text,
  pastor_que_indicou text,
  cresceu_na_igreja boolean,
  tempo_condicao text,
  responsabilidade_igreja text,
  experiencia_altar boolean,
  foi_obreiro boolean,
  foi_colaborador boolean,
  afastou boolean,
  quando_afastou date,
  motivo_afastou text,
  quando_voltou date,
  pais_sao_igreja boolean,
  obs_pais text,
  familiares_igreja boolean,
  deseja_altar boolean,
  observacao_text text,
  testemunho_text text,
  instagram text,
  facebook text,
  tiktok text,
  obs_redes text,
  estado_id uuid FK,
  bloco_id uuid FK,
  regiao_id uuid FK,
  igreja_id uuid FK,
  edicao_id uuid FK,
  aprovado enum
)

-- Avaliações dos jovens
avaliacoes (
  id uuid PK,
  jovem_id uuid FK,
  user_id uuid FK,
  data timestamp,
  espirito enum,
  caractere enum,
  disposicao enum,
  observacao text,
  nota int
)

-- Logs de histórico
logs_historico (
  id uuid PK,
  jovem_id uuid FK,
  user_id uuid FK,
  acao text,
  detalhe text,
  created_at timestamp
)
```

### Enums
- `intellimen_aprovado_enum` - Status de aprovação (null, pré-aprovado, aprovado)
- `intellimen_espirito_enum` - Avaliação do espírito (ruim, observar, bom, excelente)
- `intellimen_caractere_enum` - Avaliação do caráter (excelente, bom, observar, ruim)
- `intellimen_disposicao_enum` - Avaliação da disposição (muito_disposto, normal, pacato, desanimado)

---

## 🎨 DESIGN SYSTEM

### Cores Principais
```css
:root {
  --primary: #1e40af;      /* Azul principal */
  --secondary: #059669;    /* Verde secundário */
  --accent: #dc2626;       /* Vermelho de destaque */
  --neutral: #6b7280;      /* Cinza neutro */
  --background: #f8fafc;   /* Fundo claro */
  --surface: #ffffff;      /* Superfície */
  --text: #1f2937;         /* Texto principal */
}
```

### Componentes UI
- **Botões:** Primário, Secundário, Outline, Ghost
- **Inputs:** Text, Email, Password, Select, Textarea, File
- **Cards:** Padrão, Com header, Com ações
- **Modais:** Confirmação, Formulário, Informação
- **Tabelas:** Responsivas com filtros
- **Badges:** Status, Tags, Contadores

---

## 📱 PÁGINAS E ROTAS

### 1. **Página de Login** (`/login`)
- Formulário de autenticação
- Integração com Supabase Auth
- Redirecionamento baseado no nível de acesso

### 2. **Dashboard** (`/dashboard`)
- Visão geral do sistema
- Estatísticas por edição
- Gráficos de avaliações
- Acesso rápido às funcionalidades

### 3. **Gestão de Jovens** (`/jovens`)
- Lista de jovens com filtros
- Cards com informações básicas
- Ações: Ver detalhes, Editar, Avaliar
- Paginação e busca

### 4. **Cadastro de Jovem** (`/jovens/cadastrar`)
- Formulário em etapas
- Validação em tempo real
- Upload de foto
- Seleção hierárquica de localização

### 5. **Perfil do Jovem** (`/jovens/[id]`)
- Informações completas
- Histórico de avaliações
- Gráficos de evolução
- Ações de aprovação

### 6. **Sistema de Avaliação** (`/avaliacoes`)
- Lista de jovens para avaliar
- Formulário de avaliação
- Histórico de avaliações
- Relatórios por avaliador

### 7. **Gestão de Usuários** (`/usuarios`)
- Lista de usuários por nível
- Cadastro de novos usuários
- Edição de permissões
- Troca de liderança

### 8. **Relatórios** (`/relatorios`)
- Relatórios por edição
- Estatísticas gerais
- Exportação de dados
- Gráficos analíticos

---

## 🔧 FUNCIONALIDADES TÉCNICAS

### 1. **Autenticação e Autorização**
- Login com Supabase Auth
- RLS (Row Level Security) no banco
- Middleware de verificação de permissões
- Redirecionamento baseado em nível

### 2. **Validação de Dados**
- Validação client-side com Svelte
- Validação server-side com Supabase
- Mensagens de erro contextuais
- Sanitização de inputs

### 3. **Upload de Arquivos**
- Upload de fotos para Supabase Storage
- Compressão automática de imagens
- Validação de tipos e tamanhos
- URLs otimizadas
- **IMPORTANTE:** Usar nomes corretos dos buckets (fotos_usuarios, fotos_jovens)

### 4. **Filtros e Busca**
- Filtros em tempo real
- Busca por texto
- Filtros combinados
- Persistência de filtros na URL

### 5. **Responsividade**
- Design mobile-first
- Breakpoints: sm, md, lg, xl
- Componentes adaptáveis
- Navegação otimizada para mobile

---

## 📊 COMPONENTES PRINCIPAIS

### 1. **CadastroJovem.svelte**
```svelte
<script>
  // Formulário em etapas
  // Validação de dados
  // Upload de foto
  // Seleção hierárquica
</script>
```

### 2. **AvaliacaoJovem.svelte**
```svelte
<script>
  // Formulário de avaliação
  // Múltiplos avaliadores
  // Nota de 1 a 10
  // Comentários textuais
</script>
```

### 3. **FiltrosJovens.svelte**
```svelte
<script>
  // Filtros por localização
  // Filtros por características
  // Busca por nome
  // Filtros por edição
</script>
```

### 4. **ListaJovens.svelte**
```svelte
<script>
  // Cards de jovens
  // Paginação
  // Ações rápidas
  // Status de aprovação
</script>
```

---

## 🚀 CRONOGRAMA DE DESENVOLVIMENTO

### **Fase 1: Setup e Estrutura (Semana 1)**
- [ ] Configuração do projeto Svelte + TypeScript
- [ ] Setup do Supabase (Auth + Database + Storage)
- [ ] Configuração do Tailwind CSS
- [ ] Estrutura de pastas e arquivos
- [ ] Componentes base UI (Button, Input, Modal, Card)
- [ ] Configuração de tipos TypeScript

### **Fase 2: Banco de Dados e Autenticação (Semana 2)**
- [ ] Criação das tabelas no Supabase
- [ ] Configuração dos Enums
- [ ] Setup do Supabase Auth
- [ ] RLS Policies para todas as tabelas
- [ ] Sistema de login com recuperação de senha
- [ ] Middleware de autenticação e autorização

### **Fase 3: Cadastro de Jovens (Semana 3)**
- [ ] Formulário de cadastro em etapas
- [ ] Validação de dados com Zod
- [ ] Upload de fotos para Supabase Storage
- [ ] Seleção hierárquica Estado→Bloco→Região→Igreja
- [ ] Cálculo automático de idade
- [ ] Integração completa com banco

### **Fase 4: Sistema de Avaliação (Semana 4)**
- [ ] Modal de avaliação com múltiplos critérios
- [ ] Sistema de múltiplos avaliadores
- [ ] Nota de 1 a 10 com radio buttons
- [ ] Histórico de avaliações por jovem
- [ ] Permissões por nível de acesso
- [ ] Cálculo de médias automático

### **Fase 5: Interface e Filtros (Semana 5)**
- [ ] Lista de jovens com cards responsivos
- [ ] Sistema de filtros avançados
- [ ] Busca por nome em tempo real
- [ ] Paginação server-side
- [ ] Ordenação por múltiplos critérios
- [ ] Status de aprovação visual

### **Fase 6: Gestão de Usuários e Papéis (Semana 6)**
- [ ] Cadastro de usuários com seleção de papel
- [ ] Sistema de roles com localização
- [ ] Formulário de transferência de liderança
- [ ] Perfis de usuário com foto
- [ ] Controle de permissões granular
- [ ] Logs de auditoria

### **Fase 7: Dashboard e Relatórios (Semana 7)**
- [ ] Dashboard personalizado por papel
- [ ] Gráficos de avaliações e estatísticas
- [ ] Relatórios por edição/região/igreja
- [ ] Export CSV com filtros aplicados
- [ ] Export PDF de fichas individuais
- [ ] Métricas de acompanhamento

### **Fase 8: Configurações e Deploy (Semana 8)**
- [ ] CRUD para Estados/Blocos/Regiões/Igrejas
- [ ] Gestão de edições (1-10)
- [ ] Configuração de buckets de fotos
- [ ] Testes de funcionalidades
- [ ] Deploy na Vercel
- [ ] Configuração de domínio e SSL

---

## 🔄 FLUXOS CRÍTICOS DETALHADOS

### 1. **Cadastro com Cascata Estado→Bloco→Região→Igreja**
```javascript
// Fluxo de seleção hierárquica
OnSelect(Estado) → fetch blocos where estado_id
OnSelect(Bloco) → fetch regioes where bloco_id  
OnSelect(Região) → fetch igrejas where regiao_id
```

### 2. **Adicionar Avaliação**
- Na ficha do jovem, botão "Adicionar avaliação"
- Modal: preenchimento; ao salvar, cria registro em avaliacoes com user_id = current_user
- Após salvar, recalcular média geral do jovem (pode mostrar badge)
- Permitir "Adicionar outro avaliador" — repete modal em sequência

### 3. **Transferência de Liderança**
- Form: selecionar usuário atual, novo usuário, localidade (estado/bloco/região/igreja)
- Backend: criar log + atualizar user_roles (desabilitar antigo, adicionar novo)

### 4. **Aprovação**
- Botões "Pré-Aprovado" e "Aprovado" visíveis apenas a users com permissão
- Mudança gera log e notificação (in-app)

---

## 🗄️ SUPABASE: STORAGE, POLICIES & TIPS

### Storage Buckets
```sql
-- Bucket para fotos dos jovens
fotos_jovens (padrão private)
- Estrutura: {jovem_id}/profile.jpg
- Política: usuários só podem ver/editar se tiverem relação no user_roles

-- Bucket para fotos dos usuários  
fotos_usuarios (padrão private)
- Estrutura: {user_id}/profile.jpg
- Política: usuário só pode ver/editar sua própria foto

-- Bucket para documentos
documentos (padrão private)
- Estrutura: {jovem_id}/documentos/
- Política: acesso baseado na hierarquia do usuário

-- Bucket para backups
backups (padrão private)
- Estrutura: {data}/backup_files/
- Política: apenas administradores

-- Bucket temporário
temp (padrão private)
- Estrutura: {user_id}/temp_files/
- Política: usuários autenticados
```

### RLS Policies para Storage
```sql
-- Política para fotos de jovens
create policy "fotos_jovens_hierarchy" on storage.objects
  for all using (
    bucket_id = 'fotos_jovens' and
    exists (
      select 1 from user_roles ur 
      where ur.user_id = auth.uid() 
      and (
        ur.role_id = 'administrador' or
        ur.role_id = 'colaborador' or
        (ur.role_id like 'lider_%' and ur.estado_id = (select estado_id from jovens where id::text = (storage.foldername(name))[1]))
      )
    )
  );

-- Política para fotos de usuários
create policy "fotos_usuarios_self" on storage.objects
  for all using (
    bucket_id = 'fotos_usuarios' and
    auth.uid()::text = (storage.foldername(name))[1]
  );

-- Política para documentos
create policy "documentos_hierarchy" on storage.objects
  for all using (
    bucket_id = 'documentos' and
    exists (
      select 1 from user_roles ur 
      where ur.user_id = auth.uid() 
      and ur.role_id in ('administrador', 'colaborador', 'lider_estadual_iurd', 'lider_estadual_fju', 'lider_bloco_iurd', 'lider_bloco_fju', 'lider_regional_iurd', 'lider_igreja_iurd')
    )
  );

-- Política para backups
create policy "backups_admin" on storage.objects
  for all using (
    bucket_id = 'backups' and
    exists (
      select 1 from user_roles ur 
      where ur.user_id = auth.uid() 
      and ur.role_id = 'administrador'
    )
  );

-- Política para temp
create policy "temp_authenticated" on storage.objects
  for all using (bucket_id = 'temp');
```

### Edge Functions
```sql
-- Função para recalcular idade
create or replace function recalcular_idade()
returns trigger as $$
begin
  new.idade = date_part('year', age(new.data_nasc))::int;
  return new;
end;
$$ language plpgsql;

-- Trigger para atualizar idade automaticamente
create trigger trigger_recalcular_idade
  before insert or update on jovens
  for each row execute function recalcular_idade();
```

### Performance Tips
- **Lazy loading** para imagens + thumbnails
- **Compressão client-side** antes do upload
- **URLs temporários** para fotos privadas
- **Índices otimizados** em campos de busca

---

## 🔒 REGRAS DE NEGÓCIO E PERMISSÕES (RBAC + RLS)

### Sistema de Papéis (Roles)
```sql
-- Papéis disponíveis no sistema
roles:
- administrador (Acesso total ao sistema)
- colaborador (Acesso amplo para colaboração)
- lider_nacional_iurd (Responsável nacional IURD)
- lider_nacional_fju (Responsável nacional FJU)
- lider_estadual_iurd (Líder estadual IURD)
- lider_estadual_fju (Líder estadual FJU)
- lider_bloco_iurd (Líder de bloco IURD)
- lider_bloco_fju (Líder de bloco FJU)
- lider_regional_iurd (Líder regional IURD)
- lider_igreja_iurd (Líder de igreja IURD)
```

### Controle de Acesso por Localização
- **lider_estadual_***: Acesso apenas aos jovens do estado específico
- **lider_bloco_***: Acesso apenas aos jovens do bloco específico
- **lider_regional_***: Acesso apenas aos jovens da região específica
- **lider_igreja_***: Acesso apenas aos jovens da igreja específica
- **colaborador**: Acesso a todos os jovens
- **administrador**: Acesso total ao sistema

### RLS Policies (Row-Level Security)
```sql
-- Exemplo de regra RLS
lider_estadual_* pode SELECT/UPDATE apenas onde:
jovens.estado_id = user_role.estado_id

-- Avaliadores só podem criar/editar suas próprias avaliações
avaliacoes.user_id = auth.uid()

-- Editar avaliação por outro avaliador só por admin
admin pode editar qualquer avaliação
```

### Regras de Negócio
- **Troca de liderança**: Formulário que cria nova entrada em user_roles e cria log
- **Avaliações**: Múltiplos avaliadores por jovem, cada um cria sua própria avaliação
- **Aprovação**: Apenas líderes com permissão podem aprovar/pré-aprovar jovens
- **Logs de auditoria**: Todas as ações importantes são registradas em logs_historico

---

## 📊 RELATÓRIOS E MÉTRICAS (PRIORIDADES)

### Relatórios Principais
- **Média de notas por edição/região/igreja**
- **Distribuição por categoria** (espírito, caráter, disposição)
- **Lista de jovens "a observar"** (filtrar por avaliações que tenham "Ser observado" ou nota ≤ X)
- **Export CSV** com filtros aplicados
- **Relatório PDF** por jovem (Ficha + avaliações)

### Métricas de Acompanhamento
- Número total de jovens por edição
- Taxa de aprovação por região
- Evolução das avaliações ao longo do tempo
- Jovens com avaliações pendentes
- Distribuição por faixa etária

---

## 🔔 NOTIFICAÇÕES & COMUNICAÇÃO

### Notificações Internas
- **Inbox** para novos cadastros no alcance do líder
- **Alertas** para avaliações pendentes
- **Notificações** de mudanças de status (aprovado/pré-aprovado)
- **Lembretes** para líderes sobre jovens sem avaliação

### Integrações Opcionais
- **WhatsApp API** (externa) para avisos - plugin opcional por custos
- **Emails** (via provider SMTP) para confirmações e resets
- **SMS** para notificações críticas

---

## 🔒 SEGURANÇA & CONFORMIDADE

### Autenticação e Autorização
- **Supabase Auth** com e-mail e senha forte obrigatória
- **RLS bem configurado** e testado (cenários: usuário X não deve ver registros fora do alcance)
- **Sanitização** de textos nas avaliações
- **Logs de auditoria** (troca de líder, alteração de condição, exclusões)

### Backup e Recuperação
- **Backup periódico** de dados e cópia do storage
- **Export manual** antes de cada edição
- **Versionamento** de dados críticos
- **Recuperação** de dados em caso de falhas

---

## 🎨 ESTÉTICA / UI SUGGESTIONS (VISUAL)

### Paleta de Cores
```css
:root {
  --primary: #1e40af;      /* Azul escuro (confiança) */
  --secondary: #fbbf24;    /* Amarelo/dourado (IURD) */
  --accent: #dc2626;       /* Vermelho de destaque */
  --neutral: #6b7280;      /* Cinza neutro */
  --background: #f8fafc;   /* Fundo claro */
  --surface: #ffffff;      /* Superfície */
  --text: #1f2937;         /* Texto principal */
}
```

### Design Elements
- **Cards** com sombra suave, bordas arredondadas (2xl), espaçamentos confortáveis
- **Foto grande** na ficha; thumbnails circulares em listas
- **Micro-interações** com confirmações suaves (framer motion para Svelte/animate)
- **Loading skeletons** para melhor UX
- **Tipografia** legível, tamanho médio maior para nomes

---

## ✅ CHECKLIST DE ACEITAÇÃO PARA CADA ENTREGA

### Cadastro de Jovem
- [ ] Seleção em cascata Estado→Bloco→Região→Igreja funcionando
- [ ] Upload de foto com compressão
- [ ] Validação de todos os campos obrigatórios
- [ ] Cálculo automático de idade
- [ ] Salvamento no banco com RLS aplicado

### Visualização da Ficha
- [ ] Ficha completa com todas as abas
- [ ] Informações organizadas e legíveis
- [ ] Botões de ação funcionais (Editar, Exportar, Aprovar)
- [ ] Responsividade em mobile

### Sistema de Avaliação
- [ ] Modal de avaliação com todos os campos
- [ ] Múltiplos avaliadores por jovem
- [ ] Nota de 1 a 10 com radio buttons
- [ ] Histórico de avaliações organizado
- [ ] Cálculo de médias automático

### Permissões e Segurança
- [ ] Líder estadual só vê jovens do estado
- [ ] Líder igreja só vê jovens da igreja
- [ ] Avaliadores só editam suas próprias avaliações
- [ ] Admin tem acesso total
- [ ] RLS funcionando corretamente

### Export e Relatórios
- [ ] Export CSV com filtros aplicados
- [ ] Relatório PDF por jovem
- [ ] Gráficos de estatísticas
- [ ] Filtros funcionando corretamente

### Troca de Liderança
- [ ] Formulário de transferência
- [ ] Atualização de user_roles
- [ ] Log de auditoria criado
- [ ] Notificação enviada

---

## ⚠️ RISCOS E RECOMENDAÇÕES

### Riscos Identificados
- **RLS mal configurado** → exposição de dados
  - *Mitigação*: testes automatizados das políticas
- **Imagens grandes / storage caro** → custos elevados
  - *Mitigação*: redimensionamento client-side + thumbnails + compressão
- **Performance com muitos dados** → lentidão
  - *Mitigação*: paginação server-side + índices otimizados
- **Nomes de buckets inconsistentes** → erro "Bucket not found"
  - *Mitigação*: usar sempre fotos_usuarios e fotos_jovens (com underscore)
- **Recursão infinita em políticas RLS** → erro "infinite recursion detected"
  - *Mitigação*: usar funções auxiliares e evitar consultas circulares

### Recomendações
- **Registrar cada edição** como dado primário para histórico
- **Não sobrescrever** dados de edições passadas
- **Criar seeds** (Estados, Blocos, Regiões, Igrejas) para agilizar cadastros
- **Implementar cache** para consultas frequentes
- **Monitorar uso** de storage e otimizar regularmente

---

## 📱 RESPONSIVIDADE

### Breakpoints
- **Mobile:** < 640px
- **Tablet:** 640px - 1024px
- **Desktop:** > 1024px

### Adaptações
- Menu hambúrguer no mobile
- Cards empilhados em telas pequenas
- Formulários em coluna única
- Botões de ação otimizados

---

## 🔧 TROUBLESHOOTING

### Problemas Comuns e Soluções

#### 1. Erro "Bucket not found" no upload de fotos
**Causa:** Nomes de buckets inconsistentes entre código e Supabase
**Solução:** 
- Verificar se os buckets no Supabase são: `fotos_usuarios`, `fotos_jovens`
- Usar sempre underscore (_) nos nomes dos buckets
- Atualizar código para usar nomes corretos

#### 2. Erro de conexão com Supabase
**Causa:** Variáveis de ambiente não configuradas
**Solução:**
- Criar arquivo `.env.local` com credenciais corretas
- Verificar se `VITE_SUPABASE_URL` e `VITE_SUPABASE_ANON_KEY` estão definidas

#### 3. Erro de permissão no upload
**Causa:** Políticas RLS não configuradas ou usuário não autenticado
**Solução:**
- Verificar se o usuário está logado
- Verificar se as políticas RLS estão ativas
- Verificar se o usuário tem permissão para o bucket

#### 4. Erro "infinite recursion detected in policy for relation usuarios"
**Causa:** Políticas RLS da tabela usuarios causando recursão infinita
**Solução:**
- Usar função auxiliar `is_admin_user()` para evitar recursão
- Simplificar políticas RLS para não consultar a própria tabela
- Executar script `SOLUCAO_DEFINITIVA_RECURSAO.sql`

## 🎯 PRÓXIMOS PASSOS

1. **Revisão do Roteiro** - Aguardar feedback
2. **Ajustes e Refinamentos** - Baseado nas sugestões
3. **Roteiro Definitivo** - Versão final aprovada
4. **Início do Desenvolvimento** - Implementação das funcionalidades

---

## 💡 SUGESTÕES E MELHORIAS

### Funcionalidades Adicionais
- **Notificações** - Sistema de alertas
- **Chat** - Comunicação entre líderes
- **Calendário** - Eventos e cronogramas
- **Backup** - Exportação automática de dados
- **API** - Integração com sistemas externos

### Melhorias de UX
- **Tema escuro** - Alternância de tema
- **Atalhos de teclado** - Navegação rápida
- **Drag & Drop** - Upload de fotos
- **Autocomplete** - Busca inteligente
- **Tutorial** - Onboarding para novos usuários

---

**Data de Criação:** [Data atual]
**Versão:** 1.0
**Status:** Aguardando revisão
