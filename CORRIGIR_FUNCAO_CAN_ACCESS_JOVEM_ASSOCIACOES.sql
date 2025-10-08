-- =====================================================
-- CORREÇÃO: Função can_access_jovem com suporte a associações
-- =====================================================
-- Problema: A função can_access_jovem não considera associações da tabela jovens_usuarios_associacoes
-- Solução: Criar versão atualizada que inclui verificação de associações

-- 1. Criar nova função can_access_jovem_com_associacoes
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
        WHERE jovem_id = jovem_id AND usuario_id = current_user_id
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
        WHERE jovem_id = jovem_id AND usuario_id = current_user_id
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
        WHERE jovem_id = jovem_id AND usuario_id = current_user_id
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
        WHERE jovem_id = jovem_id AND usuario_id = current_user_id
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

-- 2. Atualizar função aprovar_jovem_multiplo para usar a nova verificação
CREATE OR REPLACE FUNCTION public.aprovar_jovem_multiplo(
  p_jovem_id uuid, 
  p_tipo_aprovacao text, 
  p_observacao text DEFAULT NULL::text
) RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
AS $function$
DECLARE
  current_user_id uuid;
  user_roles_info record;
  jovem_info record;
  resultado jsonb;
BEGIN
  -- Obter o ID do usuário atual
  current_user_id := (SELECT id FROM public.usuarios WHERE id_auth = auth.uid());
  IF current_user_id IS NULL THEN 
    RETURN jsonb_build_object('success', false, 'error', 'Usuário não autenticado');
  END IF;
  
  -- Buscar informações do jovem
  SELECT estado_id, bloco_id, regiao_id, igreja_id
  INTO jovem_info
  FROM public.jovens
  WHERE id = p_jovem_id;
  
  IF jovem_info IS NULL THEN
    RETURN jsonb_build_object('success', false, 'error', 'Jovem não encontrado');
  END IF;
  
  -- Verificar permissão usando a nova função com suporte a associações
  IF NOT public.can_access_jovem_com_associacoes(
    jovem_info.estado_id, 
    jovem_info.bloco_id, 
    jovem_info.regiao_id, 
    jovem_info.igreja_id,
    p_jovem_id  -- Passar o ID do jovem para verificação de associação
  ) THEN
    RETURN jsonb_build_object('success', false, 'error', 'Sem permissão para aprovar este jovem');
  END IF;
  
  -- Verificar se já existe aprovação deste usuário para este jovem
  IF EXISTS (
    SELECT 1 FROM public.aprovacoes_jovens 
    WHERE jovem_id = p_jovem_id AND usuario_id = current_user_id
  ) THEN
    RETURN jsonb_build_object('success', false, 'error', 'Você já aprovou este jovem');
  END IF;
  
  -- Inserir nova aprovação
  INSERT INTO public.aprovacoes_jovens (
    jovem_id, 
    usuario_id, 
    tipo_aprovacao, 
    observacao
  ) VALUES (
    p_jovem_id, 
    current_user_id, 
    p_tipo_aprovacao, 
    p_observacao
  );
  
  -- Atualizar status do jovem
  PERFORM public.atualizar_status_jovem(p_jovem_id);
  
  -- Retornar sucesso
  RETURN jsonb_build_object(
    'success', true, 
    'message', 'Jovem aprovado com sucesso',
    'tipo_aprovacao', p_tipo_aprovacao
  );
  
EXCEPTION
  WHEN OTHERS THEN
    RETURN jsonb_build_object(
      'success', false, 
      'error', 'Erro interno: ' || SQLERRM
    );
END;
$function$;

-- 3. Comentários das funções
COMMENT ON FUNCTION public.can_access_jovem_com_associacoes IS 'v2.0.0 - Verificação de acesso a jovens incluindo associações da tabela jovens_usuarios_associacoes';
COMMENT ON FUNCTION public.aprovar_jovem_multiplo IS 'v2.0.0 - Sistema de aprovações múltiplas com suporte a associações';

-- 4. Teste da correção
-- SELECT public.can_access_jovem_com_associacoes(
--   'ef6f4033-edb9-5ccb-9f4e-2350200a00ce'::uuid,  -- jovem_estado_id
--   '4fe2a911-82db-58c1-8f19-442b55d3eb39'::uuid,  -- jovem_bloco_id
--   '241fd058-a4e5-58ad-b504-d9b21fb8b53f'::uuid,  -- jovem_regiao_id
--   '46ea9b8d-a2cc-5471-ae97-b65cc8cefbca'::uuid,  -- jovem_igreja_id
--   '21687a5c-b59b-4cf4-8256-c7fb5d0c4884'::uuid   -- jovem_id
-- );
