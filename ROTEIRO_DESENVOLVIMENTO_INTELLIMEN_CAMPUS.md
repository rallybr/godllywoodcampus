# ROTEIRO_DESEnVOLVIMENTO_INTELLIMEN_CAMPUS

Este roteiro consolida objetivos, status atual, funcionalidades, backlog e diretrizes técnicas do IntelliMen Campus. Ele está alinhado com:
- `POLITICAS_RLS_COMPLETAS.md`
- `DOCUMENTACAO_FUNCOES_BANCO.md`
- `ESTRUTURA_TABELAS_BANCO.md`
E com o código presente em `src/` (Svelte + Tailwind + Supabase).

Atualize este roteiro sempre que uma nova funcionalidade ou alteração estrutural for concluída.

---

## 1) Visão geral e objetivos

- Plataforma de cadastro, avaliação e acompanhamento de jovens participantes do IntelliMen Campus.
- Foco em:
  - Cadastro completo (multi-etapas) de jovens
  - Avaliações por líderes/pastores com diferentes níveis de acesso
  - Relatórios, estatísticas e notificações
  - Experiência mobile-first, “look & feel” Facebook/Instagram

Tecnologias: SvelteKit, TypeScript/JS, Tailwind CSS, Supabase (Auth/DB/Storage), Vercel.

---

## 2) Matriz de papéis e escopos (RLS)

Os níveis abaixo definem o escopo de dados visível. Detalhes e políticas em `POLITICAS_RLS_COMPLETAS.md`.

- administrador: acesso total ao sistema
- lider_nacional_iurd, lider_nacional_fju: visão nacional
- lider_estadual_iurd, lider_estadual_fju: visão por estado (blocos, regiões, igrejas do estado)
- lider_bloco_iurd, lider_bloco_fju: visão por bloco (regiões e igrejas do bloco)
- lider_regional_iurd: visão por região (todas as igrejas da região)
- lider_igreja_iurd: visão por igreja
- colaborador: vê/gerencia o que criou
- jovem: vê e gerencia seus próprios dados

Implementação: ver RLS por tabela e funções auxiliares (`has_role`, `is_admin_user`, `can_access_jovem`, etc.).

---

## 3) Estrutura de dados (resumo)

- Tabelas principais: `usuarios`, `user_roles`, `roles`, `estados`, `blocos`, `regioes`, `igrejas`, `edicoes`, `jovens`, `avaliacoes`, `notificacoes`.
- Tabelas de apoio/ops: `logs_auditoria`, `logs_historico`, `sessoes_usuario`, `configuracoes_sistema`.
- Detalhes de colunas, FKs e defaults em `ESTRUTURA_TABELAS_BANCO.md`.

---

## 4) Functions e triggers (resumo)

Principais funções documentadas em `DOCUMENTACAO_FUNCOES_BANCO.md`:
- Acesso/RLS: `has_role`, `is_admin_user`, `can_access_jovem`, `get_user_by_auth_id`
- Notificações: `obter_lideres_para_notificacao`, `notificar_lideres`, `criar_notificacao_automatica`
- Auditoria/Manutenção: `criar_log_auditoria`, `limpar_logs_antigos`, `limpar_notificacoes_antigas`, `obter_estatisticas_sistema`
- Triggers utilitárias: `recalcular_idade`, `set_usuario_id_on_insert`, `atualizar_timestamp`, `trigger_notificar_*`

---

## 5) Funcionalidades atuais (frontend)

- Autenticação Supabase + guarda de rotas; layout com `Header` e `Sidebar` responsivos
- Cadastro de Jovem (multi-etapas) com:
  - Foto com crop responsivo (suporte a toque)
  - Dados pessoais, localização (estado/bloco/região/igreja), edição
  - Campos profissionais, espirituais, experiência, família, observações
  - Redes sociais (instagram, facebook, tiktok, obs_redes)
  - Híbrido de datas (input texto + botão calendário nativo)
  - Limpeza de payload antes do insert (remover strings vazias em datas/numéricos)
- Listagens e filtros:
  - Jovens: filtros por edição, sexo, condição, aprovação, idade, estado/bloco/região/igreja
  - Avaliações: listagem e inserção via modal
