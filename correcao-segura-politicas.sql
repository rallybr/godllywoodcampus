-- Script para correção SEGURA das políticas RLS da tabela jovens
-- Remove apenas as políticas problemáticas (comando ALL) e mantém as que funcionam

-- ============================================
-- 1. BACKUP DAS POLÍTICAS ATUAIS
-- ============================================

-- Listar todas as políticas antes da correção
SELECT 
  'BACKUP: Políticas antes da correção' as status,
  policyname as nome_politica,
  cmd as comando,
  permissive as permissiva,
  roles as roles_aplicadas
FROM pg_policies 
WHERE tablename = 'jovens'
ORDER BY policyname;

-- ============================================
-- 2. IDENTIFICAR POLÍTICAS PROBLEMÁTICAS
-- ============================================

-- Listar políticas com comando ALL (problemáticas)
SELECT 
  'POLÍTICAS PROBLEMÁTICAS (comando ALL):' as status,
  policyname as nome_politica,
  cmd as comando,
  permissive as permissiva,
  roles as roles_aplicadas
FROM pg_policies 
WHERE tablename = 'jovens' 
  AND cmd = 'ALL'
ORDER BY policyname;

-- ============================================
-- 3. VERIFICAR POLÍTICAS QUE FUNCIONAM
-- ============================================

-- Listar políticas com comandos específicos (que funcionam)
SELECT 
  'POLÍTICAS QUE FUNCIONAM (comandos específicos):' as status,
  policyname as nome_politica,
  cmd as comando,
  permissive as permissiva,
  roles as roles_aplicadas
FROM pg_policies 
WHERE tablename = 'jovens' 
  AND cmd != 'ALL'
ORDER BY policyname;

-- ============================================
-- 4. REMOVER APENAS POLÍTICAS PROBLEMÁTICAS
-- ============================================

-- Remover políticas com comando ALL (problemáticas)
DROP POLICY IF EXISTS "jovens_admin_colab" ON public.jovens;
DROP POLICY IF EXISTS "jovens_admin_policy" ON public.jovens;
DROP POLICY IF EXISTS "jovens_colaborador_policy" ON public.jovens;
DROP POLICY IF EXISTS "jovens_lider_bloco" ON public.jovens;
DROP POLICY IF EXISTS "jovens_lider_bloco_policy" ON public.jovens;
DROP POLICY IF EXISTS "jovens_lider_estadual" ON public.jovens;
DROP POLICY IF EXISTS "jovens_lider_estadual_policy" ON public.jovens;
DROP POLICY IF EXISTS "jovens_lider_igreja" ON public.jovens;
DROP POLICY IF EXISTS "jovens_lider_igreja_policy" ON public.jovens;
DROP POLICY IF EXISTS "jovens_lider_regional" ON public.jovens;
DROP POLICY IF EXISTS "jovens_lider_regional_policy" ON public.jovens;

-- ============================================
-- 5. VERIFICAR SE A FUNÇÃO can_access_jovem EXISTE
-- ============================================

-- Verificar se a função existe
SELECT 
  'Função can_access_jovem existe:' as status,
  EXISTS (
    SELECT 1 FROM pg_proc p
    JOIN pg_namespace n ON p.pronamespace = n.oid
    WHERE n.nspname = 'public' AND p.proname = 'can_access_jovem'
  ) as existe;

-- Se não existir, criar a função
CREATE OR REPLACE FUNCTION can_access_jovem(
  jovem_estado_id uuid,
  jovem_bloco_id uuid,
  jovem_regiao_id uuid,
  jovem_igreja_id uuid
) RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  current_user_id uuid;
  user_role_slug text;
BEGIN
  -- Obter o ID do usuário atual
  current_user_id := (SELECT id FROM public.usuarios WHERE id_auth = auth.uid());
  
  IF current_user_id IS NULL THEN
    RETURN false;
  END IF;
  
  -- Verificar se é administrador ou colaborador (acesso total)
  SELECT r.slug INTO user_role_slug
  FROM public.user_roles ur
  JOIN public.roles r ON r.id = ur.role_id
  WHERE ur.user_id = current_user_id
    AND ur.ativo = true
    AND r.slug IN ('administrador', 'colaborador');
  
  IF user_role_slug IS NOT NULL THEN
    RETURN true;
  END IF;
  
  -- Verificar líderes com escopo específico
  SELECT r.slug INTO user_role_slug
  FROM public.user_roles ur
  JOIN public.roles r ON r.id = ur.role_id
  WHERE ur.user_id = current_user_id
    AND ur.ativo = true
    AND r.slug IN ('lider_estadual', 'lider_bloco', 'lider_regional', 'lider_igreja')
    AND (
      (r.slug = 'lider_estadual' AND ur.estado_id = jovem_estado_id) OR
      (r.slug = 'lider_bloco' AND ur.bloco_id = jovem_bloco_id) OR
      (r.slug = 'lider_regional' AND ur.regiao_id = jovem_regiao_id) OR
      (r.slug = 'lider_igreja' AND ur.igreja_id = jovem_igreja_id)
    );
  
  RETURN user_role_slug IS NOT NULL;
END;
$$;

-- ============================================
-- 6. CRIAR POLÍTICAS LIMPAS E ORGANIZADAS
-- ============================================

-- Política para UPDATE (para os botões funcionarem)
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

-- Política para DELETE (apenas administradores)
CREATE POLICY "jovens_delete_admin" ON public.jovens
FOR DELETE TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM public.user_roles ur
    JOIN public.roles r ON r.id = ur.role_id
    WHERE ur.user_id = (SELECT id FROM public.usuarios WHERE id_auth = auth.uid())
      AND ur.ativo = true
      AND r.slug = 'administrador'
  )
);

-- ============================================
-- 7. VERIFICAÇÃO FINAL
-- ============================================

-- Verificar políticas após correção
SELECT 
  'POLÍTICAS APÓS CORREÇÃO:' as status,
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
  CASE 
    WHEN COUNT(*) > 1 THEN 'ATENÇÃO: Múltiplas políticas para o mesmo comando'
    ELSE 'OK: Uma política por comando'
  END as status
FROM pg_policies 
WHERE tablename = 'jovens'
GROUP BY cmd
ORDER BY total_politicas DESC;

-- Verificar se a função foi criada
SELECT 
  'Função can_access_jovem criada:' as status,
  EXISTS (
    SELECT 1 FROM pg_proc p
    JOIN pg_namespace n ON p.pronamespace = n.oid
    WHERE n.nspname = 'public' AND p.proname = 'can_access_jovem'
  ) as existe;
