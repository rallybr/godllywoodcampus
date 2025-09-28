-- RPC para remover aprovação (apenas administradores)
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
$$;

-- RLS para garantir que apenas administradores possam usar a função
-- (A verificação já está na função, mas podemos adicionar uma policy extra se necessário)

-- Teste da função
-- SELECT public.remover_aprovacao_admin('uuid-da-aprovacao');