- Relatórios/Estatísticas: dashboards básicos
- Notificações: dropdown e listagem; regras de envio por triggers/functions
- Responsividade mobile-first; UX parecida com rede social

Código-fonte relevante:
- `src/lib/components/forms/CadastroJovem.svelte`
- `src/lib/stores/{jovens,avaliacoes,notificacoes,geographic}.js`
- `src/routes/**` (páginas e dashboards)

---

## 6) O que falta / melhorias identificadas

Alinhar implementação com documentação e fechar lacunas:

- Perfis de usuários (página de perfil por papel):
  - Jovem: visão do próprio cadastro e status
  - Líderes: listagens contextuais (estado/bloco/região/igreja) + atalhos
  - Admin/Colab: visão geral com filtros avançados
- Gestão de papéis e escopos no app (UI):
  - Tela de cadastro/edição de user_roles (atribuição de escopo)
  - Fluxo para “Troca de liderança” por localidade
- Relatórios:
  - Painéis por papel (nacional/estadual/bloco/região/igreja) com filtros persistentes e exportação
- Auditoria e segurança:
  - UI dedicada para `logs_auditoria` e `logs_historico`
  - Página de sessões ativas (`sessoes_usuario`) e revogação manual
- Notificações:
  - Preferências por usuário (categorias de notificação) via `configuracoes_sistema`
  - Marcar lida em lote e indicadores por papel
- Avaliações:
  - Histórico consolidado por jovem (timeline)
  - Métricas agregadas (médias/últimas notas) nos cards
- UX/Polimento:
  - Acessibilidade (labels/roles/teclado) onde ainda há avisos do linter
  - Placeholder/ajuda contextual nos campos

---

## 7) Backlog priorizado (versão inicial)

1. Perfis e navegação por papel (UI):
   - Páginas de perfil para jovem/líder/admin com cards e atalhos
2. Gestão de papéis e escopos (UI):
   - CRUD `user_roles` com filtros por escopo e validações
3. Relatórios focados por papel:
   - Visão nacional/estadual/bloco/região/igreja com KPIs e exportação
4. Auditoria e sessões:
   - Telas para `logs_auditoria`, `logs_historico` e `sessoes_usuario`
5. Notificações e preferências:
   - Configurações por usuário e melhoria de UX de leitura
6. Avaliações aprimoradas:
   - Timeline por jovem e resumos (média/últimas avaliações)
7. Polimento geral de responsividade/A11y/performance

Cada item deve referenciar as colunas/tabelas/funcs em `ESTRUTURA_TABELAS_BANCO.md` e `DOCUMENTACAO_FUNCOES_BANCO.md`, além de respeitar as RLS em `POLITICAS_RLS_COMPLETAS.md`.

---

## 8) Diretrizes de desenvolvimento

- Sempre revisar os três documentos de base antes de implementar:
  - `POLITICAS_RLS_COMPLETAS.md`
  - `DOCUMENTACAO_FUNCOES_BANCO.md`
  - `ESTRUTURA_TABELAS_BANCO.md`
- RLS primeiro: novas telas/consultas devem começar pela verificação de acesso (role/escopo).
- Functions/Triggers: avaliar reutilização das existentes; documentar qualquer nova no arquivo de functions.
- Migrations: manter scripts versionados (quando necessário) e sincronizar a documentação.
- UI/UX: mobile-first, acessibilidade, feedbacks claros, componentes reutilizáveis.

---

## 9) Fluxos principais (alto nível)

- Cadastro de Jovem:
  1. Usuário autenticado (jovem ou líder/admin) acessa o formulário
  2. Preenche etapas com validações e máscaras
  3. Foto enviada para Storage + URL salva em `jovens.foto`
  4. Insert em `jovens` (limpeza de payload, cálculo idade)
  5. Triggers notificam líderes conforme escopo

- Avaliação de Jovem:
  1. Líder/colaborador acessa perfil do jovem
  2. Abre modal de avaliação, preenche campos e nota
  3. Insert em `avaliacoes`
  4. Trigger notifica líderes e timeline é atualizada

