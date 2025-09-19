-- Script para recriar as políticas originais que estavam funcionando
-- Baseado no documento POLITICAS_RLS_COMPLETAS.md

-- ============================================
-- 1. REMOVER TODAS AS POLÍTICAS ATUAIS
-- ============================================

-- Listar políticas antes da remoção
SELECT 
  'POLÍTICAS ANTES DA REMOÇÃO:' as status,
  policyname as nome_politica,
  cmd as comando
FROM pg_policies 
WHERE tablename = 'jovens'
ORDER BY policyname;

-- Remover todas as políticas existentes
DROP POLICY IF EXISTS "jovem pode inserir proprio cadastro" ON public.jovens;
DROP POLICY IF EXISTS "jovem pode ver proprio cadastro" ON public.jovens;
DROP POLICY IF EXISTS "jovens_select_scoped" ON public.jovens;
DROP POLICY IF EXISTS "jovens_insert_self_or_admin" ON public.jovens;
DROP POLICY IF EXISTS "jovens_update_scoped_roles" ON public.jovens;
DROP POLICY IF EXISTS "jovens_delete_admin" ON public.jovens;

-- ============================================
-- 2. GARANTIR QUE RLS ESTÁ HABILITADO
-- ============================================

ALTER TABLE public.jovens ENABLE ROW LEVEL SECURITY;

-- ============================================
-- 3. RECRIAR AS POLÍTICAS ORIGINAIS
-- ============================================

-- Política 1: jovem pode inserir proprio cadastro (INSERT)
CREATE POLICY "jovem pode inserir proprio cadastro" ON public.jovens
FOR INSERT TO authenticated
WITH CHECK (
  -- O jovem pode inserir seu próprio cadastro
  usuario_id = (SELECT id FROM public.usuarios WHERE id_auth = auth.uid())
);

-- Política 2: jovem pode ver proprio cadastro (SELECT)
CREATE POLICY "jovem pode ver proprio cadastro" ON public.jovens
FOR SELECT TO authenticated
USING (
  -- O jovem pode ver seu próprio cadastro
  usuario_id = (SELECT id FROM public.usuarios WHERE id_auth = auth.uid())
);

-- Política 3: jovens_select_scoped (SELECT)
CREATE POLICY "jovens_select_scoped" ON public.jovens
FOR SELECT TO authenticated
USING (
  -- Admin/colab/líderes com escopo via can_access_jovem
  can_access_jovem(estado_id, bloco_id, regiao_id, igreja_id)
);

-- Política 4: jovens_insert_self_or_admin (INSERT)
CREATE POLICY "jovens_insert_self_or_admin" ON public.jovens
FOR INSERT TO authenticated
WITH CHECK (
  -- O jovem pode inserir seu próprio cadastro
  usuario_id = (SELECT id FROM public.usuarios WHERE id_auth = auth.uid())
  OR
  -- Admin/colab/líderes com escopo via can_access_jovem
  can_access_jovem(estado_id, bloco_id, regiao_id, igreja_id)
);

-- Política 5: jovens_update_scoped_roles (UPDATE)
CREATE POLICY "jovens_update_scoped_roles" ON public.jovens
FOR UPDATE TO authenticated
USING (
  -- O próprio jovem pode atualizar seu cadastro
  usuario_id = (SELECT id FROM public.usuarios WHERE id_auth = auth.uid())
  OR
  -- Admin/colab/líderes com escopo via can_access_jovem
  can_access_jovem(estado_id, bloco_id, regiao_id, igreja_id)
)
WITH CHECK (
  -- O próprio jovem pode atualizar seu cadastro
  usuario_id = (SELECT id FROM public.usuarios WHERE id_auth = auth.uid())
  OR
  -- Admin/colab/líderes com escopo via can_access_jovem
  can_access_jovem(estado_id, bloco_id, regiao_id, igreja_id)
);

-- Política 6: jovens_delete_admin (DELETE)
CREATE POLICY "jovens_delete_admin" ON public.jovens
FOR DELETE TO authenticated
USING (
  -- Apenas administradores podem deletar
  EXISTS (
    SELECT 1 FROM public.user_roles ur
    JOIN public.roles r ON r.id = ur.role_id
    WHERE ur.user_id = (SELECT id FROM public.usuarios WHERE id_auth = auth.uid())
      AND ur.ativo = true
      AND r.slug = 'administrador'
  )
);

-- ============================================
-- 4. VERIFICAÇÃO FINAL
-- ============================================

-- Verificar políticas criadas
SELECT 
  'POLÍTICAS CRIADAS:' as status,
  policyname as nome_politica,
  cmd as comando,
  permissive as permissiva,
  roles as roles_aplicadas
FROM pg_policies 
WHERE tablename = 'jovens'
ORDER BY policyname;

-- Contar políticas por comando
SELECT 
  cmd as comando,
  COUNT(*) as total_politicas,
  STRING_AGG(policyname, ', ') as nomes_politicas
FROM pg_policies 
WHERE tablename = 'jovens'
GROUP BY cmd
ORDER BY cmd;

-- Verificar se a função can_access_jovem existe
SELECT 
  'Função can_access_jovem existe:' as status,
  EXISTS (
    SELECT 1 FROM pg_proc p
    JOIN pg_namespace n ON p.pronamespace = n.oid
    WHERE n.nspname = 'public' AND p.proname = 'can_access_jovem'
  ) as existe;

-- ============================================
-- 5. TESTE DE ACESSO
-- ============================================

-- Testar se consegue ver os jovens
SELECT 
  'Teste de acesso:' as status,
  COUNT(*) as total_jovens_visiveis
FROM public.jovens;

-- Ver alguns jovens (se a política permitir)
SELECT 
  id,
  nome_completo,
  aprovado,
  usuario_id
FROM public.jovens
LIMIT 3;
