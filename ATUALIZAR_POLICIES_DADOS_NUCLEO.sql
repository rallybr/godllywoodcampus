-- Script para atualizar as políticas RLS da tabela dados_nucleo
-- Execute este script no SQL Editor do Supabase

-- 1. Remover políticas existentes
DROP POLICY IF EXISTS "dados_nucleo_insert_own" ON public.dados_nucleo;
DROP POLICY IF EXISTS "dados_nucleo_update_own" ON public.dados_nucleo;

-- 2. Recriar política de INSERT corrigida
CREATE POLICY "dados_nucleo_insert_own" ON public.dados_nucleo
FOR INSERT TO authenticated
WITH CHECK (
  -- Jovem: pode inserir apenas seus próprios dados
  EXISTS (
    SELECT 1 FROM public.usuarios u 
    WHERE u.id_auth = auth.uid() 
    AND u.nivel = 'jovem' 
    AND u.id = dados_nucleo.jovem_id
  )
  OR
  -- Administrador: pode inserir dados de qualquer jovem
  EXISTS (
    SELECT 1 FROM public.usuarios u 
    WHERE u.id_auth = auth.uid() 
    AND u.nivel = 'administrador'
  )
  OR
  -- Colaborador: pode inserir dados dos jovens que cadastrou
  EXISTS (
    SELECT 1 FROM public.usuarios u 
    WHERE u.id_auth = auth.uid() 
    AND u.nivel = 'colaborador' 
    AND u.id = dados_nucleo.jovem_id
  )
);

-- 3. Recriar política de UPDATE corrigida
CREATE POLICY "dados_nucleo_update_own" ON public.dados_nucleo
FOR UPDATE TO authenticated
USING (
  -- Jovem: pode atualizar apenas seus próprios dados
  EXISTS (
    SELECT 1 FROM public.usuarios u 
    WHERE u.id_auth = auth.uid() 
    AND u.nivel = 'jovem' 
    AND u.id = dados_nucleo.jovem_id
  )
  OR
  -- Administrador: pode atualizar dados de qualquer jovem
  EXISTS (
    SELECT 1 FROM public.usuarios u 
    WHERE u.id_auth = auth.uid() 
    AND u.nivel = 'administrador'
  )
  OR
  -- Colaborador: pode atualizar dados dos jovens que cadastrou
  EXISTS (
    SELECT 1 FROM public.usuarios u 
    WHERE u.id_auth = auth.uid() 
    AND u.nivel = 'colaborador' 
    AND u.id = dados_nucleo.jovem_id
  )
);

-- 4. Verificar se as políticas foram criadas corretamente
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
