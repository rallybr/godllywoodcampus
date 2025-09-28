-- =====================================================
-- CORREÇÃO COMPLETA DO SISTEMA DE NÍVEIS GEOGRÁFICOS
-- =====================================================
-- Este script corrige o sistema para que os níveis hierárquicos
-- funcionem corretamente baseado no campo 'nivel' da tabela usuarios

-- ============================================
-- 1. VERIFICAR SITUAÇÃO ATUAL
-- ============================================

-- Verificar políticas atuais da tabela jovens
SELECT 
  'POLÍTICAS ATUAIS DA TABELA JOVENS' as status,
  policyname as nome_politica,
  cmd as comando,
  permissive as permissiva,
  roles as roles_aplicadas
FROM pg_policies 
WHERE tablename = 'jovens'
ORDER BY policyname;

-- Verificar se a função can_access_jovem existe
SELECT 
  'VERIFICAÇÃO DA FUNÇÃO can_access_jovem' as status,
  EXISTS (
    SELECT 1 FROM pg_proc p
    JOIN pg_namespace n ON p.pronamespace = n.oid
    WHERE n.nspname = 'public' AND p.proname = 'can_access_jovem'
  ) as funcao_existe;

-- ============================================
-- 2. CRIAR FUNÇÃO CORRIGIDA BASEADA NO CAMPO NIVEL
-- ============================================

-- Função corrigida que usa o campo 'nivel' da tabela usuarios
CREATE OR REPLACE FUNCTION public.can_access_jovem(
  jovem_estado_id uuid,
  jovem_bloco_id uuid,
  jovem_regiao_id uuid,
  jovem_igreja_id uuid
)
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  current_user_id uuid;
  user_info record;
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
  
  -- 3. LÍDERES ESTADUAIS - Visão estadual
  -- Podem ver tudo de bloco, região e igreja e jovens relacionados
  IF user_info.nivel IN ('lider_estadual_iurd', 'lider_estadual_fju') THEN
    RETURN user_info.estado_id = jovem_estado_id;
  END IF;
  
  -- 4. LÍDERES DE BLOCO - Visão de bloco
  -- Podem ver região, igreja e jovens relacionados
  IF user_info.nivel IN ('lider_bloco_iurd', 'lider_bloco_fju') THEN
    RETURN user_info.bloco_id = jovem_bloco_id;
  END IF;
  
  -- 5. LÍDER REGIONAL - Visão regional
  -- Podem ver todas as igrejas ligadas à região e jovens relacionados
  IF user_info.nivel = 'lider_regional_iurd' THEN
    RETURN user_info.regiao_id = jovem_regiao_id;
  END IF;
  
  -- 6. LÍDER DE IGREJA - Visão de igreja
  -- Podem ver jovens relacionados à igreja
  IF user_info.nivel = 'lider_igreja_iurd' THEN
    RETURN user_info.igreja_id = jovem_igreja_id;
  END IF;
  
  -- 7. COLABORADOR - Acesso aos jovens que cadastrou
  IF user_info.nivel = 'colaborador' THEN
    RETURN EXISTS (
      SELECT 1 FROM public.jovens j
      WHERE j.estado_id = jovem_estado_id
        AND j.bloco_id = jovem_bloco_id
        AND j.regiao_id = jovem_regiao_id
        AND j.igreja_id = jovem_igreja_id
        AND j.usuario_id = current_user_id
    );
  END IF;
  
  -- 8. JOVEM - Acesso APENAS aos seus próprios dados
  IF user_info.nivel = 'jovem' THEN
    RETURN EXISTS (
      SELECT 1 FROM public.jovens j
      WHERE j.estado_id = jovem_estado_id
        AND j.bloco_id = jovem_bloco_id
        AND j.regiao_id = jovem_regiao_id
        AND j.igreja_id = jovem_igreja_id
        AND j.usuario_id = current_user_id
    );
  END IF;
  
  RETURN false;
END;
$$;

-- ============================================
-- 3. LIMPAR POLÍTICAS EXISTENTES
-- ============================================

