-- Política simplificada para dados_nucleo
-- Execute este script no SQL Editor do Supabase

-- 1. Remover todas as políticas existentes
DROP POLICY IF EXISTS "dados_nucleo_insert_own" ON public.dados_nucleo;
DROP POLICY IF EXISTS "dados_nucleo_update_own" ON public.dados_nucleo;
DROP POLICY IF EXISTS "dados_nucleo_select_hierarchical" ON public.dados_nucleo;
DROP POLICY IF EXISTS "dados_nucleo_delete_admin" ON public.dados_nucleo;

-- 2. Criar política de INSERT muito simples
CREATE POLICY "dados_nucleo_insert_simple" ON public.dados_nucleo
FOR INSERT TO authenticated
WITH CHECK (
  -- Qualquer usuário autenticado pode inserir
  true
);

-- 3. Criar política de SELECT simples
CREATE POLICY "dados_nucleo_select_simple" ON public.dados_nucleo
FOR SELECT TO authenticated
USING (
  -- Qualquer usuário autenticado pode ver
  true
);

-- 4. Criar política de UPDATE simples
CREATE POLICY "dados_nucleo_update_simple" ON public.dados_nucleo
FOR UPDATE TO authenticated
USING (
  -- Qualquer usuário autenticado pode atualizar
  true
);

-- 5. Criar política de DELETE simples (apenas admin)
CREATE POLICY "dados_nucleo_delete_simple" ON public.dados_nucleo
FOR DELETE TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM public.usuarios u 
    WHERE u.id_auth = auth.uid() 
    AND u.nivel = 'administrador'
  )
);

-- 6. Verificar as políticas criadas
SELECT 
  schemaname,
  tablename,
  policyname,
  permissive,
  roles,
  cmd,
  qual,
  with_check
FROM pg_policies 
WHERE tablename = 'dados_nucleo'
ORDER BY policyname;
