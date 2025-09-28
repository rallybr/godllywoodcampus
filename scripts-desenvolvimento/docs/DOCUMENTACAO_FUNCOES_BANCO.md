# Documentação de Functions do Banco de Dados (Postgres/Supabase)

Esta referência lista todas as functions atualmente utilizadas pelo sistema IntelliMen Campus, com propósito, assinatura, parâmetros, retorno, dependências e uso típico (triggers/processos). Use este arquivo como base para manutenção e evolução de RLS, triggers e integrações.

Observação: tipos foram inferidos a partir dos trechos fornecidos e do padrão do schema; ajuste se o tipo em banco divergir.

---

## atribuir_papel_padrao_jovem
- Assinatura sugerida: `atribuir_papel_padrao_jovem() RETURNS trigger`
- Propósito: Atribui automaticamente o papel padrão "jovem" ao novo usuário quando ele ainda não possui nenhum papel.
- Parâmetros: usa `NEW.id` via trigger (sem parâmetros explícitos).
- Retorno: `NEW` (trigger BEFORE/AFTER INSERT em `usuarios`).
- Dependências: tabelas `public.roles` (slug 'jovem') e `public.user_roles`; extensão `uuid_generate_v4()`.
- Uso típico: Trigger em `usuarios` após inserção.

---

## atualizar_timestamp
- Assinatura sugerida: `atualizar_timestamp() RETURNS trigger`
- Propósito: Atualiza `NEW.atualizado_em` com `NOW()` em updates.
- Parâmetros: usa `NEW` via trigger.
- Retorno: `NEW` (trigger BEFORE UPDATE na(s) tabela(s) que possuem a coluna `atualizado_em`).
- Dependências: nenhuma além da coluna `atualizado_em`.

---

## can_access_jovem
- Assinatura sugerida: `can_access_jovem(jovem_estado_id uuid, jovem_bloco_id uuid, jovem_regiao_id uuid, jovem_igreja_id uuid) RETURNS boolean`
- Propósito: Checa, pelas roles e escopo do usuário autenticado, se ele pode acessar um jovem específico.
- Parâmetros: ids de estado, bloco, região e igreja do jovem.
- Retorno: `boolean` (permite/nega acesso).
- Dependências: `user_roles`, `roles`, `usuarios` e `auth.uid()`.
- Observações: Permite acesso para slugs: `administrador`, `colaborador`, líderes escopados (estadual/bloco/regional/igreja) condizentes com os IDs informados.

---

## criar_lembretes_avaliacao
- Assinatura sugerida: `criar_lembretes_avaliacao() RETURNS void`
- Propósito: Gera notificações de lembrete para líderes quando jovens estão há 7+ dias sem avaliação e sem lembrete recente (3 dias).
- Parâmetros: —
- Retorno: `void`
- Dependências: tabelas `jovens`, `avaliacoes`, `notificacoes` e function `obter_lideres_para_notificacao(...)`.
- Observações: Processo batch (pode ser agendado via cron/Supabase Scheduler).

---

## criar_log_auditoria
- Assinatura sugerida: `criar_log_auditoria(p_usuario_id uuid, p_acao text, p_detalhe text, p_dados_antigos jsonb, p_dados_novos jsonb) RETURNS uuid`
- Propósito: Insere um registro em `logs_auditoria` capturando metadados da requisição.
- Parâmetros: conforme assinatura.
- Retorno: `uuid` do log criado.
- Dependências: tabela `logs_auditoria`, `inet_client_addr()`, `current_setting('request.headers', true)`.

---

## criar_notificacao_automatica
- Assinatura sugerida: `criar_notificacao_automatica() RETURNS trigger`
- Propósito: Cria notificações automáticas em dois cenários:
  - INSERT em `jovens`: notifica admin/colaborador sobre novo cadastro
  - INSERT em `avaliacoes`: notifica admin/colaborador sobre nova avaliação
- Parâmetros: usa `TG_OP`, `TG_TABLE_NAME`, `NEW`.
- Retorno: `COALESCE(NEW, OLD)`.
- Dependências: `notificacoes`, `usuarios`, `user_roles`, `roles`.
- Uso típico: Trigger AFTER INSERT em `jovens` e `avaliacoes`.

---

