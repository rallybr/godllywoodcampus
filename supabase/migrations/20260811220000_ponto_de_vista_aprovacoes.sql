-- Ponto de Vista: estende aprovacoes_jovens com observar / sem_condicao
-- e mantém um status de ponto de vista por avaliador (além de "aprovado").

-- 1) Ampliar CHECK de tipo_aprovacao
ALTER TABLE public.aprovacoes_jovens
  DROP CONSTRAINT IF EXISTS aprovacoes_jovens_tipo_aprovacao_check;

ALTER TABLE public.aprovacoes_jovens
  ADD CONSTRAINT aprovacoes_jovens_tipo_aprovacao_check
  CHECK (tipo_aprovacao IN ('pre_aprovado', 'aprovado', 'observar', 'sem_condicao'));

-- 2) Atualizar RPC de aprovação múltipla
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
  jovem_info record;
  obs text;
BEGIN
  current_user_id := (SELECT id FROM public.usuarios WHERE id_auth = auth.uid());
  IF current_user_id IS NULL THEN
    RETURN jsonb_build_object('success', false, 'error', 'Usuário não autenticado');
  END IF;

  SELECT estado_id, bloco_id, regiao_id, igreja_id
  INTO jovem_info
  FROM public.jovens
  WHERE id = p_jovem_id;

  IF jovem_info IS NULL THEN
    RETURN jsonb_build_object('success', false, 'error', 'Jovem não encontrado');
  END IF;

  IF NOT public.can_access_jovem(
    jovem_info.estado_id,
    jovem_info.bloco_id,
    jovem_info.regiao_id,
    jovem_info.igreja_id,
    p_jovem_id
  ) THEN
    RETURN jsonb_build_object('success', false, 'error', 'Sem permissão para aprovar este jovem');
  END IF;

  IF p_tipo_aprovacao NOT IN ('pre_aprovado', 'aprovado', 'observar', 'sem_condicao') THEN
    RETURN jsonb_build_object('success', false, 'error', 'Tipo de aprovação inválido');
  END IF;

  obs := NULLIF(btrim(COALESCE(p_observacao, '')), '');
  IF obs IS NOT NULL AND char_length(obs) > 144 THEN
    RETURN jsonb_build_object('success', false, 'error', 'Observação deve ter no máximo 144 caracteres');
  END IF;

  -- Um ponto de vista por avaliador (OK / Observar / Sem condição são alternativos).
  -- "aprovado" permanece independente.
  IF p_tipo_aprovacao IN ('pre_aprovado', 'observar', 'sem_condicao') THEN
    DELETE FROM public.aprovacoes_jovens
    WHERE jovem_id = p_jovem_id
      AND usuario_id = current_user_id
      AND tipo_aprovacao IN ('pre_aprovado', 'observar', 'sem_condicao')
      AND tipo_aprovacao <> p_tipo_aprovacao;
  END IF;

  INSERT INTO public.aprovacoes_jovens (jovem_id, usuario_id, tipo_aprovacao, observacao)
  VALUES (p_jovem_id, current_user_id, p_tipo_aprovacao, obs)
  ON CONFLICT (jovem_id, usuario_id, tipo_aprovacao)
  DO UPDATE SET
    observacao = EXCLUDED.observacao,
    atualizado_em = now();

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
      'observacao', obs
    )
  );

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

COMMENT ON FUNCTION public.aprovar_jovem_multiplo IS 'v4.0.0 - Aprovações com ponto de vista (OK/Observar/Sem condição) e observação até 144 caracteres';
