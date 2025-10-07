-- Criar tabela de associações muitos-para-muitos entre jovens e usuarios (acompanhantes)
create table if not exists public.jovens_usuarios_associacoes (
  id uuid primary key default gen_random_uuid(),
  jovem_id uuid not null references public.jovens(id) on delete cascade,
  usuario_id uuid not null references public.usuarios(id) on delete cascade,
  created_at timestamptz not null default now(),
  created_by uuid null references public.usuarios(id) on delete set null,
  unique (jovem_id, usuario_id)
);

-- Habilitar RLS
alter table public.jovens_usuarios_associacoes enable row level security;

-- Policies: recriar idempotente
drop policy if exists associacoes_select on public.jovens_usuarios_associacoes;
drop policy if exists associacoes_insert on public.jovens_usuarios_associacoes;
drop policy if exists associacoes_delete on public.jovens_usuarios_associacoes;

-- SELECT: pode ver quando é o associado OU possui nível de gestão
create policy associacoes_select on public.jovens_usuarios_associacoes
  for select
  using (
    exists (
      select 1 from public.usuarios u
      where u.id_auth = auth.uid()
      and (u.id = usuario_id or u.nivel in (
        'administrador',
        'lider_nacional_iurd', 'lider_nacional_fju',
        'lider_estadual_iurd', 'lider_estadual_fju',
        'lider_bloco_iurd', 'lider_bloco_fju',
        'lider_regional_iurd', 'lider_igreja_iurd',
        'colaborador'
      ))
    )
  );

-- INSERT: permitir a perfis de gestão
create policy associacoes_insert on public.jovens_usuarios_associacoes
  for insert
  with check (
    exists (
      select 1 from public.usuarios u
      where u.id_auth = auth.uid()
      and u.nivel in (
        'administrador',
        'lider_nacional_iurd', 'lider_nacional_fju',
        'lider_estadual_iurd', 'lider_estadual_fju',
        'lider_bloco_iurd', 'lider_bloco_fju',
        'lider_regional_iurd', 'lider_igreja_iurd',
        'colaborador'
      )
    )
  );

-- DELETE: próprio associado ou perfis de gestão
create policy associacoes_delete on public.jovens_usuarios_associacoes
  for delete
  using (
    exists (
      select 1 from public.usuarios u
      where u.id_auth = auth.uid()
      and (u.id = usuario_id or u.nivel in (
        'administrador',
        'lider_nacional_iurd', 'lider_nacional_fju',
        'lider_estadual_iurd', 'lider_estadual_fju',
        'lider_bloco_iurd', 'lider_bloco_fju',
        'lider_regional_iurd', 'lider_igreja_iurd'
      ))
    )
  );

-- Índices para performance
create index if not exists idx_jua_jovem_id on public.jovens_usuarios_associacoes (jovem_id);
create index if not exists idx_jua_usuario_id on public.jovens_usuarios_associacoes (usuario_id);

-- Backfill inicial: copiar valores existentes de jovens.usuario_id para novas associações
insert into public.jovens_usuarios_associacoes (jovem_id, usuario_id, created_by)
select j.id, j.usuario_id, null
from public.jovens j
where j.usuario_id is not null
on conflict (jovem_id, usuario_id) do nothing;

-- Ajuste opcional nas policies de jovens: garantir visibilidade quando associado
-- Para cada policy de SELECT em public.jovens, deve existir OR EXISTS (
--   select 1 from public.usuarios u
--   join public.jovens_usuarios_associacoes a on a.usuario_id = u.id and a.jovem_id = jovens.id
--   where u.id_auth = auth.uid()
-- )
-- Como as policies são diversas e já estão versionadas em arquivos separados neste repositório,
-- aplique o padrão acima em todas as policies de SELECT em jovens.


