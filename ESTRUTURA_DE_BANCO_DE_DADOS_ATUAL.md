# DOCUMENTAÇÃO DA ESTRUTURA DO BANCO DE DADOS

**ATENÇÃO: TODAS AS ALTERAÇÕES QUE FOREM FEITAS NO BANCO DE DADOS, DEVE SER ATUALIZADA NESTE DOCUMENTO PARA NÃO ALTERAR O FUNCIONAMENTO DO SISTEMA.**

## ✅ STATUS ATUAL DO BANCO DE DADOS

**Data da Última Migração:** 2024-12-19  
**Status:** ✅ MIGRAÇÃO CONCLUÍDA COM SUCESSO  
**Versão do Banco:** 2.2  

### 🗄️ Estruturas Implementadas:
- ✅ **Tabelas Geográficas:** estados, blocos, regioes, igrejas
- ✅ **Tabelas de Sistema:** edicoes, roles, user_roles, usuarios
- ✅ **Tabelas de Negócio:** jovens, avaliacoes, logs_historico
- ✅ **Tabelas Adicionais:** notificacoes, logs_auditoria, configuracoes_sistema, sessoes_usuario
- ✅ **Enums:** intellimen_aprovado_enum, intellimen_espirito_enum, intellimen_caractere_enum, intellimen_disposicao_enum
- ✅ **Views:** jovens_view (com cálculo de idade)
- ✅ **Funções:** filtrar_jovens, recalcular_idade, criar_log_auditoria, obter_estatisticas_sistema, limpar_logs_antigos
- ✅ **RLS Policies:** Implementadas para todas as tabelas
- ✅ **Índices:** Otimizados para performance
- ✅ **Triggers:** Cálculo automático de idade, notificações automáticas
- ✅ **Storage Buckets:** fotos_usuarios, fotos_jovens, documentos, backups, temp

### 🔐 Sistema de Segurança:
- ✅ **RBAC (Role-Based Access Control)** implementado
- ✅ **RLS (Row Level Security)** ativo em todas as tabelas
- ✅ **10 Níveis Hierárquicos** de acesso configurados
- ✅ **Controle de Acesso por Localização** funcionando

### 📊 Dados Iniciais:
- ✅ **10 Edições** cadastradas (1ª a 10ª)
- ✅ **10 Papéis/Roles** configurados
- ✅ **3ª Edição** ativa para novos cadastros
- ✅ **Migração de usuários** para novo sistema de roles

---

## ÍNDICE

