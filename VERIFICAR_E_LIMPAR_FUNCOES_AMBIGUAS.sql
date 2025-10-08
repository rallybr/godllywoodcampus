-- =====================================================
-- VERIFICAÇÃO E LIMPEZA: Remover todas as versões antigas
-- =====================================================

-- 1. Verificar todas as versões da função can_access_jovem
SELECT 
  proname as nome_funcao,
  pg_get_function_arguments(oid) as argumentos,
  pg_get_functiondef(oid) as definicao
FROM pg_proc
WHERE proname LIKE '%can_access_jovem%'
  AND pronamespace = 'public'::regnamespace;

-- 2. Verificar todas as versões da função aprovar_jovem_multiplo
SELECT 
  proname as nome_funcao,
  pg_get_function_arguments(oid) as argumentos,
  pg_get_functiondef(oid) as definicao
FROM pg_proc
WHERE proname = 'aprovar_jovem_multiplo'
  AND pronamespace = 'public'::regnamespace;

-- 3. REMOVER TODAS as versões das funções
DROP FUNCTION IF EXISTS public.can_access_jovem(uuid, uuid, uuid, uuid) CASCADE;
DROP FUNCTION IF EXISTS public.can_access_jovem_com_associacoes(uuid, uuid, uuid, uuid, uuid) CASCADE;
DROP FUNCTION IF EXISTS public.can_access_jovem(uuid, uuid, uuid, uuid, uuid) CASCADE;
DROP FUNCTION IF EXISTS public.aprovar_jovem_multiplo(uuid, text, text) CASCADE;

