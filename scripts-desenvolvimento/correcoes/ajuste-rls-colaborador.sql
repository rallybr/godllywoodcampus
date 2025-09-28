-- Ajuste de RLS para colaborador ver apenas o que criou
-- 1) Corrige função can_access_jovem para não liberar visão por localização para nível 7
create or replace function public.can_access_jovem(
  jovem_estado_id uuid,
  jovem_bloco_id uuid,
  jovem_regiao_id uuid,
  jovem_igreja_id uuid
) returns boolean
language plpgsql
security definer
as $function$
DECLARE
  current_user_id uuid;
  user_roles_info record;
BEGIN
  current_user_id := (SELECT id FROM public.usuarios WHERE id_auth = auth.uid());
  IF current_user_id IS NULL THEN RETURN false; END IF;

  SELECT 
    r.slug,
    r.nivel_hierarquico,
    ur.estado_id,
    ur.bloco_id,
    ur.regiao_id,
    ur.igreja_id
  INTO user_roles_info
  FROM public.user_roles ur
  JOIN public.roles r ON r.id = ur.role_id
  WHERE ur.user_id = current_user_id 
    AND ur.ativo = true
  ORDER BY r.nivel_hierarquico ASC
  LIMIT 1;

  IF user_roles_info IS NULL THEN RETURN false; END IF;

  -- 1 e 2: admin e líderes nacionais → acesso total
  IF user_roles_info.nivel_hierarquico IN (1, 2) THEN RETURN true; END IF;

  -- 3: estadual
  IF user_roles_info.nivel_hierarquico = 3 THEN
    RETURN user_roles_info.estado_id = jovem_estado_id;
  END IF;

  -- 4: bloco
  IF user_roles_info.nivel_hierarquico = 4 THEN
    RETURN user_roles_info.bloco_id = jovem_bloco_id;
  END IF;

  -- 5: regional
  IF user_roles_info.nivel_hierarquico = 5 THEN
    RETURN user_roles_info.regiao_id = jovem_regiao_id;
  END IF;

  -- 6: igreja
  IF user_roles_info.nivel_hierarquico = 6 THEN
    RETURN user_roles_info.igreja_id = jovem_igreja_id;
  END IF;

  -- 7: colaborador → não libera visão por localização; acesso só via policy do criador
  IF user_roles_info.nivel_hierarquico = 7 THEN
    RETURN false;
  END IF;

  -- 8: jovem → acesso controlado por outras policies
  IF user_roles_info.nivel_hierarquico = 8 THEN
    RETURN false;
  END IF;

  RETURN false;
END;
$function$;

-- 2) Policy explícita para SELECT do criador (cobre colaborador)
alter table public.jovens enable row level security;

drop policy if exists jovens_select_own_creator on public.jovens;
create policy jovens_select_own_creator
on public.jovens
for select
to authenticated
using (
  usuario_id = (select u.id from public.usuarios u where u.id_auth = auth.uid())
);

-- Opcional: reforçar a policy escopada por hierarquia para líderes/admin mantendo criador
-- drop policy if exists jovens_select_scoped on public.jovens;
-- create policy jovens_select_scoped
-- on public.jovens
-- for select
-- to authenticated
-- using (
--   can_access_jovem(estado_id, bloco_id, regiao_id, igreja_id) OR
--   usuario_id = (select u.id from public.usuarios u where u.id_auth = auth.uid())
-- );