## filtrar_jovens
- Assinatura sugerida: `filtrar_jovens(filters jsonb) RETURNS TABLE (
  id uuid,
  nome_completo text,
  estado_id uuid,
  bloco_id uuid,
  regiao_id uuid,
  igreja_id uuid,
  edicao text,
  idade int,
  aprovado text
)`
- Propósito: Endpoint SQL para listagem filtrada de jovens.
- Parâmetros: `filters` em JSONB (chaves: `estado_id`, `bloco_id`, `regiao_id`, `igreja_id`, `edicao`, `nome_like`).
- Retorno: conjunto de registros com campos essenciais.
- Dependências: tabela `jovens`.

---

## get_user_by_auth_id
- Assinatura sugerida: `get_user_by_auth_id(auth_id uuid) RETURNS TABLE (id uuid, nome text, id_auth uuid)`
- Propósito: Retorna o usuário do app a partir do `auth_id` (Supabase Auth).
- Parâmetros: `auth_id`.
- Retorno: `id`, `nome`, `id_auth`.
- Dependências: tabela `usuarios`.

---

## has_role
- Assinatura sugerida: `has_role(role_slug text) RETURNS boolean`
- Propósito: Verifica se o usuário autenticado possui a role informada.
- Parâmetros: `role_slug`.
- Retorno: `boolean`.
- Dependências: `public.user_roles`, `public.roles`, `public.usuarios`, `auth.uid()`.

---

## is_admin_user
- Assinatura sugerida: `is_admin_user() RETURNS boolean`
- Propósito: Verifica se o usuário autenticado é administrador ativo.
- Parâmetros: —
- Retorno: `boolean`.
- Dependências: `user_roles`, `roles`, `usuarios`, `auth.uid()`.

---

## limpar_logs_antigos
- Assinatura sugerida: `limpar_logs_antigos(dias_retencao integer) RETURNS integer`
- Propósito: Remove logs de auditoria mais antigos que `dias_retencao` dias.
- Parâmetros: `dias_retencao`.
- Retorno: `integer` (quantidade removida via `ROW_COUNT`).
- Dependências: tabela `logs_auditoria`.

---

## limpar_notificacoes_antigas
- Assinatura sugerida: `limpar_notificacoes_antigas() RETURNS integer`
- Propósito: Remove notificações com mais de 30 dias.
- Parâmetros: —
- Retorno: `integer` (quantidade removida).
- Dependências: tabela `notificacoes`.

---

## notificar_lideres
- Assinatura sugerida: `notificar_lideres(p_tipo text, p_titulo text, p_mensagem text, p_jovem_id uuid, p_acao_url text) RETURNS void`
- Propósito: Cria notificações para os líderes relevantes de acordo com o escopo do jovem.
- Parâmetros: tipo/título/mensagem/`jovem_id`/`acao_url`.
- Retorno: `void`.
- Dependências: `notificacoes` e `obter_lideres_para_notificacao(...)`.

---

## obter_estatisticas_sistema
- Assinatura sugerida: `obter_estatisticas_sistema() RETURNS json`
- Propósito: Agrega estatísticas gerais do sistema (contagens principais e métricas diárias).
- Parâmetros: —
- Retorno: `json` com chaves: `total_usuarios`, `total_jovens`, `total_avaliacoes`, `total_notificacoes`, `usuarios_ativos`, `jovens_aprovados`, `avaliacoes_hoje`, `notificacoes_nao_lidas`.
- Dependências: tabelas `usuarios`, `jovens`, `avaliacoes`, `notificacoes`.

---

## obter_lideres_para_notificacao
- Assinatura sugerida: `obter_lideres_para_notificacao(p_estado_id uuid, p_bloco_id uuid, p_regiao_id uuid, p_igreja_id uuid) RETURNS TABLE (user_id uuid)`
- Propósito: Resolve o conjunto de `user_id` de líderes que devem receber uma notificação, considerando os escopos (nacional/estadual/bloco/regional/igreja) e também admin/colaborador.
- Parâmetros: ids de escopo.
- Retorno: conjunto de `user_id` (DISTINCT).
- Dependências: `user_roles`, `roles`.

---

