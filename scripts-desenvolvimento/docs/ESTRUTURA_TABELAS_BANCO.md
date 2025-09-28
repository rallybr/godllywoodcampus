# Estrutura de Tabelas - Banco de Dados (Postgres/Supabase)

Documento de referência com a estrutura das tabelas atuais do sistema IntelliMen Campus. Inclui colunas, tipos, defaults, chaves primárias e chaves estrangeiras conhecidas.

Observação: onde o tipo ou default não foi explicitado, foi mantido em branco. Atualize este arquivo ao alterar o schema.

---

## public.usuarios

Campos:

| Coluna | Tipo | Default | Notas |
|---|---|---|---|
| id | uuid | | PK |
| id_auth | uuid | | Auth user id (Supabase) |
| foto | text | | URL |
| nome | text | |  |
| sexo | text | |  |
| nivel | integer | |  |
| estado_id | uuid | | FK -> estados.id |
| bloco_id | uuid | | FK -> blocos.id |
| regiao_id | uuid | | FK -> regioes.id |
| igreja_id | uuid | | FK -> igrejas.id |
| criado_em | timestamp | |  |
| email | text | |  |
| estado_bandeira | text | |  |
| ativo | boolean | |  |

---

## public.user_roles

| Coluna | Tipo | Default | Notas |
|---|---|---|---|
| id | uuid | | PK |
| user_id | uuid | | FK -> usuarios.id |
| role_id | uuid | | FK -> roles.id |
| estado_id | uuid | | (escopo) FK -> estados.id |
| bloco_id | uuid | | (escopo) FK -> blocos.id |
| regiao_id | uuid | | (escopo) FK -> regioes.id |
| igreja_id | uuid | | (escopo) FK -> igrejas.id |
| ativo | boolean | |  |
| criado_em | timestamp | |  |
| criado_por | uuid | |  |

---

## public.roles

| Coluna | Tipo | Default | Notas |
|---|---|---|---|
| id | uuid | | PK |
| slug | text | | único por função |
| nome | text | |  |
| descricao | text | |  |
| nivel_hierarquico | integer | |  |
| criado_em | timestamp | |  |

---

## public.regioes

| Coluna | Tipo | Default | Notas |
|---|---|---|---|
| id | uuid | | PK |
| bloco_id | uuid | | FK -> blocos.id |
| nome | text | |  |

---

## public.notificacoes

| Coluna | Tipo | Default | Notas |
|---|---|---|---|
| id | uuid | | PK |
| tipo | text | |  |
| titulo | text | |  |
| mensagem | text | |  |
| destinatario_id | uuid | | FK -> usuarios.id |
| remetente_id | uuid | | FK -> usuarios.id |
| jovem_id | uuid | | FK -> jovens.id |
| acao_url | text | |  |
| lida | boolean | |  |
| lida_em | timestamp | |  |
| criado_em | timestamp | |  |
| atualizado_em | timestamp | |  |

---

## public.jovens

| Coluna | Tipo | Default | Notas |
|---|---|---|---|
| id | uuid | | PK |
| estado_id | uuid | | FK -> estados.id |
| bloco_id | uuid | | FK -> blocos.id |
| regiao_id | uuid | | FK -> regioes.id |
| igreja_id | uuid | | FK -> igrejas.id |
| edicao | text | |  |
| foto | text | |  |
| nome_completo | text | |  |
| whatsapp | text | |  |
| data_nasc | date | |  |
| data_cadastro | timestamp | |  |
| estado_civil | text | |  |
| namora | boolean | |  |
| tem_filho | boolean | |  |
| trabalha | boolean | |  |
| local_trabalho | text | |  |
| escolaridade | text | |  |
| formacao | text | |  |
| tem_dividas | boolean | |  |
| tempo_igreja | text | |  |
| batizado_aguas | boolean | |  |
| data_batismo_aguas | date | |  |
| batizado_es | boolean | |  |
| data_batismo_es | date | |  |
| condicao | text | |  |
| tempo_condicao | text | |  |
| responsabilidade_igreja | text | |  |
| disposto_servir | boolean | |  |
| ja_obra_altar | boolean | |  |
| ja_obreiro | boolean | |  |
| ja_colaborador | boolean | |  |
| afastado | boolean | |  |
| data_afastamento | date | |  |
| motivo_afastamento | text | |  |
| data_retorno | date | |  |
| pais_na_igreja | boolean | |  |
| observacao_pais | text | | (coluna legada; ver `obs_pais`) |
| familiares_igreja | boolean | |  |
| deseja_altar | boolean | |  |
| observacao | text | |  |
| testemunho | text | |  |
| instagram | text | |  |
| facebook | text | |  |
| tiktok | text | |  |
| obs_redes | text | |  |
| aprovado | text | | enum textual |
| pastor_que_indicou | text | |  |
| cresceu_na_igreja | boolean | |  |
| experiencia_altar | boolean | |  |
| foi_obreiro | boolean | |  |
| foi_colaborador | boolean | |  |
| afastou | boolean | |  |
| quando_afastou | date | |  |
| motivo_afastou | text | |  |
| quando_voltou | date | |  |
| pais_sao_igreja | boolean | |  |
| obs_pais | text | |  |
| observacao_text | text | |  |
| testemunho_text | text | |  |
| edicao_id | uuid | | FK -> edicoes.id |
| idade | integer | |  |
| sexo | text | |  |
| observacao_redes | text | |  |
| formado_intellimen | boolean | |  |
| fazendo_desafios | boolean | |  |
| qual_desafio | text | |  |
| valor_divida | numeric | |  |
| usuario_id | uuid | | FK -> usuarios.id |

