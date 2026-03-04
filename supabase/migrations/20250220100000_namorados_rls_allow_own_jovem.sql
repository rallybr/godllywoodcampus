-- =============================================================================
-- GODLLYWOOD CAMPUS - Ajuste RLS namorados: líder pode acessar OU jovem pode
-- editar o namorado do próprio perfil (jovens.usuario_id = usuário logado).
-- =============================================================================

-- Remover policies antigas para recriar com regra que inclui "próprio perfil"
DROP POLICY IF EXISTS "namorados_select" ON public.namorados;
DROP POLICY IF EXISTS "namorados_insert" ON public.namorados;
DROP POLICY IF EXISTS "namorados_update" ON public.namorados;
DROP POLICY IF EXISTS "namorados_delete" ON public.namorados;

-- Garantir que a função de acesso com associações exista
CREATE OR REPLACE FUNCTION public.can_access_jovem_com_associacoes(
  jovem_estado_id uuid, 
  jovem_bloco_id uuid, 
  jovem_regiao_id uuid, 
  jovem_igreja_id uuid,
  jovem_id uuid DEFAULT NULL
) RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
AS $function$
DECLARE
  current_user_id uuid;
  user_info record;
  tem_associacao boolean := false;
BEGIN
  -- Obter o ID do usuário atual
  current_user_id := (SELECT id FROM public.usuarios WHERE id_auth = auth.uid());
  
  -- Se não encontrou o usuário, não tem acesso
  IF current_user_id IS NULL THEN 
    RETURN false; 
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
  
  -- Se não encontrou o usuário, não tem acesso
  IF user_info IS NULL THEN 
    RETURN false; 
  END IF;
  
  -- 1. ADMINISTRADOR - Acesso total
  IF user_info.nivel = 'administrador' THEN 
    RETURN true; 
  END IF;
  
  -- 2. LÍDERES NACIONAIS - Acesso total (visão nacional)
  IF user_info.nivel IN ('lider_nacional_iurd', 'lider_nacional_fju') THEN 
    RETURN true; 
  END IF;
  
  -- 3. LÍDERES ESTADUAIS - Acesso ao estado OU jovens associados
  IF user_info.nivel IN ('lider_estadual_iurd', 'lider_estadual_fju') THEN 
    -- Verificar acesso geográfico
    IF user_info.estado_id IS NOT NULL AND jovem_estado_id = user_info.estado_id THEN 
      RETURN true; 
    END IF;
    
    -- Verificar associação (se jovem_id foi fornecido)
    IF jovem_id IS NOT NULL THEN
      SELECT EXISTS(
        SELECT 1 FROM public.jovens_usuarios_associacoes 
        WHERE jovens_usuarios_associacoes.jovem_id = jovem_id AND jovens_usuarios_associacoes.usuario_id = current_user_id
      ) INTO tem_associacao;
      
      IF tem_associacao THEN 
        RETURN true; 
      END IF;
    END IF;
    
    RETURN false;
  END IF;
  
  -- 4. LÍDERES DE BLOCO - Acesso ao bloco OU jovens associados
  IF user_info.nivel IN ('lider_bloco_iurd', 'lider_bloco_fju') THEN 
    -- Verificar acesso geográfico
    IF user_info.bloco_id IS NOT NULL AND jovem_bloco_id = user_info.bloco_id THEN 
      RETURN true; 
    END IF;
    
    -- Verificar associação (se jovem_id foi fornecido)
    IF jovem_id IS NOT NULL THEN
      SELECT EXISTS(
        SELECT 1 FROM public.jovens_usuarios_associacoes 
        WHERE jovens_usuarios_associacoes.jovem_id = jovem_id AND jovens_usuarios_associacoes.usuario_id = current_user_id
      ) INTO tem_associacao;
      
      IF tem_associacao THEN 
        RETURN true; 
      END IF;
    END IF;
    
    RETURN false;
  END IF;
  
  -- 5. LÍDERES REGIONAIS - Acesso à região OU jovens associados
  IF user_info.nivel = 'lider_regional_iurd' THEN 
    -- Verificar acesso geográfico
    IF user_info.regiao_id IS NOT NULL AND jovem_regiao_id = user_info.regiao_id THEN 
      RETURN true; 
    END IF;
    
    -- Verificar associação (se jovem_id foi fornecido)
    IF jovem_id IS NOT NULL THEN
      SELECT EXISTS(
        SELECT 1 FROM public.jovens_usuarios_associacoes 
        WHERE jovens_usuarios_associacoes.jovem_id = jovem_id AND jovens_usuarios_associacoes.usuario_id = current_user_id
      ) INTO tem_associacao;
      
      IF tem_associacao THEN 
        RETURN true; 
      END IF;
    END IF;
    
    RETURN false;
  END IF;
  
  -- 6. LÍDERES DE IGREJA - Acesso à igreja OU jovens associados
  IF user_info.nivel = 'lider_igreja_iurd' THEN 
    -- Verificar acesso geográfico
    IF user_info.igreja_id IS NOT NULL AND jovem_igreja_id = user_info.igreja_id THEN 
      RETURN true; 
    END IF;
    
    -- Verificar associação (se jovem_id foi fornecido)
    IF jovem_id IS NOT NULL THEN
      SELECT EXISTS(
        SELECT 1 FROM public.jovens_usuarios_associacoes 
        WHERE jovens_usuarios_associacoes.jovem_id = jovem_id AND jovens_usuarios_associacoes.usuario_id = current_user_id
      ) INTO tem_associacao;
      
      IF tem_associacao THEN 
        RETURN true; 
      END IF;
    END IF;
    
    RETURN false;
  END IF;
  
  -- 7. COLABORADOR - Acesso apenas aos jovens que cadastrou
  IF user_info.nivel = 'colaborador' THEN 
    -- Colaborador não tem acesso via associações, apenas via usuario_id
    RETURN false;
  END IF;
  
  -- 8. JOVEM - Acesso apenas ao próprio perfil
  IF user_info.nivel = 'jovem' THEN 
    -- Jovem não tem acesso via associações, apenas ao próprio perfil
    RETURN false;
  END IF;
  
  -- Se chegou até aqui, não tem acesso
  RETURN false;
