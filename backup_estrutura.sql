


SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;


CREATE SCHEMA IF NOT EXISTS "auth";


ALTER SCHEMA "auth" OWNER TO "supabase_admin";


CREATE SCHEMA IF NOT EXISTS "public";


ALTER SCHEMA "public" OWNER TO "pg_database_owner";


COMMENT ON SCHEMA "public" IS 'standard public schema';



CREATE SCHEMA IF NOT EXISTS "storage";


ALTER SCHEMA "storage" OWNER TO "supabase_admin";


CREATE TYPE "auth"."aal_level" AS ENUM (
    'aal1',
    'aal2',
    'aal3'
);


ALTER TYPE "auth"."aal_level" OWNER TO "supabase_auth_admin";


CREATE TYPE "auth"."code_challenge_method" AS ENUM (
    's256',
    'plain'
);


ALTER TYPE "auth"."code_challenge_method" OWNER TO "supabase_auth_admin";


CREATE TYPE "auth"."factor_status" AS ENUM (
    'unverified',
    'verified'
);


ALTER TYPE "auth"."factor_status" OWNER TO "supabase_auth_admin";


CREATE TYPE "auth"."factor_type" AS ENUM (
    'totp',
    'webauthn',
    'phone'
);


ALTER TYPE "auth"."factor_type" OWNER TO "supabase_auth_admin";


CREATE TYPE "auth"."oauth_authorization_status" AS ENUM (
    'pending',
    'approved',
    'denied',
    'expired'
);


ALTER TYPE "auth"."oauth_authorization_status" OWNER TO "supabase_auth_admin";


CREATE TYPE "auth"."oauth_client_type" AS ENUM (
    'public',
    'confidential'
);


ALTER TYPE "auth"."oauth_client_type" OWNER TO "supabase_auth_admin";


CREATE TYPE "auth"."oauth_registration_type" AS ENUM (
    'dynamic',
    'manual'
);


ALTER TYPE "auth"."oauth_registration_type" OWNER TO "supabase_auth_admin";


CREATE TYPE "auth"."oauth_response_type" AS ENUM (
    'code'
);


ALTER TYPE "auth"."oauth_response_type" OWNER TO "supabase_auth_admin";


CREATE TYPE "auth"."one_time_token_type" AS ENUM (
    'confirmation_token',
    'reauthentication_token',
    'recovery_token',
    'email_change_token_new',
    'email_change_token_current',
    'phone_change_token'
);


ALTER TYPE "auth"."one_time_token_type" OWNER TO "supabase_auth_admin";


CREATE TYPE "public"."intellimen_aprovado_enum" AS ENUM (
    'null',
    'pre_aprovado',
    'aprovado'
);


ALTER TYPE "public"."intellimen_aprovado_enum" OWNER TO "postgres";


CREATE TYPE "public"."intellimen_caractere_enum" AS ENUM (
    'excelente',
    'bom',
    'ser_observar',
    'ruim'
);


ALTER TYPE "public"."intellimen_caractere_enum" OWNER TO "postgres";


CREATE TYPE "public"."intellimen_disposicao_enum" AS ENUM (
    'muito_disposto',
    'normal',
    'pacato',
    'desanimado'
);


ALTER TYPE "public"."intellimen_disposicao_enum" OWNER TO "postgres";


CREATE TYPE "public"."intellimen_espirito_enum" AS ENUM (
    'ruim',
    'ser_observar',
    'bom',
    'excelente'
);


ALTER TYPE "public"."intellimen_espirito_enum" OWNER TO "postgres";


CREATE TYPE "storage"."buckettype" AS ENUM (
    'STANDARD',
    'ANALYTICS',
    'VECTOR'
);


ALTER TYPE "storage"."buckettype" OWNER TO "supabase_storage_admin";


CREATE OR REPLACE FUNCTION "auth"."email"() RETURNS "text"
    LANGUAGE "sql" STABLE
    AS $$
  select 
  coalesce(
    nullif(current_setting('request.jwt.claim.email', true), ''),
    (nullif(current_setting('request.jwt.claims', true), '')::jsonb ->> 'email')
  )::text
$$;


ALTER FUNCTION "auth"."email"() OWNER TO "supabase_auth_admin";


COMMENT ON FUNCTION "auth"."email"() IS 'Deprecated. Use auth.jwt() -> ''email'' instead.';



CREATE OR REPLACE FUNCTION "auth"."jwt"() RETURNS "jsonb"
    LANGUAGE "sql" STABLE
    AS $$
  select 
    coalesce(
        nullif(current_setting('request.jwt.claim', true), ''),
        nullif(current_setting('request.jwt.claims', true), '')
    )::jsonb
$$;


ALTER FUNCTION "auth"."jwt"() OWNER TO "supabase_auth_admin";


CREATE OR REPLACE FUNCTION "auth"."role"() RETURNS "text"
    LANGUAGE "sql" STABLE
    AS $$
  select 
  coalesce(
    nullif(current_setting('request.jwt.claim.role', true), ''),
    (nullif(current_setting('request.jwt.claims', true), '')::jsonb ->> 'role')
  )::text
$$;


ALTER FUNCTION "auth"."role"() OWNER TO "supabase_auth_admin";


COMMENT ON FUNCTION "auth"."role"() IS 'Deprecated. Use auth.jwt() -> ''role'' instead.';



CREATE OR REPLACE FUNCTION "auth"."uid"() RETURNS "uuid"
    LANGUAGE "sql" STABLE
    AS $$
  select 
  coalesce(
    nullif(current_setting('request.jwt.claim.sub', true), ''),
    (nullif(current_setting('request.jwt.claims', true), '')::jsonb ->> 'sub')
  )::uuid
$$;


ALTER FUNCTION "auth"."uid"() OWNER TO "supabase_auth_admin";


COMMENT ON FUNCTION "auth"."uid"() IS 'Deprecated. Use auth.jwt() -> ''sub'' instead.';



CREATE OR REPLACE FUNCTION "public"."aprovar_jovem_multiplo"("p_jovem_id" "uuid", "p_tipo_aprovacao" "text", "p_observacao" "text" DEFAULT NULL::"text") RETURNS "jsonb"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
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
$$;


ALTER FUNCTION "public"."aprovar_jovem_multiplo"("p_jovem_id" "uuid", "p_tipo_aprovacao" "text", "p_observacao" "text") OWNER TO "postgres";


COMMENT ON FUNCTION "public"."aprovar_jovem_multiplo"("p_jovem_id" "uuid", "p_tipo_aprovacao" "text", "p_observacao" "text") IS 'v3.0.0 - Aprovações múltiplas com suporte a associações (SEM AMBIGUIDADE)';



CREATE OR REPLACE FUNCTION "public"."atribuir_papel_padrao_jovem"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
DECLARE
  v_role_id uuid;
  v_has_role boolean;
BEGIN
  -- Pega o id do papel 'jovem'
  SELECT id INTO v_role_id
  FROM public.roles
  WHERE slug = 'jovem'
  LIMIT 1;

  -- Se por algum motivo não existir, apenas retorna
  IF v_role_id IS NULL THEN
    RETURN NEW;
  END IF;

  -- Verifica se já existe algum papel atribuído
  SELECT EXISTS (
    SELECT 1
    FROM public.user_roles
    WHERE user_id = NEW.id
  ) INTO v_has_role;

  -- Se não tem papel, atribui 'jovem' como padrão
  IF NOT v_has_role THEN
    INSERT INTO public.user_roles (id, user_id, role_id, criado_em)
    VALUES (uuid_generate_v4(), NEW.id, v_role_id, timezone('utc', now()));
  END IF;

  RETURN NEW;
END;
$$;


