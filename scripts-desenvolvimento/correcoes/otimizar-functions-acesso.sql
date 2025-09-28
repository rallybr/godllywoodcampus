-- =====================================================
-- SCRIPT PARA OTIMIZAR FUNCTIONS DE ACESSO
-- =====================================================
-- Este script otimiza as functions can_access_jovem e can_access_viagem_by_level
-- para melhor performance e menor complexidade

-- 1. BACKUP DAS FUNCTIONS ATUAIS
-- Execute este comando para ver as functions atuais:
-- SELECT proname, prosrc FROM pg_proc WHERE proname IN ('can_access_jovem', 'can_access_viagem_by_level');

-- 2. OTIMIZAR FUNCTION can_access_jovem
-- Versão otimizada com menos subconsultas e melhor performance
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
  user_roles text[];
BEGIN
  -- Obter o ID do usuário atual
  current_user_id := (SELECT id FROM public.usuarios WHERE id_auth = auth.uid());
  IF current_user_id IS NULL THEN RETURN false; END IF;
  
  -- Obter todos os roles do usuário em uma única consulta
  SELECT array_agg(r.slug) INTO user_roles
  FROM public.user_roles ur 
  JOIN public.roles r ON r.id = ur.role_id 
  WHERE ur.user_id = current_user_id 
    AND ur.ativo = true;
  
  -- Se não tem roles, não tem acesso
  IF user_roles IS NULL OR array_length(user_roles, 1) IS NULL THEN RETURN false; END IF;
  
  -- 1. Administrador (acesso total)
  IF 'administrador' = ANY(user_roles) THEN RETURN true; END IF;
  
  -- 2. Líderes Nacionais (acesso total)
  IF ('lider_nacional_iurd' = ANY(user_roles) OR 'lider_nacional_fju' = ANY(user_roles)) THEN 
    RETURN true; 
  END IF;
  
  -- 3. Líderes Estaduais
  IF ('lider_estadual_iurd' = ANY(user_roles) OR 'lider_estadual_fju' = ANY(user_roles)) THEN
    RETURN EXISTS (
      SELECT 1 FROM public.user_roles ur 
      WHERE ur.user_id = current_user_id 
        AND ur.ativo = true
        AND ur.estado_id = jovem_estado_id
    );
  END IF;
  
  -- 4. Líderes de Bloco
  IF ('lider_bloco_iurd' = ANY(user_roles) OR 'lider_bloco_fju' = ANY(user_roles)) THEN
    RETURN EXISTS (
      SELECT 1 FROM public.user_roles ur 
      WHERE ur.user_id = current_user_id 
        AND ur.ativo = true
        AND ur.bloco_id = jovem_bloco_id
    );
  END IF;
  
  -- 5. Líder Regional
  IF 'lider_regional_iurd' = ANY(user_roles) THEN
    RETURN EXISTS (
      SELECT 1 FROM public.user_roles ur 
      WHERE ur.user_id = current_user_id 
        AND ur.ativo = true
        AND ur.regiao_id = jovem_regiao_id
    );
  END IF;
  
  -- 6. Líder de Igreja
  IF 'lider_igreja_iurd' = ANY(user_roles) THEN
    RETURN EXISTS (
      SELECT 1 FROM public.user_roles ur 
      WHERE ur.user_id = current_user_id 
        AND ur.ativo = true
        AND ur.igreja_id = jovem_igreja_id
    );
  END IF;
  
  -- 7. Colaborador (acesso a nível que ele mesmo criou)
  IF 'colaborador' = ANY(user_roles) THEN RETURN true; END IF;
  
  RETURN false;
END;
$function$;

-- 3. OTIMIZAR FUNCTION can_access_viagem_by_level
-- Versão otimizada com menos subconsultas
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
  user_roles text[];
