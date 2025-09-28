-- Sistema de Controle de Último Acesso dos Usuários

-- 1. Adicionar coluna de último acesso na tabela usuarios (se não existir)
ALTER TABLE public.usuarios 
ADD COLUMN IF NOT EXISTS ultimo_acesso TIMESTAMP WITH TIME ZONE DEFAULT NULL;

-- 2. Criar função para registrar último acesso
CREATE OR REPLACE FUNCTION public.registrar_ultimo_acesso()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
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

-- 3. Criar trigger para registrar acesso automaticamente
CREATE OR REPLACE FUNCTION public.trigger_registrar_acesso()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  -- Registrar acesso quando há mudança na sessão
  PERFORM public.registrar_ultimo_acesso();
  RETURN COALESCE(NEW, OLD);
END;
$$;

-- 4. Criar função para buscar usuários com último acesso
CREATE OR REPLACE FUNCTION public.buscar_usuarios_com_ultimo_acesso()
RETURNS TABLE (
  id uuid,
  nome text,
  email text,
  nivel text,
  ativo boolean,
  foto text,
  sexo text,
  criado_em TIMESTAMP WITH TIME ZONE,
  estado_id uuid,
  bloco_id uuid,
  regiao_id uuid,
  igreja_id uuid,
  estado_bandeira text,
  ultimo_acesso TIMESTAMP WITH TIME ZONE,
  dias_sem_acesso INTEGER,
  status_acesso text
)
LANGUAGE plpgsql
SECURITY DEFINER
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

-- 5. Criar função para estatísticas de acesso
CREATE OR REPLACE FUNCTION public.estatisticas_acesso_usuarios()
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
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

-- 6. Criar função para limpar acessos antigos (manutenção)
CREATE OR REPLACE FUNCTION public.limpar_acessos_antigos(dias_para_manter INTEGER DEFAULT 365)
RETURNS INTEGER
LANGUAGE plpgsql
SECURITY DEFINER
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

-- 7. Criar política RLS para proteger dados de acesso
CREATE POLICY "Usuários podem ver seu próprio último acesso" ON public.usuarios
  FOR SELECT USING (id_auth = auth.uid());

CREATE POLICY "Administradores podem ver todos os acessos" ON public.usuarios
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM public.usuarios 
      WHERE id_auth = auth.uid() AND nivel = 'administrador'
    )
  );

-- 8. Função para registrar acesso manual (para testes)
CREATE OR REPLACE FUNCTION public.registrar_acesso_manual(p_usuario_id uuid)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
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