- Notificações:
  1. Geração automática por triggers ou manual (futuro)
  2. Usuário visualiza dropdown/lista e marca como lida

---

## 10) Relatórios e filtros (alinhado ao rascunho)

- Filtros: edição, sexo, condição, aprovação, idade, estado, bloco, região, igreja
- Avaliações: espírito, caráter, disposição, texto livre e nota 1..10
- Ações rápidas: Aprovar/Pré-aprovar (governado por RLS e funções)

---

## 11) Publicação e QA

- Checklist antes do deploy:
  - RLS revisada para novas consultas
  - Novas funções documentadas
  - Campos/colunas sincronizados com `ESTRUTURA_TABELAS_BANCO.md`
  - Teste manual: cadastro, upload, avaliações, filtros, notificações
  - Responsividade e A11y sem regressões

- Deploy: Vercel + variáveis de ambiente (ver `CONFIGURACAO_SUPABASE.md`/`env.example`).

---

## 12) Próximos passos

- Revisar este roteiro e priorizar o backlog (seção 7)
- Abrir issues/tarefas por item com referência direta às tabelas/funcs/RLS afetadas
- Iniciar pelas telas de perfil por papel e gestão de papéis/escopos

---

# 13) Backlog rastreável (por tela/endpoint/tabela/função)

Abaixo, tarefas com indicação de:
- Arquivos front (Svelte) afetados
- Stores/endpoints (
  `src/lib/stores/*.js` ou RPCs SQL)
- Tabelas/FKs/Functions/Policies envolvidas (ver 3 docs de referência)

### 13.1 Perfis por papel (UI)
- Criar páginas de perfil:
  - jovem: `src/routes/profile/+page.svelte` (ou ajustar `usuarios/`)
  - líder/admin: `src/routes/seguranca/+page.svelte` ou novas rotas por papel
- Mostrar cards com KPIs e atalhos filtrados por escopo
- Stores: reaproveitar `jovens.js`, `avaliacoes.js`, `notificacoes.js`
- Tabelas: `jovens`, `avaliacoes`, `notificacoes`
- Policies/Functions: `has_role`, `can_access_jovem`, políticas `jovens_*`

### 13.2 Gestão de user_roles (CRUD) e troca de liderança
- Nova tela: `src/routes/seguranca/auditoria/+page.svelte` (ou `usuarios/roles/+page.svelte`)
- Listar, criar, editar, remover `user_roles` com escopos (estado/bloco/região/igreja)
- Ação “Transferir liderança” (mover escopo entre usuários, gerar `logs_historico`)
- Stores: criar `src/lib/stores/roles.js` ou ampliar `usuarios.js`
- Tabelas: `user_roles`, `usuarios`, `roles`
- Functions: `has_role`, `is_admin_user`, `criar_log_auditoria`
- Policies: `user_roles_*`, `usuarios_*`

### 13.3 Avaliações: timeline e KPIs
- Jovem: componente `src/lib/components/jovens/JovemProfile.svelte` mostrar timeline
- KPIs no card: média/última nota/contagem por avaliador
- Tabelas: `avaliacoes`, `jovens`
- SQL/RPC: agregações por jovem (médias e últimas datas)
- Policies: `avaliacoes_allow_select`, `jovens_*`

### 13.4 Auditoria e sessões
- Auditoria:
  - Tela `src/routes/seguranca/auditoria/+page.svelte` (listagem `logs_auditoria`, filtros por usuário/ação/intervalo)
- Histórico:
  - Reaproveitar página de auditoria ou `src/routes/seguranca/+page.svelte` para `logs_historico`
- Sessões:
  - Página `src/routes/seguranca/sessoes/+page.svelte` (listar `sessoes_usuario`, revogar)
- Tabelas: `logs_auditoria`, `logs_historico`, `sessoes_usuario`
- Functions: `limpar_logs_antigos`, `obter_estatisticas_sistema`

### 13.5 Preferências de notificações
- Página `src/routes/notificacoes/configuracoes/+page.svelte` já existe; ampliar para categorias e opt-in/out
- Tabela: `configuracoes_sistema`
- Functions: (opcional) adicionar getters/setters RPC específicos (documentar se criar)

