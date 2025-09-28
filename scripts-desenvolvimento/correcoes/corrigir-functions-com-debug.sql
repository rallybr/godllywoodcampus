-- =====================================================
-- CORREÇÃO DAS FUNCTIONS COM DEBUG
-- =====================================================
-- Este script corrige as functions e adiciona debug para identificar problemas

-- 1. FUNCTION CORRIGIDA PARA ACESSO A JOVENS COM DEBUG
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
  debug_info text;
BEGIN
  -- Obter o ID do usuário atual
  current_user_id := (SELECT id FROM public.usuarios WHERE id_auth = auth.uid());
  
  -- Debug: Verificar se o usuário está autenticado
  IF current_user_id IS NULL THEN 
    RAISE NOTICE 'DEBUG: Usuário não autenticado ou não encontrado na tabela usuarios';
    RETURN false; 
  END IF;
  
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
  
  -- Debug: Verificar se o usuário tem papéis
  IF user_roles_info IS NULL THEN 
    RAISE NOTICE 'DEBUG: Usuário não tem papéis ativos';
    RETURN false; 
  END IF;
  
  -- Debug: Mostrar informações do papel
  RAISE NOTICE 'DEBUG: Papel encontrado: % (nível %)', user_roles_info.slug, user_roles_info.nivel_hierarquico;
  
  -- 1. ADMINISTRADOR (nível 1) - Acesso total
  IF user_roles_info.nivel_hierarquico = 1 THEN 
    RAISE NOTICE 'DEBUG: Acesso concedido - Administrador';
    RETURN true; 
  END IF;
  
  -- 2. LÍDERES NACIONAIS (nível 2) - Acesso total (como administrador)
  IF user_roles_info.nivel_hierarquico = 2 THEN 
    RAISE NOTICE 'DEBUG: Acesso concedido - Líder Nacional';
    RETURN true; 
  END IF;
  
  -- 3. LÍDERES ESTADUAIS (nível 3) - Visão estadual
  IF user_roles_info.nivel_hierarquico = 3 THEN
    IF user_roles_info.estado_id = jovem_estado_id THEN
      RAISE NOTICE 'DEBUG: Acesso concedido - Líder Estadual (mesmo estado)';
      RETURN true;
    ELSE
      RAISE NOTICE 'DEBUG: Acesso negado - Líder Estadual (estado diferente)';
      RETURN false;
    END IF;
  END IF;
  
  -- 4. LÍDERES DE BLOCO (nível 4) - Visão de bloco
  IF user_roles_info.nivel_hierarquico = 4 THEN
    IF user_roles_info.bloco_id = jovem_bloco_id THEN
      RAISE NOTICE 'DEBUG: Acesso concedido - Líder de Bloco (mesmo bloco)';
      RETURN true;
    ELSE
      RAISE NOTICE 'DEBUG: Acesso negado - Líder de Bloco (bloco diferente)';
      RETURN false;
    END IF;
  END IF;
  
  -- 5. LÍDER REGIONAL (nível 5) - Visão regional
  IF user_roles_info.nivel_hierarquico = 5 THEN
    IF user_roles_info.regiao_id = jovem_regiao_id THEN
      RAISE NOTICE 'DEBUG: Acesso concedido - Líder Regional (mesma região)';
      RETURN true;
    ELSE
      RAISE NOTICE 'DEBUG: Acesso negado - Líder Regional (região diferente)';
      RETURN false;
    END IF;
  END IF;
  
  -- 6. LÍDER DE IGREJA (nível 6) - Visão de igreja
  IF user_roles_info.nivel_hierarquico = 6 THEN
    IF user_roles_info.igreja_id = jovem_igreja_id THEN
      RAISE NOTICE 'DEBUG: Acesso concedido - Líder de Igreja (mesma igreja)';
      RETURN true;
    ELSE
      RAISE NOTICE 'DEBUG: Acesso negado - Líder de Igreja (igreja diferente)';
      RETURN false;
    END IF;
  END IF;
  
  -- 7. COLABORADOR (nível 7) - Vê o que criou
  IF user_roles_info.nivel_hierarquico = 7 THEN
    -- Verificar se o jovem foi cadastrado por este colaborador
    IF EXISTS (
      SELECT 1 FROM public.jovens j
      WHERE j.estado_id = jovem_estado_id
        AND j.bloco_id = jovem_bloco_id
        AND j.regiao_id = jovem_regiao_id
        AND j.igreja_id = jovem_igreja_id
        AND j.usuario_id = current_user_id
    ) THEN
      RAISE NOTICE 'DEBUG: Acesso concedido - Colaborador (jovem criado por ele)';
      RETURN true;
    ELSE
      RAISE NOTICE 'DEBUG: Acesso negado - Colaborador (jovem não criado por ele)';
      RETURN false;
    END IF;
  END IF;
  
  -- 8. JOVEM (nível 8) - Vê apenas seus próprios dados
  IF user_roles_info.nivel_hierarquico = 8 THEN
    IF EXISTS (
      SELECT 1 FROM public.jovens j
      WHERE j.estado_id = jovem_estado_id
        AND j.bloco_id = jovem_bloco_id
        AND j.regiao_id = jovem_regiao_id
        AND j.igreja_id = jovem_igreja_id
        AND j.usuario_id = current_user_id
    ) THEN
      RAISE NOTICE 'DEBUG: Acesso concedido - Jovem (seus próprios dados)';
      RETURN true;
    ELSE
      RAISE NOTICE 'DEBUG: Acesso negado - Jovem (dados de outros)';
      RETURN false;
    END IF;
  END IF;
  
  RAISE NOTICE 'DEBUG: Acesso negado - Nível hierárquico não reconhecido: %', user_roles_info.nivel_hierarquico;
  RETURN false;
