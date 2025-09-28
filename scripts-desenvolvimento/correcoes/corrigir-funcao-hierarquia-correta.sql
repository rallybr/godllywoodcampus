-- CORRIGIR FUNÇÃO COM HIERARQUIA CORRETA
-- Baseado na explicação do usuário sobre escopo geográfico

CREATE OR REPLACE FUNCTION public.get_jovens_por_estado_count(p_edicao_id uuid DEFAULT NULL)
RETURNS TABLE(estado_id uuid, total bigint)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  current_user_id uuid;
  user_info record;
BEGIN
  current_user_id := (SELECT id FROM public.usuarios WHERE id_auth = auth.uid());
  IF current_user_id IS NULL THEN 
    RETURN;
  END IF;

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

  IF user_info IS NULL THEN 
    RETURN;
  END IF;

  -- 1. ADMINISTRADOR - Acesso total
  IF user_info.nivel = 'administrador' THEN 
    RETURN QUERY
    SELECT 
      j.estado_id,
      COUNT(*) as total
    FROM public.jovens j
    WHERE j.estado_id IS NOT NULL
      AND (p_edicao_id IS NULL OR j.edicao_id = p_edicao_id)
    GROUP BY j.estado_id;
    RETURN;
  END IF;

  -- 2. LÍDERES NACIONAIS - Acesso total (visão nacional)
  IF user_info.nivel IN ('lider_nacional_iurd', 'lider_nacional_fju') THEN 
    RETURN QUERY
    SELECT 
      j.estado_id,
      COUNT(*) as total
    FROM public.jovens j
    WHERE j.estado_id IS NOT NULL
      AND (p_edicao_id IS NULL OR j.edicao_id = p_edicao_id)
    GROUP BY j.estado_id;
    RETURN;
  END IF;

  -- 3. LÍDERES ESTADUAIS - Vê TODO O ESTADO (blocos, regiões, igrejas, jovens)
  IF user_info.nivel IN ('lider_estadual_iurd', 'lider_estadual_fju') THEN
    RETURN QUERY
    SELECT 
      j.estado_id,
      COUNT(*) as total
    FROM public.jovens j
    WHERE j.estado_id = user_info.estado_id
      AND (p_edicao_id IS NULL OR j.edicao_id = p_edicao_id)
    GROUP BY j.estado_id;
    RETURN;
  END IF;

  -- 4. LÍDERES DE BLOCO - Vê TODO O BLOCO (regiões, igrejas, jovens do bloco)
  IF user_info.nivel IN ('lider_bloco_iurd', 'lider_bloco_fju') THEN
    RETURN QUERY
    SELECT 
      j.estado_id,
      COUNT(*) as total
    FROM public.jovens j
    WHERE j.bloco_id = user_info.bloco_id
      AND (p_edicao_id IS NULL OR j.edicao_id = p_edicao_id)
    GROUP BY j.estado_id;
    RETURN;
  END IF;

  -- 5. LÍDER REGIONAL - Vê TODA A REGIÃO (igrejas, jovens da região)
  IF user_info.nivel = 'lider_regional_iurd' THEN
    RETURN QUERY
    SELECT 
      j.estado_id,
      COUNT(*) as total
    FROM public.jovens j
    WHERE j.regiao_id = user_info.regiao_id
      AND (p_edicao_id IS NULL OR j.edicao_id = p_edicao_id)
    GROUP BY j.estado_id;
    RETURN;
  END IF;

  -- 6. LÍDER DE IGREJA - Vê TODA A IGREJA (jovens da igreja)
  IF user_info.nivel = 'lider_igreja_iurd' THEN
    RETURN QUERY
    SELECT 
      j.estado_id,
      COUNT(*) as total
    FROM public.jovens j
    WHERE j.igreja_id = user_info.igreja_id
      AND (p_edicao_id IS NULL OR j.edicao_id = p_edicao_id)
    GROUP BY j.estado_id;
    RETURN;
  END IF;

  -- 7. COLABORADOR - Apenas jovens que cadastrou
  IF user_info.nivel = 'colaborador' THEN
    RETURN QUERY
    SELECT 
      j.estado_id,
      COUNT(*) as total
    FROM public.jovens j
    WHERE j.usuario_id = current_user_id
      AND (p_edicao_id IS NULL OR j.edicao_id = p_edicao_id)
    GROUP BY j.estado_id;
    RETURN;
  END IF;

  -- 8. JOVEM - Apenas seus próprios dados
  IF user_info.nivel = 'jovem' THEN
    RETURN QUERY
    SELECT 
      j.estado_id,
      COUNT(*) as total
    FROM public.jovens j
    WHERE j.usuario_id = current_user_id
      AND (p_edicao_id IS NULL OR j.edicao_id = p_edicao_id)
    GROUP BY j.estado_id;
    RETURN;
  END IF;

  -- Se não for nenhum dos níveis acima, retorna vazio
  RETURN;
END;
$$;

-- TESTAR A FUNÇÃO CORRIGIDA
SELECT 'Função corrigida - Teste' as teste, COUNT(*) as total FROM public.get_jovens_por_estado_count(NULL);
