-- CORREÇÃO ESPECÍFICA PARA NÍVEL JOVEM
-- Jovens devem ver APENAS seus próprios dados

-- 1. CORRIGIR FUNÇÃO can_access_jovem para jovem
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
  user_info record;
BEGIN
  current_user_id := (SELECT id FROM public.usuarios WHERE id_auth = auth.uid());
  IF current_user_id IS NULL THEN RETURN false; END IF;

  -- Buscar informações do usuário atual
  SELECT 
    id,
    nivel,
    estado_id,
    bloco_id,
    regiao_id,
    igreja_id
  INTO user_info
  FROM public.usuarios
  WHERE id = current_user_id;

  IF user_info IS NULL THEN RETURN false; END IF;

  -- 1. ADMINISTRADOR - Acesso total
  IF user_info.nivel = 'administrador' THEN RETURN true; END IF;

  -- 2. LÍDERES NACIONAIS - Acesso total (visão nacional)
  IF user_info.nivel IN ('lider_nacional_iurd', 'lider_nacional_fju') THEN RETURN true; END IF;

  -- 3. LÍDERES ESTADUAIS - Visão estadual
  IF user_info.nivel IN ('lider_estadual_iurd', 'lider_estadual_fju') THEN
    RETURN user_info.estado_id = jovem_estado_id;
  END IF;

  -- 4. LÍDERES DE BLOCO - Visão de bloco
  IF user_info.nivel IN ('lider_bloco_iurd', 'lider_bloco_fju') THEN
    RETURN user_info.bloco_id = jovem_bloco_id;
  END IF;

  -- 5. LÍDER REGIONAL - Visão regional
  IF user_info.nivel = 'lider_regional_iurd' THEN
    RETURN user_info.regiao_id = jovem_regiao_id;
  END IF;

  -- 6. LÍDER DE IGREJA - Visão de igreja
  IF user_info.nivel = 'lider_igreja_iurd' THEN
    RETURN user_info.igreja_id = jovem_igreja_id;
  END IF;

  -- 7. COLABORADOR - Acesso aos jovens que cadastrou
  IF user_info.nivel = 'colaborador' THEN
    RETURN EXISTS (
      SELECT 1 FROM public.jovens j
      WHERE j.estado_id = jovem_estado_id
        AND j.bloco_id = jovem_bloco_id
        AND j.regiao_id = jovem_regiao_id
        AND j.igreja_id = jovem_igreja_id
        AND j.usuario_id = current_user_id
    );
  END IF;

  -- 8. JOVEM - Acesso APENAS aos seus próprios dados
  IF user_info.nivel = 'jovem' THEN
    -- Verificar se o jovem atual é o mesmo que está sendo acessado
    RETURN EXISTS (
      SELECT 1 FROM public.jovens j
      WHERE j.estado_id = jovem_estado_id
        AND j.bloco_id = jovem_bloco_id
        AND j.regiao_id = jovem_regiao_id
        AND j.igreja_id = jovem_igreja_id
        AND j.usuario_id = current_user_id
        -- GARANTIR que é o próprio jovem
        AND j.id IN (
          SELECT id FROM public.jovens 
          WHERE usuario_id = current_user_id
        )
    );
  END IF;

  RETURN false;
END;
$$;

-- 2. CORRIGIR FUNÇÃO can_access_viagem_by_level para jovem
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
  user_info record;
