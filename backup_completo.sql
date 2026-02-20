


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


CREATE EXTENSION IF NOT EXISTS "pg_cron" WITH SCHEMA "pg_catalog";






COMMENT ON SCHEMA "public" IS 'standard public schema';



CREATE EXTENSION IF NOT EXISTS "pg_graphql" WITH SCHEMA "graphql";






CREATE EXTENSION IF NOT EXISTS "pg_stat_statements" WITH SCHEMA "extensions";






CREATE EXTENSION IF NOT EXISTS "pgcrypto" WITH SCHEMA "extensions";






CREATE EXTENSION IF NOT EXISTS "supabase_vault" WITH SCHEMA "vault";






CREATE EXTENSION IF NOT EXISTS "uuid-ossp" WITH SCHEMA "extensions";






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
    )
  ) INTO resultado
  FROM public.jovens j
  LEFT JOIN public.estados e ON e.id = j.estado_id
  LEFT JOIN public.blocos b ON b.id = j.bloco_id
  LEFT JOIN public.regioes r ON r.id = j.regiao_id
  LEFT JOIN public.igrejas i ON i.id = j.igreja_id
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

SET default_tablespace = '';

SET default_table_access_method = "heap";


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
    CONSTRAINT "notificacoes_tipo_check" CHECK ((("tipo")::"text" = ANY ((ARRAY['cadastro'::character varying, 'avaliacao'::character varying, 'aprovacao'::character varying, 'transferencia'::character varying, 'sistema'::character varying])::"text"[])))
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



CREATE OR REPLACE TRIGGER "trg_atribuir_papel_padrao_jovem" AFTER INSERT ON "public"."usuarios" FOR EACH ROW EXECUTE FUNCTION "public"."atribuir_papel_padrao_jovem"();



CREATE OR REPLACE TRIGGER "trg_dados_viagem_set_updated" BEFORE UPDATE ON "public"."dados_viagem" FOR EACH ROW EXECUTE FUNCTION "public"."atualizar_timestamp"();



CREATE OR REPLACE TRIGGER "trg_set_usuario_id_dados_viagem" BEFORE INSERT ON "public"."dados_viagem" FOR EACH ROW EXECUTE FUNCTION "public"."set_usuario_id_dados_viagem"();



CREATE OR REPLACE TRIGGER "trg_set_usuario_id_on_insert" BEFORE INSERT ON "public"."jovens" FOR EACH ROW EXECUTE FUNCTION "public"."set_usuario_id_on_insert"();



CREATE OR REPLACE TRIGGER "trigger_atualizar_timestamp_aprovacoes" BEFORE UPDATE ON "public"."aprovacoes_jovens" FOR EACH ROW EXECUTE FUNCTION "public"."atualizar_timestamp_aprovacoes"();



CREATE OR REPLACE TRIGGER "trigger_atualizar_timestamp_configuracoes" BEFORE UPDATE ON "public"."configuracoes_sistema" FOR EACH ROW EXECUTE FUNCTION "public"."atualizar_timestamp"();



CREATE OR REPLACE TRIGGER "trigger_atualizar_timestamp_notificacoes" BEFORE UPDATE ON "public"."notificacoes" FOR EACH ROW EXECUTE FUNCTION "public"."atualizar_timestamp"();



CREATE OR REPLACE TRIGGER "trigger_atualizar_timestamp_sessoes" BEFORE UPDATE ON "public"."sessoes_usuario" FOR EACH ROW EXECUTE FUNCTION "public"."atualizar_timestamp"();



CREATE OR REPLACE TRIGGER "trigger_mudanca_status_jovem" AFTER UPDATE ON "public"."jovens" FOR EACH ROW EXECUTE FUNCTION "public"."trigger_notificar_mudanca_status"();



CREATE OR REPLACE TRIGGER "trigger_notificacao_avaliacao" AFTER INSERT ON "public"."avaliacoes" FOR EACH ROW EXECUTE FUNCTION "public"."criar_notificacao_automatica"();



CREATE OR REPLACE TRIGGER "trigger_notificacao_jovem" AFTER INSERT ON "public"."jovens" FOR EACH ROW EXECUTE FUNCTION "public"."criar_notificacao_automatica"();



CREATE OR REPLACE TRIGGER "trigger_nova_avaliacao" AFTER INSERT ON "public"."avaliacoes" FOR EACH ROW EXECUTE FUNCTION "public"."trigger_notificar_nova_avaliacao"();



CREATE OR REPLACE TRIGGER "trigger_novo_cadastro_jovem" AFTER INSERT ON "public"."jovens" FOR EACH ROW EXECUTE FUNCTION "public"."trigger_notificar_novo_cadastro"();



CREATE OR REPLACE TRIGGER "trigger_recalcular_idade" BEFORE INSERT OR UPDATE ON "public"."jovens" FOR EACH ROW EXECUTE FUNCTION "public"."recalcular_idade"();



CREATE OR REPLACE TRIGGER "trigger_set_usuario_id_dados_viagem" BEFORE INSERT ON "public"."dados_viagem" FOR EACH ROW EXECUTE FUNCTION "public"."set_usuario_id_dados_viagem"();



CREATE OR REPLACE TRIGGER "trigger_sincronizar_nivel_user_roles" AFTER INSERT OR DELETE OR UPDATE ON "public"."user_roles" FOR EACH ROW EXECUTE FUNCTION "public"."trigger_sincronizar_nivel"();



CREATE OR REPLACE TRIGGER "trigger_update_dados_nucleo_updated_at" BEFORE UPDATE ON "public"."dados_nucleo" FOR EACH ROW EXECUTE FUNCTION "public"."update_dados_nucleo_updated_at"();



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




ALTER PUBLICATION "supabase_realtime" OWNER TO "postgres";









GRANT USAGE ON SCHEMA "public" TO "postgres";
GRANT USAGE ON SCHEMA "public" TO "anon";
GRANT USAGE ON SCHEMA "public" TO "authenticated";
GRANT USAGE ON SCHEMA "public" TO "service_role";














































































































































































GRANT ALL ON FUNCTION "public"."aprovar_jovem_multiplo"("p_jovem_id" "uuid", "p_tipo_aprovacao" "text", "p_observacao" "text") TO "anon";
GRANT ALL ON FUNCTION "public"."aprovar_jovem_multiplo"("p_jovem_id" "uuid", "p_tipo_aprovacao" "text", "p_observacao" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."aprovar_jovem_multiplo"("p_jovem_id" "uuid", "p_tipo_aprovacao" "text", "p_observacao" "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."atribuir_papel_padrao_jovem"() TO "anon";
GRANT ALL ON FUNCTION "public"."atribuir_papel_padrao_jovem"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."atribuir_papel_padrao_jovem"() TO "service_role";



GRANT ALL ON FUNCTION "public"."atribuir_papel_usuario"("p_usuario_id" "uuid", "p_role_id" "uuid", "p_estado_id" "uuid", "p_bloco_id" "uuid", "p_regiao_id" "uuid", "p_igreja_id" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."atribuir_papel_usuario"("p_usuario_id" "uuid", "p_role_id" "uuid", "p_estado_id" "uuid", "p_bloco_id" "uuid", "p_regiao_id" "uuid", "p_igreja_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."atribuir_papel_usuario"("p_usuario_id" "uuid", "p_role_id" "uuid", "p_estado_id" "uuid", "p_bloco_id" "uuid", "p_regiao_id" "uuid", "p_igreja_id" "uuid") TO "service_role";



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































