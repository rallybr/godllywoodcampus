-- =====================================================
-- CORREÇÃO DAS FUNCTIONS PARA ESTRUTURA CORRETA
-- =====================================================
-- Este script corrige as functions para usar a estrutura real do sistema

-- 1. FUNCTION CORRIGIDA PARA ACESSO A JOVENS
-- Usa o campo 'nivel' da tabela usuarios em vez de user_roles
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
  user_info record;
BEGIN
  -- Obter informações do usuário atual
  SELECT 
    id,
    nivel,
    estado_id,
    bloco_id,
    regiao_id,
    igreja_id
  INTO user_info
  FROM public.usuarios 
  WHERE id_auth = auth.uid();
  
  -- Se não encontrou o usuário, não tem acesso
  IF user_info IS NULL THEN 
    RAISE NOTICE 'DEBUG: Usuário não encontrado na tabela usuarios';
    RETURN false; 
  END IF;
  
  RAISE NOTICE 'DEBUG: Usuário encontrado - Nível: %', user_info.nivel;
  
  -- 1. ADMINISTRADOR - Acesso total
  IF user_info.nivel = 'administrador' THEN 
    RAISE NOTICE 'DEBUG: Acesso concedido - Administrador';
    RETURN true; 
  END IF;
  
  -- 2. LÍDERES NACIONAIS - Acesso total (como administrador)
  IF user_info.nivel IN ('lider_nacional_iurd', 'lider_nacional_fju') THEN 
    RAISE NOTICE 'DEBUG: Acesso concedido - Líder Nacional (%)', user_info.nivel;
    RETURN true; 
  END IF;
  
  -- 3. LÍDERES ESTADUAIS - Visão estadual
  IF user_info.nivel IN ('lider_estadual_iurd', 'lider_estadual_fju') THEN
    IF user_info.estado_id = jovem_estado_id THEN
      RAISE NOTICE 'DEBUG: Acesso concedido - Líder Estadual (mesmo estado)';
      RETURN true;
    ELSE
      RAISE NOTICE 'DEBUG: Acesso negado - Líder Estadual (estado diferente)';
      RETURN false;
    END IF;
  END IF;
  
  -- 4. LÍDERES DE BLOCO - Visão de bloco
  IF user_info.nivel IN ('lider_bloco_iurd', 'lider_bloco_fju') THEN
    IF user_info.bloco_id = jovem_bloco_id THEN
      RAISE NOTICE 'DEBUG: Acesso concedido - Líder de Bloco (mesmo bloco)';
      RETURN true;
    ELSE
      RAISE NOTICE 'DEBUG: Acesso negado - Líder de Bloco (bloco diferente)';
      RETURN false;
    END IF;
  END IF;
  
  -- 5. LÍDER REGIONAL - Visão regional
  IF user_info.nivel = 'lider_regional_iurd' THEN
    IF user_info.regiao_id = jovem_regiao_id THEN
      RAISE NOTICE 'DEBUG: Acesso concedido - Líder Regional (mesma região)';
      RETURN true;
    ELSE
      RAISE NOTICE 'DEBUG: Acesso negado - Líder Regional (região diferente)';
      RETURN false;
    END IF;
  END IF;
  
  -- 6. LÍDER DE IGREJA - Visão de igreja
  IF user_info.nivel = 'lider_igreja_iurd' THEN
    IF user_info.igreja_id = jovem_igreja_id THEN
      RAISE NOTICE 'DEBUG: Acesso concedido - Líder de Igreja (mesma igreja)';
      RETURN true;
    ELSE
      RAISE NOTICE 'DEBUG: Acesso negado - Líder de Igreja (igreja diferente)';
      RETURN false;
    END IF;
  END IF;
  
  -- 7. COLABORADOR - Vê o que criou
  IF user_info.nivel = 'colaborador' THEN
    -- Verificar se o jovem foi cadastrado por este colaborador
    IF EXISTS (
      SELECT 1 FROM public.jovens j
      WHERE j.estado_id = jovem_estado_id
        AND j.bloco_id = jovem_bloco_id
        AND j.regiao_id = jovem_regiao_id
        AND j.igreja_id = jovem_igreja_id
        AND j.usuario_id = user_info.id
    ) THEN
      RAISE NOTICE 'DEBUG: Acesso concedido - Colaborador (jovem criado por ele)';
      RETURN true;
    ELSE
      RAISE NOTICE 'DEBUG: Acesso negado - Colaborador (jovem não criado por ele)';
      RETURN false;
    END IF;
  END IF;
  
  -- 8. JOVEM - Vê apenas seus próprios dados
  IF user_info.nivel = 'jovem' THEN
    IF EXISTS (
      SELECT 1 FROM public.jovens j
      WHERE j.estado_id = jovem_estado_id
        AND j.bloco_id = jovem_bloco_id
        AND j.regiao_id = jovem_regiao_id
        AND j.igreja_id = jovem_igreja_id
        AND j.usuario_id = user_info.id
    ) THEN
      RAISE NOTICE 'DEBUG: Acesso concedido - Jovem (seus próprios dados)';
      RETURN true;
    ELSE
      RAISE NOTICE 'DEBUG: Acesso negado - Jovem (dados de outros)';
      RETURN false;
    END IF;
  END IF;
  
  RAISE NOTICE 'DEBUG: Acesso negado - Nível não reconhecido: %', user_info.nivel;
  RETURN false;
END;
$function$;

-- 2. FUNCTION CORRIGIDA PARA ACESSO A DADOS DE VIAGEM
-- Usa o campo 'nivel' da tabela usuarios em vez de user_roles
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
  user_info record;