---

## public.igrejas

| Coluna | Tipo | Default | Notas |
|---|---|---|---|
| id | uuid | | PK |
| regiao_id | uuid | | FK -> regioes.id |
| nome | text | |  |
| endereco | text | |  |

---

## public.estados

| Coluna | Tipo | Default | Notas |
|---|---|---|---|
| id | uuid | | PK |
| nome | text | |  |
| sigla | text | |  |

---

## public.edicoes

| Coluna | Tipo | Default | Notas |
|---|---|---|---|
| id | uuid | | PK |
| numero | integer | |  |
| nome | text | |  |
| data_inicio | date | |  |
| data_fim | date | |  |
| ativa | boolean | |  |
| criado_em | timestamp | |  |

---

## public.blocos

| Coluna | Tipo | Default | Notas |
|---|---|---|---|
| id | uuid | | PK |
| estado_id | uuid | | FK -> estados.id |
| nome | text | |  |

---

## public.avaliacoes

| Coluna | Tipo | Default | Notas |
|---|---|---|---|
| id | uuid | | PK |
| jovem_id | uuid | | FK -> jovens.id |
| user_id | uuid | | FK -> usuarios.id |
| espirito | integer | |  |
| caractere | integer | |  |
| disposicao | integer | |  |
| avaliacao_texto | text | |  |
| nota | integer | |  |
| criado_em | timestamp | |  |
| data | date | |  |

---

# Nova tabela

## public.dados_viagem (novo)

| Coluna | Tipo | Default | Notas |
|---|---|---|---|
| id | uuid | `gen_random_uuid()` | PK |
| jovem_id | uuid | | FK -> public.jovens.id |
| edicao_id | uuid | | FK -> public.edicoes.id |
| pagou_despesas | boolean | `false` |  |
| comprovante_pagamento | text | | URL no storage |
| data_passagem_ida | timestamptz | |  |
| comprovante_passagem_ida | text | | URL no storage |
| data_passagem_volta | timestamptz | |  |
| comprovante_passagem_volta | text | | URL no storage |
| data_cadastro | timestamptz | `now()` |  |
| atualizado_em | timestamptz | `now()` | via trigger `atualizar_timestamp` |
| usuario_id | uuid | | FK -> public.usuarios.id |

Índices sugeridos:
- UNIQUE (jovem_id, edicao_id)

RLS sugerido:
- SELECT/INSERT/UPDATE conforme `can_access_jovem(j.estado_id, j.bloco_id, j.regiao_id, j.igreja_id)` e permissão do próprio jovem (via `jovens.usuario_id`).
- DELETE apenas administradores.

---

# Tabelas adicionais (dos prints anexados)

## public.logs_auditoria

| Coluna | Tipo | Default | Notas |
|---|---|---|---|
| id | uuid | `gen_random_uuid()` | PK |
| usuario_id | uuid | | FK -> public.usuarios.id |
| acao | varchar | |  |
| detalhe | text | |  |
| dados_antigos | jsonb | |  |
| dados_novos | jsonb | |  |
| ip_address | inet | |  |
| user_agent | text | |  |
| criado_em | timestamp | `now()` |  |

FKs:
- `usuario_id` → `public.usuarios.id`

---

## public.configuracoes_sistema

| Coluna | Tipo | Default | Notas |
|---|---|---|---|
| id | uuid | `gen_random_uuid()` | PK |
| chave | varchar | |  |
| valor | jsonb | `{}` |  |
| descricao | text | |  |
| categoria | varchar | `'geral'` (inferido) | categoria da configuração |
| criado_em | timestamp | `now()` |  |
| atualizado_em | timestamp | `now()` |  |

FKs: —

---

## public.sessoes_usuario

| Coluna | Tipo | Default | Notas |
|---|---|---|---|
| id | uuid | `gen_random_uuid()` | PK |
| usuario_id | uuid | | FK -> public.usuarios.id |
| token_hash | varchar | |  |
| ip_address | inet | |  |
| user_agent | text | |  |
| ativo | bool | `true` |  |
| expira_em | timestamp | |  |
| criado_em | timestamp | `now()` |  |
| atualizado_em | timestamp | `now()` |  |

FKs:
- `usuario_id` → `public.usuarios.id`

---

## public.logs_historico

| Coluna | Tipo | Default | Notas |
|---|---|---|---|
| id | uuid | `gen_random_uuid()` | PK |
| jovem_id | uuid | | FK -> public.jovens.id |
| user_id | uuid | | FK -> public.usuarios.id |
| acao | text | |  |
| detalhe | text | |  |
| dados_anteriores | jsonb | | nome inferido pelo print (campo de "dados antigos") |
| dados_novos | jsonb | |  |
| created_at | timestamp | `now()` |  |

FKs:
- `jovem_id` → `public.jovens.id`
- `user_id` → `public.usuarios.id`

---

## Observações Gerais
- Considere adicionar `created_at/updated_at` consistentes (triggers `atualizar_timestamp`) quando aplicável.
- Utilize `gen_random_uuid()` para PKs UUID quando disponível.
- Tipos `varchar/text` podem ser normalizados conforme necessidade.
- Mantenha este documento sincronizado com migrações SQL.