-- 4. RECRIAR função can_access_jovem com alias JUA (SEM AMBIGUIDADE)
CREATE OR REPLACE FUNCTION public.can_access_jovem(
  jovem_estado_id uuid, 
  jovem_bloco_id uuid, 
  jovem_regiao_id uuid, 
  jovem_igreja_id uuid,
  p_jovem_id uuid DEFAULT NULL
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
  
  IF user_info IS NULL THEN 
    RETURN false; 
  END IF;
  
  -- 1. ADMINISTRADOR - Acesso total
  IF user_info.nivel = 'administrador' THEN 
    RETURN true; 
  END IF;
  
  -- 2. LÍDERES NACIONAIS - Acesso total
  IF user_info.nivel IN ('lider_nacional_iurd', 'lider_nacional_fju') THEN 
    RETURN true; 
  END IF;
  
  -- 3. LÍDERES ESTADUAIS - Acesso ao estado OU jovens associados
  IF user_info.nivel IN ('lider_estadual_iurd', 'lider_estadual_fju') THEN 
    IF user_info.estado_id IS NOT NULL AND jovem_estado_id = user_info.estado_id THEN 
      RETURN true; 
    END IF;
    
    IF p_jovem_id IS NOT NULL THEN
      SELECT EXISTS(
        SELECT 1 FROM public.jovens_usuarios_associacoes jua
        WHERE jua.jovem_id = p_jovem_id AND jua.usuario_id = current_user_id
      ) INTO tem_associacao;
      
      IF tem_associacao THEN 
        RETURN true; 
      END IF;
    END IF;
    
    RETURN false;
  END IF;
  
  -- 4. LÍDERES DE BLOCO - Acesso ao bloco OU jovens associados
  IF user_info.nivel IN ('lider_bloco_iurd', 'lider_bloco_fju') THEN 
    IF user_info.bloco_id IS NOT NULL AND jovem_bloco_id = user_info.bloco_id THEN 
      RETURN true; 
    END IF;
    
    IF p_jovem_id IS NOT NULL THEN
      SELECT EXISTS(
        SELECT 1 FROM public.jovens_usuarios_associacoes jua
        WHERE jua.jovem_id = p_jovem_id AND jua.usuario_id = current_user_id
      ) INTO tem_associacao;
      
      IF tem_associacao THEN 
        RETURN true; 
      END IF;
    END IF;
    
    RETURN false;
  END IF;
  
  -- 5. LÍDERES REGIONAIS - Acesso à região OU jovens associados
  IF user_info.nivel = 'lider_regional_iurd' THEN 
    IF user_info.regiao_id IS NOT NULL AND jovem_regiao_id = user_info.regiao_id THEN 
      RETURN true; 
    END IF;
    
    IF p_jovem_id IS NOT NULL THEN
      SELECT EXISTS(
        SELECT 1 FROM public.jovens_usuarios_associacoes jua
        WHERE jua.jovem_id = p_jovem_id AND jua.usuario_id = current_user_id
      ) INTO tem_associacao;
      
      IF tem_associacao THEN 
        RETURN true; 
      END IF;
    END IF;
    
    RETURN false;
  END IF;
  
  -- 6. LÍDERES DE IGREJA - Acesso à igreja OU jovens associados
  IF user_info.nivel = 'lider_igreja_iurd' THEN 
    IF user_info.igreja_id IS NOT NULL AND jovem_igreja_id = user_info.igreja_id THEN 
      RETURN true; 
    END IF;
    
    IF p_jovem_id IS NOT NULL THEN
      SELECT EXISTS(
        SELECT 1 FROM public.jovens_usuarios_associacoes jua
        WHERE jua.jovem_id = p_jovem_id AND jua.usuario_id = current_user_id
      ) INTO tem_associacao;
      
      IF tem_associacao THEN 
        RETURN true; 
      END IF;
    END IF;
    
    RETURN false;
  END IF;
  
  RETURN false;
END;
$function$;

-- 5. RECRIAR função aprovar_jovem_multiplo (SEM AMBIGUIDADE)
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
  
  -- ✅ CORREÇÃO: Usar a função com nome correto e passar p_jovem_id
  IF NOT public.can_access_jovem(
    jovem_info.estado_id, 
    jovem_info.bloco_id, 
    jovem_info.regiao_id, 
    jovem_info.igreja_id,
    p_jovem_id  -- ✅ Passar o ID do jovem para verificação de associação
  ) THEN
    RETURN jsonb_build_object('success', false, 'error', 'Sem permissão para aprovar este jovem');
  END IF;
  
  -- Verificar se o tipo de aprovação é válido
  IF p_tipo_aprovacao NOT IN ('pre_aprovado', 'aprovado') THEN
    RETURN jsonb_build_object('success', false, 'error', 'Tipo de aprovação inválido');
  END IF;
  
  -- Inserir ou atualizar aprovação (usando alias AJ para evitar ambiguidade)
  INSERT INTO public.aprovacoes_jovens (jovem_id, usuario_id, tipo_aprovacao, observacao)
  VALUES (p_jovem_id, current_user_id, p_tipo_aprovacao, p_observacao)
  ON CONFLICT (jovem_id, usuario_id, tipo_aprovacao) 
  DO UPDATE SET 
    observacao = EXCLUDED.observacao,
    atualizado_em = now();
  
  -- Criar log de auditoria
  INSERT INTO public.logs_auditoria (
    usuario_id, 
    acao, 
    detalhe, 
    dados_novos
  ) VALUES (
    current_user_id,
    'aprovacao_multipla',
    format('Jovem %s %s por usuário %s', p_jovem_id, p_tipo_aprovacao, current_user_id),
    jsonb_build_object(
      'jovem_id', p_jovem_id,
      'tipo_aprovacao', p_tipo_aprovacao,
      'observacao', p_observacao
    )
  );
  
  -- Retornar sucesso
  RETURN jsonb_build_object(
    'success', true, 
    'message', 'Aprovação registrada com sucesso',
    'jovem_id', p_jovem_id,
    'tipo_aprovacao', p_tipo_aprovacao
  );
  
EXCEPTION
  WHEN OTHERS THEN
    RETURN jsonb_build_object('success', false, 'error', SQLERRM);
END;
$function$;

-- 6. Comentários
COMMENT ON FUNCTION public.can_access_jovem IS 'v3.0.0 - Verificação de acesso com suporte a associações (SEM AMBIGUIDADE)';
COMMENT ON FUNCTION public.aprovar_jovem_multiplo IS 'v3.0.0 - Aprovações múltiplas com suporte a associações (SEM AMBIGUIDADE)';

-- 7. Verificação final
SELECT 
  'CORREÇÃO COMPLETA APLICADA' as status,
  'Funções recriadas sem ambiguidade' as detalhe,
  'Teste novamente a aprovação' as proxima_acao;