END;
$function$;

-- Helper: jovem pertence ao usuário logado (jovem pode editar seu próprio perfil)
-- usuários.id_auth = auth.uid() e jovens.usuario_id = usuários.id
CREATE OR REPLACE FUNCTION public.namorado_jovem_pertence_ao_usuario(p_jovem_id uuid)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1
    FROM public.jovens j
    INNER JOIN public.usuarios u ON u.id = j.usuario_id AND u.id_auth = auth.uid()
    WHERE j.id = p_jovem_id
  );
$$;

COMMENT ON FUNCTION public.namorado_jovem_pertence_ao_usuario(uuid) IS 'True se o jovem pertence ao usuário logado (jovens.usuario_id = usuarios.id onde id_auth = auth.uid())';

-- SELECT: líder (can_access_jovem / com associações) OU dona do perfil
CREATE POLICY "namorados_select"
ON public.namorados FOR SELECT
TO authenticated
USING (
  public.can_access_jovem(
    (SELECT j.estado_id FROM public.jovens j WHERE j.id = namorados.jovem_id),
    (SELECT j.bloco_id FROM public.jovens j WHERE j.id = namorados.jovem_id),
    (SELECT j.regiao_id FROM public.jovens j WHERE j.id = namorados.jovem_id),
    (SELECT j.igreja_id FROM public.jovens j WHERE j.id = namorados.jovem_id)
  )
  OR public.can_access_jovem_com_associacoes(
    (SELECT j.estado_id FROM public.jovens j WHERE j.id = namorados.jovem_id),
    (SELECT j.bloco_id FROM public.jovens j WHERE j.id = namorados.jovem_id),
    (SELECT j.regiao_id FROM public.jovens j WHERE j.id = namorados.jovem_id),
    (SELECT j.igreja_id FROM public.jovens j WHERE j.id = namorados.jovem_id),
    namorados.jovem_id
  )
  OR public.namorado_jovem_pertence_ao_usuario(namorados.jovem_id)
);