BEGIN
  current_user_id := (SELECT id FROM public.usuarios WHERE id_auth = auth.uid());
  IF current_user_id IS NULL THEN RETURN false; END IF;

  -- Buscar informações do usuário atual
  SELECT 
    id,
    nivel,
    estado_id,
    bloco_id,
    regiao_id,
    igreja_id
  INTO user_info
  FROM public.usuarios
  WHERE id = current_user_id;

  IF user_info IS NULL THEN RETURN false; END IF;

  -- 1. ADMINISTRADOR - Acesso total
  IF user_info.nivel = 'administrador' THEN RETURN true; END IF;

  -- 2. LÍDERES NACIONAIS - Acesso total (visão nacional)
  IF user_info.nivel IN ('lider_nacional_iurd', 'lider_nacional_fju') THEN RETURN true; END IF;

  -- 3. LÍDERES ESTADUAIS - Visão estadual
  IF user_info.nivel IN ('lider_estadual_iurd', 'lider_estadual_fju') THEN
    RETURN user_info.estado_id = jovem_estado_id;
  END IF;

  -- 4. LÍDERES DE BLOCO - Visão de bloco
  IF user_info.nivel IN ('lider_bloco_iurd', 'lider_bloco_fju') THEN
    RETURN user_info.bloco_id = jovem_bloco_id;
  END IF;

  -- 5. LÍDER REGIONAL - Visão regional
  IF user_info.nivel = 'lider_regional_iurd' THEN
    RETURN user_info.regiao_id = jovem_regiao_id;
  END IF;

  -- 6. LÍDER DE IGREJA - Visão de igreja
  IF user_info.nivel = 'lider_igreja_iurd' THEN
    RETURN user_info.igreja_id = jovem_igreja_id;
  END IF;

  -- 7. COLABORADOR - Acesso aos dados de viagem dos jovens que cadastrou
  IF user_info.nivel = 'colaborador' THEN
    RETURN EXISTS (
      SELECT 1 FROM public.jovens j
      WHERE j.estado_id = jovem_estado_id
        AND j.bloco_id = jovem_bloco_id
        AND j.regiao_id = jovem_regiao_id
        AND j.igreja_id = jovem_igreja_id
        AND j.usuario_id = current_user_id
    );
  END IF;

  -- 8. JOVEM - Acesso APENAS aos seus próprios dados de viagem
  IF user_info.nivel = 'jovem' THEN
    -- Verificar se o jovem atual é o mesmo que está sendo acessado
    RETURN EXISTS (
      SELECT 1 FROM public.jovens j
      WHERE j.estado_id = jovem_estado_id
        AND j.bloco_id = jovem_bloco_id
        AND j.regiao_id = jovem_regiao_id
        AND j.igreja_id = jovem_igreja_id
        AND j.usuario_id = current_user_id
        -- GARANTIR que é o próprio jovem
        AND j.id IN (
          SELECT id FROM public.jovens 
          WHERE usuario_id = current_user_id
        )
    );
  END IF;

  RETURN false;
END;
$$;

-- 3. CRIAR POLICY ESPECÍFICA PARA JOVENS
DROP POLICY IF EXISTS "Allow read based on hierarchy" ON public.jovens;
CREATE POLICY "Allow read based on hierarchy" ON public.jovens FOR SELECT USING (
  can_access_jovem(estado_id, bloco_id, regiao_id, igreja_id)
);

-- 4. CRIAR POLICY ESPECÍFICA PARA DADOS_VIAGEM
DROP POLICY IF EXISTS "Allow read based on hierarchy" ON public.dados_viagem;
CREATE POLICY "Allow read based on hierarchy" ON public.dados_viagem FOR SELECT USING (
  EXISTS (
    SELECT 1 FROM public.jovens j 
    WHERE j.id = dados_viagem.jovem_id 
    AND can_access_viagem_by_level(j.estado_id, j.bloco_id, j.regiao_id, j.igreja_id)
  )
);

-- 5. VERIFICAR SE AS CORREÇÕES FORAM APLICADAS
SELECT 
  'Função can_access_jovem corrigida para jovem' as item,
  CASE WHEN EXISTS (
    SELECT 1 FROM information_schema.routines 
    WHERE routine_name = 'can_access_jovem'
  ) THEN 'OK' ELSE 'ERRO' END as status;

SELECT 
  'Função can_access_viagem_by_level corrigida para jovem' as item,
  CASE WHEN EXISTS (
    SELECT 1 FROM information_schema.routines 
    WHERE routine_name = 'can_access_viagem_by_level'
  ) THEN 'OK' ELSE 'ERRO' END as status;