### 13.6 Relatórios por papel com export
- Rotas em `src/routes/relatorios/**` já existem; alinhar por papel (nacional/estadual/bloco/região/igreja)
- Exportação: gerar CSV/Excel a partir de consultas com os mesmos filtros (client ou server)
- Tabelas: `jovens`, `avaliacoes`, `notificacoes`
- Policies/Functions: `can_access_jovem`, agregações específicas

### 13.7 Polimento A11y e UX
- Passar linter A11y nas páginas de forms/modais onde ainda há avisos (ver `read_lints` locais)
- Garantir `role/aria/label/keyboard` em elementos clicáveis

---

## 14) Referências diretas para cada tarefa
- RLS/Policies: `POLITICAS_RLS_COMPLETAS.md`
- Functions/Triggers: `DOCUMENTACAO_FUNCOES_BANCO.md`
- Tabelas/FKs/Tipos: `ESTRUTURA_TABELAS_BANCO.md`

Cada PR deve citar explicitamente quais itens do backlog acima atende e quais seções/linhas desses 3 documentos foram consideradas/alteradas.

---

# 15) Issues/tarefas numeradas com checklist e estimativas

Formato de estimativa: P (Pequena ~2-4h), M (Média ~1-2 dias), G (Grande ~3-5 dias).

## I-01 Perfis por papel (UI) [M]
Checklist:
- [ ] Criar rota `profile` para jovem com visão do próprio cadastro e status
- [ ] Criar rota(s) de perfil para líderes/admin com KPIs e atalhos por escopo
- [ ] Reutilizar stores (`jovens`, `avaliacoes`, `notificacoes`) e aplicar filtros por escopo
- [ ] Validar acesso via RLS (`can_access_jovem`, policies)
Referências: seções 2, 3, 5, 13.1; 3 docs base.

## I-02 CRUD de user_roles e troca de liderança [G]
Checklist:
- [ ] Tela de listagem/edição de `user_roles` (criar/editar/remover)
- [ ] Seleção de escopos (estado/bloco/região/igreja) com dependências
- [ ] Ação “Transferir liderança” (mover escopo, registrar `logs_historico`)
- [ ] RLS e validações de integridade
Referências: seções 2, 3, 13.2; 3 docs base.

## I-03 Avaliações: timeline e KPIs por jovem [M]
Checklist:
- [ ] Timeline no `JovemProfile.svelte` com avaliações e datas
- [ ] Cálculo de média, última avaliação e contagem por avaliador
- [ ] Seletores/filtros por período
- [ ] Garantir policies de leitura
Referências: seções 5, 6, 13.3; 3 docs base.

## I-04 UI de Auditoria e Sessões [M]
Checklist:
- [ ] Listagem `logs_auditoria` com filtros (usuário, ação, intervalo)
- [ ] Listagem `logs_historico` (eventos de negócio)
- [ ] Sessões ativas (`sessoes_usuario`) com revogação manual
- [ ] Botões utilitários (limpar logs antigos via RPC)
Referências: seções 3, 6, 13.4; 3 docs base.

## I-05 Preferências de Notificações [P]
Checklist:
- [ ] UI para categorias/opt-in no `notificacoes/configuracoes`
- [ ] Persistência em `configuracoes_sistema`
- [ ] Ajustes de leitura em lote
Referências: seções 5, 6, 13.5; 3 docs base.

## I-06 Relatórios por papel com export [M]
Checklist:
- [ ] KPIs por papel (nacional/estadual/bloco/região/igreja)
- [ ] Exports CSV/Excel com filtros atuais
- [ ] Garantir RLS e consistência com listagens
Referências: seções 6, 10, 13.6; 3 docs base.

## I-07 A11y e polimento [P]
Checklist:
- [ ] Corrigir avisos do linter A11y mais comuns (labels/roles)
- [ ] Padronizar placeholders/helps e estados vazios
- [ ] Revisar responsividade em páginas críticas
Referências: seções 5, 6, 13.7; 3 docs base.