-- INSERT: líder (geografia OU associações) OU dona do perfil (jovem_id é o da linha sendo inserida)
CREATE POLICY "namorados_insert"
ON public.namorados FOR INSERT
TO authenticated
WITH CHECK (
  public.can_access_jovem(
    (SELECT j.estado_id FROM public.jovens j WHERE j.id = jovem_id),
    (SELECT j.bloco_id FROM public.jovens j WHERE j.id = jovem_id),
    (SELECT j.regiao_id FROM public.jovens j WHERE j.id = jovem_id),
    (SELECT j.igreja_id FROM public.jovens j WHERE j.id = jovem_id)
  )
  OR public.can_access_jovem_com_associacoes(
    (SELECT j.estado_id FROM public.jovens j WHERE j.id = jovem_id),
    (SELECT j.bloco_id FROM public.jovens j WHERE j.id = jovem_id),
    (SELECT j.regiao_id FROM public.jovens j WHERE j.id = jovem_id),
    (SELECT j.igreja_id FROM public.jovens j WHERE j.id = jovem_id),
    jovem_id
  )
  OR public.namorado_jovem_pertence_ao_usuario(jovem_id)
);

-- UPDATE: líder (geografia OU associações) OU dona do perfil
CREATE POLICY "namorados_update"
ON public.namorados FOR UPDATE
TO authenticated
USING (
  public.can_access_jovem(
    (SELECT j.estado_id FROM public.jovens j WHERE j.id = namorados.jovem_id),
    (SELECT j.bloco_id FROM public.jovens j WHERE j.id = namorados.jovem_id),
    (SELECT j.regiao_id FROM public.jovens j WHERE j.id = namorados.jovem_id),
    (SELECT j.igreja_id FROM public.jovens j WHERE j.id = namorados.jovem_id)
  )
  OR public.can_access_jovem_com_associacoes(
    (SELECT j.estado_id FROM public.jovens j WHERE j.id = namorados.jovem_id),
    (SELECT j.bloco_id FROM public.jovens j WHERE j.id = namorados.jovem_id),
    (SELECT j.regiao_id FROM public.jovens j WHERE j.id = namorados.jovem_id),
    (SELECT j.igreja_id FROM public.jovens j WHERE j.id = namorados.jovem_id),
    namorados.jovem_id
  )
  OR public.namorado_jovem_pertence_ao_usuario(namorados.jovem_id)
);

-- DELETE: líder (geografia OU associações) OU dona do perfil
CREATE POLICY "namorados_delete"
ON public.namorados FOR DELETE
TO authenticated
USING (
  public.can_access_jovem(
    (SELECT j.estado_id FROM public.jovens j WHERE j.id = namorados.jovem_id),
    (SELECT j.bloco_id FROM public.jovens j WHERE j.id = namorados.jovem_id),
    (SELECT j.regiao_id FROM public.jovens j WHERE j.id = namorados.jovem_id),
    (SELECT j.igreja_id FROM public.jovens j WHERE j.id = namorados.jovem_id)
  )
  OR public.can_access_jovem_com_associacoes(
    (SELECT j.estado_id FROM public.jovens j WHERE j.id = namorados.jovem_id),
    (SELECT j.bloco_id FROM public.jovens j WHERE j.id = namorados.jovem_id),
    (SELECT j.regiao_id FROM public.jovens j WHERE j.id = namorados.jovem_id),
    (SELECT j.igreja_id FROM public.jovens j WHERE j.id = namorados.jovem_id),
    namorados.jovem_id
  )
  OR public.namorado_jovem_pertence_ao_usuario(namorados.jovem_id)
);