ALTER FUNCTION "public"."atribuir_papel_padrao_jovem"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."atribuir_papel_usuario"("p_usuario_id" "uuid", "p_role_id" "uuid", "p_estado_id" "uuid" DEFAULT NULL::"uuid", "p_bloco_id" "uuid" DEFAULT NULL::"uuid", "p_regiao_id" "uuid" DEFAULT NULL::"uuid", "p_igreja_id" "uuid" DEFAULT NULL::"uuid") RETURNS "jsonb"
    LANGUAGE "plpgsql" SECURITY DEFINER
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
    regiao_id,  -- ✅ CORRIGIDO: era p_regiao_id
    igreja_id,
    ativo,
    criado_em
  ) VALUES (
    papel_id,
    p_usuario_id,
    p_role_id,
    p_estado_id,
    p_bloco_id,
    p_regiao_id,  -- ✅ CORRIGIDO: era p_regiao_id
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


ALTER FUNCTION "public"."atribuir_papel_usuario"("p_usuario_id" "uuid", "p_role_id" "uuid", "p_estado_id" "uuid", "p_bloco_id" "uuid", "p_regiao_id" "uuid", "p_igreja_id" "uuid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."atualizar_namorados_updated_at"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    AS $$
BEGIN
  NEW.atualizado_em = now();
  RETURN NEW;
END;
$$;


ALTER FUNCTION "public"."atualizar_namorados_updated_at"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."atualizar_status_jovem"("p_jovem_id" "uuid") RETURNS "void"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
DECLARE
  aprovacoes_count integer;
  tem_aprovado boolean := false;
  tem_pre_aprovado boolean := false;
  status_final intellimen_aprovado_enum; -- ✅ USAR O TIPO ENUM CORRETO
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
    -- ✅ USAR CAST PARA O TIPO ENUM CORRETO
    IF tem_aprovado THEN
      status_final := 'aprovado'::intellimen_aprovado_enum;
    ELSIF tem_pre_aprovado THEN
      status_final := 'pre_aprovado'::intellimen_aprovado_enum;
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


ALTER FUNCTION "public"."atualizar_status_jovem"("p_jovem_id" "uuid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."atualizar_timestamp"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    AS $$
begin 
  new.atualizado_em = now(); 
  return new; 
end $$;


ALTER FUNCTION "public"."atualizar_timestamp"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."atualizar_timestamp_aprovacoes"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    AS $$
BEGIN
  NEW.atualizado_em = now();
  RETURN NEW;
END;
$$;


ALTER FUNCTION "public"."atualizar_timestamp_aprovacoes"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."atualizar_usuario_admin"("p_usuario_id" "uuid", "p_nome" "text", "p_email" "text", "p_sexo" "text" DEFAULT NULL::"text", "p_foto" "text" DEFAULT NULL::"text", "p_nivel" "text" DEFAULT NULL::"text", "p_ativo" boolean DEFAULT NULL::boolean) RETURNS "jsonb"
    LANGUAGE "plpgsql" SECURITY DEFINER
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


ALTER FUNCTION "public"."atualizar_usuario_admin"("p_usuario_id" "uuid", "p_nome" "text", "p_email" "text", "p_sexo" "text", "p_foto" "text", "p_nivel" "text", "p_ativo" boolean) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."buscar_aprovacoes_jovem"("p_jovem_id" "uuid") RETURNS TABLE("id" "uuid", "usuario_id" "uuid", "usuario_nome" "text", "usuario_nivel" "text", "usuario_estado_bandeira" "text", "tipo_aprovacao" "text", "observacao" "text", "criado_em" timestamp with time zone)
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
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
$$;


ALTER FUNCTION "public"."buscar_aprovacoes_jovem"("p_jovem_id" "uuid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."buscar_papeis_disponiveis"() RETURNS TABLE("id" "uuid", "nome" "text", "slug" "text", "nivel_hierarquico" integer, "descricao" "text")
    LANGUAGE "plpgsql" SECURITY DEFINER
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


ALTER FUNCTION "public"."buscar_papeis_disponiveis"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."buscar_papeis_usuario"("p_usuario_id" "uuid") RETURNS TABLE("id" "uuid", "role_id" "uuid", "role_nome" "text", "role_slug" "text", "nivel_hierarquico" integer, "ativo" boolean, "estado_id" "uuid", "bloco_id" "uuid", "regiao_id" "uuid", "igreja_id" "uuid")
    LANGUAGE "plpgsql" SECURITY DEFINER
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


ALTER FUNCTION "public"."buscar_papeis_usuario"("p_usuario_id" "uuid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."buscar_usuarios_com_ultimo_acesso"() RETURNS TABLE("id" "uuid", "nome" "text", "email" "text", "nivel" "text", "ativo" boolean, "foto" "text", "sexo" "text", "criado_em" timestamp with time zone, "estado_id" "uuid", "bloco_id" "uuid", "regiao_id" "uuid", "igreja_id" "uuid", "estado_bandeira" "text", "ultimo_acesso" timestamp with time zone, "dias_sem_acesso" integer, "status_acesso" "text")
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
BEGIN
  RETURN QUERY
  SELECT 
    u.id,
    u.nome,
    u.email,
    u.nivel,
    u.ativo,
    u.foto,
    u.sexo,
    u.criado_em,
    u.estado_id,
    u.bloco_id,
    u.regiao_id,
    u.igreja_id,
    u.estado_bandeira,
    u.ultimo_acesso,
    CASE 
      WHEN u.ultimo_acesso IS NULL THEN NULL
      ELSE EXTRACT(DAY FROM (NOW() - u.ultimo_acesso))::INTEGER
    END as dias_sem_acesso,
    CASE 
      WHEN u.ultimo_acesso IS NULL THEN 'Nunca acessou'
      WHEN u.ultimo_acesso > NOW() - INTERVAL '1 day' THEN 'Ativo (últimas 24h)'
      WHEN u.ultimo_acesso > NOW() - INTERVAL '7 days' THEN 'Ativo (última semana)'
      WHEN u.ultimo_acesso > NOW() - INTERVAL '30 days' THEN 'Inativo (último mês)'
      ELSE 'Muito inativo'
    END as status_acesso
  FROM public.usuarios u
  ORDER BY u.ultimo_acesso DESC NULLS LAST;
END;
$$;


ALTER FUNCTION "public"."buscar_usuarios_com_ultimo_acesso"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."can_access_jovem"("jovem_estado_id" "uuid", "jovem_bloco_id" "uuid", "jovem_regiao_id" "uuid", "jovem_igreja_id" "uuid", "p_jovem_id" "uuid" DEFAULT NULL::"uuid") RETURNS boolean
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
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
$$;


ALTER FUNCTION "public"."can_access_jovem"("jovem_estado_id" "uuid", "jovem_bloco_id" "uuid", "jovem_regiao_id" "uuid", "jovem_igreja_id" "uuid", "p_jovem_id" "uuid") OWNER TO "postgres";


COMMENT ON FUNCTION "public"."can_access_jovem"("jovem_estado_id" "uuid", "jovem_bloco_id" "uuid", "jovem_regiao_id" "uuid", "jovem_igreja_id" "uuid", "p_jovem_id" "uuid") IS 'v3.0.0 - Verificação de acesso com suporte a associações (SEM AMBIGUIDADE)';



CREATE OR REPLACE FUNCTION "public"."can_access_jovem_com_associacoes"("jovem_estado_id" "uuid", "jovem_bloco_id" "uuid", "jovem_regiao_id" "uuid", "jovem_igreja_id" "uuid", "jovem_id" "uuid" DEFAULT NULL::"uuid") RETURNS boolean
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
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
        WHERE jovens_usuarios_associacoes.jovem_id = jovem_id AND jovens_usuarios_associacoes.usuario_id = current_user_id
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
        WHERE jovens_usuarios_associacoes.jovem_id = jovem_id AND jovens_usuarios_associacoes.usuario_id = current_user_id
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
        WHERE jovens_usuarios_associacoes.jovem_id = jovem_id AND jovens_usuarios_associacoes.usuario_id = current_user_id
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
        WHERE jovens_usuarios_associacoes.jovem_id = jovem_id AND jovens_usuarios_associacoes.usuario_id = current_user_id
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
$$;


ALTER FUNCTION "public"."can_access_jovem_com_associacoes"("jovem_estado_id" "uuid", "jovem_bloco_id" "uuid", "jovem_regiao_id" "uuid", "jovem_igreja_id" "uuid", "jovem_id" "uuid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."can_access_viagem_by_level"("jovem_estado_id" "uuid", "jovem_bloco_id" "uuid", "jovem_regiao_id" "uuid", "jovem_igreja_id" "uuid") RETURNS boolean
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
DECLARE
  current_user_id uuid;
  user_info record;
BEGIN
  current_user_id := (SELECT id FROM public.usuarios WHERE id_auth = auth.uid());
  IF current_user_id IS NULL THEN RETURN false; END IF;

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

  IF user_info IS NULL THEN RETURN false; END IF;

  -- 1. ADMINISTRADOR - Acesso total
  IF user_info.nivel = 'administrador' THEN RETURN true; END IF;

  -- 2. LÍDERES NACIONAIS - Acesso total (visão nacional)
  IF user_info.nivel IN ('lider_nacional_iurd', 'lider_nacional_fju') THEN RETURN true; END IF;

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

  -- 7. COLABORADOR - Acesso APENAS aos dados de viagem dos jovens que cadastrou (SEM verificar localização)
  IF user_info.nivel = 'colaborador' THEN
    RETURN EXISTS (
      SELECT 1 FROM public.jovens j
      WHERE j.usuario_id = current_user_id
        AND j.estado_id = jovem_estado_id
        AND j.bloco_id = jovem_bloco_id
        AND j.regiao_id = jovem_regiao_id
        AND j.igreja_id = jovem_igreja_id
    );
  END IF;

  -- 8. JOVEM - Acesso APENAS aos seus próprios dados de viagem
  IF user_info.nivel = 'jovem' THEN
    RETURN EXISTS (
      SELECT 1 FROM public.jovens j
      WHERE j.usuario_id = current_user_id
        AND j.estado_id = jovem_estado_id
        AND j.bloco_id = jovem_bloco_id
        AND j.regiao_id = jovem_regiao_id
        AND j.igreja_id = jovem_igreja_id
    );
  END IF;

  RETURN false;
END;
$$;


ALTER FUNCTION "public"."can_access_viagem_by_level"("jovem_estado_id" "uuid", "jovem_bloco_id" "uuid", "jovem_regiao_id" "uuid", "jovem_igreja_id" "uuid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."criar_lembretes_avaliacao"() RETURNS "void"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
DECLARE
  jovem_record record;
  avaliador_record record;
BEGIN
  -- Buscar jovens sem avaliação há mais de 7 dias
  FOR jovem_record IN
    SELECT j.id, j.nome_completo, j.estado_id, j.bloco_id, j.regiao_id, j.igreja_id
    FROM jovens j
    WHERE j.aprovado IS NULL
    AND j.data_cadastro < NOW() - INTERVAL '7 days'
    AND NOT EXISTS (
      SELECT 1 FROM avaliacoes a WHERE a.jovem_id = j.id
    )
  LOOP
    -- Buscar avaliadores (líderes) para este jovem
    FOR avaliador_record IN
      SELECT user_id FROM obter_lideres_para_notificacao(
        jovem_record.estado_id,
        jovem_record.bloco_id,
        jovem_record.regiao_id,
        jovem_record.igreja_id
      )
    LOOP
      -- Verificar se já existe lembrete recente (últimos 3 dias)
      IF NOT EXISTS (
        SELECT 1 FROM notificacoes n
        WHERE n.destinatario_id = avaliador_record.user_id
        AND n.jovem_id = jovem_record.id
        AND n.tipo = 'lembrete_avaliacao'
        AND n.criado_em > NOW() - INTERVAL '3 days'
      ) THEN
        -- Criar lembrete
        INSERT INTO notificacoes (
          destinatario_id,
          tipo,
          titulo,
          mensagem,
          jovem_id,
          acao_url,
          lida
        ) VALUES (
          avaliador_record.user_id,
          'lembrete_avaliacao',
          'Lembrete de Avaliação',
          'Não esqueça de avaliar ' || jovem_record.nome_completo,
          jovem_record.id,
          '/jovens/' || jovem_record.id,
          false
        );
      END IF;
    END LOOP;
  END LOOP;
END;
$$;


ALTER FUNCTION "public"."criar_lembretes_avaliacao"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."criar_log_auditoria"("p_usuario_id" "uuid", "p_acao" character varying, "p_detalhe" "text", "p_dados_antigos" "jsonb" DEFAULT NULL::"jsonb", "p_dados_novos" "jsonb" DEFAULT NULL::"jsonb") RETURNS "uuid"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
DECLARE
  log_id UUID;
BEGIN
  INSERT INTO logs_auditoria (
    usuario_id,
    acao,
    detalhe,
    dados_antigos,
    dados_novos,
    ip_address,
    user_agent
  ) VALUES (
    p_usuario_id,
    p_acao,
    p_detalhe,
    p_dados_antigos,
    p_dados_novos,
    inet_client_addr(),
    current_setting('request.headers', true)::json->>'user-agent'
  ) RETURNING id INTO log_id;
  
  RETURN log_id;
END;
$$;


ALTER FUNCTION "public"."criar_log_auditoria"("p_usuario_id" "uuid", "p_acao" character varying, "p_detalhe" "text", "p_dados_antigos" "jsonb", "p_dados_novos" "jsonb") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."criar_notificacao_automatica"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    AS $$
BEGIN
  -- Notificar sobre novo jovem cadastrado
  IF TG_OP = 'INSERT' AND TG_TABLE_NAME = 'jovens' THEN
    INSERT INTO notificacoes (tipo, titulo, mensagem, destinatario_id, jovem_id, acao_url)
    SELECT 
      'cadastro',
      'Novo Jovem Cadastrado',
      'Um novo jovem foi cadastrado no sistema',
      u.id,
      NEW.id,
      '/jovens/' || NEW.id
    FROM usuarios u
    JOIN user_roles ur ON ur.user_id = u.id
    JOIN roles r ON r.id = ur.role_id
    WHERE ur.ativo = true
    AND r.slug IN ('administrador', 'colaborador');
  END IF;
  
  -- Notificar sobre nova avaliação
  IF TG_OP = 'INSERT' AND TG_TABLE_NAME = 'avaliacoes' THEN
    INSERT INTO notificacoes (tipo, titulo, mensagem, destinatario_id, jovem_id, acao_url)
    SELECT 
      'avaliacao',
      'Nova Avaliação',
      'Um jovem recebeu uma nova avaliação',
      u.id,
      NEW.jovem_id,
      '/jovens/' || NEW.jovem_id
    FROM usuarios u
    JOIN user_roles ur ON ur.user_id = u.id
    JOIN roles r ON r.id = ur.role_id
    WHERE ur.ativo = true
    AND r.slug IN ('administrador', 'colaborador');
  END IF;
  
  RETURN COALESCE(NEW, OLD);
END;
$$;


ALTER FUNCTION "public"."criar_notificacao_automatica"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."estatisticas_acesso_usuarios"() RETURNS "jsonb"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
DECLARE
  stats jsonb;
BEGIN
  SELECT jsonb_build_object(
    'total_usuarios', (SELECT COUNT(*) FROM public.usuarios),
    'usuarios_ativos_hoje', (
      SELECT COUNT(*) FROM public.usuarios 
      WHERE ultimo_acesso > NOW() - INTERVAL '1 day'
    ),
    'usuarios_ativos_semana', (
      SELECT COUNT(*) FROM public.usuarios 
      WHERE ultimo_acesso > NOW() - INTERVAL '7 days'
    ),
    'usuarios_ativos_mes', (
      SELECT COUNT(*) FROM public.usuarios 
      WHERE ultimo_acesso > NOW() - INTERVAL '30 days'
    ),
    'usuarios_nunca_acessaram', (
      SELECT COUNT(*) FROM public.usuarios 
      WHERE ultimo_acesso IS NULL
    ),
    'usuarios_inativos_30_dias', (
      SELECT COUNT(*) FROM public.usuarios 
      WHERE ultimo_acesso < NOW() - INTERVAL '30 days' OR ultimo_acesso IS NULL
    )
  ) INTO stats;
  
  RETURN stats;
END;
$$;


ALTER FUNCTION "public"."estatisticas_acesso_usuarios"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."filtrar_jovens"("filters" "jsonb") RETURNS TABLE("id" "uuid", "nome_completo" "text", "estado_id" "uuid", "bloco_id" "uuid", "regiao_id" "uuid", "igreja_id" "uuid", "edicao" "text", "idade" integer, "aprovado" "public"."intellimen_aprovado_enum")
    LANGUAGE "sql"
    AS $$
select 
  j.id,
  j.nome_completo,
  j.estado_id,
  j.bloco_id,
  j.regiao_id,
  j.igreja_id,
  j.edicao,
  date_part('year', age(j.data_nasc))::int as idade,
  j.aprovado
from jovens j
where (coalesce(filters->>'estado_id','') = '' or j.estado_id = (filters->>'estado_id')::uuid)
  and (coalesce(filters->>'bloco_id','') = '' or j.bloco_id = (filters->>'bloco_id')::uuid)
  and (coalesce(filters->>'regiao_id','') = '' or j.regiao_id = (filters->>'regiao_id')::uuid)
  and (coalesce(filters->>'igreja_id','') = '' or j.igreja_id = (filters->>'igreja_id')::uuid)
  and (coalesce(filters->>'edicao','') = '' or j.edicao = (filters->>'edicao')::text)
  and (coalesce(filters->>'nome_like','') = '' or lower(j.nome_completo) like '%' || lower((filters->>'nome_like')::text) || '%');
$$;


ALTER FUNCTION "public"."filtrar_jovens"("filters" "jsonb") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."get_jovem_completo"("p_jovem_id" "uuid") RETURNS "jsonb"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
DECLARE
  resultado jsonb;
BEGIN
  SELECT jsonb_build_object(
    'id', j.id,
    'nome_completo', j.nome_completo,
    'idade', j.idade,
    'aprovado', j.aprovado,
    'sexo', j.sexo,
    'whatsapp', j.whatsapp,
    'data_nasc', j.data_nasc,
    'data_cadastro', j.data_cadastro,
    'estado_civil', j.estado_civil,
    'namora', j.namora,
    'tem_filho', j.tem_filho,
    'trabalha', j.trabalha,
    'local_trabalho', j.local_trabalho,
    'escolaridade', j.escolaridade,
    'formacao', j.formacao,
    'tem_dividas', j.tem_dividas,
    'tempo_igreja', j.tempo_igreja,
    'batizado_aguas', j.batizado_aguas,
    'data_batismo_aguas', j.data_batismo_aguas,
    'batizado_es', j.batizado_es,
    'data_batismo_es', j.data_batismo_es,
    'condicao', j.condicao,
    'tempo_condicao', j.tempo_condicao,
    'responsabilidade_igreja', j.responsabilidade_igreja,
    'disposto_servir', j.disposto_servir,
    'ja_obra_altar', j.ja_obra_altar,
    'ja_obreiro', j.ja_obreiro,
    'ja_colaborador', j.ja_colaborador,
    'afastado', j.afastado,
    'data_afastamento', j.data_afastamento,
    'motivo_afastamento', j.motivo_afastamento,
    'data_retorno', j.data_retorno,
    'pais_na_igreja', j.pais_na_igreja,
    'observacao_pais', j.observacao_pais,
    'familiares_igreja', j.familiares_igreja,
    'deseja_altar', j.deseja_altar,
    'observacao', j.observacao,
    'testemunho', j.testemunho,
    'instagram', j.instagram,
    'facebook', j.facebook,
    'tiktok', j.tiktok,
    'obs_redes', j.obs_redes,
    'pastor_que_indicou', j.pastor_que_indicou,
    'cresceu_na_igreja', j.cresceu_na_igreja,
    'experiencia_altar', j.experiencia_altar,
    'foi_obreiro', j.foi_obreiro,
    'foi_colaborador', j.foi_colaborador,
    'afastou', j.afastou,
    'quando_afastou', j.quando_afastou,
    'motivo_afastou', j.motivo_afastou,
    'quando_voltou', j.quando_voltou,
    'pais_sao_igreja', j.pais_sao_igreja,
    'obs_pais', j.obs_pais,
    'observacao_text', j.observacao_text,
    'testemunho_text', j.testemunho_text,
    'edicao', j.edicao,
    'foto', j.foto,
    'observacao_redes', j.observacao_redes,
    'formado_intellimen', j.formado_intellimen,
    'fazendo_desafios', j.fazendo_desafios,
    'qual_desafio', j.qual_desafio,
    'valor_divida', j.valor_divida,
    'usuario_id', j.usuario_id,
    'condicao_campus', j.condicao_campus,
    'estado_id', j.estado_id,
    'bloco_id', j.bloco_id,
    'regiao_id', j.regiao_id,
    'igreja_id', j.igreja_id,
    'edicao_id', j.edicao_id,
    'estado', jsonb_build_object(
      'id', e.id,
      'nome', e.nome,
      'sigla', e.sigla,
      'bandeira', e.bandeira
    ),
    'bloco', jsonb_build_object(
      'id', b.id,
      'nome', b.nome
    ),
    'regiao', jsonb_build_object(
      'id', r.id,
      'nome', r.nome
    ),
    'igreja', jsonb_build_object(
      'id', i.id,
      'nome', i.nome,
      'endereco', i.endereco
    ),
    'namorado', CASE
      WHEN n.id IS NOT NULL THEN jsonb_build_object(
        'id', n.id,
        'nome', n.nome,
        'foto', n.foto,
        'idade', n.idade,
        'tempo_obra', n.tempo_obra,
        'tempo_namoro', n.tempo_namoro,
        'como_se_conheceram', n.como_se_conheceram,
        'quanto_tempo_se_conhece', n.quanto_tempo_se_conhece,
        'onde_esta_atualmente', n.onde_esta_atualmente,
        'atribuicao_atual', n.atribuicao_atual,
        'observacao_namoro', n.observacao_namoro
      )
      ELSE NULL
    END
  ) INTO resultado
  FROM public.jovens j
  LEFT JOIN public.estados e ON e.id = j.estado_id
  LEFT JOIN public.blocos b ON b.id = j.bloco_id
  LEFT JOIN public.regioes r ON r.id = j.regiao_id
  LEFT JOIN public.igrejas i ON i.id = j.igreja_id
  LEFT JOIN public.namorados n ON n.jovem_id = j.id
  WHERE j.id = p_jovem_id;

  RETURN resultado;
END;
$$;


ALTER FUNCTION "public"."get_jovem_completo"("p_jovem_id" "uuid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."get_jovens_por_estado_count"("p_edicao_id" "uuid" DEFAULT NULL::"uuid") RETURNS TABLE("estado_id" "uuid", "total" bigint)
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
DECLARE
  current_user_id uuid;
  user_info record;
BEGIN
  current_user_id := (SELECT id FROM public.usuarios WHERE id_auth = auth.uid());
  IF current_user_id IS NULL THEN 
    RETURN;
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
    RETURN;
  END IF;

  -- 1. ADMINISTRADOR - Acesso total
  IF user_info.nivel = 'administrador' THEN 
    RETURN QUERY
    SELECT 
      j.estado_id,
      COUNT(*) as total
    FROM public.jovens j
    WHERE j.estado_id IS NOT NULL
      AND (p_edicao_id IS NULL OR j.edicao_id = p_edicao_id)
    GROUP BY j.estado_id;
    RETURN;
  END IF;

  -- 2. LÍDERES NACIONAIS - Acesso total (visão nacional)
  IF user_info.nivel IN ('lider_nacional_iurd', 'lider_nacional_fju') THEN 
    RETURN QUERY
    SELECT 
      j.estado_id,
      COUNT(*) as total
    FROM public.jovens j
    WHERE j.estado_id IS NOT NULL
      AND (p_edicao_id IS NULL OR j.edicao_id = p_edicao_id)
    GROUP BY j.estado_id;
    RETURN;
  END IF;

  -- 3. LÍDERES ESTADUAIS - Vê TODO O ESTADO (todos os blocos, regiões, igrejas e jovens do estado)
  IF user_info.nivel IN ('lider_estadual_iurd', 'lider_estadual_fju') THEN
    RETURN QUERY
    SELECT 
      j.estado_id,
      COUNT(*) as total
    FROM public.jovens j
    WHERE j.estado_id = user_info.estado_id
      AND (p_edicao_id IS NULL OR j.edicao_id = p_edicao_id)
    GROUP BY j.estado_id;
    RETURN;
  END IF;

  -- 4. LÍDERES DE BLOCO - Vê TODO O BLOCO (todas as regiões, igrejas e jovens do bloco)
  IF user_info.nivel IN ('lider_bloco_iurd', 'lider_bloco_fju') THEN
    RETURN QUERY
    SELECT 
      j.estado_id,
      COUNT(*) as total
    FROM public.jovens j
    WHERE j.bloco_id = user_info.bloco_id
      AND (p_edicao_id IS NULL OR j.edicao_id = p_edicao_id)
    GROUP BY j.estado_id;
    RETURN;
  END IF;

  -- 5. LÍDER REGIONAL - Vê TODA A REGIÃO (todas as igrejas e jovens da região)
  IF user_info.nivel = 'lider_regional_iurd' THEN
    RETURN QUERY
    SELECT 
      j.estado_id,
      COUNT(*) as total
    FROM public.jovens j
    WHERE j.regiao_id = user_info.regiao_id
      AND (p_edicao_id IS NULL OR j.edicao_id = p_edicao_id)
    GROUP BY j.estado_id;
    RETURN;
  END IF;

  -- 6. LÍDER DE IGREJA - Vê TODA A IGREJA (todos os jovens da igreja)
  IF user_info.nivel = 'lider_igreja_iurd' THEN
    RETURN QUERY
    SELECT 
      j.estado_id,
      COUNT(*) as total
    FROM public.jovens j
    WHERE j.igreja_id = user_info.igreja_id
      AND (p_edicao_id IS NULL OR j.edicao_id = p_edicao_id)
    GROUP BY j.estado_id;
    RETURN;
  END IF;

  -- 7. COLABORADOR - Apenas jovens que cadastrou
  IF user_info.nivel = 'colaborador' THEN
    RETURN QUERY
    SELECT 
      j.estado_id,
      COUNT(*) as total
    FROM public.jovens j
    WHERE j.usuario_id = current_user_id
      AND (p_edicao_id IS NULL OR j.edicao_id = p_edicao_id)
    GROUP BY j.estado_id;
    RETURN;
  END IF;

  -- 8. JOVEM - Apenas seus próprios dados
  IF user_info.nivel = 'jovem' THEN
    RETURN QUERY
    SELECT 
      j.estado_id,
      COUNT(*) as total
    FROM public.jovens j
    WHERE j.usuario_id = current_user_id
      AND (p_edicao_id IS NULL OR j.edicao_id = p_edicao_id)
    GROUP BY j.estado_id;
    RETURN;
  END IF;

  -- Se não for nenhum dos níveis acima, retorna vazio
  RETURN;
END;
$$;


ALTER FUNCTION "public"."get_jovens_por_estado_count"("p_edicao_id" "uuid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."get_user_by_auth_id"("auth_id" "uuid") RETURNS TABLE("id" "uuid", "nome" "text", "id_auth" "uuid")
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
BEGIN
  RETURN QUERY
  SELECT u.id, u.nome, u.id_auth
  FROM usuarios u
  WHERE u.id_auth = auth_id;
END;
$$;


ALTER FUNCTION "public"."get_user_by_auth_id"("auth_id" "uuid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."get_user_hierarchy_level"() RETURNS integer
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
DECLARE
  current_user_id uuid;
  min_level integer;
BEGIN
  current_user_id := (SELECT id FROM public.usuarios WHERE id_auth = auth.uid());
  IF current_user_id IS NULL THEN RETURN 999; END IF;
  
  SELECT MIN(r.nivel_hierarquico) INTO min_level
  FROM public.user_roles ur
  JOIN public.roles r ON r.id = ur.role_id
  WHERE ur.user_id = current_user_id 
    AND ur.ativo = true;
  
  RETURN COALESCE(min_level, 999);
END;
$$;


ALTER FUNCTION "public"."get_user_hierarchy_level"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."get_user_roles"() RETURNS TABLE("role_slug" "text", "nivel_hierarquico" integer, "estado_id" "uuid", "bloco_id" "uuid", "regiao_id" "uuid", "igreja_id" "uuid")
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
DECLARE
  current_user_id uuid;
BEGIN
  current_user_id := (SELECT id FROM public.usuarios WHERE id_auth = auth.uid());
  IF current_user_id IS NULL THEN RETURN; END IF;
  
  RETURN QUERY
  SELECT 
    r.slug,
    r.nivel_hierarquico,
    ur.estado_id,
    ur.bloco_id,
    ur.regiao_id,
    ur.igreja_id
  FROM public.user_roles ur
  JOIN public.roles r ON r.id = ur.role_id
  WHERE ur.user_id = current_user_id 
    AND ur.ativo = true
  ORDER BY r.nivel_hierarquico ASC;
END;
$$;


ALTER FUNCTION "public"."get_user_roles"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."handle_new_auth_user"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
BEGIN
  -- Tentar inserir usuário com tratamento de erro
  BEGIN
    INSERT INTO public.usuarios (
      id_auth,
      email,
      nome,
      nivel,
      ativo,
      criado_em
    )
    VALUES (
      NEW.id,
      NEW.email,
      COALESCE(split_part(NEW.email, '@', 1), 'usuario'),
      'jovem',
      true,
      timezone('utc', now())
    )
    ON CONFLICT (id_auth) DO NOTHING;
    
    -- Se chegou até aqui, inserção foi bem-sucedida
    RETURN NEW;
    
  EXCEPTION
    WHEN OTHERS THEN
      -- Log do erro mas não falha o signup
      INSERT INTO public.logs_auditoria (
        usuario_id,
        acao,
        detalhe,
        dados_novos
      ) VALUES (
        NULL,
        'erro_trigger_signup',
        'Erro ao criar usuário automaticamente: ' || SQLERRM,
        jsonb_build_object(
          'auth_user_id', NEW.id,
          'email', NEW.email,
          'erro', SQLERRM
        )
      );
      
      -- Retornar NEW mesmo com erro para não bloquear o signup
      RETURN NEW;
  END;
END;
$$;


ALTER FUNCTION "public"."handle_new_auth_user"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."has_role"("role_slug" "text") RETURNS boolean
    LANGUAGE "sql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
  SELECT EXISTS (
    SELECT 1
    FROM public.user_roles ur
    JOIN public.roles r ON r.id = ur.role_id
    WHERE ur.user_id = (SELECT id FROM public.usuarios WHERE id_auth = auth.uid())
      AND r.slug = role_slug
  );
$$;


ALTER FUNCTION "public"."has_role"("role_slug" "text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."is_admin_user"() RETURNS boolean
    LANGUAGE "sql" STABLE SECURITY DEFINER
    AS $$
  SELECT EXISTS (
    SELECT 1 FROM user_roles ur
    JOIN roles r ON r.id = ur.role_id
    WHERE ur.user_id = (SELECT id FROM usuarios WHERE id_auth = auth.uid())
    AND r.slug = 'administrador'
    AND ur.ativo = true
  );
$$;


ALTER FUNCTION "public"."is_admin_user"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."limpar_acessos_antigos"("dias_para_manter" integer DEFAULT 365) RETURNS integer
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
DECLARE
  usuarios_afetados INTEGER;
BEGIN
  -- Não vamos deletar usuários, apenas limpar logs de acesso muito antigos
  -- Esta função pode ser usada para limpar logs de auditoria relacionados a acessos
  
  SELECT COUNT(*) INTO usuarios_afetados
  FROM public.usuarios 
  WHERE ultimo_acesso < NOW() - (dias_para_manter || ' days')::INTERVAL;
  
  -- Log da operação
  INSERT INTO public.logs_auditoria (usuario_id, acao, detalhe, dados_novos)
  VALUES (
    (SELECT id FROM public.usuarios WHERE nivel = 'administrador' LIMIT 1),
    'limpeza_acessos_antigos',
    'Limpeza de acessos antigos executada',
    jsonb_build_object('dias_para_manter', dias_para_manter, 'usuarios_afetados', usuarios_afetados)
  );
  
  RETURN usuarios_afetados;
END;
$$;


ALTER FUNCTION "public"."limpar_acessos_antigos"("dias_para_manter" integer) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."limpar_logs_antigos"("dias_retencao" integer DEFAULT 90) RETURNS integer
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
DECLARE
  logs_removidos INTEGER;
BEGIN
  DELETE FROM logs_auditoria 
  WHERE criado_em < NOW() - INTERVAL '1 day' * dias_retencao;
  
  GET DIAGNOSTICS logs_removidos = ROW_COUNT;
  
  RETURN logs_removidos;
END;
$$;


ALTER FUNCTION "public"."limpar_logs_antigos"("dias_retencao" integer) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."limpar_notificacoes_antigas"() RETURNS integer
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
DECLARE
  count_deleted integer;
BEGIN
  DELETE FROM notificacoes
  WHERE criado_em < NOW() - INTERVAL '30 days';
  
  GET DIAGNOSTICS count_deleted = ROW_COUNT;
  RETURN count_deleted;
END;
$$;


ALTER FUNCTION "public"."limpar_notificacoes_antigas"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."namorado_jovem_pertence_ao_usuario"("p_jovem_id" "uuid") RETURNS boolean
    LANGUAGE "sql" STABLE SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
  SELECT EXISTS (
    SELECT 1
    FROM public.jovens j
    INNER JOIN public.usuarios u ON u.id = j.usuario_id AND u.id_auth = auth.uid()
    WHERE j.id = p_jovem_id
  );
$$;


ALTER FUNCTION "public"."namorado_jovem_pertence_ao_usuario"("p_jovem_id" "uuid") OWNER TO "postgres";


COMMENT ON FUNCTION "public"."namorado_jovem_pertence_ao_usuario"("p_jovem_id" "uuid") IS 'True se o jovem pertence ao usuário logado (jovens.usuario_id = usuarios.id onde id_auth = auth.uid())';



CREATE OR REPLACE FUNCTION "public"."notificar_associacao_jovem"("p_jovem_id" "uuid", "p_usuario_associado_id" "uuid", "p_titulo" "text", "p_mensagem" "text", "p_acao_url" "text" DEFAULT NULL::"text") RETURNS integer
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
declare
  v_count integer := 0;
  v_estado uuid;
  v_bloco uuid;
  v_regiao uuid;
  v_igreja uuid;
begin
  select estado_id, bloco_id, regiao_id, igreja_id
  into v_estado, v_bloco, v_regiao, v_igreja
  from jovens
  where id = p_jovem_id;

  insert into notificacoes (destinatario_id, tipo, titulo, mensagem, jovem_id, acao_url, lida, criado_em)
  select user_id, 'sistema', p_titulo, p_mensagem, p_jovem_id,
         coalesce(p_acao_url, '/jovens/' || p_jovem_id::text), false, now()
  from obter_lideres_para_notificacao(v_estado, v_bloco, v_regiao, v_igreja);

  get diagnostics v_count = row_count;

  if p_usuario_associado_id is not null then
    insert into notificacoes (destinatario_id, tipo, titulo, mensagem, jovem_id, acao_url, lida, criado_em)
    values (p_usuario_associado_id, 'sistema', p_titulo, p_mensagem, p_jovem_id,
            coalesce(p_acao_url, '/jovens/' || p_jovem_id::text), false, now());
    v_count := v_count + 1;
  end if;

  return v_count;
end;
$$;


ALTER FUNCTION "public"."notificar_associacao_jovem"("p_jovem_id" "uuid", "p_usuario_associado_id" "uuid", "p_titulo" "text", "p_mensagem" "text", "p_acao_url" "text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."notificar_evento_jovem"("p_jovem_id" "uuid", "p_tipo" "text", "p_titulo" "text", "p_mensagem" "text", "p_remetente_id" "uuid" DEFAULT NULL::"uuid", "p_acao_url" "text" DEFAULT NULL::"text") RETURNS integer
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
declare
  v_count integer := 0;
  v_estado uuid;
  v_bloco uuid;
  v_regiao uuid;
  v_igreja uuid;
begin
  select estado_id, bloco_id, regiao_id, igreja_id
  into v_estado, v_bloco, v_regiao, v_igreja
  from jovens
  where id = p_jovem_id;

  insert into notificacoes (destinatario_id, tipo, titulo, mensagem, jovem_id, acao_url, remetente_id, lida, criado_em)
  select user_id, p_tipo, p_titulo, p_mensagem, p_jovem_id,
         coalesce(p_acao_url, '/jovens/' || p_jovem_id::text), p_remetente_id,
         false, now()
  from obter_lideres_para_notificacao(v_estado, v_bloco, v_regiao, v_igreja);

  get diagnostics v_count = row_count;
  return v_count;
end;
$$;


ALTER FUNCTION "public"."notificar_evento_jovem"("p_jovem_id" "uuid", "p_tipo" "text", "p_titulo" "text", "p_mensagem" "text", "p_remetente_id" "uuid", "p_acao_url" "text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."notificar_lideres"("p_tipo" "text", "p_titulo" "text", "p_mensagem" "text", "p_jovem_id" "uuid", "p_acao_url" "text" DEFAULT NULL::"text") RETURNS "void"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
DECLARE
  jovem_record record;
  lider_record record;
BEGIN
  -- Buscar dados do jovem
  SELECT estado_id, bloco_id, regiao_id, igreja_id
  INTO jovem_record
  FROM jovens
  WHERE id = p_jovem_id;
  
  -- Criar notificação para cada líder
  FOR lider_record IN 
    SELECT user_id FROM obter_lideres_para_notificacao(
      jovem_record.estado_id,
      jovem_record.bloco_id,
      jovem_record.regiao_id,
      jovem_record.igreja_id
    )
  LOOP
    INSERT INTO notificacoes (
      destinatario_id,
      tipo,
      titulo,
      mensagem,
      jovem_id,
      acao_url,
      lida
    ) VALUES (
      lider_record.user_id,
      p_tipo,
      p_titulo,
      p_mensagem,
      p_jovem_id,
      p_acao_url,
      false
    );
  END LOOP;
END;
$$;


ALTER FUNCTION "public"."notificar_lideres"("p_tipo" "text", "p_titulo" "text", "p_mensagem" "text", "p_jovem_id" "uuid", "p_acao_url" "text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."obter_estatisticas_sistema"() RETURNS json
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
DECLARE
  stats JSON;
BEGIN
  SELECT json_build_object(
    'total_usuarios', (SELECT COUNT(*) FROM usuarios),
    'total_jovens', (SELECT COUNT(*) FROM jovens),
    'total_avaliacoes', (SELECT COUNT(*) FROM avaliacoes),
    'total_notificacoes', (SELECT COUNT(*) FROM notificacoes),
    'usuarios_ativos', (SELECT COUNT(*) FROM usuarios WHERE ativo = true),
    'jovens_aprovados', (SELECT COUNT(*) FROM jovens WHERE aprovado = 'aprovado'),  -- ✅ CORRIGIDO: enum correto
    'jovens_pre_aprovados', (SELECT COUNT(*) FROM jovens WHERE aprovado = 'pre_aprovado'),  -- ✅ ADICIONADO
    'avaliacoes_hoje', (SELECT COUNT(*) FROM avaliacoes WHERE DATE(criado_em) = CURRENT_DATE),
    'notificacoes_nao_lidas', (SELECT COUNT(*) FROM notificacoes WHERE lida = false)
  ) INTO stats;
  
  RETURN stats;
END;
$$;


ALTER FUNCTION "public"."obter_estatisticas_sistema"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."obter_lideres_para_notificacao"("p_estado_id" "uuid", "p_bloco_id" "uuid", "p_regiao_id" "uuid", "p_igreja_id" "uuid") RETURNS TABLE("user_id" "uuid")
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
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
$$;


ALTER FUNCTION "public"."obter_lideres_para_notificacao"("p_estado_id" "uuid", "p_bloco_id" "uuid", "p_regiao_id" "uuid", "p_igreja_id" "uuid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."recalcular_idade"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    AS $$
begin
  new.idade = date_part('year', age(new.data_nasc))::int;
  return new;
end;
$$;


ALTER FUNCTION "public"."recalcular_idade"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."registrar_acesso_manual"("p_usuario_id" "uuid") RETURNS "jsonb"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
DECLARE
  current_user_id uuid;
  user_role_info record;
BEGIN
  current_user_id := auth.uid();
  IF current_user_id IS NULL THEN
    RETURN jsonb_build_object('success', false, 'error', 'Usuário não autenticado.');
  END IF;

  -- Verificar se é administrador
  SELECT id, nivel INTO user_role_info FROM public.usuarios WHERE id_auth = current_user_id;
  IF user_role_info.id IS NULL THEN
    RETURN jsonb_build_object('success', false, 'error', 'Perfil de usuário não encontrado.');
  END IF;

  IF user_role_info.nivel != 'administrador' THEN
    RETURN jsonb_build_object('success', false, 'error', 'Apenas administradores podem registrar acessos manualmente.');
  END IF;

  -- Atualizar último acesso
  UPDATE public.usuarios 
  SET ultimo_acesso = NOW()
  WHERE id = p_usuario_id;

  RETURN jsonb_build_object(
    'success', true,
    'message', 'Último acesso registrado com sucesso.',
    'usuario_id', p_usuario_id,
    'ultimo_acesso', NOW()
  );

EXCEPTION
  WHEN OTHERS THEN
    RETURN jsonb_build_object('success', false, 'error', SQLERRM);
END;
$$;


ALTER FUNCTION "public"."registrar_acesso_manual"("p_usuario_id" "uuid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."registrar_ultimo_acesso"() RETURNS "void"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
DECLARE
  current_user_id uuid;
  usuario_id uuid;
BEGIN
  -- Obter o ID do usuário autenticado
  current_user_id := auth.uid();
  
  IF current_user_id IS NULL THEN
    RETURN;
  END IF;
  
  -- Obter o ID do usuário na tabela usuarios
  SELECT id INTO usuario_id 
  FROM public.usuarios 
  WHERE id_auth = current_user_id;
  
  IF usuario_id IS NOT NULL THEN
    -- Atualizar o último acesso
    UPDATE public.usuarios 
    SET ultimo_acesso = NOW()
    WHERE id = usuario_id;
  END IF;
END;
$$;


ALTER FUNCTION "public"."registrar_ultimo_acesso"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."remover_aprovacao_admin"("p_aprovacao_id" "uuid") RETURNS "jsonb"
    LANGUAGE "plpgsql" SECURITY DEFINER
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


ALTER FUNCTION "public"."remover_aprovacao_admin"("p_aprovacao_id" "uuid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."remover_papel_usuario"("p_papel_id" "uuid") RETURNS "jsonb"
    LANGUAGE "plpgsql" SECURITY DEFINER
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


ALTER FUNCTION "public"."remover_papel_usuario"("p_papel_id" "uuid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."set_usuario_id_dados_viagem"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
begin
  if new.usuario_id is null then
    new.usuario_id := (select id from public.usuarios where id_auth = auth.uid());
  end if;
  return new;
end;
$$;


ALTER FUNCTION "public"."set_usuario_id_dados_viagem"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."set_usuario_id_on_insert"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
BEGIN
  IF NEW.usuario_id IS NULL THEN
    NEW.usuario_id := (SELECT id FROM public.usuarios WHERE id_auth = auth.uid());
  END IF;
  RETURN NEW;
END;
$$;


ALTER FUNCTION "public"."set_usuario_id_on_insert"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."sincronizar_nivel_com_papeis"("p_usuario_id" "uuid") RETURNS "jsonb"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
DECLARE
  user_info record;
  role_info record;
  nivel_correto text;
  resultado jsonb;
BEGIN
  -- Obter informações do usuário
  SELECT id, nome, nivel, estado_id, bloco_id, regiao_id, igreja_id
  INTO user_info
  FROM public.usuarios
  WHERE id = p_usuario_id;
  
  IF user_info IS NULL THEN
    RETURN jsonb_build_object('success', false, 'error', 'Usuário não encontrado');
  END IF;
  
  -- Buscar o papel com menor nível hierárquico (maior privilégio)
  SELECT r.slug, r.nivel_hierarquico
  INTO role_info
  FROM public.user_roles ur
  JOIN public.roles r ON r.id = ur.role_id
  WHERE ur.user_id = p_usuario_id 
    AND ur.ativo = true
  ORDER BY r.nivel_hierarquico ASC
  LIMIT 1;
  
  -- Se não tem papéis, manter o nível atual
  IF role_info IS NULL THEN
    RETURN jsonb_build_object(
      'success', true, 
      'message', 'Usuário sem papéis ativos - nível mantido',
      'nivel_atual', user_info.nivel
    );
  END IF;
  
  -- Determinar o nível correto baseado no papel
  nivel_correto := role_info.slug;
  
  -- Atualizar o nível se necessário
  IF user_info.nivel != nivel_correto THEN
    UPDATE public.usuarios
    SET nivel = nivel_correto
    WHERE id = p_usuario_id;
    
    -- Log da alteração
    INSERT INTO public.logs_auditoria (usuario_id, acao, detalhe, dados_novos)
    VALUES (
      p_usuario_id,
      'sincronizacao_nivel',
      'Nível sincronizado com papéis',
      jsonb_build_object(
        'nivel_anterior', user_info.nivel,
        'nivel_novo', nivel_correto,
        'papel_base', role_info.slug
      )
    );
    
    RETURN jsonb_build_object(
      'success', true,
      'message', 'Nível sincronizado com sucesso',
      'nivel_anterior', user_info.nivel,
      'nivel_novo', nivel_correto
    );
  ELSE
    RETURN jsonb_build_object(
      'success', true,
      'message', 'Nível já está sincronizado',
      'nivel_atual', user_info.nivel
    );
  END IF;
  
EXCEPTION
  WHEN OTHERS THEN
    RETURN jsonb_build_object('success', false, 'error', SQLERRM);
END;
$$;


ALTER FUNCTION "public"."sincronizar_nivel_com_papeis"("p_usuario_id" "uuid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."test_access_simple"() RETURNS "text"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
DECLARE
  user_info record;
BEGIN
  -- Obter informações do usuário atual
  SELECT 
    id,
    nivel,
    nome
  INTO user_info
  FROM public.usuarios 
  WHERE id_auth = auth.uid();
  
  -- Se não encontrou o usuário
  IF user_info IS NULL THEN 
    RETURN 'ERRO: Usuário não encontrado';
  END IF;
  
  -- Retornar informações do usuário
  RETURN 'Usuário: ' || user_info.nome || ' | Nível: ' || user_info.nivel;
END;
$$;


ALTER FUNCTION "public"."test_access_simple"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."test_access_simple_return"() RETURNS boolean
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
DECLARE
  user_info record;
BEGIN
  -- Obter informações do usuário atual
  SELECT 
    id,
    nivel,
    nome
  INTO user_info
  FROM public.usuarios 
  WHERE id_auth = auth.uid();
  
  -- Se não encontrou o usuário
  IF user_info IS NULL THEN 
    RETURN false;
  END IF;
  
  -- Verificar se é líder nacional
  IF user_info.nivel IN ('lider_nacional_iurd', 'lider_nacional_fju') THEN
    RETURN true;
  END IF;
  
  -- Verificar se é administrador
  IF user_info.nivel = 'administrador' THEN
    RETURN true;
  END IF;
  
  -- Se não é líder nacional nem administrador
  RETURN false;
END;
$$;


ALTER FUNCTION "public"."test_access_simple_return"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."test_lider_nacional"() RETURNS "text"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
DECLARE
  user_info record;
BEGIN
  -- Obter informações do usuário atual
  SELECT 
    id,
    nivel,
    nome
  INTO user_info
  FROM public.usuarios 
  WHERE id_auth = auth.uid();
  
  -- Se não encontrou o usuário
  IF user_info IS NULL THEN 
    RETURN 'ERRO: Usuário não encontrado';
  END IF;
  
  -- Verificar se é líder nacional
  IF user_info.nivel IN ('lider_nacional_iurd', 'lider_nacional_fju') THEN
    RETURN 'SUCESSO: Usuário é líder nacional - ' || user_info.nivel;
  END IF;
  
  -- Verificar se é administrador
  IF user_info.nivel = 'administrador' THEN
    RETURN 'SUCESSO: Usuário é administrador';
  END IF;
  
  -- Se não é líder nacional nem administrador
  RETURN 'ERRO: Usuário não é líder nacional nem administrador - Nível: ' || user_info.nivel;
END;
$$;


ALTER FUNCTION "public"."test_lider_nacional"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."trigger_notificar_mudanca_status"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    AS $$
DECLARE
  status_anterior text;
  status_novo text;
BEGIN
  -- Verificar se o status mudou
  IF OLD.aprovado IS DISTINCT FROM NEW.aprovado THEN
    -- Determinar status anterior e novo
    status_anterior := CASE 
      WHEN OLD.aprovado IS NULL THEN 'Não avaliado'
      WHEN OLD.aprovado = 'pre_aprovado' THEN 'Pré-aprovado'
      WHEN OLD.aprovado = 'aprovado' THEN 'Aprovado'
      ELSE 'Desconhecido'
    END;
    
    status_novo := CASE 
      WHEN NEW.aprovado IS NULL THEN 'Não avaliado'
      WHEN NEW.aprovado = 'pre_aprovado' THEN 'Pré-aprovado'
      WHEN NEW.aprovado = 'aprovado' THEN 'Aprovado'
      ELSE 'Desconhecido'
    END;
    
    -- Notificar líderes sobre mudança de status (usando tipo válido 'aprovacao')
    PERFORM notificar_lideres(
      'aprovacao',  -- ✅ TIPO VÁLIDO!
      'Status Alterado',
      'Um jovem teve seu status alterado de "' || status_anterior || '" para "' || status_novo || '"',
      NEW.id,
      '/jovens/' || NEW.id
    );
  END IF;
  
  RETURN NEW;
END;
$$;


ALTER FUNCTION "public"."trigger_notificar_mudanca_status"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."trigger_notificar_nova_avaliacao"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    AS $$
BEGIN
  -- Notificar líderes sobre nova avaliação
  PERFORM notificar_lideres(
    'avaliacao',
    'Nova Avaliação',
    'Um jovem recebeu uma nova avaliação',
    NEW.jovem_id,
    '/jovens/' || NEW.jovem_id
  );
  
  RETURN NEW;
END;
$$;


ALTER FUNCTION "public"."trigger_notificar_nova_avaliacao"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."trigger_notificar_novo_cadastro"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    AS $$
BEGIN
  -- Notificar líderes sobre novo cadastro
  PERFORM notificar_lideres(
    'cadastro',
    'Novo Jovem Cadastrado',
    'Um novo jovem foi cadastrado no sistema',
    NEW.id,
    '/jovens/' || NEW.id
  );
  
  RETURN NEW;
END;
$$;


ALTER FUNCTION "public"."trigger_notificar_novo_cadastro"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."trigger_registrar_acesso"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
BEGIN
  -- Registrar acesso quando há mudança na sessão
  PERFORM public.registrar_ultimo_acesso();
  RETURN COALESCE(NEW, OLD);
END;
$$;


ALTER FUNCTION "public"."trigger_registrar_acesso"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."trigger_sincronizar_nivel"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    AS $$
DECLARE
  resultado jsonb;
BEGIN
  -- Sincronizar nível do usuário afetado
  IF TG_OP = 'INSERT' OR TG_OP = 'UPDATE' THEN
    SELECT public.sincronizar_nivel_com_papeis(NEW.user_id) INTO resultado;
  ELSIF TG_OP = 'DELETE' THEN
    SELECT public.sincronizar_nivel_com_papeis(OLD.user_id) INTO resultado;
  END IF;
  
  RETURN COALESCE(NEW, OLD);
END;
$$;


ALTER FUNCTION "public"."trigger_sincronizar_nivel"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."update_dados_nucleo_updated_at"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    AS $$
BEGIN
    NEW.atualizado_em = NOW();
    RETURN NEW;
END;
$$;


ALTER FUNCTION "public"."update_dados_nucleo_updated_at"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."usuario_ja_aprovou"("p_jovem_id" "uuid", "p_tipo_aprovacao" "text" DEFAULT NULL::"text") RETURNS boolean
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
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
$$;


ALTER FUNCTION "public"."usuario_ja_aprovou"("p_jovem_id" "uuid", "p_tipo_aprovacao" "text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."verificar_integridade_funcoes"() RETURNS "jsonb"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
DECLARE
  resultado jsonb := '{}';
  funcoes_problemas text[] := '{}';
  total_funcoes integer := 0;
  funcoes_ok integer := 0;
BEGIN
  -- Verificar se as funções principais existem
  SELECT COUNT(*) INTO total_funcoes
  FROM information_schema.routines 
  WHERE routine_schema = 'public' 
  AND routine_type = 'FUNCTION';
  
  -- Verificar funções críticas
  IF NOT EXISTS (SELECT 1 FROM information_schema.routines WHERE routine_name = 'can_access_jovem') THEN
    funcoes_problemas := array_append(funcoes_problemas, 'can_access_jovem');
  ELSE
    funcoes_ok := funcoes_ok + 1;
  END IF;
  
  IF NOT EXISTS (SELECT 1 FROM information_schema.routines WHERE routine_name = 'atualizar_status_jovem') THEN
    funcoes_problemas := array_append(funcoes_problemas, 'atualizar_status_jovem');
  ELSE
    funcoes_ok := funcoes_ok + 1;
  END IF;
  
  IF NOT EXISTS (SELECT 1 FROM information_schema.routines WHERE routine_name = 'remover_aprovacao_admin') THEN
    funcoes_problemas := array_append(funcoes_problemas, 'remover_aprovacao_admin');
  ELSE
    funcoes_ok := funcoes_ok + 1;
  END IF;
  
  IF NOT EXISTS (SELECT 1 FROM information_schema.routines WHERE routine_name = 'obter_lideres_para_notificacao') THEN
    funcoes_problemas := array_append(funcoes_problemas, 'obter_lideres_para_notificacao');
  ELSE
    funcoes_ok := funcoes_ok + 1;
  END IF;
  
  resultado := jsonb_build_object(
    'total_funcoes', total_funcoes,
    'funcoes_criticas_ok', funcoes_ok,
    'funcoes_problemas', funcoes_problemas,
    'status', CASE 
      WHEN array_length(funcoes_problemas, 1) IS NULL THEN 'TODAS_OK'
      ELSE 'PROBLEMAS_ENCONTRADOS'
    END
  );
  
  RETURN resultado;
END;
$$;


ALTER FUNCTION "public"."verificar_integridade_funcoes"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "storage"."allow_any_operation"("expected_operations" "text"[]) RETURNS boolean
    LANGUAGE "sql" STABLE
    AS $$
  WITH current_operation AS (
    SELECT storage.operation() AS raw_operation
  ),
  normalized AS (
    SELECT CASE
      WHEN raw_operation LIKE 'storage.%' THEN substr(raw_operation, 9)
      ELSE raw_operation
    END AS current_operation
    FROM current_operation
  )
  SELECT EXISTS (
    SELECT 1
    FROM normalized n
    CROSS JOIN LATERAL unnest(expected_operations) AS expected_operation
    WHERE expected_operation IS NOT NULL
      AND expected_operation <> ''
      AND n.current_operation = CASE
        WHEN expected_operation LIKE 'storage.%' THEN substr(expected_operation, 9)
        ELSE expected_operation
      END
  );
$$;


ALTER FUNCTION "storage"."allow_any_operation"("expected_operations" "text"[]) OWNER TO "supabase_storage_admin";


CREATE OR REPLACE FUNCTION "storage"."allow_only_operation"("expected_operation" "text") RETURNS boolean
    LANGUAGE "sql" STABLE
    AS $$
  WITH current_operation AS (
    SELECT storage.operation() AS raw_operation
  ),
  normalized AS (
    SELECT
      CASE
        WHEN raw_operation LIKE 'storage.%' THEN substr(raw_operation, 9)
        ELSE raw_operation
      END AS current_operation,
      CASE
        WHEN expected_operation LIKE 'storage.%' THEN substr(expected_operation, 9)
        ELSE expected_operation
      END AS requested_operation
    FROM current_operation
  )
  SELECT CASE
    WHEN requested_operation IS NULL OR requested_operation = '' THEN FALSE
    ELSE COALESCE(current_operation = requested_operation, FALSE)
  END
  FROM normalized;
$$;


ALTER FUNCTION "storage"."allow_only_operation"("expected_operation" "text") OWNER TO "supabase_storage_admin";


CREATE OR REPLACE FUNCTION "storage"."can_insert_object"("bucketid" "text", "name" "text", "owner" "uuid", "metadata" "jsonb") RETURNS "void"
    LANGUAGE "plpgsql"
    AS $$
BEGIN
  INSERT INTO "storage"."objects" ("bucket_id", "name", "owner", "metadata") VALUES (bucketid, name, owner, metadata);
  -- hack to rollback the successful insert
  RAISE sqlstate 'PT200' using
  message = 'ROLLBACK',
  detail = 'rollback successful insert';
END
$$;


ALTER FUNCTION "storage"."can_insert_object"("bucketid" "text", "name" "text", "owner" "uuid", "metadata" "jsonb") OWNER TO "supabase_storage_admin";


CREATE OR REPLACE FUNCTION "storage"."enforce_bucket_name_length"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    AS $$
begin
    if length(new.name) > 100 then
        raise exception 'bucket name "%" is too long (% characters). Max is 100.', new.name, length(new.name);
    end if;
    return new;
end;
$$;


ALTER FUNCTION "storage"."enforce_bucket_name_length"() OWNER TO "supabase_storage_admin";


CREATE OR REPLACE FUNCTION "storage"."extension"("name" "text") RETURNS "text"
    LANGUAGE "plpgsql" IMMUTABLE
    AS $$
DECLARE
    _parts text[];
    _filename text;
BEGIN
    -- Split on "/" to get path segments
    SELECT string_to_array(name, '/') INTO _parts;
    -- Get the last path segment (the actual filename)
    SELECT _parts[array_length(_parts, 1)] INTO _filename;
    -- Extract extension: reverse, split on '.', then reverse again
    RETURN reverse(split_part(reverse(_filename), '.', 1));
END
$$;


ALTER FUNCTION "storage"."extension"("name" "text") OWNER TO "supabase_storage_admin";


CREATE OR REPLACE FUNCTION "storage"."filename"("name" "text") RETURNS "text"
    LANGUAGE "plpgsql"
    AS $$
DECLARE
_parts text[];
BEGIN
	select string_to_array(name, '/') into _parts;
	return _parts[array_length(_parts,1)];
END
$$;


ALTER FUNCTION "storage"."filename"("name" "text") OWNER TO "supabase_storage_admin";


CREATE OR REPLACE FUNCTION "storage"."foldername"("name" "text") RETURNS "text"[]
    LANGUAGE "plpgsql" IMMUTABLE
    AS $$
DECLARE
    _parts text[];
BEGIN
    -- Split on "/" to get path segments
    SELECT string_to_array(name, '/') INTO _parts;
    -- Return everything except the last segment
    RETURN _parts[1 : array_length(_parts,1) - 1];
END
$$;


ALTER FUNCTION "storage"."foldername"("name" "text") OWNER TO "supabase_storage_admin";


CREATE OR REPLACE FUNCTION "storage"."get_common_prefix"("p_key" "text", "p_prefix" "text", "p_delimiter" "text") RETURNS "text"
    LANGUAGE "sql" IMMUTABLE
    AS $$
SELECT CASE
    WHEN position(p_delimiter IN substring(p_key FROM length(p_prefix) + 1)) > 0
    THEN left(p_key, length(p_prefix) + position(p_delimiter IN substring(p_key FROM length(p_prefix) + 1)))
    ELSE NULL
END;
$$;


ALTER FUNCTION "storage"."get_common_prefix"("p_key" "text", "p_prefix" "text", "p_delimiter" "text") OWNER TO "supabase_storage_admin";


CREATE OR REPLACE FUNCTION "storage"."get_size_by_bucket"() RETURNS TABLE("size" bigint, "bucket_id" "text")
    LANGUAGE "plpgsql" STABLE
    AS $$
BEGIN
    return query
        select sum((metadata->>'size')::bigint)::bigint as size, obj.bucket_id
        from "storage".objects as obj
        group by obj.bucket_id;
END
$$;


ALTER FUNCTION "storage"."get_size_by_bucket"() OWNER TO "supabase_storage_admin";


CREATE OR REPLACE FUNCTION "storage"."list_multipart_uploads_with_delimiter"("bucket_id" "text", "prefix_param" "text", "delimiter_param" "text", "max_keys" integer DEFAULT 100, "next_key_token" "text" DEFAULT ''::"text", "next_upload_token" "text" DEFAULT ''::"text") RETURNS TABLE("key" "text", "id" "text", "created_at" timestamp with time zone)
    LANGUAGE "plpgsql"
    AS $_$
BEGIN
    RETURN QUERY EXECUTE
        'SELECT DISTINCT ON(key COLLATE "C") * from (
            SELECT
                CASE
                    WHEN position($2 IN substring(key from length($1) + 1)) > 0 THEN
                        substring(key from 1 for length($1) + position($2 IN substring(key from length($1) + 1)))
                    ELSE
                        key
                END AS key, id, created_at
            FROM
                storage.s3_multipart_uploads
            WHERE
                bucket_id = $5 AND
                key ILIKE $1 || ''%'' AND
                CASE
                    WHEN $4 != '''' AND $6 = '''' THEN
                        CASE
                            WHEN position($2 IN substring(key from length($1) + 1)) > 0 THEN
                                substring(key from 1 for length($1) + position($2 IN substring(key from length($1) + 1))) COLLATE "C" > $4
                            ELSE
                                key COLLATE "C" > $4
                            END
                    ELSE
                        true
                END AND
                CASE
                    WHEN $6 != '''' THEN
                        id COLLATE "C" > $6
                    ELSE
                        true
                    END
            ORDER BY
                key COLLATE "C" ASC, created_at ASC) as e order by key COLLATE "C" LIMIT $3'
        USING prefix_param, delimiter_param, max_keys, next_key_token, bucket_id, next_upload_token;
END;
$_$;


ALTER FUNCTION "storage"."list_multipart_uploads_with_delimiter"("bucket_id" "text", "prefix_param" "text", "delimiter_param" "text", "max_keys" integer, "next_key_token" "text", "next_upload_token" "text") OWNER TO "supabase_storage_admin";


CREATE OR REPLACE FUNCTION "storage"."list_objects_with_delimiter"("_bucket_id" "text", "prefix_param" "text", "delimiter_param" "text", "max_keys" integer DEFAULT 100, "start_after" "text" DEFAULT ''::"text", "next_token" "text" DEFAULT ''::"text", "sort_order" "text" DEFAULT 'asc'::"text") RETURNS TABLE("name" "text", "id" "uuid", "metadata" "jsonb", "updated_at" timestamp with time zone, "created_at" timestamp with time zone, "last_accessed_at" timestamp with time zone)
    LANGUAGE "plpgsql" STABLE
    AS $_$
DECLARE
    v_peek_name TEXT;
    v_current RECORD;
    v_common_prefix TEXT;

    -- Configuration
    v_is_asc BOOLEAN;
    v_prefix TEXT;
    v_start TEXT;
    v_upper_bound TEXT;
    v_file_batch_size INT;

    -- Seek state
    v_next_seek TEXT;
    v_count INT := 0;

    -- Dynamic SQL for batch query only
    v_batch_query TEXT;

BEGIN
    -- ========================================================================
    -- INITIALIZATION
    -- ========================================================================
    v_is_asc := lower(coalesce(sort_order, 'asc')) = 'asc';
    v_prefix := coalesce(prefix_param, '');
    v_start := CASE WHEN coalesce(next_token, '') <> '' THEN next_token ELSE coalesce(start_after, '') END;
    v_file_batch_size := LEAST(GREATEST(max_keys * 2, 100), 1000);

    -- Calculate upper bound for prefix filtering (bytewise, using COLLATE "C")
    IF v_prefix = '' THEN
        v_upper_bound := NULL;
    ELSIF right(v_prefix, 1) = delimiter_param THEN
        v_upper_bound := left(v_prefix, -1) || chr(ascii(delimiter_param) + 1);
    ELSE
        v_upper_bound := left(v_prefix, -1) || chr(ascii(right(v_prefix, 1)) + 1);
    END IF;

    -- Build batch query (dynamic SQL - called infrequently, amortized over many rows)
    IF v_is_asc THEN
        IF v_upper_bound IS NOT NULL THEN
            v_batch_query := 'SELECT o.name, o.id, o.updated_at, o.created_at, o.last_accessed_at, o.metadata ' ||
                'FROM storage.objects o WHERE o.bucket_id = $1 AND o.name COLLATE "C" >= $2 ' ||
                'AND o.name COLLATE "C" < $3 ORDER BY o.name COLLATE "C" ASC LIMIT $4';
        ELSE
            v_batch_query := 'SELECT o.name, o.id, o.updated_at, o.created_at, o.last_accessed_at, o.metadata ' ||
                'FROM storage.objects o WHERE o.bucket_id = $1 AND o.name COLLATE "C" >= $2 ' ||
                'ORDER BY o.name COLLATE "C" ASC LIMIT $4';
        END IF;
    ELSE
        IF v_upper_bound IS NOT NULL THEN
            v_batch_query := 'SELECT o.name, o.id, o.updated_at, o.created_at, o.last_accessed_at, o.metadata ' ||
                'FROM storage.objects o WHERE o.bucket_id = $1 AND o.name COLLATE "C" < $2 ' ||
                'AND o.name COLLATE "C" >= $3 ORDER BY o.name COLLATE "C" DESC LIMIT $4';
        ELSE
            v_batch_query := 'SELECT o.name, o.id, o.updated_at, o.created_at, o.last_accessed_at, o.metadata ' ||
                'FROM storage.objects o WHERE o.bucket_id = $1 AND o.name COLLATE "C" < $2 ' ||
                'ORDER BY o.name COLLATE "C" DESC LIMIT $4';
        END IF;
    END IF;

    -- ========================================================================
    -- SEEK INITIALIZATION: Determine starting position
    -- ========================================================================
    IF v_start = '' THEN
        IF v_is_asc THEN
            v_next_seek := v_prefix;
        ELSE
            -- DESC without cursor: find the last item in range
            IF v_upper_bound IS NOT NULL THEN
                SELECT o.name INTO v_next_seek FROM storage.objects o
                WHERE o.bucket_id = _bucket_id AND o.name COLLATE "C" >= v_prefix AND o.name COLLATE "C" < v_upper_bound
                ORDER BY o.name COLLATE "C" DESC LIMIT 1;
            ELSIF v_prefix <> '' THEN
                SELECT o.name INTO v_next_seek FROM storage.objects o
                WHERE o.bucket_id = _bucket_id AND o.name COLLATE "C" >= v_prefix
                ORDER BY o.name COLLATE "C" DESC LIMIT 1;
            ELSE
                SELECT o.name INTO v_next_seek FROM storage.objects o
                WHERE o.bucket_id = _bucket_id
                ORDER BY o.name COLLATE "C" DESC LIMIT 1;
            END IF;

            IF v_next_seek IS NOT NULL THEN
                v_next_seek := v_next_seek || delimiter_param;
            ELSE
                RETURN;
            END IF;
        END IF;
    ELSE
        -- Cursor provided: determine if it refers to a folder or leaf
        IF EXISTS (
            SELECT 1 FROM storage.objects o
            WHERE o.bucket_id = _bucket_id
              AND o.name COLLATE "C" LIKE v_start || delimiter_param || '%'
            LIMIT 1
        ) THEN
            -- Cursor refers to a folder
            IF v_is_asc THEN
                v_next_seek := v_start || chr(ascii(delimiter_param) + 1);
            ELSE
                v_next_seek := v_start || delimiter_param;
            END IF;
        ELSE
            -- Cursor refers to a leaf object
            IF v_is_asc THEN
                v_next_seek := v_start || delimiter_param;
            ELSE
                v_next_seek := v_start;
            END IF;
        END IF;
    END IF;

    -- ========================================================================
    -- MAIN LOOP: Hybrid peek-then-batch algorithm
    -- Uses STATIC SQL for peek (hot path) and DYNAMIC SQL for batch
    -- ========================================================================
    LOOP
        EXIT WHEN v_count >= max_keys;

        -- STEP 1: PEEK using STATIC SQL (plan cached, very fast)
        IF v_is_asc THEN
            IF v_upper_bound IS NOT NULL THEN
                SELECT o.name INTO v_peek_name FROM storage.objects o
                WHERE o.bucket_id = _bucket_id AND o.name COLLATE "C" >= v_next_seek AND o.name COLLATE "C" < v_upper_bound
                ORDER BY o.name COLLATE "C" ASC LIMIT 1;
            ELSE
                SELECT o.name INTO v_peek_name FROM storage.objects o
                WHERE o.bucket_id = _bucket_id AND o.name COLLATE "C" >= v_next_seek
                ORDER BY o.name COLLATE "C" ASC LIMIT 1;
            END IF;
        ELSE
            IF v_upper_bound IS NOT NULL THEN
                SELECT o.name INTO v_peek_name FROM storage.objects o
                WHERE o.bucket_id = _bucket_id AND o.name COLLATE "C" < v_next_seek AND o.name COLLATE "C" >= v_prefix
                ORDER BY o.name COLLATE "C" DESC LIMIT 1;
            ELSIF v_prefix <> '' THEN
                SELECT o.name INTO v_peek_name FROM storage.objects o
                WHERE o.bucket_id = _bucket_id AND o.name COLLATE "C" < v_next_seek AND o.name COLLATE "C" >= v_prefix
                ORDER BY o.name COLLATE "C" DESC LIMIT 1;
            ELSE
                SELECT o.name INTO v_peek_name FROM storage.objects o
                WHERE o.bucket_id = _bucket_id AND o.name COLLATE "C" < v_next_seek
                ORDER BY o.name COLLATE "C" DESC LIMIT 1;
            END IF;
        END IF;

        EXIT WHEN v_peek_name IS NULL;

        -- STEP 2: Check if this is a FOLDER or FILE
        v_common_prefix := storage.get_common_prefix(v_peek_name, v_prefix, delimiter_param);

        IF v_common_prefix IS NOT NULL THEN
            -- FOLDER: Emit and skip to next folder (no heap access needed)
            name := rtrim(v_common_prefix, delimiter_param);
            id := NULL;
            updated_at := NULL;
            created_at := NULL;
            last_accessed_at := NULL;
            metadata := NULL;
            RETURN NEXT;
            v_count := v_count + 1;

            -- Advance seek past the folder range
            IF v_is_asc THEN
                v_next_seek := left(v_common_prefix, -1) || chr(ascii(delimiter_param) + 1);
            ELSE
                v_next_seek := v_common_prefix;
            END IF;
        ELSE
            -- FILE: Batch fetch using DYNAMIC SQL (overhead amortized over many rows)
            -- For ASC: upper_bound is the exclusive upper limit (< condition)
            -- For DESC: prefix is the inclusive lower limit (>= condition)
            FOR v_current IN EXECUTE v_batch_query USING _bucket_id, v_next_seek,
                CASE WHEN v_is_asc THEN COALESCE(v_upper_bound, v_prefix) ELSE v_prefix END, v_file_batch_size
            LOOP
                v_common_prefix := storage.get_common_prefix(v_current.name, v_prefix, delimiter_param);

                IF v_common_prefix IS NOT NULL THEN
                    -- Hit a folder: exit batch, let peek handle it
                    v_next_seek := v_current.name;
                    EXIT;
                END IF;

                -- Emit file
                name := v_current.name;
                id := v_current.id;
                updated_at := v_current.updated_at;
                created_at := v_current.created_at;
                last_accessed_at := v_current.last_accessed_at;
                metadata := v_current.metadata;
                RETURN NEXT;
                v_count := v_count + 1;

                -- Advance seek past this file
                IF v_is_asc THEN
                    v_next_seek := v_current.name || delimiter_param;
                ELSE
                    v_next_seek := v_current.name;
                END IF;

                EXIT WHEN v_count >= max_keys;
            END LOOP;
        END IF;
    END LOOP;
END;
$_$;


ALTER FUNCTION "storage"."list_objects_with_delimiter"("_bucket_id" "text", "prefix_param" "text", "delimiter_param" "text", "max_keys" integer, "start_after" "text", "next_token" "text", "sort_order" "text") OWNER TO "supabase_storage_admin";


CREATE OR REPLACE FUNCTION "storage"."operation"() RETURNS "text"
    LANGUAGE "plpgsql" STABLE
    AS $$
BEGIN
    RETURN current_setting('storage.operation', true);
END;
$$;


ALTER FUNCTION "storage"."operation"() OWNER TO "supabase_storage_admin";


CREATE OR REPLACE FUNCTION "storage"."protect_delete"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    AS $$
BEGIN
    -- Check if storage.allow_delete_query is set to 'true'
    IF COALESCE(current_setting('storage.allow_delete_query', true), 'false') != 'true' THEN
        RAISE EXCEPTION 'Direct deletion from storage tables is not allowed. Use the Storage API instead.'
            USING HINT = 'This prevents accidental data loss from orphaned objects.',
                  ERRCODE = '42501';
    END IF;
    RETURN NULL;
END;
$$;


ALTER FUNCTION "storage"."protect_delete"() OWNER TO "supabase_storage_admin";


CREATE OR REPLACE FUNCTION "storage"."search"("prefix" "text", "bucketname" "text", "limits" integer DEFAULT 100, "levels" integer DEFAULT 1, "offsets" integer DEFAULT 0, "search" "text" DEFAULT ''::"text", "sortcolumn" "text" DEFAULT 'name'::"text", "sortorder" "text" DEFAULT 'asc'::"text") RETURNS TABLE("name" "text", "id" "uuid", "updated_at" timestamp with time zone, "created_at" timestamp with time zone, "last_accessed_at" timestamp with time zone, "metadata" "jsonb")
    LANGUAGE "plpgsql" STABLE
    AS $_$
DECLARE
    v_peek_name TEXT;
    v_current RECORD;
    v_common_prefix TEXT;
    v_delimiter CONSTANT TEXT := '/';

    -- Configuration
    v_limit INT;
    v_prefix TEXT;
    v_prefix_lower TEXT;
    v_is_asc BOOLEAN;
    v_order_by TEXT;
    v_sort_order TEXT;
    v_upper_bound TEXT;
    v_file_batch_size INT;

    -- Dynamic SQL for batch query only
    v_batch_query TEXT;

    -- Seek state
    v_next_seek TEXT;
    v_count INT := 0;
    v_skipped INT := 0;
BEGIN
    -- ========================================================================
    -- INITIALIZATION
    -- ========================================================================
    v_limit := LEAST(coalesce(limits, 100), 1500);
    v_prefix := coalesce(prefix, '') || coalesce(search, '');
    v_prefix_lower := lower(v_prefix);
    v_is_asc := lower(coalesce(sortorder, 'asc')) = 'asc';
    v_file_batch_size := LEAST(GREATEST(v_limit * 2, 100), 1000);

    -- Validate sort column
    CASE lower(coalesce(sortcolumn, 'name'))
        WHEN 'name' THEN v_order_by := 'name';
        WHEN 'updated_at' THEN v_order_by := 'updated_at';
        WHEN 'created_at' THEN v_order_by := 'created_at';
        WHEN 'last_accessed_at' THEN v_order_by := 'last_accessed_at';
        ELSE v_order_by := 'name';
    END CASE;

    v_sort_order := CASE WHEN v_is_asc THEN 'asc' ELSE 'desc' END;

    -- ========================================================================
    -- NON-NAME SORTING: Use path_tokens approach (unchanged)
    -- ========================================================================
    IF v_order_by != 'name' THEN
        RETURN QUERY EXECUTE format(
            $sql$
            WITH folders AS (
                SELECT path_tokens[$1] AS folder
                FROM storage.objects
                WHERE objects.name ILIKE $2 || '%%'
                  AND bucket_id = $3
                  AND array_length(objects.path_tokens, 1) <> $1
                GROUP BY folder
                ORDER BY folder %s
            )
            (SELECT folder AS "name",
                   NULL::uuid AS id,
                   NULL::timestamptz AS updated_at,
                   NULL::timestamptz AS created_at,
                   NULL::timestamptz AS last_accessed_at,
                   NULL::jsonb AS metadata FROM folders)
            UNION ALL
            (SELECT path_tokens[$1] AS "name",
                   id, updated_at, created_at, last_accessed_at, metadata
             FROM storage.objects
             WHERE objects.name ILIKE $2 || '%%'
               AND bucket_id = $3
               AND array_length(objects.path_tokens, 1) = $1
             ORDER BY %I %s)
            LIMIT $4 OFFSET $5
            $sql$, v_sort_order, v_order_by, v_sort_order
        ) USING levels, v_prefix, bucketname, v_limit, offsets;
        RETURN;
    END IF;

    -- ========================================================================
    -- NAME SORTING: Hybrid skip-scan with batch optimization
    -- ========================================================================

    -- Calculate upper bound for prefix filtering
    IF v_prefix_lower = '' THEN
        v_upper_bound := NULL;
    ELSIF right(v_prefix_lower, 1) = v_delimiter THEN
        v_upper_bound := left(v_prefix_lower, -1) || chr(ascii(v_delimiter) + 1);
    ELSE
        v_upper_bound := left(v_prefix_lower, -1) || chr(ascii(right(v_prefix_lower, 1)) + 1);
    END IF;

    -- Build batch query (dynamic SQL - called infrequently, amortized over many rows)
    IF v_is_asc THEN
        IF v_upper_bound IS NOT NULL THEN
            v_batch_query := 'SELECT o.name, o.id, o.updated_at, o.created_at, o.last_accessed_at, o.metadata ' ||
                'FROM storage.objects o WHERE o.bucket_id = $1 AND lower(o.name) COLLATE "C" >= $2 ' ||
                'AND lower(o.name) COLLATE "C" < $3 ORDER BY lower(o.name) COLLATE "C" ASC LIMIT $4';
        ELSE
            v_batch_query := 'SELECT o.name, o.id, o.updated_at, o.created_at, o.last_accessed_at, o.metadata ' ||
                'FROM storage.objects o WHERE o.bucket_id = $1 AND lower(o.name) COLLATE "C" >= $2 ' ||
                'ORDER BY lower(o.name) COLLATE "C" ASC LIMIT $4';
        END IF;
    ELSE
        IF v_upper_bound IS NOT NULL THEN
            v_batch_query := 'SELECT o.name, o.id, o.updated_at, o.created_at, o.last_accessed_at, o.metadata ' ||
                'FROM storage.objects o WHERE o.bucket_id = $1 AND lower(o.name) COLLATE "C" < $2 ' ||
                'AND lower(o.name) COLLATE "C" >= $3 ORDER BY lower(o.name) COLLATE "C" DESC LIMIT $4';
        ELSE
            v_batch_query := 'SELECT o.name, o.id, o.updated_at, o.created_at, o.last_accessed_at, o.metadata ' ||
                'FROM storage.objects o WHERE o.bucket_id = $1 AND lower(o.name) COLLATE "C" < $2 ' ||
                'ORDER BY lower(o.name) COLLATE "C" DESC LIMIT $4';
        END IF;
    END IF;

    -- Initialize seek position
    IF v_is_asc THEN
        v_next_seek := v_prefix_lower;
    ELSE
        -- DESC: find the last item in range first (static SQL)
        IF v_upper_bound IS NOT NULL THEN
            SELECT o.name INTO v_peek_name FROM storage.objects o
            WHERE o.bucket_id = bucketname AND lower(o.name) COLLATE "C" >= v_prefix_lower AND lower(o.name) COLLATE "C" < v_upper_bound
            ORDER BY lower(o.name) COLLATE "C" DESC LIMIT 1;
        ELSIF v_prefix_lower <> '' THEN
            SELECT o.name INTO v_peek_name FROM storage.objects o
            WHERE o.bucket_id = bucketname AND lower(o.name) COLLATE "C" >= v_prefix_lower
            ORDER BY lower(o.name) COLLATE "C" DESC LIMIT 1;
        ELSE
            SELECT o.name INTO v_peek_name FROM storage.objects o
            WHERE o.bucket_id = bucketname
            ORDER BY lower(o.name) COLLATE "C" DESC LIMIT 1;
        END IF;

        IF v_peek_name IS NOT NULL THEN
            v_next_seek := lower(v_peek_name) || v_delimiter;
        ELSE
            RETURN;
        END IF;
    END IF;

    -- ========================================================================
    -- MAIN LOOP: Hybrid peek-then-batch algorithm
    -- Uses STATIC SQL for peek (hot path) and DYNAMIC SQL for batch
    -- ========================================================================
    LOOP
        EXIT WHEN v_count >= v_limit;

        -- STEP 1: PEEK using STATIC SQL (plan cached, very fast)
        IF v_is_asc THEN
            IF v_upper_bound IS NOT NULL THEN
                SELECT o.name INTO v_peek_name FROM storage.objects o
                WHERE o.bucket_id = bucketname AND lower(o.name) COLLATE "C" >= v_next_seek AND lower(o.name) COLLATE "C" < v_upper_bound
                ORDER BY lower(o.name) COLLATE "C" ASC LIMIT 1;
            ELSE
                SELECT o.name INTO v_peek_name FROM storage.objects o
                WHERE o.bucket_id = bucketname AND lower(o.name) COLLATE "C" >= v_next_seek
                ORDER BY lower(o.name) COLLATE "C" ASC LIMIT 1;
            END IF;
        ELSE
            IF v_upper_bound IS NOT NULL THEN
                SELECT o.name INTO v_peek_name FROM storage.objects o
                WHERE o.bucket_id = bucketname AND lower(o.name) COLLATE "C" < v_next_seek AND lower(o.name) COLLATE "C" >= v_prefix_lower
                ORDER BY lower(o.name) COLLATE "C" DESC LIMIT 1;
            ELSIF v_prefix_lower <> '' THEN
                SELECT o.name INTO v_peek_name FROM storage.objects o
                WHERE o.bucket_id = bucketname AND lower(o.name) COLLATE "C" < v_next_seek AND lower(o.name) COLLATE "C" >= v_prefix_lower
                ORDER BY lower(o.name) COLLATE "C" DESC LIMIT 1;
            ELSE
                SELECT o.name INTO v_peek_name FROM storage.objects o
                WHERE o.bucket_id = bucketname AND lower(o.name) COLLATE "C" < v_next_seek
                ORDER BY lower(o.name) COLLATE "C" DESC LIMIT 1;
            END IF;
        END IF;

        EXIT WHEN v_peek_name IS NULL;

        -- STEP 2: Check if this is a FOLDER or FILE
        v_common_prefix := storage.get_common_prefix(lower(v_peek_name), v_prefix_lower, v_delimiter);

        IF v_common_prefix IS NOT NULL THEN
            -- FOLDER: Handle offset, emit if needed, skip to next folder
            IF v_skipped < offsets THEN
                v_skipped := v_skipped + 1;
            ELSE
                name := split_part(rtrim(storage.get_common_prefix(v_peek_name, v_prefix, v_delimiter), v_delimiter), v_delimiter, levels);
                id := NULL;
                updated_at := NULL;
                created_at := NULL;
                last_accessed_at := NULL;
                metadata := NULL;
                RETURN NEXT;
                v_count := v_count + 1;
            END IF;

            -- Advance seek past the folder range
            IF v_is_asc THEN
                v_next_seek := lower(left(v_common_prefix, -1)) || chr(ascii(v_delimiter) + 1);
            ELSE
                v_next_seek := lower(v_common_prefix);
            END IF;
        ELSE
            -- FILE: Batch fetch using DYNAMIC SQL (overhead amortized over many rows)
            -- For ASC: upper_bound is the exclusive upper limit (< condition)
            -- For DESC: prefix_lower is the inclusive lower limit (>= condition)
            FOR v_current IN EXECUTE v_batch_query
                USING bucketname, v_next_seek,
                    CASE WHEN v_is_asc THEN COALESCE(v_upper_bound, v_prefix_lower) ELSE v_prefix_lower END, v_file_batch_size
            LOOP
                v_common_prefix := storage.get_common_prefix(lower(v_current.name), v_prefix_lower, v_delimiter);

                IF v_common_prefix IS NOT NULL THEN
                    -- Hit a folder: exit batch, let peek handle it
                    v_next_seek := lower(v_current.name);
                    EXIT;
                END IF;

                -- Handle offset skipping
                IF v_skipped < offsets THEN
                    v_skipped := v_skipped + 1;
                ELSE
                    -- Emit file
                    name := split_part(v_current.name, v_delimiter, levels);
                    id := v_current.id;
                    updated_at := v_current.updated_at;
                    created_at := v_current.created_at;
                    last_accessed_at := v_current.last_accessed_at;
                    metadata := v_current.metadata;
                    RETURN NEXT;
                    v_count := v_count + 1;
                END IF;

                -- Advance seek past this file
                IF v_is_asc THEN
                    v_next_seek := lower(v_current.name) || v_delimiter;
                ELSE
                    v_next_seek := lower(v_current.name);
                END IF;

                EXIT WHEN v_count >= v_limit;
            END LOOP;
        END IF;
    END LOOP;
END;
$_$;


ALTER FUNCTION "storage"."search"("prefix" "text", "bucketname" "text", "limits" integer, "levels" integer, "offsets" integer, "search" "text", "sortcolumn" "text", "sortorder" "text") OWNER TO "supabase_storage_admin";


CREATE OR REPLACE FUNCTION "storage"."search_by_timestamp"("p_prefix" "text", "p_bucket_id" "text", "p_limit" integer, "p_level" integer, "p_start_after" "text", "p_sort_order" "text", "p_sort_column" "text", "p_sort_column_after" "text") RETURNS TABLE("key" "text", "name" "text", "id" "uuid", "updated_at" timestamp with time zone, "created_at" timestamp with time zone, "last_accessed_at" timestamp with time zone, "metadata" "jsonb")
    LANGUAGE "plpgsql" STABLE
    AS $_$
DECLARE
    v_cursor_op text;
    v_query text;
    v_prefix text;
BEGIN
    v_prefix := coalesce(p_prefix, '');

    IF p_sort_order = 'asc' THEN
        v_cursor_op := '>';
    ELSE
        v_cursor_op := '<';
    END IF;

    v_query := format($sql$
        WITH raw_objects AS (
            SELECT
                o.name AS obj_name,
                o.id AS obj_id,
                o.updated_at AS obj_updated_at,
                o.created_at AS obj_created_at,
                o.last_accessed_at AS obj_last_accessed_at,
                o.metadata AS obj_metadata,
                storage.get_common_prefix(o.name, $1, '/') AS common_prefix
            FROM storage.objects o
            WHERE o.bucket_id = $2
              AND o.name COLLATE "C" LIKE $1 || '%%'
        ),
        -- Aggregate common prefixes (folders)
        -- Both created_at and updated_at use MIN(obj_created_at) to match the old prefixes table behavior
        aggregated_prefixes AS (
            SELECT
                rtrim(common_prefix, '/') AS name,
                NULL::uuid AS id,
                MIN(obj_created_at) AS updated_at,
                MIN(obj_created_at) AS created_at,
                NULL::timestamptz AS last_accessed_at,
                NULL::jsonb AS metadata,
                TRUE AS is_prefix
            FROM raw_objects
            WHERE common_prefix IS NOT NULL
            GROUP BY common_prefix
        ),
        leaf_objects AS (
            SELECT
                obj_name AS name,
                obj_id AS id,
                obj_updated_at AS updated_at,
                obj_created_at AS created_at,
                obj_last_accessed_at AS last_accessed_at,
                obj_metadata AS metadata,
                FALSE AS is_prefix
            FROM raw_objects
            WHERE common_prefix IS NULL
        ),
        combined AS (
            SELECT * FROM aggregated_prefixes
            UNION ALL
            SELECT * FROM leaf_objects
        ),
        filtered AS (
            SELECT *
            FROM combined
            WHERE (
                $5 = ''
                OR ROW(
                    date_trunc('milliseconds', %I),
                    name COLLATE "C"
                ) %s ROW(
                    COALESCE(NULLIF($6, '')::timestamptz, 'epoch'::timestamptz),
                    $5
                )
            )
        )
        SELECT
            split_part(name, '/', $3) AS key,
            name,
            id,
            updated_at,
            created_at,
            last_accessed_at,
            metadata
        FROM filtered
        ORDER BY
            COALESCE(date_trunc('milliseconds', %I), 'epoch'::timestamptz) %s,
            name COLLATE "C" %s
        LIMIT $4
    $sql$,
        p_sort_column,
        v_cursor_op,
        p_sort_column,
        p_sort_order,
        p_sort_order
    );

    RETURN QUERY EXECUTE v_query
    USING v_prefix, p_bucket_id, p_level, p_limit, p_start_after, p_sort_column_after;
END;
$_$;


ALTER FUNCTION "storage"."search_by_timestamp"("p_prefix" "text", "p_bucket_id" "text", "p_limit" integer, "p_level" integer, "p_start_after" "text", "p_sort_order" "text", "p_sort_column" "text", "p_sort_column_after" "text") OWNER TO "supabase_storage_admin";


CREATE OR REPLACE FUNCTION "storage"."search_v2"("prefix" "text", "bucket_name" "text", "limits" integer DEFAULT 100, "levels" integer DEFAULT 1, "start_after" "text" DEFAULT ''::"text", "sort_order" "text" DEFAULT 'asc'::"text", "sort_column" "text" DEFAULT 'name'::"text", "sort_column_after" "text" DEFAULT ''::"text") RETURNS TABLE("key" "text", "name" "text", "id" "uuid", "updated_at" timestamp with time zone, "created_at" timestamp with time zone, "last_accessed_at" timestamp with time zone, "metadata" "jsonb")
    LANGUAGE "plpgsql" STABLE
    AS $$
DECLARE
    v_sort_col text;
    v_sort_ord text;
    v_limit int;
BEGIN
    -- Cap limit to maximum of 1500 records
    v_limit := LEAST(coalesce(limits, 100), 1500);

    -- Validate and normalize sort_order
    v_sort_ord := lower(coalesce(sort_order, 'asc'));
    IF v_sort_ord NOT IN ('asc', 'desc') THEN
        v_sort_ord := 'asc';
    END IF;

    -- Validate and normalize sort_column
    v_sort_col := lower(coalesce(sort_column, 'name'));
    IF v_sort_col NOT IN ('name', 'updated_at', 'created_at') THEN
        v_sort_col := 'name';
    END IF;

    -- Route to appropriate implementation
    IF v_sort_col = 'name' THEN
        -- Use list_objects_with_delimiter for name sorting (most efficient: O(k * log n))
        RETURN QUERY
        SELECT
            split_part(l.name, '/', levels) AS key,
            l.name AS name,
            l.id,
            l.updated_at,
            l.created_at,
            l.last_accessed_at,
            l.metadata
        FROM storage.list_objects_with_delimiter(
            bucket_name,
            coalesce(prefix, ''),
            '/',
            v_limit,
            start_after,
            '',
            v_sort_ord
        ) l;
    ELSE
        -- Use aggregation approach for timestamp sorting
        -- Not efficient for large datasets but supports correct pagination
        RETURN QUERY SELECT * FROM storage.search_by_timestamp(
            prefix, bucket_name, v_limit, levels, start_after,
            v_sort_ord, v_sort_col, sort_column_after
        );
    END IF;
END;
$$;


ALTER FUNCTION "storage"."search_v2"("prefix" "text", "bucket_name" "text", "limits" integer, "levels" integer, "start_after" "text", "sort_order" "text", "sort_column" "text", "sort_column_after" "text") OWNER TO "supabase_storage_admin";


CREATE OR REPLACE FUNCTION "storage"."update_updated_at_column"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW; 
END;
$$;


ALTER FUNCTION "storage"."update_updated_at_column"() OWNER TO "supabase_storage_admin";

SET default_tablespace = '';

SET default_table_access_method = "heap";


CREATE TABLE IF NOT EXISTS "auth"."audit_log_entries" (
    "instance_id" "uuid",
    "id" "uuid" NOT NULL,
    "payload" json,
    "created_at" timestamp with time zone,
    "ip_address" character varying(64) DEFAULT ''::character varying NOT NULL
);


ALTER TABLE "auth"."audit_log_entries" OWNER TO "supabase_auth_admin";


COMMENT ON TABLE "auth"."audit_log_entries" IS 'Auth: Audit trail for user actions.';



CREATE TABLE IF NOT EXISTS "auth"."custom_oauth_providers" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "provider_type" "text" NOT NULL,
    "identifier" "text" NOT NULL,
    "name" "text" NOT NULL,
    "client_id" "text" NOT NULL,
    "client_secret" "text" NOT NULL,
    "acceptable_client_ids" "text"[] DEFAULT '{}'::"text"[] NOT NULL,
    "scopes" "text"[] DEFAULT '{}'::"text"[] NOT NULL,
    "pkce_enabled" boolean DEFAULT true NOT NULL,
    "attribute_mapping" "jsonb" DEFAULT '{}'::"jsonb" NOT NULL,
    "authorization_params" "jsonb" DEFAULT '{}'::"jsonb" NOT NULL,
    "enabled" boolean DEFAULT true NOT NULL,
    "email_optional" boolean DEFAULT false NOT NULL,
    "issuer" "text",
    "discovery_url" "text",
    "skip_nonce_check" boolean DEFAULT false NOT NULL,
    "cached_discovery" "jsonb",
    "discovery_cached_at" timestamp with time zone,
    "authorization_url" "text",
    "token_url" "text",
    "userinfo_url" "text",
    "jwks_uri" "text",
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    CONSTRAINT "custom_oauth_providers_authorization_url_https" CHECK ((("authorization_url" IS NULL) OR ("authorization_url" ~~ 'https://%'::"text"))),
    CONSTRAINT "custom_oauth_providers_authorization_url_length" CHECK ((("authorization_url" IS NULL) OR ("char_length"("authorization_url") <= 2048))),
    CONSTRAINT "custom_oauth_providers_client_id_length" CHECK ((("char_length"("client_id") >= 1) AND ("char_length"("client_id") <= 512))),
    CONSTRAINT "custom_oauth_providers_discovery_url_length" CHECK ((("discovery_url" IS NULL) OR ("char_length"("discovery_url") <= 2048))),
    CONSTRAINT "custom_oauth_providers_identifier_format" CHECK (("identifier" ~ '^[a-z0-9][a-z0-9:-]{0,48}[a-z0-9]$'::"text")),
    CONSTRAINT "custom_oauth_providers_issuer_length" CHECK ((("issuer" IS NULL) OR (("char_length"("issuer") >= 1) AND ("char_length"("issuer") <= 2048)))),
    CONSTRAINT "custom_oauth_providers_jwks_uri_https" CHECK ((("jwks_uri" IS NULL) OR ("jwks_uri" ~~ 'https://%'::"text"))),
    CONSTRAINT "custom_oauth_providers_jwks_uri_length" CHECK ((("jwks_uri" IS NULL) OR ("char_length"("jwks_uri") <= 2048))),
    CONSTRAINT "custom_oauth_providers_name_length" CHECK ((("char_length"("name") >= 1) AND ("char_length"("name") <= 100))),
    CONSTRAINT "custom_oauth_providers_oauth2_requires_endpoints" CHECK ((("provider_type" <> 'oauth2'::"text") OR (("authorization_url" IS NOT NULL) AND ("token_url" IS NOT NULL) AND ("userinfo_url" IS NOT NULL)))),
    CONSTRAINT "custom_oauth_providers_oidc_discovery_url_https" CHECK ((("provider_type" <> 'oidc'::"text") OR ("discovery_url" IS NULL) OR ("discovery_url" ~~ 'https://%'::"text"))),
    CONSTRAINT "custom_oauth_providers_oidc_issuer_https" CHECK ((("provider_type" <> 'oidc'::"text") OR ("issuer" IS NULL) OR ("issuer" ~~ 'https://%'::"text"))),
    CONSTRAINT "custom_oauth_providers_oidc_requires_issuer" CHECK ((("provider_type" <> 'oidc'::"text") OR ("issuer" IS NOT NULL))),
    CONSTRAINT "custom_oauth_providers_provider_type_check" CHECK (("provider_type" = ANY (ARRAY['oauth2'::"text", 'oidc'::"text"]))),
    CONSTRAINT "custom_oauth_providers_token_url_https" CHECK ((("token_url" IS NULL) OR ("token_url" ~~ 'https://%'::"text"))),
    CONSTRAINT "custom_oauth_providers_token_url_length" CHECK ((("token_url" IS NULL) OR ("char_length"("token_url") <= 2048))),
    CONSTRAINT "custom_oauth_providers_userinfo_url_https" CHECK ((("userinfo_url" IS NULL) OR ("userinfo_url" ~~ 'https://%'::"text"))),
    CONSTRAINT "custom_oauth_providers_userinfo_url_length" CHECK ((("userinfo_url" IS NULL) OR ("char_length"("userinfo_url") <= 2048)))
);


ALTER TABLE "auth"."custom_oauth_providers" OWNER TO "supabase_auth_admin";


CREATE TABLE IF NOT EXISTS "auth"."flow_state" (
    "id" "uuid" NOT NULL,
    "user_id" "uuid",
    "auth_code" "text",
    "code_challenge_method" "auth"."code_challenge_method",
    "code_challenge" "text",
    "provider_type" "text" NOT NULL,
    "provider_access_token" "text",
    "provider_refresh_token" "text",
    "created_at" timestamp with time zone,
    "updated_at" timestamp with time zone,
    "authentication_method" "text" NOT NULL,
    "auth_code_issued_at" timestamp with time zone,
    "invite_token" "text",
    "referrer" "text",
    "oauth_client_state_id" "uuid",
    "linking_target_id" "uuid",
    "email_optional" boolean DEFAULT false NOT NULL
);


ALTER TABLE "auth"."flow_state" OWNER TO "supabase_auth_admin";


COMMENT ON TABLE "auth"."flow_state" IS 'Stores metadata for all OAuth/SSO login flows';



CREATE TABLE IF NOT EXISTS "auth"."identities" (
    "provider_id" "text" NOT NULL,
    "user_id" "uuid" NOT NULL,
    "identity_data" "jsonb" NOT NULL,
    "provider" "text" NOT NULL,
    "last_sign_in_at" timestamp with time zone,
    "created_at" timestamp with time zone,
    "updated_at" timestamp with time zone,
    "email" "text" GENERATED ALWAYS AS ("lower"(("identity_data" ->> 'email'::"text"))) STORED,
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL
);


ALTER TABLE "auth"."identities" OWNER TO "supabase_auth_admin";


COMMENT ON TABLE "auth"."identities" IS 'Auth: Stores identities associated to a user.';



COMMENT ON COLUMN "auth"."identities"."email" IS 'Auth: Email is a generated column that references the optional email property in the identity_data';



CREATE TABLE IF NOT EXISTS "auth"."instances" (
    "id" "uuid" NOT NULL,
    "uuid" "uuid",
    "raw_base_config" "text",
    "created_at" timestamp with time zone,
    "updated_at" timestamp with time zone
);


ALTER TABLE "auth"."instances" OWNER TO "supabase_auth_admin";


COMMENT ON TABLE "auth"."instances" IS 'Auth: Manages users across multiple sites.';



CREATE TABLE IF NOT EXISTS "auth"."mfa_amr_claims" (
    "session_id" "uuid" NOT NULL,
    "created_at" timestamp with time zone NOT NULL,
    "updated_at" timestamp with time zone NOT NULL,
    "authentication_method" "text" NOT NULL,
    "id" "uuid" NOT NULL
);


ALTER TABLE "auth"."mfa_amr_claims" OWNER TO "supabase_auth_admin";


COMMENT ON TABLE "auth"."mfa_amr_claims" IS 'auth: stores authenticator method reference claims for multi factor authentication';



CREATE TABLE IF NOT EXISTS "auth"."mfa_challenges" (
    "id" "uuid" NOT NULL,
    "factor_id" "uuid" NOT NULL,
    "created_at" timestamp with time zone NOT NULL,
    "verified_at" timestamp with time zone,
    "ip_address" "inet" NOT NULL,
    "otp_code" "text",
    "web_authn_session_data" "jsonb"
);


ALTER TABLE "auth"."mfa_challenges" OWNER TO "supabase_auth_admin";


COMMENT ON TABLE "auth"."mfa_challenges" IS 'auth: stores metadata about challenge requests made';



CREATE TABLE IF NOT EXISTS "auth"."mfa_factors" (
    "id" "uuid" NOT NULL,
    "user_id" "uuid" NOT NULL,
    "friendly_name" "text",
    "factor_type" "auth"."factor_type" NOT NULL,
    "status" "auth"."factor_status" NOT NULL,
    "created_at" timestamp with time zone NOT NULL,
    "updated_at" timestamp with time zone NOT NULL,
    "secret" "text",
    "phone" "text",
    "last_challenged_at" timestamp with time zone,
    "web_authn_credential" "jsonb",
    "web_authn_aaguid" "uuid",
    "last_webauthn_challenge_data" "jsonb"
);


ALTER TABLE "auth"."mfa_factors" OWNER TO "supabase_auth_admin";


COMMENT ON TABLE "auth"."mfa_factors" IS 'auth: stores metadata about factors';



COMMENT ON COLUMN "auth"."mfa_factors"."last_webauthn_challenge_data" IS 'Stores the latest WebAuthn challenge data including attestation/assertion for customer verification';



CREATE TABLE IF NOT EXISTS "auth"."oauth_authorizations" (
    "id" "uuid" NOT NULL,
    "authorization_id" "text" NOT NULL,
    "client_id" "uuid" NOT NULL,
    "user_id" "uuid",
    "redirect_uri" "text" NOT NULL,
    "scope" "text" NOT NULL,
    "state" "text",
    "resource" "text",
    "code_challenge" "text",
    "code_challenge_method" "auth"."code_challenge_method",
    "response_type" "auth"."oauth_response_type" DEFAULT 'code'::"auth"."oauth_response_type" NOT NULL,
    "status" "auth"."oauth_authorization_status" DEFAULT 'pending'::"auth"."oauth_authorization_status" NOT NULL,
    "authorization_code" "text",
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "expires_at" timestamp with time zone DEFAULT ("now"() + '00:03:00'::interval) NOT NULL,
    "approved_at" timestamp with time zone,
    "nonce" "text",
    CONSTRAINT "oauth_authorizations_authorization_code_length" CHECK (("char_length"("authorization_code") <= 255)),
    CONSTRAINT "oauth_authorizations_code_challenge_length" CHECK (("char_length"("code_challenge") <= 128)),
    CONSTRAINT "oauth_authorizations_expires_at_future" CHECK (("expires_at" > "created_at")),
    CONSTRAINT "oauth_authorizations_nonce_length" CHECK (("char_length"("nonce") <= 255)),
    CONSTRAINT "oauth_authorizations_redirect_uri_length" CHECK (("char_length"("redirect_uri") <= 2048)),
    CONSTRAINT "oauth_authorizations_resource_length" CHECK (("char_length"("resource") <= 2048)),
    CONSTRAINT "oauth_authorizations_scope_length" CHECK (("char_length"("scope") <= 4096)),
    CONSTRAINT "oauth_authorizations_state_length" CHECK (("char_length"("state") <= 4096))
);


ALTER TABLE "auth"."oauth_authorizations" OWNER TO "supabase_auth_admin";


CREATE TABLE IF NOT EXISTS "auth"."oauth_client_states" (
    "id" "uuid" NOT NULL,
    "provider_type" "text" NOT NULL,
    "code_verifier" "text",
    "created_at" timestamp with time zone NOT NULL
);


ALTER TABLE "auth"."oauth_client_states" OWNER TO "supabase_auth_admin";


COMMENT ON TABLE "auth"."oauth_client_states" IS 'Stores OAuth states for third-party provider authentication flows where Supabase acts as the OAuth client.';



CREATE TABLE IF NOT EXISTS "auth"."oauth_clients" (
    "id" "uuid" NOT NULL,
    "client_secret_hash" "text",
    "registration_type" "auth"."oauth_registration_type" NOT NULL,
    "redirect_uris" "text" NOT NULL,
    "grant_types" "text" NOT NULL,
    "client_name" "text",
    "client_uri" "text",
    "logo_uri" "text",
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "deleted_at" timestamp with time zone,
    "client_type" "auth"."oauth_client_type" DEFAULT 'confidential'::"auth"."oauth_client_type" NOT NULL,
    "token_endpoint_auth_method" "text" NOT NULL,
    CONSTRAINT "oauth_clients_client_name_length" CHECK (("char_length"("client_name") <= 1024)),
    CONSTRAINT "oauth_clients_client_uri_length" CHECK (("char_length"("client_uri") <= 2048)),
    CONSTRAINT "oauth_clients_logo_uri_length" CHECK (("char_length"("logo_uri") <= 2048)),
    CONSTRAINT "oauth_clients_token_endpoint_auth_method_check" CHECK (("token_endpoint_auth_method" = ANY (ARRAY['client_secret_basic'::"text", 'client_secret_post'::"text", 'none'::"text"])))
);


ALTER TABLE "auth"."oauth_clients" OWNER TO "supabase_auth_admin";


CREATE TABLE IF NOT EXISTS "auth"."oauth_consents" (
    "id" "uuid" NOT NULL,
    "user_id" "uuid" NOT NULL,
    "client_id" "uuid" NOT NULL,
    "scopes" "text" NOT NULL,
    "granted_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "revoked_at" timestamp with time zone,
    CONSTRAINT "oauth_consents_revoked_after_granted" CHECK ((("revoked_at" IS NULL) OR ("revoked_at" >= "granted_at"))),
    CONSTRAINT "oauth_consents_scopes_length" CHECK (("char_length"("scopes") <= 2048)),
    CONSTRAINT "oauth_consents_scopes_not_empty" CHECK (("char_length"(TRIM(BOTH FROM "scopes")) > 0))
);


ALTER TABLE "auth"."oauth_consents" OWNER TO "supabase_auth_admin";


CREATE TABLE IF NOT EXISTS "auth"."one_time_tokens" (
    "id" "uuid" NOT NULL,
    "user_id" "uuid" NOT NULL,
    "token_type" "auth"."one_time_token_type" NOT NULL,
    "token_hash" "text" NOT NULL,
    "relates_to" "text" NOT NULL,
    "created_at" timestamp without time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp without time zone DEFAULT "now"() NOT NULL,
    CONSTRAINT "one_time_tokens_token_hash_check" CHECK (("char_length"("token_hash") > 0))
);


ALTER TABLE "auth"."one_time_tokens" OWNER TO "supabase_auth_admin";


CREATE TABLE IF NOT EXISTS "auth"."refresh_tokens" (
    "instance_id" "uuid",
    "id" bigint NOT NULL,
    "token" character varying(255),
    "user_id" character varying(255),
    "revoked" boolean,
    "created_at" timestamp with time zone,
    "updated_at" timestamp with time zone,
    "parent" character varying(255),
    "session_id" "uuid"
);


ALTER TABLE "auth"."refresh_tokens" OWNER TO "supabase_auth_admin";


COMMENT ON TABLE "auth"."refresh_tokens" IS 'Auth: Store of tokens used to refresh JWT tokens once they expire.';



CREATE SEQUENCE IF NOT EXISTS "auth"."refresh_tokens_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE "auth"."refresh_tokens_id_seq" OWNER TO "supabase_auth_admin";


ALTER SEQUENCE "auth"."refresh_tokens_id_seq" OWNED BY "auth"."refresh_tokens"."id";



CREATE TABLE IF NOT EXISTS "auth"."saml_providers" (
    "id" "uuid" NOT NULL,
    "sso_provider_id" "uuid" NOT NULL,
    "entity_id" "text" NOT NULL,
    "metadata_xml" "text" NOT NULL,
    "metadata_url" "text",
    "attribute_mapping" "jsonb",
    "created_at" timestamp with time zone,
    "updated_at" timestamp with time zone,
    "name_id_format" "text",
    CONSTRAINT "entity_id not empty" CHECK (("char_length"("entity_id") > 0)),
    CONSTRAINT "metadata_url not empty" CHECK ((("metadata_url" = NULL::"text") OR ("char_length"("metadata_url") > 0))),
    CONSTRAINT "metadata_xml not empty" CHECK (("char_length"("metadata_xml") > 0))
);


ALTER TABLE "auth"."saml_providers" OWNER TO "supabase_auth_admin";


COMMENT ON TABLE "auth"."saml_providers" IS 'Auth: Manages SAML Identity Provider connections.';



CREATE TABLE IF NOT EXISTS "auth"."saml_relay_states" (
    "id" "uuid" NOT NULL,
    "sso_provider_id" "uuid" NOT NULL,
    "request_id" "text" NOT NULL,
    "for_email" "text",
    "redirect_to" "text",
    "created_at" timestamp with time zone,
    "updated_at" timestamp with time zone,
    "flow_state_id" "uuid",
    CONSTRAINT "request_id not empty" CHECK (("char_length"("request_id") > 0))
);


ALTER TABLE "auth"."saml_relay_states" OWNER TO "supabase_auth_admin";


COMMENT ON TABLE "auth"."saml_relay_states" IS 'Auth: Contains SAML Relay State information for each Service Provider initiated login.';



CREATE TABLE IF NOT EXISTS "auth"."schema_migrations" (
    "version" character varying(255) NOT NULL
);


ALTER TABLE "auth"."schema_migrations" OWNER TO "supabase_auth_admin";


COMMENT ON TABLE "auth"."schema_migrations" IS 'Auth: Manages updates to the auth system.';



CREATE TABLE IF NOT EXISTS "auth"."sessions" (
    "id" "uuid" NOT NULL,
    "user_id" "uuid" NOT NULL,
    "created_at" timestamp with time zone,
    "updated_at" timestamp with time zone,
    "factor_id" "uuid",
    "aal" "auth"."aal_level",
    "not_after" timestamp with time zone,
    "refreshed_at" timestamp without time zone,
    "user_agent" "text",
    "ip" "inet",
    "tag" "text",
    "oauth_client_id" "uuid",
    "refresh_token_hmac_key" "text",
    "refresh_token_counter" bigint,
    "scopes" "text",
    CONSTRAINT "sessions_scopes_length" CHECK (("char_length"("scopes") <= 4096))
);


ALTER TABLE "auth"."sessions" OWNER TO "supabase_auth_admin";


COMMENT ON TABLE "auth"."sessions" IS 'Auth: Stores session data associated to a user.';



COMMENT ON COLUMN "auth"."sessions"."not_after" IS 'Auth: Not after is a nullable column that contains a timestamp after which the session should be regarded as expired.';



COMMENT ON COLUMN "auth"."sessions"."refresh_token_hmac_key" IS 'Holds a HMAC-SHA256 key used to sign refresh tokens for this session.';



COMMENT ON COLUMN "auth"."sessions"."refresh_token_counter" IS 'Holds the ID (counter) of the last issued refresh token.';



CREATE TABLE IF NOT EXISTS "auth"."sso_domains" (
    "id" "uuid" NOT NULL,
    "sso_provider_id" "uuid" NOT NULL,
    "domain" "text" NOT NULL,
    "created_at" timestamp with time zone,
    "updated_at" timestamp with time zone,
    CONSTRAINT "domain not empty" CHECK (("char_length"("domain") > 0))
);


ALTER TABLE "auth"."sso_domains" OWNER TO "supabase_auth_admin";


COMMENT ON TABLE "auth"."sso_domains" IS 'Auth: Manages SSO email address domain mapping to an SSO Identity Provider.';



CREATE TABLE IF NOT EXISTS "auth"."sso_providers" (
    "id" "uuid" NOT NULL,
    "resource_id" "text",
    "created_at" timestamp with time zone,
    "updated_at" timestamp with time zone,
    "disabled" boolean,
    CONSTRAINT "resource_id not empty" CHECK ((("resource_id" = NULL::"text") OR ("char_length"("resource_id") > 0)))
);


ALTER TABLE "auth"."sso_providers" OWNER TO "supabase_auth_admin";


COMMENT ON TABLE "auth"."sso_providers" IS 'Auth: Manages SSO identity provider information; see saml_providers for SAML.';



COMMENT ON COLUMN "auth"."sso_providers"."resource_id" IS 'Auth: Uniquely identifies a SSO provider according to a user-chosen resource ID (case insensitive), useful in infrastructure as code.';



CREATE TABLE IF NOT EXISTS "auth"."users" (
    "instance_id" "uuid",
    "id" "uuid" NOT NULL,
    "aud" character varying(255),
    "role" character varying(255),
    "email" character varying(255),
    "encrypted_password" character varying(255),
    "email_confirmed_at" timestamp with time zone,
    "invited_at" timestamp with time zone,
    "confirmation_token" character varying(255),
    "confirmation_sent_at" timestamp with time zone,
    "recovery_token" character varying(255),
    "recovery_sent_at" timestamp with time zone,
    "email_change_token_new" character varying(255),
    "email_change" character varying(255),
    "email_change_sent_at" timestamp with time zone,
    "last_sign_in_at" timestamp with time zone,
    "raw_app_meta_data" "jsonb",
    "raw_user_meta_data" "jsonb",
    "is_super_admin" boolean,
    "created_at" timestamp with time zone,
    "updated_at" timestamp with time zone,
    "phone" "text" DEFAULT NULL::character varying,
    "phone_confirmed_at" timestamp with time zone,
    "phone_change" "text" DEFAULT ''::character varying,
    "phone_change_token" character varying(255) DEFAULT ''::character varying,
    "phone_change_sent_at" timestamp with time zone,
    "confirmed_at" timestamp with time zone GENERATED ALWAYS AS (LEAST("email_confirmed_at", "phone_confirmed_at")) STORED,
    "email_change_token_current" character varying(255) DEFAULT ''::character varying,
    "email_change_confirm_status" smallint DEFAULT 0,
    "banned_until" timestamp with time zone,
    "reauthentication_token" character varying(255) DEFAULT ''::character varying,
    "reauthentication_sent_at" timestamp with time zone,
    "is_sso_user" boolean DEFAULT false NOT NULL,
    "deleted_at" timestamp with time zone,
    "is_anonymous" boolean DEFAULT false NOT NULL,
    CONSTRAINT "users_email_change_confirm_status_check" CHECK ((("email_change_confirm_status" >= 0) AND ("email_change_confirm_status" <= 2)))
);


ALTER TABLE "auth"."users" OWNER TO "supabase_auth_admin";


COMMENT ON TABLE "auth"."users" IS 'Auth: Stores user login data within a secure schema.';



COMMENT ON COLUMN "auth"."users"."is_sso_user" IS 'Auth: Set this column to true when the account comes from SSO. These accounts can have duplicate emails.';



CREATE TABLE IF NOT EXISTS "auth"."webauthn_challenges" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "user_id" "uuid",
    "challenge_type" "text" NOT NULL,
    "session_data" "jsonb" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "expires_at" timestamp with time zone NOT NULL,
    CONSTRAINT "webauthn_challenges_challenge_type_check" CHECK (("challenge_type" = ANY (ARRAY['signup'::"text", 'registration'::"text", 'authentication'::"text"])))
);


ALTER TABLE "auth"."webauthn_challenges" OWNER TO "supabase_auth_admin";


CREATE TABLE IF NOT EXISTS "auth"."webauthn_credentials" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "user_id" "uuid" NOT NULL,
    "credential_id" "bytea" NOT NULL,
    "public_key" "bytea" NOT NULL,
    "attestation_type" "text" DEFAULT ''::"text" NOT NULL,
    "aaguid" "uuid",
    "sign_count" bigint DEFAULT 0 NOT NULL,
    "transports" "jsonb" DEFAULT '[]'::"jsonb" NOT NULL,
    "backup_eligible" boolean DEFAULT false NOT NULL,
    "backed_up" boolean DEFAULT false NOT NULL,
    "friendly_name" "text" DEFAULT ''::"text" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "last_used_at" timestamp with time zone
);


ALTER TABLE "auth"."webauthn_credentials" OWNER TO "supabase_auth_admin";


CREATE TABLE IF NOT EXISTS "public"."anti_pausa" (
    "id" bigint NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "numero" integer
);


ALTER TABLE "public"."anti_pausa" OWNER TO "postgres";


ALTER TABLE "public"."anti_pausa" ALTER COLUMN "id" ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME "public"."anti_pausa_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);



CREATE TABLE IF NOT EXISTS "public"."aprovacoes_jovens" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "jovem_id" "uuid" NOT NULL,
    "usuario_id" "uuid" NOT NULL,
    "tipo_aprovacao" "text" NOT NULL,
    "observacao" "text",
    "criado_em" timestamp with time zone DEFAULT "now"(),
    "atualizado_em" timestamp with time zone DEFAULT "now"(),
    CONSTRAINT "aprovacoes_jovens_tipo_aprovacao_check" CHECK (("tipo_aprovacao" = ANY (ARRAY['pre_aprovado'::"text", 'aprovado'::"text"])))
);


ALTER TABLE "public"."aprovacoes_jovens" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."avaliacoes" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "jovem_id" "uuid",
    "user_id" "uuid",
    "espirito" "public"."intellimen_espirito_enum",
    "caractere" "public"."intellimen_caractere_enum",
    "disposicao" "public"."intellimen_disposicao_enum",
    "avaliacao_texto" "text",
    "nota" integer,
    "criado_em" timestamp with time zone DEFAULT "now"(),
    "data" timestamp without time zone DEFAULT "now"(),
    CONSTRAINT "avaliacoes_nota_check" CHECK ((("nota" >= 1) AND ("nota" <= 10)))
);


ALTER TABLE "public"."avaliacoes" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."blocos" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "estado_id" "uuid",
    "nome" "text" NOT NULL
);


ALTER TABLE "public"."blocos" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."configuracoes_sistema" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "chave" character varying(100) NOT NULL,
    "valor" "jsonb" NOT NULL,
    "descricao" "text",
    "categoria" character varying(50) DEFAULT 'geral'::character varying,
    "criado_em" timestamp with time zone DEFAULT "now"(),
    "atualizado_em" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."configuracoes_sistema" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."dados_nucleo" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "jovem_id" "uuid" NOT NULL,
    "faz_nucleo" boolean,
    "ja_fez_nucleo" boolean,
    "dias_semana" "jsonb",
    "ha_quanto_tempo" "text",
    "foi_voce_que_iniciou" boolean,
    "media_pessoas" integer,
    "foto_1" "text",
    "foto_2" "text",
    "foto_3" "text",
    "foto_4" "text",
    "foto_5" "text",
    "video_link" "text",
    "video_plataforma" "text",
    "tem_obreiros" boolean,
    "quantos_obreiros" integer,
    "alguem_ajuda" boolean,
    "quem_ajuda" "text",
    "quantas_pessoas_vao_igreja" integer,
    "maior_experiencia" "text",
    "observacao_geral" "text",
    "criado_em" timestamp with time zone DEFAULT "now"(),
    "atualizado_em" timestamp with time zone DEFAULT "now"(),
    "criado_por" "uuid",
    "atualizado_por" "uuid"
);


ALTER TABLE "public"."dados_nucleo" OWNER TO "postgres";


COMMENT ON TABLE "public"."dados_nucleo" IS 'Tabela para armazenar dados sobre núcleos de oração dos jovens';



COMMENT ON COLUMN "public"."dados_nucleo"."jovem_id" IS 'ID do jovem relacionado';



COMMENT ON COLUMN "public"."dados_nucleo"."faz_nucleo" IS 'Se o jovem faz núcleo atualmente';



COMMENT ON COLUMN "public"."dados_nucleo"."ja_fez_nucleo" IS 'Se o jovem já fez núcleo no passado';



COMMENT ON COLUMN "public"."dados_nucleo"."dias_semana" IS 'Array JSON com os dias da semana que o núcleo acontece';



COMMENT ON COLUMN "public"."dados_nucleo"."ha_quanto_tempo" IS 'Há quanto tempo faz núcleo';



COMMENT ON COLUMN "public"."dados_nucleo"."foi_voce_que_iniciou" IS 'Se foi o jovem que iniciou o núcleo';



COMMENT ON COLUMN "public"."dados_nucleo"."media_pessoas" IS 'Média de pessoas que participam do núcleo';



COMMENT ON COLUMN "public"."dados_nucleo"."foto_1" IS 'URL da foto 1 do núcleo';



COMMENT ON COLUMN "public"."dados_nucleo"."foto_2" IS 'URL da foto 2 do núcleo';



COMMENT ON COLUMN "public"."dados_nucleo"."foto_3" IS 'URL da foto 3 do núcleo';



COMMENT ON COLUMN "public"."dados_nucleo"."foto_4" IS 'URL da foto 4 do núcleo';



COMMENT ON COLUMN "public"."dados_nucleo"."foto_5" IS 'URL da foto 5 do núcleo';



COMMENT ON COLUMN "public"."dados_nucleo"."video_link" IS 'Link do vídeo do núcleo';



COMMENT ON COLUMN "public"."dados_nucleo"."video_plataforma" IS 'Plataforma do vídeo (youtube, google_drive, instagram, facebook)';



COMMENT ON COLUMN "public"."dados_nucleo"."tem_obreiros" IS 'Se tem obreiros no núcleo';



COMMENT ON COLUMN "public"."dados_nucleo"."quantos_obreiros" IS 'Quantos obreiros tem no núcleo';



COMMENT ON COLUMN "public"."dados_nucleo"."alguem_ajuda" IS 'Se alguém ajuda no núcleo';



COMMENT ON COLUMN "public"."dados_nucleo"."quem_ajuda" IS 'Quem ajuda no núcleo';



COMMENT ON COLUMN "public"."dados_nucleo"."quantas_pessoas_vao_igreja" IS 'Quantas pessoas do núcleo vão à igreja';



COMMENT ON COLUMN "public"."dados_nucleo"."maior_experiencia" IS 'Maior experiência no núcleo';



COMMENT ON COLUMN "public"."dados_nucleo"."observacao_geral" IS 'Observação geral sobre o núcleo';



CREATE TABLE IF NOT EXISTS "public"."dados_viagem" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "jovem_id" "uuid" NOT NULL,
    "edicao_id" "uuid" NOT NULL,
    "pagou_despesas" boolean DEFAULT false NOT NULL,
    "comprovante_pagamento" "text",
    "data_passagem_ida" timestamp with time zone,
    "comprovante_passagem_ida" "text",
    "data_passagem_volta" timestamp with time zone,
    "comprovante_passagem_volta" "text",
    "data_cadastro" timestamp with time zone DEFAULT "now"() NOT NULL,
    "atualizado_em" timestamp with time zone DEFAULT "now"() NOT NULL,
    "usuario_id" "uuid",
    "como_pagou_despesas" "text",
    "como_pagou_passagens" "text",
    "como_conseguiu_valor" "text",
    "alguem_ajudou_pagar" boolean DEFAULT false,
    "quem_ajudou_pagar" "text"
);


ALTER TABLE "public"."dados_viagem" OWNER TO "postgres";


COMMENT ON COLUMN "public"."dados_viagem"."como_pagou_despesas" IS 'Como o jovem pagou as despesas';



COMMENT ON COLUMN "public"."dados_viagem"."como_pagou_passagens" IS 'Como o jovem pagou as passagens';



COMMENT ON COLUMN "public"."dados_viagem"."como_conseguiu_valor" IS 'Como o jovem conseguiu o valor para pagar';



COMMENT ON COLUMN "public"."dados_viagem"."alguem_ajudou_pagar" IS 'Indica se alguém ajudou o jovem a pagar';



COMMENT ON COLUMN "public"."dados_viagem"."quem_ajudou_pagar" IS 'Nome de quem ajudou o jovem a pagar (se alguem_ajudou_pagar = true)';



CREATE TABLE IF NOT EXISTS "public"."edicoes" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "numero" integer NOT NULL,
    "nome" "text" NOT NULL,
    "data_inicio" "date",
    "data_fim" "date",
    "ativa" boolean DEFAULT true,
    "criado_em" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."edicoes" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."estados" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "nome" "text" NOT NULL,
    "sigla" "text" NOT NULL,
    "bandeira" "text"
);


ALTER TABLE "public"."estados" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."igrejas" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "regiao_id" "uuid",
    "nome" "text" NOT NULL,
    "endereco" "text"
);


ALTER TABLE "public"."igrejas" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."jovens" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "estado_id" "uuid",
    "bloco_id" "uuid",
    "regiao_id" "uuid",
    "igreja_id" "uuid",
    "edicao" "text" NOT NULL,
    "foto" "text",
    "nome_completo" "text" NOT NULL,
    "whatsapp" "text",
    "data_nasc" "date" NOT NULL,
    "data_cadastro" timestamp with time zone DEFAULT "now"(),
    "estado_civil" "text",
    "namora" boolean,
    "tem_filho" boolean,
    "trabalha" boolean,
    "local_trabalho" "text",
    "escolaridade" "text",
    "formacao" "text",
    "tem_dividas" boolean,
    "tempo_igreja" "text",
    "batizado_aguas" boolean,
    "data_batismo_aguas" "date",
    "batizado_es" boolean,
    "data_batismo_es" "date",
    "condicao" "text",
    "tempo_condicao" "text",
    "responsabilidade_igreja" "text",
    "disposto_servir" boolean,
    "ja_obra_altar" boolean,
    "ja_obreiro" boolean,
    "ja_colaborador" boolean,
    "afastado" boolean,
    "data_afastamento" "date",
    "motivo_afastamento" "text",
    "data_retorno" "date",
    "pais_na_igreja" boolean,
    "observacao_pais" "text",
    "familiares_igreja" boolean,
    "deseja_altar" boolean,
    "observacao" "text",
    "testemunho" "text",
    "instagram" "text",
    "facebook" "text",
    "tiktok" "text",
    "obs_redes" "text",
    "aprovado" "public"."intellimen_aprovado_enum" DEFAULT 'null'::"public"."intellimen_aprovado_enum",
    "pastor_que_indicou" "text",
    "cresceu_na_igreja" boolean,
    "experiencia_altar" boolean,
    "foi_obreiro" boolean,
    "foi_colaborador" boolean,
    "afastou" boolean,
    "quando_afastou" "date",
    "motivo_afastou" "text",
    "quando_voltou" "date",
    "pais_sao_igreja" boolean,
    "obs_pais" "text",
    "observacao_text" "text",
    "testemunho_text" "text",
    "edicao_id" "uuid",
    "idade" integer,
    "sexo" "text",
    "observacao_redes" "text",
    "formado_intellimen" boolean DEFAULT false,
    "fazendo_desafios" boolean DEFAULT false,
    "qual_desafio" "text",
    "valor_divida" numeric(10,2),
    "usuario_id" "uuid",
    "condicao_campus" "text",
    "id_usuario_jovem" "uuid",
    "descricao_curta" "text",
    CONSTRAINT "descricao_curta_max_length" CHECK (("length"("descricao_curta") <= 144))
);

ALTER TABLE ONLY "public"."jovens" FORCE ROW LEVEL SECURITY;


ALTER TABLE "public"."jovens" OWNER TO "postgres";


COMMENT ON COLUMN "public"."jovens"."formado_intellimen" IS 'Indica se o jovem é formado no IntelliMen';



COMMENT ON COLUMN "public"."jovens"."fazendo_desafios" IS 'Indica se o jovem está fazendo os desafios do IntelliMen';



COMMENT ON COLUMN "public"."jovens"."qual_desafio" IS 'Qual desafio específico o jovem está fazendo (ex: Desafio #12)';



COMMENT ON COLUMN "public"."jovens"."valor_divida" IS 'Valor da dívida do jovem (apenas se tem_dividas = true)';



COMMENT ON COLUMN "public"."jovens"."condicao_campus" IS 'Condição do jovem quando foi para o Campus (para acompanhar evolução)';



COMMENT ON COLUMN "public"."jovens"."descricao_curta" IS 'Descrição curta do jovem para exibição nos cards do relatório (máximo 144 caracteres)';



CREATE TABLE IF NOT EXISTS "public"."jovens_usuarios_associacoes" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "jovem_id" "uuid" NOT NULL,
    "usuario_id" "uuid" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "created_by" "uuid"
);


ALTER TABLE "public"."jovens_usuarios_associacoes" OWNER TO "postgres";


CREATE OR REPLACE VIEW "public"."jovens_view" AS
 SELECT "id",
    "estado_id",
    "bloco_id",
    "regiao_id",
    "igreja_id",
    "edicao",
    "foto",
    "nome_completo",
    "whatsapp" AS "numero_whatsapp",
    "data_nasc",
    "data_cadastro",
    "estado_civil",
    "namora",
    "tem_filho",
    "trabalha",
    "local_trabalho",
    "escolaridade",
    "formacao",
    "tem_dividas",
    "tempo_igreja",
    "batizado_aguas",
    "data_batismo_aguas",
    "batizado_es",
    "data_batismo_es",
    "condicao",
    "tempo_condicao",
    "responsabilidade_igreja",
    "disposto_servir",
    "ja_obra_altar",
    "ja_obreiro",
    "ja_colaborador",
    "afastado",
    "data_afastamento",
    "motivo_afastamento",
    "data_retorno",
    "pais_na_igreja",
    "observacao_pais",
    "familiares_igreja",
    "deseja_altar",
    "observacao",
    "testemunho",
    "instagram" AS "link_instagram",
    "facebook" AS "link_facebook",
    "tiktok" AS "link_tiktok",
    "obs_redes" AS "observacao_redes",
    "aprovado",
    ("date_part"('year'::"text", "age"(("data_nasc")::timestamp with time zone)))::integer AS "idade"
   FROM "public"."jovens" "j";


ALTER VIEW "public"."jovens_view" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."logs_auditoria" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "usuario_id" "uuid",
    "acao" character varying(100) NOT NULL,
    "detalhe" "text" NOT NULL,
    "dados_antigos" "jsonb",
    "dados_novos" "jsonb",
    "ip_address" "inet",
    "user_agent" "text",
    "criado_em" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."logs_auditoria" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."logs_historico" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "jovem_id" "uuid",
    "user_id" "uuid",
    "acao" "text" NOT NULL,
    "detalhe" "text",
    "dados_anteriores" "jsonb",
    "dados_novos" "jsonb",
    "created_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."logs_historico" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."namorados" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "jovem_id" "uuid" NOT NULL,
    "nome" "text",
    "foto" "text",
    "idade" integer,
    "tempo_obra" "text",
    "tempo_namoro" "text",
    "como_se_conheceram" "text",
    "quanto_tempo_se_conhece" "text",
    "onde_esta_atualmente" "text",
    "atribuicao_atual" "text",
    "observacao_namoro" "text",
    "criado_em" timestamp with time zone DEFAULT "now"(),
    "atualizado_em" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."namorados" OWNER TO "postgres";


COMMENT ON TABLE "public"."namorados" IS 'Dados do namorado (pastor) da jovem do Godllywood Campus';



COMMENT ON COLUMN "public"."namorados"."nome" IS 'Nome do namorado';



COMMENT ON COLUMN "public"."namorados"."foto" IS 'URL da foto do namorado (Storage)';



COMMENT ON COLUMN "public"."namorados"."idade" IS 'Idade do namorado';



COMMENT ON COLUMN "public"."namorados"."tempo_obra" IS 'Tempo de obra';



COMMENT ON COLUMN "public"."namorados"."tempo_namoro" IS 'Tempo de namoro';



COMMENT ON COLUMN "public"."namorados"."como_se_conheceram" IS 'Como se conheceram';



COMMENT ON COLUMN "public"."namorados"."quanto_tempo_se_conhece" IS 'Há quanto tempo se conhecem';



COMMENT ON COLUMN "public"."namorados"."onde_esta_atualmente" IS 'Onde está atualmente';



COMMENT ON COLUMN "public"."namorados"."atribuicao_atual" IS 'Atribuição atual (pastor, etc.)';



COMMENT ON COLUMN "public"."namorados"."observacao_namoro" IS 'Observação sobre o namoro';



CREATE TABLE IF NOT EXISTS "public"."notificacoes" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "tipo" character varying(50) NOT NULL,
    "titulo" character varying(255) NOT NULL,
    "mensagem" "text" NOT NULL,
    "destinatario_id" "uuid" NOT NULL,
    "remetente_id" "uuid",
    "jovem_id" "uuid",
    "acao_url" "text",
    "lida" boolean DEFAULT false,
    "lida_em" timestamp with time zone,
    "criado_em" timestamp with time zone DEFAULT "now"(),
    "atualizado_em" timestamp with time zone DEFAULT "now"(),
    CONSTRAINT "notificacoes_tipo_check" CHECK ((("tipo")::"text" = ANY (ARRAY[('cadastro'::character varying)::"text", ('avaliacao'::character varying)::"text", ('aprovacao'::character varying)::"text", ('transferencia'::character varying)::"text", ('sistema'::character varying)::"text"])))
);


ALTER TABLE "public"."notificacoes" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."regioes" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "bloco_id" "uuid",
    "nome" "text" NOT NULL
);


ALTER TABLE "public"."regioes" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."roles" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "slug" "text" NOT NULL,
    "nome" "text" NOT NULL,
    "descricao" "text",
    "nivel_hierarquico" integer NOT NULL,
    "criado_em" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."roles" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."sessoes_usuario" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "usuario_id" "uuid" NOT NULL,
    "token_hash" character varying(255) NOT NULL,
    "ip_address" "inet",
    "user_agent" "text",
    "ativo" boolean DEFAULT true,
    "expira_em" timestamp with time zone NOT NULL,
    "criado_em" timestamp with time zone DEFAULT "now"(),
    "atualizado_em" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."sessoes_usuario" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."user_roles" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "user_id" "uuid",
    "role_id" "uuid",
    "estado_id" "uuid",
    "bloco_id" "uuid",
    "regiao_id" "uuid",
    "igreja_id" "uuid",
    "ativo" boolean DEFAULT true,
    "criado_em" timestamp with time zone DEFAULT "now"(),
    "criado_por" "uuid"
);


ALTER TABLE "public"."user_roles" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."usuarios" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "id_auth" "uuid",
    "foto" "text",
    "nome" "text" NOT NULL,
    "sexo" "text",
    "nivel" "text" NOT NULL,
    "estado_id" "uuid",
    "bloco_id" "uuid",
    "regiao_id" "uuid",
    "igreja_id" "uuid",
    "criado_em" timestamp with time zone DEFAULT "now"(),
    "email" "text",
    "estado_bandeira" "text",
    "ativo" boolean DEFAULT true,
    "ultimo_acesso" timestamp with time zone,
    CONSTRAINT "usuarios_sexo_check" CHECK (("sexo" = ANY (ARRAY['masculino'::"text", 'feminino'::"text"])))
);


ALTER TABLE "public"."usuarios" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "storage"."buckets" (
    "id" "text" NOT NULL,
    "name" "text" NOT NULL,
    "owner" "uuid",
    "created_at" timestamp with time zone DEFAULT "now"(),
    "updated_at" timestamp with time zone DEFAULT "now"(),
    "public" boolean DEFAULT false,
    "avif_autodetection" boolean DEFAULT false,
    "file_size_limit" bigint,
    "allowed_mime_types" "text"[],
    "owner_id" "text",
    "type" "storage"."buckettype" DEFAULT 'STANDARD'::"storage"."buckettype" NOT NULL
);


ALTER TABLE "storage"."buckets" OWNER TO "supabase_storage_admin";


COMMENT ON COLUMN "storage"."buckets"."owner" IS 'Field is deprecated, use owner_id instead';



CREATE TABLE IF NOT EXISTS "storage"."buckets_analytics" (
    "name" "text" NOT NULL,
    "type" "storage"."buckettype" DEFAULT 'ANALYTICS'::"storage"."buckettype" NOT NULL,
    "format" "text" DEFAULT 'ICEBERG'::"text" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "deleted_at" timestamp with time zone
);


ALTER TABLE "storage"."buckets_analytics" OWNER TO "supabase_storage_admin";


CREATE TABLE IF NOT EXISTS "storage"."buckets_vectors" (
    "id" "text" NOT NULL,
    "type" "storage"."buckettype" DEFAULT 'VECTOR'::"storage"."buckettype" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "storage"."buckets_vectors" OWNER TO "supabase_storage_admin";


CREATE TABLE IF NOT EXISTS "storage"."migrations" (
    "id" integer NOT NULL,
    "name" character varying(100) NOT NULL,
    "hash" character varying(40) NOT NULL,
    "executed_at" timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE "storage"."migrations" OWNER TO "supabase_storage_admin";


CREATE TABLE IF NOT EXISTS "storage"."objects" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "bucket_id" "text",
    "name" "text",
    "owner" "uuid",
    "created_at" timestamp with time zone DEFAULT "now"(),
    "updated_at" timestamp with time zone DEFAULT "now"(),
    "last_accessed_at" timestamp with time zone DEFAULT "now"(),
    "metadata" "jsonb",
    "path_tokens" "text"[] GENERATED ALWAYS AS ("string_to_array"("name", '/'::"text")) STORED,
    "version" "text",
    "owner_id" "text",
    "user_metadata" "jsonb"
);


ALTER TABLE "storage"."objects" OWNER TO "supabase_storage_admin";


COMMENT ON COLUMN "storage"."objects"."owner" IS 'Field is deprecated, use owner_id instead';



CREATE TABLE IF NOT EXISTS "storage"."s3_multipart_uploads" (
    "id" "text" NOT NULL,
    "in_progress_size" bigint DEFAULT 0 NOT NULL,
    "upload_signature" "text" NOT NULL,
    "bucket_id" "text" NOT NULL,
    "key" "text" NOT NULL COLLATE "pg_catalog"."C",
    "version" "text" NOT NULL,
    "owner_id" "text",
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "user_metadata" "jsonb",
    "metadata" "jsonb"
);


ALTER TABLE "storage"."s3_multipart_uploads" OWNER TO "supabase_storage_admin";


CREATE TABLE IF NOT EXISTS "storage"."s3_multipart_uploads_parts" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "upload_id" "text" NOT NULL,
    "size" bigint DEFAULT 0 NOT NULL,
    "part_number" integer NOT NULL,
    "bucket_id" "text" NOT NULL,
    "key" "text" NOT NULL COLLATE "pg_catalog"."C",
    "etag" "text" NOT NULL,
    "owner_id" "text",
    "version" "text" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "storage"."s3_multipart_uploads_parts" OWNER TO "supabase_storage_admin";


CREATE TABLE IF NOT EXISTS "storage"."vector_indexes" (
    "id" "text" DEFAULT "gen_random_uuid"() NOT NULL,
    "name" "text" NOT NULL COLLATE "pg_catalog"."C",
    "bucket_id" "text" NOT NULL,
    "data_type" "text" NOT NULL,
    "dimension" integer NOT NULL,
    "distance_metric" "text" NOT NULL,
    "metadata_configuration" "jsonb",
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "storage"."vector_indexes" OWNER TO "supabase_storage_admin";


ALTER TABLE ONLY "auth"."refresh_tokens" ALTER COLUMN "id" SET DEFAULT "nextval"('"auth"."refresh_tokens_id_seq"'::"regclass");



ALTER TABLE ONLY "auth"."mfa_amr_claims"
    ADD CONSTRAINT "amr_id_pk" PRIMARY KEY ("id");



ALTER TABLE ONLY "auth"."audit_log_entries"
    ADD CONSTRAINT "audit_log_entries_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "auth"."custom_oauth_providers"
    ADD CONSTRAINT "custom_oauth_providers_identifier_key" UNIQUE ("identifier");



ALTER TABLE ONLY "auth"."custom_oauth_providers"
    ADD CONSTRAINT "custom_oauth_providers_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "auth"."flow_state"
    ADD CONSTRAINT "flow_state_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "auth"."identities"
    ADD CONSTRAINT "identities_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "auth"."identities"
    ADD CONSTRAINT "identities_provider_id_provider_unique" UNIQUE ("provider_id", "provider");



ALTER TABLE ONLY "auth"."instances"
    ADD CONSTRAINT "instances_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "auth"."mfa_amr_claims"
    ADD CONSTRAINT "mfa_amr_claims_session_id_authentication_method_pkey" UNIQUE ("session_id", "authentication_method");



ALTER TABLE ONLY "auth"."mfa_challenges"
    ADD CONSTRAINT "mfa_challenges_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "auth"."mfa_factors"
    ADD CONSTRAINT "mfa_factors_last_challenged_at_key" UNIQUE ("last_challenged_at");



ALTER TABLE ONLY "auth"."mfa_factors"
    ADD CONSTRAINT "mfa_factors_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "auth"."oauth_authorizations"
    ADD CONSTRAINT "oauth_authorizations_authorization_code_key" UNIQUE ("authorization_code");



ALTER TABLE ONLY "auth"."oauth_authorizations"
    ADD CONSTRAINT "oauth_authorizations_authorization_id_key" UNIQUE ("authorization_id");



ALTER TABLE ONLY "auth"."oauth_authorizations"
    ADD CONSTRAINT "oauth_authorizations_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "auth"."oauth_client_states"
    ADD CONSTRAINT "oauth_client_states_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "auth"."oauth_clients"
    ADD CONSTRAINT "oauth_clients_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "auth"."oauth_consents"
    ADD CONSTRAINT "oauth_consents_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "auth"."oauth_consents"
    ADD CONSTRAINT "oauth_consents_user_client_unique" UNIQUE ("user_id", "client_id");



ALTER TABLE ONLY "auth"."one_time_tokens"
    ADD CONSTRAINT "one_time_tokens_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "auth"."refresh_tokens"
    ADD CONSTRAINT "refresh_tokens_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "auth"."refresh_tokens"
    ADD CONSTRAINT "refresh_tokens_token_unique" UNIQUE ("token");



ALTER TABLE ONLY "auth"."saml_providers"
    ADD CONSTRAINT "saml_providers_entity_id_key" UNIQUE ("entity_id");



ALTER TABLE ONLY "auth"."saml_providers"
    ADD CONSTRAINT "saml_providers_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "auth"."saml_relay_states"
    ADD CONSTRAINT "saml_relay_states_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "auth"."schema_migrations"
    ADD CONSTRAINT "schema_migrations_pkey" PRIMARY KEY ("version");



ALTER TABLE ONLY "auth"."sessions"
    ADD CONSTRAINT "sessions_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "auth"."sso_domains"
    ADD CONSTRAINT "sso_domains_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "auth"."sso_providers"
    ADD CONSTRAINT "sso_providers_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "auth"."users"
    ADD CONSTRAINT "users_phone_key" UNIQUE ("phone");



ALTER TABLE ONLY "auth"."users"
    ADD CONSTRAINT "users_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "auth"."webauthn_challenges"
    ADD CONSTRAINT "webauthn_challenges_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "auth"."webauthn_credentials"
    ADD CONSTRAINT "webauthn_credentials_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."anti_pausa"
    ADD CONSTRAINT "anti_pausa_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."aprovacoes_jovens"
    ADD CONSTRAINT "aprovacoes_jovens_jovem_id_usuario_id_tipo_aprovacao_key" UNIQUE ("jovem_id", "usuario_id", "tipo_aprovacao");



ALTER TABLE ONLY "public"."aprovacoes_jovens"
    ADD CONSTRAINT "aprovacoes_jovens_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."avaliacoes"
    ADD CONSTRAINT "avaliacoes_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."blocos"
    ADD CONSTRAINT "blocos_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."configuracoes_sistema"
    ADD CONSTRAINT "configuracoes_sistema_chave_key" UNIQUE ("chave");



ALTER TABLE ONLY "public"."configuracoes_sistema"
    ADD CONSTRAINT "configuracoes_sistema_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."dados_nucleo"
    ADD CONSTRAINT "dados_nucleo_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."dados_viagem"
    ADD CONSTRAINT "dados_viagem_jovem_id_edicao_id_key" UNIQUE ("jovem_id", "edicao_id");



ALTER TABLE ONLY "public"."dados_viagem"
    ADD CONSTRAINT "dados_viagem_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."edicoes"
    ADD CONSTRAINT "edicoes_numero_key" UNIQUE ("numero");



ALTER TABLE ONLY "public"."edicoes"
    ADD CONSTRAINT "edicoes_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."estados"
    ADD CONSTRAINT "estados_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."igrejas"
    ADD CONSTRAINT "igrejas_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."jovens"
    ADD CONSTRAINT "jovens_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."jovens_usuarios_associacoes"
    ADD CONSTRAINT "jovens_usuarios_associacoes_jovem_id_usuario_id_key" UNIQUE ("jovem_id", "usuario_id");



ALTER TABLE ONLY "public"."jovens_usuarios_associacoes"
    ADD CONSTRAINT "jovens_usuarios_associacoes_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."logs_auditoria"
    ADD CONSTRAINT "logs_auditoria_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."logs_historico"
    ADD CONSTRAINT "logs_historico_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."namorados"
    ADD CONSTRAINT "namorados_jovem_id_unique" UNIQUE ("jovem_id");



ALTER TABLE ONLY "public"."namorados"
    ADD CONSTRAINT "namorados_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."notificacoes"
    ADD CONSTRAINT "notificacoes_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."regioes"
    ADD CONSTRAINT "regioes_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."roles"
    ADD CONSTRAINT "roles_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."roles"
    ADD CONSTRAINT "roles_slug_key" UNIQUE ("slug");



ALTER TABLE ONLY "public"."sessoes_usuario"
    ADD CONSTRAINT "sessoes_usuario_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."aprovacoes_jovens"
    ADD CONSTRAINT "unique_aprovacao_por_usuario_jovem_tipo" UNIQUE ("jovem_id", "usuario_id", "tipo_aprovacao");



ALTER TABLE ONLY "public"."user_roles"
    ADD CONSTRAINT "user_roles_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."user_roles"
    ADD CONSTRAINT "user_roles_user_id_role_id_estado_id_bloco_id_regiao_id_igr_key" UNIQUE ("user_id", "role_id", "estado_id", "bloco_id", "regiao_id", "igreja_id");



ALTER TABLE ONLY "public"."usuarios"
    ADD CONSTRAINT "usuarios_id_auth_key" UNIQUE ("id_auth");



ALTER TABLE ONLY "public"."usuarios"
    ADD CONSTRAINT "usuarios_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "storage"."buckets_analytics"
    ADD CONSTRAINT "buckets_analytics_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "storage"."buckets"
    ADD CONSTRAINT "buckets_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "storage"."buckets_vectors"
    ADD CONSTRAINT "buckets_vectors_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "storage"."migrations"
    ADD CONSTRAINT "migrations_name_key" UNIQUE ("name");



ALTER TABLE ONLY "storage"."migrations"
    ADD CONSTRAINT "migrations_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "storage"."objects"
    ADD CONSTRAINT "objects_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "storage"."s3_multipart_uploads_parts"
    ADD CONSTRAINT "s3_multipart_uploads_parts_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "storage"."s3_multipart_uploads"
    ADD CONSTRAINT "s3_multipart_uploads_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "storage"."vector_indexes"
    ADD CONSTRAINT "vector_indexes_pkey" PRIMARY KEY ("id");



CREATE INDEX "audit_logs_instance_id_idx" ON "auth"."audit_log_entries" USING "btree" ("instance_id");



CREATE UNIQUE INDEX "confirmation_token_idx" ON "auth"."users" USING "btree" ("confirmation_token") WHERE (("confirmation_token")::"text" !~ '^[0-9 ]*$'::"text");



CREATE INDEX "custom_oauth_providers_created_at_idx" ON "auth"."custom_oauth_providers" USING "btree" ("created_at");



CREATE INDEX "custom_oauth_providers_enabled_idx" ON "auth"."custom_oauth_providers" USING "btree" ("enabled");



CREATE INDEX "custom_oauth_providers_identifier_idx" ON "auth"."custom_oauth_providers" USING "btree" ("identifier");



CREATE INDEX "custom_oauth_providers_provider_type_idx" ON "auth"."custom_oauth_providers" USING "btree" ("provider_type");



CREATE UNIQUE INDEX "email_change_token_current_idx" ON "auth"."users" USING "btree" ("email_change_token_current") WHERE (("email_change_token_current")::"text" !~ '^[0-9 ]*$'::"text");



CREATE UNIQUE INDEX "email_change_token_new_idx" ON "auth"."users" USING "btree" ("email_change_token_new") WHERE (("email_change_token_new")::"text" !~ '^[0-9 ]*$'::"text");



CREATE INDEX "factor_id_created_at_idx" ON "auth"."mfa_factors" USING "btree" ("user_id", "created_at");



CREATE INDEX "flow_state_created_at_idx" ON "auth"."flow_state" USING "btree" ("created_at" DESC);



CREATE INDEX "identities_email_idx" ON "auth"."identities" USING "btree" ("email" "text_pattern_ops");



COMMENT ON INDEX "auth"."identities_email_idx" IS 'Auth: Ensures indexed queries on the email column';



CREATE INDEX "identities_user_id_idx" ON "auth"."identities" USING "btree" ("user_id");



CREATE INDEX "idx_auth_code" ON "auth"."flow_state" USING "btree" ("auth_code");



CREATE INDEX "idx_oauth_client_states_created_at" ON "auth"."oauth_client_states" USING "btree" ("created_at");



CREATE INDEX "idx_user_id_auth_method" ON "auth"."flow_state" USING "btree" ("user_id", "authentication_method");



CREATE INDEX "mfa_challenge_created_at_idx" ON "auth"."mfa_challenges" USING "btree" ("created_at" DESC);



CREATE UNIQUE INDEX "mfa_factors_user_friendly_name_unique" ON "auth"."mfa_factors" USING "btree" ("friendly_name", "user_id") WHERE (TRIM(BOTH FROM "friendly_name") <> ''::"text");



CREATE INDEX "mfa_factors_user_id_idx" ON "auth"."mfa_factors" USING "btree" ("user_id");



CREATE INDEX "oauth_auth_pending_exp_idx" ON "auth"."oauth_authorizations" USING "btree" ("expires_at") WHERE ("status" = 'pending'::"auth"."oauth_authorization_status");



CREATE INDEX "oauth_clients_deleted_at_idx" ON "auth"."oauth_clients" USING "btree" ("deleted_at");



CREATE INDEX "oauth_consents_active_client_idx" ON "auth"."oauth_consents" USING "btree" ("client_id") WHERE ("revoked_at" IS NULL);



CREATE INDEX "oauth_consents_active_user_client_idx" ON "auth"."oauth_consents" USING "btree" ("user_id", "client_id") WHERE ("revoked_at" IS NULL);



CREATE INDEX "oauth_consents_user_order_idx" ON "auth"."oauth_consents" USING "btree" ("user_id", "granted_at" DESC);



CREATE INDEX "one_time_tokens_relates_to_hash_idx" ON "auth"."one_time_tokens" USING "hash" ("relates_to");



CREATE INDEX "one_time_tokens_token_hash_hash_idx" ON "auth"."one_time_tokens" USING "hash" ("token_hash");



CREATE UNIQUE INDEX "one_time_tokens_user_id_token_type_key" ON "auth"."one_time_tokens" USING "btree" ("user_id", "token_type");



CREATE UNIQUE INDEX "reauthentication_token_idx" ON "auth"."users" USING "btree" ("reauthentication_token") WHERE (("reauthentication_token")::"text" !~ '^[0-9 ]*$'::"text");



CREATE UNIQUE INDEX "recovery_token_idx" ON "auth"."users" USING "btree" ("recovery_token") WHERE (("recovery_token")::"text" !~ '^[0-9 ]*$'::"text");



CREATE INDEX "refresh_tokens_instance_id_idx" ON "auth"."refresh_tokens" USING "btree" ("instance_id");



CREATE INDEX "refresh_tokens_instance_id_user_id_idx" ON "auth"."refresh_tokens" USING "btree" ("instance_id", "user_id");



CREATE INDEX "refresh_tokens_parent_idx" ON "auth"."refresh_tokens" USING "btree" ("parent");



CREATE INDEX "refresh_tokens_session_id_revoked_idx" ON "auth"."refresh_tokens" USING "btree" ("session_id", "revoked");



CREATE INDEX "refresh_tokens_updated_at_idx" ON "auth"."refresh_tokens" USING "btree" ("updated_at" DESC);



CREATE INDEX "saml_providers_sso_provider_id_idx" ON "auth"."saml_providers" USING "btree" ("sso_provider_id");



CREATE INDEX "saml_relay_states_created_at_idx" ON "auth"."saml_relay_states" USING "btree" ("created_at" DESC);



CREATE INDEX "saml_relay_states_for_email_idx" ON "auth"."saml_relay_states" USING "btree" ("for_email");



CREATE INDEX "saml_relay_states_sso_provider_id_idx" ON "auth"."saml_relay_states" USING "btree" ("sso_provider_id");



CREATE INDEX "sessions_not_after_idx" ON "auth"."sessions" USING "btree" ("not_after" DESC);



CREATE INDEX "sessions_oauth_client_id_idx" ON "auth"."sessions" USING "btree" ("oauth_client_id");



CREATE INDEX "sessions_user_id_idx" ON "auth"."sessions" USING "btree" ("user_id");



CREATE UNIQUE INDEX "sso_domains_domain_idx" ON "auth"."sso_domains" USING "btree" ("lower"("domain"));



CREATE INDEX "sso_domains_sso_provider_id_idx" ON "auth"."sso_domains" USING "btree" ("sso_provider_id");



CREATE UNIQUE INDEX "sso_providers_resource_id_idx" ON "auth"."sso_providers" USING "btree" ("lower"("resource_id"));



CREATE INDEX "sso_providers_resource_id_pattern_idx" ON "auth"."sso_providers" USING "btree" ("resource_id" "text_pattern_ops");



CREATE UNIQUE INDEX "unique_phone_factor_per_user" ON "auth"."mfa_factors" USING "btree" ("user_id", "phone");



CREATE INDEX "user_id_created_at_idx" ON "auth"."sessions" USING "btree" ("user_id", "created_at");



CREATE UNIQUE INDEX "users_email_partial_key" ON "auth"."users" USING "btree" ("email") WHERE ("is_sso_user" = false);



COMMENT ON INDEX "auth"."users_email_partial_key" IS 'Auth: A partial unique index that applies only when is_sso_user is false';



CREATE INDEX "users_instance_id_email_idx" ON "auth"."users" USING "btree" ("instance_id", "lower"(("email")::"text"));



CREATE INDEX "users_instance_id_idx" ON "auth"."users" USING "btree" ("instance_id");



CREATE INDEX "users_is_anonymous_idx" ON "auth"."users" USING "btree" ("is_anonymous");



CREATE INDEX "webauthn_challenges_expires_at_idx" ON "auth"."webauthn_challenges" USING "btree" ("expires_at");



CREATE INDEX "webauthn_challenges_user_id_idx" ON "auth"."webauthn_challenges" USING "btree" ("user_id");



CREATE UNIQUE INDEX "webauthn_credentials_credential_id_key" ON "auth"."webauthn_credentials" USING "btree" ("credential_id");



CREATE INDEX "webauthn_credentials_user_id_idx" ON "auth"."webauthn_credentials" USING "btree" ("user_id");



CREATE INDEX "idx_aprovacoes_jovens_composto" ON "public"."aprovacoes_jovens" USING "btree" ("jovem_id", "tipo_aprovacao", "criado_em");



CREATE INDEX "idx_aprovacoes_jovens_jovem_id" ON "public"."aprovacoes_jovens" USING "btree" ("jovem_id");



CREATE INDEX "idx_aprovacoes_jovens_tipo" ON "public"."aprovacoes_jovens" USING "btree" ("tipo_aprovacao");



CREATE INDEX "idx_aprovacoes_jovens_usuario_id" ON "public"."aprovacoes_jovens" USING "btree" ("usuario_id");



CREATE INDEX "idx_configuracoes_categoria" ON "public"."configuracoes_sistema" USING "btree" ("categoria");



CREATE INDEX "idx_configuracoes_chave" ON "public"."configuracoes_sistema" USING "btree" ("chave");



CREATE INDEX "idx_dados_nucleo_criado_em" ON "public"."dados_nucleo" USING "btree" ("criado_em");



CREATE INDEX "idx_dados_nucleo_faz_nucleo" ON "public"."dados_nucleo" USING "btree" ("faz_nucleo");



CREATE INDEX "idx_dados_nucleo_jovem_id" ON "public"."dados_nucleo" USING "btree" ("jovem_id");



CREATE INDEX "idx_dados_viagem_jovem_id" ON "public"."dados_viagem" USING "btree" ("jovem_id");



CREATE INDEX "idx_dados_viagem_usuario_id" ON "public"."dados_viagem" USING "btree" ("usuario_id");



CREATE INDEX "idx_edicoes_ativa" ON "public"."edicoes" USING "btree" ("ativa");



CREATE INDEX "idx_edicoes_numero" ON "public"."edicoes" USING "btree" ("numero");



CREATE INDEX "idx_jovens_aprovado" ON "public"."jovens" USING "btree" ("aprovado");



CREATE INDEX "idx_jovens_edicao_id" ON "public"."jovens" USING "btree" ("edicao_id");



CREATE INDEX "idx_jovens_estado_bloco_regiao_igreja" ON "public"."jovens" USING "btree" ("estado_id", "bloco_id", "regiao_id", "igreja_id");



CREATE INDEX "idx_jovens_usuario_id" ON "public"."jovens" USING "btree" ("usuario_id");



CREATE INDEX "idx_jua_jovem_id" ON "public"."jovens_usuarios_associacoes" USING "btree" ("jovem_id");



CREATE INDEX "idx_jua_usuario_id" ON "public"."jovens_usuarios_associacoes" USING "btree" ("usuario_id");



CREATE INDEX "idx_logs_acao" ON "public"."logs_historico" USING "btree" ("acao");



CREATE INDEX "idx_logs_auditoria_acao" ON "public"."logs_auditoria" USING "btree" ("acao");



CREATE INDEX "idx_logs_auditoria_criado_em" ON "public"."logs_auditoria" USING "btree" ("criado_em");



CREATE INDEX "idx_logs_auditoria_usuario" ON "public"."logs_auditoria" USING "btree" ("usuario_id");



CREATE INDEX "idx_logs_created_at" ON "public"."logs_historico" USING "btree" ("created_at");



CREATE INDEX "idx_logs_jovem_id" ON "public"."logs_historico" USING "btree" ("jovem_id");



CREATE INDEX "idx_logs_user_id" ON "public"."logs_historico" USING "btree" ("user_id");



CREATE INDEX "idx_namorados_jovem_id" ON "public"."namorados" USING "btree" ("jovem_id");



CREATE INDEX "idx_notificacoes_criado_em" ON "public"."notificacoes" USING "btree" ("criado_em");



CREATE INDEX "idx_notificacoes_destinatario" ON "public"."notificacoes" USING "btree" ("destinatario_id");



CREATE INDEX "idx_notificacoes_lida" ON "public"."notificacoes" USING "btree" ("lida");



CREATE INDEX "idx_notificacoes_tipo" ON "public"."notificacoes" USING "btree" ("tipo");



CREATE INDEX "idx_roles_nivel" ON "public"."roles" USING "btree" ("nivel_hierarquico");



CREATE INDEX "idx_roles_nivel_hierarquico" ON "public"."roles" USING "btree" ("nivel_hierarquico");



CREATE INDEX "idx_roles_slug" ON "public"."roles" USING "btree" ("slug");



CREATE INDEX "idx_sessoes_ativo" ON "public"."sessoes_usuario" USING "btree" ("ativo");



CREATE INDEX "idx_sessoes_expira_em" ON "public"."sessoes_usuario" USING "btree" ("expira_em");



CREATE INDEX "idx_sessoes_token" ON "public"."sessoes_usuario" USING "btree" ("token_hash");



CREATE INDEX "idx_sessoes_usuario" ON "public"."sessoes_usuario" USING "btree" ("usuario_id");



CREATE INDEX "idx_user_roles_ativo" ON "public"."user_roles" USING "btree" ("ativo");



CREATE INDEX "idx_user_roles_bloco_id" ON "public"."user_roles" USING "btree" ("bloco_id");



CREATE INDEX "idx_user_roles_estado_id" ON "public"."user_roles" USING "btree" ("estado_id");



CREATE INDEX "idx_user_roles_igreja_id" ON "public"."user_roles" USING "btree" ("igreja_id");



CREATE INDEX "idx_user_roles_regiao_id" ON "public"."user_roles" USING "btree" ("regiao_id");



CREATE INDEX "idx_user_roles_role_id" ON "public"."user_roles" USING "btree" ("role_id");



CREATE INDEX "idx_user_roles_user_id" ON "public"."user_roles" USING "btree" ("user_id");



CREATE INDEX "idx_user_roles_user_id_ativo" ON "public"."user_roles" USING "btree" ("user_id", "ativo");



CREATE INDEX "idx_user_roles_user_id_ativo_nivel" ON "public"."user_roles" USING "btree" ("user_id", "ativo");



CREATE INDEX "idx_usuarios_id_auth" ON "public"."usuarios" USING "btree" ("id_auth");



CREATE UNIQUE INDEX "bname" ON "storage"."buckets" USING "btree" ("name");



CREATE UNIQUE INDEX "bucketid_objname" ON "storage"."objects" USING "btree" ("bucket_id", "name");



CREATE UNIQUE INDEX "buckets_analytics_unique_name_idx" ON "storage"."buckets_analytics" USING "btree" ("name") WHERE ("deleted_at" IS NULL);



CREATE INDEX "idx_multipart_uploads_list" ON "storage"."s3_multipart_uploads" USING "btree" ("bucket_id", "key", "created_at");



CREATE INDEX "idx_objects_bucket_id_name" ON "storage"."objects" USING "btree" ("bucket_id", "name" COLLATE "C");



CREATE INDEX "idx_objects_bucket_id_name_lower" ON "storage"."objects" USING "btree" ("bucket_id", "lower"("name") COLLATE "C");



CREATE INDEX "name_prefix_search" ON "storage"."objects" USING "btree" ("name" "text_pattern_ops");



CREATE UNIQUE INDEX "vector_indexes_name_bucket_id_idx" ON "storage"."vector_indexes" USING "btree" ("name", "bucket_id");



CREATE OR REPLACE TRIGGER "trg_atribuir_papel_padrao_jovem" AFTER INSERT ON "public"."usuarios" FOR EACH ROW EXECUTE FUNCTION "public"."atribuir_papel_padrao_jovem"();



CREATE OR REPLACE TRIGGER "trg_dados_viagem_set_updated" BEFORE UPDATE ON "public"."dados_viagem" FOR EACH ROW EXECUTE FUNCTION "public"."atualizar_timestamp"();



CREATE OR REPLACE TRIGGER "trg_set_usuario_id_dados_viagem" BEFORE INSERT ON "public"."dados_viagem" FOR EACH ROW EXECUTE FUNCTION "public"."set_usuario_id_dados_viagem"();



CREATE OR REPLACE TRIGGER "trg_set_usuario_id_on_insert" BEFORE INSERT ON "public"."jovens" FOR EACH ROW EXECUTE FUNCTION "public"."set_usuario_id_on_insert"();



CREATE OR REPLACE TRIGGER "trigger_atualizar_timestamp_aprovacoes" BEFORE UPDATE ON "public"."aprovacoes_jovens" FOR EACH ROW EXECUTE FUNCTION "public"."atualizar_timestamp_aprovacoes"();



CREATE OR REPLACE TRIGGER "trigger_atualizar_timestamp_configuracoes" BEFORE UPDATE ON "public"."configuracoes_sistema" FOR EACH ROW EXECUTE FUNCTION "public"."atualizar_timestamp"();



CREATE OR REPLACE TRIGGER "trigger_atualizar_timestamp_notificacoes" BEFORE UPDATE ON "public"."notificacoes" FOR EACH ROW EXECUTE FUNCTION "public"."atualizar_timestamp"();



CREATE OR REPLACE TRIGGER "trigger_atualizar_timestamp_sessoes" BEFORE UPDATE ON "public"."sessoes_usuario" FOR EACH ROW EXECUTE FUNCTION "public"."atualizar_timestamp"();



CREATE OR REPLACE TRIGGER "trigger_mudanca_status_jovem" AFTER UPDATE ON "public"."jovens" FOR EACH ROW EXECUTE FUNCTION "public"."trigger_notificar_mudanca_status"();



CREATE OR REPLACE TRIGGER "trigger_namorados_updated_at" BEFORE UPDATE ON "public"."namorados" FOR EACH ROW EXECUTE FUNCTION "public"."atualizar_namorados_updated_at"();



CREATE OR REPLACE TRIGGER "trigger_notificacao_avaliacao" AFTER INSERT ON "public"."avaliacoes" FOR EACH ROW EXECUTE FUNCTION "public"."criar_notificacao_automatica"();



CREATE OR REPLACE TRIGGER "trigger_notificacao_jovem" AFTER INSERT ON "public"."jovens" FOR EACH ROW EXECUTE FUNCTION "public"."criar_notificacao_automatica"();



CREATE OR REPLACE TRIGGER "trigger_nova_avaliacao" AFTER INSERT ON "public"."avaliacoes" FOR EACH ROW EXECUTE FUNCTION "public"."trigger_notificar_nova_avaliacao"();



CREATE OR REPLACE TRIGGER "trigger_novo_cadastro_jovem" AFTER INSERT ON "public"."jovens" FOR EACH ROW EXECUTE FUNCTION "public"."trigger_notificar_novo_cadastro"();



CREATE OR REPLACE TRIGGER "trigger_recalcular_idade" BEFORE INSERT OR UPDATE ON "public"."jovens" FOR EACH ROW EXECUTE FUNCTION "public"."recalcular_idade"();



CREATE OR REPLACE TRIGGER "trigger_set_usuario_id_dados_viagem" BEFORE INSERT ON "public"."dados_viagem" FOR EACH ROW EXECUTE FUNCTION "public"."set_usuario_id_dados_viagem"();



CREATE OR REPLACE TRIGGER "trigger_sincronizar_nivel_user_roles" AFTER INSERT OR DELETE OR UPDATE ON "public"."user_roles" FOR EACH ROW EXECUTE FUNCTION "public"."trigger_sincronizar_nivel"();



CREATE OR REPLACE TRIGGER "trigger_update_dados_nucleo_updated_at" BEFORE UPDATE ON "public"."dados_nucleo" FOR EACH ROW EXECUTE FUNCTION "public"."update_dados_nucleo_updated_at"();



CREATE OR REPLACE TRIGGER "enforce_bucket_name_length_trigger" BEFORE INSERT OR UPDATE OF "name" ON "storage"."buckets" FOR EACH ROW EXECUTE FUNCTION "storage"."enforce_bucket_name_length"();



CREATE OR REPLACE TRIGGER "protect_buckets_delete" BEFORE DELETE ON "storage"."buckets" FOR EACH STATEMENT EXECUTE FUNCTION "storage"."protect_delete"();



CREATE OR REPLACE TRIGGER "protect_objects_delete" BEFORE DELETE ON "storage"."objects" FOR EACH STATEMENT EXECUTE FUNCTION "storage"."protect_delete"();



CREATE OR REPLACE TRIGGER "update_objects_updated_at" BEFORE UPDATE ON "storage"."objects" FOR EACH ROW EXECUTE FUNCTION "storage"."update_updated_at_column"();



ALTER TABLE ONLY "auth"."identities"
    ADD CONSTRAINT "identities_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "auth"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "auth"."mfa_amr_claims"
    ADD CONSTRAINT "mfa_amr_claims_session_id_fkey" FOREIGN KEY ("session_id") REFERENCES "auth"."sessions"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "auth"."mfa_challenges"
    ADD CONSTRAINT "mfa_challenges_auth_factor_id_fkey" FOREIGN KEY ("factor_id") REFERENCES "auth"."mfa_factors"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "auth"."mfa_factors"
    ADD CONSTRAINT "mfa_factors_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "auth"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "auth"."oauth_authorizations"
    ADD CONSTRAINT "oauth_authorizations_client_id_fkey" FOREIGN KEY ("client_id") REFERENCES "auth"."oauth_clients"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "auth"."oauth_authorizations"
    ADD CONSTRAINT "oauth_authorizations_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "auth"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "auth"."oauth_consents"
    ADD CONSTRAINT "oauth_consents_client_id_fkey" FOREIGN KEY ("client_id") REFERENCES "auth"."oauth_clients"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "auth"."oauth_consents"
    ADD CONSTRAINT "oauth_consents_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "auth"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "auth"."one_time_tokens"
    ADD CONSTRAINT "one_time_tokens_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "auth"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "auth"."refresh_tokens"
    ADD CONSTRAINT "refresh_tokens_session_id_fkey" FOREIGN KEY ("session_id") REFERENCES "auth"."sessions"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "auth"."saml_providers"
    ADD CONSTRAINT "saml_providers_sso_provider_id_fkey" FOREIGN KEY ("sso_provider_id") REFERENCES "auth"."sso_providers"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "auth"."saml_relay_states"
    ADD CONSTRAINT "saml_relay_states_flow_state_id_fkey" FOREIGN KEY ("flow_state_id") REFERENCES "auth"."flow_state"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "auth"."saml_relay_states"
    ADD CONSTRAINT "saml_relay_states_sso_provider_id_fkey" FOREIGN KEY ("sso_provider_id") REFERENCES "auth"."sso_providers"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "auth"."sessions"
    ADD CONSTRAINT "sessions_oauth_client_id_fkey" FOREIGN KEY ("oauth_client_id") REFERENCES "auth"."oauth_clients"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "auth"."sessions"
    ADD CONSTRAINT "sessions_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "auth"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "auth"."sso_domains"
    ADD CONSTRAINT "sso_domains_sso_provider_id_fkey" FOREIGN KEY ("sso_provider_id") REFERENCES "auth"."sso_providers"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "auth"."webauthn_challenges"
    ADD CONSTRAINT "webauthn_challenges_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "auth"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "auth"."webauthn_credentials"
    ADD CONSTRAINT "webauthn_credentials_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "auth"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."aprovacoes_jovens"
    ADD CONSTRAINT "aprovacoes_jovens_jovem_id_fkey" FOREIGN KEY ("jovem_id") REFERENCES "public"."jovens"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."aprovacoes_jovens"
    ADD CONSTRAINT "aprovacoes_jovens_usuario_id_fkey" FOREIGN KEY ("usuario_id") REFERENCES "public"."usuarios"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."avaliacoes"
    ADD CONSTRAINT "avaliacoes_jovem_id_fkey" FOREIGN KEY ("jovem_id") REFERENCES "public"."jovens"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."avaliacoes"
    ADD CONSTRAINT "avaliacoes_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "public"."usuarios"("id");



ALTER TABLE ONLY "public"."blocos"
    ADD CONSTRAINT "blocos_estado_id_fkey" FOREIGN KEY ("estado_id") REFERENCES "public"."estados"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."dados_nucleo"
    ADD CONSTRAINT "dados_nucleo_atualizado_por_fkey" FOREIGN KEY ("atualizado_por") REFERENCES "public"."usuarios"("id");



ALTER TABLE ONLY "public"."dados_nucleo"
    ADD CONSTRAINT "dados_nucleo_criado_por_fkey" FOREIGN KEY ("criado_por") REFERENCES "public"."usuarios"("id");



ALTER TABLE ONLY "public"."dados_nucleo"
    ADD CONSTRAINT "dados_nucleo_jovem_id_fkey" FOREIGN KEY ("jovem_id") REFERENCES "public"."jovens"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."dados_viagem"
    ADD CONSTRAINT "dados_viagem_edicao_id_fkey" FOREIGN KEY ("edicao_id") REFERENCES "public"."edicoes"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."dados_viagem"
    ADD CONSTRAINT "dados_viagem_jovem_id_fkey" FOREIGN KEY ("jovem_id") REFERENCES "public"."jovens"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."dados_viagem"
    ADD CONSTRAINT "dados_viagem_usuario_id_fkey" FOREIGN KEY ("usuario_id") REFERENCES "public"."usuarios"("id");



ALTER TABLE ONLY "public"."igrejas"
    ADD CONSTRAINT "igrejas_regiao_id_fkey" FOREIGN KEY ("regiao_id") REFERENCES "public"."regioes"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."jovens"
    ADD CONSTRAINT "jovens_bloco_id_fkey" FOREIGN KEY ("bloco_id") REFERENCES "public"."blocos"("id");



ALTER TABLE ONLY "public"."jovens"
    ADD CONSTRAINT "jovens_edicao_id_fkey" FOREIGN KEY ("edicao_id") REFERENCES "public"."edicoes"("id");



ALTER TABLE ONLY "public"."jovens"
    ADD CONSTRAINT "jovens_estado_id_fkey" FOREIGN KEY ("estado_id") REFERENCES "public"."estados"("id");



ALTER TABLE ONLY "public"."jovens"
    ADD CONSTRAINT "jovens_igreja_id_fkey" FOREIGN KEY ("igreja_id") REFERENCES "public"."igrejas"("id");



ALTER TABLE ONLY "public"."jovens"
    ADD CONSTRAINT "jovens_regiao_id_fkey" FOREIGN KEY ("regiao_id") REFERENCES "public"."regioes"("id");



ALTER TABLE ONLY "public"."jovens"
    ADD CONSTRAINT "jovens_usuario_id_fkey" FOREIGN KEY ("usuario_id") REFERENCES "public"."usuarios"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."jovens_usuarios_associacoes"
    ADD CONSTRAINT "jovens_usuarios_associacoes_created_by_fkey" FOREIGN KEY ("created_by") REFERENCES "public"."usuarios"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."jovens_usuarios_associacoes"
    ADD CONSTRAINT "jovens_usuarios_associacoes_jovem_id_fkey" FOREIGN KEY ("jovem_id") REFERENCES "public"."jovens"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."jovens_usuarios_associacoes"
    ADD CONSTRAINT "jovens_usuarios_associacoes_usuario_id_fkey" FOREIGN KEY ("usuario_id") REFERENCES "public"."usuarios"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."logs_auditoria"
    ADD CONSTRAINT "logs_auditoria_usuario_id_fkey" FOREIGN KEY ("usuario_id") REFERENCES "public"."usuarios"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."logs_historico"
    ADD CONSTRAINT "logs_historico_jovem_id_fkey" FOREIGN KEY ("jovem_id") REFERENCES "public"."jovens"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."logs_historico"
    ADD CONSTRAINT "logs_historico_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "public"."usuarios"("id");



ALTER TABLE ONLY "public"."namorados"
    ADD CONSTRAINT "namorados_jovem_id_fkey" FOREIGN KEY ("jovem_id") REFERENCES "public"."jovens"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."notificacoes"
    ADD CONSTRAINT "notificacoes_destinatario_id_fkey" FOREIGN KEY ("destinatario_id") REFERENCES "public"."usuarios"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."notificacoes"
    ADD CONSTRAINT "notificacoes_jovem_id_fkey" FOREIGN KEY ("jovem_id") REFERENCES "public"."jovens"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."notificacoes"
    ADD CONSTRAINT "notificacoes_remetente_id_fkey" FOREIGN KEY ("remetente_id") REFERENCES "public"."usuarios"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."regioes"
    ADD CONSTRAINT "regioes_bloco_id_fkey" FOREIGN KEY ("bloco_id") REFERENCES "public"."blocos"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."sessoes_usuario"
    ADD CONSTRAINT "sessoes_usuario_usuario_id_fkey" FOREIGN KEY ("usuario_id") REFERENCES "public"."usuarios"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."user_roles"
    ADD CONSTRAINT "user_roles_bloco_id_fkey" FOREIGN KEY ("bloco_id") REFERENCES "public"."blocos"("id");



ALTER TABLE ONLY "public"."user_roles"
    ADD CONSTRAINT "user_roles_criado_por_fkey" FOREIGN KEY ("criado_por") REFERENCES "public"."usuarios"("id");



ALTER TABLE ONLY "public"."user_roles"
    ADD CONSTRAINT "user_roles_estado_id_fkey" FOREIGN KEY ("estado_id") REFERENCES "public"."estados"("id");



ALTER TABLE ONLY "public"."user_roles"
    ADD CONSTRAINT "user_roles_igreja_id_fkey" FOREIGN KEY ("igreja_id") REFERENCES "public"."igrejas"("id");



ALTER TABLE ONLY "public"."user_roles"
    ADD CONSTRAINT "user_roles_regiao_id_fkey" FOREIGN KEY ("regiao_id") REFERENCES "public"."regioes"("id");



ALTER TABLE ONLY "public"."user_roles"
    ADD CONSTRAINT "user_roles_role_id_fkey" FOREIGN KEY ("role_id") REFERENCES "public"."roles"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."user_roles"
    ADD CONSTRAINT "user_roles_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "public"."usuarios"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."usuarios"
    ADD CONSTRAINT "usuarios_bloco_id_fkey" FOREIGN KEY ("bloco_id") REFERENCES "public"."blocos"("id");



ALTER TABLE ONLY "public"."usuarios"
    ADD CONSTRAINT "usuarios_estado_id_fkey" FOREIGN KEY ("estado_id") REFERENCES "public"."estados"("id");



ALTER TABLE ONLY "public"."usuarios"
    ADD CONSTRAINT "usuarios_igreja_id_fkey" FOREIGN KEY ("igreja_id") REFERENCES "public"."igrejas"("id");



ALTER TABLE ONLY "public"."usuarios"
    ADD CONSTRAINT "usuarios_regiao_id_fkey" FOREIGN KEY ("regiao_id") REFERENCES "public"."regioes"("id");



ALTER TABLE ONLY "storage"."objects"
    ADD CONSTRAINT "objects_bucketId_fkey" FOREIGN KEY ("bucket_id") REFERENCES "storage"."buckets"("id");



ALTER TABLE ONLY "storage"."s3_multipart_uploads"
    ADD CONSTRAINT "s3_multipart_uploads_bucket_id_fkey" FOREIGN KEY ("bucket_id") REFERENCES "storage"."buckets"("id");



ALTER TABLE ONLY "storage"."s3_multipart_uploads_parts"
    ADD CONSTRAINT "s3_multipart_uploads_parts_bucket_id_fkey" FOREIGN KEY ("bucket_id") REFERENCES "storage"."buckets"("id");



ALTER TABLE ONLY "storage"."s3_multipart_uploads_parts"
    ADD CONSTRAINT "s3_multipart_uploads_parts_upload_id_fkey" FOREIGN KEY ("upload_id") REFERENCES "storage"."s3_multipart_uploads"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "storage"."vector_indexes"
    ADD CONSTRAINT "vector_indexes_bucket_id_fkey" FOREIGN KEY ("bucket_id") REFERENCES "storage"."buckets_vectors"("id");



ALTER TABLE "auth"."audit_log_entries" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "auth"."flow_state" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "auth"."identities" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "auth"."instances" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "auth"."mfa_amr_claims" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "auth"."mfa_challenges" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "auth"."mfa_factors" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "auth"."one_time_tokens" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "auth"."refresh_tokens" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "auth"."saml_providers" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "auth"."saml_relay_states" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "auth"."schema_migrations" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "auth"."sessions" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "auth"."sso_domains" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "auth"."sso_providers" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "auth"."users" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "Acesso Geral" ON "public"."dados_viagem" USING (true) WITH CHECK (true);



CREATE POLICY "Allow admin all access" ON "public"."usuarios" TO "authenticated" USING ((EXISTS ( SELECT 1
   FROM "public"."usuarios" "u"
  WHERE (("u"."id_auth" = "auth"."uid"()) AND ("u"."nivel" = 'administrador'::"text")))));



CREATE POLICY "Allow all for admin" ON "public"."avaliacoes" USING ("public"."has_role"('administrador'::"text"));



CREATE POLICY "Allow all for admin" ON "public"."dados_viagem" USING ("public"."has_role"('administrador'::"text"));



CREATE POLICY "Allow all for admin" ON "public"."jovens" USING ("public"."has_role"('administrador'::"text"));



CREATE POLICY "Allow all for admin" ON "public"."logs_auditoria" USING ("public"."has_role"('administrador'::"text"));



CREATE POLICY "Allow all for admin" ON "public"."notificacoes" USING ("public"."has_role"('administrador'::"text"));



CREATE POLICY "Allow all for admin" ON "public"."roles" USING ("public"."has_role"('administrador'::"text"));



CREATE POLICY "Allow all for admin" ON "public"."user_roles" USING ("public"."has_role"('administrador'::"text"));



CREATE POLICY "Allow delete for admin" ON "public"."user_roles" FOR DELETE USING ("public"."has_role"('administrador'::"text"));



CREATE POLICY "Allow insert for admin" ON "public"."user_roles" FOR INSERT WITH CHECK ("public"."has_role"('administrador'::"text"));



CREATE POLICY "Allow insert for authenticated users" ON "public"."avaliacoes" FOR INSERT WITH CHECK (("auth"."role"() = 'authenticated'::"text"));



CREATE POLICY "Allow insert for authenticated users" ON "public"."dados_viagem" FOR INSERT WITH CHECK (("auth"."role"() = 'authenticated'::"text"));



CREATE POLICY "Allow insert for authenticated users" ON "public"."jovens" FOR INSERT WITH CHECK (("auth"."role"() = 'authenticated'::"text"));



CREATE POLICY "Allow insert for authenticated users" ON "public"."notificacoes" FOR INSERT WITH CHECK (("auth"."role"() = 'authenticated'::"text"));



CREATE POLICY "Allow insert for signup" ON "public"."usuarios" FOR INSERT TO "authenticated" WITH CHECK (true);



CREATE POLICY "Allow read for authenticated users" ON "public"."avaliacoes" FOR SELECT USING (("auth"."role"() = 'authenticated'::"text"));



CREATE POLICY "Allow read for authenticated users" ON "public"."logs_auditoria" FOR SELECT USING (("auth"."role"() = 'authenticated'::"text"));



CREATE POLICY "Allow read for authenticated users" ON "public"."notificacoes" FOR SELECT USING (("auth"."role"() = 'authenticated'::"text"));



CREATE POLICY "Allow read for authenticated users" ON "public"."roles" FOR SELECT USING (("auth"."role"() = 'authenticated'::"text"));



CREATE POLICY "Allow read for authenticated users" ON "public"."user_roles" FOR SELECT USING (("auth"."role"() = 'authenticated'::"text"));



CREATE POLICY "Allow select own profile" ON "public"."usuarios" FOR SELECT TO "authenticated" USING (("id_auth" = "auth"."uid"()));



CREATE POLICY "Allow update for admin" ON "public"."user_roles" FOR UPDATE USING ("public"."has_role"('administrador'::"text"));



CREATE POLICY "Allow update for authenticated users" ON "public"."avaliacoes" FOR UPDATE USING (("auth"."role"() = 'authenticated'::"text"));



CREATE POLICY "Allow update for authenticated users" ON "public"."dados_viagem" FOR UPDATE USING (("auth"."role"() = 'authenticated'::"text"));



CREATE POLICY "Allow update for authenticated users" ON "public"."jovens" FOR UPDATE USING (("auth"."role"() = 'authenticated'::"text"));



CREATE POLICY "Allow update for authenticated users" ON "public"."notificacoes" FOR UPDATE USING (("auth"."role"() = 'authenticated'::"text"));



CREATE POLICY "Allow update own profile" ON "public"."usuarios" FOR UPDATE TO "authenticated" USING (("id_auth" = "auth"."uid"())) WITH CHECK (("id_auth" = "auth"."uid"()));



CREATE POLICY "Edições são visíveis para todos" ON "public"."edicoes" FOR SELECT TO "authenticated" USING (true);



CREATE POLICY "Estados são visíveis para todos" ON "public"."estados" FOR SELECT TO "authenticated" USING (true);



CREATE POLICY "Todos podem ler estados" ON "public"."estados" FOR SELECT USING (true);



CREATE POLICY "Usuário pode ver apenas seus dados" ON "public"."usuarios" FOR SELECT TO "authenticated" USING (("auth"."uid"() = "id"));



CREATE POLICY "allow_read_all_edicoes" ON "public"."edicoes" FOR SELECT USING (true);



CREATE POLICY "allow_read_all_estados" ON "public"."estados" FOR SELECT USING (true);



CREATE POLICY "allow_read_aprovacoes_jovens" ON "public"."aprovacoes_jovens" FOR SELECT USING (true);



CREATE POLICY "allow_read_configuracoes_sistema" ON "public"."configuracoes_sistema" FOR SELECT USING (true);



CREATE POLICY "allow_read_sessoes_usuario" ON "public"."sessoes_usuario" FOR SELECT USING (true);



ALTER TABLE "public"."anti_pausa" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."aprovacoes_jovens" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "associacoes_delete" ON "public"."jovens_usuarios_associacoes" FOR DELETE USING ((EXISTS ( SELECT 1
   FROM "public"."usuarios" "u"
  WHERE (("u"."id_auth" = "auth"."uid"()) AND (("u"."id" = "jovens_usuarios_associacoes"."usuario_id") OR ("u"."nivel" = ANY (ARRAY['administrador'::"text", 'lider_nacional_iurd'::"text", 'lider_nacional_fju'::"text", 'lider_estadual_iurd'::"text", 'lider_estadual_fju'::"text", 'lider_bloco_iurd'::"text", 'lider_bloco_fju'::"text", 'lider_regional_iurd'::"text", 'lider_igreja_iurd'::"text"])))))));



CREATE POLICY "associacoes_insert" ON "public"."jovens_usuarios_associacoes" FOR INSERT WITH CHECK ((EXISTS ( SELECT 1
   FROM "public"."usuarios" "u"
  WHERE (("u"."id_auth" = "auth"."uid"()) AND ("u"."nivel" = ANY (ARRAY['administrador'::"text", 'lider_nacional_iurd'::"text", 'lider_nacional_fju'::"text", 'lider_estadual_iurd'::"text", 'lider_estadual_fju'::"text", 'lider_bloco_iurd'::"text", 'lider_bloco_fju'::"text", 'lider_regional_iurd'::"text", 'lider_igreja_iurd'::"text", 'colaborador'::"text"]))))));



CREATE POLICY "associacoes_select" ON "public"."jovens_usuarios_associacoes" FOR SELECT USING ((EXISTS ( SELECT 1
   FROM "public"."usuarios" "u"
  WHERE (("u"."id_auth" = "auth"."uid"()) AND (("u"."id" = "jovens_usuarios_associacoes"."usuario_id") OR ("u"."nivel" = ANY (ARRAY['administrador'::"text", 'lider_nacional_iurd'::"text", 'lider_nacional_fju'::"text", 'lider_estadual_iurd'::"text", 'lider_estadual_fju'::"text", 'lider_bloco_iurd'::"text", 'lider_bloco_fju'::"text", 'lider_regional_iurd'::"text", 'lider_igreja_iurd'::"text", 'colaborador'::"text"])))))));



CREATE POLICY "avaliacoes_insert_by_level" ON "public"."avaliacoes" FOR INSERT TO "authenticated" WITH CHECK ((EXISTS ( SELECT 1
   FROM "public"."usuarios" "u"
  WHERE (("u"."id_auth" = "auth"."uid"()) AND (("u"."nivel" = 'administrador'::"text") OR ("u"."nivel" = ANY (ARRAY['lider_nacional_iurd'::"text", 'lider_nacional_fju'::"text"])) OR (("u"."nivel" = ANY (ARRAY['lider_estadual_iurd'::"text", 'lider_estadual_fju'::"text"])) AND ("u"."estado_id" = ( SELECT "j"."estado_id"
           FROM "public"."jovens" "j"
          WHERE ("j"."id" = "avaliacoes"."jovem_id")))) OR (("u"."nivel" = ANY (ARRAY['lider_bloco_iurd'::"text", 'lider_bloco_fju'::"text"])) AND ("u"."bloco_id" = ( SELECT "j"."bloco_id"
           FROM "public"."jovens" "j"
          WHERE ("j"."id" = "avaliacoes"."jovem_id")))) OR (("u"."nivel" = 'lider_regional_iurd'::"text") AND ("u"."regiao_id" = ( SELECT "j"."regiao_id"
           FROM "public"."jovens" "j"
          WHERE ("j"."id" = "avaliacoes"."jovem_id")))) OR (("u"."nivel" = 'lider_igreja_iurd'::"text") AND ("u"."igreja_id" = ( SELECT "j"."igreja_id"
           FROM "public"."jovens" "j"
          WHERE ("j"."id" = "avaliacoes"."jovem_id")))) OR ("u"."nivel" = 'colaborador'::"text") OR (("u"."nivel" = 'jovem'::"text") AND ("u"."id" = "avaliacoes"."user_id")))))));



CREATE POLICY "avaliacoes_select_by_level" ON "public"."avaliacoes" FOR SELECT TO "authenticated" USING (((EXISTS ( SELECT 1
   FROM "public"."usuarios" "u"
  WHERE (("u"."id_auth" = "auth"."uid"()) AND ("u"."nivel" = 'administrador'::"text")))) OR (EXISTS ( SELECT 1
   FROM "public"."usuarios" "u"
  WHERE (("u"."id_auth" = "auth"."uid"()) AND ("u"."nivel" = ANY (ARRAY['lider_nacional_iurd'::"text", 'lider_nacional_fju'::"text"]))))) OR (EXISTS ( SELECT 1
   FROM "public"."usuarios" "u"
  WHERE (("u"."id_auth" = "auth"."uid"()) AND ("u"."nivel" = ANY (ARRAY['lider_estadual_iurd'::"text", 'lider_estadual_fju'::"text"])) AND ("u"."estado_id" = ( SELECT "j"."estado_id"
           FROM "public"."jovens" "j"
          WHERE ("j"."id" = "avaliacoes"."jovem_id")))))) OR (EXISTS ( SELECT 1
   FROM "public"."usuarios" "u"
  WHERE (("u"."id_auth" = "auth"."uid"()) AND ("u"."nivel" = ANY (ARRAY['lider_bloco_iurd'::"text", 'lider_bloco_fju'::"text"])) AND ("u"."bloco_id" = ( SELECT "j"."bloco_id"
           FROM "public"."jovens" "j"
          WHERE ("j"."id" = "avaliacoes"."jovem_id")))))) OR (EXISTS ( SELECT 1
   FROM "public"."usuarios" "u"
  WHERE (("u"."id_auth" = "auth"."uid"()) AND ("u"."nivel" = 'lider_regional_iurd'::"text") AND ("u"."regiao_id" = ( SELECT "j"."regiao_id"
           FROM "public"."jovens" "j"
          WHERE ("j"."id" = "avaliacoes"."jovem_id")))))) OR (EXISTS ( SELECT 1
   FROM "public"."usuarios" "u"
  WHERE (("u"."id_auth" = "auth"."uid"()) AND ("u"."nivel" = 'lider_igreja_iurd'::"text") AND ("u"."igreja_id" = ( SELECT "j"."igreja_id"
           FROM "public"."jovens" "j"
          WHERE ("j"."id" = "avaliacoes"."jovem_id")))))) OR (EXISTS ( SELECT 1
   FROM "public"."usuarios" "u"
  WHERE (("u"."id_auth" = "auth"."uid"()) AND ("u"."nivel" = 'colaborador'::"text") AND ("u"."id" = "avaliacoes"."user_id")))) OR (EXISTS ( SELECT 1
   FROM "public"."usuarios" "u"
  WHERE (("u"."id_auth" = "auth"."uid"()) AND ("u"."nivel" = 'jovem'::"text") AND ("u"."id" = "avaliacoes"."user_id"))))));



CREATE POLICY "avaliacoes_update_by_level" ON "public"."avaliacoes" FOR UPDATE TO "authenticated" USING ((EXISTS ( SELECT 1
   FROM "public"."usuarios" "u"
  WHERE (("u"."id_auth" = "auth"."uid"()) AND (("u"."nivel" = 'administrador'::"text") OR ("u"."nivel" = ANY (ARRAY['lider_nacional_iurd'::"text", 'lider_nacional_fju'::"text"])) OR (("u"."nivel" = ANY (ARRAY['lider_estadual_iurd'::"text", 'lider_estadual_fju'::"text"])) AND ("u"."estado_id" = ( SELECT "j"."estado_id"
           FROM "public"."jovens" "j"
          WHERE ("j"."id" = "avaliacoes"."jovem_id")))) OR (("u"."nivel" = ANY (ARRAY['lider_bloco_iurd'::"text", 'lider_bloco_fju'::"text"])) AND ("u"."bloco_id" = ( SELECT "j"."bloco_id"
           FROM "public"."jovens" "j"
          WHERE ("j"."id" = "avaliacoes"."jovem_id")))) OR (("u"."nivel" = 'lider_regional_iurd'::"text") AND ("u"."regiao_id" = ( SELECT "j"."regiao_id"
           FROM "public"."jovens" "j"
          WHERE ("j"."id" = "avaliacoes"."jovem_id")))) OR (("u"."nivel" = 'lider_igreja_iurd'::"text") AND ("u"."igreja_id" = ( SELECT "j"."igreja_id"
           FROM "public"."jovens" "j"
          WHERE ("j"."id" = "avaliacoes"."jovem_id")))) OR (("u"."nivel" = 'colaborador'::"text") AND ("u"."id" = "avaliacoes"."user_id")) OR (("u"."nivel" = 'jovem'::"text") AND ("u"."id" = "avaliacoes"."user_id"))))))) WITH CHECK ((EXISTS ( SELECT 1
   FROM "public"."usuarios" "u"
  WHERE (("u"."id_auth" = "auth"."uid"()) AND (("u"."nivel" = 'administrador'::"text") OR ("u"."nivel" = ANY (ARRAY['lider_nacional_iurd'::"text", 'lider_nacional_fju'::"text"])) OR (("u"."nivel" = ANY (ARRAY['lider_estadual_iurd'::"text", 'lider_estadual_fju'::"text"])) AND ("u"."estado_id" = ( SELECT "j"."estado_id"
           FROM "public"."jovens" "j"
          WHERE ("j"."id" = "avaliacoes"."jovem_id")))) OR (("u"."nivel" = ANY (ARRAY['lider_bloco_iurd'::"text", 'lider_bloco_fju'::"text"])) AND ("u"."bloco_id" = ( SELECT "j"."bloco_id"
           FROM "public"."jovens" "j"
          WHERE ("j"."id" = "avaliacoes"."jovem_id")))) OR (("u"."nivel" = 'lider_regional_iurd'::"text") AND ("u"."regiao_id" = ( SELECT "j"."regiao_id"
           FROM "public"."jovens" "j"
          WHERE ("j"."id" = "avaliacoes"."jovem_id")))) OR (("u"."nivel" = 'lider_igreja_iurd'::"text") AND ("u"."igreja_id" = ( SELECT "j"."igreja_id"
           FROM "public"."jovens" "j"
          WHERE ("j"."id" = "avaliacoes"."jovem_id")))) OR (("u"."nivel" = 'colaborador'::"text") AND ("u"."id" = "avaliacoes"."user_id")) OR (("u"."nivel" = 'jovem'::"text") AND ("u"."id" = "avaliacoes"."user_id")))))));



ALTER TABLE "public"."blocos" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "blocos_delete_admin" ON "public"."blocos" FOR DELETE USING ((EXISTS ( SELECT 1
   FROM "public"."usuarios" "u"
  WHERE (("u"."id_auth" = "auth"."uid"()) AND ("u"."nivel" = 'administrador'::"text")))));



CREATE POLICY "blocos_insert_admin" ON "public"."blocos" FOR INSERT WITH CHECK (((EXISTS ( SELECT 1
   FROM "public"."usuarios" "u"
  WHERE (("u"."id_auth" = "auth"."uid"()) AND ("u"."nivel" = 'administrador'::"text")))) OR (EXISTS ( SELECT 1
   FROM "public"."usuarios" "u"
  WHERE (("u"."id_auth" = "auth"."uid"()) AND ("u"."nivel" = ANY (ARRAY['lider_nacional_iurd'::"text", 'lider_nacional_fju'::"text"]))))) OR (EXISTS ( SELECT 1
   FROM "public"."usuarios" "u"
  WHERE (("u"."id_auth" = "auth"."uid"()) AND ("u"."nivel" = ANY (ARRAY['lider_estadual_iurd'::"text", 'lider_estadual_fju'::"text"])) AND ("u"."estado_id" = "blocos"."estado_id"))))));



CREATE POLICY "blocos_select_all" ON "public"."blocos" FOR SELECT USING (true);



CREATE POLICY "blocos_update_admin" ON "public"."blocos" FOR UPDATE USING (((EXISTS ( SELECT 1
   FROM "public"."usuarios" "u"
  WHERE (("u"."id_auth" = "auth"."uid"()) AND ("u"."nivel" = 'administrador'::"text")))) OR (EXISTS ( SELECT 1
   FROM "public"."usuarios" "u"
  WHERE (("u"."id_auth" = "auth"."uid"()) AND ("u"."nivel" = ANY (ARRAY['lider_nacional_iurd'::"text", 'lider_nacional_fju'::"text"]))))) OR (EXISTS ( SELECT 1
   FROM "public"."usuarios" "u"
  WHERE (("u"."id_auth" = "auth"."uid"()) AND ("u"."nivel" = ANY (ARRAY['lider_estadual_iurd'::"text", 'lider_estadual_fju'::"text"])) AND ("u"."estado_id" = "blocos"."estado_id")))))) WITH CHECK (((EXISTS ( SELECT 1
   FROM "public"."usuarios" "u"
  WHERE (("u"."id_auth" = "auth"."uid"()) AND ("u"."nivel" = 'administrador'::"text")))) OR (EXISTS ( SELECT 1
   FROM "public"."usuarios" "u"
  WHERE (("u"."id_auth" = "auth"."uid"()) AND ("u"."nivel" = ANY (ARRAY['lider_nacional_iurd'::"text", 'lider_nacional_fju'::"text"]))))) OR (EXISTS ( SELECT 1
   FROM "public"."usuarios" "u"
  WHERE (("u"."id_auth" = "auth"."uid"()) AND ("u"."nivel" = ANY (ARRAY['lider_estadual_iurd'::"text", 'lider_estadual_fju'::"text"])) AND ("u"."estado_id" = "blocos"."estado_id"))))));



ALTER TABLE "public"."configuracoes_sistema" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."dados_nucleo" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "dados_nucleo_delete_admin" ON "public"."dados_nucleo" FOR DELETE TO "authenticated" USING ((EXISTS ( SELECT 1
   FROM "public"."usuarios" "u"
  WHERE (("u"."id_auth" = "auth"."uid"()) AND ("u"."nivel" = 'administrador'::"text")))));



CREATE POLICY "dados_nucleo_delete_working" ON "public"."dados_nucleo" FOR DELETE TO "authenticated" USING ((EXISTS ( SELECT 1
   FROM "public"."usuarios" "u"
  WHERE (("u"."id_auth" = "auth"."uid"()) AND ("u"."nivel" = 'administrador'::"text")))));



CREATE POLICY "dados_nucleo_insert_own" ON "public"."dados_nucleo" FOR INSERT TO "authenticated" WITH CHECK (((EXISTS ( SELECT 1
   FROM "public"."usuarios" "u"
  WHERE (("u"."id_auth" = "auth"."uid"()) AND ("u"."nivel" = 'jovem'::"text") AND ("u"."id" = ( SELECT "j"."usuario_id"
           FROM "public"."jovens" "j"
          WHERE ("j"."id" = "dados_nucleo"."jovem_id")))))) OR (EXISTS ( SELECT 1
   FROM "public"."usuarios" "u"
  WHERE (("u"."id_auth" = "auth"."uid"()) AND ("u"."nivel" = 'administrador'::"text")))) OR (EXISTS ( SELECT 1
   FROM "public"."usuarios" "u"
  WHERE (("u"."id_auth" = "auth"."uid"()) AND ("u"."nivel" = 'colaborador'::"text") AND ("u"."id" = ( SELECT "j"."usuario_id"
           FROM "public"."jovens" "j"
          WHERE ("j"."id" = "dados_nucleo"."jovem_id"))))))));



CREATE POLICY "dados_nucleo_insert_working" ON "public"."dados_nucleo" FOR INSERT TO "authenticated" WITH CHECK (("auth"."uid"() IS NOT NULL));



CREATE POLICY "dados_nucleo_select_authenticated" ON "public"."dados_nucleo" FOR SELECT TO "authenticated" USING (true);



CREATE POLICY "dados_nucleo_select_hierarchical" ON "public"."dados_nucleo" FOR SELECT TO "authenticated" USING (((EXISTS ( SELECT 1
   FROM "public"."usuarios" "u"
  WHERE (("u"."id_auth" = "auth"."uid"()) AND ("u"."nivel" = 'administrador'::"text")))) OR (EXISTS ( SELECT 1
   FROM "public"."usuarios" "u"
  WHERE (("u"."id_auth" = "auth"."uid"()) AND ("u"."nivel" = ANY (ARRAY['lider_nacional_iurd'::"text", 'lider_nacional_fju'::"text"]))))) OR (EXISTS ( SELECT 1
   FROM "public"."usuarios" "u"
  WHERE (("u"."id_auth" = "auth"."uid"()) AND ("u"."nivel" = ANY (ARRAY['lider_estadual_iurd'::"text", 'lider_estadual_fju'::"text"])) AND ("u"."estado_id" = ( SELECT "j"."estado_id"
           FROM "public"."jovens" "j"
          WHERE ("j"."id" = "dados_nucleo"."jovem_id")))))) OR (EXISTS ( SELECT 1
   FROM "public"."usuarios" "u"
  WHERE (("u"."id_auth" = "auth"."uid"()) AND ("u"."nivel" = ANY (ARRAY['lider_bloco_iurd'::"text", 'lider_bloco_fju'::"text"])) AND ("u"."bloco_id" = ( SELECT "j"."bloco_id"
           FROM "public"."jovens" "j"
          WHERE ("j"."id" = "dados_nucleo"."jovem_id")))))) OR (EXISTS ( SELECT 1
   FROM "public"."usuarios" "u"
  WHERE (("u"."id_auth" = "auth"."uid"()) AND ("u"."nivel" = 'lider_regional_iurd'::"text") AND ("u"."regiao_id" = ( SELECT "j"."regiao_id"
           FROM "public"."jovens" "j"
          WHERE ("j"."id" = "dados_nucleo"."jovem_id")))))) OR (EXISTS ( SELECT 1
   FROM "public"."usuarios" "u"
  WHERE (("u"."id_auth" = "auth"."uid"()) AND ("u"."nivel" = 'lider_igreja_iurd'::"text") AND ("u"."igreja_id" = ( SELECT "j"."igreja_id"
           FROM "public"."jovens" "j"
          WHERE ("j"."id" = "dados_nucleo"."jovem_id")))))) OR (EXISTS ( SELECT 1
   FROM "public"."usuarios" "u"
  WHERE (("u"."id_auth" = "auth"."uid"()) AND ("u"."nivel" = 'colaborador'::"text") AND ("u"."id" = ( SELECT "j"."usuario_id"
           FROM "public"."jovens" "j"
          WHERE ("j"."id" = "dados_nucleo"."jovem_id")))))) OR (EXISTS ( SELECT 1
   FROM "public"."usuarios" "u"
  WHERE (("u"."id_auth" = "auth"."uid"()) AND ("u"."nivel" = 'jovem'::"text") AND ("u"."id" = ( SELECT "j"."usuario_id"
           FROM "public"."jovens" "j"
          WHERE ("j"."id" = "dados_nucleo"."jovem_id"))))))));



CREATE POLICY "dados_nucleo_select_working" ON "public"."dados_nucleo" FOR SELECT TO "authenticated" USING (("auth"."uid"() IS NOT NULL));



CREATE POLICY "dados_nucleo_update_own" ON "public"."dados_nucleo" FOR UPDATE TO "authenticated" USING (((EXISTS ( SELECT 1
   FROM "public"."usuarios" "u"
  WHERE (("u"."id_auth" = "auth"."uid"()) AND ("u"."nivel" = 'jovem'::"text") AND ("u"."id" = ( SELECT "j"."usuario_id"
           FROM "public"."jovens" "j"
          WHERE ("j"."id" = "dados_nucleo"."jovem_id")))))) OR (EXISTS ( SELECT 1
   FROM "public"."usuarios" "u"
  WHERE (("u"."id_auth" = "auth"."uid"()) AND ("u"."nivel" = 'administrador'::"text")))) OR (EXISTS ( SELECT 1
   FROM "public"."usuarios" "u"
  WHERE (("u"."id_auth" = "auth"."uid"()) AND ("u"."nivel" = 'colaborador'::"text") AND ("u"."id" = ( SELECT "j"."usuario_id"
           FROM "public"."jovens" "j"
          WHERE ("j"."id" = "dados_nucleo"."jovem_id"))))))));



CREATE POLICY "dados_nucleo_update_working" ON "public"."dados_nucleo" FOR UPDATE TO "authenticated" USING (("auth"."uid"() IS NOT NULL));



ALTER TABLE "public"."dados_viagem" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."edicoes" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."estados" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."igrejas" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "igrejas_delete_admin" ON "public"."igrejas" FOR DELETE USING ((EXISTS ( SELECT 1
   FROM "public"."usuarios" "u"
  WHERE (("u"."id_auth" = "auth"."uid"()) AND ("u"."nivel" = 'administrador'::"text")))));



CREATE POLICY "igrejas_insert_admin" ON "public"."igrejas" FOR INSERT WITH CHECK (((EXISTS ( SELECT 1
   FROM "public"."usuarios" "u"
  WHERE (("u"."id_auth" = "auth"."uid"()) AND ("u"."nivel" = 'administrador'::"text")))) OR (EXISTS ( SELECT 1
   FROM "public"."usuarios" "u"
  WHERE (("u"."id_auth" = "auth"."uid"()) AND ("u"."nivel" = ANY (ARRAY['lider_nacional_iurd'::"text", 'lider_nacional_fju'::"text"]))))) OR (EXISTS ( SELECT 1
   FROM ("public"."usuarios" "u"
     JOIN "public"."blocos" "b" ON (("b"."id" = ( SELECT "r"."bloco_id"
           FROM "public"."regioes" "r"
          WHERE ("r"."id" = "igrejas"."regiao_id")))))
  WHERE (("u"."id_auth" = "auth"."uid"()) AND ("u"."nivel" = ANY (ARRAY['lider_estadual_iurd'::"text", 'lider_estadual_fju'::"text"])) AND ("u"."estado_id" = "b"."estado_id")))) OR (EXISTS ( SELECT 1
   FROM ("public"."usuarios" "u"
     JOIN "public"."regioes" "r" ON (("r"."id" = "igrejas"."regiao_id")))
  WHERE (("u"."id_auth" = "auth"."uid"()) AND ("u"."nivel" = ANY (ARRAY['lider_bloco_iurd'::"text", 'lider_bloco_fju'::"text"])) AND ("u"."bloco_id" = "r"."bloco_id")))) OR (EXISTS ( SELECT 1
   FROM "public"."usuarios" "u"
  WHERE (("u"."id_auth" = "auth"."uid"()) AND ("u"."nivel" = 'lider_regional_iurd'::"text") AND ("u"."regiao_id" = "igrejas"."regiao_id"))))));



CREATE POLICY "igrejas_select_all" ON "public"."igrejas" FOR SELECT USING (true);



CREATE POLICY "igrejas_update_admin" ON "public"."igrejas" FOR UPDATE USING (((EXISTS ( SELECT 1
   FROM "public"."usuarios" "u"
  WHERE (("u"."id_auth" = "auth"."uid"()) AND ("u"."nivel" = 'administrador'::"text")))) OR (EXISTS ( SELECT 1
   FROM "public"."usuarios" "u"
  WHERE (("u"."id_auth" = "auth"."uid"()) AND ("u"."nivel" = ANY (ARRAY['lider_nacional_iurd'::"text", 'lider_nacional_fju'::"text"]))))) OR (EXISTS ( SELECT 1
   FROM ("public"."usuarios" "u"
     JOIN "public"."blocos" "b" ON (("b"."id" = ( SELECT "r"."bloco_id"
           FROM "public"."regioes" "r"
          WHERE ("r"."id" = "igrejas"."regiao_id")))))
  WHERE (("u"."id_auth" = "auth"."uid"()) AND ("u"."nivel" = ANY (ARRAY['lider_estadual_iurd'::"text", 'lider_estadual_fju'::"text"])) AND ("u"."estado_id" = "b"."estado_id")))) OR (EXISTS ( SELECT 1
   FROM ("public"."usuarios" "u"
     JOIN "public"."regioes" "r" ON (("r"."id" = "igrejas"."regiao_id")))
  WHERE (("u"."id_auth" = "auth"."uid"()) AND ("u"."nivel" = ANY (ARRAY['lider_bloco_iurd'::"text", 'lider_bloco_fju'::"text"])) AND ("u"."bloco_id" = "r"."bloco_id")))) OR (EXISTS ( SELECT 1
   FROM "public"."usuarios" "u"
  WHERE (("u"."id_auth" = "auth"."uid"()) AND ("u"."nivel" = 'lider_regional_iurd'::"text") AND ("u"."regiao_id" = "igrejas"."regiao_id")))))) WITH CHECK (((EXISTS ( SELECT 1
   FROM "public"."usuarios" "u"
  WHERE (("u"."id_auth" = "auth"."uid"()) AND ("u"."nivel" = 'administrador'::"text")))) OR (EXISTS ( SELECT 1
   FROM "public"."usuarios" "u"
  WHERE (("u"."id_auth" = "auth"."uid"()) AND ("u"."nivel" = ANY (ARRAY['lider_nacional_iurd'::"text", 'lider_nacional_fju'::"text"]))))) OR (EXISTS ( SELECT 1
   FROM ("public"."usuarios" "u"
     JOIN "public"."blocos" "b" ON (("b"."id" = ( SELECT "r"."bloco_id"
           FROM "public"."regioes" "r"
          WHERE ("r"."id" = "igrejas"."regiao_id")))))
  WHERE (("u"."id_auth" = "auth"."uid"()) AND ("u"."nivel" = ANY (ARRAY['lider_estadual_iurd'::"text", 'lider_estadual_fju'::"text"])) AND ("u"."estado_id" = "b"."estado_id")))) OR (EXISTS ( SELECT 1
   FROM ("public"."usuarios" "u"
     JOIN "public"."regioes" "r" ON (("r"."id" = "igrejas"."regiao_id")))
  WHERE (("u"."id_auth" = "auth"."uid"()) AND ("u"."nivel" = ANY (ARRAY['lider_bloco_iurd'::"text", 'lider_bloco_fju'::"text"])) AND ("u"."bloco_id" = "r"."bloco_id")))) OR (EXISTS ( SELECT 1
   FROM "public"."usuarios" "u"
  WHERE (("u"."id_auth" = "auth"."uid"()) AND ("u"."nivel" = 'lider_regional_iurd'::"text") AND ("u"."regiao_id" = "igrejas"."regiao_id"))))));



ALTER TABLE "public"."jovens" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "jovens_read_authenticated_scoped" ON "public"."jovens" FOR SELECT TO "authenticated" USING ((EXISTS ( SELECT 1
   FROM "public"."usuarios" "u"
  WHERE (("u"."id_auth" = "auth"."uid"()) AND (("u"."nivel" <> 'jovem'::"text") OR (("u"."nivel" = 'jovem'::"text") AND (("u"."id" = "jovens"."usuario_id") OR ("jovens"."usuario_id" IS NULL))))))));



CREATE POLICY "jovens_select_with_associations" ON "public"."jovens" FOR SELECT TO "authenticated" USING (((EXISTS ( SELECT 1
   FROM "public"."usuarios" "u"
  WHERE (("u"."id_auth" = "auth"."uid"()) AND ("u"."nivel" = 'administrador'::"text")))) OR (EXISTS ( SELECT 1
   FROM "public"."usuarios" "u"
  WHERE (("u"."id_auth" = "auth"."uid"()) AND ("u"."nivel" = ANY (ARRAY['lider_nacional_iurd'::"text", 'lider_nacional_fju'::"text"]))))) OR (EXISTS ( SELECT 1
   FROM "public"."usuarios" "u"
  WHERE (("u"."id_auth" = "auth"."uid"()) AND ("u"."nivel" = ANY (ARRAY['lider_estadual_iurd'::"text", 'lider_estadual_fju'::"text"])) AND (("u"."estado_id" = "jovens"."estado_id") OR ("u"."id" = "jovens"."usuario_id"))))) OR (EXISTS ( SELECT 1
   FROM "public"."usuarios" "u"
  WHERE (("u"."id_auth" = "auth"."uid"()) AND ("u"."nivel" = ANY (ARRAY['lider_bloco_iurd'::"text", 'lider_bloco_fju'::"text"])) AND (("u"."bloco_id" = "jovens"."bloco_id") OR ("u"."id" = "jovens"."usuario_id"))))) OR (EXISTS ( SELECT 1
   FROM "public"."usuarios" "u"
  WHERE (("u"."id_auth" = "auth"."uid"()) AND ("u"."nivel" = 'lider_regional_iurd'::"text") AND (("u"."regiao_id" = "jovens"."regiao_id") OR ("u"."id" = "jovens"."usuario_id"))))) OR (EXISTS ( SELECT 1
   FROM "public"."usuarios" "u"
  WHERE (("u"."id_auth" = "auth"."uid"()) AND ("u"."nivel" = 'lider_igreja_iurd'::"text") AND (("u"."igreja_id" = "jovens"."igreja_id") OR ("u"."id" = "jovens"."usuario_id"))))) OR (EXISTS ( SELECT 1
   FROM "public"."usuarios" "u"
  WHERE (("u"."id_auth" = "auth"."uid"()) AND ("u"."nivel" = 'colaborador'::"text") AND ("u"."id" = "jovens"."usuario_id")))) OR (EXISTS ( SELECT 1
   FROM "public"."usuarios" "u"
  WHERE (("u"."id_auth" = "auth"."uid"()) AND ("u"."nivel" = 'jovem'::"text") AND (("u"."id" = "jovens"."usuario_id") OR ("u"."id" = "jovens"."id_usuario_jovem")))))));



ALTER TABLE "public"."jovens_usuarios_associacoes" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."logs_auditoria" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."logs_historico" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."namorados" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "namorados_delete" ON "public"."namorados" FOR DELETE TO "authenticated" USING (("public"."can_access_jovem"(( SELECT "j"."estado_id"
   FROM "public"."jovens" "j"
  WHERE ("j"."id" = "namorados"."jovem_id")), ( SELECT "j"."bloco_id"
   FROM "public"."jovens" "j"
  WHERE ("j"."id" = "namorados"."jovem_id")), ( SELECT "j"."regiao_id"
   FROM "public"."jovens" "j"
  WHERE ("j"."id" = "namorados"."jovem_id")), ( SELECT "j"."igreja_id"
   FROM "public"."jovens" "j"
  WHERE ("j"."id" = "namorados"."jovem_id"))) OR "public"."can_access_jovem_com_associacoes"(( SELECT "j"."estado_id"
   FROM "public"."jovens" "j"
  WHERE ("j"."id" = "namorados"."jovem_id")), ( SELECT "j"."bloco_id"
   FROM "public"."jovens" "j"
  WHERE ("j"."id" = "namorados"."jovem_id")), ( SELECT "j"."regiao_id"
   FROM "public"."jovens" "j"
  WHERE ("j"."id" = "namorados"."jovem_id")), ( SELECT "j"."igreja_id"
   FROM "public"."jovens" "j"
  WHERE ("j"."id" = "namorados"."jovem_id")), "jovem_id") OR "public"."namorado_jovem_pertence_ao_usuario"("jovem_id")));



CREATE POLICY "namorados_insert" ON "public"."namorados" FOR INSERT TO "authenticated" WITH CHECK (("public"."can_access_jovem"(( SELECT "j"."estado_id"
   FROM "public"."jovens" "j"
  WHERE ("j"."id" = "namorados"."jovem_id")), ( SELECT "j"."bloco_id"
   FROM "public"."jovens" "j"
  WHERE ("j"."id" = "namorados"."jovem_id")), ( SELECT "j"."regiao_id"
   FROM "public"."jovens" "j"
  WHERE ("j"."id" = "namorados"."jovem_id")), ( SELECT "j"."igreja_id"
   FROM "public"."jovens" "j"
  WHERE ("j"."id" = "namorados"."jovem_id"))) OR "public"."can_access_jovem_com_associacoes"(( SELECT "j"."estado_id"
   FROM "public"."jovens" "j"
  WHERE ("j"."id" = "namorados"."jovem_id")), ( SELECT "j"."bloco_id"
   FROM "public"."jovens" "j"
  WHERE ("j"."id" = "namorados"."jovem_id")), ( SELECT "j"."regiao_id"
   FROM "public"."jovens" "j"
  WHERE ("j"."id" = "namorados"."jovem_id")), ( SELECT "j"."igreja_id"
   FROM "public"."jovens" "j"
  WHERE ("j"."id" = "namorados"."jovem_id")), "jovem_id") OR "public"."namorado_jovem_pertence_ao_usuario"("jovem_id")));



CREATE POLICY "namorados_select" ON "public"."namorados" FOR SELECT TO "authenticated" USING (("public"."can_access_jovem"(( SELECT "j"."estado_id"
   FROM "public"."jovens" "j"
  WHERE ("j"."id" = "namorados"."jovem_id")), ( SELECT "j"."bloco_id"
   FROM "public"."jovens" "j"
  WHERE ("j"."id" = "namorados"."jovem_id")), ( SELECT "j"."regiao_id"
   FROM "public"."jovens" "j"
  WHERE ("j"."id" = "namorados"."jovem_id")), ( SELECT "j"."igreja_id"
   FROM "public"."jovens" "j"
  WHERE ("j"."id" = "namorados"."jovem_id"))) OR "public"."can_access_jovem_com_associacoes"(( SELECT "j"."estado_id"
   FROM "public"."jovens" "j"
  WHERE ("j"."id" = "namorados"."jovem_id")), ( SELECT "j"."bloco_id"
   FROM "public"."jovens" "j"
  WHERE ("j"."id" = "namorados"."jovem_id")), ( SELECT "j"."regiao_id"
   FROM "public"."jovens" "j"
  WHERE ("j"."id" = "namorados"."jovem_id")), ( SELECT "j"."igreja_id"
   FROM "public"."jovens" "j"
  WHERE ("j"."id" = "namorados"."jovem_id")), "jovem_id") OR "public"."namorado_jovem_pertence_ao_usuario"("jovem_id")));



CREATE POLICY "namorados_update" ON "public"."namorados" FOR UPDATE TO "authenticated" USING (("public"."can_access_jovem"(( SELECT "j"."estado_id"
   FROM "public"."jovens" "j"
  WHERE ("j"."id" = "namorados"."jovem_id")), ( SELECT "j"."bloco_id"
   FROM "public"."jovens" "j"
  WHERE ("j"."id" = "namorados"."jovem_id")), ( SELECT "j"."regiao_id"
   FROM "public"."jovens" "j"
  WHERE ("j"."id" = "namorados"."jovem_id")), ( SELECT "j"."igreja_id"
   FROM "public"."jovens" "j"
  WHERE ("j"."id" = "namorados"."jovem_id"))) OR "public"."can_access_jovem_com_associacoes"(( SELECT "j"."estado_id"
   FROM "public"."jovens" "j"
  WHERE ("j"."id" = "namorados"."jovem_id")), ( SELECT "j"."bloco_id"
   FROM "public"."jovens" "j"
  WHERE ("j"."id" = "namorados"."jovem_id")), ( SELECT "j"."regiao_id"
   FROM "public"."jovens" "j"
  WHERE ("j"."id" = "namorados"."jovem_id")), ( SELECT "j"."igreja_id"
   FROM "public"."jovens" "j"
  WHERE ("j"."id" = "namorados"."jovem_id")), "jovem_id") OR "public"."namorado_jovem_pertence_ao_usuario"("jovem_id")));



ALTER TABLE "public"."notificacoes" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."regioes" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "regioes_delete_admin" ON "public"."regioes" FOR DELETE USING ((EXISTS ( SELECT 1
   FROM "public"."usuarios" "u"
  WHERE (("u"."id_auth" = "auth"."uid"()) AND ("u"."nivel" = 'administrador'::"text")))));



CREATE POLICY "regioes_insert_admin" ON "public"."regioes" FOR INSERT WITH CHECK (((EXISTS ( SELECT 1
   FROM "public"."usuarios" "u"
  WHERE (("u"."id_auth" = "auth"."uid"()) AND ("u"."nivel" = 'administrador'::"text")))) OR (EXISTS ( SELECT 1
   FROM "public"."usuarios" "u"
  WHERE (("u"."id_auth" = "auth"."uid"()) AND ("u"."nivel" = ANY (ARRAY['lider_nacional_iurd'::"text", 'lider_nacional_fju'::"text"]))))) OR (EXISTS ( SELECT 1
   FROM ("public"."usuarios" "u"
     JOIN "public"."blocos" "b" ON (("b"."id" = "regioes"."bloco_id")))
  WHERE (("u"."id_auth" = "auth"."uid"()) AND ("u"."nivel" = ANY (ARRAY['lider_estadual_iurd'::"text", 'lider_estadual_fju'::"text"])) AND ("u"."estado_id" = "b"."estado_id")))) OR (EXISTS ( SELECT 1
   FROM "public"."usuarios" "u"
  WHERE (("u"."id_auth" = "auth"."uid"()) AND ("u"."nivel" = ANY (ARRAY['lider_bloco_iurd'::"text", 'lider_bloco_fju'::"text"])) AND ("u"."bloco_id" = "regioes"."bloco_id"))))));



CREATE POLICY "regioes_select_all" ON "public"."regioes" FOR SELECT USING (true);



CREATE POLICY "regioes_update_admin" ON "public"."regioes" FOR UPDATE USING (((EXISTS ( SELECT 1
   FROM "public"."usuarios" "u"
  WHERE (("u"."id_auth" = "auth"."uid"()) AND ("u"."nivel" = 'administrador'::"text")))) OR (EXISTS ( SELECT 1
   FROM "public"."usuarios" "u"
  WHERE (("u"."id_auth" = "auth"."uid"()) AND ("u"."nivel" = ANY (ARRAY['lider_nacional_iurd'::"text", 'lider_nacional_fju'::"text"]))))) OR (EXISTS ( SELECT 1
   FROM ("public"."usuarios" "u"
     JOIN "public"."blocos" "b" ON (("b"."id" = "regioes"."bloco_id")))
  WHERE (("u"."id_auth" = "auth"."uid"()) AND ("u"."nivel" = ANY (ARRAY['lider_estadual_iurd'::"text", 'lider_estadual_fju'::"text"])) AND ("u"."estado_id" = "b"."estado_id")))) OR (EXISTS ( SELECT 1
   FROM "public"."usuarios" "u"
  WHERE (("u"."id_auth" = "auth"."uid"()) AND ("u"."nivel" = ANY (ARRAY['lider_bloco_iurd'::"text", 'lider_bloco_fju'::"text"])) AND ("u"."bloco_id" = "regioes"."bloco_id")))))) WITH CHECK (((EXISTS ( SELECT 1
   FROM "public"."usuarios" "u"
  WHERE (("u"."id_auth" = "auth"."uid"()) AND ("u"."nivel" = 'administrador'::"text")))) OR (EXISTS ( SELECT 1
   FROM "public"."usuarios" "u"
  WHERE (("u"."id_auth" = "auth"."uid"()) AND ("u"."nivel" = ANY (ARRAY['lider_nacional_iurd'::"text", 'lider_nacional_fju'::"text"]))))) OR (EXISTS ( SELECT 1
   FROM ("public"."usuarios" "u"
     JOIN "public"."blocos" "b" ON (("b"."id" = "regioes"."bloco_id")))
  WHERE (("u"."id_auth" = "auth"."uid"()) AND ("u"."nivel" = ANY (ARRAY['lider_estadual_iurd'::"text", 'lider_estadual_fju'::"text"])) AND ("u"."estado_id" = "b"."estado_id")))) OR (EXISTS ( SELECT 1
   FROM "public"."usuarios" "u"
  WHERE (("u"."id_auth" = "auth"."uid"()) AND ("u"."nivel" = ANY (ARRAY['lider_bloco_iurd'::"text", 'lider_bloco_fju'::"text"])) AND ("u"."bloco_id" = "regioes"."bloco_id"))))));



ALTER TABLE "public"."roles" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."sessoes_usuario" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."user_roles" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "storage"."buckets" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "storage"."buckets_analytics" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "storage"."buckets_vectors" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "fotos_jovens_delete" ON "storage"."objects" FOR DELETE TO "authenticated" USING (("bucket_id" = 'fotos_jovens'::"text"));



CREATE POLICY "fotos_jovens_insert" ON "storage"."objects" FOR INSERT TO "authenticated" WITH CHECK (("bucket_id" = 'fotos_jovens'::"text"));



CREATE POLICY "fotos_jovens_select" ON "storage"."objects" FOR SELECT USING (("bucket_id" = 'fotos_jovens'::"text"));



CREATE POLICY "fotos_jovens_update" ON "storage"."objects" FOR UPDATE TO "authenticated" USING (("bucket_id" = 'fotos_jovens'::"text"));



CREATE POLICY "fotos_nucleos_delete" ON "storage"."objects" FOR DELETE TO "authenticated" USING (("bucket_id" = 'fotos_nucleos'::"text"));



CREATE POLICY "fotos_nucleos_insert" ON "storage"."objects" FOR INSERT TO "authenticated" WITH CHECK (("bucket_id" = 'fotos_nucleos'::"text"));



CREATE POLICY "fotos_nucleos_select" ON "storage"."objects" FOR SELECT USING (("bucket_id" = 'fotos_nucleos'::"text"));



CREATE POLICY "fotos_nucleos_update" ON "storage"."objects" FOR UPDATE TO "authenticated" USING (("bucket_id" = 'fotos_nucleos'::"text"));



CREATE POLICY "fotos_usuarios_delete" ON "storage"."objects" FOR DELETE TO "authenticated" USING ((("bucket_id" = 'fotos_usuarios'::"text") AND (("owner" = "auth"."uid"()) OR (("storage"."foldername"("name"))[1] = ( SELECT ("usuarios"."id")::"text" AS "id"
   FROM "public"."usuarios"
  WHERE ("usuarios"."id_auth" = "auth"."uid"())
 LIMIT 1)))));



CREATE POLICY "fotos_usuarios_insert" ON "storage"."objects" FOR INSERT TO "authenticated" WITH CHECK (("bucket_id" = 'fotos_usuarios'::"text"));



CREATE POLICY "fotos_usuarios_select" ON "storage"."objects" FOR SELECT USING (("bucket_id" = 'fotos_usuarios'::"text"));



CREATE POLICY "fotos_usuarios_update" ON "storage"."objects" FOR UPDATE TO "authenticated" USING ((("bucket_id" = 'fotos_usuarios'::"text") AND (("owner" = "auth"."uid"()) OR (("storage"."foldername"("name"))[1] = ( SELECT ("usuarios"."id")::"text" AS "id"
   FROM "public"."usuarios"
  WHERE ("usuarios"."id_auth" = "auth"."uid"())
 LIMIT 1)))));



ALTER TABLE "storage"."migrations" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "storage"."objects" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "storage"."s3_multipart_uploads" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "storage"."s3_multipart_uploads_parts" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "storage"."vector_indexes" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "viagens_delete" ON "storage"."objects" FOR DELETE TO "authenticated" USING (("bucket_id" = 'viagens'::"text"));



CREATE POLICY "viagens_insert" ON "storage"."objects" FOR INSERT TO "authenticated" WITH CHECK (("bucket_id" = 'viagens'::"text"));



CREATE POLICY "viagens_select" ON "storage"."objects" FOR SELECT USING (("bucket_id" = 'viagens'::"text"));



CREATE POLICY "viagens_update" ON "storage"."objects" FOR UPDATE TO "authenticated" USING (("bucket_id" = 'viagens'::"text"));



GRANT USAGE ON SCHEMA "auth" TO "anon";
GRANT USAGE ON SCHEMA "auth" TO "authenticated";
GRANT USAGE ON SCHEMA "auth" TO "service_role";
GRANT ALL ON SCHEMA "auth" TO "supabase_auth_admin";
GRANT ALL ON SCHEMA "auth" TO "dashboard_user";
GRANT USAGE ON SCHEMA "auth" TO "postgres";



GRANT USAGE ON SCHEMA "public" TO "postgres";
GRANT USAGE ON SCHEMA "public" TO "anon";
GRANT USAGE ON SCHEMA "public" TO "authenticated";
GRANT USAGE ON SCHEMA "public" TO "service_role";



GRANT USAGE ON SCHEMA "storage" TO "postgres" WITH GRANT OPTION;
GRANT USAGE ON SCHEMA "storage" TO "anon";
GRANT USAGE ON SCHEMA "storage" TO "authenticated";
GRANT USAGE ON SCHEMA "storage" TO "service_role";
GRANT ALL ON SCHEMA "storage" TO "supabase_storage_admin" WITH GRANT OPTION;
GRANT ALL ON SCHEMA "storage" TO "dashboard_user";



GRANT ALL ON FUNCTION "auth"."email"() TO "dashboard_user";



GRANT ALL ON FUNCTION "auth"."jwt"() TO "postgres";
GRANT ALL ON FUNCTION "auth"."jwt"() TO "dashboard_user";



GRANT ALL ON FUNCTION "auth"."role"() TO "dashboard_user";



GRANT ALL ON FUNCTION "auth"."uid"() TO "dashboard_user";



GRANT ALL ON FUNCTION "public"."aprovar_jovem_multiplo"("p_jovem_id" "uuid", "p_tipo_aprovacao" "text", "p_observacao" "text") TO "anon";
GRANT ALL ON FUNCTION "public"."aprovar_jovem_multiplo"("p_jovem_id" "uuid", "p_tipo_aprovacao" "text", "p_observacao" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."aprovar_jovem_multiplo"("p_jovem_id" "uuid", "p_tipo_aprovacao" "text", "p_observacao" "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."atribuir_papel_padrao_jovem"() TO "anon";
GRANT ALL ON FUNCTION "public"."atribuir_papel_padrao_jovem"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."atribuir_papel_padrao_jovem"() TO "service_role";



GRANT ALL ON FUNCTION "public"."atribuir_papel_usuario"("p_usuario_id" "uuid", "p_role_id" "uuid", "p_estado_id" "uuid", "p_bloco_id" "uuid", "p_regiao_id" "uuid", "p_igreja_id" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."atribuir_papel_usuario"("p_usuario_id" "uuid", "p_role_id" "uuid", "p_estado_id" "uuid", "p_bloco_id" "uuid", "p_regiao_id" "uuid", "p_igreja_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."atribuir_papel_usuario"("p_usuario_id" "uuid", "p_role_id" "uuid", "p_estado_id" "uuid", "p_bloco_id" "uuid", "p_regiao_id" "uuid", "p_igreja_id" "uuid") TO "service_role";



GRANT ALL ON FUNCTION "public"."atualizar_namorados_updated_at"() TO "anon";
GRANT ALL ON FUNCTION "public"."atualizar_namorados_updated_at"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."atualizar_namorados_updated_at"() TO "service_role";



GRANT ALL ON FUNCTION "public"."atualizar_status_jovem"("p_jovem_id" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."atualizar_status_jovem"("p_jovem_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."atualizar_status_jovem"("p_jovem_id" "uuid") TO "service_role";



GRANT ALL ON FUNCTION "public"."atualizar_timestamp"() TO "anon";
GRANT ALL ON FUNCTION "public"."atualizar_timestamp"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."atualizar_timestamp"() TO "service_role";



GRANT ALL ON FUNCTION "public"."atualizar_timestamp_aprovacoes"() TO "anon";
GRANT ALL ON FUNCTION "public"."atualizar_timestamp_aprovacoes"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."atualizar_timestamp_aprovacoes"() TO "service_role";



GRANT ALL ON FUNCTION "public"."atualizar_usuario_admin"("p_usuario_id" "uuid", "p_nome" "text", "p_email" "text", "p_sexo" "text", "p_foto" "text", "p_nivel" "text", "p_ativo" boolean) TO "anon";
GRANT ALL ON FUNCTION "public"."atualizar_usuario_admin"("p_usuario_id" "uuid", "p_nome" "text", "p_email" "text", "p_sexo" "text", "p_foto" "text", "p_nivel" "text", "p_ativo" boolean) TO "authenticated";
GRANT ALL ON FUNCTION "public"."atualizar_usuario_admin"("p_usuario_id" "uuid", "p_nome" "text", "p_email" "text", "p_sexo" "text", "p_foto" "text", "p_nivel" "text", "p_ativo" boolean) TO "service_role";



GRANT ALL ON FUNCTION "public"."buscar_aprovacoes_jovem"("p_jovem_id" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."buscar_aprovacoes_jovem"("p_jovem_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."buscar_aprovacoes_jovem"("p_jovem_id" "uuid") TO "service_role";



GRANT ALL ON FUNCTION "public"."buscar_papeis_disponiveis"() TO "anon";
GRANT ALL ON FUNCTION "public"."buscar_papeis_disponiveis"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."buscar_papeis_disponiveis"() TO "service_role";



GRANT ALL ON FUNCTION "public"."buscar_papeis_usuario"("p_usuario_id" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."buscar_papeis_usuario"("p_usuario_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."buscar_papeis_usuario"("p_usuario_id" "uuid") TO "service_role";



GRANT ALL ON FUNCTION "public"."buscar_usuarios_com_ultimo_acesso"() TO "anon";
GRANT ALL ON FUNCTION "public"."buscar_usuarios_com_ultimo_acesso"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."buscar_usuarios_com_ultimo_acesso"() TO "service_role";



GRANT ALL ON FUNCTION "public"."can_access_jovem"("jovem_estado_id" "uuid", "jovem_bloco_id" "uuid", "jovem_regiao_id" "uuid", "jovem_igreja_id" "uuid", "p_jovem_id" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."can_access_jovem"("jovem_estado_id" "uuid", "jovem_bloco_id" "uuid", "jovem_regiao_id" "uuid", "jovem_igreja_id" "uuid", "p_jovem_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."can_access_jovem"("jovem_estado_id" "uuid", "jovem_bloco_id" "uuid", "jovem_regiao_id" "uuid", "jovem_igreja_id" "uuid", "p_jovem_id" "uuid") TO "service_role";



GRANT ALL ON FUNCTION "public"."can_access_jovem_com_associacoes"("jovem_estado_id" "uuid", "jovem_bloco_id" "uuid", "jovem_regiao_id" "uuid", "jovem_igreja_id" "uuid", "jovem_id" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."can_access_jovem_com_associacoes"("jovem_estado_id" "uuid", "jovem_bloco_id" "uuid", "jovem_regiao_id" "uuid", "jovem_igreja_id" "uuid", "jovem_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."can_access_jovem_com_associacoes"("jovem_estado_id" "uuid", "jovem_bloco_id" "uuid", "jovem_regiao_id" "uuid", "jovem_igreja_id" "uuid", "jovem_id" "uuid") TO "service_role";



GRANT ALL ON FUNCTION "public"."can_access_viagem_by_level"("jovem_estado_id" "uuid", "jovem_bloco_id" "uuid", "jovem_regiao_id" "uuid", "jovem_igreja_id" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."can_access_viagem_by_level"("jovem_estado_id" "uuid", "jovem_bloco_id" "uuid", "jovem_regiao_id" "uuid", "jovem_igreja_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."can_access_viagem_by_level"("jovem_estado_id" "uuid", "jovem_bloco_id" "uuid", "jovem_regiao_id" "uuid", "jovem_igreja_id" "uuid") TO "service_role";



GRANT ALL ON FUNCTION "public"."criar_lembretes_avaliacao"() TO "anon";
GRANT ALL ON FUNCTION "public"."criar_lembretes_avaliacao"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."criar_lembretes_avaliacao"() TO "service_role";



GRANT ALL ON FUNCTION "public"."criar_log_auditoria"("p_usuario_id" "uuid", "p_acao" character varying, "p_detalhe" "text", "p_dados_antigos" "jsonb", "p_dados_novos" "jsonb") TO "anon";
GRANT ALL ON FUNCTION "public"."criar_log_auditoria"("p_usuario_id" "uuid", "p_acao" character varying, "p_detalhe" "text", "p_dados_antigos" "jsonb", "p_dados_novos" "jsonb") TO "authenticated";
GRANT ALL ON FUNCTION "public"."criar_log_auditoria"("p_usuario_id" "uuid", "p_acao" character varying, "p_detalhe" "text", "p_dados_antigos" "jsonb", "p_dados_novos" "jsonb") TO "service_role";



GRANT ALL ON FUNCTION "public"."criar_notificacao_automatica"() TO "anon";
GRANT ALL ON FUNCTION "public"."criar_notificacao_automatica"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."criar_notificacao_automatica"() TO "service_role";



GRANT ALL ON FUNCTION "public"."estatisticas_acesso_usuarios"() TO "anon";
GRANT ALL ON FUNCTION "public"."estatisticas_acesso_usuarios"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."estatisticas_acesso_usuarios"() TO "service_role";



GRANT ALL ON FUNCTION "public"."filtrar_jovens"("filters" "jsonb") TO "anon";
GRANT ALL ON FUNCTION "public"."filtrar_jovens"("filters" "jsonb") TO "authenticated";
GRANT ALL ON FUNCTION "public"."filtrar_jovens"("filters" "jsonb") TO "service_role";



GRANT ALL ON FUNCTION "public"."get_jovem_completo"("p_jovem_id" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."get_jovem_completo"("p_jovem_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."get_jovem_completo"("p_jovem_id" "uuid") TO "service_role";



GRANT ALL ON FUNCTION "public"."get_jovens_por_estado_count"("p_edicao_id" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."get_jovens_por_estado_count"("p_edicao_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."get_jovens_por_estado_count"("p_edicao_id" "uuid") TO "service_role";



GRANT ALL ON FUNCTION "public"."get_user_by_auth_id"("auth_id" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."get_user_by_auth_id"("auth_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."get_user_by_auth_id"("auth_id" "uuid") TO "service_role";



GRANT ALL ON FUNCTION "public"."get_user_hierarchy_level"() TO "anon";
GRANT ALL ON FUNCTION "public"."get_user_hierarchy_level"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."get_user_hierarchy_level"() TO "service_role";



GRANT ALL ON FUNCTION "public"."get_user_roles"() TO "anon";
GRANT ALL ON FUNCTION "public"."get_user_roles"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."get_user_roles"() TO "service_role";



GRANT ALL ON FUNCTION "public"."handle_new_auth_user"() TO "anon";
GRANT ALL ON FUNCTION "public"."handle_new_auth_user"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."handle_new_auth_user"() TO "service_role";



GRANT ALL ON FUNCTION "public"."has_role"("role_slug" "text") TO "anon";
GRANT ALL ON FUNCTION "public"."has_role"("role_slug" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."has_role"("role_slug" "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."is_admin_user"() TO "anon";
GRANT ALL ON FUNCTION "public"."is_admin_user"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."is_admin_user"() TO "service_role";



GRANT ALL ON FUNCTION "public"."limpar_acessos_antigos"("dias_para_manter" integer) TO "anon";
GRANT ALL ON FUNCTION "public"."limpar_acessos_antigos"("dias_para_manter" integer) TO "authenticated";
GRANT ALL ON FUNCTION "public"."limpar_acessos_antigos"("dias_para_manter" integer) TO "service_role";



GRANT ALL ON FUNCTION "public"."limpar_logs_antigos"("dias_retencao" integer) TO "anon";
GRANT ALL ON FUNCTION "public"."limpar_logs_antigos"("dias_retencao" integer) TO "authenticated";
GRANT ALL ON FUNCTION "public"."limpar_logs_antigos"("dias_retencao" integer) TO "service_role";



GRANT ALL ON FUNCTION "public"."limpar_notificacoes_antigas"() TO "anon";
GRANT ALL ON FUNCTION "public"."limpar_notificacoes_antigas"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."limpar_notificacoes_antigas"() TO "service_role";



GRANT ALL ON FUNCTION "public"."namorado_jovem_pertence_ao_usuario"("p_jovem_id" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."namorado_jovem_pertence_ao_usuario"("p_jovem_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."namorado_jovem_pertence_ao_usuario"("p_jovem_id" "uuid") TO "service_role";



GRANT ALL ON FUNCTION "public"."notificar_associacao_jovem"("p_jovem_id" "uuid", "p_usuario_associado_id" "uuid", "p_titulo" "text", "p_mensagem" "text", "p_acao_url" "text") TO "anon";
GRANT ALL ON FUNCTION "public"."notificar_associacao_jovem"("p_jovem_id" "uuid", "p_usuario_associado_id" "uuid", "p_titulo" "text", "p_mensagem" "text", "p_acao_url" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."notificar_associacao_jovem"("p_jovem_id" "uuid", "p_usuario_associado_id" "uuid", "p_titulo" "text", "p_mensagem" "text", "p_acao_url" "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."notificar_evento_jovem"("p_jovem_id" "uuid", "p_tipo" "text", "p_titulo" "text", "p_mensagem" "text", "p_remetente_id" "uuid", "p_acao_url" "text") TO "anon";
GRANT ALL ON FUNCTION "public"."notificar_evento_jovem"("p_jovem_id" "uuid", "p_tipo" "text", "p_titulo" "text", "p_mensagem" "text", "p_remetente_id" "uuid", "p_acao_url" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."notificar_evento_jovem"("p_jovem_id" "uuid", "p_tipo" "text", "p_titulo" "text", "p_mensagem" "text", "p_remetente_id" "uuid", "p_acao_url" "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."notificar_lideres"("p_tipo" "text", "p_titulo" "text", "p_mensagem" "text", "p_jovem_id" "uuid", "p_acao_url" "text") TO "anon";
GRANT ALL ON FUNCTION "public"."notificar_lideres"("p_tipo" "text", "p_titulo" "text", "p_mensagem" "text", "p_jovem_id" "uuid", "p_acao_url" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."notificar_lideres"("p_tipo" "text", "p_titulo" "text", "p_mensagem" "text", "p_jovem_id" "uuid", "p_acao_url" "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."obter_estatisticas_sistema"() TO "anon";
GRANT ALL ON FUNCTION "public"."obter_estatisticas_sistema"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."obter_estatisticas_sistema"() TO "service_role";



GRANT ALL ON FUNCTION "public"."obter_lideres_para_notificacao"("p_estado_id" "uuid", "p_bloco_id" "uuid", "p_regiao_id" "uuid", "p_igreja_id" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."obter_lideres_para_notificacao"("p_estado_id" "uuid", "p_bloco_id" "uuid", "p_regiao_id" "uuid", "p_igreja_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."obter_lideres_para_notificacao"("p_estado_id" "uuid", "p_bloco_id" "uuid", "p_regiao_id" "uuid", "p_igreja_id" "uuid") TO "service_role";



GRANT ALL ON FUNCTION "public"."recalcular_idade"() TO "anon";
GRANT ALL ON FUNCTION "public"."recalcular_idade"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."recalcular_idade"() TO "service_role";



GRANT ALL ON FUNCTION "public"."registrar_acesso_manual"("p_usuario_id" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."registrar_acesso_manual"("p_usuario_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."registrar_acesso_manual"("p_usuario_id" "uuid") TO "service_role";



GRANT ALL ON FUNCTION "public"."registrar_ultimo_acesso"() TO "anon";
GRANT ALL ON FUNCTION "public"."registrar_ultimo_acesso"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."registrar_ultimo_acesso"() TO "service_role";



GRANT ALL ON FUNCTION "public"."remover_aprovacao_admin"("p_aprovacao_id" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."remover_aprovacao_admin"("p_aprovacao_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."remover_aprovacao_admin"("p_aprovacao_id" "uuid") TO "service_role";



GRANT ALL ON FUNCTION "public"."remover_papel_usuario"("p_papel_id" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."remover_papel_usuario"("p_papel_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."remover_papel_usuario"("p_papel_id" "uuid") TO "service_role";



GRANT ALL ON FUNCTION "public"."set_usuario_id_dados_viagem"() TO "anon";
GRANT ALL ON FUNCTION "public"."set_usuario_id_dados_viagem"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."set_usuario_id_dados_viagem"() TO "service_role";



GRANT ALL ON FUNCTION "public"."set_usuario_id_on_insert"() TO "anon";
GRANT ALL ON FUNCTION "public"."set_usuario_id_on_insert"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."set_usuario_id_on_insert"() TO "service_role";



GRANT ALL ON FUNCTION "public"."sincronizar_nivel_com_papeis"("p_usuario_id" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."sincronizar_nivel_com_papeis"("p_usuario_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."sincronizar_nivel_com_papeis"("p_usuario_id" "uuid") TO "service_role";



GRANT ALL ON FUNCTION "public"."test_access_simple"() TO "anon";
GRANT ALL ON FUNCTION "public"."test_access_simple"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."test_access_simple"() TO "service_role";



GRANT ALL ON FUNCTION "public"."test_access_simple_return"() TO "anon";
GRANT ALL ON FUNCTION "public"."test_access_simple_return"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."test_access_simple_return"() TO "service_role";



GRANT ALL ON FUNCTION "public"."test_lider_nacional"() TO "anon";
GRANT ALL ON FUNCTION "public"."test_lider_nacional"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."test_lider_nacional"() TO "service_role";



GRANT ALL ON FUNCTION "public"."trigger_notificar_mudanca_status"() TO "anon";
GRANT ALL ON FUNCTION "public"."trigger_notificar_mudanca_status"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."trigger_notificar_mudanca_status"() TO "service_role";



GRANT ALL ON FUNCTION "public"."trigger_notificar_nova_avaliacao"() TO "anon";
GRANT ALL ON FUNCTION "public"."trigger_notificar_nova_avaliacao"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."trigger_notificar_nova_avaliacao"() TO "service_role";



GRANT ALL ON FUNCTION "public"."trigger_notificar_novo_cadastro"() TO "anon";
GRANT ALL ON FUNCTION "public"."trigger_notificar_novo_cadastro"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."trigger_notificar_novo_cadastro"() TO "service_role";



GRANT ALL ON FUNCTION "public"."trigger_registrar_acesso"() TO "anon";
GRANT ALL ON FUNCTION "public"."trigger_registrar_acesso"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."trigger_registrar_acesso"() TO "service_role";



GRANT ALL ON FUNCTION "public"."trigger_sincronizar_nivel"() TO "anon";
GRANT ALL ON FUNCTION "public"."trigger_sincronizar_nivel"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."trigger_sincronizar_nivel"() TO "service_role";



GRANT ALL ON FUNCTION "public"."update_dados_nucleo_updated_at"() TO "anon";
GRANT ALL ON FUNCTION "public"."update_dados_nucleo_updated_at"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."update_dados_nucleo_updated_at"() TO "service_role";



GRANT ALL ON FUNCTION "public"."usuario_ja_aprovou"("p_jovem_id" "uuid", "p_tipo_aprovacao" "text") TO "anon";
GRANT ALL ON FUNCTION "public"."usuario_ja_aprovou"("p_jovem_id" "uuid", "p_tipo_aprovacao" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."usuario_ja_aprovou"("p_jovem_id" "uuid", "p_tipo_aprovacao" "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."verificar_integridade_funcoes"() TO "anon";
GRANT ALL ON FUNCTION "public"."verificar_integridade_funcoes"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."verificar_integridade_funcoes"() TO "service_role";



GRANT ALL ON TABLE "auth"."audit_log_entries" TO "dashboard_user";
GRANT INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,MAINTAIN,UPDATE ON TABLE "auth"."audit_log_entries" TO "postgres";
GRANT SELECT ON TABLE "auth"."audit_log_entries" TO "postgres" WITH GRANT OPTION;



GRANT ALL ON TABLE "auth"."custom_oauth_providers" TO "postgres";
GRANT ALL ON TABLE "auth"."custom_oauth_providers" TO "dashboard_user";



GRANT INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,MAINTAIN,UPDATE ON TABLE "auth"."flow_state" TO "postgres";
GRANT SELECT ON TABLE "auth"."flow_state" TO "postgres" WITH GRANT OPTION;
GRANT ALL ON TABLE "auth"."flow_state" TO "dashboard_user";



GRANT INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,MAINTAIN,UPDATE ON TABLE "auth"."identities" TO "postgres";
GRANT SELECT ON TABLE "auth"."identities" TO "postgres" WITH GRANT OPTION;
GRANT ALL ON TABLE "auth"."identities" TO "dashboard_user";



GRANT ALL ON TABLE "auth"."instances" TO "dashboard_user";
GRANT INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,MAINTAIN,UPDATE ON TABLE "auth"."instances" TO "postgres";
GRANT SELECT ON TABLE "auth"."instances" TO "postgres" WITH GRANT OPTION;



GRANT INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,MAINTAIN,UPDATE ON TABLE "auth"."mfa_amr_claims" TO "postgres";
GRANT SELECT ON TABLE "auth"."mfa_amr_claims" TO "postgres" WITH GRANT OPTION;
GRANT ALL ON TABLE "auth"."mfa_amr_claims" TO "dashboard_user";



GRANT INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,MAINTAIN,UPDATE ON TABLE "auth"."mfa_challenges" TO "postgres";
GRANT SELECT ON TABLE "auth"."mfa_challenges" TO "postgres" WITH GRANT OPTION;
GRANT ALL ON TABLE "auth"."mfa_challenges" TO "dashboard_user";



GRANT INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,MAINTAIN,UPDATE ON TABLE "auth"."mfa_factors" TO "postgres";
GRANT SELECT ON TABLE "auth"."mfa_factors" TO "postgres" WITH GRANT OPTION;
GRANT ALL ON TABLE "auth"."mfa_factors" TO "dashboard_user";



GRANT ALL ON TABLE "auth"."oauth_authorizations" TO "postgres";
GRANT ALL ON TABLE "auth"."oauth_authorizations" TO "dashboard_user";



GRANT ALL ON TABLE "auth"."oauth_client_states" TO "postgres";
GRANT ALL ON TABLE "auth"."oauth_client_states" TO "dashboard_user";



GRANT ALL ON TABLE "auth"."oauth_clients" TO "postgres";
GRANT ALL ON TABLE "auth"."oauth_clients" TO "dashboard_user";



GRANT ALL ON TABLE "auth"."oauth_consents" TO "postgres";
GRANT ALL ON TABLE "auth"."oauth_consents" TO "dashboard_user";



GRANT INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,MAINTAIN,UPDATE ON TABLE "auth"."one_time_tokens" TO "postgres";
GRANT SELECT ON TABLE "auth"."one_time_tokens" TO "postgres" WITH GRANT OPTION;
GRANT ALL ON TABLE "auth"."one_time_tokens" TO "dashboard_user";



GRANT ALL ON TABLE "auth"."refresh_tokens" TO "dashboard_user";
GRANT INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,MAINTAIN,UPDATE ON TABLE "auth"."refresh_tokens" TO "postgres";
GRANT SELECT ON TABLE "auth"."refresh_tokens" TO "postgres" WITH GRANT OPTION;



GRANT ALL ON SEQUENCE "auth"."refresh_tokens_id_seq" TO "dashboard_user";
GRANT ALL ON SEQUENCE "auth"."refresh_tokens_id_seq" TO "postgres";



GRANT INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,MAINTAIN,UPDATE ON TABLE "auth"."saml_providers" TO "postgres";
GRANT SELECT ON TABLE "auth"."saml_providers" TO "postgres" WITH GRANT OPTION;
GRANT ALL ON TABLE "auth"."saml_providers" TO "dashboard_user";



GRANT INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,MAINTAIN,UPDATE ON TABLE "auth"."saml_relay_states" TO "postgres";
GRANT SELECT ON TABLE "auth"."saml_relay_states" TO "postgres" WITH GRANT OPTION;
GRANT ALL ON TABLE "auth"."saml_relay_states" TO "dashboard_user";



GRANT SELECT ON TABLE "auth"."schema_migrations" TO "postgres" WITH GRANT OPTION;



GRANT INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,MAINTAIN,UPDATE ON TABLE "auth"."sessions" TO "postgres";
GRANT SELECT ON TABLE "auth"."sessions" TO "postgres" WITH GRANT OPTION;
GRANT ALL ON TABLE "auth"."sessions" TO "dashboard_user";



GRANT INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,MAINTAIN,UPDATE ON TABLE "auth"."sso_domains" TO "postgres";
GRANT SELECT ON TABLE "auth"."sso_domains" TO "postgres" WITH GRANT OPTION;
GRANT ALL ON TABLE "auth"."sso_domains" TO "dashboard_user";



GRANT INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,MAINTAIN,UPDATE ON TABLE "auth"."sso_providers" TO "postgres";
GRANT SELECT ON TABLE "auth"."sso_providers" TO "postgres" WITH GRANT OPTION;
GRANT ALL ON TABLE "auth"."sso_providers" TO "dashboard_user";



GRANT ALL ON TABLE "auth"."users" TO "dashboard_user";
GRANT INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,MAINTAIN,UPDATE ON TABLE "auth"."users" TO "postgres";
GRANT SELECT ON TABLE "auth"."users" TO "postgres" WITH GRANT OPTION;



GRANT ALL ON TABLE "auth"."webauthn_challenges" TO "postgres";
GRANT ALL ON TABLE "auth"."webauthn_challenges" TO "dashboard_user";



GRANT ALL ON TABLE "auth"."webauthn_credentials" TO "postgres";
GRANT ALL ON TABLE "auth"."webauthn_credentials" TO "dashboard_user";



GRANT ALL ON TABLE "public"."anti_pausa" TO "anon";
GRANT ALL ON TABLE "public"."anti_pausa" TO "authenticated";
GRANT ALL ON TABLE "public"."anti_pausa" TO "service_role";



GRANT ALL ON SEQUENCE "public"."anti_pausa_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."anti_pausa_id_seq" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."anti_pausa_id_seq" TO "service_role";



GRANT ALL ON TABLE "public"."aprovacoes_jovens" TO "anon";
GRANT ALL ON TABLE "public"."aprovacoes_jovens" TO "authenticated";
GRANT ALL ON TABLE "public"."aprovacoes_jovens" TO "service_role";



GRANT ALL ON TABLE "public"."avaliacoes" TO "anon";
GRANT ALL ON TABLE "public"."avaliacoes" TO "authenticated";
GRANT ALL ON TABLE "public"."avaliacoes" TO "service_role";



GRANT ALL ON TABLE "public"."blocos" TO "anon";
GRANT ALL ON TABLE "public"."blocos" TO "authenticated";
GRANT ALL ON TABLE "public"."blocos" TO "service_role";



GRANT ALL ON TABLE "public"."configuracoes_sistema" TO "anon";
GRANT ALL ON TABLE "public"."configuracoes_sistema" TO "authenticated";
GRANT ALL ON TABLE "public"."configuracoes_sistema" TO "service_role";



GRANT ALL ON TABLE "public"."dados_nucleo" TO "anon";
GRANT ALL ON TABLE "public"."dados_nucleo" TO "authenticated";
GRANT ALL ON TABLE "public"."dados_nucleo" TO "service_role";



GRANT ALL ON TABLE "public"."dados_viagem" TO "anon";
GRANT ALL ON TABLE "public"."dados_viagem" TO "authenticated";
GRANT ALL ON TABLE "public"."dados_viagem" TO "service_role";



GRANT ALL ON TABLE "public"."edicoes" TO "anon";
GRANT ALL ON TABLE "public"."edicoes" TO "authenticated";
GRANT ALL ON TABLE "public"."edicoes" TO "service_role";



GRANT ALL ON TABLE "public"."estados" TO "anon";
GRANT ALL ON TABLE "public"."estados" TO "authenticated";
GRANT ALL ON TABLE "public"."estados" TO "service_role";



GRANT ALL ON TABLE "public"."igrejas" TO "anon";
GRANT ALL ON TABLE "public"."igrejas" TO "authenticated";
GRANT ALL ON TABLE "public"."igrejas" TO "service_role";



GRANT ALL ON TABLE "public"."jovens" TO "anon";
GRANT ALL ON TABLE "public"."jovens" TO "authenticated";
GRANT ALL ON TABLE "public"."jovens" TO "service_role";



GRANT ALL ON TABLE "public"."jovens_usuarios_associacoes" TO "anon";
GRANT ALL ON TABLE "public"."jovens_usuarios_associacoes" TO "authenticated";
GRANT ALL ON TABLE "public"."jovens_usuarios_associacoes" TO "service_role";



GRANT ALL ON TABLE "public"."jovens_view" TO "anon";
GRANT ALL ON TABLE "public"."jovens_view" TO "authenticated";
GRANT ALL ON TABLE "public"."jovens_view" TO "service_role";



GRANT ALL ON TABLE "public"."logs_auditoria" TO "anon";
GRANT ALL ON TABLE "public"."logs_auditoria" TO "authenticated";
GRANT ALL ON TABLE "public"."logs_auditoria" TO "service_role";



GRANT ALL ON TABLE "public"."logs_historico" TO "anon";
GRANT ALL ON TABLE "public"."logs_historico" TO "authenticated";
GRANT ALL ON TABLE "public"."logs_historico" TO "service_role";



GRANT ALL ON TABLE "public"."namorados" TO "anon";
GRANT ALL ON TABLE "public"."namorados" TO "authenticated";
GRANT ALL ON TABLE "public"."namorados" TO "service_role";



GRANT ALL ON TABLE "public"."notificacoes" TO "anon";
GRANT ALL ON TABLE "public"."notificacoes" TO "authenticated";
GRANT ALL ON TABLE "public"."notificacoes" TO "service_role";



GRANT ALL ON TABLE "public"."regioes" TO "anon";
GRANT ALL ON TABLE "public"."regioes" TO "authenticated";
GRANT ALL ON TABLE "public"."regioes" TO "service_role";



GRANT ALL ON TABLE "public"."roles" TO "anon";
GRANT ALL ON TABLE "public"."roles" TO "authenticated";
GRANT ALL ON TABLE "public"."roles" TO "service_role";



GRANT ALL ON TABLE "public"."sessoes_usuario" TO "anon";
GRANT ALL ON TABLE "public"."sessoes_usuario" TO "authenticated";
GRANT ALL ON TABLE "public"."sessoes_usuario" TO "service_role";



GRANT ALL ON TABLE "public"."user_roles" TO "anon";
GRANT ALL ON TABLE "public"."user_roles" TO "authenticated";
GRANT ALL ON TABLE "public"."user_roles" TO "service_role";



GRANT ALL ON TABLE "public"."usuarios" TO "anon";
GRANT ALL ON TABLE "public"."usuarios" TO "authenticated";
GRANT ALL ON TABLE "public"."usuarios" TO "service_role";



REVOKE ALL ON TABLE "storage"."buckets" FROM "supabase_storage_admin";
GRANT ALL ON TABLE "storage"."buckets" TO "supabase_storage_admin" WITH GRANT OPTION;
GRANT ALL ON TABLE "storage"."buckets" TO "service_role";
GRANT ALL ON TABLE "storage"."buckets" TO "authenticated";
GRANT ALL ON TABLE "storage"."buckets" TO "anon";
GRANT ALL ON TABLE "storage"."buckets" TO "postgres" WITH GRANT OPTION;



GRANT ALL ON TABLE "storage"."buckets_analytics" TO "service_role";
GRANT ALL ON TABLE "storage"."buckets_analytics" TO "authenticated";
GRANT ALL ON TABLE "storage"."buckets_analytics" TO "anon";



GRANT SELECT ON TABLE "storage"."buckets_vectors" TO "service_role";
GRANT SELECT ON TABLE "storage"."buckets_vectors" TO "authenticated";
GRANT SELECT ON TABLE "storage"."buckets_vectors" TO "anon";



REVOKE ALL ON TABLE "storage"."objects" FROM "supabase_storage_admin";
GRANT ALL ON TABLE "storage"."objects" TO "supabase_storage_admin" WITH GRANT OPTION;
GRANT ALL ON TABLE "storage"."objects" TO "service_role";
GRANT ALL ON TABLE "storage"."objects" TO "authenticated";
GRANT ALL ON TABLE "storage"."objects" TO "anon";
GRANT ALL ON TABLE "storage"."objects" TO "postgres" WITH GRANT OPTION;



GRANT ALL ON TABLE "storage"."s3_multipart_uploads" TO "service_role";
GRANT SELECT ON TABLE "storage"."s3_multipart_uploads" TO "authenticated";
GRANT SELECT ON TABLE "storage"."s3_multipart_uploads" TO "anon";



GRANT ALL ON TABLE "storage"."s3_multipart_uploads_parts" TO "service_role";
GRANT SELECT ON TABLE "storage"."s3_multipart_uploads_parts" TO "authenticated";
GRANT SELECT ON TABLE "storage"."s3_multipart_uploads_parts" TO "anon";



GRANT SELECT ON TABLE "storage"."vector_indexes" TO "service_role";
GRANT SELECT ON TABLE "storage"."vector_indexes" TO "authenticated";
GRANT SELECT ON TABLE "storage"."vector_indexes" TO "anon";



ALTER DEFAULT PRIVILEGES FOR ROLE "supabase_auth_admin" IN SCHEMA "auth" GRANT ALL ON SEQUENCES TO "postgres";
ALTER DEFAULT PRIVILEGES FOR ROLE "supabase_auth_admin" IN SCHEMA "auth" GRANT ALL ON SEQUENCES TO "dashboard_user";



ALTER DEFAULT PRIVILEGES FOR ROLE "supabase_auth_admin" IN SCHEMA "auth" GRANT ALL ON FUNCTIONS TO "postgres";
ALTER DEFAULT PRIVILEGES FOR ROLE "supabase_auth_admin" IN SCHEMA "auth" GRANT ALL ON FUNCTIONS TO "dashboard_user";



ALTER DEFAULT PRIVILEGES FOR ROLE "supabase_auth_admin" IN SCHEMA "auth" GRANT ALL ON TABLES TO "postgres";
ALTER DEFAULT PRIVILEGES FOR ROLE "supabase_auth_admin" IN SCHEMA "auth" GRANT ALL ON TABLES TO "dashboard_user";



ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES TO "postgres";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES TO "anon";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES TO "authenticated";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES TO "service_role";






ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS TO "postgres";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS TO "anon";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS TO "authenticated";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS TO "service_role";






ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES TO "postgres";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES TO "anon";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES TO "authenticated";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES TO "service_role";






ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "storage" GRANT ALL ON SEQUENCES TO "postgres";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "storage" GRANT ALL ON SEQUENCES TO "anon";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "storage" GRANT ALL ON SEQUENCES TO "authenticated";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "storage" GRANT ALL ON SEQUENCES TO "service_role";



ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "storage" GRANT ALL ON FUNCTIONS TO "postgres";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "storage" GRANT ALL ON FUNCTIONS TO "anon";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "storage" GRANT ALL ON FUNCTIONS TO "authenticated";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "storage" GRANT ALL ON FUNCTIONS TO "service_role";



ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "storage" GRANT ALL ON TABLES TO "postgres";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "storage" GRANT ALL ON TABLES TO "anon";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "storage" GRANT ALL ON TABLES TO "authenticated";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "storage" GRANT ALL ON TABLES TO "service_role";




