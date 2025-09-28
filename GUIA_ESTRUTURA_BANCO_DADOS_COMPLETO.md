# Guia Completo da Estrutura do Banco de Dados - Campus IntelliMen

## 📋 Índice
1. [Visão Geral](#visão-geral)
2. [Tabelas do Sistema](#tabelas-do-sistema)
3. [Functions RPC](#functions-rpc)
4. [Policies RLS](#policies-rls)
5. [Hierarquia de Permissões](#hierarquia-de-permissões)
6. [Relacionamentos](#relacionamentos)
7. [Guia de Manutenção](#guia-de-manutenção)

---

## 🎯 Visão Geral

Sistema de gerenciamento e avaliação de jovens com arquitetura robusta baseada em:
- **PostgreSQL** com Supabase
- **Sistema hierárquico** de 8 níveis de permissão
- **Storage** para arquivos e documentos
- **Sistema de notificações** automatizado
- **Auditoria completa** de ações

---

## 📊 Tabelas do Sistema

### 1. **aprovacoes_jovens** - Sistema de Aprovações
```sql
CREATE TABLE public.aprovacoes_jovens (
  atualizado_em timestamp with time zone DEFAULT now(),
  tipo_aprovacao text NOT NULL,
  observacao text,
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  jovem_id uuid NOT NULL,
  usuario_id uuid NOT NULL,
  criado_em timestamp with time zone DEFAULT now()
);
```
**Propósito**: Controla aprovações múltiplas de jovens por diferentes usuários
**Campos Principais**: `jovem_id`, `usuario_id`, `tipo_aprovacao`, `observacao`

### 2. **avaliacoes** - Sistema de Avaliações
```sql
CREATE TABLE public.avaliacoes (
  disposicao USER-DEFINED,
  caractere USER-DEFINED,
  espirito USER-DEFINED,
  user_id uuid,
  jovem_id uuid,
  avaliacao_texto text,
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  data timestamp without time zone DEFAULT now(),
  criado_em timestamp with time zone DEFAULT now(),
  nota integer
);
```
**Propósito**: Armazena avaliações dos jovens com notas e comentários
**Campos Principais**: `jovem_id`, `user_id`, `nota`, `avaliacao_texto`

### 3. **blocos** - Estrutura Geográfica
```sql
CREATE TABLE public.blocos (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  nome text NOT NULL,
  estado_id uuid
);
```
**Propósito**: Organização geográfica por blocos dentro dos estados
**Campos Principais**: `nome`, `estado_id`

### 4. **configuracoes_sistema** - Configurações
```sql
CREATE TABLE public.configuracoes_sistema (
  categoria character varying DEFAULT 'geral'::character varying,
  descricao text,
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  atualizado_em timestamp with time zone DEFAULT now(),
  chave character varying NOT NULL,
  criado_em timestamp with time zone DEFAULT now(),
  valor jsonb NOT NULL
);
```
**Propósito**: Configurações gerais do sistema
**Campos Principais**: `chave`, `valor`, `categoria`

### 5. **dados_viagem** - Dados de Viagem
```sql
CREATE TABLE public.dados_viagem (
  edicao_id uuid NOT NULL,
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  comprovante_pagamento text,
  atualizado_em timestamp with time zone NOT NULL DEFAULT now(),
  comprovante_passagem_ida text,
  data_cadastro timestamp with time zone NOT NULL DEFAULT now(),
  data_passagem_volta timestamp with time zone,
  data_passagem_ida timestamp with time zone,
  pagou_despesas boolean NOT NULL DEFAULT false,
  jovem_id uuid NOT NULL,
  comprovante_passagem_volta text,
  usuario_id uuid
);
```
**Propósito**: Controle de dados de viagem dos jovens
**Campos Principais**: `jovem_id`, `edicao_id`, `comprovante_pagamento`, `data_passagem_ida`

### 6. **edicoes** - Edições do Campus
```sql
CREATE TABLE public.edicoes (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  numero integer NOT NULL,
  ativa boolean DEFAULT true,
  data_fim date,
  nome text NOT NULL,
  data_inicio date,
  criado_em timestamp with time zone DEFAULT now()
);
```
**Propósito**: Controle de edições do Campus IntelliMen
**Campos Principais**: `numero`, `nome`, `data_inicio`, `data_fim`, `ativa`

### 7. **estados** - Estados Brasileiros
```sql
CREATE TABLE public.estados (
  sigla text NOT NULL,
  nome text NOT NULL,
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  bandeira text
);
```
**Propósito**: Cadastro de estados brasileiros
**Campos Principais**: `nome`, `sigla`, `bandeira`

### 8. **igrejas** - Igrejas Locais
```sql
CREATE TABLE public.igrejas (
  nome text NOT NULL,
  regiao_id uuid,
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  endereco text
);
```
**Propósito**: Cadastro de igrejas locais
**Campos Principais**: `nome`, `endereco`, `regiao_id`

### 9. **jovens** - Dados dos Jovens
```sql
CREATE TABLE public.jovens (
  foi_obreiro boolean,
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  estado_id uuid,
  bloco_id uuid,
  regiao_id uuid,
  igreja_id uuid,
  data_nasc date NOT NULL,
  data_cadastro timestamp with time zone DEFAULT now(),
  namora boolean,
  tem_filho boolean,
  trabalha boolean,
  tem_dividas boolean,
  batizado_aguas boolean,
  data_batismo_aguas date,
  batizado_es boolean,
  data_batismo_es date,
  disposto_servir boolean,
  ja_obra_altar boolean,
  ja_obreiro boolean,
  ja_colaborador boolean,
  afastado boolean,
  data_afastamento date,
  data_retorno date,
  pais_na_igreja boolean,
  familiares_igreja boolean,
  deseja_altar boolean,
  aprovado USER-DEFINED DEFAULT 'null'::intellimen_aprovado_enum,
  cresceu_na_igreja boolean,
  experiencia_altar boolean,
  foi_colaborador boolean,
  afastou boolean,
  quando_afastou date,
  quando_voltou date,
  pais_sao_igreja boolean,
  edicao_id uuid,
  idade integer,
  formado_intellimen boolean DEFAULT false,
  fazendo_desafios boolean DEFAULT false,
  valor_divida numeric,
  usuario_id uuid,
  tempo_igreja text,
  motivo_afastou text,
  condicao text,
  tempo_condicao text,
  responsabilidade_igreja text,
  obs_pais text,
  observacao_text text,
  testemunho_text text,
  motivo_afastamento text,
  sexo text,
  observacao_redes text,
  observacao_pais text,
  observacao text,
  testemunho text,
  instagram text,
  facebook text,
  tiktok text,
  obs_redes text,
  edicao text NOT NULL,
  foto text,
  nome_completo text NOT NULL,
  whatsapp text,
  qual_desafio text,
  pastor_que_indicou text,
  estado_civil text,
  condicao_campus text,
  local_trabalho text,
  escolaridade text,
  formacao text
);
```
**Propósito**: Dados completos dos jovens cadastrados
**Campos Principais**: `nome_completo`, `data_nasc`, `aprovado`, `estado_id`, `bloco_id`, `regiao_id`, `igreja_id`

### 10. **jovens_view** - View dos Jovens
```sql
CREATE TABLE public.jovens_view (
  data_nasc date,
  testemunho text,
  link_instagram text,
  link_facebook text,
  link_tiktok text,
  estado_id uuid,
  bloco_id uuid,
  regiao_id uuid,
  igreja_id uuid,
  idade integer,
  aprovado USER-DEFINED,
  data_retorno date,
  deseja_altar boolean,
  familiares_igreja boolean,
  pais_na_igreja boolean,
  id uuid,
  observacao_redes text,
  data_afastamento date,
  afastado boolean,
  ja_colaborador boolean,
  ja_obreiro boolean,
  ja_obra_altar boolean,
  edicao text,
  foto text,
  nome_completo text,
  numero_whatsapp text,
  estado_civil text,
  disposto_servir boolean,
  data_batismo_es date,
  batizado_es boolean,
  local_trabalho text,
  escolaridade text,
  formacao text,
  data_batismo_aguas date,
  tempo_igreja text,
  batizado_aguas boolean,
  condicao text,
  tempo_condicao text,
  responsabilidade_igreja text,
  tem_dividas boolean,
  trabalha boolean,
  tem_filho boolean,
  motivo_afastamento text,
  namora boolean,
  observacao_pais text,
  data_cadastro timestamp with time zone,
  observacao text
);
```
**Propósito**: View otimizada para consultas dos jovens
**Campos Principais**: Mesmos campos da tabela `jovens` com nomes padronizados

### 11. **logs_auditoria** - Logs de Auditoria
```sql
CREATE TABLE public.logs_auditoria (
  detalhe text NOT NULL,
  dados_antigos jsonb,
  dados_novos jsonb,
  ip_address inet,
  criado_em timestamp with time zone DEFAULT now(),
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  usuario_id uuid,
  user_agent text,
  acao character varying NOT NULL
);
```
**Propósito**: Log completo de todas as ações do sistema
**Campos Principais**: `usuario_id`, `acao`, `detalhe`, `dados_antigos`, `dados_novos`

### 12. **logs_historico** - Histórico de Alterações
```sql
CREATE TABLE public.logs_historico (
  detalhe text,
  acao text NOT NULL,
  jovem_id uuid,
  user_id uuid,
  created_at timestamp with time zone DEFAULT now(),
  dados_novos jsonb,
  dados_anteriores jsonb,
  id uuid NOT NULL DEFAULT gen_random_uuid()
);
```
**Propósito**: Histórico específico de alterações nos jovens
**Campos Principais**: `jovem_id`, `user_id`, `acao`, `dados_anteriores`, `dados_novos`

### 13. **notificacoes** - Sistema de Notificações
```sql
CREATE TABLE public.notificacoes (
  titulo character varying NOT NULL,
  mensagem text NOT NULL,
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  destinatario_id uuid NOT NULL,
  remetente_id uuid,
  jovem_id uuid,
  lida boolean DEFAULT false,
  lida_em timestamp with time zone,
  criado_em timestamp with time zone DEFAULT now(),
  atualizado_em timestamp with time zone DEFAULT now(),
  acao_url text,
  tipo character varying NOT NULL
);
```
**Propósito**: Sistema de notificações entre usuários
**Campos Principais**: `destinatario_id`, `titulo`, `mensagem`, `tipo`, `lida`

### 14. **regioes** - Regiões
```sql
CREATE TABLE public.regioes (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  nome text NOT NULL,
  bloco_id uuid
);
```
**Propósito**: Organização geográfica por regiões dentro dos blocos
**Campos Principais**: `nome`, `bloco_id`

### 15. **roles** - Papéis do Sistema
```sql
CREATE TABLE public.roles (
  nivel_hierarquico integer NOT NULL,
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  descricao text,
  criado_em timestamp with time zone DEFAULT now(),
  slug text NOT NULL,
  nome text NOT NULL
);
```
**Propósito**: Definição dos papéis e níveis hierárquicos
**Campos Principais**: `nome`, `slug`, `nivel_hierarquico`, `descricao`

### 16. **sessoes_usuario** - Controle de Sessões
```sql
CREATE TABLE public.sessoes_usuario (
  expira_em timestamp with time zone NOT NULL,
  atualizado_em timestamp with time zone DEFAULT now(),
  criado_em timestamp with time zone DEFAULT now(),
  ativo boolean DEFAULT true,
  ip_address inet,
  usuario_id uuid NOT NULL,
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  user_agent text,
  token_hash character varying NOT NULL
);
```
**Propósito**: Controle de sessões ativas dos usuários
**Campos Principais**: `usuario_id`, `token_hash`, `expira_em`, `ativo`

### 17. **user_roles** - Papéis dos Usuários
```sql
CREATE TABLE public.user_roles (
  igreja_id uuid,
  estado_id uuid,
  bloco_id uuid,
  role_id uuid,
  ativo boolean DEFAULT true,
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  regiao_id uuid,
  criado_em timestamp with time zone DEFAULT now(),
  criado_por uuid,
  user_id uuid
);
```
**Propósito**: Associação de papéis aos usuários com escopo geográfico
**Campos Principais**: `user_id`, `role_id`, `estado_id`, `bloco_id`, `regiao_id`, `igreja_id`

### 18. **usuarios** - Usuários do Sistema
```sql
CREATE TABLE public.usuarios (
  criado_em timestamp with time zone DEFAULT now(),
  igreja_id uuid,
  regiao_id uuid,
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  id_auth uuid,
  estado_id uuid,
  nivel text NOT NULL,
  sexo text,
  nome text NOT NULL,
  foto text,
  estado_bandeira text,
  email text,
  bloco_id uuid,
  ultimo_acesso timestamp with time zone,
  ativo boolean DEFAULT true
);
```
**Propósito**: Cadastro de usuários do sistema
**Campos Principais**: `nome`, `email`, `nivel`, `estado_id`, `bloco_id`, `regiao_id`, `igreja_id`

---

## ⚙️ Functions RPC

### **Sistema de Aprovações**

#### `aprovar_jovem_multiplo(p_jovem_id, p_tipo_aprovacao, p_observacao)`
**Propósito**: Aprovar jovem com múltiplas aprovações
**Parâmetros**: 
- `p_jovem_id`: ID do jovem
- `p_tipo_aprovacao`: 'pre_aprovado' ou 'aprovado'
- `p_observacao`: Observação da aprovação
**Retorno**: JSON com status da operação

#### `buscar_aprovacoes_jovem(p_jovem_id)`
**Propósito**: Buscar histórico de aprovações de um jovem
**Parâmetros**: `p_jovem_id`: ID do jovem
**Retorno**: Tabela com aprovações e dados dos usuários

#### `atualizar_status_jovem(p_jovem_id)`
**Propósito**: Atualizar status de aprovação do jovem baseado nas aprovações
**Parâmetros**: `p_jovem_id`: ID do jovem
**Retorno**: Void (atualiza diretamente a tabela)

#### `remover_aprovacao_admin(p_aprovacao_id)`
**Propósito**: Remover aprovação (apenas administradores)
**Parâmetros**: `p_aprovacao_id`: ID da aprovação
**Retorno**: JSON com status da operação

### **Sistema de Usuários**

#### `atualizar_usuario_admin(p_usuario_id, p_nome, p_email, p_sexo, p_foto, p_nivel, p_ativo)`
**Propósito**: Atualizar dados de usuário
**Parâmetros**: Dados do usuário a serem atualizados
**Retorno**: JSON com status da operação

#### `atribuir_papel_usuario(p_usuario_id, p_role_id, p_estado_id, p_bloco_id, p_regiao_id, p_igreja_id)`
**Propósito**: Atribuir papel a usuário com escopo geográfico
**Parâmetros**: ID do usuário, papel e escopo geográfico
**Retorno**: JSON com status da operação

#### `buscar_papeis_disponiveis()`
**Propósito**: Listar todos os papéis disponíveis
**Retorno**: Tabela com papéis ordenados por nível hierárquico

#### `buscar_papeis_usuario(p_usuario_id)`
**Propósito**: Buscar papéis de um usuário específico
**Parâmetros**: `p_usuario_id`: ID do usuário
**Retorno**: Tabela com papéis do usuário

#### `buscar_usuarios_com_ultimo_acesso()`
**Propósito**: Listar usuários com informações de último acesso
**Retorno**: Tabela com usuários e status de acesso

### **Sistema de Acesso e Permissões**

#### `can_access_jovem(jovem_estado_id, jovem_bloco_id, jovem_regiao_id, jovem_igreja_id)`
**Propósito**: Verificar se usuário pode acessar jovem específico
**Parâmetros**: IDs geográficos do jovem
**Retorno**: Boolean

#### `can_access_viagem_by_level(jovem_estado_id, jovem_bloco_id, jovem_regiao_id, jovem_igreja_id)`
**Propósito**: Verificar acesso a dados de viagem
**Parâmetros**: IDs geográficos do jovem
**Retorno**: Boolean

#### `get_user_hierarchy_level()`
**Propósito**: Obter nível hierárquico do usuário atual
**Retorno**: Integer (menor número = maior privilégio)

#### `get_user_roles()`
**Propósito**: Obter papéis do usuário atual
**Retorno**: Tabela com papéis e escopo geográfico

#### `has_role(role_slug)`
**Propósito**: Verificar se usuário tem papel específico
**Parâmetros**: `role_slug`: Slug do papel
**Retorno**: Boolean

#### `is_admin_user()`
**Propósito**: Verificar se usuário é administrador
**Retorno**: Boolean

### **Sistema de Notificações**

#### `notificar_evento_jovem(p_jovem_id, p_tipo, p_titulo, p_mensagem, p_remetente_id, p_acao_url)`
**Propósito**: Notificar líderes sobre evento relacionado a jovem
**Parâmetros**: Dados da notificação
**Retorno**: Integer (número de notificações criadas)

#### `notificar_associacao_jovem(p_jovem_id, p_usuario_associado_id, p_titulo, p_mensagem, p_acao_url)`
**Propósito**: Notificar sobre associação de jovem
**Parâmetros**: Dados da notificação
**Retorno**: Integer (número de notificações criadas)

#### `obter_lideres_para_notificacao(p_estado_id, p_bloco_id, p_regiao_id, p_igreja_id)`
**Propósito**: Obter líderes que devem receber notificação
**Parâmetros**: IDs geográficos
**Retorno**: Tabela com IDs dos líderes

#### `criar_lembretes_avaliacao()`
**Propósito**: Criar lembretes automáticos para avaliação
**Retorno**: Void

### **Sistema de Dados**

#### `get_jovem_completo(p_jovem_id)`
**Propósito**: Obter dados completos de um jovem
**Parâmetros**: `p_jovem_id`: ID do jovem
**Retorno**: JSON com dados completos

#### `filtrar_jovens(filters)`
**Propósito**: Filtrar jovens com critérios específicos
**Parâmetros**: `filters`: JSON com filtros
**Retorno**: Tabela com jovens filtrados

#### `get_jovens_por_estado_count(p_edicao_id)`
**Propósito**: Contar jovens por estado
**Parâmetros**: `p_edicao_id`: ID da edição (opcional)
**Retorno**: Tabela com contagem por estado

#### `get_user_by_auth_id(auth_id)`
**Propósito**: Obter usuário por ID de autenticação
**Parâmetros**: `auth_id`: ID de autenticação
**Retorno**: Tabela com dados do usuário

### **Sistema de Estatísticas**

#### `obter_estatisticas_sistema()`
**Propósito**: Obter estatísticas gerais do sistema
**Retorno**: JSON com estatísticas

#### `estatisticas_acesso_usuarios()`
**Propósito**: Obter estatísticas de acesso dos usuários
**Retorno**: JSON com estatísticas de acesso

### **Sistema de Limpeza**

#### `limpar_logs_antigos(dias_retencao)`
**Propósito**: Limpar logs antigos
**Parâmetros**: `dias_retencao`: Dias para manter logs
**Retorno**: Integer (número de logs removidos)

#### `limpar_notificacoes_antigas()`
**Propósito**: Limpar notificações antigas
**Retorno**: Integer (número de notificações removidas)

#### `limpar_acessos_antigos(dias_para_manter)`
**Propósito**: Limpar acessos antigos
**Parâmetros**: `dias_para_manter`: Dias para manter acessos
**Retorno**: Integer (número de usuários afetados)

### **Sistema de Sincronização**

#### `sincronizar_nivel_com_papeis(p_usuario_id)`
**Propósito**: Sincronizar nível do usuário com seus papéis
**Parâmetros**: `p_usuario_id`: ID do usuário
**Retorno**: JSON com status da sincronização

#### `registrar_ultimo_acesso()`
**Propósito**: Registrar último acesso do usuário atual
**Retorno**: Void

#### `registrar_acesso_manual(p_usuario_id)`
**Propósito**: Registrar acesso manual (apenas administradores)
**Parâmetros**: `p_usuario_id`: ID do usuário
**Retorno**: JSON com status da operação

### **Sistema de Triggers**

#### `atualizar_timestamp()`
**Propósito**: Atualizar timestamp de modificação
**Retorno**: Trigger

#### `atualizar_timestamp_aprovacoes()`
**Propósito**: Atualizar timestamp de aprovações
**Retorno**: Trigger

#### `recalcular_idade()`
**Propósito**: Recalcular idade do jovem
**Retorno**: Trigger

#### `set_usuario_id_on_insert()`
**Propósito**: Definir usuário_id automaticamente
**Retorno**: Trigger

#### `set_usuario_id_dados_viagem()`
**Propósito**: Definir usuário_id em dados de viagem
**Retorno**: Trigger

#### `atribuir_papel_padrao_jovem()`
**Propósito**: Atribuir papel padrão 'jovem' a novos usuários
**Retorno**: Trigger

#### `criar_notificacao_automatica()`
**Propósito**: Criar notificações automáticas
**Retorno**: Trigger

#### `trigger_notificar_mudanca_status()`
**Propósito**: Notificar sobre mudança de status
**Retorno**: Trigger

#### `trigger_notificar_nova_avaliacao()`
**Propósito**: Notificar sobre nova avaliação
**Retorno**: Trigger

#### `trigger_notificar_novo_cadastro()`
**Propósito**: Notificar sobre novo cadastro
**Retorno**: Trigger

#### `trigger_registrar_acesso()`
**Propósito**: Registrar acesso automaticamente
**Retorno**: Trigger

#### `trigger_sincronizar_nivel()`
**Propósito**: Sincronizar nível automaticamente
**Retorno**: Trigger

### **Sistema de Testes**

#### `test_access_simple()`
**Propósito**: Teste simples de acesso
**Retorno**: Text com informações do usuário

#### `test_access_simple_return()`
**Propósito**: Teste simples de acesso (boolean)
**Retorno**: Boolean

#### `test_lider_nacional()`
**Propósito**: Teste de acesso de líder nacional
**Retorno**: Text com resultado do teste

#### `verificar_integridade_funcoes()`
**Propósito**: Verificar integridade das funções
**Retorno**: JSON com status das funções

### **Sistema de Logs**

#### `criar_log_auditoria(p_usuario_id, p_acao, p_detalhe, p_dados_antigos, p_dados_novos)`
**Propósito**: Criar log de auditoria
**Parâmetros**: Dados do log
**Retorno**: UUID do log criado

#### `usuario_ja_aprovou(p_jovem_id, p_tipo_aprovacao)`
**Propósito**: Verificar se usuário já aprovou jovem
**Parâmetros**: ID do jovem e tipo de aprovação
**Retorno**: Boolean

---

## 🛡️ Policies RLS

### **📋 Nota Importante sobre Policies Geográficas**

As tabelas geográficas (`blocos`, `regioes`, `igrejas`) possuem policies específicas que respeitam a hierarquia organizacional:

- **Administradores**: Acesso total a todas as operações
- **Líderes Nacionais**: Acesso total a todas as operações  
- **Líderes Estaduais**: Podem gerenciar blocos, regiões e igrejas do seu estado
- **Líderes de Bloco**: Podem gerenciar regiões e igrejas do seu bloco
- **Líderes Regionais**: Podem gerenciar igrejas da sua região
- **Outros níveis**: Apenas leitura

### **Tabela `aprovacoes_jovens`**
- **`allow_read_aprovacoes_jovens`**: Permite leitura para todos

### **Tabela `avaliacoes`**
- **`Allow all for admin`**: Administradores têm acesso total
- **`Allow insert for authenticated users`**: Usuários autenticados podem inserir
- **`Allow read based on hierarchy`**: Leitura baseada na hierarquia
- **`Allow update based on hierarchy`**: Atualização baseada na hierarquia
- **`allow_insert_avaliacoes`**: Inserção para usuários autenticados
- **`allow_read_avaliacoes_by_hierarchy`**: Leitura hierárquica complexa

### **Tabela `blocos`**
- **`blocos_select_all`**: Leitura para todos
- **`blocos_insert_admin`**: Inserção para administradores, líderes nacionais e líderes estaduais (do seu estado)
- **`blocos_update_admin`**: Atualização para administradores, líderes nacionais e líderes estaduais (do seu estado)
- **`blocos_delete_admin`**: Exclusão apenas para administradores

### **Tabela `configuracoes_sistema`**
- **`allow_read_configuracoes_sistema`**: Leitura para todos

### **Tabela `dados_viagem`**
- **`Allow all for admin`**: Administradores têm acesso total
- **`Allow insert for authenticated users`**: Usuários autenticados podem inserir
- **`Allow read based on hierarchy`**: Leitura baseada na hierarquia
- **`Allow update based on hierarchy`**: Atualização baseada na hierarquia
- **`allow_read_dados_viagem`**: Leitura para todos

### **Tabela `edicoes`**
- **`Edições são visíveis para todos`**: Leitura para usuários autenticados
- **`allow_read_all_edicoes`**: Leitura para todos

### **Tabela `estados`**
- **`Estados são visíveis para todos`**: Leitura para usuários autenticados
- **`allow_read_all_estados`**: Leitura para todos

### **Tabela `regioes`**
- **`regioes_select_all`**: Leitura para todos
- **`regioes_insert_admin`**: Inserção para administradores, líderes nacionais, líderes estaduais (do seu estado) e líderes de bloco (do seu bloco)
- **`regioes_update_admin`**: Atualização para administradores, líderes nacionais, líderes estaduais (do seu estado) e líderes de bloco (do seu bloco)
- **`regioes_delete_admin`**: Exclusão apenas para administradores

### **Tabela `igrejas`**
- **`igrejas_select_all`**: Leitura para todos
- **`igrejas_insert_admin`**: Inserção para administradores, líderes nacionais, líderes estaduais (do seu estado), líderes de bloco (do seu bloco) e líderes regionais (da sua região)
- **`igrejas_update_admin`**: Atualização para administradores, líderes nacionais, líderes estaduais (do seu estado), líderes de bloco (do seu bloco) e líderes regionais (da sua região)
- **`igrejas_delete_admin`**: Exclusão apenas para administradores

### **Tabela `jovens`**
- **`Allow all for admin`**: Administradores têm acesso total
- **`Allow insert for authenticated users`**: Usuários autenticados podem inserir
- **`Allow read based on hierarchy`**: Leitura baseada na hierarquia
- **`Allow update based on hierarchy`**: Atualização baseada na hierarquia
- **`allow_insert_jovens`**: Inserção para colaboradores e administradores
- **`allow_read_jovens_by_hierarchy`**: Leitura hierárquica complexa
- **`allow_update_jovens_by_hierarchy`**: Atualização hierárquica complexa
- **`jovens_delete_admin`**: Exclusão apenas para administradores
- **`jovens_insert_self_or_admin`**: Inserção para próprio usuário ou admin
- **`jovens_select_scoped`**: Seleção com escopo
- **`jovens_update_scoped_roles`**: Atualização com escopo de papéis

### **Tabela `logs_auditoria`**
- **`Allow all for admin`**: Administradores têm acesso total
- **`Allow read for authenticated users`**: Leitura para usuários autenticados
- **`allow_read_logs_auditoria`**: Leitura para todos

### **Tabela `notificacoes`**
- **`Allow all for admin`**: Administradores têm acesso total
- **`Allow insert for authenticated users`**: Usuários autenticados podem inserir
- **`Allow read for authenticated users`**: Leitura para usuários autenticados
- **`Allow update for authenticated users`**: Atualização para usuários autenticados
- **`allow_read_notificacoes`**: Leitura para todos

### **Tabela `regioes`**
- **`allow_read_all_regioes`**: Leitura para todos

### **Tabela `roles`**
- **`Allow all for admin`**: Administradores têm acesso total
- **`Allow read for authenticated users`**: Leitura para usuários autenticados
- **`allow_read_all_roles`**: Leitura para todos

### **Tabela `sessoes_usuario`**
- **`allow_read_sessoes_usuario`**: Leitura para todos

### **Tabela `user_roles`**
- **`Allow all for admin`**: Administradores têm acesso total
- **`Allow delete for admin`**: Exclusão apenas para administradores
- **`Allow insert for admin`**: Inserção apenas para administradores
- **`Allow read for authenticated users`**: Leitura para usuários autenticados
- **`Allow update for admin`**: Atualização apenas para administradores
- **`allow_read_own_user_roles`**: Leitura dos próprios papéis

### **Tabela `usuarios`**
- **`Allow all for admin`**: Administradores têm acesso total
- **`Allow read for authenticated users`**: Leitura para usuários autenticados
- **`Allow update for own profile`**: Atualização do próprio perfil
- **`allow_read_own_user_data`**: Leitura dos próprios dados
- **`allow_update_own_user_data`**: Atualização dos próprios dados

---

## 🏗️ Hierarquia de Permissões

### **Níveis Hierárquicos (8 níveis)**

1. **Administrador** (Nível 1)
   - Acesso total ao sistema
   - Pode gerenciar todos os usuários
   - Pode ver todos os dados

2. **Líder Nacional IURD** (Nível 2)
   - Acesso nacional
   - Pode ver todos os estados

3. **Líder Nacional FJU** (Nível 2)
   - Acesso nacional
   - Pode ver todos os estados

4. **Líder Estadual IURD** (Nível 3)
   - Acesso ao estado específico
   - Pode ver todos os blocos do estado

5. **Líder Estadual FJU** (Nível 3)
   - Acesso ao estado específico
   - Pode ver todos os blocos do estado

6. **Líder de Bloco IURD** (Nível 4)
   - Acesso ao bloco específico
   - Pode ver todas as regiões do bloco

7. **Líder de Bloco FJU** (Nível 4)
   - Acesso ao bloco específico
   - Pode ver todas as regiões do bloco

8. **Líder Regional IURD** (Nível 5)
   - Acesso à região específica
   - Pode ver todas as igrejas da região

9. **Líder de Igreja IURD** (Nível 6)
   - Acesso à igreja específica
   - Pode ver todos os jovens da igreja

10. **Colaborador** (Nível 7)
    - Acesso apenas aos jovens que cadastrou
    - Pode cadastrar novos jovens

11. **Jovem** (Nível 8)
    - Acesso apenas aos próprios dados
    - Pode visualizar seu perfil

---

## 🔗 Relacionamentos

### **Hierarquia Geográfica**
```
Estados
├── Blocos
│   ├── Regiões
│   │   └── Igrejas
│   │       └── Jovens
```

### **Relacionamentos Principais**

1. **Usuários ↔ Papéis**
   - `usuarios.id` ↔ `user_roles.user_id`
   - `user_roles.role_id` ↔ `roles.id`

2. **Jovens ↔ Localização**
   - `jovens.estado_id` ↔ `estados.id`
   - `jovens.bloco_id` ↔ `blocos.id`
   - `jovens.regiao_id` ↔ `regioes.id`
   - `jovens.igreja_id` ↔ `igrejas.id`

3. **Jovens ↔ Usuários**
   - `jovens.usuario_id` ↔ `usuarios.id`

4. **Aprovações ↔ Jovens**
   - `aprovacoes_jovens.jovem_id` ↔ `jovens.id`
   - `aprovacoes_jovens.usuario_id` ↔ `usuarios.id`

5. **Avaliações ↔ Jovens**
   - `avaliacoes.jovem_id` ↔ `jovens.id`
   - `avaliacoes.user_id` ↔ `usuarios.id`

6. **Dados de Viagem ↔ Jovens**
   - `dados_viagem.jovem_id` ↔ `jovens.id`
   - `dados_viagem.edicao_id` ↔ `edicoes.id`

7. **Notificações ↔ Usuários**
   - `notificacoes.destinatario_id` ↔ `usuarios.id`
   - `notificacoes.remetente_id` ↔ `usuarios.id`

---

## 🔧 Guia de Manutenção

### **📝 Correções de Policies Implementadas**

#### **Problema Identificado**
As tabelas geográficas (`blocos`, `regioes`, `igrejas`) não possuíam policies de INSERT, UPDATE e DELETE, causando erros 403 (Forbidden) ao tentar inserir dados.

#### **Solução Aplicada**
- ✅ **Tabela `blocos`**: Policies de INSERT, UPDATE e DELETE implementadas
- ✅ **Tabela `regioes`**: Policies de INSERT, UPDATE e DELETE implementadas  
- ✅ **Tabela `igrejas`**: Policies de INSERT, UPDATE e DELETE implementadas

#### **Scripts de Correção**
- `corrigir-policies-geograficas.sql`: Script completo para todas as tabelas geográficas
- `corrigir-policies-blocos.sql`: Script específico para tabela blocos
- `testar-policies-blocos.sql`: Script de teste e verificação

### **Funções Críticas para Manutenção**

1. **`can_access_jovem`**: Função principal de controle de acesso
2. **`atualizar_status_jovem`**: Atualiza status de aprovação
3. **`obter_lideres_para_notificacao`**: Sistema de notificações
4. **`sincronizar_nivel_com_papeis`**: Sincronização de níveis

### **Triggers Importantes**

1. **`trigger_sincronizar_nivel`**: Sincroniza níveis automaticamente
2. **`trigger_notificar_mudanca_status`**: Notifica mudanças de status
3. **`trigger_registrar_acesso`**: Registra acessos automaticamente

### **Limpeza de Dados**

1. **`limpar_logs_antigos`**: Limpa logs antigos
2. **`limpar_notificacoes_antigas`**: Limpa notificações antigas
3. **`limpar_acessos_antigos`**: Limpa acessos antigos

### **Monitoramento**

1. **`verificar_integridade_funcoes`**: Verifica integridade das funções
2. **`obter_estatisticas_sistema`**: Estatísticas gerais
3. **`estatisticas_acesso_usuarios`**: Estatísticas de acesso

### **Backup e Recuperação**

1. **Logs de Auditoria**: Histórico completo de alterações
2. **Logs de Histórico**: Histórico específico de jovens
3. **Sessões de Usuário**: Controle de sessões ativas

---

## 📚 Conclusão

Este guia fornece uma visão completa da estrutura do banco de dados do sistema Campus IntelliMen, incluindo:

- **18 tabelas** com relacionamentos bem definidos
- **50+ functions** para lógica de negócio
- **50+ policies** para controle de acesso (incluindo correções recentes)
- **Sistema hierárquico** de 8 níveis de permissão
- **Sistema de notificações** automatizado
- **Auditoria completa** de todas as ações
- **Policies geográficas** corrigidas e funcionais

### **✅ Status Atual**
- **Policies RLS**: Todas as tabelas possuem policies completas (SELECT, INSERT, UPDATE, DELETE)
- **Controle de Acesso**: Hierarquia de permissões funcionando corretamente
- **Tabelas Geográficas**: Blocos, regiões e igrejas com policies corretas
- **Sistema de Segurança**: Robusto e bem estruturado

A estrutura é robusta, escalável e mantém a integridade dos dados através de triggers e policies bem definidas. As correções recentes garantem que todas as operações CRUD funcionem corretamente respeitando a hierarquia de permissões.
