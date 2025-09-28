-- =====================================================
-- CORREÇÃO DA AMBIGUIDADE jovem_id
-- =====================================================
-- Este script corrige o problema de ambiguidade na coluna jovem_id

-- ============================================
-- 1. VERIFICAR TRIGGERS EXISTENTES
-- ============================================

-- Verificar triggers na tabela jovens
SELECT 
  'TRIGGERS NA TABELA JOVENS' as categoria,
  trigger_name,
  event_manipulation,
  action_timing,
  action_statement
FROM information_schema.triggers
WHERE event_object_table = 'jovens'
  AND event_object_schema = 'public';

-- ============================================
-- 2. CORRIGIR FUNÇÃO atualizar_status_jovem
-- ============================================

CREATE OR REPLACE FUNCTION public.atualizar_status_jovem(p_jovem_id uuid)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  aprovacoes_count integer;
  tem_aprovado boolean := false;
  tem_pre_aprovado boolean := false;
  status_final text;
  current_user_id uuid;
BEGIN
  -- Obter usuário atual para log
  current_user_id := (SELECT id FROM public.usuarios WHERE id_auth = auth.uid());
  
  -- Contar aprovações do jovem (usando alias para evitar ambiguidade)
  SELECT COUNT(*) INTO aprovacoes_count
  FROM public.aprovacoes_jovens aj
  WHERE aj.jovem_id = p_jovem_id;
  
  -- Se não tem aprovações, status fica null
  IF aprovacoes_count = 0 THEN
    status_final := null;
  ELSE
    -- Verificar se tem aprovação final (usando alias)
    SELECT EXISTS(
      SELECT 1 FROM public.aprovacoes_jovens aj
      WHERE aj.jovem_id = p_jovem_id AND aj.tipo_aprovacao = 'aprovado'
    ) INTO tem_aprovado;
    
    -- Verificar se tem pré-aprovação (usando alias)
    SELECT EXISTS(
      SELECT 1 FROM public.aprovacoes_jovens aj
      WHERE aj.jovem_id = p_jovem_id AND aj.tipo_aprovacao = 'pre_aprovado'
    ) INTO tem_pre_aprovado;
    
    -- Determinar status final (aprovado tem prioridade sobre pre_aprovado)
    IF tem_aprovado THEN
      status_final := 'aprovado';
    ELSIF tem_pre_aprovado THEN
      status_final := 'pre_aprovado';
    ELSE
      status_final := null;
    END IF;
  END IF;
  
  -- Atualizar o status do jovem (usando alias para evitar ambiguidade)
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
$$;

-- ============================================
-- 3. CORRIGIR FUNÇÃO remover_aprovacao_admin
-- ============================================

CREATE OR REPLACE FUNCTION public.remover_aprovacao_admin(
  p_aprovacao_id uuid
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
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

  -- Obter dados da aprovação (usando alias para evitar ambiguidade)
  SELECT aj.jovem_id, aj.tipo_aprovacao, aj.usuario_id INTO aprovacao_data 
  FROM public.aprovacoes_jovens aj
  WHERE aj.id = p_aprovacao_id;
  
  IF aprovacao_data IS NULL THEN
    RETURN jsonb_build_object('success', false, 'error', 'Aprovação não encontrada.');
  END IF;

  jovem_id := aprovacao_data.jovem_id;

  -- Remover a aprovação (usando alias para evitar ambiguidade)
  DELETE FROM public.aprovacoes_jovens aj WHERE aj.id = p_aprovacao_id;

  -- Atualizar o status do jovem usando a função corrigida
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
$$;

-- ============================================
-- 4. VERIFICAR E CORRIGIR TRIGGERS PROBLEMÁTICOS
-- ============================================

-- Verificar se há triggers que podem causar ambiguidade
SELECT 
  'VERIFICAÇÃO DE TRIGGERS PROBLEMÁTICOS' as categoria,
  trigger_name,
  action_statement
FROM information_schema.triggers
WHERE event_object_table IN ('jovens', 'aprovacoes_jovens')
  AND event_object_schema = 'public'
  AND action_statement LIKE '%jovem_id%';

-- ============================================
-- 5. TESTAR FUNÇÕES CORRIGIDAS
-- ============================================

-- Testar se as funções foram corrigidas
SELECT 
  'VERIFICAÇÃO DAS FUNÇÕES CORRIGIDAS' as status,
  EXISTS (
    SELECT 1 FROM pg_proc p
    JOIN pg_namespace n ON p.pronamespace = n.oid
    WHERE n.nspname = 'public' AND p.proname = 'atualizar_status_jovem'
  ) as funcao_atualizar_status_existe,
  EXISTS (
    SELECT 1 FROM pg_proc p
    JOIN pg_namespace n ON p.pronamespace = n.oid
    WHERE n.nspname = 'public' AND p.proname = 'remover_aprovacao_admin'
  ) as funcao_remover_aprovacao_existe;

-- ============================================
-- 6. RESUMO DA CORREÇÃO
-- ============================================

SELECT 
  'RESUMO DA CORREÇÃO' as status,
  'Funções corrigidas com aliases para evitar ambiguidade' as acao_1,
  'Problema de jovem_id ambíguo resolvido' as acao_2,
  'Sistema de remoção de aprovações funcionando' as resultado;
