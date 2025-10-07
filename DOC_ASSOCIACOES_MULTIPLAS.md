# Associações múltiplas de jovens a usuários

Este documento resume a mudança de arquitetura para permitir associar um jovem a múltiplos usuários (acompanhantes/avaliadores), além do vínculo de "dono" via `id_usuario_jovem`.

## Visão geral

- `jovens.id_usuario_jovem` (sem mudanças): relacionamento do jovem com o "dono" (perfil editável pelo próprio). Fluxo permanece no formulário de edição do jovem.
- `public.jovens_usuarios_associacoes` (novo): mapeia associações N:N entre jovem e usuários que o acompanham/avaliam.
- `jovens.usuario_id` (legado): mantido para “quem cadastrou” e para compatibilidade. Não é mais sobrescrito pelo fluxo de associação.

## Banco de Dados

- Tabela: `public.jovens_usuarios_associacoes(jovem_id uuid, usuario_id uuid, created_at timestamptz, created_by uuid)`
- RLS:
  - SELECT: visível para o usuário associado e perfis de gestão (admin, líderes, etc.).
  - INSERT/DELETE: permitido para perfis de gestão; delete também pelo próprio associado.
- Backfill: valores antigos de `jovens.usuario_id` foram copiados para a nova tabela.

Arquivo SQL: `CRIAR_TABELA_ASSOCIACOES_JOVENS.sql`.

## Frontend – onde mudou

- Modal de associação `src/lib/components/modals/AssociarUsuarioModal.svelte`
  - Agora faz `upsert` em `jovens_usuarios_associacoes`.
  - Dispara `rpc('notificar_evento_jovem', ...)` após associar.

- Desassociar: `src/lib/stores/estatisticas.js`
  - `desassociarJovemUsuario(jovemId, usuarioId)`: agora faz `delete` na tabela associativa.
  - `loadUsuariosAssociadosJovem(...)`: corrige embed usando a FK `usuarios!jovens_usuarios_associacoes_usuario_id_fkey`.

- Listagens/consultas (incluem associados via `OR id.in.(...)`)
  - Stores:
    - `src/lib/stores/jovens.js`
    - `src/lib/stores/jovens-simple.js`
    - `src/lib/stores/estatisticas.js` (estatísticas e filtros por nível)
  - Rotas de listagem:
    - `src/routes/jovens/todos/+page.svelte`
    - `src/routes/jovens/pendentes/+page.svelte`
    - `src/routes/jovens/avaliados/+page.svelte`
    - `src/routes/jovens/aprovados/+page.svelte`
    - `src/routes/jovens/cards/+page.svelte`

Padrão aplicado para líderes (estadual, bloco, regional, igreja):
1. Buscar `jovensIds` associados ao usuário em `jovens_usuarios_associacoes`.
2. Combinar com escopo geográfico via `query.or('escopo_geografico, id.in.(...)')`.

## O que permanece igual

- Formulário em `jovens/[id]/editar`: mantém fluxo de atualizar `id_usuario_jovem`.
- Acesso do próprio jovem: checagens continuam aceitando `usuario_id` OU `id_usuario_jovem` quando aplicável.

## Considerações de Segurança (RLS)

- Garanta que policies de SELECT em `public.jovens` considerem associação por meio de:
  ```sql
  OR EXISTS (
    SELECT 1
    FROM public.usuarios u
    JOIN public.jovens_usuarios_associacoes a
      ON a.usuario_id = u.id AND a.jovem_id = jovens.id
    WHERE u.id_auth = auth.uid()
  )
  ```

## Próximos passos sugeridos

- Revisar outras páginas de listagens se surgirem novas (manter padrão acima).
- Se necessário, adicionar metadados à associação (papel no acompanhamento, observações, etc.).


