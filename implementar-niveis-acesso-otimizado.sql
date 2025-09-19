-- =====================================================
-- IMPLEMENTAÇÃO OTIMIZADA DOS NÍVEIS DE ACESSO
-- =====================================================
-- Este script implementa exatamente a hierarquia de níveis descrita
-- usando a lógica do código existente de forma otimizada

-- 1. ATUALIZAR NÍVEIS HIERÁRQUICOS NA TABELA ROLES
-- Garantir que os níveis hierárquicos estejam corretos
UPDATE public.roles SET nivel_hierarquico = 1 WHERE slug = 'administrador';
UPDATE public.roles SET nivel_hierarquico = 2 WHERE slug IN ('lider_nacional_iurd', 'lider_nacional_fju');
UPDATE public.roles SET nivel_hierarquico = 3 WHERE slug IN ('lider_estadual_iurd', 'lider_estadual_fju');
UPDATE public.roles SET nivel_hierarquico = 4 WHERE slug IN ('lider_bloco_iurd', 'lider_bloco_fju');
UPDATE public.roles SET nivel_hierarquico = 5 WHERE slug = 'lider_regional_iurd';
UPDATE public.roles SET nivel_hierarquico = 6 WHERE slug = 'lider_igreja_iurd';
UPDATE public.roles SET nivel_hierarquico = 7 WHERE slug = 'colaborador';
UPDATE public.roles SET nivel_hierarquico = 8 WHERE slug = 'jovem';

-- 2. FUNCTION OTIMIZADA PARA ACESSO A JOVENS
-- Implementa exatamente a hierarquia descrita
CREATE OR REPLACE FUNCTION public.can_access_jovem(
  jovem_estado_id uuid, 
  jovem_bloco_id uuid, 
  jovem_regiao_id uuid, 
  jovem_igreja_id uuid
)
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
AS $function$
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
  
  -- 7. COLABORADOR (nível 7) - Vê o que criou
  IF user_roles_info.nivel_hierarquico = 7 THEN
    -- Verificar se o jovem foi cadastrado por este colaborador
    RETURN EXISTS (
      SELECT 1 FROM public.jovens j
      WHERE j.estado_id = jovem_estado_id
        AND j.bloco_id = jovem_bloco_id
        AND j.regiao_id = jovem_regiao_id
        AND j.igreja_id = jovem_igreja_id
        AND j.usuario_id = current_user_id
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
$function$;

-- 3. FUNCTION OTIMIZADA PARA ACESSO A DADOS DE VIAGEM
-- Implementa a mesma lógica para dados de viagem
CREATE OR REPLACE FUNCTION public.can_access_viagem_by_level(
  jovem_estado_id uuid, 
  jovem_bloco_id uuid, 
  jovem_regiao_id uuid, 
  jovem_igreja_id uuid
)
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
AS $function$
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
  
  -- 7. COLABORADOR (nível 7) - Vê o que criou
  IF user_roles_info.nivel_hierarquico = 7 THEN
    -- Verificar se o colaborador criou dados de viagem para este jovem
    RETURN EXISTS (
      SELECT 1 FROM public.dados_viagem dv
      JOIN public.jovens j ON j.id = dv.jovem_id
      WHERE j.estado_id = jovem_estado_id
        AND j.bloco_id = jovem_bloco_id
        AND j.regiao_id = jovem_regiao_id
        AND j.igreja_id = jovem_igreja_id
        AND dv.usuario_id = current_user_id
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
$function$;

-- 4. FUNCTION PARA OBTER NÍVEL HIERÁRQUICO DO USUÁRIO
-- Útil para o frontend saber o nível de acesso
CREATE OR REPLACE FUNCTION public.get_user_hierarchy_level()
RETURNS integer
LANGUAGE plpgsql
SECURITY DEFINER
AS $function$
DECLARE
  current_user_id uuid;
  min_level integer;
BEGIN
  current_user_id := (SELECT id FROM public.usuarios WHERE id_auth = auth.uid());
  IF current_user_id IS NULL THEN RETURN 999; END IF;
  
  SELECT MIN(r.nivel_hierarquico) INTO min_level
  FROM public.user_roles ur
  JOIN public.roles r ON r.id = ur.role_id
  WHERE ur.user_id = current_user_id 
    AND ur.ativo = true;
  
  RETURN COALESCE(min_level, 999);
END;
$function$;

-- 5. FUNCTION PARA OBTER PAPÉIS DO USUÁRIO
-- Útil para o frontend saber quais papéis o usuário tem
CREATE OR REPLACE FUNCTION public.get_user_roles()
RETURNS TABLE(role_slug text, nivel_hierarquico integer, estado_id uuid, bloco_id uuid, regiao_id uuid, igreja_id uuid)
LANGUAGE plpgsql
SECURITY DEFINER
AS $function$
DECLARE
  current_user_id uuid;
BEGIN
  current_user_id := (SELECT id FROM public.usuarios WHERE id_auth = auth.uid());
  IF current_user_id IS NULL THEN RETURN; END IF;
  
  RETURN QUERY
  SELECT 
    r.slug,
    r.nivel_hierarquico,
    ur.estado_id,
    ur.bloco_id,
    ur.regiao_id,
    ur.igreja_id
  FROM public.user_roles ur
  JOIN public.roles r ON r.id = ur.role_id
  WHERE ur.user_id = current_user_id 
    AND ur.ativo = true
  ORDER BY r.nivel_hierarquico ASC;
END;
$function$;

-- 6. CRIAR ÍNDICES PARA OTIMIZAR PERFORMANCE
-- Índices para user_roles
CREATE INDEX IF NOT EXISTS idx_user_roles_user_id_ativo_nivel ON public.user_roles(user_id, ativo);
CREATE INDEX IF NOT EXISTS idx_user_roles_estado_id ON public.user_roles(estado_id) WHERE estado_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_user_roles_bloco_id ON public.user_roles(bloco_id) WHERE bloco_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_user_roles_regiao_id ON public.user_roles(regiao_id) WHERE regiao_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_user_roles_igreja_id ON public.user_roles(igreja_id) WHERE igreja_id IS NOT NULL;

-- Índices para roles
CREATE INDEX IF NOT EXISTS idx_roles_nivel_hierarquico ON public.roles(nivel_hierarquico);

-- Índices para usuarios
CREATE INDEX IF NOT EXISTS idx_usuarios_id_auth ON public.usuarios(id_auth);

-- Índices para jovens
CREATE INDEX IF NOT EXISTS idx_jovens_usuario_id ON public.jovens(usuario_id);
CREATE INDEX IF NOT EXISTS idx_jovens_estado_bloco_regiao_igreja ON public.jovens(estado_id, bloco_id, regiao_id, igreja_id);

-- Índices para dados_viagem
CREATE INDEX IF NOT EXISTS idx_dados_viagem_usuario_id ON public.dados_viagem(usuario_id);
CREATE INDEX IF NOT EXISTS idx_dados_viagem_jovem_id ON public.dados_viagem(jovem_id);

-- 7. VERIFICAR IMPLEMENTAÇÃO
-- Execute estas consultas para testar:
-- SELECT get_user_hierarchy_level();
-- SELECT * FROM get_user_roles();
-- SELECT can_access_jovem('uuid-do-estado', 'uuid-do-bloco', 'uuid-da-regiao', 'uuid-da-igreja');

-- =====================================================
-- FIM DO SCRIPT
-- =====================================================