## recalcular_idade
- Assinatura sugerida: `recalcular_idade() RETURNS trigger`
- Propósito: Recalcula `NEW.idade` com base em `NEW.data_nasc` sempre que inserir/atualizar.
- Parâmetros: usa `NEW` via trigger.
- Retorno: `NEW`.
- Uso típico: BEFORE INSERT/UPDATE em `jovens`.

---

## set_usuario_id_on_insert
- Assinatura sugerida: `set_usuario_id_on_insert() RETURNS trigger`
- Propósito: Preenche `NEW.usuario_id` com o usuário atual (via `auth.uid()`) quando não informado.
- Parâmetros: usa `NEW` via trigger.
- Retorno: `NEW`.
- Dependências: `public.usuarios`, `auth.uid()`.
- Uso típico: BEFORE INSERT na(s) tabela(s) que possuem `usuario_id` (ex.: `jovens`).

---

## trigger_notificar_mudanca_status
- Assinatura sugerida: `trigger_notificar_mudanca_status() RETURNS trigger`
- Propósito: Ao alterar o campo `aprovado` de um jovem, envia notificação com descrição do status anterior e novo.
- Parâmetros: usa `OLD`, `NEW` via trigger.
- Retorno: `NEW`.
- Dependências: function `notificar_lideres(...)`.
- Uso típico: AFTER UPDATE em `jovens` quando `aprovado` muda.

---

## trigger_notificar_nova_avaliacao
- Assinatura sugerida: `trigger_notificar_nova_avaliacao() RETURNS trigger`
- Propósito: Ao inserir uma avaliação, envia notificação para líderes.
- Parâmetros: usa `NEW` via trigger.
- Retorno: `NEW`.
- Dependências: function `notificar_lideres(...)`.
- Uso típico: AFTER INSERT em `avaliacoes`.

---

## trigger_notificar_novo_cadastro
- Assinatura sugerida: `trigger_notificar_novo_cadastro() RETURNS trigger`
- Propósito: Ao inserir um novo jovem, envia notificação para líderes.
- Parâmetros: usa `NEW` via trigger.
- Retorno: `NEW`.
- Dependências: function `notificar_lideres(...)`.
- Uso típico: AFTER INSERT em `jovens`.

---

## set_usuario_id_on_insert_dados_viagem (sugerida)
- Assinatura: `set_usuario_id_on_insert_dados_viagem() RETURNS trigger`
- Propósito: Preenche `NEW.usuario_id` com o usuário atual ao inserir em `dados_viagem`.
- Parâmetros: usa `NEW` via trigger e `auth.uid()`.
- Retorno: `NEW`.
- Uso típico: BEFORE INSERT em `public.dados_viagem`.

---

## criar_log_viagem_update (opcional)
- Assinatura: `criar_log_viagem_update() RETURNS trigger`
- Propósito: Grava em `logs_historico` alterações de `dados_viagem` com `acao = 'viagem_update'`.
- Parâmetros: `OLD`, `NEW`.
- Retorno: `NEW`.
- Uso típico: AFTER INSERT/UPDATE em `public.dados_viagem`.

---
## Mapas de Uso (Triggers sugeridos)

- `usuarios`
  - AFTER INSERT: `atribuir_papel_padrao_jovem()`
  - BEFORE UPDATE: `atualizar_timestamp()`

- `jovens`
  - BEFORE INSERT/UPDATE: `recalcular_idade()`
  - BEFORE INSERT: `set_usuario_id_on_insert()`
  - AFTER INSERT: `trigger_notificar_novo_cadastro()` ou `criar_notificacao_automatica()`
  - AFTER UPDATE (campo `aprovado`): `trigger_notificar_mudanca_status()`

- `avaliacoes`
  - AFTER INSERT: `trigger_notificar_nova_avaliacao()` ou `criar_notificacao_automatica()`

---

## Observações Operacionais
- Functions que usam `auth.uid()` devem ser executadas no contexto de sessão autenticada (RPC do Supabase ou policies que respeitem JWT do usuário).
- Para jobs/schedulers, considere usar service role apenas quando necessário e com RLS apropriada.
- Mantenha versões/CHANGELOG das functions ao fazer ajustes de regras de negócio.

---

Última atualização desta documentação: mantenha este carimbo atualizado sempre que alterar qualquer function.
