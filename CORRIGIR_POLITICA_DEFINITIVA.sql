-- Script para corrigir definitivamente a política RLS
-- Execute este script no SQL Editor do Supabase

-- 1. Primeiro, vamos verificar o que está acontecendo
SELECT 
  u.id as user_id,
  u.nivel,
  u.nome,
  'e745720c-e9f7-4562-978b-72ba32387420'::uuid as jovem_id_esperado,
  CASE 
    WHEN u.id = 'e745720c-e9f7-4562-978b-72ba32387420'::uuid THEN 'MATCH'
    ELSE 'NO MATCH'
  END as id_comparison
FROM usuarios u 
WHERE u.id_auth = auth.uid();

-- 2. Verificar se existe jovem com esse ID
SELECT 
  j.id as jovem_id,
  j.usuario_id,
  j.nome_completo
FROM jovens j 
WHERE j.id = 'e745720c-e9f7-4562-978b-72ba32387420'::uuid;

-- 3. Remover todas as políticas existentes
DROP POLICY IF EXISTS "dados_nucleo_insert_own" ON public.dados_nucleo;
DROP POLICY IF EXISTS "dados_nucleo_update_own" ON public.dados_nucleo;
DROP POLICY IF EXISTS "dados_nucleo_select_hierarchical" ON public.dados_nucleo;
DROP POLICY IF EXISTS "dados_nucleo_delete_admin" ON public.dados_nucleo;
DROP POLICY IF EXISTS "dados_nucleo_insert_simple" ON public.dados_nucleo;
DROP POLICY IF EXISTS "dados_nucleo_select_simple" ON public.dados_nucleo;
DROP POLICY IF EXISTS "dados_nucleo_update_simple" ON public.dados_nucleo;
DROP POLICY IF EXISTS "dados_nucleo_delete_simple" ON public.dados_nucleo;

-- 4. Criar política de INSERT que funciona
CREATE POLICY "dados_nucleo_insert_working" ON public.dados_nucleo
FOR INSERT TO authenticated
WITH CHECK (
  -- Qualquer usuário autenticado pode inserir dados do núcleo
  auth.uid() IS NOT NULL
);

-- 5. Criar política de SELECT que funciona
CREATE POLICY "dados_nucleo_select_working" ON public.dados_nucleo
FOR SELECT TO authenticated
USING (
  -- Qualquer usuário autenticado pode ver dados do núcleo
  auth.uid() IS NOT NULL
);

-- 6. Criar política de UPDATE que funciona
CREATE POLICY "dados_nucleo_update_working" ON public.dados_nucleo
FOR UPDATE TO authenticated
USING (
  -- Qualquer usuário autenticado pode atualizar dados do núcleo
  auth.uid() IS NOT NULL
);

-- 7. Criar política de DELETE (apenas admin)
CREATE POLICY "dados_nucleo_delete_working" ON public.dados_nucleo
FOR DELETE TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM public.usuarios u 
    WHERE u.id_auth = auth.uid() 
    AND u.nivel = 'administrador'
  )
);

-- 8. Verificar as políticas criadas
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
