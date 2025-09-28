-- Script para corrigir políticas RLS da tabela jovens
-- Execute este script no Supabase SQL Editor

-- ============================================
-- 1. CRIAR FUNÇÃO can_access_jovem
-- ============================================

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
-- 2. REMOVER POLÍTICAS EXISTENTES
-- ============================================

DROP POLICY IF EXISTS "jovem pode inserir proprio cadastro" ON public.jovens;
DROP POLICY IF EXISTS "jovem pode ver proprio cadastro" ON public.jovens;
DROP POLICY IF EXISTS "jovens_select_scoped" ON public.jovens;
DROP POLICY IF EXISTS "jovens_insert_self_or_admin" ON public.jovens;
DROP POLICY IF EXISTS "jovens_update_scoped_roles" ON public.jovens;
DROP POLICY IF EXISTS "jovens_delete_admin" ON public.jovens;

-- ============================================
-- 3. HABILITAR RLS
-- ============================================

ALTER TABLE public.jovens ENABLE ROW LEVEL SECURITY;

-- ============================================
-- 4. CRIAR POLÍTICAS CORRETAS
-- ============================================

-- Política para SELECT
CREATE POLICY "jovens_select_scoped" ON public.jovens
FOR SELECT TO authenticated
USING (
  -- O próprio jovem pode ver seu cadastro
  usuario_id = (SELECT id FROM public.usuarios WHERE id_auth = auth.uid())
  OR
  -- Admin/colab/líderes com escopo via can_access_jovem
  can_access_jovem(estado_id, bloco_id, regiao_id, igreja_id)
);

-- Política para INSERT
CREATE POLICY "jovens_insert_self_or_admin" ON public.jovens
FOR INSERT TO authenticated
WITH CHECK (
  -- O jovem pode inserir seu próprio cadastro
  usuario_id = (SELECT id FROM public.usuarios WHERE id_auth = auth.uid())
  OR
  -- Admin/colab/líderes com escopo via can_access_jovem
  can_access_jovem(estado_id, bloco_id, regiao_id, igreja_id)
);

-- Política para UPDATE
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
-- 5. VERIFICAÇÃO FINAL
-- ============================================

-- Verificar se as políticas foram criadas
SELECT 'Políticas criadas:' as status, COUNT(*) as total
FROM pg_policies 
WHERE tablename = 'jovens';

-- Listar todas as políticas da tabela jovens
SELECT policyname, cmd, permissive, roles
FROM pg_policies 
WHERE tablename = 'jovens'
ORDER BY policyname;
