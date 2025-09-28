-- RESTAURAR SISTEMA ORIGINAL
-- Reverter todas as mudanças e restaurar o sistema que estava funcionando

-- 1. Restaurar função can_access_jovem original
CREATE OR REPLACE FUNCTION public.can_access_jovem(
  jovem_estado_id uuid,
  jovem_bloco_id uuid,
  jovem_regiao_id uuid,
  jovem_igreja_id uuid
)
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
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

  -- 7: colaborador → acesso baseado no nível da tabela usuarios
  IF user_roles_info.nivel_hierarquico = 7 THEN
    -- Verificar se o usuário tem nível colaborador na tabela usuarios
    RETURN EXISTS (
      SELECT 1 FROM public.usuarios u
      WHERE u.id = current_user_id
        AND u.nivel = 'colaborador'
    );
  END IF;

  -- 8: jovem → acesso controlado por outras policies
  IF user_roles_info.nivel_hierarquico = 8 THEN
    RETURN false;
  END IF;

  RETURN false;
END;
$$;

-- 2. Restaurar função can_access_viagem_by_level original
CREATE OR REPLACE FUNCTION public.can_access_viagem_by_level(
  jovem_estado_id uuid,
  jovem_bloco_id uuid,
  jovem_regiao_id uuid,
  jovem_igreja_id uuid
)
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  current_user_id uuid;
  user_roles_info record;
BEGIN
  -- Obter o ID do usuário atual
  current_user_id := (SELECT id FROM public.usuarios WHERE id_auth = auth.uid());
  IF current_user_id IS NULL THEN RETURN false; END IF;
  
  -- Buscar o papel com menor nível hierárquico (maior privilégio) do usuário
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
  
  -- Se não tem papel, não tem acesso
  IF user_roles_info IS NULL THEN RETURN false; END IF;
  
  -- 1. ADMINISTRADOR (nível 1) - Acesso total
  IF user_roles_info.nivel_hierarquico = 1 THEN RETURN true; END IF;
  
  -- 2. LÍDERES NACIONAIS (nível 2) - Acesso total (como administrador)
  IF user_roles_info.nivel_hierarquico = 2 THEN RETURN true; END IF;
  
  -- 3. LÍDERES ESTADUAIS (nível 3) - Visão estadual
  IF user_roles_info.nivel_hierarquico = 3 THEN
    RETURN user_roles_info.estado_id = jovem_estado_id;
  END IF;
  
  -- 4. LÍDERES DE BLOCO (nível 4) - Visão de bloco
  IF user_roles_info.nivel_hierarquico = 4 THEN
    RETURN user_roles_info.bloco_id = jovem_bloco_id;
  END IF;
  
  -- 5. LÍDER REGIONAL (nível 5) - Visão regional
  IF user_roles_info.nivel_hierarquico = 5 THEN
    RETURN user_roles_info.regiao_id = jovem_regiao_id;
  END IF;
  
  -- 6. LÍDER DE IGREJA (nível 6) - Visão de igreja
  IF user_roles_info.nivel_hierarquico = 6 THEN
    RETURN user_roles_info.igreja_id = jovem_igreja_id;
  END IF;
  
  -- 7. COLABORADOR (nível 7) - Acesso baseado no nível da tabela usuarios
  IF user_roles_info.nivel_hierarquico = 7 THEN
    -- Verificar se o usuário tem nível colaborador na tabela usuarios
    RETURN EXISTS (
      SELECT 1 FROM public.usuarios u
      WHERE u.id = current_user_id
        AND u.nivel = 'colaborador'
    );
  END IF;
  
  -- 8. JOVEM (nível 8) - Vê apenas seus próprios dados
  IF user_roles_info.nivel_hierarquico = 8 THEN
    RETURN EXISTS (
      SELECT 1 FROM public.jovens j
      WHERE j.estado_id = jovem_estado_id
        AND j.bloco_id = jovem_bloco_id
        AND j.regiao_id = jovem_regiao_id
        AND j.igreja_id = jovem_igreja_id
        AND j.usuario_id = current_user_id
    );
  END IF;
  
  RETURN false;
END;
$$;
