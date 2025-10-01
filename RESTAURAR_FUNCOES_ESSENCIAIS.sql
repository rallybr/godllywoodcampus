-- =====================================================
-- SCRIPT PARA RESTAURAR FUNÇÕES ESSENCIAIS
-- =====================================================
-- Execute este script APÓS executar o RESTAURAR_ESTRUTURA_ORIGINAL_COMPLETA.sql

-- Função can_access_jovem (ESSENCIAL)
CREATE OR REPLACE FUNCTION public.can_access_jovem(jovem_estado_id uuid, jovem_bloco_id uuid, jovem_regiao_id uuid, jovem_igreja_id uuid)
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
AS $function$
DECLARE
  current_user_id uuid;
  user_info record;
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

-- Função atualizar_status_jovem (ESSENCIAL)
CREATE OR REPLACE FUNCTION public.atualizar_status_jovem(p_jovem_id uuid)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $function$
DECLARE
  aprovacoes_count integer;
  tem_aprovado boolean := false;
  tem_pre_aprovado boolean := false;
  status_final intellimen_aprovado_enum;
  current_user_id uuid;
BEGIN
  -- Obter usuário atual para log
  current_user_id := (SELECT id FROM public.usuarios WHERE id_auth = auth.uid());
  
  -- Contar aprovações do jovem
  SELECT COUNT(*) INTO aprovacoes_count
  FROM public.aprovacoes_jovens aj
  WHERE aj.jovem_id = p_jovem_id;
  
  -- Se não tem aprovações, status fica null
  IF aprovacoes_count = 0 THEN
    status_final := null;
  ELSE
    -- Verificar se tem aprovação final
    SELECT EXISTS(
      SELECT 1 FROM public.aprovacoes_jovens aj
      WHERE aj.jovem_id = p_jovem_id AND aj.tipo_aprovacao = 'aprovado'
    ) INTO tem_aprovado;
    
    -- Verificar se tem pré-aprovação
    SELECT EXISTS(
      SELECT 1 FROM public.aprovacoes_jovens aj
      WHERE aj.jovem_id = p_jovem_id AND aj.tipo_aprovacao = 'pre_aprovado'
    ) INTO tem_pre_aprovado;
    
    -- Determinar status final (aprovado tem prioridade sobre pre_aprovado)
    IF tem_aprovado THEN
      status_final := 'aprovado'::intellimen_aprovado_enum;
    ELSIF tem_pre_aprovado THEN
      status_final := 'pre_aprovado'::intellimen_aprovado_enum;
    ELSE
      status_final := null;
    END IF;
  END IF;
  
  -- Atualizar o status do jovem
  UPDATE public.jovens j
  SET aprovado = status_final
  WHERE j.id = p_jovem_id;
  
  -- Log da atualização (apenas se usuário estiver autenticado)
  IF current_user_id IS NOT NULL THEN
    INSERT INTO public.logs_auditoria (usuario_id, acao, detalhe, dados_novos)
    VALUES (
      current_user_id,
      'atualizacao_status_jovem',
      'Status do jovem atualizado automaticamente',
      jsonb_build_object(
        'jovem_id', p_jovem_id,
        'status_anterior', (SELECT j2.aprovado FROM public.jovens j2 WHERE j2.id = p_jovem_id),
        'status_novo', status_final,
        'aprovacoes_count', aprovacoes_count
      )
    );
  END IF;
END;
$function$;

-- Função aprovar_jovem_multiplo (ESSENCIAL)
CREATE OR REPLACE FUNCTION public.aprovar_jovem_multiplo(p_jovem_id uuid, p_tipo_aprovacao text, p_observacao text DEFAULT NULL::text)
RETURNS jsonb
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
  
  -- Verificar permissão usando a função can_access_jovem
  IF NOT public.can_access_jovem(
    jovem_info.estado_id, 
    jovem_info.bloco_id, 
    jovem_info.regiao_id, 
    jovem_info.igreja_id
  ) THEN
    RETURN jsonb_build_object('success', false, 'error', 'Sem permissão para aprovar este jovem');
  END IF;
  
  -- Verificar se o tipo de aprovação é válido
  IF p_tipo_aprovacao NOT IN ('pre_aprovado', 'aprovado') THEN
    RETURN jsonb_build_object('success', false, 'error', 'Tipo de aprovação inválido');
  END IF;
  
  -- Inserir ou atualizar aprovação
  INSERT INTO public.aprovacoes_jovens (jovem_id, usuario_id, tipo_aprovacao, observacao)
  VALUES (p_jovem_id, current_user_id, p_tipo_aprovacao, p_observacao)
  ON CONFLICT (jovem_id, usuario_id, tipo_aprovacao) 
  DO UPDATE SET 
    observacao = EXCLUDED.observacao,
    atualizado_em = now();
  
  -- Atualizar status do jovem
  PERFORM public.atualizar_status_jovem(p_jovem_id);
  
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

-- Função obter_lideres_para_notificacao (ESSENCIAL)
CREATE OR REPLACE FUNCTION public.obter_lideres_para_notificacao(p_estado_id uuid, p_bloco_id uuid, p_regiao_id uuid, p_igreja_id uuid)
RETURNS TABLE(user_id uuid)
LANGUAGE plpgsql
SECURITY DEFINER
AS $function$
BEGIN
  RETURN QUERY
  SELECT DISTINCT u.id as user_id
  FROM public.usuarios u
  WHERE u.ativo = true
  AND (
    -- Administradores recebem todas as notificações
    u.nivel = 'administrador'
    OR
    -- Líderes nacionais recebem todas as notificações
    u.nivel IN ('lider_nacional_iurd', 'lider_nacional_fju')
    OR
    -- Líderes estaduais recebem notificações do seu estado
    (u.nivel IN ('lider_estadual_iurd', 'lider_estadual_fju') AND u.estado_id = p_estado_id)
    OR
    -- Líderes de bloco recebem notificações do seu bloco
    (u.nivel IN ('lider_bloco_iurd', 'lider_bloco_fju') AND u.bloco_id = p_bloco_id)
    OR
    -- Líderes regionais recebem notificações da sua região
    (u.nivel = 'lider_regional_iurd' AND u.regiao_id = p_regiao_id)
    OR
    -- Líderes de igreja recebem notificações da sua igreja
    (u.nivel = 'lider_igreja_iurd' AND u.igreja_id = p_igreja_id)
  );
