-- =====================================================
-- CORREÇÃO DE PROBLEMAS NAS FUNÇÕES DO SISTEMA
-- =====================================================

-- 1. CORRIGIR função atribuir_papel_usuario
-- =====================================================
CREATE OR REPLACE FUNCTION public.atribuir_papel_usuario(
  p_usuario_id uuid, 
  p_role_id uuid, 
  p_estado_id uuid DEFAULT NULL::uuid, 
  p_bloco_id uuid DEFAULT NULL::uuid, 
  p_regiao_id uuid DEFAULT NULL::uuid, 
  p_igreja_id uuid DEFAULT NULL::uuid
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
AS $function$
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
$function$;

-- 2. CORRIGIR função obter_estatisticas_sistema
-- =====================================================
CREATE OR REPLACE FUNCTION public.obter_estatisticas_sistema()
RETURNS json
LANGUAGE plpgsql
SECURITY DEFINER
AS $function$
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
$function$;

-- 3. CORRIGIR função obter_lideres_para_notificacao
-- =====================================================
CREATE OR REPLACE FUNCTION public.obter_lideres_para_notificacao(
  p_estado_id uuid, 
  p_bloco_id uuid, 
  p_regiao_id uuid, 
  p_igreja_id uuid
)
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

-- 4. CORRIGIR função notificar_evento_jovem
-- =====================================================
CREATE OR REPLACE FUNCTION public.notificar_evento_jovem(
  p_jovem_id uuid, 
  p_tipo text, 
  p_titulo text, 
  p_mensagem text, 
  p_remetente_id uuid DEFAULT NULL::uuid, 
  p_acao_url text DEFAULT NULL::text
)
RETURNS integer
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $function$
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
$function$;

-- 5. ADICIONAR função para verificar integridade das funções
-- =====================================================
CREATE OR REPLACE FUNCTION public.verificar_integridade_funcoes()
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
AS $function$
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
$function$;

-- =====================================================
-- EXECUTAR VERIFICAÇÃO
-- =====================================================
SELECT public.verificar_integridade_funcoes() as verificacao_funcoes;