BEGIN
  -- Obter usuário atual
  current_user_id := auth.uid();
  IF current_user_id IS NULL THEN RETURN false; END IF;

  -- Obter todos os roles do usuário em uma única consulta
  SELECT array_agg(r.slug) INTO user_roles
  FROM public.user_roles ur
  JOIN public.roles r ON r.id = ur.role_id
  JOIN public.usuarios u ON u.id = ur.user_id
  WHERE u.id_auth = current_user_id
    AND ur.ativo = true;

  -- Se não tem roles, não tem acesso
  IF user_roles IS NULL OR array_length(user_roles, 1) IS NULL THEN RETURN false; END IF;

  -- Administrador: acesso total
  IF 'administrador' = ANY(user_roles) THEN RETURN true; END IF;

  -- Líderes nacionais: acesso total
  IF ('lider_nacional_iurd' = ANY(user_roles) OR 'lider_nacional_fju' = ANY(user_roles)) THEN
    RETURN true;
  END IF;

  -- Líderes estaduais: acesso a tudo do estado
  IF ('lider_estadual_iurd' = ANY(user_roles) OR 'lider_estadual_fju' = ANY(user_roles)) THEN
    RETURN EXISTS (
      SELECT 1 FROM public.user_roles ur2
      JOIN public.usuarios u2 ON u2.id = ur2.user_id
      WHERE u2.id_auth = current_user_id
        AND ur2.ativo = true
        AND ur2.estado_id = jovem_estado_id
    );
  END IF;

  -- Líderes de bloco: acesso a tudo do bloco
  IF ('lider_bloco_iurd' = ANY(user_roles) OR 'lider_bloco_fju' = ANY(user_roles)) THEN
    RETURN EXISTS (
      SELECT 1 FROM public.user_roles ur2
      JOIN public.usuarios u2 ON u2.id = ur2.user_id
      WHERE u2.id_auth = current_user_id
        AND ur2.ativo = true
        AND ur2.bloco_id = jovem_bloco_id
    );
  END IF;

  -- Líder regional: acesso a tudo da região
  IF 'lider_regional_iurd' = ANY(user_roles) THEN
    RETURN EXISTS (
      SELECT 1 FROM public.user_roles ur2
      JOIN public.usuarios u2 ON u2.id = ur2.user_id
      WHERE u2.id_auth = current_user_id
        AND ur2.ativo = true
        AND ur2.regiao_id = jovem_regiao_id
    );
  END IF;

  -- Líder de igreja: acesso a tudo da igreja
  IF 'lider_igreja_iurd' = ANY(user_roles) THEN
    RETURN EXISTS (
      SELECT 1 FROM public.user_roles ur2
      JOIN public.usuarios u2 ON u2.id = ur2.user_id
      WHERE u2.id_auth = current_user_id
        AND ur2.ativo = true
        AND ur2.igreja_id = jovem_igreja_id
    );
  END IF;

  -- Colaborador: acesso a tudo que ele criou
  IF 'colaborador' = ANY(user_roles) THEN
    RETURN EXISTS (
      SELECT 1 FROM public.dados_viagem dv
      JOIN public.usuarios u ON u.id = dv.usuario_id
      WHERE u.id_auth = current_user_id
        AND dv.jovem_id IN (
          SELECT id FROM public.jovens 
          WHERE estado_id = jovem_estado_id 
            AND bloco_id = jovem_bloco_id 
            AND regiao_id = jovem_regiao_id 
            AND igreja_id = jovem_igreja_id
        )
    );
  END IF;

  RETURN false;
END;
$function$;

-- 4. CRIAR ÍNDICES PARA MELHORAR PERFORMANCE
-- Índices para user_roles
CREATE INDEX IF NOT EXISTS idx_user_roles_user_id_ativo ON public.user_roles(user_id, ativo);
CREATE INDEX IF NOT EXISTS idx_user_roles_estado_id ON public.user_roles(estado_id) WHERE estado_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_user_roles_bloco_id ON public.user_roles(bloco_id) WHERE bloco_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_user_roles_regiao_id ON public.user_roles(regiao_id) WHERE regiao_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_user_roles_igreja_id ON public.user_roles(igreja_id) WHERE igreja_id IS NOT NULL;

-- Índices para usuarios
CREATE INDEX IF NOT EXISTS idx_usuarios_id_auth ON public.usuarios(id_auth);

-- Índices para jovens
CREATE INDEX IF NOT EXISTS idx_jovens_estado_bloco_regiao_igreja ON public.jovens(estado_id, bloco_id, regiao_id, igreja_id);
CREATE INDEX IF NOT EXISTS idx_jovens_usuario_id ON public.jovens(usuario_id);

-- Índices para dados_viagem
CREATE INDEX IF NOT EXISTS idx_dados_viagem_jovem_id ON public.dados_viagem(jovem_id);
CREATE INDEX IF NOT EXISTS idx_dados_viagem_usuario_id ON public.dados_viagem(usuario_id);

-- 5. VERIFICAR PERFORMANCE
-- Execute estas consultas para verificar se as functions estão funcionando:
-- SELECT can_access_jovem('uuid-do-estado', 'uuid-do-bloco', 'uuid-da-regiao', 'uuid-da-igreja');
-- SELECT can_access_viagem_by_level('uuid-do-estado', 'uuid-do-bloco', 'uuid-da-regiao', 'uuid-da-igreja');

