-- Policies mínimas para notificacoes (SELECT/UPDATE próprias)
-- Postgres não suporta CREATE POLICY IF NOT EXISTS. Use DROP ... IF EXISTS + CREATE.
alter table public.notificacoes enable row level security;

drop policy if exists notificacoes_select_own on public.notificacoes;
create policy notificacoes_select_own
on public.notificacoes
for select
to authenticated
using (
  destinatario_id = (select u.id from public.usuarios u where u.id_auth = auth.uid())
);

drop policy if exists notificacoes_update_own on public.notificacoes;
create policy notificacoes_update_own
on public.notificacoes
for update
to authenticated
using (
  destinatario_id = (select u.id from public.usuarios u where u.id_auth = auth.uid())
)
with check (
  destinatario_id = (select u.id from public.usuarios u where u.id_auth = auth.uid())
);

-- RPC genérica para eventos (resolve hierarquia e insere)
create or replace function public.notificar_evento_jovem(
  p_jovem_id uuid,
  p_tipo text,
  p_titulo text,
  p_mensagem text,
  p_remetente_id uuid default null,
  p_acao_url text default null
) returns integer
language plpgsql
security definer
set search_path = public
as $$
declare
  v_count integer := 0;
  v_estado uuid;
  v_bloco uuid;
  v_regiao uuid;
  v_igreja uuid;
begin
  select estado_id, bloco_id, regiao_id, igreja_id
  into v_estado, v_bloco, v_regiao, v_igreja
  from jovens
  where id = p_jovem_id;

  insert into notificacoes (destinatario_id, tipo, titulo, mensagem, jovem_id, acao_url, remetente_id, lida, criado_em)
  select user_id, p_tipo, p_titulo, p_mensagem, p_jovem_id,
         coalesce(p_acao_url, '/jovens/' || p_jovem_id::text), p_remetente_id,
         false, now()
  from obter_lideres_para_notificacao(v_estado, v_bloco, v_regiao, v_igreja);

  get diagnostics v_count = row_count;
  return v_count;
end;
$$;

grant execute on function public.notificar_evento_jovem(uuid, text, text, text, uuid, text) to authenticated;

-- RPC específica para associação (hierarquia + usuário associado)
create or replace function public.notificar_associacao_jovem(
  p_jovem_id uuid,
  p_usuario_associado_id uuid,
  p_titulo text,
  p_mensagem text,
  p_acao_url text default null
) returns integer
language plpgsql
security definer
set search_path = public
as $$
declare
  v_count integer := 0;
  v_estado uuid;
  v_bloco uuid;
  v_regiao uuid;
  v_igreja uuid;
begin
  select estado_id, bloco_id, regiao_id, igreja_id
  into v_estado, v_bloco, v_regiao, v_igreja
  from jovens
  where id = p_jovem_id;

  insert into notificacoes (destinatario_id, tipo, titulo, mensagem, jovem_id, acao_url, lida, criado_em)
  select user_id, 'sistema', p_titulo, p_mensagem, p_jovem_id,
         coalesce(p_acao_url, '/jovens/' || p_jovem_id::text), false, now()
  from obter_lideres_para_notificacao(v_estado, v_bloco, v_regiao, v_igreja);

  get diagnostics v_count = row_count;

  if p_usuario_associado_id is not null then
    insert into notificacoes (destinatario_id, tipo, titulo, mensagem, jovem_id, acao_url, lida, criado_em)
    values (p_usuario_associado_id, 'sistema', p_titulo, p_mensagem, p_jovem_id,
            coalesce(p_acao_url, '/jovens/' || p_jovem_id::text), false, now());
    v_count := v_count + 1;
  end if;

  return v_count;
end;
$$;

grant execute on function public.notificar_associacao_jovem(uuid, uuid, text, text, text) to authenticated;

-- Job de limpeza (pg_cron) - executa diariamente às 03:00 removendo notificações com mais de 30 dias
-- Necessita extensão pg_cron instalada e permissões adequadas.
-- Para instalar: create extension if not exists pg_cron;
-- Agendar:
-- select cron.schedule('limpar_notificacoes_diariamente', '0 3 * * *', $$
--   delete from public.notificacoes where criado_em < now() - interval '30 days';
-- $$);
