# Guia Completo da Estrutura do Sistema - Campus IntelliMen

## 📋 Índice
1. [Visão Geral](#visão-geral)
2. [Tabelas do Sistema](#tabelas-do-sistema)
3. [Functions RPC](#functions-rpc)
4. [Policies RLS](#policies-rls)
5. [Storage Buckets](#storage-buckets)
6. [Hierarquia de Permissões](#hierarquia-de-permissões)
7. [Relacionamentos](#relacionamentos)
8. [Guia de Manutenção](#guia-de-manutenção)

---

## 🎯 Visão Geral

Sistema de gerenciamento e avaliação de jovens com arquitetura robusta baseada em:
- **PostgreSQL** com Supabase
- **SvelteKit** no frontend
- **Sistema hierárquico** de 8 níveis de permissão
- **Storage** para arquivos e documentos
- **Sistema de notificações** automatizado

---

## 📊 Tabelas do Sistema

### 1. **usuarios** - Gestão de Usuários
```sql
CREATE TABLE public.usuarios (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  id_auth uuid,                    -- ID do Supabase Auth
  nome text NOT NULL,
  email text,
  foto text,
  sexo text,
  nivel text NOT NULL,            -- Nível hierárquico
  ativo boolean DEFAULT true,
  criado_em timestamp with time zone DEFAULT now(),
  ultimo_acesso timestamp with time zone,
  -- Localização geográfica
  estado_id uuid,
  bloco_id uuid,
  regiao_id uuid,
  igreja_id uuid,
  estado_bandeira text
);
```

### 2. **jovens** - Cadastro de Jovens
```sql
CREATE TABLE public.jovens (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  nome_completo text NOT NULL,
  data_nasc date NOT NULL,
  idade integer,
  sexo text,
  whatsapp text,
  foto text,
  -- Dados pessoais
  estado_civil text,
  namora boolean,
  tem_filho boolean,
  trabalha boolean,
  local_trabalho text,
  escolaridade text,
  formacao text,
  tem_dividas boolean,
  valor_divida numeric,
  -- Dados espirituais
  tempo_igreja text,
  batizado_aguas boolean,
  data_batismo_aguas date,
  batizado_es boolean,
  data_batismo_es date,
  condicao text,
  condicao_campus text,
  tempo_condicao text,
  responsabilidade_igreja text,
  -- Experiência
  disposto_servir boolean,
  ja_obra_altar boolean,
  ja_obreiro boolean,
  ja_colaborador boolean,
  afastado boolean,
  data_afastamento date,
  motivo_afastamento text,
  data_retorno date,
  -- Informações familiares
  pais_na_igreja boolean,
  obs_pais text,
  familiares_igreja boolean,
  -- Dados adicionais
  deseja_altar boolean,
  observacao text,
  testemunho text,
  -- Redes sociais
  instagram text,
  facebook text,
  tiktok text,
  obs_redes text,
  -- IntelliMen
  formado_intellimen boolean DEFAULT false,
  fazendo_desafios boolean DEFAULT false,
  qual_desafio text,
  -- Sistema
  aprovado intellimen_aprovado_enum DEFAULT 'null',
  data_cadastro timestamp with time zone DEFAULT now(),
  usuario_id uuid,
  -- Localização
  estado_id uuid,
  bloco_id uuid,
  regiao_id uuid,
  igreja_id uuid,
  edicao_id uuid,
  edicao text NOT NULL
);
```

### 3. **avaliacoes** - Sistema de Avaliações
```sql
CREATE TABLE public.avaliacoes (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  jovem_id uuid NOT NULL,
  user_id uuid NOT NULL,
  -- Avaliações por categoria
  espirito intellimen_avaliacao_enum,
  caractere intellimen_avaliacao_enum,
  disposicao intellimen_disposicao_enum,
  nota integer,
  avaliacao_texto text,
  data timestamp without time zone DEFAULT now(),
  criado_em timestamp with time zone DEFAULT now()
);
```

### 4. **aprovacoes_jovens** - Sistema de Aprovações Múltiplas
```sql
CREATE TABLE public.aprovacoes_jovens (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  jovem_id uuid NOT NULL,
  usuario_id uuid NOT NULL,
  tipo_aprovacao text NOT NULL,    -- 'pre_aprovado' ou 'aprovado'
  observacao text,
  criado_em timestamp with time zone DEFAULT now(),
  atualizado_em timestamp with time zone DEFAULT now()
);
```

### 5. **dados_viagem** - Gestão de Viagens
```sql
CREATE TABLE public.dados_viagem (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  jovem_id uuid NOT NULL,
  edicao_id uuid NOT NULL,
  usuario_id uuid,
  -- Dados de pagamento
  pagou_despesas boolean DEFAULT false,
  comprovante_pagamento text,
  -- Passagens
  data_passagem_ida timestamp with time zone,
  comprovante_passagem_ida text,
  data_passagem_volta timestamp with time zone,
  comprovante_passagem_volta text,
  -- Sistema
  data_cadastro timestamp with time zone DEFAULT now(),
  atualizado_em timestamp with time zone DEFAULT now()
);
```

### 6. **roles** - Sistema de Papéis
```sql
CREATE TABLE public.roles (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  nome text NOT NULL,
  slug text NOT NULL,
  descricao text,
  nivel_hierarquico integer NOT NULL,
  criado_em timestamp with time zone DEFAULT now()
);
```

### 7. **user_roles** - Associação Usuário-Papel
```sql
CREATE TABLE public.user_roles (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL,
  role_id uuid NOT NULL,
  ativo boolean DEFAULT true,
  -- Escopo geográfico
  estado_id uuid,
  bloco_id uuid,
  regiao_id uuid,
  igreja_id uuid,
  -- Sistema
  criado_em timestamp with time zone DEFAULT now(),
  criado_por uuid
);
```

### 8. **estados** - Estados Brasileiros
```sql
CREATE TABLE public.estados (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  nome text NOT NULL,
  sigla text NOT NULL,
  bandeira text
);
```

### 9. **blocos** - Blocos Regionais
```sql
CREATE TABLE public.blocos (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  nome text NOT NULL,
  estado_id uuid
);
```

### 10. **regioes** - Regiões
```sql
CREATE TABLE public.regioes (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  nome text NOT NULL,
  bloco_id uuid
);
```

### 11. **igrejas** - Igrejas
```sql
CREATE TABLE public.igrejas (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  nome text NOT NULL,
  endereco text,
  regiao_id uuid
);
```

### 12. **edicoes** - Edições do Campus
```sql
CREATE TABLE public.edicoes (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  nome text NOT NULL,
  numero integer NOT NULL,
  ativa boolean DEFAULT true,
  data_inicio date,
  data_fim date,
  criado_em timestamp with time zone DEFAULT now()
);
```

### 13. **notificacoes** - Sistema de Notificações
```sql
CREATE TABLE public.notificacoes (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  destinatario_id uuid NOT NULL,
  remetente_id uuid,
  jovem_id uuid,
  tipo character varying NOT NULL,
  titulo character varying NOT NULL,
  mensagem text NOT NULL,
  acao_url text,
  lida boolean DEFAULT false,
  lida_em timestamp with time zone,
  criado_em timestamp with time zone DEFAULT now(),
  atualizado_em timestamp with time zone DEFAULT now()
);
```

### 14. **logs_auditoria** - Logs de Auditoria
```sql
CREATE TABLE public.logs_auditoria (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  usuario_id uuid,
  acao character varying NOT NULL,
  detalhe text NOT NULL,
  dados_antigos jsonb,
  dados_novos jsonb,
  ip_address inet,
  user_agent text,
  criado_em timestamp with time zone DEFAULT now()
);
```

### 15. **logs_historico** - Histórico de Mudanças
```sql
CREATE TABLE public.logs_historico (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  jovem_id uuid,
  user_id uuid,
  acao text NOT NULL,
  detalhe text,
  dados_anteriores jsonb,
  dados_novos jsonb,
  created_at timestamp with time zone DEFAULT now()
);
```

### 16. **sessoes_usuario** - Controle de Sessões
```sql
CREATE TABLE public.sessoes_usuario (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  usuario_id uuid NOT NULL,
  token_hash character varying NOT NULL,
  expira_em timestamp with time zone NOT NULL,
  ativo boolean DEFAULT true,
  ip_address inet,
  user_agent text,
  criado_em timestamp with time zone DEFAULT now(),
  atualizado_em timestamp with time zone DEFAULT now()
);
```

### 17. **configuracoes_sistema** - Configurações
```sql
CREATE TABLE public.configuracoes_sistema (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  chave character varying NOT NULL,
  valor jsonb NOT NULL,
  categoria character varying DEFAULT 'geral',
  descricao text,
  criado_em timestamp with time zone DEFAULT now(),
  atualizado_em timestamp with time zone DEFAULT now()
);
```

### 18. **jovens_view** - View para Relatórios
```sql
CREATE TABLE public.jovens_view (
  -- Campos derivados da tabela jovens para relatórios
  id uuid,
  nome_completo text,
  data_nasc date,
  idade integer,
  aprovado intellimen_aprovado_enum,
  -- Dados geográficos
  estado_id uuid,
  bloco_id uuid,
  regiao_id uuid,
  igreja_id uuid,
  -- Dados de contato
  numero_whatsapp text,
  foto text,
  -- Dados espirituais
  tempo_igreja text,
  batizado_aguas boolean,
  data_batismo_aguas date,
  batizado_es boolean,
  data_batismo_es date,
  -- Experiência
  disposto_servir boolean,
  ja_obra_altar boolean,
  ja_obreiro boolean,
  ja_colaborador boolean,
  afastado boolean,
  data_afastamento date,
  data_retorno date,
  -- Informações familiares
  pais_na_igreja boolean,
  familiares_igreja boolean,
  observacao_pais text,
  -- Dados adicionais
  deseja_altar boolean,
  observacao text,
  testemunho text,
  -- Redes sociais
  link_instagram text,
  link_facebook text,
  link_tiktok text,
  observacao_redes text,
  -- Sistema
  edicao text,
  data_cadastro timestamp with time zone
);
```

---

## ⚙️ Functions RPC

### **Sistema de Aprovações**

#### `aprovar_jovem_multiplo(p_jovem_id, p_tipo_aprovacao, p_observacao)`
- **Função**: Aprova jovem com sistema de múltiplas aprovações
- **Parâmetros**: 
  - `p_jovem_id`: UUID do jovem
  - `p_tipo_aprovacao`: 'pre_aprovado' ou 'aprovado'
  - `p_observacao`: Observação opcional
- **Retorno**: JSON com status da operação

#### `buscar_aprovacoes_jovem(p_jovem_id)`
- **Função**: Busca todas as aprovações de um jovem
- **Parâmetros**: `p_jovem_id` (UUID)
- **Retorno**: Lista de aprovações com dados do usuário

#### `remover_aprovacao_admin(p_aprovacao_id)`
- **Função**: Remove aprovação (apenas administradores)
- **Parâmetros**: `p_aprovacao_id` (UUID)
- **Retorno**: JSON com status da operação

### **Sistema de Notificações**

#### `notificar_evento_jovem(p_jovem_id, p_tipo, p_titulo, p_mensagem, p_remetente_id, p_acao_url)`
- **Função**: Cria notificação para líderes relacionados ao jovem
- **Parâmetros**: Dados da notificação
- **Retorno**: Número de notificações criadas

#### `notificar_associacao_jovem(p_jovem_id, p_usuario_associado_id, p_titulo, p_mensagem, p_acao_url)`
- **Função**: Notifica sobre associação de jovem a usuário
- **Parâmetros**: Dados da associação
- **Retorno**: Número de notificações criadas

#### `obter_lideres_para_notificacao(p_estado_id, p_bloco_id, p_regiao_id, p_igreja_id)`
- **Função**: Retorna IDs dos líderes que devem ser notificados
- **Parâmetros**: Localização geográfica
- **Retorno**: Lista de user_ids

### **Sistema de Usuários**

#### `atualizar_usuario_admin(p_usuario_id, p_nome, p_email, p_sexo, p_foto, p_nivel, p_ativo)`
- **Função**: Atualiza dados do usuário (apenas administradores)
- **Parâmetros**: Dados do usuário
- **Retorno**: JSON com status da operação

#### `atribuir_papel_usuario(p_usuario_id, p_role_id, p_estado_id, p_bloco_id, p_regiao_id, p_igreja_id)`
- **Função**: Atribui papel a usuário
- **Parâmetros**: IDs do usuário, papel e escopo geográfico
- **Retorno**: JSON com status da operação

#### `remover_papel_usuario(p_papel_id)`
- **Função**: Remove papel de usuário
- **Parâmetros**: `p_papel_id` (UUID)
- **Retorno**: JSON com status da operação

#### `buscar_papeis_disponiveis()`
- **Função**: Lista todos os papéis disponíveis
- **Retorno**: Lista de papéis com hierarquia

#### `buscar_papeis_usuario(p_usuario_id)`
- **Função**: Lista papéis de um usuário
- **Parâmetros**: `p_usuario_id` (UUID)
- **Retorno**: Lista de papéis do usuário

### **Sistema de Acesso**

#### `can_access_jovem(jovem_estado_id, jovem_bloco_id, jovem_regiao_id, jovem_igreja_id)`
- **Função**: Verifica se usuário pode acessar jovem
- **Parâmetros**: Localização do jovem
- **Retorno**: Boolean

#### `can_access_viagem_by_level(jovem_estado_id, jovem_bloco_id, jovem_regiao_id, jovem_igreja_id)`
- **Função**: Verifica acesso a dados de viagem
- **Parâmetros**: Localização do jovem
- **Retorno**: Boolean

#### `get_user_hierarchy_level()`
- **Função**: Retorna nível hierárquico do usuário atual
- **Retorno**: Integer (1-8)

#### `get_user_roles()`
- **Função**: Retorna papéis do usuário atual
- **Retorno**: Lista de papéis com escopo geográfico

### **Sistema de Estatísticas**

#### `get_jovens_por_estado_count(p_edicao_id)`
- **Função**: Conta jovens por estado
- **Parâmetros**: `p_edicao_id` (opcional)
- **Retorno**: Lista de estados com contagem

#### `obter_estatisticas_sistema()`
- **Função**: Retorna estatísticas gerais do sistema
- **Retorno**: JSON com estatísticas

#### `estatisticas_acesso_usuarios()`
- **Função**: Estatísticas de acesso dos usuários
- **Retorno**: JSON com dados de acesso

#### `buscar_usuarios_com_ultimo_acesso()`
- **Função**: Lista usuários com dados de último acesso
- **Retorno**: Lista de usuários com status de acesso

### **Sistema de Auditoria**

#### `criar_log_auditoria(p_usuario_id, p_acao, p_detalhe, p_dados_antigos, p_dados_novos)`
- **Função**: Cria log de auditoria
- **Parâmetros**: Dados do log
- **Retorno**: UUID do log criado

#### `registrar_ultimo_acesso()`
- **Função**: Registra último acesso do usuário
- **Retorno**: Void

#### `registrar_acesso_manual(p_usuario_id)`
- **Função**: Registra acesso manual (administradores)
- **Parâmetros**: `p_usuario_id` (UUID)
- **Retorno**: JSON com status

### **Sistema de Limpeza**

#### `limpar_logs_antigos(dias_retencao)`
- **Função**: Remove logs antigos
- **Parâmetros**: `dias_retencao` (integer, padrão 90)
- **Retorno**: Número de logs removidos

#### `limpar_notificacoes_antigas()`
- **Função**: Remove notificações antigas
- **Retorno**: Número de notificações removidas

#### `limpar_acessos_antigos(dias_para_manter)`
- **Função**: Limpa dados de acesso antigos
- **Parâmetros**: `dias_para_manter` (integer, padrão 365)
- **Retorno**: Número de usuários afetados

### **Sistema de Sincronização**

#### `sincronizar_nivel_com_papeis(p_usuario_id)`
- **Função**: Sincroniza nível do usuário com seus papéis
- **Parâmetros**: `p_usuario_id` (UUID)
- **Retorno**: JSON com resultado da sincronização

#### `atualizar_status_jovem(p_jovem_id)`
- **Função**: Atualiza status de aprovação do jovem
- **Parâmetros**: `p_jovem_id` (UUID)
- **Retorno**: Void

### **Sistema de Verificação**

#### `usuario_ja_aprovou(p_jovem_id, p_tipo_aprovacao)`
- **Função**: Verifica se usuário já aprovou jovem
- **Parâmetros**: IDs do jovem e tipo de aprovação
- **Retorno**: Boolean

#### `verificar_integridade_funcoes()`
- **Função**: Verifica integridade das functions
- **Retorno**: JSON com status das functions

#### `test_access_simple()`
- **Função**: Teste simples de acesso
- **Retorno**: String com informações do usuário

---

## 🛡️ Policies RLS

### **Tabela `jovens`**
```sql
-- Política para visualização baseada em hierarquia
CREATE POLICY "jovens_select_policy" ON public.jovens
FOR SELECT USING (can_access_jovem(estado_id, bloco_id, regiao_id, igreja_id));

-- Política para inserção (colaboradores podem inserir)
CREATE POLICY "jovens_insert_policy" ON public.jovens
FOR INSERT WITH CHECK (
  auth.uid() IS NOT NULL AND
  (SELECT nivel FROM public.usuarios WHERE id_auth = auth.uid()) IN 
  ('administrador', 'colaborador', 'lider_nacional_iurd', 'lider_nacional_fju')
);

-- Política para atualização
CREATE POLICY "jovens_update_policy" ON public.jovens
FOR UPDATE USING (can_access_jovem(estado_id, bloco_id, regiao_id, igreja_id));

-- Política para exclusão (apenas administradores)
CREATE POLICY "jovens_delete_policy" ON public.jovens
FOR DELETE USING (
  (SELECT nivel FROM public.usuarios WHERE id_auth = auth.uid()) = 'administrador'
);
```

### **Tabela `avaliacoes`**
```sql
-- Política para visualização
CREATE POLICY "avaliacoes_select_policy" ON public.avaliacoes
FOR SELECT USING (
  auth.uid() IS NOT NULL AND
  (SELECT nivel FROM public.usuarios WHERE id_auth = auth.uid()) IN 
  ('administrador', 'lider_nacional_iurd', 'lider_nacional_fju', 'colaborador')
);

-- Política para inserção
CREATE POLICY "avaliacoes_insert_policy" ON public.avaliacoes
FOR INSERT WITH CHECK (
  auth.uid() IS NOT NULL AND
  user_id = (SELECT id FROM public.usuarios WHERE id_auth = auth.uid())
);
```

### **Tabela `usuarios`**
```sql
-- Política para visualização (usuários podem ver outros baseado em hierarquia)
CREATE POLICY "usuarios_select_policy" ON public.usuarios
FOR SELECT USING (
  auth.uid() IS NOT NULL AND
  (SELECT nivel FROM public.usuarios WHERE id_auth = auth.uid()) IN 
  ('administrador', 'lider_nacional_iurd', 'lider_nacional_fju', 'colaborador')
);

-- Política para atualização (usuários podem editar próprio perfil)
CREATE POLICY "usuarios_update_own_policy" ON public.usuarios
FOR UPDATE USING (
  id_auth = auth.uid()
) WITH CHECK (
  id_auth = auth.uid()
);
```

### **Tabela `dados_viagem`**
```sql
-- Política para visualização
CREATE POLICY "dados_viagem_select_policy" ON public.dados_viagem
FOR SELECT USING (can_access_viagem_by_level(
  (SELECT estado_id FROM public.jovens WHERE id = jovem_id),
  (SELECT bloco_id FROM public.jovens WHERE id = jovem_id),
  (SELECT regiao_id FROM public.jovens WHERE id = jovem_id),
  (SELECT igreja_id FROM public.jovens WHERE id = jovem_id)
));

-- Política para inserção/atualização
CREATE POLICY "dados_viagem_upsert_policy" ON public.dados_viagem
FOR ALL USING (
  auth.uid() IS NOT NULL AND
  usuario_id = (SELECT id FROM public.usuarios WHERE id_auth = auth.uid())
);
```

### **Tabela `notificacoes`**
```sql
-- Política para visualização (usuários veem apenas suas notificações)
CREATE POLICY "notificacoes_select_policy" ON public.notificacoes
FOR SELECT USING (
  destinatario_id = (SELECT id FROM public.usuarios WHERE id_auth = auth.uid())
);

-- Política para atualização (marcar como lida)
CREATE POLICY "notificacoes_update_policy" ON public.notificacoes
FOR UPDATE USING (
  destinatario_id = (SELECT id FROM public.usuarios WHERE id_auth = auth.uid())
);
```

---

## 📁 Storage Buckets

### **Buckets Configurados**

| Bucket | Tipo | Política | Uso |
|--------|------|----------|-----|
| `fotos_jovens` | Public | Granular | Fotos dos jovens |
| `fotos_usuarios` | Public | Granular | Fotos dos usuários |
| `viagens` | Public | Granular | Comprovantes de viagem |
| `documentos` | Private | Restrito | Documentos gerais |
| `backups` | Private | Admin | Backups do sistema |
| `temp` | Private | Temporário | Arquivos temporários |

### **Policies de Storage**

#### **Bucket `fotos_jovens`**
```sql
-- Upload permitido para usuários autenticados
CREATE POLICY "Allow upload fotos_jovens for authenticated users" 
ON storage.objects FOR INSERT 
WITH CHECK (bucket_id = 'fotos_jovens');

-- Visualização permitida para usuários autenticados
CREATE POLICY "Allow select fotos_jovens for authenticated users" 
ON storage.objects FOR SELECT 
USING (bucket_id = 'fotos_jovens');

-- Atualização permitida para usuários autenticados
CREATE POLICY "Allow update fotos_jovens for authenticated users" 
ON storage.objects FOR UPDATE 
USING (bucket_id = 'fotos_jovens')
WITH CHECK (bucket_id = 'fotos_jovens');

-- Exclusão permitida para usuários autenticados
CREATE POLICY "Allow delete fotos_jovens for authenticated users" 
ON storage.objects FOR DELETE 
USING (bucket_id = 'fotos_jovens');
```

#### **Bucket `fotos_usuarios`**
```sql
-- Acesso total para usuários autenticados
CREATE POLICY "Allow all fotos_usuarios for authenticated users" 
ON storage.objects FOR ALL 
USING (bucket_id = 'fotos_usuarios')
WITH CHECK (bucket_id = 'fotos_usuarios');
```

#### **Bucket `viagens`**
```sql
-- Acesso total para usuários autenticados
CREATE POLICY "Allow all for authenticated users" 
ON storage.objects FOR ALL 
USING (bucket_id = 'viagens')
WITH CHECK (bucket_id = 'viagens');
```

---

## 🏗️ Hierarquia de Permissões

### **Níveis Hierárquicos (1-8)**

| Nível | Papel | Descrição | Permissões |
|-------|-------|-----------|------------|
| 1 | `administrador` | Administrador do sistema | Acesso total |
| 2 | `lider_nacional_iurd` | Líder nacional IURD | Visão nacional |
| 2 | `lider_nacional_fju` | Líder nacional FJU | Visão nacional |
| 3 | `lider_estadual_iurd` | Líder estadual IURD | Visão estadual |
| 3 | `lider_estadual_fju` | Líder estadual FJU | Visão estadual |
| 4 | `lider_bloco_iurd` | Líder de bloco IURD | Visão de bloco |
| 4 | `lider_bloco_fju` | Líder de bloco FJU | Visão de bloco |
| 5 | `lider_regional_iurd` | Líder regional IURD | Visão regional |
| 6 | `lider_igreja_iurd` | Líder de igreja IURD | Visão de igreja |
| 7 | `colaborador` | Colaborador | Apenas jovens cadastrados |
| 8 | `jovem` | Jovem | Apenas próprios dados |

### **Escopo Geográfico**

```
Brasil
├── Estados (lider_estadual)
│   ├── Blocos (lider_bloco)
│   │   ├── Regiões (lider_regional)
│   │   │   └── Igrejas (lider_igreja)
│   │   │       └── Jovens
```

### **Regras de Acesso**

1. **Administradores**: Acesso total ao sistema
2. **Líderes Nacionais**: Visão nacional, podem ver todos os dados
3. **Líderes Estaduais**: Visão do estado, podem ver dados do estado
4. **Líderes de Bloco**: Visão do bloco, podem ver dados do bloco
5. **Líderes Regionais**: Visão da região, podem ver dados da região
6. **Líderes de Igreja**: Visão da igreja, podem ver dados da igreja
7. **Colaboradores**: Apenas jovens que cadastraram
8. **Jovens**: Apenas seus próprios dados

---

## 🔗 Relacionamentos

### **Diagrama de Relacionamentos**

```
usuarios (1) ←→ (N) user_roles (N) ←→ (1) roles
    ↓
    ↓ (1)
    ↓
jovens (N) ←→ (1) estados
    ↓ (N) ←→ (1) blocos
    ↓ (N) ←→ (1) regioes
    ↓ (N) ←→ (1) igrejas
    ↓ (N) ←→ (1) edicoes

jovens (1) ←→ (N) avaliacoes
jovens (1) ←→ (N) aprovacoes_jovens
jovens (1) ←→ (N) dados_viagem
jovens (1) ←→ (N) notificacoes
```

### **Foreign Keys Principais**

- `jovens.usuario_id` → `usuarios.id`
- `jovens.estado_id` → `estados.id`
- `jovens.bloco_id` → `blocos.id`
- `jovens.regiao_id` → `regioes.id`
- `jovens.igreja_id` → `igrejas.id`
- `jovens.edicao_id` → `edicoes.id`
- `avaliacoes.jovem_id` → `jovens.id`
- `avaliacoes.user_id` → `usuarios.id`
- `aprovacoes_jovens.jovem_id` → `jovens.id`
- `aprovacoes_jovens.usuario_id` → `usuarios.id`
- `dados_viagem.jovem_id` → `jovens.id`
- `dados_viagem.edicao_id` → `edicoes.id`
- `user_roles.user_id` → `usuarios.id`
- `user_roles.role_id` → `roles.id`

---

## 🔧 Guia de Manutenção

### **Backup e Restauração**

#### **Backup Completo**
```sql
-- Backup de todas as tabelas
pg_dump -h [host] -U [user] -d [database] > backup_completo.sql

-- Backup apenas dados
pg_dump -h [host] -U [user] -d [database] --data-only > backup_dados.sql

-- Backup apenas estrutura
pg_dump -h [host] -U [user] -d [database] --schema-only > backup_estrutura.sql
```

#### **Backup de Functions**
```sql
-- Exportar todas as functions
SELECT routine_name, routine_definition 
FROM information_schema.routines 
WHERE routine_schema = 'public';
```

### **Monitoramento de Performance**

#### **Queries Mais Lentas**
```sql
-- Identificar queries lentas
SELECT query, mean_time, calls, total_time
FROM pg_stat_statements
ORDER BY mean_time DESC
LIMIT 10;
```

#### **Índices Recomendados**
```sql
-- Índices para performance
CREATE INDEX IF NOT EXISTS idx_jovens_estado_id ON public.jovens(estado_id);
CREATE INDEX IF NOT EXISTS idx_jovens_bloco_id ON public.jovens(bloco_id);
CREATE INDEX IF NOT EXISTS idx_jovens_regiao_id ON public.jovens(regiao_id);
CREATE INDEX IF NOT EXISTS idx_jovens_igreja_id ON public.jovens(igreja_id);
CREATE INDEX IF NOT EXISTS idx_jovens_aprovado ON public.jovens(aprovado);
CREATE INDEX IF NOT EXISTS idx_avaliacoes_jovem_id ON public.avaliacoes(jovem_id);
CREATE INDEX IF NOT EXISTS idx_notificacoes_destinatario ON public.notificacoes(destinatario_id);
CREATE INDEX IF NOT EXISTS idx_logs_auditoria_criado_em ON public.logs_auditoria(criado_em);
```

### **Limpeza de Dados**

#### **Limpeza Automática**
```sql
-- Executar limpeza de logs antigos (90 dias)
SELECT limpar_logs_antigos(90);

-- Executar limpeza de notificações antigas (30 dias)
SELECT limpar_notificacoes_antigas();

-- Executar limpeza de acessos antigos (365 dias)
SELECT limpar_acessos_antigos(365);
```

#### **Manutenção de Storage**
```sql
-- Verificar tamanho dos buckets
SELECT bucket_id, count(*), sum(octet_length(decode(encode, 'base64')))
FROM storage.objects
GROUP BY bucket_id;
```

### **Troubleshooting**

#### **Problemas Comuns**

1. **Erro de Permissão RLS**
   - Verificar se policies estão ativas
   - Verificar se usuário tem role correto
   - Verificar se `can_access_jovem` retorna true

2. **Erro de Upload de Arquivo**
   - Verificar se bucket existe
   - Verificar policies de storage
   - Verificar tamanho do arquivo

3. **Erro de Function RPC**
   - Verificar se function existe
   - Verificar parâmetros corretos
   - Verificar permissões do usuário

#### **Logs de Debug**
```sql
-- Ativar logs de RLS
SET log_statement = 'all';
SET log_min_duration_statement = 0;

-- Verificar policies ativas
SELECT schemaname, tablename, policyname, permissive, roles, cmd, qual
FROM pg_policies
WHERE schemaname = 'public'
ORDER BY tablename, policyname;
```

### **Atualizações de Schema**

#### **Migração Segura**
```sql
-- 1. Backup antes da migração
-- 2. Testar em ambiente de desenvolvimento
-- 3. Executar migração em horário de baixo uso
-- 4. Verificar integridade após migração
-- 5. Monitorar performance
```

#### **Versionamento de Functions**
```sql
-- Adicionar comentário com versão
COMMENT ON FUNCTION public.aprovar_jovem_multiplo IS 'v1.2.0 - Sistema de aprovações múltiplas';

-- Verificar versões
SELECT routine_name, obj_description(oid) as version
FROM pg_proc p
JOIN pg_namespace n ON p.pronamespace = n.oid
WHERE n.nspname = 'public' AND routine_name LIKE '%jovem%';
```

---

## 📞 Suporte e Contato

Para dúvidas sobre a estrutura do sistema ou implementação de novas funcionalidades, consulte:

1. **Documentação do Supabase**: https://supabase.com/docs
2. **Documentação do PostgreSQL**: https://www.postgresql.org/docs/
3. **Logs de Auditoria**: Tabela `logs_auditoria` para rastreamento de mudanças
4. **Functions de Debug**: `test_access_simple()`, `verificar_integridade_funcoes()`

---

**Última atualização**: $(date)
**Versão do documento**: 1.0.0
**Sistema**: Campus IntelliMen - Sistema de Gerenciamento de Jovens
