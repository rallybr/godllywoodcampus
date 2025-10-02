-- CORRIGIR CAMPOS GEOGRÁFICOS NO MODAL DE EDITAR USUÁRIO
-- Este script atualiza a RPC para incluir os campos geográficos

-- 1. Atualizar a RPC atualizar_usuario_admin para incluir campos geográficos
CREATE OR REPLACE FUNCTION public.atualizar_usuario_admin(
  p_usuario_id uuid,
  p_nome text,
  p_email text,
  p_sexo text DEFAULT NULL,
  p_foto text DEFAULT NULL,
  p_nivel text DEFAULT NULL,
  p_ativo boolean DEFAULT NULL,
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
  target_user record;
  can_edit boolean := false;
BEGIN
  current_user_id := auth.uid();
  IF current_user_id IS NULL THEN
    RETURN jsonb_build_object('success', false, 'error', 'Usuário não autenticado.');
  END IF;

  -- Obter informações do usuário atual
  SELECT id, nivel INTO user_role_info FROM public.usuarios WHERE id_auth = current_user_id;
  IF user_role_info.id IS NULL THEN
    RETURN jsonb_build_object('success', false, 'error', 'Perfil de usuário não encontrado.');
  END IF;

  -- Obter informações do usuário alvo
  SELECT id, nivel, nome, email INTO target_user FROM public.usuarios WHERE id = p_usuario_id;
  IF target_user.id IS NULL THEN
    RETURN jsonb_build_object('success', false, 'error', 'Usuário não encontrado.');
  END IF;

  -- Verificar permissões
  -- Administradores podem editar qualquer usuário
  -- Usuários comuns podem editar apenas seu próprio perfil
  IF user_role_info.nivel = 'administrador' THEN
    can_edit := true;
  ELSIF user_role_info.id = p_usuario_id THEN
    can_edit := true;
  END IF;

  IF NOT can_edit THEN
    RETURN jsonb_build_object('success', false, 'error', 'Você não tem permissão para editar este usuário.');
  END IF;

  -- Verificar se o email já existe em outro usuário
  IF p_email IS NOT NULL AND p_email != target_user.email THEN
    IF EXISTS (SELECT 1 FROM public.usuarios WHERE email = p_email AND id != p_usuario_id) THEN
      RETURN jsonb_build_object('success', false, 'error', 'Este email já está sendo usado por outro usuário.');
    END IF;
  END IF;

  -- Preparar dados para atualização
  DECLARE
    update_data jsonb := '{}';
  BEGIN
    IF p_nome IS NOT NULL THEN
      update_data := update_data || jsonb_build_object('nome', p_nome);
    END IF;
    
    IF p_email IS NOT NULL THEN
      update_data := update_data || jsonb_build_object('email', p_email);
    END IF;
    
    IF p_sexo IS NOT NULL THEN
      update_data := update_data || jsonb_build_object('sexo', p_sexo);
    END IF;
    
    IF p_foto IS NOT NULL THEN
      update_data := update_data || jsonb_build_object('foto', p_foto);
    END IF;
    
    -- Campos geográficos (sempre permitidos)
    IF p_estado_id IS NOT NULL THEN
      update_data := update_data || jsonb_build_object('estado_id', p_estado_id);
    END IF;
    
    IF p_bloco_id IS NOT NULL THEN
      update_data := update_data || jsonb_build_object('bloco_id', p_bloco_id);
    END IF;
    
    IF p_regiao_id IS NOT NULL THEN
      update_data := update_data || jsonb_build_object('regiao_id', p_regiao_id);
    END IF;
    
    IF p_igreja_id IS NOT NULL THEN
      update_data := update_data || jsonb_build_object('igreja_id', p_igreja_id);
    END IF;
    
    -- Apenas administradores podem alterar nível e status
    IF user_role_info.nivel = 'administrador' THEN
      IF p_nivel IS NOT NULL THEN
        update_data := update_data || jsonb_build_object('nivel', p_nivel);
      END IF;
      
      IF p_ativo IS NOT NULL THEN
        update_data := update_data || jsonb_build_object('ativo', p_ativo);
      END IF;
    END IF;

    -- Atualizar usuário
    UPDATE public.usuarios
    SET 
      nome = COALESCE((update_data->>'nome')::text, nome),
      email = COALESCE((update_data->>'email')::text, email),
      sexo = COALESCE((update_data->>'sexo')::text, sexo),
      foto = COALESCE((update_data->>'foto')::text, foto),
      estado_id = COALESCE((update_data->>'estado_id')::uuid, estado_id),
      bloco_id = COALESCE((update_data->>'bloco_id')::uuid, bloco_id),
      regiao_id = COALESCE((update_data->>'regiao_id')::uuid, regiao_id),
      igreja_id = COALESCE((update_data->>'igreja_id')::uuid, igreja_id),
      nivel = CASE 
        WHEN user_role_info.nivel = 'administrador' AND (update_data->>'nivel') IS NOT NULL 
        THEN (update_data->>'nivel')::text 
        ELSE nivel 
      END,
      ativo = CASE 
        WHEN user_role_info.nivel = 'administrador' AND (update_data->>'ativo') IS NOT NULL 
        THEN (update_data->>'ativo')::boolean 
        ELSE ativo 
      END
    WHERE id = p_usuario_id;

    -- Criar log de auditoria
    INSERT INTO public.logs_auditoria (usuario_id, acao, detalhe, dados_novos)
    VALUES (
      user_role_info.id, 
      'edicao_usuario', 
      'Usuário ' || target_user.nome || ' editado por ' || user_role_info.nivel, 
      jsonb_build_object(
        'usuario_editado_id', p_usuario_id,
        'usuario_editado_nome', target_user.nome,
        'alteracoes', update_data
      )
    );

    RETURN jsonb_build_object(
      'success', true, 
      'message', 'Usuário atualizado com sucesso.',
      'usuario_id', p_usuario_id
    );

  EXCEPTION
    WHEN unique_violation THEN
      RETURN jsonb_build_object('success', false, 'error', 'Email já está sendo usado por outro usuário.');
    WHEN OTHERS THEN
      RETURN jsonb_build_object('success', false, 'error', SQLERRM);
  END;
END;
$$;

-- 2. Verificar se a função foi atualizada corretamente
SELECT 
    'Função atualizada com sucesso!' as status,
    proname as function_name,
    pronargs as parameter_count
FROM pg_proc 
WHERE proname = 'atualizar_usuario_admin';

-- 3. Testar a função com dados de exemplo (comentado para não executar)
/*
SELECT public.atualizar_usuario_admin(
  'uuid-do-usuario',
  'Novo Nome',
  'novo@email.com',
  'masculino',
  'https://nova-foto-url.com',
  'colaborador',
  true,
  'uuid-do-estado',
  'uuid-do-bloco',
  'uuid-da-regiao',
  'uuid-da-igreja'
);
*/
