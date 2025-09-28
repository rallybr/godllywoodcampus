-- Função para buscar papéis disponíveis
CREATE OR REPLACE FUNCTION public.buscar_papeis_disponiveis()
RETURNS TABLE (
  id uuid,
  nome text,
  slug text,
  nivel_hierarquico integer,
  descricao text
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  RETURN QUERY
  SELECT 
    r.id,
    r.nome,
    r.slug,
    r.nivel_hierarquico,
    r.descricao
  FROM public.roles r
  ORDER BY r.nivel_hierarquico ASC, r.nome ASC;
END;
$$;

-- Função para buscar papéis de um usuário específico
CREATE OR REPLACE FUNCTION public.buscar_papeis_usuario(p_usuario_id uuid)
RETURNS TABLE (
  id uuid,
  role_id uuid,
  role_nome text,
  role_slug text,
  nivel_hierarquico integer,
  ativo boolean,
  estado_id uuid,
  bloco_id uuid,
  regiao_id uuid,
  igreja_id uuid
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  RETURN QUERY
  SELECT 
    ur.id,
    ur.role_id,
    r.nome as role_nome,
    r.slug as role_slug,
    r.nivel_hierarquico,
    ur.ativo,
    ur.estado_id,
    ur.bloco_id,
    ur.regiao_id,
    ur.igreja_id
  FROM public.user_roles ur
  JOIN public.roles r ON r.id = ur.role_id
  WHERE ur.user_id = p_usuario_id
  ORDER BY r.nivel_hierarquico ASC;
END;
$$;

-- Função para atribuir papel a usuário
CREATE OR REPLACE FUNCTION public.atribuir_papel_usuario(
  p_usuario_id uuid,
  p_role_id uuid,
  p_estado_id uuid DEFAULT NULL,
  p_bloco_id uuid DEFAULT NULL,
  p_regiao_id uuid DEFAULT NULL,
  p_igreja_id uuid DEFAULT NULL
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  current_user_id uuid;
  user_role_info record;
  role_info record;
  papel_id uuid;
BEGIN
  current_user_id := auth.uid();
  IF current_user_id IS NULL THEN
    RETURN jsonb_build_object('success', false, 'error', 'Usuário não autenticado.');
  END IF;

  -- Verificar se o usuário atual é administrador
  SELECT id, nivel INTO user_role_info FROM public.usuarios WHERE id_auth = current_user_id;
  IF user_role_info.id IS NULL THEN
    RETURN jsonb_build_object('success', false, 'error', 'Perfil de usuário não encontrado.');
  END IF;

  IF user_role_info.nivel != 'administrador' THEN
    RETURN jsonb_build_object('success', false, 'error', 'Apenas administradores podem atribuir papéis.');
  END IF;

  -- Verificar se o papel existe
  SELECT id, nome, slug INTO role_info FROM public.roles WHERE id = p_role_id;
  IF role_info.id IS NULL THEN
    RETURN jsonb_build_object('success', false, 'error', 'Papel não encontrado.');
  END IF;

  -- Verificar se o usuário já tem este papel
  IF EXISTS (SELECT 1 FROM public.user_roles WHERE user_id = p_usuario_id AND role_id = p_role_id) THEN
    RETURN jsonb_build_object('success', false, 'error', 'Usuário já possui este papel.');
  END IF;

  -- Atribuir papel
  papel_id := uuid_generate_v4();
  INSERT INTO public.user_roles (
    id,
    user_id,
    role_id,
    estado_id,
    bloco_id,
    regiao_id,
    igreja_id,
    ativo,
    criado_em
  ) VALUES (
    papel_id,
    p_usuario_id,
    p_role_id,
    p_estado_id,
    p_bloco_id,
    p_regiao_id,
    p_igreja_id,
    true,
    NOW()
  );

  -- Log de auditoria
  INSERT INTO public.logs_auditoria (usuario_id, acao, detalhe, dados_novos)
  VALUES (
    user_role_info.id,
    'atribuicao_papel',
    'Papel ' || role_info.nome || ' atribuído ao usuário',
    jsonb_build_object(
      'usuario_id', p_usuario_id,
      'role_id', p_role_id,
      'role_nome', role_info.nome,
      'papel_id', papel_id
    )
  );

  RETURN jsonb_build_object(
    'success', true,
    'message', 'Papel atribuído com sucesso.',
    'papel_id', papel_id
  );

EXCEPTION
  WHEN OTHERS THEN
    RETURN jsonb_build_object('success', false, 'error', SQLERRM);
END;
$$;

-- Função para remover papel de usuário
CREATE OR REPLACE FUNCTION public.remover_papel_usuario(p_papel_id uuid)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  current_user_id uuid;
  user_role_info record;
  papel_info record;
BEGIN
  current_user_id := auth.uid();
  IF current_user_id IS NULL THEN
    RETURN jsonb_build_object('success', false, 'error', 'Usuário não autenticado.');
  END IF;

  -- Verificar se o usuário atual é administrador
  SELECT id, nivel INTO user_role_info FROM public.usuarios WHERE id_auth = current_user_id;
  IF user_role_info.id IS NULL THEN
    RETURN jsonb_build_object('success', false, 'error', 'Perfil de usuário não encontrado.');
  END IF;

  IF user_role_info.nivel != 'administrador' THEN
    RETURN jsonb_build_object('success', false, 'error', 'Apenas administradores podem remover papéis.');
  END IF;

  -- Obter informações do papel
  SELECT ur.id, ur.user_id, r.nome as role_nome, r.slug as role_slug
  INTO papel_info
  FROM public.user_roles ur
  JOIN public.roles r ON r.id = ur.role_id
  WHERE ur.id = p_papel_id;

  IF papel_info.id IS NULL THEN
    RETURN jsonb_build_object('success', false, 'error', 'Papel não encontrado.');
  END IF;

  -- Remover papel
  DELETE FROM public.user_roles WHERE id = p_papel_id;

  -- Log de auditoria
  INSERT INTO public.logs_auditoria (usuario_id, acao, detalhe, dados_novos)
  VALUES (
    user_role_info.id,
    'remocao_papel',
    'Papel ' || papel_info.role_nome || ' removido do usuário',
    jsonb_build_object(
      'papel_id', p_papel_id,
      'usuario_id', papel_info.user_id,
      'role_nome', papel_info.role_nome
    )
  );

  RETURN jsonb_build_object(
    'success', true,
    'message', 'Papel removido com sucesso.'
  );

EXCEPTION
  WHEN OTHERS THEN
    RETURN jsonb_build_object('success', false, 'error', SQLERRM);
END;
$$;