-- 6. ROLLBACK (se necessário)
-- Se algo der errado, você pode restaurar as functions originais:
-- (Execute apenas se necessário)

-- Restaurar can_access_jovem original
-- CREATE OR REPLACE FUNCTION public.can_access_jovem(jovem_estado_id uuid, jovem_bloco_id uuid, jovem_regiao_id uuid, jovem_igreja_id uuid)
-- RETURNS boolean
-- LANGUAGE plpgsql
-- SECURITY DEFINER
-- AS $function$
-- DECLARE
--   current_user_id uuid;
--   user_role_slug text;
--   user_estado_id uuid;
--   user_bloco_id uuid;
--   user_regiao_id uuid;
--   user_igreja_id uuid;
-- BEGIN
--   -- Obter o ID do usuário atual
--   current_user_id := (SELECT id FROM public.usuarios WHERE id_auth = auth.uid());
--   IF current_user_id IS NULL THEN RETURN false; END IF;
--   
--   -- Obter dados do usuário
--   SELECT u.estado_id, u.bloco_id, u.regiao_id, u.igreja_id
--   INTO user_estado_id, user_bloco_id, user_regiao_id, user_igreja_id
--   FROM public.usuarios u WHERE u.id = current_user_id;
--   
--   -- 1. Administrador (acesso total)
--   IF EXISTS (
--     SELECT 1 FROM public.user_roles ur 
--     JOIN public.roles r ON r.id = ur.role_id 
--     WHERE ur.user_id = current_user_id 
--     AND ur.ativo = true 
--     AND r.slug = 'administrador'
--   ) THEN RETURN true; END IF;
--   
--   -- 2. Líderes Nacionais (acesso total)
--   IF EXISTS (
--     SELECT 1 FROM public.user_roles ur 
--     JOIN public.roles r ON r.id = ur.role_id 
--     WHERE ur.user_id = current_user_id 
--     AND ur.ativo = true 
--     AND r.slug IN ('lider_nacional_iurd', 'lider_nacional_fju')
--   ) THEN RETURN true; END IF;
--   
--   -- 3. Líderes Estaduais
--   IF EXISTS (
--     SELECT 1 FROM public.user_roles ur 
--     JOIN public.roles r ON r.id = ur.role_id 
--     WHERE ur.user_id = current_user_id 
--     AND ur.ativo = true 
--     AND r.slug IN ('lider_estadual_iurd', 'lider_estadual_fju')
--     AND ur.estado_id = jovem_estado_id
--   ) THEN RETURN true; END IF;
--   
--   -- 4. Líderes de Bloco
--   IF EXISTS (
--     SELECT 1 FROM public.user_roles ur 
--     JOIN public.roles r ON r.id = ur.role_id 
--     WHERE ur.user_id = current_user_id 
--     AND ur.ativo = true 
--     AND r.slug IN ('lider_bloco_iurd', 'lider_bloco_fju')
--     AND ur.bloco_id = jovem_bloco_id
--   ) THEN RETURN true; END IF;
--   
--   -- 5. Líder Regional
--   IF EXISTS (
--     SELECT 1 FROM public.user_roles ur 
--     JOIN public.roles r ON r.id = ur.role_id 
--     WHERE ur.user_id = current_user_id 
--     AND ur.ativo = true 
--     AND r.slug = 'lider_regional_iurd'
--     AND ur.regiao_id = jovem_regiao_id
--   ) THEN RETURN true; END IF;
--   
--   -- 6. Líder de Igreja
--   IF EXISTS (
--     SELECT 1 FROM public.user_roles ur 
--     JOIN public.roles r ON r.id = ur.role_id 
--     WHERE ur.user_id = current_user_id 
--     AND ur.ativo = true 
--     AND r.slug = 'lider_igreja_iurd'
--     AND ur.igreja_id = jovem_igreja_id
--   ) THEN RETURN true; END IF;
--   
--   -- 7. Colaborador (acesso a nível que ele mesmo criou)
--   IF EXISTS (
--     SELECT 1 FROM public.user_roles ur 
--     JOIN public.roles r ON r.id = ur.role_id 
--     WHERE ur.user_id = current_user_id 
--     AND ur.ativo = true 
--     AND r.slug = 'colaborador'
--   ) THEN RETURN true; END IF;
--   
--   RETURN false;
-- END;
-- $function$;

-- =====================================================
-- FIM DO SCRIPT
-- =====================================================
