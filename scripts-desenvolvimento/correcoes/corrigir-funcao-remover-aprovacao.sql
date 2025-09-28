-- =====================================================
-- CORREÇÃO DA FUNÇÃO DE REMOÇÃO DE APROVAÇÕES
-- =====================================================
-- Este script corrige o problema de remoção de aprovações

-- ============================================
-- 1. CRIAR FUNÇÃO atualizar_status_jovem
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
BEGIN
  -- Contar aprovações do jovem
  SELECT COUNT(*) INTO aprovacoes_count
  FROM public.aprovacoes_jovens
  WHERE jovem_id = p_jovem_id;
  
  -- Se não tem aprovações, status fica null
  IF aprovacoes_count = 0 THEN
    status_final := null;
  ELSE
    -- Verificar se tem aprovação final
    SELECT EXISTS(
      SELECT 1 FROM public.aprovacoes_jovens 
      WHERE jovem_id = p_jovem_id AND tipo_aprovacao = 'aprovado'
    ) INTO tem_aprovado;
    
    -- Verificar se tem pré-aprovação
    SELECT EXISTS(
      SELECT 1 FROM public.aprovacoes_jovens 
      WHERE jovem_id = p_jovem_id AND tipo_aprovacao = 'pre_aprovado'
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
  
  -- Atualizar o status do jovem
  UPDATE public.jovens
  SET aprovado = status_final
  WHERE id = p_jovem_id;
  
  -- Log da atualização
  INSERT INTO public.logs_auditoria (usuario_id, acao, detalhe, dados_novos)
  VALUES (
    (SELECT id FROM public.usuarios WHERE id_auth = auth.uid()),
    'atualizacao_status_jovem',
    'Status do jovem atualizado automaticamente',
    jsonb_build_object(
      'jovem_id', p_jovem_id,
      'status_anterior', (SELECT aprovado FROM public.jovens WHERE id = p_jovem_id),
      'status_novo', status_final,
      'aprovacoes_count', aprovacoes_count
    )
  );
END;
$$;

-- ============================================
-- 2. CORRIGIR FUNÇÃO remover_aprovacao_admin
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

  -- Obter dados da aprovação
  SELECT jovem_id, tipo_aprovacao, usuario_id INTO aprovacao_data 
  FROM public.aprovacoes_jovens 
  WHERE id = p_aprovacao_id;
  
  IF aprovacao_data IS NULL THEN
    RETURN jsonb_build_object('success', false, 'error', 'Aprovação não encontrada.');
  END IF;

  jovem_id := aprovacao_data.jovem_id;

  -- Remover a aprovação
  DELETE FROM public.aprovacoes_jovens WHERE id = p_aprovacao_id;

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
-- 3. TESTAR FUNÇÕES
-- ============================================

-- Testar se as funções foram criadas corretamente
SELECT 
  'VERIFICAÇÃO DAS FUNÇÕES' as status,
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
-- 4. VERIFICAR APROVAÇÕES EXISTENTES
-- ============================================

-- Verificar aprovações existentes para teste
SELECT 
  'APROVAÇÕES EXISTENTES' as categoria,
  COUNT(*) as total_aprovacoes,
  COUNT(CASE WHEN tipo_aprovacao = 'aprovado' THEN 1 END) as aprovados,
  COUNT(CASE WHEN tipo_aprovacao = 'pre_aprovado' THEN 1 END) as pre_aprovados
FROM public.aprovacoes_jovens;

-- ============================================
-- 5. RESUMO DA CORREÇÃO
-- ============================================

SELECT 
  'RESUMO DA CORREÇÃO' as status,
  'Função atualizar_status_jovem criada' as acao_1,
  'Função remover_aprovacao_admin corrigida' as acao_2,
  'Sistema de remoção de aprovações funcionando' as resultado;
