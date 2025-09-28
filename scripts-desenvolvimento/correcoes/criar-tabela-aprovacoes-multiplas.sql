-- =====================================================
-- CRIAR TABELA PARA APROVAÇÕES MÚLTIPLAS
-- =====================================================
-- Esta tabela armazenará todas as aprovações de diferentes usuários
-- para o mesmo jovem, permitindo múltiplas aprovações

-- ============================================
-- 1. CRIAR TABELA aprovacoes_jovens
-- ============================================

CREATE TABLE IF NOT EXISTS public.aprovacoes_jovens (
  id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  jovem_id uuid NOT NULL REFERENCES public.jovens(id) ON DELETE CASCADE,
  usuario_id uuid NOT NULL REFERENCES public.usuarios(id) ON DELETE CASCADE,
  tipo_aprovacao text NOT NULL CHECK (tipo_aprovacao IN ('pre_aprovado', 'aprovado')),
  observacao text,
  criado_em timestamptz DEFAULT now(),
  atualizado_em timestamptz DEFAULT now(),
  
  -- Constraint para evitar aprovação duplicada do mesmo usuário
  UNIQUE(jovem_id, usuario_id, tipo_aprovacao)
);

-- ============================================
-- 2. CRIAR ÍNDICES PARA PERFORMANCE
-- ============================================

-- Índice para buscar aprovações por jovem
CREATE INDEX IF NOT EXISTS idx_aprovacoes_jovens_jovem_id 
ON public.aprovacoes_jovens(jovem_id);

-- Índice para buscar aprovações por usuário
CREATE INDEX IF NOT EXISTS idx_aprovacoes_jovens_usuario_id 
ON public.aprovacoes_jovens(usuario_id);

-- Índice para buscar por tipo de aprovação
CREATE INDEX IF NOT EXISTS idx_aprovacoes_jovens_tipo 
ON public.aprovacoes_jovens(tipo_aprovacao);

-- Índice composto para performance
CREATE INDEX IF NOT EXISTS idx_aprovacoes_jovens_composto 
ON public.aprovacoes_jovens(jovem_id, tipo_aprovacao, criado_em);

-- ============================================
-- 3. CRIAR TRIGGER PARA ATUALIZAR TIMESTAMP
-- ============================================

CREATE OR REPLACE FUNCTION public.atualizar_timestamp_aprovacoes()
RETURNS trigger AS $$
BEGIN
  NEW.atualizado_em = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_atualizar_timestamp_aprovacoes
  BEFORE UPDATE ON public.aprovacoes_jovens
  FOR EACH ROW
  EXECUTE FUNCTION public.atualizar_timestamp_aprovacoes();

-- ============================================
-- 4. CRIAR FUNÇÃO PARA APROVAR JOVEM
-- ============================================

CREATE OR REPLACE FUNCTION public.aprovar_jovem_multiplo(
  p_jovem_id uuid,
  p_tipo_aprovacao text,
  p_observacao text DEFAULT NULL
) RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
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
  
  -- Verificar permissão usando a função can_access_jovem
  IF NOT public.can_access_jovem(
    jovem_info.estado_id, 
    jovem_info.bloco_id, 
    jovem_info.regiao_id, 
    jovem_info.igreja_id
  ) THEN
    RETURN jsonb_build_object('success', false, 'error', 'Sem permissão para aprovar este jovem');
  END IF;
  
  -- Verificar se o tipo de aprovação é válido
  IF p_tipo_aprovacao NOT IN ('pre_aprovado', 'aprovado') THEN
    RETURN jsonb_build_object('success', false, 'error', 'Tipo de aprovação inválido');
  END IF;
  
  -- Inserir ou atualizar aprovação
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

-- ============================================
-- 5. CRIAR FUNÇÃO PARA BUSCAR APROVAÇÕES
-- ============================================

CREATE OR REPLACE FUNCTION public.buscar_aprovacoes_jovem(p_jovem_id uuid)
RETURNS TABLE (
  id uuid,
  usuario_id uuid,
  usuario_nome text,
  usuario_nivel text,
  usuario_estado_bandeira text,
  tipo_aprovacao text,
  observacao text,
  criado_em timestamptz
)
LANGUAGE plpgsql
SECURITY DEFINER
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