BEGIN
  -- Obter informações do usuário atual
  SELECT 
    id,
    nivel,
    estado_id,
    bloco_id,
    regiao_id,
    igreja_id
  INTO user_info
  FROM public.usuarios 
  WHERE id_auth = auth.uid();
  
  -- Se não encontrou o usuário, não tem acesso
  IF user_info IS NULL THEN 
    RAISE NOTICE 'DEBUG: Usuário não encontrado na tabela usuarios';
    RETURN false; 
  END IF;
  
  RAISE NOTICE 'DEBUG: Usuário encontrado - Nível: %', user_info.nivel;
  
  -- 1. ADMINISTRADOR - Acesso total
  IF user_info.nivel = 'administrador' THEN 
    RAISE NOTICE 'DEBUG: Acesso concedido - Administrador';
    RETURN true; 
  END IF;
  
  -- 2. LÍDERES NACIONAIS - Acesso total (como administrador)
  IF user_info.nivel IN ('lider_nacional_iurd', 'lider_nacional_fju') THEN 
    RAISE NOTICE 'DEBUG: Acesso concedido - Líder Nacional (%)', user_info.nivel;
    RETURN true; 
  END IF;
  
  -- 3. LÍDERES ESTADUAIS - Visão estadual
  IF user_info.nivel IN ('lider_estadual_iurd', 'lider_estadual_fju') THEN
    IF user_info.estado_id = jovem_estado_id THEN
      RAISE NOTICE 'DEBUG: Acesso concedido - Líder Estadual (mesmo estado)';
      RETURN true;
    ELSE
      RAISE NOTICE 'DEBUG: Acesso negado - Líder Estadual (estado diferente)';
      RETURN false;
    END IF;
  END IF;
  
  -- 4. LÍDERES DE BLOCO - Visão de bloco
  IF user_info.nivel IN ('lider_bloco_iurd', 'lider_bloco_fju') THEN
    IF user_info.bloco_id = jovem_bloco_id THEN
      RAISE NOTICE 'DEBUG: Acesso concedido - Líder de Bloco (mesmo bloco)';
      RETURN true;
    ELSE
      RAISE NOTICE 'DEBUG: Acesso negado - Líder de Bloco (bloco diferente)';
      RETURN false;
    END IF;
  END IF;
  
  -- 5. LÍDER REGIONAL - Visão regional
  IF user_info.nivel = 'lider_regional_iurd' THEN
    IF user_info.regiao_id = jovem_regiao_id THEN
      RAISE NOTICE 'DEBUG: Acesso concedido - Líder Regional (mesma região)';
      RETURN true;
    ELSE
      RAISE NOTICE 'DEBUG: Acesso negado - Líder Regional (região diferente)';
      RETURN false;
    END IF;
  END IF;
  
  -- 6. LÍDER DE IGREJA - Visão de igreja
  IF user_info.nivel = 'lider_igreja_iurd' THEN
    IF user_info.igreja_id = jovem_igreja_id THEN
      RAISE NOTICE 'DEBUG: Acesso concedido - Líder de Igreja (mesma igreja)';
      RETURN true;
    ELSE
      RAISE NOTICE 'DEBUG: Acesso negado - Líder de Igreja (igreja diferente)';
      RETURN false;
    END IF;
  END IF;
  
  -- 7. COLABORADOR - Vê o que criou
  IF user_info.nivel = 'colaborador' THEN
    -- Verificar se o colaborador criou dados de viagem para este jovem
    IF EXISTS (
      SELECT 1 FROM public.dados_viagem dv
      JOIN public.jovens j ON j.id = dv.jovem_id
      WHERE j.estado_id = jovem_estado_id
        AND j.bloco_id = jovem_bloco_id
        AND j.regiao_id = jovem_regiao_id
        AND j.igreja_id = jovem_igreja_id
        AND dv.usuario_id = user_info.id
    ) THEN
      RAISE NOTICE 'DEBUG: Acesso concedido - Colaborador (dados de viagem criados por ele)';
      RETURN true;
    ELSE
      RAISE NOTICE 'DEBUG: Acesso negado - Colaborador (dados de viagem não criados por ele)';
      RETURN false;
    END IF;
  END IF;
  
  -- 8. JOVEM - Vê apenas seus próprios dados
  IF user_info.nivel = 'jovem' THEN
    IF EXISTS (
      SELECT 1 FROM public.jovens j
      WHERE j.estado_id = jovem_estado_id
        AND j.bloco_id = jovem_bloco_id
        AND j.regiao_id = jovem_regiao_id
        AND j.igreja_id = jovem_igreja_id
        AND j.usuario_id = user_info.id
    ) THEN
      RAISE NOTICE 'DEBUG: Acesso concedido - Jovem (seus próprios dados)';
      RETURN true;
    ELSE
      RAISE NOTICE 'DEBUG: Acesso negado - Jovem (dados de outros)';
      RETURN false;
    END IF;
  END IF;
  
  RAISE NOTICE 'DEBUG: Acesso negado - Nível não reconhecido: %', user_info.nivel;
  RETURN false;
END;
$function$;

-- 3. VERIFICAR SE AS FUNCTIONS FORAM CRIADAS CORRETAMENTE
SELECT 
  'VERIFICAÇÃO DE FUNCTIONS CRIADAS' as status,
  proname as function_name,
  CASE 
    WHEN prosrc LIKE '%user_info.nivel%' THEN '✅ Function corrigida para usar campo nivel'
    ELSE '❌ Function ainda usa estrutura antiga'
  END as status_correcao
FROM pg_proc 
WHERE proname IN ('can_access_jovem', 'can_access_viagem_by_level')
  AND pronamespace = (SELECT oid FROM pg_namespace WHERE nspname = 'public');

-- =====================================================
-- FIM DA CORREÇÃO
-- =====================================================