-- Remover todas as políticas existentes da tabela jovens
DROP POLICY IF EXISTS "jovem pode inserir proprio cadastro" ON public.jovens;
DROP POLICY IF EXISTS "jovem pode ver proprio cadastro" ON public.jovens;
DROP POLICY IF EXISTS "jovens_select_scoped" ON public.jovens;
DROP POLICY IF EXISTS "jovens_insert_self_or_admin" ON public.jovens;
DROP POLICY IF EXISTS "jovens_update_scoped_roles" ON public.jovens;
DROP POLICY IF EXISTS "jovens_delete_admin" ON public.jovens;
DROP POLICY IF EXISTS "jovens_select_own_creator" ON public.jovens;

-- ============================================
-- 4. HABILITAR RLS
-- ============================================

ALTER TABLE public.jovens ENABLE ROW LEVEL SECURITY;

-- ============================================
-- 5. CRIAR POLÍTICAS CORRETAS
-- ============================================

-- Política para SELECT - Acesso baseado na hierarquia
CREATE POLICY "jovens_select_hierarquia" ON public.jovens
FOR SELECT TO authenticated
USING (
  -- O próprio jovem pode ver seu cadastro
  usuario_id = (SELECT id FROM public.usuarios WHERE id_auth = auth.uid())
  OR
  -- Líderes/admin/colab com escopo via can_access_jovem
  can_access_jovem(estado_id, bloco_id, regiao_id, igreja_id)
);

-- Política para INSERT - Cadastro de jovens
CREATE POLICY "jovens_insert_hierarquia" ON public.jovens
FOR INSERT TO authenticated
WITH CHECK (
  -- O jovem pode inserir seu próprio cadastro
  usuario_id = (SELECT id FROM public.usuarios WHERE id_auth = auth.uid())
  OR
  -- Líderes/admin/colab com escopo via can_access_jovem
  can_access_jovem(estado_id, bloco_id, regiao_id, igreja_id)
);

-- Política para UPDATE - Edição de jovens
CREATE POLICY "jovens_update_hierarquia" ON public.jovens
FOR UPDATE TO authenticated
USING (
  -- O próprio jovem pode atualizar seu cadastro
  usuario_id = (SELECT id FROM public.usuarios WHERE id_auth = auth.uid())
  OR
  -- Líderes/admin/colab com escopo via can_access_jovem
  can_access_jovem(estado_id, bloco_id, regiao_id, igreja_id)
)
WITH CHECK (
  -- O próprio jovem pode atualizar seu cadastro
  usuario_id = (SELECT id FROM public.usuarios WHERE id_auth = auth.uid())
  OR
  -- Líderes/admin/colab com escopo via can_access_jovem
  can_access_jovem(estado_id, bloco_id, regiao_id, igreja_id)
);

-- Política para DELETE - Apenas administradores
CREATE POLICY "jovens_delete_admin" ON public.jovens
FOR DELETE TO authenticated
USING (
  -- Apenas administradores podem deletar
  EXISTS (
    SELECT 1 FROM public.usuarios 
    WHERE id_auth = auth.uid() 
    AND nivel = 'administrador'
  )
);

-- ============================================
-- 6. VERIFICAR POLÍTICAS CRIADAS
-- ============================================

-- Listar políticas criadas
SELECT 
  'POLÍTICAS CRIADAS PARA TABELA JOVENS' as status,
  policyname as nome_politica,
  cmd as comando,
  permissive as permissiva,
  roles as roles_aplicadas
FROM pg_policies 
WHERE tablename = 'jovens'
ORDER BY policyname;

-- ============================================
-- 7. TESTAR FUNÇÃO CORRIGIDA
-- ============================================

-- Teste básico da função
SELECT 
  'TESTE DA FUNÇÃO CORRIGIDA' as status,
  can_access_jovem(NULL, NULL, NULL, NULL) as resultado_teste;

-- ============================================
-- 8. RESUMO DA CORREÇÃO
-- ============================================

SELECT 
  'RESUMO DA CORREÇÃO' as status,
  'Sistema corrigido para usar campo nivel da tabela usuarios' as acao_realizada,
  'Líderes estaduais: veem tudo do estado' as comportamento_estadual,
  'Líderes de bloco: veem tudo do bloco' as comportamento_bloco,
  'Líderes regionais: veem tudo da região' as comportamento_regional,
  'Líderes de igreja: veem tudo da igreja' as comportamento_igreja;