END;
$function$;

-- 2. FUNCTION CORRIGIDA PARA ACESSO A DADOS DE VIAGEM COM DEBUG
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
  
  -- Debug: Verificar se o usuário está autenticado
  IF current_user_id IS NULL THEN 
    RAISE NOTICE 'DEBUG: Usuário não autenticado ou não encontrado na tabela usuarios';
    RETURN false; 
  END IF;
  
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
  
  -- Debug: Verificar se o usuário tem papéis
  IF user_roles_info IS NULL THEN 
    RAISE NOTICE 'DEBUG: Usuário não tem papéis ativos';
    RETURN false; 
  END IF;
  
  -- Debug: Mostrar informações do papel
  RAISE NOTICE 'DEBUG: Papel encontrado: % (nível %)', user_roles_info.slug, user_roles_info.nivel_hierarquico;
  
  -- 1. ADMINISTRADOR (nível 1) - Acesso total
  IF user_roles_info.nivel_hierarquico = 1 THEN 
    RAISE NOTICE 'DEBUG: Acesso concedido - Administrador';
    RETURN true; 
  END IF;
  
  -- 2. LÍDERES NACIONAIS (nível 2) - Acesso total (como administrador)
  IF user_roles_info.nivel_hierarquico = 2 THEN 
    RAISE NOTICE 'DEBUG: Acesso concedido - Líder Nacional';
    RETURN true; 
  END IF;
  
  -- 3. LÍDERES ESTADUAIS (nível 3) - Visão estadual
  IF user_roles_info.nivel_hierarquico = 3 THEN
    IF user_roles_info.estado_id = jovem_estado_id THEN
      RAISE NOTICE 'DEBUG: Acesso concedido - Líder Estadual (mesmo estado)';
      RETURN true;
    ELSE
      RAISE NOTICE 'DEBUG: Acesso negado - Líder Estadual (estado diferente)';
      RETURN false;
    END IF;
  END IF;
  
  -- 4. LÍDERES DE BLOCO (nível 4) - Visão de bloco
  IF user_roles_info.nivel_hierarquico = 4 THEN
    IF user_roles_info.bloco_id = jovem_bloco_id THEN
      RAISE NOTICE 'DEBUG: Acesso concedido - Líder de Bloco (mesmo bloco)';
      RETURN true;
    ELSE
      RAISE NOTICE 'DEBUG: Acesso negado - Líder de Bloco (bloco diferente)';
      RETURN false;
    END IF;
  END IF;
  
  -- 5. LÍDER REGIONAL (nível 5) - Visão regional
  IF user_roles_info.nivel_hierarquico = 5 THEN
    IF user_roles_info.regiao_id = jovem_regiao_id THEN
      RAISE NOTICE 'DEBUG: Acesso concedido - Líder Regional (mesma região)';
      RETURN true;
    ELSE
      RAISE NOTICE 'DEBUG: Acesso negado - Líder Regional (região diferente)';
      RETURN false;
    END IF;
  END IF;
  
  -- 6. LÍDER DE IGREJA (nível 6) - Visão de igreja
  IF user_roles_info.nivel_hierarquico = 6 THEN
    IF user_roles_info.igreja_id = jovem_igreja_id THEN
      RAISE NOTICE 'DEBUG: Acesso concedido - Líder de Igreja (mesma igreja)';
      RETURN true;
    ELSE
      RAISE NOTICE 'DEBUG: Acesso negado - Líder de Igreja (igreja diferente)';
      RETURN false;
    END IF;
  END IF;
  
  -- 7. COLABORADOR (nível 7) - Vê o que criou
  IF user_roles_info.nivel_hierarquico = 7 THEN
    -- Verificar se o colaborador criou dados de viagem para este jovem
    IF EXISTS (
      SELECT 1 FROM public.dados_viagem dv
      JOIN public.jovens j ON j.id = dv.jovem_id
      WHERE j.estado_id = jovem_estado_id
        AND j.bloco_id = jovem_bloco_id
        AND j.regiao_id = jovem_regiao_id
        AND j.igreja_id = jovem_igreja_id
        AND dv.usuario_id = current_user_id
    ) THEN
      RAISE NOTICE 'DEBUG: Acesso concedido - Colaborador (dados de viagem criados por ele)';
      RETURN true;
    ELSE
      RAISE NOTICE 'DEBUG: Acesso negado - Colaborador (dados de viagem não criados por ele)';
      RETURN false;
    END IF;
  END IF;
  
  -- 8. JOVEM (nível 8) - Vê apenas seus próprios dados
  IF user_roles_info.nivel_hierarquico = 8 THEN
    IF EXISTS (
      SELECT 1 FROM public.jovens j
      WHERE j.estado_id = jovem_estado_id
        AND j.bloco_id = jovem_bloco_id
        AND j.regiao_id = jovem_regiao_id
        AND j.igreja_id = jovem_igreja_id
        AND j.usuario_id = current_user_id
    ) THEN
      RAISE NOTICE 'DEBUG: Acesso concedido - Jovem (seus próprios dados)';
      RETURN true;
    ELSE
      RAISE NOTICE 'DEBUG: Acesso negado - Jovem (dados de outros)';
      RETURN false;
    END IF;
  END IF;
  
  RAISE NOTICE 'DEBUG: Acesso negado - Nível hierárquico não reconhecido: %', user_roles_info.nivel_hierarquico;
  RETURN false;
END;
$function$;

-- 3. VERIFICAR SE AS FUNCTIONS FORAM CRIADAS CORRETAMENTE
SELECT 
  'VERIFICAÇÃO DE FUNCTIONS CRIADAS' as status,
  proname as function_name,
  CASE 
    WHEN prosrc LIKE '%RAISE NOTICE%' THEN '✅ Function com debug criada'
    ELSE '❌ Function sem debug'
  END as debug_status
FROM pg_proc 
WHERE proname IN ('can_access_jovem', 'can_access_viagem_by_level')
  AND pronamespace = (SELECT oid FROM pg_namespace WHERE nspname = 'public');

-- =====================================================
-- FIM DA CORREÇÃO COM DEBUG
-- =====================================================
