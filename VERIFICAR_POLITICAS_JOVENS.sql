-- =====================================================
-- VERIFICAR POLÍTICAS RLS DA TABELA JOVENS
-- =====================================================
-- Data: 2024-12-19
-- Objetivo: Verificar e corrigir políticas RLS da tabela jovens

-- =====================================================
-- 1. VERIFICAR POLÍTICAS ATUAIS DA TABELA JOVENS
-- =====================================================

SELECT 
  'POLÍTICAS JOVENS' as status,
  policyname,
  permissive,
  roles,
  cmd,
  qual,
  with_check
FROM pg_policies 
WHERE tablename = 'jovens'
ORDER BY policyname;

-- =====================================================
-- 2. VERIFICAR SE RLS ESTÁ HABILITADO
-- =====================================================

SELECT 
  'RLS STATUS' as status,
  schemaname,
  tablename,
  rowsecurity as rls_habilitado
FROM pg_tables 
WHERE tablename = 'jovens';

-- =====================================================
-- 3. VERIFICAR FUNÇÕES AUXILIARES
-- =====================================================

SELECT 
  'FUNÇÕES AUXILIARES' as status,
  routine_name,
  routine_type
FROM information_schema.routines 
WHERE routine_schema = 'public' 
  AND routine_name IN ('is_admin_user', 'has_role', 'can_access_jovem')
ORDER BY routine_name;

-- =====================================================
-- 4. TESTAR FUNÇÕES AUXILIARES
-- =====================================================

SELECT 
  'TESTE FUNÇÕES' as status,
  is_admin_user() as is_admin,
  has_role('administrador') as has_admin_role,
  can_access_jovem(
    'c20e70c2-92e6-4c50-96a5-177822095a25'::uuid,
    'b0cb2a8a-5b89-478b-95a9-a5bb8e84f06d'::uuid,
    '84cff91c-3afa-49da-b211-24f50f7cb2ab'::uuid,
    'd3301078-fc09-4131-b9e8-03c78570a774'::uuid
  ) as can_access;