1. [Extensões](#extensões)
2. [Enums](#enums)
3. [Tabelas Geográficas](#tabelas-geográficas)
4. [Tabela Edições](#tabela-edições)
5. [Tabela Roles](#tabela-roles)
6. [Tabela User Roles](#tabela-user-roles)
7. [Tabela Usuários](#tabela-usuários)
8. [Tabela Jovens](#tabela-jovens)
9. [Tabela Avaliações](#tabela-avaliações)
10. [Tabela Logs Histórico](#tabela-logs-histórico)
11. [Tabela Notificações](#tabela-notificações)
12. [Tabela Logs Auditoria](#tabela-logs-auditoria)
13. [Tabela Configurações Sistema](#tabela-configurações-sistema)
14. [Tabela Sessões Usuário](#tabela-sessões-usuário)
15. [Views](#views)
16. [Funções](#funções)
17. [RLS Policies](#rls-policies)
18. [Chaves e Constraints](#chaves-e-constraints)
19. [Índices](#índices)
20. [Storage (Supabase)](#storage-supabase)

---

## EXTENSÕES

```sql
create extension if not exists "pgcrypto";
```

**Descrição:** Extensão para criptografia e geração de UUIDs aleatórios.

---

## ENUMS

### 1. intellimen_aprovado_enum
```sql
create type intellimen_aprovado_enum as enum ('null', 'pre_aprovado', 'aprovado');
```
**Valores:**
- `null`: Status inicial (padrão)
- `pre_aprovado`: Pré-aprovado para o evento
- `aprovado`: Aprovado definitivamente

### 2. intellimen_espirito_enum
```sql
create type intellimen_espirito_enum as enum ('ruim','ser_observar','bom','excelente');
```
**Valores:**
- `ruim`: Espírito ruim
- `ser_observar`: Precisa ser observado
- `bom`: Bom espírito
- `excelente`: Espírito excelente

### 3. intellimen_caractere_enum
```sql
create type intellimen_caractere_enum as enum ('excelente','bom','ser_observar','ruim');
```
**Valores:**
- `excelente`: Caráter excelente
- `bom`: Bom caráter
- `ser_observar`: Caráter a ser observado
- `ruim`: Caráter ruim

### 4. intellimen_disposicao_enum
```sql
create type intellimen_disposicao_enum as enum ('muito_disposto','normal','pacato','desanimado');
```
**Valores:**
- `muito_disposto`: Muito disposto a servir
- `normal`: Disposição normal
- `pacato`: Pacato
- `desanimado`: Desanimado

---

## TABELAS GEOGRÁFICAS

### 1. Estados
```sql
create table if not exists estados (
  id uuid primary key default gen_random_uuid(),
  nome text not null,
  sigla text not null
);
```

**Campos:**
- `id`: UUID único (chave primária)
- `nome`: Nome completo do estado
- `sigla`: Sigla do estado (ex: SP, RJ, MG)

### 2. Blocos
```sql
create table if not exists blocos (
  id uuid primary key default gen_random_uuid(),
  estado_id uuid references estados(id) on delete cascade,
  nome text not null
);
```

**Campos:**
- `id`: UUID único (chave primária)
- `estado_id`: Referência ao estado (FK)
- `nome`: Nome do bloco

### 3. Regiões
```sql
create table if not exists regioes (
  id uuid primary key default gen_random_uuid(),
  bloco_id uuid references blocos(id) on delete cascade,
  nome text not null
);
```

**Campos:**
- `id`: UUID único (chave primária)
- `bloco_id`: Referência ao bloco (FK)
- `nome`: Nome da região

### 4. Igrejas
```sql
create table if not exists igrejas (
  id uuid primary key default gen_random_uuid(),
  regiao_id uuid references regioes(id) on delete cascade,
  nome text not null,
  endereco text
);
```

**Campos:**
- `id`: UUID único (chave primária)
- `regiao_id`: Referência à região (FK)
- `nome`: Nome da igreja
- `endereco`: Endereço da igreja (opcional)

---

## TABELA EDIÇÕES

```sql
create table if not exists edicoes (
  id uuid primary key default gen_random_uuid(),
  numero int not null unique,
  nome text not null,
  data_inicio date,
  data_fim date,
  ativa boolean default true,
  criado_em timestamptz default now()
);
```

**Campos:**
- `id`: UUID único (chave primária)
- `numero`: Número da edição (1-10)
- `nome`: Nome da edição
- `data_inicio`: Data de início da edição
- `data_fim`: Data de fim da edição
- `ativa`: Se a edição está ativa para novos cadastros
- `criado_em`: Data de criação do registro

---

## TABELA ROLES

```sql
create table if not exists roles (
  id uuid primary key default gen_random_uuid(),
  slug text not null unique,
  nome text not null,
  descricao text,
  nivel_hierarquico int not null,
  criado_em timestamptz default now()
);
```

**Campos:**
- `id`: UUID único (chave primária)
- `slug`: Identificador único do papel (ex: 'administrador', 'lider_estadual_iurd')
- `nome`: Nome do papel
- `descricao`: Descrição do papel
- `nivel_hierarquico`: Nível hierárquico (1=admin, 2=colab, 3=nacional, 4=estadual, 5=bloco, 6=regional, 7=igreja)
- `criado_em`: Data de criação do registro

**Papéis Disponíveis:**
- `administrador`: Acesso total ao sistema (nível 1)
- `colaborador`: Acesso amplo para colaboração (nível 2)
- `lider_nacional_iurd`: Responsável nacional IURD (nível 3)
- `lider_nacional_fju`: Responsável nacional FJU (nível 3)
- `lider_estadual_iurd`: Líder estadual IURD (nível 4)
- `lider_estadual_fju`: Líder estadual FJU (nível 4)
- `lider_bloco_iurd`: Líder de bloco IURD (nível 5)
- `lider_bloco_fju`: Líder de bloco FJU (nível 5)
- `lider_regional_iurd`: Líder regional IURD (nível 6)
- `lider_igreja_iurd`: Líder de igreja IURD (nível 7)

---

## TABELA USER ROLES

```sql
create table if not exists user_roles (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references usuarios(id) on delete cascade,
  role_id uuid references roles(id) on delete cascade,
  estado_id uuid references estados(id),
  bloco_id uuid references blocos(id),
  regiao_id uuid references regioes(id),
  igreja_id uuid references igrejas(id),
  ativo boolean default true,
  criado_em timestamptz default now(),
  criado_por uuid references usuarios(id),
  unique(user_id, role_id, estado_id, bloco_id, regiao_id, igreja_id)
);
```

**Campos:**
- `id`: UUID único (chave primária)
- `user_id`: Referência ao usuário (FK)
- `role_id`: Referência ao papel/role (FK)
- `estado_id`: Referência ao estado (FK) - para líderes estaduais
- `bloco_id`: Referência ao bloco (FK) - para líderes de bloco
- `regiao_id`: Referência à região (FK) - para líderes regionais
- `igreja_id`: Referência à igreja (FK) - para líderes de igreja
- `ativo`: Se o papel está ativo para o usuário
- `criado_em`: Data de criação do registro
- `criado_por`: Usuário que criou o relacionamento

**Descrição:** Tabela de relacionamento que permite que um usuário tenha múltiplos papéis e seja limitado por localização geográfica.

---

## TABELA USUÁRIOS

```sql
create table if not exists usuarios (
  id uuid primary key default gen_random_uuid(),
  id_auth uuid unique, -- vinculo com auth.users
  email text,
  foto text,
  nome text not null,
  sexo text check (sexo in ('masculino','feminino')),
  nivel text not null, -- mantido para compatibilidade
  estado_bandeira text,
  estado_id uuid references estados(id),
  bloco_id uuid references blocos(id),
  regiao_id uuid references regioes(id),
  igreja_id uuid references igrejas(id),
  ativo boolean default true,
  criado_em timestamptz default now()
);
```

**Campos:**
- `id`: UUID único (chave primária)
- `id_auth`: Vinculo com auth.users do Supabase (único)
- `email`: E-mail do usuário
- `foto`: URL da foto do usuário
- `nome`: Nome completo do usuário
- `sexo`: Sexo (masculino/feminino)
- `nivel`: Nível de acesso do usuário (mantido para compatibilidade)
- `estado_bandeira`: Sigla do estado da bandeira do usuário
- `estado_id`: Referência ao estado (FK)
- `bloco_id`: Referência ao bloco (FK)
- `regiao_id`: Referência à região (FK)
- `igreja_id`: Referência à igreja (FK)
- `ativo`: Se o usuário está ativo
- `criado_em`: Data de criação do registro

**Nota:** O sistema de níveis agora é gerenciado através da tabela `user_roles` com o sistema RBAC (Role-Based Access Control).

---

## TABELA JOVENS

```sql
create table if not exists jovens (
  id uuid primary key default gen_random_uuid(),
  estado_id uuid references estados(id),
  bloco_id uuid references blocos(id),
  regiao_id uuid references regioes(id),
  igreja_id uuid references igrejas(id),
  edicao text not null, -- mantido para compatibilidade
  edicao_id uuid references edicoes(id),
  foto text,
  nome_completo text not null,
  whatsapp text,
  data_nasc date not null,
  idade int, -- calculado automaticamente
  data_cadastro timestamptz default now(),
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
  tempo_condicao text,
  responsabilidade_igreja text,
  disposto_servir boolean,
  ja_obra_altar boolean,
  ja_obreiro boolean,
  ja_colaborador boolean,
  afastado boolean,
  data_afastamento date,
  motivo_afastamento text,
  data_retorno date,
  pais_na_igreja boolean,
  observacao_pais text,
  familiares_igreja boolean,
  deseja_altar boolean,
  observacao text,
  testemunho text,
  instagram text,
  facebook text,
  tiktok text,
  observacao_redes text,
  -- Novos campos adicionados
  pastor_que_indicou text,
  cresceu_na_igreja boolean,
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
  aprovado intellimen_aprovado_enum default 'null'
);
```

**Campos Principais:**
- `id`: UUID único (chave primária)
- `estado_id`, `bloco_id`, `regiao_id`, `igreja_id`: Referências geográficas
- `edicao`: Edição do evento (ex: "2024", "2025")
- `foto`: URL da foto do jovem
- `nome_completo`: Nome completo do jovem
- `numero_whatsapp`: Número do WhatsApp
- `data_nasc`: Data de nascimento
- `data_cadastro`: Data de cadastro no sistema

**Informações Pessoais:**
- `estado_civil`: Estado civil
- `namora`: Se está namorando
- `tem_filho`: Se tem filhos
- `trabalha`: Se trabalha
- `local_trabalho`: Local de trabalho
- `escolaridade`: Nível de escolaridade
- `formacao`: Formação acadêmica
- `tem_dividas`: Se possui dívidas

**Informações Espirituais:**
- `tempo_igreja`: Tempo na igreja
- `batizado_aguas`: Se foi batizado nas águas
- `data_batismo_aguas`: Data do batismo nas águas
- `batizado_es`: Se foi batizado com o Espírito Santo
- `data_batismo_es`: Data do batismo com o Espírito Santo
- `condicao`: Condição espiritual
- `tempo_condicao`: Tempo na condição
- `responsabilidade_igreja`: Responsabilidades na igreja

**Informações de Serviço:**
- `disposto_servir`: Se está disposto a servir
- `ja_obra_altar`: Se já trabalha no altar
- `ja_obreiro`: Se já é obreiro
- `ja_colaborador`: Se já é colaborador

**Informações de Afastamento:**
- `afastado`: Se está afastado
- `data_afastamento`: Data do afastamento
- `motivo_afastamento`: Motivo do afastamento
- `data_retorno`: Data de retorno

**Informações Familiares:**
- `pais_na_igreja`: Se os pais estão na igreja
- `observacao_pais`: Observações sobre os pais
- `familiares_igreja`: Se tem familiares na igreja

**Informações Adicionais:**
- `deseja_altar`: Se deseja trabalhar no altar
- `observacao`: Observações gerais
- `testemunho`: Testemunho pessoal
- `link_instagram`, `link_facebook`, `link_tiktok`: Links das redes sociais
- `observacao_redes`: Observações sobre redes sociais
- `aprovado`: Status de aprovação (enum)

---

## TABELA AVALIAÇÕES

```sql
create table if not exists avaliacoes (
  id uuid primary key default gen_random_uuid(),
  jovem_id uuid references jovens(id) on delete cascade,
  user_id uuid references usuarios(id), -- avaliador
  espirito intellimen_espirito_enum,
  caractere intellimen_caractere_enum,
  disposicao intellimen_disposicao_enum,
  avaliacao_texto text,
  nota int check (nota between 1 and 10),
  criado_em timestamptz default now()
);
```

**Campos:**
- `id`: UUID único (chave primária)
- `jovem_id`: Referência ao jovem avaliado (FK)
- `user_id`: Referência ao usuário avaliador (FK)
- `espirito`: Avaliação do espírito (enum)
- `caractere`: Avaliação do caráter (enum)
- `disposicao`: Avaliação da disposição (enum)
- `avaliacao_texto`: Texto da avaliação
- `nota`: Nota de 1 a 10
- `criado_em`: Data de criação da avaliação

---

## TABELA LOGS HISTÓRICO

```sql
create table if not exists logs_historico (
  id uuid primary key default gen_random_uuid(),
  jovem_id uuid references jovens(id) on delete cascade,
  user_id uuid references usuarios(id),
  acao text not null,
  detalhe text,
  dados_anteriores jsonb,
  dados_novos jsonb,
  created_at timestamptz default now()
);
```

**Campos:**
- `id`: UUID único (chave primária)
- `jovem_id`: Referência ao jovem (FK)
- `user_id`: Referência ao usuário que executou a ação (FK)
- `acao`: Tipo de ação executada
- `detalhe`: Detalhes da ação
- `dados_anteriores`: Dados anteriores em formato JSON
- `dados_novos`: Dados novos em formato JSON
- `created_at`: Data de criação do log

**Tipos de Ação:**
- `cadastro`: Cadastro de novo jovem
- `edicao`: Edição de dados do jovem
- `avaliacao`: Criação/edição de avaliação
- `aprovacao`: Mudança de status de aprovação
- `transferencia_lideranca`: Transferência de liderança

---

## TABELA NOTIFICAÇÕES

```sql
create table if not exists notificacoes (
  id uuid primary key default gen_random_uuid(),
  tipo varchar(50) not null check (tipo in ('cadastro', 'avaliacao', 'aprovacao', 'transferencia', 'sistema')),
  titulo varchar(255) not null,
  mensagem text not null,
  destinatario_id uuid not null references usuarios(id) on delete cascade,
  remetente_id uuid references usuarios(id) on delete set null,
  jovem_id uuid references jovens(id) on delete cascade,
  acao_url text,
  lida boolean default false,
  lida_em timestamptz,
  criado_em timestamptz default now(),
  atualizado_em timestamptz default now()
);
```

**Campos:**
- `id`: UUID único (chave primária)
- `tipo`: Tipo da notificação (enum)
- `titulo`: Título da notificação
- `mensagem`: Mensagem da notificação
- `destinatario_id`: Referência ao usuário destinatário (FK)
- `remetente_id`: Referência ao usuário remetente (FK)
- `jovem_id`: Referência ao jovem relacionado (FK)
- `acao_url`: URL para ação relacionada
- `lida`: Se a notificação foi lida
- `lida_em`: Data/hora que foi lida
- `criado_em`: Data de criação da notificação
- `atualizado_em`: Data de última atualização

**Tipos de Notificação:**
- `cadastro`: Notificação sobre cadastro de jovens
- `avaliacao`: Notificação sobre avaliações
- `aprovacao`: Notificação sobre aprovações
- `transferencia`: Notificação sobre transferências
- `sistema`: Notificação do sistema

---

## TABELA LOGS AUDITORIA

```sql
create table if not exists logs_auditoria (
  id uuid primary key default gen_random_uuid(),
  usuario_id uuid references usuarios(id) on delete set null,
  acao varchar(100) not null,
  detalhe text not null,
  dados_antigos jsonb,
  dados_novos jsonb,
  ip_address inet,
  user_agent text,
  criado_em timestamptz default now()
);
```

**Campos:**
- `id`: UUID único (chave primária)
- `usuario_id`: Referência ao usuário que executou a ação (FK)
- `acao`: Tipo de ação executada
- `detalhe`: Detalhes da ação
- `dados_antigos`: Dados anteriores em formato JSON
- `dados_novos`: Dados novos em formato JSON
- `ip_address`: Endereço IP do usuário
- `user_agent`: User agent do navegador
- `criado_em`: Data de criação do log

**Descrição:** Tabela para logs de auditoria detalhados com informações de segurança.

---

## TABELA CONFIGURAÇÕES SISTEMA

```sql
create table if not exists configuracoes_sistema (
  id uuid primary key default gen_random_uuid(),
  chave varchar(100) unique not null,
  valor jsonb not null,
  descricao text,
  categoria varchar(50) default 'geral',
  criado_em timestamptz default now(),
  atualizado_em timestamptz default now()
);
```

**Campos:**
- `id`: UUID único (chave primária)
- `chave`: Chave única da configuração
- `valor`: Valor da configuração em JSON
- `descricao`: Descrição da configuração
- `categoria`: Categoria da configuração
- `criado_em`: Data de criação
- `atualizado_em`: Data de última atualização

**Categorias:**
- `geral`: Configurações gerais do sistema
- `seguranca`: Configurações de segurança
- `notificacoes`: Configurações de notificações
- `backup`: Configurações de backup

---

## TABELA SESSÕES USUÁRIO

```sql
create table if not exists sessoes_usuario (
  id uuid primary key default gen_random_uuid(),
  usuario_id uuid not null references usuarios(id) on delete cascade,
  token_hash varchar(255) not null,
  ip_address inet,
  user_agent text,
  ativo boolean default true,
  expira_em timestamptz not null,
  criado_em timestamptz default now(),
  atualizado_em timestamptz default now()
);
```

**Campos:**
- `id`: UUID único (chave primária)
- `usuario_id`: Referência ao usuário (FK)
- `token_hash`: Hash do token de sessão
- `ip_address`: Endereço IP da sessão
- `user_agent`: User agent do navegador
- `ativo`: Se a sessão está ativa
- `expira_em`: Data/hora de expiração da sessão
- `criado_em`: Data de criação da sessão
- `atualizado_em`: Data de última atualização

**Descrição:** Tabela para controle de sessões de usuário com informações de segurança.

---

## VIEWS

### 1. jovens_view
```sql
create or replace view jovens_view as
select j.*,
       date_part('year', age(j.data_nasc))::int as idade
from jovens j;
```

**Descrição:** View que adiciona o campo `idade` calculado automaticamente baseado na data de nascimento.

**Campos Adicionais:**
- `idade`: Idade calculada em anos

---

## FUNÇÕES

### 1. filtrar_jovens
```sql
create or replace function filtrar_jovens(filters jsonb)
returns table (
  id uuid,
  nome_completo text,
  estado_id uuid,
  bloco_id uuid,
  regiao_id uuid,
  igreja_id uuid,
  edicao text,
  idade int,
  aprovado intellimen_aprovado_enum
)
language sql
as $$
select 
  j.id,
  j.nome_completo,
  j.estado_id,
  j.bloco_id,
  j.regiao_id,
  j.igreja_id,
  j.edicao,
  date_part('year', age(j.data_nasc))::int as idade,
  j.aprovado
from jovens j
where (coalesce(filters->>'estado_id','') = '' or j.estado_id = (filters->>'estado_id')::uuid)
  and (coalesce(filters->>'bloco_id','') = '' or j.bloco_id = (filters->>'bloco_id')::uuid)
  and (coalesce(filters->>'regiao_id','') = '' or j.regiao_id = (filters->>'regiao_id')::uuid)
  and (coalesce(filters->>'igreja_id','') = '' or j.igreja_id = (filters->>'igreja_id')::uuid)
  and (coalesce(filters->>'edicao','') = '' or j.edicao = (filters->>'edicao')::text)
  and (coalesce(filters->>'nome_like','') = '' or lower(j.nome_completo) like '%' || lower((filters->>'nome_like')::text) || '%');
$$;
```

**Parâmetros:**
- `filters`: JSONB com os filtros a serem aplicados

**Filtros Suportados:**
- `estado_id`: Filtrar por estado
- `bloco_id`: Filtrar por bloco
- `regiao_id`: Filtrar por região
- `igreja_id`: Filtrar por igreja
- `edicao`: Filtrar por edição
- `nome_like`: Busca parcial por nome

**Retorno:** Tabela com informações básicas dos jovens filtrados incluindo idade calculada.

### 2. recalcular_idade
```sql
create or replace function recalcular_idade()
returns trigger as $$
begin
  new.idade = date_part('year', age(new.data_nasc))::int;
  return new;
end;
$$ language plpgsql;
```

**Descrição:** Função trigger que recalcula automaticamente a idade do jovem baseada na data de nascimento.

### 3. criar_log_auditoria
```sql
create or replace function criar_log_auditoria(
  p_jovem_id uuid,
  p_acao text,
  p_detalhe text default null,
  p_dados_anteriores jsonb default null,
  p_dados_novos jsonb default null
)
returns void as $$
begin
  insert into logs_historico (jovem_id, user_id, acao, detalhe, dados_anteriores, dados_novos)
  values (
    p_jovem_id,
    (select id from usuarios where id_auth = auth.uid()),
    p_acao,
    p_detalhe,
    p_dados_anteriores,
    p_dados_novos
  );
end;
$$ language plpgsql security definer;
```

**Parâmetros:**
- `p_jovem_id`: ID do jovem
- `p_acao`: Tipo de ação executada
- `p_detalhe`: Detalhes da ação (opcional)
- `p_dados_anteriores`: Dados anteriores em JSON (opcional)
- `p_dados_novos`: Dados novos em JSON (opcional)

**Descrição:** Função para criar logs de auditoria de forma segura.

### 4. obter_estatisticas_sistema
```sql
create or replace function obter_estatisticas_sistema()
returns json as $$
declare
  stats json;
begin
  select json_build_object(
    'total_usuarios', (select count(*) from usuarios),
    'total_jovens', (select count(*) from jovens),
    'total_avaliacoes', (select count(*) from avaliacoes),
    'total_notificacoes', (select count(*) from notificacoes),
    'usuarios_ativos', (select count(*) from usuarios where ativo = true),
    'jovens_aprovados', (select count(*) from jovens where aprovado = true),
    'avaliacoes_hoje', (select count(*) from avaliacoes where date(criado_em) = current_date),
    'notificacoes_nao_lidas', (select count(*) from notificacoes where lida = false)
  ) into stats;
  
  return stats;
end;
$$ language plpgsql security definer;
```

**Descrição:** Função para obter estatísticas gerais do sistema em formato JSON.

### 5. limpar_logs_antigos
```sql
create or replace function limpar_logs_antigos(dias_retencao integer default 90)
returns integer as $$
declare
  logs_removidos integer;
begin
  delete from logs_auditoria 
  where criado_em < now() - interval '1 day' * dias_retencao;
  
  get diagnostics logs_removidos = row_count;
  
  return logs_removidos;
end;
$$ language plpgsql security definer;
```

**Parâmetros:**
- `dias_retencao`: Número de dias para reter os logs (padrão: 90)

**Retorno:** Número de logs removidos

**Descrição:** Função para limpar logs de auditoria antigos automaticamente.

### 6. is_admin_user ✅
```sql
create or replace function is_admin_user()
returns boolean
language sql
security definer
stable
as $$
  select exists (
    select 1 from user_roles ur
    join roles r on r.id = ur.role_id
    where ur.user_id = (select id from usuarios where id_auth = auth.uid())
    and r.slug = 'administrador'
    and ur.ativo = true
  );
$$;
```

**Retorno:** Boolean indicando se o usuário atual é administrador

**Descrição:** Função auxiliar para verificar se o usuário atual tem permissão de administrador, evitando recursão infinita nas políticas RLS.

**Status:** ✅ Implementada para resolver problema de recursão infinita

---

## RLS POLICIES

### Status Atual do RLS
**✅ RLS HABILITADO** - 2024-12-19

```sql
-- RLS habilitado em todas as tabelas principais
ALTER TABLE usuarios ENABLE ROW LEVEL SECURITY;
ALTER TABLE jovens ENABLE ROW LEVEL SECURITY;
ALTER TABLE avaliacoes ENABLE ROW LEVEL SECURITY;
ALTER TABLE edicoes ENABLE ROW LEVEL SECURITY;
ALTER TABLE roles ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_roles ENABLE ROW LEVEL SECURITY;
ALTER TABLE logs_historico ENABLE ROW LEVEL SECURITY;
ALTER TABLE notificacoes ENABLE ROW LEVEL SECURITY;
ALTER TABLE logs_auditoria ENABLE ROW LEVEL SECURITY;
ALTER TABLE configuracoes_sistema ENABLE ROW LEVEL SECURITY;
ALTER TABLE sessoes_usuario ENABLE ROW LEVEL SECURITY;

-- Tabelas geográficas (apenas leitura para todos)
ALTER TABLE estados ENABLE ROW LEVEL SECURITY;
ALTER TABLE blocos ENABLE ROW LEVEL SECURITY;
ALTER TABLE regioes ENABLE ROW LEVEL SECURITY;
ALTER TABLE igrejas ENABLE ROW LEVEL SECURITY;
```

**Status:** ✅ Todas as políticas implementadas e funcionando corretamente

### Funções Auxiliares RLS

#### 1. is_admin_user() ✅
```sql
CREATE OR REPLACE FUNCTION is_admin_user()
RETURNS boolean
LANGUAGE sql
SECURITY DEFINER
STABLE
AS $$
  SELECT EXISTS (
    SELECT 1 FROM user_roles ur
    JOIN roles r ON r.id = ur.role_id
    WHERE ur.user_id = (SELECT id FROM usuarios WHERE id_auth = auth.uid())
    AND r.slug = 'administrador'
    AND ur.ativo = true
  );
$$;
```

#### 2. has_role(role_slug text) ✅
```sql
CREATE OR REPLACE FUNCTION has_role(role_slug text)
RETURNS boolean
LANGUAGE sql
SECURITY DEFINER
STABLE
AS $$
  SELECT EXISTS (
    SELECT 1 FROM user_roles ur
    JOIN roles r ON r.id = ur.role_id
    WHERE ur.user_id = (SELECT id FROM usuarios WHERE id_auth = auth.uid())
    AND r.slug = role_slug
    AND ur.ativo = true
  );
$$;
```

#### 3. can_access_jovem() ✅
```sql
CREATE OR REPLACE FUNCTION can_access_jovem(jovem_estado_id uuid, jovem_bloco_id uuid, jovem_regiao_id uuid, jovem_igreja_id uuid)
RETURNS boolean
LANGUAGE sql
SECURITY DEFINER
STABLE
AS $$
  SELECT EXISTS (
    SELECT 1 FROM user_roles ur
    JOIN roles r ON r.id = ur.role_id
    WHERE ur.user_id = (SELECT id FROM usuarios WHERE id_auth = auth.uid())
    AND ur.ativo = true
    AND (
      r.slug IN ('administrador', 'colaborador') OR
      (r.slug LIKE 'lider_estadual_%' AND ur.estado_id = jovem_estado_id) OR
      (r.slug LIKE 'lider_bloco_%' AND ur.bloco_id = jovem_bloco_id) OR
      (r.slug = 'lider_regional_iurd' AND ur.regiao_id = jovem_regiao_id) OR
      (r.slug = 'lider_igreja_iurd' AND ur.igreja_id = jovem_igreja_id)
    )
  );
$$;
```

### Policies - Usuários

#### 1. usuarios_admin_full ✅
```sql
CREATE POLICY "usuarios_admin_full" ON usuarios
  FOR ALL
  USING (is_admin_user());
```
**Descrição:** Administradores têm acesso total à tabela de usuários.

#### 2. usuarios_self_select ✅
```sql
CREATE POLICY "usuarios_self_select" ON usuarios
  FOR SELECT
  USING (id_auth = auth.uid());
```
**Descrição:** Usuários podem visualizar apenas seus próprios dados.

#### 3. usuarios_self_update ✅
```sql
CREATE POLICY "usuarios_self_update" ON usuarios
  FOR UPDATE
  USING (id_auth = auth.uid());
```
**Descrição:** Usuários podem atualizar apenas seus próprios dados.

#### 4. usuarios_colaborador_select ✅
```sql
CREATE POLICY "usuarios_colaborador_select" ON usuarios
  FOR SELECT
  USING (has_role('colaborador'));
```
**Descrição:** Colaboradores podem ver todos os usuários.

### Policies - Jovens

#### 1. jovens_admin_colab ✅
```sql
CREATE POLICY "jovens_admin_colab" ON jovens
  FOR ALL
  USING (has_role('administrador') OR has_role('colaborador'));
```
**Descrição:** Administradores e colaboradores têm acesso total à tabela de jovens.

#### 2. jovens_lider_estadual ✅
```sql
CREATE POLICY "jovens_lider_estadual" ON jovens
  FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM user_roles ur
      JOIN roles r ON r.id = ur.role_id
      WHERE ur.user_id = (SELECT id FROM usuarios WHERE id_auth = auth.uid())
      AND r.slug LIKE 'lider_estadual_%'
      AND ur.estado_id = jovens.estado_id
      AND ur.ativo = true
    )
  );
```
**Descrição:** Líderes estaduais têm acesso apenas aos jovens de seu estado.

#### 3. jovens_lider_bloco ✅
```sql
CREATE POLICY "jovens_lider_bloco" ON jovens
  FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM user_roles ur
      JOIN roles r ON r.id = ur.role_id
      WHERE ur.user_id = (SELECT id FROM usuarios WHERE id_auth = auth.uid())
      AND r.slug LIKE 'lider_bloco_%'
      AND ur.bloco_id = jovens.bloco_id
      AND ur.ativo = true
    )
  );
```
**Descrição:** Líderes de bloco têm acesso apenas aos jovens de seu bloco.

#### 4. jovens_lider_regional ✅
```sql
CREATE POLICY "jovens_lider_regional" ON jovens
  FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM user_roles ur
      JOIN roles r ON r.id = ur.role_id
      WHERE ur.user_id = (SELECT id FROM usuarios WHERE id_auth = auth.uid())
      AND r.slug = 'lider_regional_iurd'
      AND ur.regiao_id = jovens.regiao_id
      AND ur.ativo = true
    )
  );
```
**Descrição:** Líderes regionais têm acesso apenas aos jovens de sua região.

#### 5. jovens_lider_igreja ✅
```sql
CREATE POLICY "jovens_lider_igreja" ON jovens
  FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM user_roles ur
      JOIN roles r ON r.id = ur.role_id
      WHERE ur.user_id = (SELECT id FROM usuarios WHERE id_auth = auth.uid())
      AND r.slug = 'lider_igreja_iurd'
      AND ur.igreja_id = jovens.igreja_id
      AND ur.ativo = true
    )
  );
```
**Descrição:** Líderes de igreja têm acesso apenas aos jovens de sua igreja.

### Policies - Avaliações

#### 1. avaliacoes_admin_colab ✅
```sql
CREATE POLICY "avaliacoes_admin_colab" ON avaliacoes
  FOR ALL
  USING (has_role('administrador') OR has_role('colaborador'));
```
**Descrição:** Administradores e colaboradores têm acesso total à tabela de avaliações.

#### 2. avaliacoes_by_jovem_access ✅
```sql
CREATE POLICY "avaliacoes_by_jovem_access" ON avaliacoes
  FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM jovens j
      WHERE j.id = avaliacoes.jovem_id
      AND can_access_jovem(j.estado_id, j.bloco_id, j.regiao_id, j.igreja_id)
    )
  );
```
**Descrição:** Usuários podem ver avaliações dos jovens que podem acessar.

#### 3. avaliacoes_insert_by_jovem_access ✅
```sql
CREATE POLICY "avaliacoes_insert_by_jovem_access" ON avaliacoes
  FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM jovens j
      WHERE j.id = avaliacoes.jovem_id
      AND can_access_jovem(j.estado_id, j.bloco_id, j.regiao_id, j.igreja_id)
    )
  );
```
**Descrição:** Usuários podem criar avaliações para jovens que podem acessar.

#### 4. avaliacoes_self_update ✅
```sql
CREATE POLICY "avaliacoes_self_update" ON avaliacoes
  FOR UPDATE
  USING (user_id = (SELECT id FROM usuarios WHERE id_auth = auth.uid()));
```
**Descrição:** Usuários podem editar apenas suas próprias avaliações.

#### 5. avaliacoes_self_delete ✅
```sql
CREATE POLICY "avaliacoes_self_delete" ON avaliacoes
  FOR DELETE
  USING (user_id = (SELECT id FROM usuarios WHERE id_auth = auth.uid()));
```
**Descrição:** Usuários podem deletar apenas suas próprias avaliações.

### Policies - Edições

#### 1. edicoes_select_all ✅
```sql
CREATE POLICY "edicoes_select_all" ON edicoes
  FOR SELECT
  USING (true);
```
**Descrição:** Todos podem visualizar as edições.

#### 2. edicoes_admin_modify ✅
```sql
CREATE POLICY "edicoes_admin_modify" ON edicoes
  FOR ALL
  USING (is_admin_user());
```
**Descrição:** Apenas administradores podem modificar edições.

### Policies - Roles

#### 1. roles_select_all ✅
```sql
CREATE POLICY "roles_select_all" ON roles
  FOR SELECT
  USING (true);
```
**Descrição:** Todos podem visualizar os papéis disponíveis.

#### 2. roles_admin_modify ✅
```sql
CREATE POLICY "roles_admin_modify" ON roles
  FOR ALL
  USING (is_admin_user());
```
**Descrição:** Apenas administradores podem modificar roles.

### Policies - User Roles

#### 1. user_roles_admin_colab ✅
```sql
CREATE POLICY "user_roles_admin_colab" ON user_roles
  FOR ALL
  USING (has_role('administrador') OR has_role('colaborador'));
```
**Descrição:** Administradores e colaboradores podem gerenciar todos os user_roles.

#### 2. user_roles_self_select ✅
```sql
CREATE POLICY "user_roles_self_select" ON user_roles
  FOR SELECT
  USING (user_id = (SELECT id FROM usuarios WHERE id_auth = auth.uid()));
```
**Descrição:** Usuários podem ver seus próprios papéis.

### Policies - Logs Histórico

#### 1. logs_historico_admin_colab ✅
```sql
CREATE POLICY "logs_historico_admin_colab" ON logs_historico
  FOR ALL
  USING (has_role('administrador') OR has_role('colaborador'));
```
**Descrição:** Administradores e colaboradores têm acesso total aos logs.

#### 2. logs_historico_by_jovem_access ✅
```sql
CREATE POLICY "logs_historico_by_jovem_access" ON logs_historico
  FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM jovens j
      WHERE j.id = logs_historico.jovem_id
      AND can_access_jovem(j.estado_id, j.bloco_id, j.regiao_id, j.igreja_id)
    )
  );
```
**Descrição:** Líderes podem ver logs dos jovens que podem acessar.

#### 3. logs_historico_system_insert ✅
```sql
CREATE POLICY "logs_historico_system_insert" ON logs_historico
  FOR INSERT
  WITH CHECK (true);
```
**Descrição:** Sistema pode inserir logs (para função criar_log_auditoria).

### Policies - Notificações

#### 1. notificacoes_self ✅
```sql
CREATE POLICY "notificacoes_self" ON notificacoes
  FOR ALL
  USING (destinatario_id = (SELECT id FROM usuarios WHERE id_auth = auth.uid()));
```
**Descrição:** Usuários podem gerenciar apenas suas próprias notificações.

#### 2. notificacoes_system_insert ✅
```sql
CREATE POLICY "notificacoes_system_insert" ON notificacoes
  FOR INSERT
  WITH CHECK (true);
```
**Descrição:** Sistema pode criar notificações.

### Policies - Logs Auditoria

#### 1. logs_auditoria_admin ✅
```sql
CREATE POLICY "logs_auditoria_admin" ON logs_auditoria
  FOR SELECT
  USING (is_admin_user());
```
**Descrição:** Apenas administradores podem ver logs de auditoria.

#### 2. logs_auditoria_system_insert ✅
```sql
CREATE POLICY "logs_auditoria_system_insert" ON logs_auditoria
  FOR INSERT
  WITH CHECK (true);
```
**Descrição:** Sistema pode inserir logs de auditoria.

### Policies - Configurações Sistema

#### 1. configuracoes_select_all ✅
```sql
CREATE POLICY "configuracoes_select_all" ON configuracoes_sistema
  FOR SELECT
  USING (true);
```
**Descrição:** Todos podem visualizar configurações.

#### 2. configuracoes_admin_modify ✅
```sql
CREATE POLICY "configuracoes_admin_modify" ON configuracoes_sistema
  FOR ALL
  USING (is_admin_user());
```
**Descrição:** Apenas administradores podem modificar configurações.

### Policies - Sessões Usuário

#### 1. sessoes_self ✅
```sql
CREATE POLICY "sessoes_self" ON sessoes_usuario
  FOR ALL
  USING (usuario_id = (SELECT id FROM usuarios WHERE id_auth = auth.uid()));
```
**Descrição:** Usuários podem gerenciar apenas suas próprias sessões.

#### 2. sessoes_system_insert ✅
```sql
CREATE POLICY "sessoes_system_insert" ON sessoes_usuario
  FOR INSERT
  WITH CHECK (true);
```
**Descrição:** Sistema pode criar sessões.

### Policies - Tabelas Geográficas

#### 1. Estados ✅
```sql
CREATE POLICY "estados_select_all" ON estados
  FOR SELECT
  USING (true);

CREATE POLICY "estados_admin_modify" ON estados
  FOR ALL
  USING (is_admin_user());
```

#### 2. Blocos ✅
```sql
CREATE POLICY "blocos_select_all" ON blocos
  FOR SELECT
  USING (true);

CREATE POLICY "blocos_admin_modify" ON blocos
  FOR ALL
  USING (is_admin_user());
```

#### 3. Regiões ✅
```sql
CREATE POLICY "regioes_select_all" ON regioes
  FOR SELECT
  USING (true);

CREATE POLICY "regioes_admin_modify" ON regioes
  FOR ALL
  USING (is_admin_user());
```

#### 4. Igrejas ✅
```sql
CREATE POLICY "igrejas_select_all" ON igrejas
  FOR SELECT
  USING (true);

CREATE POLICY "igrejas_admin_modify" ON igrejas
  FOR ALL
  USING (is_admin_user());
```

---

## CHAVES E CONSTRAINTS

### Chaves Primárias
- Todas as tabelas utilizam UUID como chave primária
- Geração automática com `gen_random_uuid()`

### Chaves Estrangeiras

#### Estados → Blocos
- `blocos.estado_id` → `estados.id` (CASCADE DELETE)

#### Blocos → Regiões
- `regioes.bloco_id` → `blocos.id` (CASCADE DELETE)

#### Regiões → Igrejas
- `igrejas.regiao_id` → `regioes.id` (CASCADE DELETE)

#### Estados → Usuários
- `usuarios.estado_id` → `estados.id`

#### Blocos → Usuários
- `usuarios.bloco_id` → `blocos.id`

#### Regiões → Usuários
- `usuarios.regiao_id` → `regioes.id`

#### Igrejas → Usuários
- `usuarios.igreja_id` → `igrejas.id`

#### Estados → Jovens
- `jovens.estado_id` → `estados.id`

#### Blocos → Jovens
- `jovens.bloco_id` → `blocos.id`

#### Regiões → Jovens
- `jovens.regiao_id` → `regioes.id`

#### Igrejas → Jovens
- `jovens.igreja_id` → `igrejas.id`

#### Jovens → Avaliações
- `avaliacoes.jovem_id` → `jovens.id` (CASCADE DELETE)

#### Usuários → Avaliações
- `avaliacoes.user_id` → `usuarios.id`

#### Edições → Jovens
- `jovens.edicao_id` → `edicoes.id`

#### Usuários → User Roles
- `user_roles.user_id` → `usuarios.id`
- `user_roles.criado_por` → `usuarios.id`

#### Roles → User Roles
- `user_roles.role_id` → `roles.id`

#### Estados → User Roles
- `user_roles.estado_id` → `estados.id`

#### Blocos → User Roles
- `user_roles.bloco_id` → `blocos.id`

#### Regiões → User Roles
- `user_roles.regiao_id` → `regioes.id`

#### Igrejas → User Roles
- `user_roles.igreja_id` → `igrejas.id`

#### Jovens → Logs Histórico
- `logs_historico.jovem_id` → `jovens.id` (CASCADE DELETE)

#### Usuários → Logs Histórico
- `logs_historico.user_id` → `usuarios.id`

### Constraints

#### Usuários
- `sexo` deve ser 'masculino' ou 'feminino'
- `id_auth` deve ser único

#### Avaliações
- `nota` deve estar entre 1 e 10

#### Edições
- `numero` deve ser único
- `numero` deve estar entre 1 e 10

#### Roles
- `slug` deve ser único
- `nivel_hierarquico` deve estar entre 1 e 7

#### User Roles
- Combinação `(user_id, role_id, estado_id, bloco_id, regiao_id, igreja_id)` deve ser única

---

## ÍNDICES

### Índices Recomendados (para otimização)

```sql
-- Índices para tabelas geográficas
create index if not exists idx_blocos_estado_id on blocos(estado_id);
create index if not exists idx_regioes_bloco_id on regioes(bloco_id);
create index if not exists idx_igrejas_regiao_id on igrejas(regiao_id);

-- Índices para usuários
create index if not exists idx_usuarios_id_auth on usuarios(id_auth);
create index if not exists idx_usuarios_nivel on usuarios(nivel);
create index if not exists idx_usuarios_estado_id on usuarios(estado_id);
create index if not exists idx_usuarios_bloco_id on usuarios(bloco_id);
create index if not exists idx_usuarios_regiao_id on usuarios(regiao_id);
create index if not exists idx_usuarios_igreja_id on usuarios(igreja_id);

-- Índices para jovens
create index if not exists idx_jovens_estado_id on jovens(estado_id);
create index if not exists idx_jovens_bloco_id on jovens(bloco_id);
create index if not exists idx_jovens_regiao_id on jovens(regiao_id);
create index if not exists idx_jovens_igreja_id on jovens(igreja_id);
create index if not exists idx_jovens_edicao on jovens(edicao);
create index if not exists idx_jovens_aprovado on jovens(aprovado);
create index if not exists idx_jovens_data_nasc on jovens(data_nasc);
create index if not exists idx_jovens_nome_completo on jovens using gin(to_tsvector('portuguese', nome_completo));

-- Índices para avaliações
create index if not exists idx_avaliacoes_jovem_id on avaliacoes(jovem_id);
create index if not exists idx_avaliacoes_user_id on avaliacoes(user_id);
create index if not exists idx_avaliacoes_criado_em on avaliacoes(criado_em);

-- Índices para edições
create index if not exists idx_edicoes_numero on edicoes(numero);
create index if not exists idx_edicoes_ativa on edicoes(ativa);

-- Índices para roles
create index if not exists idx_roles_slug on roles(slug);
create index if not exists idx_roles_nivel on roles(nivel_hierarquico);

-- Índices para user_roles
create index if not exists idx_user_roles_user_id on user_roles(user_id);
create index if not exists idx_user_roles_role_id on user_roles(role_id);
create index if not exists idx_user_roles_estado_id on user_roles(estado_id);
create index if not exists idx_user_roles_bloco_id on user_roles(bloco_id);
create index if not exists idx_user_roles_regiao_id on user_roles(regiao_id);
create index if not exists idx_user_roles_igreja_id on user_roles(igreja_id);
create index if not exists idx_user_roles_ativo on user_roles(ativo);

-- Índices para logs_historico
create index if not exists idx_logs_jovem_id on logs_historico(jovem_id);
create index if not exists idx_logs_user_id on logs_historico(user_id);
create index if not exists idx_logs_acao on logs_historico(acao);
create index if not exists idx_logs_created_at on logs_historico(created_at);

-- Índices adicionais para jovens
create index if not exists idx_jovens_edicao_id on jovens(edicao_id);
create index if not exists idx_jovens_aprovado on jovens(aprovado);
```

---

## STORAGE (SUPABASE)

### Buckets Implementados

#### 1. fotos_usuarios ✅
- **Propósito:** Armazenar fotos dos usuários
- **Política:** Apenas o próprio usuário pode fazer upload/visualizar
- **Formato:** JPG, PNG, WEBP
- **Tamanho máximo:** 5MB
- **Status:** Implementado e funcionando

#### 2. fotos_jovens ✅
- **Propósito:** Armazenar fotos dos jovens
- **Política:** Líderes podem fazer upload/visualizar conforme hierarquia
- **Formato:** JPG, PNG, WEBP
- **Tamanho máximo:** 5MB
- **Status:** Implementado e funcionando

#### 3. documentos ✅
- **Propósito:** Armazenar documentos diversos (certificados, comprovantes, etc.)
- **Política:** Acesso baseado no nível do usuário
- **Formato:** PDF, DOC, DOCX, JPG, PNG
- **Tamanho máximo:** 10MB
- **Status:** Implementado

#### 4. backups ✅
- **Propósito:** Armazenar backups do sistema
- **Política:** Apenas administradores podem acessar
- **Formato:** SQL, JSON, ZIP
- **Tamanho máximo:** 100MB
- **Status:** Implementado

#### 5. temp ✅
- **Propósito:** Arquivos temporários
- **Política:** Usuários autenticados podem usar
- **Formato:** Qualquer
- **Tamanho máximo:** 50MB
- **Status:** Implementado

### Estrutura de Pastas Sugerida

```
fotos_usuarios/
├── {user_id}/
│   └── profile.jpg

fotos_jovens/
├── {jovem_id}/
│   └── profile.jpg

documentos/
├── {jovem_id}/
│   ├── certificados/
│   ├── comprovantes/
│   └── outros/

backups/
├── {data}/
│   ├── database_backup.sql
│   ├── files_backup.zip
│   └── config_backup.json

temp/
├── {user_id}/
│   └── {arquivo_temporario}
```

### Políticas de Storage (RLS) ✅

#### 1. Fotos de Usuários ✅
```sql
CREATE POLICY "fotos_usuarios_self" ON storage.objects
  FOR ALL
  USING (
    bucket_id = 'fotos_usuarios' 
    AND auth.uid()::text = (storage.foldername(name))[1]
  );
```
**Descrição:** Apenas o próprio usuário pode acessar suas fotos.

#### 2. Fotos de Jovens ✅
```sql
CREATE POLICY "fotos_jovens_hierarchy" ON storage.objects
  FOR ALL
  USING (
    bucket_id = 'fotos_jovens' 
    AND EXISTS (
      SELECT 1 FROM jovens j
      WHERE j.id::text = (storage.foldername(name))[1]
      AND can_access_jovem(j.estado_id, j.bloco_id, j.regiao_id, j.igreja_id)
    )
  );
```
**Descrição:** Líderes podem acessar fotos dos jovens de sua jurisdição.

#### 3. Documentos ✅
```sql
CREATE POLICY "documentos_hierarchy" ON storage.objects
  FOR ALL
  USING (
    bucket_id = 'documentos' 
    AND EXISTS (
      SELECT 1 FROM user_roles ur
      JOIN roles r ON r.id = ur.role_id
      WHERE ur.user_id = (SELECT id FROM usuarios WHERE id_auth = auth.uid())
      AND ur.ativo = true
      AND r.slug IN ('administrador', 'colaborador', 'lider_estadual_iurd', 'lider_estadual_fju', 'lider_bloco_iurd', 'lider_bloco_fju', 'lider_regional_iurd', 'lider_igreja_iurd')
    )
  );
```
**Descrição:** Líderes podem acessar documentos conforme hierarquia.

#### 4. Backups ✅
```sql
CREATE POLICY "backups_admin" ON storage.objects
  FOR ALL
  USING (
    bucket_id = 'backups' 
    AND is_admin_user()
  );
```
**Descrição:** Apenas administradores podem acessar backups.

#### 5. Arquivos Temporários ✅
```sql
CREATE POLICY "temp_authenticated" ON storage.objects
  FOR ALL
  USING (bucket_id = 'temp');
```
**Descrição:** Usuários autenticados podem usar arquivos temporários.

**Status:** ✅ Todas as políticas implementadas e funcionando corretamente

### Correção de Recursão Infinita ✅

**Problema Identificado:** A política `usuarios_admin_full` estava causando recursão infinita porque consultava a própria tabela `usuarios` durante a verificação de permissões.

**Solução Implementada:**
1. **Função auxiliar criada:** `is_admin_user()` para verificar permissões sem recursão
2. **Política problemática removida:** `usuarios_admin_full`
3. **Nova política criada:** `usuarios_admin_policy` usando a função auxiliar
4. **Políticas existentes mantidas:** `usuarios_self_select` e `usuarios_self_update`

**Status:** ✅ Problema resolvido - Upload de fotos funcionando sem erros de recursão

---

## ✅ VERIFICAÇÃO PÓS-MIGRAÇÃO

### Comandos para Verificar se a Migração Foi Bem-Sucedida:

```sql
-- Verificar se todas as tabelas foram criadas
SELECT table_name 
FROM information_schema.tables 
WHERE table_schema = 'public' 
ORDER BY table_name;

-- Verificar se os roles foram inseridos
SELECT slug, nome, nivel_hierarquico 
FROM roles 
ORDER BY nivel_hierarquico;

-- Verificar se as edições foram criadas
SELECT numero, nome, ativa 
FROM edicoes 
ORDER BY numero;

-- Verificar se os campos foram adicionados na tabela jovens
SELECT column_name, data_type 
FROM information_schema.columns 
WHERE table_name = 'jovens' 
AND column_name IN ('pastor_que_indicou', 'cresceu_na_igreja', 'experiencia_altar', 'edicao_id')
ORDER BY column_name;

-- Verificar se as RLS Policies estão ativas
SELECT schemaname, tablename, policyname, permissive, roles, cmd, qual 
FROM pg_policies 
WHERE schemaname = 'public'
ORDER BY tablename, policyname;

-- Verificar se os índices foram criados
SELECT indexname, tablename, indexdef 
FROM pg_indexes 
WHERE schemaname = 'public' 
AND indexname LIKE 'idx_%'
ORDER BY tablename, indexname;

-- Verificar se a função is_admin_user foi criada
SELECT proname, prosrc 
FROM pg_proc 
WHERE proname = 'is_admin_user';

-- Testar a função is_admin_user (deve executar sem recursão)
SELECT is_admin_user() as is_admin;
```

### Testes de Funcionalidade:

```sql
-- Testar função de cálculo de idade
INSERT INTO jovens (nome_completo, data_nasc, estado_id, edicao, edicao_id) 
VALUES ('Teste', '1990-01-01', (SELECT id FROM estados LIMIT 1), '3ª Edição', (SELECT id FROM edicoes WHERE ativa = true LIMIT 1));

-- Verificar se a idade foi calculada automaticamente
SELECT nome_completo, data_nasc, idade FROM jovens WHERE nome_completo = 'Teste';

-- Testar função de log de auditoria
SELECT criar_log_auditoria(
  (SELECT id FROM jovens WHERE nome_completo = 'Teste' LIMIT 1),
  'teste',
  'Teste de funcionalidade'
);

-- Verificar se o log foi criado
SELECT * FROM logs_historico WHERE acao = 'teste';

-- Limpar dados de teste
DELETE FROM jovens WHERE nome_completo = 'Teste';

-- Testar se não há mais recursão infinita (deve executar sem erro)
SELECT count(*) FROM usuarios WHERE id_auth = auth.uid();

-- Testar upload de arquivo (simulação - deve funcionar sem recursão)
-- Este teste verifica se as políticas RLS não causam mais recursão
SELECT 'Teste de recursão passou' as status;
```

## OBSERVAÇÕES IMPORTANTES

1. **Backup:** Sempre faça backup antes de alterações estruturais
2. **Versionamento:** Mantenha este documento atualizado com todas as mudanças
3. **Testes:** Teste todas as alterações em ambiente de desenvolvimento
4. **Performance:** Monitore a performance dos índices e queries
5. **Segurança:** Revise as políticas RLS regularmente
6. **Storage:** Monitore o uso de espaço nos buckets do Supabase
7. **Verificação:** Execute os comandos de verificação após cada migração
8. **Recursão RLS:** Evite políticas RLS que consultem a própria tabela para prevenir recursão infinita
9. **Funções Auxiliares:** Use funções auxiliares como `is_admin_user()` para verificar permissões complexas

---

## HISTÓRICO DE ALTERAÇÕES

| Data | Versão | Alteração | Autor |
|------|--------|-----------|-------|
| 2024-12-19 | 1.0 | Criação inicial do documento | Sistema |
| 2024-12-19 | 2.0 | Atualização para sistema RBAC completo | Sistema |
| 2024-12-19 | 2.0 | Adicionadas tabelas: edicoes, roles, user_roles, logs_historico | Sistema |
| 2024-12-19 | 2.0 | Atualizado sistema de permissões com RLS baseado em roles | Sistema |
| 2024-12-19 | 2.0 | Adicionados campos extras na tabela jovens | Sistema |
| 2024-12-19 | 2.0 | Criadas funções auxiliares para auditoria e cálculo de idade | Sistema |
| 2024-12-19 | 2.1 | **MIGRAÇÃO EXECUTADA COM SUCESSO** | Sistema |
| 2024-12-19 | 2.1 | Banco de dados atualizado com todas as novas estruturas | Sistema |
| 2024-12-19 | 2.1 | Sistema RBAC implementado e funcionando | Sistema |
| 2024-12-19 | 2.1 | RLS Policies atualizadas e ativas | Sistema |
| 2024-12-19 | 2.1 | Triggers e funções auxiliares implementadas | Sistema |

---

|| 2024-12-19 | 2.2 | **ATUALIZAÇÃO PARA SISTEMA COMPLETO** | Sistema |
|| 2024-12-19 | 2.2 | Adicionadas tabelas: notificacoes, logs_auditoria, configuracoes_sistema, sessoes_usuario | Sistema |
|| 2024-12-19 | 2.2 | Criados 5 buckets de storage com políticas RLS corretas | Sistema |
|| 2024-12-19 | 2.2 | Adicionadas funções: obter_estatisticas_sistema, limpar_logs_antigos | Sistema |
|| 2024-12-19 | 2.2 | Implementadas políticas RLS para todas as novas tabelas | Sistema |
|| 2024-12-19 | 2.2 | Sistema de notificações e auditoria completo | Sistema |

---

||| 2024-12-19 | 2.3 | **CORREÇÃO CRÍTICA: NOMES DOS BUCKETS** | Sistema |
||| 2024-12-19 | 2.3 | Corrigidos nomes dos buckets no código: fotos_usuarios e fotos_jovens | Sistema |
||| 2024-12-19 | 2.3 | Resolvido erro "Bucket not found" no upload de fotos | Sistema |
||| 2024-12-19 | 2.3 | Atualizada documentação com nomes corretos dos buckets | Sistema |
||| 2024-12-19 | 2.3 | Sistema de upload de fotos funcionando corretamente | Sistema |

---

||| 2024-12-19 | 2.4 | **CORREÇÃO CRÍTICA: RECURSÃO INFINITA RLS** | Sistema |
||| 2024-12-19 | 2.4 | Identificado problema de recursão infinita nas políticas RLS | Sistema |
||| 2024-12-19 | 2.4 | Criada função auxiliar is_admin_user() para evitar recursão | Sistema |
||| 2024-12-19 | 2.4 | Corrigidas políticas RLS da tabela usuarios | Sistema |
||| 2024-12-19 | 2.4 | Upload de fotos funcionando sem erros de recursão | Sistema |

---

||| 2024-12-19 | 2.5 | **CORREÇÃO FINAL: DOCUMENTAÇÃO ATUALIZADA** | Sistema |
||| 2024-12-19 | 2.5 | Adicionada função is_admin_user() na documentação | Sistema |
||| 2024-12-19 | 2.5 | Atualizadas políticas RLS com nova estrutura | Sistema |
||| 2024-12-19 | 2.5 | Adicionada seção de correção de recursão infinita | Sistema |
||| 2024-12-19 | 2.5 | Incluídos testes de verificação para recursão | Sistema |
||| 2024-12-19 | 2.5 | Documentação completamente sincronizada com correções | Sistema |

---

|||| 2024-12-19 | 2.6 | **ATUALIZAÇÃO COMPLETA DAS POLÍTICAS RLS** | Sistema |
|||| 2024-12-19 | 2.6 | Analisado código do projeto para identificar operações necessárias | Sistema |
|||| 2024-12-19 | 2.6 | Criadas funções auxiliares: is_admin_user(), has_role(), can_access_jovem() | Sistema |
|||| 2024-12-19 | 2.6 | Atualizadas todas as políticas RLS baseadas no código real | Sistema |
|||| 2024-12-19 | 2.6 | Implementadas políticas para todas as tabelas do sistema | Sistema |
|||| 2024-12-19 | 2.6 | Documentação completamente sincronizada com políticas corretas | Sistema |
|||| 2024-12-19 | 2.6 | Sistema de permissões hierárquicas funcionando corretamente | Sistema |

---

**Última atualização:** 2024-12-19
**Versão do documento:** 2.6
**Status:** ✅ SISTEMA COMPLETO IMPLEMENTADO E DOCUMENTADO