END;
$function$;

-- Função remover_aprovacao_admin (ESSENCIAL)
CREATE OR REPLACE FUNCTION public.remover_aprovacao_admin(p_aprovacao_id uuid)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
AS $function$
DECLARE
  current_user_id uuid;
  user_role_info record;
  aprovacao_data record;
  jovem_id uuid;
BEGIN
  current_user_id := auth.uid();
  IF current_user_id IS NULL THEN
    RETURN jsonb_build_object('success', false, 'error', 'Usuário não autenticado.');
  END IF;

  -- Verificar se o usuário é administrador
  SELECT id, nivel INTO user_role_info FROM public.usuarios WHERE id_auth = current_user_id;
  IF user_role_info.id IS NULL THEN
    RETURN jsonb_build_object('success', false, 'error', 'Perfil de usuário não encontrado.');
  END IF;

  -- Verificar se é administrador
  IF user_role_info.nivel != 'administrador' THEN
    RETURN jsonb_build_object('success', false, 'error', 'Apenas administradores podem remover aprovações.');
  END IF;

  -- Obter dados da aprovação
  SELECT aj.jovem_id, aj.tipo_aprovacao, aj.usuario_id INTO aprovacao_data 
  FROM public.aprovacoes_jovens aj
  WHERE aj.id = p_aprovacao_id;
  
  IF aprovacao_data IS NULL THEN
    RETURN jsonb_build_object('success', false, 'error', 'Aprovação não encontrada.');
  END IF;

  jovem_id := aprovacao_data.jovem_id;

  -- Remover a aprovação
  DELETE FROM public.aprovacoes_jovens aj WHERE aj.id = p_aprovacao_id;

  -- Atualizar o status do jovem
  PERFORM public.atualizar_status_jovem(jovem_id);

  -- Criar log de auditoria
  INSERT INTO public.logs_auditoria (usuario_id, acao, detalhe, dados_novos)
  VALUES (
    user_role_info.id, 
    'remocao_aprovacao_admin', 
    'Aprovação ' || p_aprovacao_id || ' removida por administrador', 
    jsonb_build_object(
      'aprovacao_id', p_aprovacao_id, 
      'jovem_id', jovem_id,
      'tipo_aprovacao', aprovacao_data.tipo_aprovacao,
      'usuario_removido', aprovacao_data.usuario_id
    )
  );

  RETURN jsonb_build_object(
    'success', true, 
    'message', 'Aprovação removida com sucesso.',
    'jovem_id', jovem_id
  );

EXCEPTION
  WHEN OTHERS THEN
    RETURN jsonb_build_object('success', false, 'error', SQLERRM);
END;
$function$;

-- Função buscar_aprovacoes_jovem (ESSENCIAL)
CREATE OR REPLACE FUNCTION public.buscar_aprovacoes_jovem(p_jovem_id uuid)
RETURNS TABLE(id uuid, usuario_id uuid, usuario_nome text, usuario_nivel text, usuario_estado_bandeira text, tipo_aprovacao text, observacao text, criado_em timestamp with time zone)
LANGUAGE plpgsql
SECURITY DEFINER
AS $function$
BEGIN
  RETURN QUERY
  SELECT 
    aj.id,
    aj.usuario_id,
    u.nome as usuario_nome,
    u.nivel as usuario_nivel,
    u.estado_bandeira as usuario_estado_bandeira,
    aj.tipo_aprovacao,
    aj.observacao,
    aj.criado_em
  FROM public.aprovacoes_jovens aj
  JOIN public.usuarios u ON u.id = aj.usuario_id
  WHERE aj.jovem_id = p_jovem_id
  ORDER BY aj.criado_em DESC;
END;
$function$;

-- Função usuario_ja_aprovou (ESSENCIAL)
CREATE OR REPLACE FUNCTION public.usuario_ja_aprovou(p_jovem_id uuid, p_tipo_aprovacao text DEFAULT NULL::text)
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
AS $function$
DECLARE
  current_user_id uuid;
  count_aprovacoes integer;
BEGIN
  current_user_id := (SELECT id FROM public.usuarios WHERE id_auth = auth.uid());
  IF current_user_id IS NULL THEN RETURN false; END IF;
  
  IF p_tipo_aprovacao IS NULL THEN
    -- Verificar se já aprovou de qualquer tipo
    SELECT COUNT(*) INTO count_aprovacoes
    FROM public.aprovacoes_jovens
    WHERE jovem_id = p_jovem_id AND usuario_id = current_user_id;
  ELSE
    -- Verificar se já aprovou do tipo específico
    SELECT COUNT(*) INTO count_aprovacoes
    FROM public.aprovacoes_jovens
    WHERE jovem_id = p_jovem_id 
      AND usuario_id = current_user_id 
      AND tipo_aprovacao = p_tipo_aprovacao;
  END IF;
  
  RETURN count_aprovacoes > 0;
END;
$function$;

-- Mensagem de sucesso
DO $$
BEGIN
    RAISE NOTICE 'Funções essenciais restauradas com sucesso!';
    RAISE NOTICE 'Sistema básico está funcionando.';
END $$;
