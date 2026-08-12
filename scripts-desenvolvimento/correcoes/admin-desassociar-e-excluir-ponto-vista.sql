-- Admin: desassociar jovem de qualquer usuário e limpar observação de ponto de vista.

CREATE OR REPLACE FUNCTION public.desassociar_jovem_admin(
  p_jovem_id uuid,
  p_usuario_id uuid
) RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
AS $function$
DECLARE
  admin_row record;
  removidos integer := 0;
BEGIN
  SELECT id, nivel INTO admin_row
  FROM public.usuarios
  WHERE id_auth = auth.uid();

  IF admin_row.id IS NULL THEN
    RETURN jsonb_build_object('success', false, 'error', 'Usuário não autenticado');
  END IF;

  IF admin_row.nivel <> 'administrador' THEN
    RETURN jsonb_build_object('success', false, 'error', 'Apenas administradores podem desassociar jovens');
  END IF;

  DELETE FROM public.jovens_usuarios_associacoes
  WHERE jovem_id = p_jovem_id
    AND usuario_id = p_usuario_id;

  GET DIAGNOSTICS removidos = ROW_COUNT;

  INSERT INTO public.logs_auditoria (usuario_id, acao, detalhe, dados_novos)
  VALUES (
    admin_row.id,
    'desassociacao_admin',
    format('Jovem %s desassociado do usuário %s', p_jovem_id, p_usuario_id),
    jsonb_build_object(
      'jovem_id', p_jovem_id,
      'usuario_id', p_usuario_id,
      'removidos', removidos
    )
  );

  RETURN jsonb_build_object(
    'success', true,
    'message', CASE WHEN removidos > 0 THEN 'Jovem desassociado com sucesso' ELSE 'Nenhuma associação encontrada' END,
    'removidos', removidos
  );

EXCEPTION
  WHEN OTHERS THEN
    RETURN jsonb_build_object('success', false, 'error', SQLERRM);
END;
$function$;

CREATE OR REPLACE FUNCTION public.limpar_observacao_aprovacao_admin(
  p_aprovacao_id uuid
) RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
AS $function$
DECLARE
  admin_row record;
  aprovacao_data record;
BEGIN
  SELECT id, nivel INTO admin_row
  FROM public.usuarios
  WHERE id_auth = auth.uid();

  IF admin_row.id IS NULL THEN
    RETURN jsonb_build_object('success', false, 'error', 'Usuário não autenticado');
  END IF;

  IF admin_row.nivel <> 'administrador' THEN
    RETURN jsonb_build_object('success', false, 'error', 'Apenas administradores podem excluir observações');
  END IF;

  SELECT id, jovem_id, usuario_id, tipo_aprovacao, observacao
  INTO aprovacao_data
  FROM public.aprovacoes_jovens
  WHERE id = p_aprovacao_id;

  IF aprovacao_data.id IS NULL THEN
    RETURN jsonb_build_object('success', false, 'error', 'Registro não encontrado');
  END IF;

  UPDATE public.aprovacoes_jovens
  SET observacao = NULL,
      atualizado_em = now()
  WHERE id = p_aprovacao_id;

  INSERT INTO public.logs_auditoria (usuario_id, acao, detalhe, dados_novos)
  VALUES (
    admin_row.id,
    'limpeza_observacao_admin',
    format('Observação removida da aprovação %s', p_aprovacao_id),
    jsonb_build_object(
      'aprovacao_id', p_aprovacao_id,
      'jovem_id', aprovacao_data.jovem_id,
      'usuario_id', aprovacao_data.usuario_id,
      'tipo_aprovacao', aprovacao_data.tipo_aprovacao
    )
  );

  RETURN jsonb_build_object('success', true, 'message', 'Observação excluída com sucesso');

EXCEPTION
  WHEN OTHERS THEN
    RETURN jsonb_build_object('success', false, 'error', SQLERRM);
END;
$function$;

GRANT EXECUTE ON FUNCTION public.desassociar_jovem_admin(uuid, uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.limpar_observacao_aprovacao_admin(uuid) TO authenticated;

COMMENT ON FUNCTION public.desassociar_jovem_admin IS 'v1.0.0 - Administrador desassocia jovem de qualquer usuário';
COMMENT ON FUNCTION public.limpar_observacao_aprovacao_admin IS 'v1.0.0 - Administrador exclui observação de ponto de vista sem remover o status';