-- ============================================
-- 6. CRIAR FUNÇÃO PARA VERIFICAR SE USUÁRIO JÁ APROVOU
-- ============================================

CREATE OR REPLACE FUNCTION public.usuario_ja_aprovou(
  p_jovem_id uuid,
  p_tipo_aprovacao text DEFAULT NULL
) RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
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

-- ============================================
-- 7. CONFIGURAR RLS (ROW LEVEL SECURITY)
-- ============================================

-- Habilitar RLS na tabela
ALTER TABLE public.aprovacoes_jovens ENABLE ROW LEVEL SECURITY;

-- Política para SELECT: usuários podem ver aprovações de jovens que têm acesso
CREATE POLICY "aprovacoes_select_accessible" ON public.aprovacoes_jovens
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM public.jovens j
      WHERE j.id = aprovacoes_jovens.jovem_id
        AND public.can_access_jovem(j.estado_id, j.bloco_id, j.regiao_id, j.igreja_id)
    )
  );

-- Política para INSERT: usuários podem aprovar jovens que têm acesso
CREATE POLICY "aprovacoes_insert_accessible" ON public.aprovacoes_jovens
  FOR INSERT WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.jovens j
      WHERE j.id = aprovacoes_jovens.jovem_id
        AND public.can_access_jovem(j.estado_id, j.bloco_id, j.regiao_id, j.igreja_id)
    )
    AND usuario_id = (SELECT id FROM public.usuarios WHERE id_auth = auth.uid())
  );

-- Política para UPDATE: usuários podem atualizar suas próprias aprovações
CREATE POLICY "aprovacoes_update_own" ON public.aprovacoes_jovens
  FOR UPDATE USING (
    usuario_id = (SELECT id FROM public.usuarios WHERE id_auth = auth.uid())
  );

-- Política para DELETE: apenas administradores podem deletar
CREATE POLICY "aprovacoes_delete_admin" ON public.aprovacoes_jovens
  FOR DELETE USING (
    EXISTS (
      SELECT 1 FROM public.usuarios u
      WHERE u.id_auth = auth.uid()
        AND u.nivel = 'administrador'
    )
  );

-- ============================================
-- 8. MIGRAR DADOS EXISTENTES (SE HOUVER)
-- ============================================

-- Migrar aprovações existentes da tabela jovens para a nova tabela
INSERT INTO public.aprovacoes_jovens (jovem_id, usuario_id, tipo_aprovacao, observacao)
SELECT 
  j.id as jovem_id,
  j.usuario_id, -- Assumindo que o criador foi quem aprovou
  j.aprovado as tipo_aprovacao,
  'Migração automática do sistema anterior' as observacao
FROM public.jovens j
WHERE j.aprovado IS NOT NULL 
  AND j.aprovado != 'null'
  AND j.aprovado IN ('pre_aprovado', 'aprovado')
ON CONFLICT (jovem_id, usuario_id, tipo_aprovacao) DO NOTHING;

-- ============================================
-- 9. VERIFICAR SE A CRIAÇÃO FOI BEM-SUCEDIDA
-- ============================================

-- Verificar se a tabela foi criada
SELECT 
  'TABELA CRIADA' as status,
  schemaname,
  tablename,
  tableowner
FROM pg_tables 
WHERE tablename = 'aprovacoes_jovens' 
  AND schemaname = 'public';

-- Verificar se as funções foram criadas
SELECT 
  'FUNÇÕES CRIADAS' as status,
  proname as nome_funcao,
  prokind as tipo_funcao
FROM pg_proc p
JOIN pg_namespace n ON p.pronamespace = n.oid
WHERE n.nspname = 'public' 
  AND proname IN ('aprovar_jovem_multiplo', 'buscar_aprovacoes_jovem', 'usuario_ja_aprovou');

-- Verificar se as políticas RLS foram criadas
SELECT 
  'POLÍTICAS RLS CRIADAS' as status,
  policyname,
  cmd,
  permissive
FROM pg_policies 
WHERE tablename = 'aprovacoes_jovens'
ORDER BY policyname;
